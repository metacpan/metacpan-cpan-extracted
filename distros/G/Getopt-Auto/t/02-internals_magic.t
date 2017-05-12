#! /usr/bin/perl

#  Copyright (C) 2010, Geoffrey Leach
#
#===============================================================================
#
#         FILE:  02-internals_magic.t
#
#  DESCRIPTION:  Test the construction of internal data structures
#                which result from the "magic" mode of Getopt::Auto
#
#       AUTHOR:  Geoffrey Leach (), <geoff@hughes.net>
#      VERSION:  1.9.8
#      CREATED:  07/06/2009 03:27:58 PM PDT
#===============================================================================

use strict;
use warnings;

use Test::More tests => 6;
use Test::Output qw{ stderr_from };
use Getopt::Auto( { 'test' => 1 } );

use 5.006;
our $VERSION = '1.9.8';
my $me = q{02-internals_magic.t}; # The directory path is unimportant

## no critic (RestrictLongStrings)
## no critic (ProhibitImplicitNewlines)
## no critic (ProtectPrivateSubs)
## no critic (RequireLocalizedPunctuationVars)
## no critic (ProtectPrivateVars)
## no critic (ProhibitPackageVars)

# Will be assigned by Getopt::Auto
our %options;
if ( %options ) {}; # Avoid complaints from perl-5.6.2

# What we expect to find in the spec list
my @exspec = (
    [   '--foo', 'do a foo', 'Test long help for foo.
', \&foo
    ],
);

# What we expect to find in the options hash
my %ex_options = (
    '--foo' => {
        'longhelp' => 'Test long help for foo.
',
        'code'       => \&foo,
        'shorthelp'  => 'do a foo',
        'options'    => 'main::options',
        'package'    => 'main',
        'registered' => 1,
    },
    '--version' => {
        'shorthelp'  => 'Prints the version number',
        'registered' => 1,
        'code'       => \&Getopt::Auto::_version,
        'registered' => 1,
    },
    '--help' => {
        'shorthelp'  => 'This text',
        'code'       => \&Getopt::Auto::_help,
        'registered' => 1,
    },
);

my $is_foo_called;
sub foo { ++$is_foo_called; return; }

is_deeply( Getopt::Auto::_get_spec_ref(),
    \@exspec, 'Spec gets built correctly' );
is_deeply( Getopt::Auto::_get_options_ref(),
    \%ex_options, '... and gets converted to options OK' );

@ARGV = qw(--foo);
Getopt::Auto::_parse_args;
ok( $is_foo_called, 'Sub foo() was called' );

# In the tests that follow, directory path (and especially the / or \) is unimportant
# The goal of the regex s{\S+$me}{$me} is to remove all non-space characters up to
# $me. Hopefully this a directory path, prefixed with a space.

my $version = "This is $me version $VERSION

";

@ARGV = qw(--version);
my $stderr = stderr_from( \&Getopt::Auto::_parse_args );
$stderr =~ s{\S+$me}{$me}xism;   
is( $stderr, $version, 'Check version' );

my $help = "This is $me version $VERSION

$me --foo - do a foo [*]
$me --help - This text
$me --version - Prints the version number

More help is available on the topics marked with [*]
Try $me --help --foo
This is the built-in help, exiting
";

@ARGV = qw(--help);
$stderr = stderr_from( \&Getopt::Auto::_parse_args );
$stderr =~ s{\S+$me}{$me}gxism; 
is( $stderr, $help, 'Check help' );

$help = "This is $me version $VERSION

$me --foo - do a foo

Test long help for foo.

This is the built-in help, exiting
";

@ARGV = qw(--help --foo);
$stderr = stderr_from( \&Getopt::Auto::_parse_args);
$stderr =~ s{\S+$me}{$me}gxism;   
is( $stderr, $help, 'Check help for foo' );

exit 0;

__END__

# This is the POD that Getopt::Auto sees. Strange, no?
# The third =head2 demonstrates how casual coding can generate
# something that looks like an option, but isn't

=pod

=head2 --foo - do a foo

Test long help for foo.

=head2 -this is not an option

This text does not belong to --foo!

=head2 another -

non-option

=cut
