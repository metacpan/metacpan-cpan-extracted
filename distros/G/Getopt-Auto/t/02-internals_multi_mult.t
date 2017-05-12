#! /usr/bin/perl

#  Copyright (C) 2010, Geoffrey Leach

#===============================================================================
#
#         FILE:  02-internals_notmagic_mult.t
#
#  DESCRIPTION:  Test the construction of internal data structures
#                which result from the multiple uses of the "non-magic"
#                mode and the "magic" mode of Getopt::Auto
#                --foo and --tar come from non-magic, while --bar-bar
#                gets picked up from the POD. Note also that conversion
#                from --bar-bar to sub bar_bar{...} is also tested.
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Geoffrey Leach (), geoff@hughes.net
#      COMPANY:
#      VERSION:  1.9.8
#      CREATED:  11/05/2009 04:32:25 PM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use 5.006;
our $VERSION = '1.9.8';

use Test::More tests => 5;

## no critic (ProhibitImplicitNewlines)
## no critic (ProtectPrivateSubs)
## no critic (RequireLocalizedPunctuationVars)
## no critic (ProhibitPackageVars)
## no critic (ProtectPrivateVars)

use Getopt::Auto(
    { test => 1 },
    [   [   '--foo', 'do a foo', 'Test
', \&foo
        ],
        [   '--tar', 'do a tar', 'Test
', \&tar
        ],
    ]
);

our %options;    # Will be assigned by Getopt::Auto

# What we expect to find in the spec list
# Note: ordering here. First come the contributions from 'use Getopt::Auto' in
# the same order as they appear. Next the contributions from the POD, in sorted order.
my @exspec = (
    [   '--foo', 'do a foo', 'Test
', \&foo
    ],
    [   '--tar', 'do a tar', 'Test
', \&tar
    ],
    [   '--bar-bar', 'do a bar-bar', 'Test
', \&bar_bar
    ],
    [  '--tar-tar', 'do a tar-tar', undef, undef ],
);

# What we expect to find in the options hash
my %ex_options = (
    '--version' => {
        'shorthelp'  => 'Prints the version number',
        'code'       => \&Getopt::Auto::_version,
        'registered' => 1,
    },
    '--tar' => {
        'longhelp' => 'Test
',
        'code'       => \&tar,
        'shorthelp'  => 'do a tar',
        'options'    => 'main::options',
        'package'    => 'main',
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
    '--tar-tar' => {
        'longhelp' => undef,
        'shorthelp'  => 'do a tar-tar',
        'options'    => 'main::options',
        'package'    => 'main',
        'registered' => 1,
    },
    '--bar-bar' => {
        'longhelp' => 'Test
',
        'code'       => \&bar_bar,
        'shorthelp'  => 'do a bar-bar',
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

my $is_bar_bar_called;
sub bar_bar { ++$is_bar_bar_called; return; }

my $is_tar_called;
sub tar { ++$is_tar_called; return; }

# These structures have been created according to the params to Getopt::Auto

is_deeply( Getopt::Auto::_get_spec_ref(),
    \@exspec, 'Spec gets built correctly' );
is_deeply( Getopt::Auto::_get_options_ref(),
    \%ex_options, '... and gets converted to options OK' );

@ARGV = qw(--foo --bar-bar --tar);
Getopt::Auto::_parse_args;
ok( $is_foo_called,     'Sub foo() was called' );
ok( $is_bar_bar_called, 'Sub bar_bar() was called' );
ok( $is_tar_called,     'Sub tar() was called' );

exit 0;

__END__

=pod

=head2 --tar-tar - do a tar-tar

=head2 --bar-bar - do a bar-bar

Test

=cut
