#! /usr/bin/perl

#  Copyright (C) 2010, Geoffrey Leach
#
#===============================================================================
#
#         FILE:  03-options_bare.t
#
#  DESCRIPTION:  Test run-time options that are BARE -- i.e., no '-' or '--'
#                There is no 'stop parsing' convention.
#                Also, there's no way to split a bare option into letters.
#
#       AUTHOR:  Geoffrey Leach (), <geoff@hughes.net>
#      VERSION:  1.9.8
#      CREATED:  Mon Aug 10 13:28:07 PDT 2009
#===============================================================================

use strict;
use warnings;

use Test::More tests => 14;
use Test::Output;

use 5.006;
our $VERSION = '1.9.8';

## no critic (ProhibitImplicitNewlines)
## no critic (ProtectPrivateSubs)
## no critic (RequireLocalizedPunctuationVars)
## no critic (ProhibitPackageVars)
## no critic (ProtectPrivateVars)

BEGIN {

   # This simulates our being called with various options on the command line.
   # It's here because Getopt::Auto needs to look at it
    @ARGV = qw(foo bar bararg1 bararg2 notanarg tar=tararg2 - foobar);
    use Getopt::Auto;
}

our %options;
if (%options) { }
;    # Avoid complaints from perl-5.6.2
my $EMPTY = q{};

# What we expect to find in the spec list
my @exspec = (
    [   'bar', 'do a bar', 'This is the help for bar
', \&bar,
    ],
    [ 'eq1', 'assignment op',         undef, \&eq1, ],
    [ 'eq3', 'assignment op, no sub', undef, undef, ],
    [   'foo', 'do a foo', 'This is the help for foo
', \&foo,
    ],
    [   'nosubs', 'bump a counter',
        'Nosub has -- surprise -- no associated sub
', undef,
    ],
    [   'tar', $EMPTY, 'This is the long help for tar, which has no short help
', \&tar,
    ],
);

# What we expect to find in the options hash
my %ex_options = (
    'tar' => {
        'longhelp' => 'This is the long help for tar, which has no short help
',
        'code'       => \&tar,
        'shorthelp'  => $EMPTY,
        'options'    => 'main::options',
        'package'    => 'main',
        'registered' => 1,
    },
    'nosubs' => {
        'longhelp' => 'Nosub has -- surprise -- no associated sub
',
        'shorthelp'  => 'bump a counter',
        'options'    => 'main::options',
        'package'    => 'main',
        'registered' => 1,
    },
    'bar' => {
        'longhelp' => 'This is the help for bar
',
        'code'       => \&bar,
        'shorthelp'  => 'do a bar',
        'options'    => 'main::options',
        'package'    => 'main',
        'registered' => 1,
    },
    'version' => {
        'shorthelp'  => 'Prints the version number',
        'code'       => \&Getopt::Auto::_version,
        'registered' => 1,
    },
    'help' => {
        'shorthelp'  => 'This text',
        'code'       => \&Getopt::Auto::_help,
        'registered' => 1,
    },
    'foo' => {
        'longhelp' => 'This is the help for foo
',
        'code'       => \&foo,
        'shorthelp'  => 'do a foo',
        'options'    => 'main::options',
        'package'    => 'main',
        'registered' => 1,
    },
    'eq1' => {
        'longhelp'   => undef,
        'code'       => \&eq1,
        'shorthelp'  => 'assignment op',
        'options'    => 'main::options',
        'package'    => 'main',
        'registered' => 1,
    },
    'eq3' => {
        'longhelp'   => undef,
        'shorthelp'  => 'assignment op, no sub',
        'options'    => 'main::options',
        'package'    => 'main',
        'registered' => 1,
    },
);

is_deeply( Getopt::Auto::_get_spec_ref(),
    \@exspec, 'Spec gets built correctly' );
is_deeply( Getopt::Auto::_get_options_ref(),
    \%ex_options, '... and gets converted to options OK' );

# Option has no args
my $is_foo_called;
sub foo { $is_foo_called = 1; return; }
ok( $is_foo_called, 'Calling foo()' );

# Option has two args
my $is_bar_called;

sub bar {
    $is_bar_called = ( shift @ARGV ) . ' and ' . shift @ARGV;
    return;
}
ok( defined $is_bar_called, "Calling bar() with $is_bar_called" );

# Option has one arg, tied with '='
my $is_tar_called;
sub tar { $is_tar_called = shift @ARGV; return; }
ok( defined $is_tar_called, "Calling tar() with $is_tar_called" );

# Option occurs after '-', so is not called
# Subroutine is required as otherwise its always ignored
my $is_foobar_called;
sub foobar { $is_foobar_called = 1; return; }
ok( !defined $is_foobar_called, 'Foobar was not called' );

# Check the leftover command line args, and their position
ok( $ARGV[0] eq 'notanarg',
    'Unused command line argument "notanarg" remains' );
ok( $ARGV[1] eq 'foobar', 'Unused command line argument "foobar" remains' );

# Verify not a registered option.
# Stupid, actually because this is implicitly verified in prior tests,
# but it's nice to have it.
@ARGV = qw{ abcdefg };
stdout_isnt(
    \&Getopt::Auto::_parse_args,
    "abcdefg is not a registered option\n",
    'abcdefg correctly not a registered option'
);
ok( $ARGV[0] eq 'abcdefg', 'Unregistered option abcedegf remains' );

my $eq1_is_called;
sub eq1 { $eq1_is_called = shift @ARGV; return; }

# eq2 does not get an error because it's BARE and unregistered,
# thus its treated as data.

@ARGV = qw{ eq1=1 eq2=99 eq3=111 };
stderr_is(
    \&Getopt::Auto::_parse_args,
    "Getopt::Auto: To use eq3 with \"=\", a subroutine must be provided\n",
    'eq2 correctly not registered option, eq3 has no sub'
);
ok( $eq1_is_called == 1, 'eq1() correct' );
ok( $ARGV[0] eq 'eq2=99',  'eq2 restored to ARGV' );
ok( $ARGV[1] eq 'eq3=111', 'eq3 restored to ARGV' );

exit 0;

__END__

=pod

=begin stopwords
nosubs
Nosub
eq
=end stopwords

=head2 foo - do a foo

This is the help for foo

=head2 bar - do a bar

This is the help for bar

=head2 tar - 

This is the long help for tar, which has no short help

=head2 nosubs - bump a counter

Nosub has -- surprise -- no associated sub

=item eq1 - assignment op

=item eq3 - assignment op, no sub

=cut

