#!perl
#===============================================================================
#
# t/04_par.t
#
# DESCRIPTION
#   Test script to check PAR::Filter::Crypto module (and decryption filter).
#
# COPYRIGHT
#   Copyright (C) 2004-2006, 2008-2009, 2012, 2014 Steve Hay.  All rights
#   reserved.
#
# LICENCE
#   You may distribute under the terms of either the GNU General Public License
#   or the Artistic License, as specified in the LICENCE file.
#
#===============================================================================

use 5.008001;

use strict;
use warnings;

use Config qw(%Config);
use Cwd qw(abs_path);
use File::Spec::Functions qw(canonpath catdir catfile curdir updir);
use FindBin qw($Bin);
use Test::More;

## no critic (Subroutines::ProhibitSubroutinePrototypes)

sub new_filename();

#===============================================================================
# INITIALIZATION
#===============================================================================

my($pp);

BEGIN {
    my $i = 0;
    sub new_filename() {
        $i++;
        return "test$i$Config{_exe}";
    }

    my $top_dir = canonpath(abs_path(catdir($Bin, updir())));
    my $lib_dir = catfile($top_dir, 'blib', 'lib', 'Filter', 'Crypto');

    unless (-f catfile($lib_dir, 'CryptFile.pm')) {
        plan skip_all => 'CryptFile component not built';
    }

    unless (-f catfile($lib_dir, 'Decrypt.pm')) {
        plan skip_all => 'Decrypt component not built';
    }

    unless (eval { require PAR::Filter }) {
        plan skip_all => 'PAR::Filter required to test PAR::Filter::Crypto';
    }

    my @keys = qw(
        installsitescript installvendorscript installscript
        installsitebin    installvendorbin    installbin
    );

    foreach my $key (@keys) {
        next unless exists $Config{$key} and $Config{$key} ne '';
        next unless -d $Config{$key};
        $pp = catfile($Config{$key}, 'pp');
        last if -f $pp;
        undef $pp;
    }

    if (defined $pp) {
        plan tests => 16;
    }
    else {
        plan skip_all => "'pp' required to test PAR::Filter::Crypto";
    }
}

#===============================================================================
# MAIN PROGRAM
#===============================================================================

MAIN: {
    my $ifile  = 'test.pl';
    my $str    = 'Hello, world.';
    my $prog   = qq[use strict; print "$str\\n";\n];
    my $head   = 'use Filter::Crypto::Decrypt;';
    my $qrhead = qr/^\Q$head\E/o;

    my $perl_exe = $^X =~ / /o ? qq["$^X"] : $^X;
    my $perl = qq[$perl_exe -Mblib];

    my $have_archive_zip = eval { require Archive::Zip };
    my $have_broken_module_scandeps;
    if (eval { require Module::ScanDeps }) {
        $have_broken_module_scandeps = ($Module::ScanDeps::VERSION eq '0.75');
    }

    my($fh, $ofile, $line, $cur_ofile);

    open $fh, '>', $ifile or die "Can't create file '$ifile': $!\n";
    print $fh $prog;
    close $fh;

    {
        $ofile = new_filename();

        qx{$perl $pp -f Crypto -M Filter::Crypto::Decrypt -o $ofile $ifile};
        is($?, 0, 'pp -f Crypto exited successfully');
        cmp_ok(-s $ofile, '>', 0, '... and created a non-zero size PAR archive');

        SKIP: {
            skip 'Archive::Zip required to inspect PAR archive', 5
                unless $have_archive_zip;

            my $zip = Archive::Zip->new() or die "Can't create new Archive::Zip\n";
            my $ret = eval { $zip->read($ofile) };
            is($@, '', 'No exceptions were thrown reading the PAR archive');
            is($ret, Archive::Zip::AZ_OK(), '... and read() returned OK');
            like($zip->contents("script/$ifile"), $qrhead,
                 '... and the script contents are as expected');
            unlike($zip->contents("lib/strict.pm"), $qrhead,
                 '... and the included module contents are as expected');
            unlike($zip->contents("lib/Filter/Crypto/Decrypt.pm"), $qrhead,
                 '... and the decryption module contents are as expected');
        }

        SKIP: {
            skip "Module::ScanDeps $Module::ScanDeps::VERSION is broken", 1
                if $have_broken_module_scandeps;

            # Some platforms search the directories in PATH before the current
            # directory so be explicit which file we want to run.
            $cur_ofile = catfile(curdir(), $ofile);
            chomp($line = qx{$cur_ofile});
            is($line, $str, 'Running the PAR archive produces the expected output');
        }

        unlink $ofile;
    }

    {
        $ofile = new_filename();

        qx{$perl $pp -f Crypto -F Crypto -M Filter::Crypto::Decrypt -o $ofile $ifile};
        is($?, 0, 'pp -f Crypto -F Crypto exited successfully');
        cmp_ok(-s $ofile, '>', 0, '... and created a non-zero size PAR archive');

        SKIP: {
            skip 'Archive::Zip required to inspect PAR archive', 5
                unless $have_archive_zip;

            my $zip = Archive::Zip->new() or die "Can't create new Archive::Zip\n";
            my $ret = eval { $zip->read($ofile) };
            is($@, '', 'No exceptions were thrown reading the PAR archive');
            is($ret, Archive::Zip::AZ_OK(), '... and read() returned OK');
            like($zip->contents("script/$ifile"), $qrhead,
                 '... and the script contents are as expected');
            like($zip->contents("lib/strict.pm"), $qrhead,
                 '... and the included module contents are as expected');
            unlike($zip->contents("lib/Filter/Crypto/Decrypt.pm"), $qrhead,
                 '... and the decryption module contents are as expected');
        }

        SKIP: {
            skip "Module::ScanDeps $Module::ScanDeps::VERSION is broken", 1
                if $have_broken_module_scandeps;

            # Some platforms search the directories in PATH before the current
            # directory so be explicit which file we want to run.
            $cur_ofile = catfile(curdir(), $ofile);
            chomp($line = qx{$cur_ofile});
            is($line, $str, 'Running the PAR archive produces the expected output');
        }

        unlink $ofile;
    }

    unlink $ifile;
}
