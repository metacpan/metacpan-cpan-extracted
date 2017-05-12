#! /usr/bin/perl

#  Copyright (C) 2010, Geoffrey Leach
#
#===============================================================================
#
#         FILE:  03-options_short.t
#
#  DESCRIPTION:  Test combination of 'short' ('-') run-time options
#                We also check options with POD formatting attached
#
#       AUTHOR:  Geoffrey Leach (), <geoff@hughes.net>
#      VERSION:  1.9.8
#      CREATED:  Sun Aug  9 16:38:44 PDT 2009
#===============================================================================

use strict;
use warnings;

use Test::More tests => 24;
use Test::Output;

use 5.006;
our $VERSION = '1.9.8';

## no critic (RequireLocalizedPunctuationVars)
## no critic (ProhibitPackageVars)
## no critic (ProhibitMagicNumbers)
## no critic (ProtectPrivateVars)

BEGIN {

   # This simulates our being called with various options on the command line.
   # It's here because Getopt::Auto needs to look at it
    @ARGV
        = qw(-foo -bar bararg1 bararg2 notanarg -tar=tararg2 -nosub -foo1 -foo2 -foo3 --two -tt - -foobar);
    use Getopt::Auto{ 'nohelp' => 1 };
}

our %options;

my %ex_options = ( '-nosub' => 1, );

# Option has no args
my $is_foo_called;
sub foo { $is_foo_called = 1; return; }
ok( $is_foo_called, 'Calling foo()' );

my $is_foo1_called;
sub foo1 { $is_foo1_called = 1; return; }
ok( $is_foo1_called, 'Calling foo1()' );

my $is_foo2_called;
sub foo2 { $is_foo2_called = 1; return; }
ok( $is_foo2_called, 'Calling foo2()' );

my $is_foo3_called;
sub foo3 { $is_foo3_called = 1; return; }
ok( $is_foo3_called, 'Calling foo3()' );

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

my $is_two_called;
sub two { $is_two_called++; return; }

# Option occurs after '--', so is not called
# Subroutine is required as otherwise its always ignored
my $is_foobar_called;
sub foobar { $is_foobar_called = 1; return; }
ok( !defined $is_foobar_called, 'Foobar was not called' );

# Check the leftover command line args, and their position
ok( $ARGV[0] eq 'notanarg',
    'Unused command line argument "notanarg" remains' );
ok( $ARGV[1] eq '-foobar', 'Unused command line argument "-foobar" remains' );

# This checks use of a short option that does not have a sub, but its letters do.

my $is_t_called;
sub t { $is_t_called = 1; two(); return; }

ok( defined $is_t_called, "Calling t()" );
ok( $is_two_called == 3,  "Calling two() for two() and t()" );

# This establishes that -nosub was noticed. It's registered, so no letter split-out
is_deeply( \%options, \%ex_options, 'Option hash constructed correctly' );

my $a_is_called;
sub a { $a_is_called = 1; return; }

my $b_is_called;
sub b { $b_is_called = 1; return; }

my $c_is_called;
sub c { $c_is_called = 1; return; }

# Verify grouping of single-letter short options
# The group is broken down and all but g have subs.
# However, there is no sub for the group itself.
@ARGV = qw{ -abcdefg };
stderr_is(
    \&Getopt::Auto::_parse_args,
    "Getopt::Auto: -g (from -abcdefg) is not a registered option\n",
    '-g correctly not registered option'
);
ok( defined $a_is_called,  "Calling a()" );
ok( defined $b_is_called,  "Calling b()" );
ok( defined $c_is_called,  "Calling c()" );
ok( exists $options{'-d'}, '-d was recognized' );
ok( exists $options{'-e'}, '-e was recognized' );
ok( exists $options{'-f'}, '-f was recognized' );
ok( $ARGV[0] eq '-g', '-g restored to ARGV' );

my $xq1_is_called;
sub xq1 { $xq1_is_called = shift @ARGV; return; }

@ARGV = qw{ -xq1=2 -xq2=99 -xq3=111 };
stderr_is(
    \&Getopt::Auto::_parse_args,
    "Getopt::Auto: -xq2 is not a registered option\n"
        . "Getopt::Auto: To use -xq3 with \"=\", a subroutine must be provided\n",
    '-xq2 correctly not registered option, -xq3 has no sub'
);
ok( $xq1_is_called == 2, 'xq1() correct' );
ok( $ARGV[0] eq '-xq2=99',  '-xq2 restored to ARGV' );
ok( $ARGV[1] eq '-xq3=111', '-xq3 restored to ARGV' );

exit 0;

__END__

=pod

=begin stopwords
Nosub
nosubs 
xq
=end stopwords 

=head2 -foo - do a foo

This is the help for -foo

=head2 -bar - do a bar

This is the help for -bar

=head2 -tar - do a tar

This is the help for -tar

=head2 -foobar - do a foobar

This is the help for -foobar, which won't be executed
because of the '-' in the command line

=head2 -nosub - bump a counter

Nosub has -- supprise -- no associated sub

=item B<-foo1> - Foo again

=item C<-foo2> - Foo again

=item I<-foo3> - Foo again

=item -t, --two - two options on the same item

=item -a - multiple use

=item -b - multiple use

=item -c - multiple use

=item -d - multiple use, no sub

=item -e - multiple use, no sub

=item -f - multiple use, no sub

=item -xq1 - assignment op

=item -xq3 - assignment op, no sub

=cut

