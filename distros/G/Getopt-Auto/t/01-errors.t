#! /usr/bin/perl

#  Copyright (C) 2010, Geoffrey Leach
#===============================================================================
#
#         FILE:  01.errors.t
#
#  DESCRIPTION:  Test generation of error messages
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Geoffrey Leach (), <geoff@hughes.net>
#      COMPANY:
#      VERSION:  1.9.8
#      CREATED:  Tue Nov 10 10:30:32 PST 2009
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Test::More tests => 6;
use Test::Output;

use 5.006;
our $VERSION = '1.9.8';

## no critic (ProhibitMagicNumbers))
## no critic (ProhibitImplicitNewlines))
## no critic (RequireLocalizedPunctuationVars)
## no critic (ProtectPrivateVars)

use Getopt::Auto( { 'test' => 1 } );

BEGIN {
    stderr_is(
        sub { import Getopt::Auto(123) },
        'Getopt::Auto: Must be use-d with: no args, an HASH ref or an ARRAY ref
', 'Getopt::Auto with int'
    );
    stderr_is(
        sub { import Getopt::Auto( [123] ) },
        'Getopt::Auto: Option specification 123 must be a reference
', 'Getopt::Auto with annon array'
    );
    stderr_is(
        sub { import Getopt::Auto( [ [123] ] ) },
        'Getopt::Auto: Option list is incompletly specified
', 'Getopt::Auto with short array'
    );
    stderr_is(
        sub { import Getopt::Auto( { foo => 1 } ) },
        'Getopt::Auto: Option \'foo\' is unknown
', 'Getopt::Auto with bad configuration option'
    );
}

@ARGV = qw{--abc -abc };
stderr_is(
    \&Getopt::Auto::_parse_args,
    qq{Getopt::Auto: --abc is not a registered option\n}
        . qq{Getopt::Auto: -a (from -abc) is not a registered option\n}
        . qq{Getopt::Auto: -c (from -abc) is not a registered option\n},
    'Option errors'
);

@ARGV = qw{ -b=2 };
stderr_is( \&Getopt::Auto::_parse_args,
    qq{Getopt::Auto: To use -b with "=", a subroutine must be provided\n},
    'Arg = error' );

exit 0;

__END__

=pod

=head2 -b - 

