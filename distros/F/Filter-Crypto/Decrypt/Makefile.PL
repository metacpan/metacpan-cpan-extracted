#!perl
#===============================================================================
#
# Decrypt/Makefile.PL
#
# DESCRIPTION
#   Makefile creation script.
#
# COPYRIGHT
#   Copyright (C) 2004, 2006, 2014 Steve Hay.  All rights reserved.
#
# LICENCE
#   This script is free software; you can redistribute it and/or modify it under
#   the same terms as Perl itself, i.e. under the terms of either the GNU
#   General Public License or the Artistic License, as specified in the LICENCE
#   file.
#
#===============================================================================

use 5.008001;

use strict;
use warnings;

use ExtUtils::MakeMaker 6.66;
use ExtUtils::MakeMaker qw(WriteMakefile);
use File::Spec::Functions qw(catfile updir);

#===============================================================================
# MAIN PROGRAM
#===============================================================================

MAIN: {
    my $config_h  = catfile(updir(), 'CipherConfig.h');
    my $common_c  = catfile(updir(), 'CryptoCommon-c.inc');
    my $common_xs = catfile(updir(), 'CryptoCommon-xs.inc');

    WriteMakefile(
        NAME         => 'Filter::Crypto::Decrypt',
        VERSION_FROM => 'lib/Filter/Crypto/Decrypt.pm',

        DEFINE       => $ENV{__SHAY_PRIVATE_DEFINE},
        INC          => $ENV{__SHAY_PRIVATE_INC},
        LIBS         => $ENV{__SHAY_PRIVATE_LIBS},

        depend => {
            '$(C_FILES)' => "$config_h $common_c $common_xs"
        }
    );
}

#===============================================================================
