#!perl
#===============================================================================
#
# t/cryptfile-leaktest.pl
#
# DESCRIPTION
#   Test script to check for leaks in the crypt_file() function.
#
#   This file is intentionally named so as not to be included in the main test
#   suite when running "make test" or equivalent because it is not easy for it
#   to determine for itself if it is leaking, nor to say how long it should be
#   run for to be sure.
#
#   Instead, users should manually run this test by typing:
#
#       perl -Mblib t/cryptfile-leaktest.pl
#
#   from the top-level directory.
#
# COPYRIGHT
#   Copyright (C) 2004-2006, 2014 Steve Hay.  All rights reserved.
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

use Cwd qw(abs_path);
use Fcntl qw(:seek);
use File::Spec::Functions qw(canonpath catdir catfile updir);
use FindBin qw($Bin);

#===============================================================================
# INITIALIZATION
#===============================================================================

BEGIN {
    my $top_dir = canonpath(abs_path(catdir($Bin, updir())));
    my $lib_dir = catfile($top_dir, 'blib', 'lib', 'Filter', 'Crypto');

    if (-f catfile($lib_dir, 'CryptFile.pm')) {
        require Filter::Crypto::CryptFile;
        Filter::Crypto::CryptFile->import();
    }
    else {
        die "CryptFile component not built!\n";
    }
}

#===============================================================================
# MAIN PROGRAM
#===============================================================================

MAIN: {
    my $file = 'test.pl';
    my $prog = qq[print "Hello, world.\\n";\n];

    my($fh, $interrupted, $i);

    open $fh, '>', $file or die "Can't create file '$file': $!\n";
    print $fh $prog;
    close $fh;

    print "Running crypt_file() indefinitely.\n" .
          "Watch your memory usage (PID $$), and press Ctrl+C to quit.\n" .
          "Press RETURN to begin...\n";
    <STDIN>;

    $interrupted = 0;

    $SIG{INT} = sub {
        print "Caught SIGINT. Terminating.\n";
        # Do not exit here because crypt_file() could have the file open, and we
        # cannot delete an open file on Win32.
        $interrupted = 1;
    };

    for ($i = 1; 1; $i++) {
        print "$i\n";
        crypt_file($file) or die "crypt_file() failed\n";
        if ($interrupted) {
            unlink $file or die "Can't delete file '$file': $!\n";
            exit;
        }
    }
}

#===============================================================================
