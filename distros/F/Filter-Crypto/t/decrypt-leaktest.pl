#!perl
#===============================================================================
#
# t/decrypt-leaktest.pl
#
# DESCRIPTION
#   Test script to check for leaks in the decryption filter.
#
#   This file is intentionally named so as not to be included in the main test
#   suite when running "make test" or equivalent because it is not easy for it
#   to determine for itself if it is leaking, nor to say how long it should be
#   run for to be sure.
#
#   Instead, users should manually run this test by typing:
#
#       perl -Mblib t/decrypt-leaktest.pl
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

    unless (-f catfile($lib_dir, 'Decrypt.pm')) {
        die "Decrypt component not built!\n";
    }
}

#===============================================================================
# MAIN PROGRAM
#===============================================================================

MAIN: {
    # Test both a syntactically correct script (for which the decryption filter
    # should complete successfully) and a syntactically incorrect script (for
    # which the decryption filter should fail part-way through).
    my $file1 = 'test1.pl';
    my $prog1 = qq[my \$str = "Hello, world.\\n";\n1;\n];
    my $file2 = 'test2.pl';
    my $prog2 = qq[my \$str = "Hello, world.\\n;\n1;\n];

    my($fh, $interrupted, $i);

    open $fh, '>', $file1 or die "Can't create file '$file1': $!\n";
    print $fh $prog1;
    close $fh;

    open $fh, '>', $file2 or die "Can't create file '$file2': $!\n";
    print $fh $prog2;
    close $fh;

    crypt_file($file1) or die "crypt_file($file1) failed\n";
    crypt_file($file2) or die "crypt_file($file2) failed\n";

    print "Running decryption filter indefinitely.\n" .
          "Watch your memory usage (PID $$), and press Ctrl+C to quit.\n" .
          "Press RETURN to begin...\n";
    <STDIN>;

    $interrupted = 0;

    $SIG{INT} = sub {
        print "Caught SIGINT. Terminating.\n";
        # Do not exit here because require() could have the file open, and we
        # cannot delete an open file on Win32.
        $interrupted = 1;
    };

    for ($i = 1; 1; $i++) {
        print "$i\n";
        require $file1;
        if ($interrupted) {
            unlink $file1 or die "Can't delete file '$file1': $!\n";
            unlink $file2 or die "Can't delete file '$file2': $!\n";
            exit;
        }
        delete $INC{$file1};
        eval { require $file2 };
        if ($interrupted) {
            unlink $file1 or die "Can't delete file '$file1': $!\n";
            unlink $file2 or die "Can't delete file '$file2': $!\n";
            exit;
        }
        delete $INC{$file2};
    }
}

#===============================================================================
