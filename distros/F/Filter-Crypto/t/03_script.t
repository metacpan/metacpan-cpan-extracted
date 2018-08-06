#!perl
#===============================================================================
#
# t/03_script.t
#
# DESCRIPTION
#   Test script to check crypt_file script (and decryption filter).
#
# COPYRIGHT
#   Copyright (C) 2004-2007, 2009, 2014 Steve Hay.  All rights reserved.
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

use Cwd qw(abs_path cwd);
use File::Copy qw(copy);
use File::Spec::Functions qw(canonpath catdir catfile devnull rel2abs updir);
use File::Temp qw(tempfile);
use FindBin qw($Bin);
use Test::More;

## no critic (Subroutines::ProhibitSubroutinePrototypes)

sub new_ofilename();

#===============================================================================
# INITIALIZATION
#===============================================================================

my($top_dir, $lib_dir);

BEGIN {
    my $i = 0;
    sub new_ofilename() {
        $i++;
        return "test$i.enc.pl";
    }

    $top_dir = canonpath(abs_path(catdir($Bin, updir())));
    $lib_dir = catfile($top_dir, 'blib', 'lib', 'Filter', 'Crypto');

    if (-f catfile($lib_dir, 'CryptFile.pm')) {
        plan tests => 105;
    }
    else {
        plan skip_all => 'CryptFile component not built';
    }
}

#===============================================================================
# MAIN PROGRAM
#===============================================================================

