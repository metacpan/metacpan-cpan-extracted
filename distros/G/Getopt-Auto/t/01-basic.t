#! /usr/bin/perl
#  Copyright (C) 2010, Geoffrey Leach
#===============================================================================
#
#         FILE:  01.basic.t
#
#  DESCRIPTION:  Test the construction of internal data structures
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Geoffrey Leach (), <geoff@hughes.net>
#      COMPANY:
#      VERSION:  1.9.8
#      CREATED:  07/06/2009 03:27:58 PM PDT
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Test::More tests => 6;
use Test::Output;
use Getopt::Auto( { test => 1, nohelp=>1 } );

use 5.006;
our $VERSION = '1.9.8';

## no critic (ProhibitImplicitNewlines)
## no critic (ProtectPrivateSubs)
## no critic (RequireLocalizedPunctuationVars)
## no critic (ProtectPrivateVars)
## no critic (ProhibitPackageVars)

our %options;    # Will be set by Getopt::Auto; 'our' is required for that

my @exspec = (
    [   '--foo', 'do a foo', 'Test
', \&foo
    ]
);

my %ex_options = (
    '--foo' => {
        'longhelp' => 'Test
',
        'code'       => \&foo,
        'shorthelp'  => 'do a foo',
        'options'    => 'main::options',
        'package'    => 'main',
        'registered' => 1,
    },
    '--version' => {
        'shorthelp'  => 'Prints the version number',
        'code'       => \&Getopt::Auto::_version,
        'registered' => 1,
    },
    '--help' => {
        'shorthelp'  => 'This text',
        'code'       => \&Getopt::Auto::_help,
        'registered' => 1,
    },
);

is_deeply( Getopt::Auto::_get_spec_ref(),
    \@exspec, 'Spec gets built correctly' );
is_deeply( Getopt::Auto::_get_options_ref(),
    \%ex_options, '... and gets converted to options OK' );

# Now, if all is proceeding according to plan, we are set up to expect option
# --foo. $is_foo_called will be set to 1 if the subroutine foo() implied by the
# --foo option is called. We also have here a "short" option, -x, which has
# not been specified in advance, so we expect that $main::options->{x} will not be set

my $is_foo_called = 0;
sub foo { ++$is_foo_called; return; }

@ARGV = qw( -x --foo );
stderr_is(
    \&Getopt::Auto::_parse_args,
    "Getopt::Auto: -x is not a registered option\n",
    '-x not registered'
);
ok( $is_foo_called, 'Sub foo() was called' );
isnt( $options{'x'}, 1, 'option "x" was not set' );

# The most basic situation is the one where there are no options given
@ARGV = qw( /twas/brillig/and/the/slythe/toes );
stderr_isnt(
    \&Getopt::Auto::_parse_args,
    "Getopt::Auto:  /twas/brillig/and/the/slythe/toes is not a registered option\n",
    '/twas/brillig/and/the/slythe/toes not flagged'
);

exit 0;

__END__

=pod

=head2 --foo - do a foo

Test

=cut

