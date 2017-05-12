#!perl
#===============================================================================
#
# t/05_errstr.t
#
# DESCRIPTION
#   Test script to check $ErrStr variable in Filter::Crypto::CryptFile.
#
# COPYRIGHT
#   Copyright (C) 2004-2006, 2014 Steve Hay.  All rights reserved.
#
# LICENCE
#   You may distribute under the terms of either the GNU General Public License
#   or the Artistic License, as specified in the LICENCE file.
#
#===============================================================================

use 5.008001;

use strict;
use warnings;

use Cwd qw(abs_path);
use File::Spec::Functions qw(canonpath catdir catfile updir);
use FindBin qw($Bin);
use Test::More;

#===============================================================================
# INITIALIZATION
#===============================================================================

my($top_dir);
our($ErrStr);

BEGIN {
    $top_dir = canonpath(abs_path(catdir($Bin, updir())));
    my $lib_dir = catfile($top_dir, 'blib', 'lib', 'Filter', 'Crypto');

    if (-f catfile($lib_dir, 'CryptFile.pm')) {
        require Filter::Crypto::CryptFile;
        Filter::Crypto::CryptFile->import(qw(:DEFAULT $ErrStr));
        plan tests => 4;
    }
    else {
        plan skip_all => 'CryptFile component not built';
    }

}

#===============================================================================
# MAIN PROGRAM
#===============================================================================

MAIN: {
    my $iofile = 'test.pl';

    my $crypt_file = catfile($top_dir, 'blib', 'script', 'crypt_file');

    my $fh;

    open $fh, '>', $iofile;
    close $fh;

    crypt_file($iofile, CRYPT_MODE_DECRYPTED());
    is($ErrStr, 'Input data was already decrypted',
       '$ErrStr is set correctly when crypt_file() skips decryption');

    crypt_file($iofile);
    is($ErrStr, '',
       '$ErrStr is blank when crypt_file() succeeds');

    crypt_file($iofile, CRYPT_MODE_ENCRYPTED());
    is($ErrStr, 'Input data was already encrypted',
       '$ErrStr is set correctly when crypt_file() skips encryption');

    unlink $iofile;

    crypt_file($iofile);
    like($ErrStr, qr/^Can't open file '\Q$iofile\E'/o,
         '$ErrStr is set correctly when crypt_file() fails');
}

#===============================================================================
