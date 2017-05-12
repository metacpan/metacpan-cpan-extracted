#!perl
#===============================================================================
#
# t/02_function.t
#
# DESCRIPTION
#   Test script to check crypt_file() function (and decryption filter).
#
# COPYRIGHT
#   Copyright (C) 2004-2006, 2009, 2014 Steve Hay.  All rights reserved.
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

## no critic (Subroutines::ProhibitSubroutinePrototypes)

sub new_ifilename();
sub new_ofilename();

#===============================================================================
# INITIALIZATION
#===============================================================================

my($have_decrypt);

BEGIN {
    my $i = 0;
    sub new_ifilename() {
        $i++;
        return "test$i.pl";
    }
    my $j = 0;
    sub new_ofilename() {
        $j++;
        return "test$j.enc.pl";
    }

    my $top_dir = canonpath(abs_path(catdir($Bin, updir())));
    my $lib_dir = catfile($top_dir, 'blib', 'lib', 'Filter', 'Crypto');

    if (-f catfile($lib_dir, 'CryptFile.pm')) {
        require Filter::Crypto::CryptFile;
        Filter::Crypto::CryptFile->import(qw(:DEFAULT $ErrStr));
        plan tests => 295;
    }
    else {
        plan skip_all => 'CryptFile component not built';
    }

    $have_decrypt = -f catfile($lib_dir, 'Decrypt.pm');
}

#===============================================================================
# MAIN PROGRAM
#===============================================================================

