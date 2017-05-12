#! /usr/bin/perl

#  Copyright (C) 2010, Geoffrey Leach
#
#===============================================================================
#
#         FILE:  02-internals_notmagic.t
#
#  DESCRIPTION:  Test the construction of internal data structures
#                which result from the "non-magic" mode of Getopt::Auto
#
#       AUTHOR:  Geoffrey Leach (), <geoff@hughes.net>
#      VERSION:  1.9.8
#      CREATED:  Fri Aug  7 14:04:29 PDT 2009
#===============================================================================

use strict;
use warnings;

use 5.006;
our $VERSION = '1.9.8';

use Test::More tests => 3;

## no critic (ProhibitImplicitNewlines)
## no critic (ProtectPrivateSubs)
## no critic (RequireLocalizedPunctuationVars)
## no critic (ProhibitPackageVars)
## no critic (ProtectPrivateVars)

use Getopt::Auto(
    { test => 1 },
    [   [   '--foo', 'do a foo', 'Test
', \&foo
        ]
    ]
);

our %options;    # Will be assigned by Getopt::Auto
if ( %options ) {}; # Avoid complaints from perl-5.6.2

# What we expect to find in the spec list
# Note: ordering here must correspond to that in use Getopt::Auto above.
my @exspec = (
    [   '--foo', 'do a foo', 'Test
', \&foo
    ],
);

# What we expect to find in the options hash
my %ex_options = (
    '--version' => {
        'shorthelp'  => 'Prints the version number',
        'code'       => \&Getopt::Auto::_version,
        'registered' => 1,
    },
    '--foo' => {
        'longhelp' => 'Test
',
        'code'       => \&foo,
        'shorthelp'  => 'do a foo',
        'options'    => 'main::options',
        'package'    => 'main',
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

# These structures have been created according to the params to Getopt::Auto

is_deeply( Getopt::Auto::_get_spec_ref(),
    \@exspec, 'Spec gets built correctly' );
is_deeply( Getopt::Auto::_get_options_ref(),
    \%ex_options, '... and gets converted to options OK' );

@ARGV = qw(--foo);
Getopt::Auto::_parse_args;
ok( $is_foo_called, 'Sub foo() was called' );

exit 0;

