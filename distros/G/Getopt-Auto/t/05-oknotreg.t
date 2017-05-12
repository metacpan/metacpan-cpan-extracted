#! /usr/bin/perl

#  Copyright (C) 2010, Geoffrey Leach
#
#===============================================================================
#
#         FILE:  05-options_oknotreg.t
#
#  DESCRIPTION:  Validate the oknotreg option`
#
#       AUTHOR:  Geoffrey Leach (), <geoff@hughes.net>
#      VERSION:  1.9.8
#      CREATED:  Wed Dec  2 13:05:25 PST 2009
#===============================================================================

use strict;
use warnings;

use Test::More tests => 2;
use Test::Output;

use 5.006;
our $VERSION = '1.9.8';

## no critic (RequireLocalizedPunctuationVars)
## no critic (ProhibitPackageVars)
## no critic (ProtectPrivateVars)

use Getopt::Auto( { 'oknotreg' => 1 } );

our %options;
if ( %options ) {}; # Avoid complaints from perl-5.6.2

# Verify not a registered option
@ARGV = qw{ --abc -def};
stderr_isnt(
    \&Getopt::Auto::_parse_args,
    "--abc is not a registered option\n",
    '--abc correctly not reported not a registered option'
);
stderr_isnt(
    \&Getopt::Auto::_parse_args,
    "-def is not a registered option\n",
    '-def correctly not reported not a registered option'
);

exit 0;

__END__