MAIN: {
    my $script = 'foo.pl';
    my $module = 'Foo.pm';
    my $str    = 'Hello, world.';
    my $prog   = qq[print "$str\\n";\n];
    my $scrsrc = qq[use Carp;\nuse Foo;\nFoo::foo();\n];
    my $modsrc = qq[package Foo;\nsub foo() { print "$str\\n" }\n1;\n];
    my $head   = 'use Filter::Crypto::Decrypt;';
    my $qrhead = qr/^\Q$head\E/o;
    my $buf    = '';

    my $perl_exe = $^X =~ / /o ? qq["$^X"] : $^X;
    my $perl = qq[$perl_exe -Mblib];

    my($ifile, $ofile, $iofile);
    my($fh, $ifh, $ofh, $iofh, $contents, $saved_contents, $line, $i, $n);

    {
        $ifile = new_ifilename();
        $iofile = $ifile;

        open $fh, '>', $ifile or die "Can't create file '$ifile': $!\n";
        print $fh $prog;
        close $fh;

        open $iofh, '+<', $iofile or die "Can't update file '$iofile': $!\n";
        binmode $iofh;
        ok(crypt_file($iofh), 'crypt_file($fh) returned OK') or
            diag("\$ErrStr = '$ErrStr'");
        close $iofh;

        open $fh, '<', $iofile or die "Can't read file '$iofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        like($contents, $qrhead, '... and encrypted file OK');

        SKIP: {
            skip 'Decrypt component not built', 1 unless $have_decrypt;
            chomp($line = qx{$perl $iofile});
            is($line, $str, '... and encrypted file runs OK');
        }

        ok(crypt_file($iofile), 'crypt_file($file) returned OK') or
            diag("\$ErrStr = '$ErrStr'");

        open $fh, '<', $iofile or die "Can't read file '$iofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        is($contents, $prog, '... and decrypted file OK');

        chomp($line = qx{$perl $iofile});
        is($line, $str, '... and decrypted file runs OK');

        open $iofh, '+<', $iofile or die "Can't update file '$iofile': $!\n";
        binmode $iofh;
        ok(crypt_file($iofh, CRYPT_MODE_AUTO()),
           'crypt_file($fh, CRYPT_MODE_AUTO) returned OK') or
           diag("\$ErrStr = '$ErrStr'");
        close $iofh;

        open $fh, '<', $iofile or die "Can't read file '$iofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        like($contents, $qrhead, '... and encrypted file OK');

        SKIP: {
            skip 'Decrypt component not built', 1 unless $have_decrypt;
            chomp($line = qx{$perl $iofile});
            is($line, $str, '... and encrypted file runs OK');
        }

        ok(crypt_file($iofile, CRYPT_MODE_AUTO()),
           'crypt_file($file, CRYPT_MODE_AUTO) returned OK') or
           diag("\$ErrStr = '$ErrStr'");

        open $fh, '<', $iofile or die "Can't read file '$iofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        is($contents, $prog, '... and decrypted file OK');

        chomp($line = qx{$perl $iofile});
        is($line, $str, '... and decrypted file runs OK');

        open $iofh, '+<', $iofile or die "Can't update file '$iofile': $!\n";
        binmode $iofh;
        ok(crypt_file($iofh, CRYPT_MODE_ENCRYPT()),
           'crypt_file($fh, CRYPT_MODE_ENCRYPT) returned OK') or
           diag("\$ErrStr = '$ErrStr'");
        close $iofh;

        open $fh, '<', $iofile or die "Can't read file '$iofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        like($contents, $qrhead, '... and encrypted file OK');

        SKIP: {
            skip 'Decrypt component not built', 1 unless $have_decrypt;
            chomp($line = qx{$perl $iofile});
            is($line, $str, '... and encrypted file runs OK');
        }

        $saved_contents = $contents;

        open $iofh, '+<', $iofile or die "Can't update file '$iofile': $!\n";
        binmode $iofh;
        ok(crypt_file($iofh, CRYPT_MODE_ENCRYPTED()),
           'crypt_file($fh, CRYPT_MODE_ENCRYPTED) returned OK') or
           diag("\$ErrStr = '$ErrStr'");
        close $iofh;

        open $fh, '<', $iofile or die "Can't read file '$iofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        is($contents, $saved_contents, '... and left file encrypted');

        SKIP: {
            skip 'Decrypt component not built', 1 unless $have_decrypt;
            chomp($line = qx{$perl $iofile});
            is($line, $str, '... and encrypted file still runs OK');
        }

        ok(crypt_file($iofile, CRYPT_MODE_DECRYPT()),
           'crypt_file($file, CRYPT_MODE_DECRYPT) returned OK') or
           diag("\$ErrStr = '$ErrStr'");

        open $fh, '<', $iofile or die "Can't read file '$iofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        is($contents, $prog, '... and decrypted file OK');

        chomp($line = qx{$perl $iofile});
        is($line, $str, '... and decrypted file runs OK');

        ok(crypt_file($iofile, CRYPT_MODE_DECRYPTED()),
           'crypt_file($file, CRYPT_MODE_DECRYPTED) returned OK') or
           diag("\$ErrStr = '$ErrStr'");

        open $fh, '<', $iofile or die "Can't read file '$iofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        is($contents, $prog, '... and left file decrypted');

        chomp($line = qx{$perl $iofile});
        is($line, $str, '... and decrypted file still runs OK');

        $ofile = new_ofilename();

        open $ifh, '<', $ifile or die "Can't read file '$ifile': $!\n";
        binmode $ifh;
        open $ofh, '>', $ofile or die "Can't write file '$ofile': $!\n";
        binmode $ofh;
        ok(crypt_file($ifh, $ofh), 'crypt_file($fh1, $fh2) returned OK') or
            diag("\$ErrStr = '$ErrStr'");
        close $ofh;
        close $ifh;

        open $fh, '<', $ifile or die "Can't read file '$ifile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        is($contents, $prog, '... and left input file unencrypted');
        open $fh, '<', $ofile or die "Can't read file '$ofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        like($contents, $qrhead, '... and encrypted output file OK');

        SKIP: {
            skip 'Decrypt component not built', 1 unless $have_decrypt;
            chomp($line = qx{$perl $ofile});
            is($line, $str, '... and encrypted output file runs OK');
        }

        unlink $ifile;
        $ifile = new_ifilename();

        open $ofh, '<', $ofile or die "Can't read file '$ofile': $!\n";
        binmode $ofh;
        ok(crypt_file($ofh, $ifile), 'crypt_file($fh, $file) returned OK') or
            diag("\$ErrStr = '$ErrStr'");
        close $ofh;

        open $fh, '<', $ofile or die "Can't read file '$ofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        like($contents, $qrhead, '... and left input file encrypted');
        open $fh, '<', $ifile or die "Can't read file '$ifile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        is($contents, $prog, '... and decrypted output file OK');

        chomp($line = qx{$perl $ifile});
        is($line, $str, '... and decrypted output file runs OK');

        unlink $ofile;
        $ofile = new_ofilename();

        open $ofh, '>', $ofile or die "Can't write file '$ofile': $!\n";
        binmode $ofh;
        ok(crypt_file($ifile, $ofh), 'crypt_file($file, $fh) returned OK') or
            diag("\$ErrStr = '$ErrStr'");
        close $ofh;

        open $fh, '<', $ifile or die "Can't read file '$ifile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        is($contents, $prog, '... and left input file unencrypted');
        open $fh, '<', $ofile or die "Can't read file '$ofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        like($contents, $qrhead, '... and encrypted output file OK');

        SKIP: {
            skip 'Decrypt component not built', 1 unless $have_decrypt;
            chomp($line = qx{$perl $ofile});
            is($line, $str, '... and encrypted output file runs OK');
        }

        unlink $ifile;
        $ifile = new_ifilename();

        ok(crypt_file($ofile, $ifile), 'crypt_file($file1, $file2) returned OK') or
            diag("\$ErrStr = '$ErrStr'");

        open $fh, '<', $ofile or die "Can't read file '$ofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        like($contents, $qrhead, '... and left input file encrypted');
        open $fh, '<', $ifile or die "Can't read file '$ifile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        is($contents, $prog, '... and decrypted output file OK');

        chomp($line = qx{$perl $ifile});
        is($line, $str, '... and decrypted output file runs OK');

        unlink $ofile;
        $ofile = new_ofilename();

        open $ifh, '<', $ifile or die "Can't read file '$ifile': $!\n";
        binmode $ifh;
        open $ofh, '>', $ofile or die "Can't write file '$ofile': $!\n";
        binmode $ofh;
        ok(crypt_file($ifh, $ofh, CRYPT_MODE_AUTO()),
           'crypt_file($fh1, $fh2, CRYPT_MODE_AUTO) returned OK') or
           diag("\$ErrStr = '$ErrStr'");
        close $ofh;
        close $ifh;

        open $fh, '<', $ifile or die "Can't read file '$ifile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        is($contents, $prog, '... and left input file unencrypted');
        open $fh, '<', $ofile or die "Can't read file '$ofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        like($contents, $qrhead, '... and encrypted output file OK');

        SKIP: {
            skip 'Decrypt component not built', 1 unless $have_decrypt;
            chomp($line = qx{$perl $ofile});
            is($line, $str, '... and encrypted output file runs OK');
        }

        unlink $ifile;
        $ifile = new_ifilename();

        open $ofh, '<', $ofile or die "Can't read file '$ofile': $!\n";
        binmode $ofh;
        ok(crypt_file($ofh, $ifile, CRYPT_MODE_AUTO()),
           'crypt_file($fh, $file, CRYPT_MODE_AUTO) returned OK') or
           diag("\$ErrStr = '$ErrStr'");
        close $ofh;

        open $fh, '<', $ofile or die "Can't read file '$ofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        like($contents, $qrhead, '... and left input file encrypted');
        open $fh, '<', $ifile or die "Can't read file '$ifile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        is($contents, $prog, '... and decrypted output file OK');

        chomp($line = qx{$perl $ifile});
        is($line, $str, '... and decrypted output file runs OK');

        unlink $ofile;
        $ofile = new_ofilename();

        open $ofh, '>', $ofile or die "Can't write file '$ofile': $!\n";
        binmode $ofh;
        ok(crypt_file($ifile, $ofh, CRYPT_MODE_AUTO()),
           'crypt_file($file, $fh, CRYPT_MODE_AUTO) returned OK') or
           diag("\$ErrStr = '$ErrStr'");
        close $ofh;

        open $fh, '<', $ifile or die "Can't read file '$ifile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        is($contents, $prog, '... and left input file unencrypted');
        open $fh, '<', $ofile or die "Can't read file '$ofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        like($contents, $qrhead, '... and encrypted output file OK');

        SKIP: {
            skip 'Decrypt component not built', 1 unless $have_decrypt;
            chomp($line = qx{$perl $ofile});
            is($line, $str, '... and encrypted output file runs OK');
        }

        unlink $ifile;
        $ifile = new_ifilename();

        ok(crypt_file($ofile, $ifile, CRYPT_MODE_AUTO()),
           'crypt_file($file1, $file2, CRYPT_MODE_AUTO) returned OK') or
           diag("\$ErrStr = '$ErrStr'");
        close $ofh;

        open $fh, '<', $ofile or die "Can't read file '$ofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        like($contents, $qrhead, '... and left input file encrypted');
        open $fh, '<', $ifile or die "Can't read file '$ifile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        is($contents, $prog, '... and decrypted output file OK');

        chomp($line = qx{$perl $ifile});
        is($line, $str, '... and decrypted output file runs OK');

        unlink $ofile;
        $ofile = new_ofilename();

        open $ifh, '<', $ifile or die "Can't read file '$ifile': $!\n";
        binmode $ifh;
        open $ofh, '>', $ofile or die "Can't write file '$ofile': $!\n";
        binmode $ofh;
        ok(crypt_file($ifh, $ofh, CRYPT_MODE_ENCRYPT()),
           'crypt_file($fh1, $fh2, CRYPT_MODE_ENCRYPT) returned OK') or
           diag("\$ErrStr = '$ErrStr'");
        close $ofh;
        close $ifh;

        open $fh, '<', $ifile or die "Can't read file '$ifile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        is($contents, $prog, '... and left intput file unencrypted');
        open $fh, '<', $ofile or die "Can't read file '$ofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        like($contents, $qrhead, '... and encrypted output file OK');

        SKIP: {
            skip 'Decrypt component not built', 1 unless $have_decrypt;
            chomp($line = qx{$perl $ofile});
            is($line, $str, '... and encrypted output file runs OK');
        }

        unlink $ofile;
        $ofile = new_ofilename();

        open $ifh, '<', $ifile or die "Can't read file '$ifile': $!\n";
        binmode $ifh;
        open $ofh, '>', $ofile or die "Can't write file '$ofile': $!\n";
        binmode $ofh;
        ok(crypt_file($ifh, $ofh, CRYPT_MODE_ENCRYPTED()),
           'crypt_file($fh1, $fh2, CRYPT_MODE_ENCRYPTED) returned OK') or
           diag("\$ErrStr = '$ErrStr'");
        close $ofh;
        close $ifh;

        open $fh, '<', $ifile or die "Can't read file '$ifile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        is($contents, $prog, '... and left input file unencrypted');
        open $fh, '<', $ofile or die "Can't read file '$ofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        like($contents, $qrhead, '... and encrypted output file OK');

        SKIP: {
            skip 'Decrypt component not built', 1 unless $have_decrypt;
            chomp($line = qx{$perl $ofile});
            is($line, $str, '... and encrypted output file runs OK');
        }

        unlink $ifile;
        $ifile = new_ifilename();

        open $ofh, '<', $ofile or die "Can't read file '$ofile': $!\n";
        binmode $ofh;
        ok(crypt_file($ofh, $ifile, CRYPT_MODE_DECRYPT()),
           'crypt_file($fh, $file, CRYPT_MODE_DECRYPT) returned OK') or
           diag("\$ErrStr = '$ErrStr'");
        close $ofh;

        open $fh, '<', $ofile or die "Can't read file '$ofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        like($contents, $qrhead, '... and left intput file encrypted');
        open $fh, '<', $ifile or die "Can't read file '$ifile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        is($contents, $prog, '... and decrypted output file OK');

        chomp($line = qx{$perl $ifile});
        is($line, $str, '... and decrypted output file runs OK');

        unlink $ifile;
        $ifile = new_ifilename();

        open $ofh, '<', $ofile or die "Can't read file '$ofile': $!\n";
        binmode $ofh;
        ok(crypt_file($ofh, $ifile, CRYPT_MODE_DECRYPTED()),
           'crypt_file($fh, $file, CRYPT_MODE_DECRYPTED) returned OK') or
           diag("\$ErrStr = '$ErrStr'");
        close $ofh;

        open $fh, '<', $ofile or die "Can't read file '$ofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        like($contents, $qrhead, '... and left input file encrypted');
        open $fh, '<', $ifile or die "Can't read file '$ifile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        is($contents, $prog, '... and decrypted output file OK');

        chomp($line = qx{$perl $ifile});
        is($line, $str, '... and decrypted output file runs OK');

        unlink $ofile;
        $ofile = new_ofilename();

        open $ofh, '>', $ofile or die "Can't write file '$ofile': $!\n";
        binmode $ofh;
        ok(crypt_file($ifile, $ofh, CRYPT_MODE_ENCRYPT()),
           'crypt_file($file, $fh, CRYPT_MODE_ENCRYPT) returned OK') or
           diag("\$ErrStr = '$ErrStr'");
        close $ofh;

        open $fh, '<', $ifile or die "Can't read file '$ifile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        is($contents, $prog, '... and left input file unencrypted');
        open $fh, '<', $ofile or die "Can't read file '$ofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        like($contents, $qrhead, '... and encrypted output file OK');

        SKIP: {
            skip 'Decrypt component not built', 1 unless $have_decrypt;
            chomp($line = qx{$perl $ofile});
            is($line, $str, '... and encrypted output file runs OK');
        }

        unlink $ofile;
        $ofile = new_ofilename();

        open $ofh, '>', $ofile or die "Can't write file '$ofile': $!\n";
        binmode $ofh;
        ok(crypt_file($ifile, $ofh, CRYPT_MODE_ENCRYPTED()),
           'crypt_file($file, $fh, CRYPT_MODE_ENCRYPTED) returned OK') or
           diag("\$ErrStr = '$ErrStr'");
        close $ofh;

        open $fh, '<', $ifile or die "Can't read file '$ifile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        is($contents, $prog, '... and left input file unencrypted');
        open $fh, '<', $ofile or die "Can't read file '$ofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        like($contents, $qrhead, '... and encrypted output file OK');

        SKIP: {
            skip 'Decrypt component not built', 1 unless $have_decrypt;
            chomp($line = qx{$perl $ofile});
            is($line, $str, '... and encrypted output file runs OK');
        }

        unlink $ifile;
        $ifile = new_ifilename();

        ok(crypt_file($ofile, $ifile, CRYPT_MODE_DECRYPT()),
           'crypt_file($file1, $file2, CRYPT_MODE_DECRYPT) returned OK') or
           diag("\$ErrStr = '$ErrStr'");
        close $ofh;

        open $fh, '<', $ofile or die "Can't read file '$ofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        like($contents, $qrhead, '... and left input file encrypted');
        open $fh, '<', $ifile or die "Can't read file '$ifile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        is($contents, $prog, '... and decrypted output file OK');

        chomp($line = qx{$perl $ifile});
        is($line, $str, '... and decrypted output file runs OK');

        unlink $ifile;
        $ifile = new_ifilename();

        ok(crypt_file($ofile, $ifile, CRYPT_MODE_DECRYPTED()),
           'crypt_file($file1, $file2, CRYPT_MODE_DECRYPTED) returned OK') or
           diag("\$ErrStr = '$ErrStr'");
        close $ofh;

        open $fh, '<', $ofile or die "Can't read file '$ofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        like($contents, $qrhead, '... and left input file encrypted');
        open $fh, '<', $ifile or die "Can't read file '$ifile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        is($contents, $prog, '... and decrypted output file OK');

        SKIP: {
            skip 'Decrypt component not built', 1 unless $have_decrypt;
            chomp($line = qx{$perl $ifile});
            is($line, $str, '... and decrypted output file runs OK');
        }

        unlink $ifile;
        unlink $ofile;
    }

    {
        $iofile = new_ifilename();

        $prog =~ s/\n$//o;
        open $fh, '>', $iofile or die "Can't create file '$iofile': $!\n";
        print $fh $prog;
        close $fh;

        ok(crypt_file($iofile), 'file without newline at EOF: OK') or
           diag("\$ErrStr = '$ErrStr'");

        open $fh, '<', $iofile or die "Can't read file '$iofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        like($contents, $qrhead, '... and file encrypted OK');

        SKIP: {
            skip 'Decrypt component not built', 1 unless $have_decrypt;
            chomp($line = qx{$perl $iofile});
            is($line, $str, '... and encrypted file runs OK');
        }

        for ($i = 1; $i <= 16; $i++) {
            open $fh, '>', $iofile or die "Can't create file '$iofile': $!\n";
            binmode $fh;
            print $fh +(';' x ($i - 1)) . "\n";
            close $fh;

            ok(crypt_file($iofile), "$i byte file with newline at EOF: OK") or
                diag("\$ErrStr = '$ErrStr'");

            open $fh, '<', $iofile or die "Can't read file '$iofile': $!\n";
            $contents = do { local $/; <$fh> };
            close $fh;
            like($contents, $qrhead, '... and file encrypted OK');

            SKIP: {
                skip 'Decrypt component not built', 1 unless $have_decrypt;
                chomp($line = qx{$perl $iofile});
                is($line, '', '... and encrypted file runs OK');
            }
        }

        for ($i = 1; $i <= 16; $i++) {
            open $fh, '>', $iofile or die "Can't create file '$iofile': $!\n";
            print $fh ';' x $i;
            close $fh;

            ok(crypt_file($iofile), "$i byte file without newline at EOF: OK") or
                diag("\$ErrStr = '$ErrStr'");

            open $fh, '<', $iofile or die "Can't read file '$iofile': $!\n";
            $contents = do { local $/; <$fh> };
            close $fh;
            like($contents, $qrhead, '... and file encrypted OK');

            SKIP: {
                skip 'Decrypt component not built', 1 unless $have_decrypt;
                chomp($line = qx{$perl $iofile});
                is($line, '', '... and encrypted file runs OK');
            }
        }

        for ($i = 1; $i <= 16; $i++) {
            $buf = ';' x $i;
            open $fh, '>', $iofile or die "Can't create file '$iofile': $!\n";
            print $fh qq[print "$buf";\n];
            close $fh;

            $n = -s $iofile;
            ok(crypt_file($iofile), "$n byte file with newline at EOF: OK") or
                diag("\$ErrStr = '$ErrStr'");

            open $fh, '<', $iofile or die "Can't read file '$iofile': $!\n";
            $contents = do { local $/; <$fh> };
            close $fh;
            like($contents, $qrhead, '... and file encrypted OK');

            SKIP: {
                skip 'Decrypt component not built', 1 unless $have_decrypt;
                chomp($line = qx{$perl $iofile});
                is($line, $buf, '... and encrypted file runs OK');
            }
        }

        for ($i = 1; $i <= 16; $i++) {
            $buf = ';' x $i;
            open $fh, '>', $iofile or die "Can't create file '$iofile': $!\n";
            print $fh qq[print "$buf";];
            close $fh;

            $n = -s $iofile;
            ok(crypt_file($iofile), "$n byte file without newline at EOF: OK") or
                diag("\$ErrStr = '$ErrStr'");

            open $fh, '<', $iofile or die "Can't read file '$iofile': $!\n";
            $contents = do { local $/; <$fh> };
            close $fh;
            like($contents, $qrhead, '... and file encrypted OK');

                SKIP: {
                skip 'Decrypt component not built', 1 unless $have_decrypt;
                chomp($line = qx{$perl $iofile});
                is($line, $buf, '... and encrypted file runs OK');
            }
        }

        $buf = ';' x 4096;
        open $fh, '>', $iofile or die "Can't create file '$iofile': $!\n";
        print $fh qq[print "$buf";\n];
        close $fh;

        $n = -s $iofile;
        ok(crypt_file($iofile), "$n byte file with newline at EOF: OK") or
            diag("\$ErrStr = '$ErrStr'");

        open $fh, '<', $iofile or die "Can't read file '$iofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        like($contents, $qrhead, '... and file encrypted OK');

        SKIP: {
            skip 'Decrypt component not built', 1 unless $have_decrypt;
            chomp($line = qx{$perl $iofile});
            is($line, $buf, '... and encrypted file runs OK');
        }

        $buf = ';' x 4096;
        open $fh, '>', $iofile or die "Can't create file '$iofile': $!\n";
        print $fh qq[print "$buf";];
        close $fh;

        $n = -s $iofile;
        ok(crypt_file($iofile), "$n byte file without newline at EOF: OK") or
            diag("\$ErrStr = '$ErrStr'");

        open $fh, '<', $iofile or die "Can't read file '$iofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        like($contents, $qrhead, '... and file encrypted OK');

        SKIP: {
            skip 'Decrypt component not built', 1 unless $have_decrypt;
            chomp($line = qx{$perl $iofile});
            is($line, $buf, '... and encrypted file runs OK');
        }

        open $fh, '>', $iofile or die "Can't create file '$iofile': $!\n";
        print $fh $prog;
        close $fh;
    
        ok(crypt_file($iofile), 'crypt_file($file) returned OK') or
            diag("\$ErrStr = '$ErrStr'");
    
        open $fh, '<', $iofile or die "Can't read file '$iofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        like($contents, $qrhead, '... and file encrypted OK');
    
        SKIP: {
            skip 'Decrypt component not built', 1 unless $have_decrypt;
            chomp($line = qx{$perl -MCarp $iofile});
            is($line, $str, '... and encrypted file runs OK with Carp loaded');
        }

        unlink $iofile;
    }

    {
        open $fh, '>', $script or die "Can't create file '$script': $!\n";
        print $fh $scrsrc;
        close $fh;
    
        open $fh, '>', $module or die "Can't create file '$module': $!\n";
        print $fh $modsrc;
        close $fh;
    
        ok(crypt_file($module), 'crypt_file($file) returned OK') or
            diag("\$ErrStr = '$ErrStr'");
    
        open $fh, '<', $module or die "Can't read file '$module': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        like($contents, $qrhead, '... and module encrypted OK');
    
        SKIP: {
            skip 'Decrypt component not built', 1 unless $have_decrypt;
            chomp($line = qx{$perl $script});
            is($line, $str, '... and encrypted module runs OK with Carp loaded');
        }

        unlink $script;
        unlink $module;
    }
}

#===============================================================================