MAIN: {
    my $ifile  = 'test.pl';
    my $iofile = $ifile;
    my $script = 'foo.pl';
    my $module = 'Foo.pm';
    my $bfile  = "$ifile.bak";
    my $lfile  = 'test.lst';
    my $dir1   = 'testdir1';
    my $dir2   = 'testdir2';
    my $cat    = 'cat.pl';
    my $str    = 'Hello, world.';
    my $prog   = qq[print "$str\\n";\n];
    my $scrsrc = qq[use Foo;\nFoo::foo();\n];
    my $modsrc = qq[package Foo;\nsub foo() { print "$str\\n" }\n1;\n];
    my $head   = 'use Filter::Crypto::Decrypt;';
    my $qrhead = qr/^\Q$head\E/o;
    my $q      = $^O eq 'MSWin32' ? '' : "'";
    my $null   = devnull();

    my $perl_exe = $^X =~ / /o ? qq["$^X"] : $^X;
    my $perl = qq[$perl_exe -Mblib];

    my $have_decrypt   = -f catfile($lib_dir, 'Decrypt.pm');

    my $crypt_file = catfile($top_dir, 'blib', 'script', 'crypt_file');

    require Filter::Crypto::CryptFile;
    my $debug_mode = Filter::Crypto::CryptFile::_debug_mode();

    my($fh, $ofile, $contents, $line, $dfile, $rdir, $abs_ifile, $cdir, $ddir);
    my($dir3, $dir4, $dir5, $expected, $file, $data);

    open $fh, '>', $ifile or die "Can't create file '$ifile': $!\n";
    print $fh $prog;
    close $fh;

    open $fh, '>', $lfile or die "Can't create file '$lfile': $!\n";
    print $fh "$ifile\n";
    close $fh;

    open $fh, '>', $script or die "Can't create file '$script': $!\n";
    print $fh $scrsrc;
    close $fh;

    open $fh, '>', $module or die "Can't create file '$module': $!\n";
    print $fh $modsrc;
    close $fh;

    open $fh, '>', $cat or die "Can't create file '$cat': $!\n";
    print $fh "binmode STDIN; binmode STDOUT; print while <>;\n";
    close $fh;

    {
        $ofile = new_ofilename();

        qx{$perl $crypt_file <$ifile >$ofile 2>$null};
        is($?, 0, 'crypt_file ran OK when using STD handle re-directions');

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
    }

    {
        $ofile = new_ofilename();

        qx{$perl $cat <$ifile | $perl $crypt_file - 2>$null | $perl $cat >$ofile};
        is($?, 0, 'crypt_file ran OK when using STD handle pipelines');

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
        unlink $cat;
    }

    {
        $ofile = new_ofilename();

        qx{$perl $crypt_file $ifile >$ofile 2>$null};
        is($?, 0, 'crypt_file ran OK with file spec input');

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
    }

    {
        $ofile = new_ofilename();

        qx{$perl $crypt_file -l $lfile >$ofile 2>$null};
        is($?, 0, 'crypt_file ran OK with -l option');

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
        unlink $lfile;
    }

    {
        $ofile = new_ofilename();

        mkdir $dir1 or die "Can't create directory '$dir1': $!\n";
        copy($ifile, $dir1) or
            die "Can't copy file '$ifile' into directory '$dir1': $!\n";

        qx{$perl $crypt_file -d $dir1 $ifile >$ofile 2>$null};
        is($?, 0, 'crypt_file ran OK with -d option');

        $dfile = catfile($dir1, $ifile);
        open $fh, '<', $dfile or die "Can't read file '$dfile': $!\n";
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

        unlink $dfile;
        unlink $ofile;
    }

    {
        $ofile = new_ofilename();

        $rdir = catdir($dir1, $dir2);
        mkdir $rdir or die "Can't create directory '$rdir': $!\n";
        copy($ifile, $rdir) or
            die "Can't copy file '$ifile' into directory '$rdir': $!\n";

        qx[$perl $crypt_file -d $dir1 -r ${q}test.p?$q >$ofile 2>$null];
        is($?, 0, 'crypt_file ran OK with -r option');

        $dfile = catfile($rdir, $ifile);
        open $fh, '<', $dfile or die "Can't read file '$dfile': $!\n";
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

        unlink $dfile;
        rmdir $rdir;
        rmdir $dir1;
        unlink $ofile;
    }

    {
        $abs_ifile = rel2abs($ifile);
        chomp($data = qx{$perl $crypt_file -t $ifile});
        is($?, 0, 'crypt_file ran OK with -t option');
        is($data, $abs_ifile, '... and output correct file path');

        open $fh, '<', $ifile or die "Can't read file '$ifile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        is($contents, $prog, '... and left input file unencrypted');
    }

    {
        $dir3 = catdir($top_dir, 'lib');
        $dir4 = catdir($dir3, 'Filter');
        $dir5 = catdir($dir3, 'PAR', 'Filter');

        $expected = catdir($dir4, 'Crypto.pm');
        $file = catfile('lib', 'Filter', 'Crypto.pm');
        chomp($data = qx{$perl $crypt_file -d $top_dir -t $file});
        is($data, $expected, '-t works with one -d');
        $file = catfile('Filter', 'Crypto.pm');
        chomp($data = qx{$perl $crypt_file -d $dir3 -t $file});
        is($data, $expected, '-t works with another -d');
        $file = 'Crypto.pm';
        chomp($data = qx{$perl $crypt_file -d $dir4 -t $file});
        is($data, $expected, '-t works with yet another -d');

        $expected = catdir($dir4, $file);
        chomp($data = qx{$perl $crypt_file -d $dir4 -d $dir5 -t $file});
        is($data, $expected, "-t works with two -ds");

        $expected = catdir($dir5, $file);
        chomp($data = qx{$perl $crypt_file -d $dir5 -d $dir4 -t $file});
        is($data, $expected, "-t works with two -ds reversed");

        $expected = catfile($top_dir, 'Makefile.PL') . "\n";
        $data = qx[$perl $crypt_file -d $top_dir -t ${q}Makefil?.PL$q];
        is($data, $expected, '-t works with -d and a glob');
        $data = qx[$perl $crypt_file -d $top_dir -t ${q}Make*.PL$q];
        is($data, $expected, '-t works with -d and another glob');
        $data = qx[$perl $crypt_file -d $top_dir -t ${q}Makefile.[PQR]L$q];
        is($data, $expected, '-t works with -d and yet another glob');

        $expected = join("\n", sort +(
            catfile($top_dir,              'Makefile.PL'),
            catfile($top_dir, 'CryptFile', 'Makefile.PL'),
            catfile($top_dir, 'Decrypt',   'Makefile.PL')
        )) . "\n";
        chomp($data = qx[$perl $crypt_file -d $top_dir -r -t ${q}Makefil?.PL$q]);
        $data = join("\n", sort split /\n/, $data) . "\n";
        is($data, $expected, '-t works with -d, -r and a glob');
        chomp($data = qx[$perl $crypt_file -d $top_dir -r -t ${q}Make*.PL$q]);
        $data = join("\n", sort split /\n/, $data) . "\n";
        is($data, $expected, '-t works with -d, -r and another glob');
        chomp($data = qx[$perl $crypt_file -d $top_dir -r -t ${q}Makefile.[PQR]L$q]);
        $data = join("\n", sort split /\n/, $data) . "\n";
        is($data, $expected, '-t works with -d, -r and yet another glob');

        $dir3 = catdir($top_dir, 'CryptFile');
        $dir4 = catdir($top_dir, 'Decrypt');
        $file = "${q}Make*.PL$q";

        chomp($data = qx{$perl $crypt_file -d $top_dir -d $dir3 -d $dir4 -t $file});
        $data = join("\n", sort split /\n/, $data) . "\n";
        is($data, $expected, "-t works with three -ds and a glob");
        chomp($data = qx{$perl $crypt_file -d $top_dir -d $dir3 -d $dir4 -r -t $file});
        $data = join("\n", sort split /\n/, $data) . "\n";
        is($data, $expected, "-t works with three -ds, -r and a glob");
    }

    {
        $ofile = new_ofilename();

        chomp($line = qx{$perl $crypt_file $ifile 2>&1 1>$ofile});
        is($?, 0, 'crypt_file ran OK without --silent option');
        SKIP: {
            skip 'Built in debug mode', 1 if $debug_mode;
            is($line, "$abs_ifile: OK", '... and output correct file path');
        }

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
    }

    {
        $ofile = new_ofilename();

        chomp($line = qx{$perl $crypt_file --silent $ifile 2>&1 1>$ofile});
        is($?, 0, 'crypt_file ran OK with --silent option');
        SKIP: {
            skip 'Built in debug mode', 1 if $debug_mode;
            is($line, '', "... and didn't output a file path");
        }

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
    }

    {
        qx{$perl $crypt_file -i $iofile 2>$null};
        is($?, 0, 'crypt_file ran OK with -i option');

        open $fh, '<', $iofile or die "Can't read file '$iofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        like($contents, $qrhead, '... and encrypted input file OK');

        SKIP: {
            skip 'Decrypt component not built', 1 unless $have_decrypt;
            chomp($line = qx{$perl $iofile});
            is($line, $str, '... and encrypted input file runs OK');
        }

        qx{$perl $crypt_file -i $iofile 2>$null};
        is($?, 0, 'crypt_file ran OK again with -i option');

        open $fh, '<', $iofile or die "Can't read file '$iofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        is($contents, $prog, '... and decrypted input file OK');

        chomp($line = qx{$perl $iofile});
        is($line, $str, '... and decrypted input file runs OK');
    }

    {
        qx{$perl $crypt_file -i $script 2>$null};
        is($?, 0, 'crypt_file ran OK with unencrypted script + module');

        open $fh, '<', $script or die "Can't read file '$script': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        like($contents, $qrhead, '... and encrypted script OK');

        SKIP: {
            skip 'Decrypt component not built', 1 unless $have_decrypt;
            chomp($line = qx{$perl $script});
            is($line, $str, '... and encrypted script + unencrypted module run OK');
        }

        qx{$perl $crypt_file -i $module 2>$null};
        is($?, 0, 'crypt_file ran OK with unencrypted module');

        open $fh, '<', $module or die "Can't read file '$module': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        like($contents, $qrhead, '... and encrypted module OK');

        SKIP: {
            skip 'Decrypt component not built', 1 unless $have_decrypt;
            chomp($line = qx{$perl $script});
            is($line, $str, '... and encrypted script + encrypted module run OK');
        }

        qx{$perl $crypt_file -i $script 2>$null};
        is($?, 0, 'crypt_file ran OK with encrypted script + module');

        open $fh, '<', $script or die "Can't read file '$script': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        is($contents, $scrsrc, '... and decrypted script OK');

        SKIP: {
            skip 'Decrypt component not built', 1 unless $have_decrypt;
            chomp($line = qx{$perl $script});
            is($line, $str, '... and unencrypted script + encrypted module run OK');
        }

        unlink $script;
        unlink $module;
    }

    {
        qx{$perl $crypt_file -i -e memory $iofile 2>$null};
        is($?, 0, 'crypt_file ran OK with -e memory option');

        open $fh, '<', $iofile or die "Can't read file '$iofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        like($contents, $qrhead, '... and encrypted file OK');

        SKIP: {
            skip 'Decrypt component not built', 1 unless $have_decrypt;
            chomp($line = qx{$perl $iofile});
            is($line, $str, '... and encrypted file runs OK');
        }

        qx{$perl $crypt_file -i -e tempfile $iofile 2>$null};
        is($?, 0, 'crypt_file ran OK with -e tempfile option');

        open $fh, '<', $iofile or die "Can't read file '$iofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        is($contents, $prog, '... and decrypted file OK');
    }

    {
        qx{$perl $crypt_file -i -b $q*.bak$q $iofile 2>$null};
        is($?, 0, 'crypt_file ran OK with -b option');

        open $fh, '<', $bfile or die "Can't read file '$bfile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        is($contents, $prog, '... and created unencrypted backup file');
        open $fh, '<', $iofile or die "Can't read file '$iofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        like($contents, $qrhead, '... and encrypted file OK');

        SKIP: {
            skip 'Decrypt component not built', 1 unless $have_decrypt;
            chomp($line = qx{$perl $iofile});
            is($line, $str, '... and encrypted file runs OK');
        }

        rename $bfile, $iofile;
    }

    {
        ($ofile = $ifile) =~ s/\.(.*?)$/.enc.$1/;

        qx{$perl $crypt_file -o $q?.enc.[$q $ifile 2>$null};
        is($?, 0, 'crypt_file ran OK with -o option');

        open $fh, '<', $ifile or die "Can't read file '$ifile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        is($contents, $prog, '... and left input file unencrypted');
        open $fh, '<', $ofile or die "Can't read file '$ofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        like($contents, $qrhead, '... and created encrypted output file OK');

        SKIP: {
            skip 'Decrypt component not built', 1 unless $have_decrypt;
            chomp($line = qx{$perl $ofile});
            is($line, $str, '... and encrypted output file runs OK');
        }

        unlink $ofile;
    }

    {
        qx{$perl $crypt_file -i -c auto $iofile 2>$null};
        is($?, 0, 'crypt_file ran OK with -c auto option');

        open $fh, '<', $iofile or die "Can't read file '$iofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        like($contents, $qrhead, '... and encrypted file OK');

        SKIP: {
            skip 'Decrypt component not built', 1 unless $have_decrypt;
            chomp($line = qx{$perl $iofile});
            is($line, $str, '... and encrypted file runs OK');
        }

        qx{$perl $crypt_file -i -c auto $iofile 2>$null};
        is($?, 0, 'crypt_file ran OK again with -c auto option');

        open $fh, '<', $iofile or die "Can't read file '$iofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        is($contents, $prog, '... and decrypted file OK');

        chomp($line = qx{$perl $iofile});
        is($line, $str, '... and decrypted file runs OK');

        qx{$perl $crypt_file -i -c encrypt $iofile 2>$null};
        is($?, 0, 'crypt_file ran OK with -c encrypt option');

        open $fh, '<', $iofile or die "Can't read file '$iofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        like($contents, $qrhead, '... and encrypted file OK');

        SKIP: {
            skip 'Decrypt component not built', 1 unless $have_decrypt;
            chomp($line = qx{$perl $iofile});
            is($line, $str, '... and encrypted file runs OK');
        }

        qx{$perl $crypt_file -i -c encrypted $iofile 2>$null};
        is($?, 0, 'crypt_file ran OK with -c encrypted option (working in memory)');

        open $fh, '<', $iofile or die "Can't read file '$iofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        like($contents, $qrhead, '... and left file encrypted');

        SKIP: {
            skip 'Decrypt component not built', 1 unless $have_decrypt;
            chomp($line = qx{$perl $iofile});
            is($line, $str, '... and encrypted file still runs OK');
        }

        qx{$perl $crypt_file -i -e tempfile -c encrypted $iofile 2>$null};
        is($?, 0, 'crypt_file ran OK with -c encrypted option (using a tempfile)');

        open $fh, '<', $iofile or die "Can't read file '$iofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        like($contents, $qrhead, '... and left file encrypted');

        SKIP: {
            skip 'Decrypt component not built', 1 unless $have_decrypt;
            chomp($line = qx{$perl $iofile});
            is($line, $str, '... and encrypted file still runs OK');
        }

        qx{$perl $crypt_file -i -c decrypt $iofile 2>$null};
        is($?, 0, 'crypt_file ran OK with -c decrypt option');

        open $fh, '<', $iofile or die "Can't read file '$iofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        is($contents, $prog, '... and decrypted file OK');

        chomp($line = qx{$perl $iofile});
        is($line, $str, '... and decrypted file runs OK');

        qx{$perl $crypt_file -i -c decrypted $iofile 2>$null};
        is($?, 0, 'crypt_file ran OK with -c decrypted option (working in memory)');

        open $fh, '<', $iofile or die "Can't read file '$iofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        is($contents, $prog, '... and left file decrypted');

        chomp($line = qx{$perl $iofile});
        is($line, $str, '... and decrypted file still runs OK');

        qx{$perl $crypt_file -i -e tempfile -c decrypted $iofile 2>$null};
        is($?, 0, 'crypt_file ran OK with -c decrypted option (using a tempfile)');

        open $fh, '<', $iofile or die "Can't read file '$iofile': $!\n";
        $contents = do { local $/; <$fh> };
        close $fh;
        is($contents, $prog, '... and left file decrypted');

        chomp($line = qx{$perl $iofile});
        is($line, $str, '... and decrypted file still runs OK');

        unlink $iofile;
    }

    {
        chomp($data = qx{$perl $crypt_file -v});
        like($data, qr/\A This\ is\ crypt_file              .*?
                        ^ Copyright                         .*?
                        ^ This\ script\ is\ free\ software /mosx,
             '-v option works');

        chomp($data = qx{$perl $crypt_file -h});
        like($data, qr/\A Usage:     .*?
                        ^ Arguments: .*?
                        ^ Options:   /mosx,
             '-h option works');

        SKIP: {
            if (-e catfile('', 'etc', 'debian_version') and
                not -e catfile('', 'usr', 'bin', 'perldoc.stub'))
            {
                skip 'Debian-based host without perl-doc installed', 1;
            }

            local $ENV{PERLDOC} = '-t';
            chomp($data = qx{$perl $crypt_file -m});
            like($data, qr/^ NAME         .*?
                           ^ SYNOPSIS     .*?
                           ^ ARGUMENTS    .*?
                           ^ OPTIONS      .*?
                           ^ EXIT\ STATUS .*?
                           ^ DIAGNOSTICS  .*?
                           ^ EXAMPLES     .*?
                           ^ ENVIRONMENT  .*?
                           ^ SEE\ ALSO    .*?
                           ^ AUTHOR       .*?
                           ^ COPYRIGHT    .*?
                           ^ LICENCE      .*?
                           ^ VERSION      .*?
                           ^ DATE         .*?
                           ^ HISTORY      /mosx,
                 '-m option works');
        }
    }
}

#===============================================================================
