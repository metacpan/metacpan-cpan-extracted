#!/usr/bin/perl -T
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Mail-ClamAV.t'

# Set env variable TEST_CONSTANTS=1 if you want the tests of constants to run.

#########################

use Test::More tests => 11;
use strict;
BEGIN { use_ok('Mail::ClamAV') };

import Mail::ClamAV qw/:all/;

my $fail = 0;
my (@warned, @failed);
if ($ENV{TEST_CONSTANTS}) {
    foreach my $constname (qw(
        CL_CLEAN
        CL_VIRUS
        CL_BREAK

        CL_EMAXREC
        CL_EMAXSIZE
        CL_EMAXFILES
        CL_EACCES
        CL_ENULLARG
        CL_ETMPFILE
        CL_EMEM
        CL_EOPEN
        CL_EMALFDB
        CL_ETMPDIR
        CL_ECVD
        CL_EFORMAT

        CL_ENCINIT
        CL_ENCLOAD
        CL_ENCIO

        CL_SCAN_RAW
        CL_SCAN_ARCHIVE
        CL_SCAN_MAIL
        CL_SCAN_OLE2
        CL_SCAN_BLOCKENCRYPTED
        CL_SCAN_HTML
        CL_SCAN_PE
        CL_SCAN_BLOCKBROKEN
        CL_SCAN_MAILURL
        CL_SCAN_BLOCKMAX
        CL_SCAN_ALGORITHMIC
        CL_SCAN_PHISHING_BLOCKSSL

        CL_SCAN_PHISHING_BLOCKCLOAK
        CL_SCAN_ELF

        CL_SCAN_STDOPT
    MICHAEL_SCOTT
    DWIGHT_SCHRUTE
        CL_RAW
        CL_ARCHIVE
        CL_MAIL
        CL_OLE2
        CL_BLOCKENCRYPTED
        CL_HTML
        CL_PE
        CL_BLOCKBROKEN
        CL_MAILURL
        CL_BLOCKMAX)) {
      next if (eval "my \$a = $constname; 1");
      if ($@ =~ /^Your vendor has not defined Mail::ClamAV macro $constname/) {
        chomp $@;
        push @warned, $@;
      } else {
        chomp $@;
        push @failed, $@;
        $fail = 1;
      }
    }
}

SKIP: {
    skip 'The TEST_CONSTANTS environment variable is not set.', 1 unless $ENV{TEST_CONSTANTS};
    ok($fail == 0, 'Constants')
        or diag("Mail::ClamAV found no defs for these macros in clamav.h: @warned, and these caused errors: @failed");
}

my $c = new Mail::ClamAV(retdbdir());
ok($c, 'allocate scanning engine')
    or BAIL_OUT('Failed to allocate clamav scanning engine');
$|=1;
$c->buildtrie;

$c->maxreclevel(6);
ok($c->maxreclevel == 6, 'Set/Get maxreclevel');

$c->maxfiles(1001);
ok($c->maxfiles == 1001, 'Set/Get maxfiles');

$c->maxfilesize(1024 * 1028 * 20);
ok(($c->maxfilesize == (1024 * 1028 * 20)), 'Set/Get maxfilesize');

my $f = "t/virus.eml";
my $status = $c->scan($f, CL_SCAN_STDOPT());
ok("$status" eq "Eicar-Test-Signature", 'Scan File');
open my $fh, "<", $f;
ok($c->scan($fh, CL_SCAN_STDOPT())->virus, 'Scan FileHandle');

$status = $c->scan($f, CL_SCAN_STDOPT());
ok("$status" eq "Eicar-Test-Signature", 'Scan File overload');
seek $fh, 0, 0;
$status = $c->scan($fh, CL_SCAN_STDOPT());
ok("$status" eq "Eicar-Test-Signature", 'Scan FileHandle overload');

eval { $status = $c->scan($f.substr($0, 0, 0), CL_SCAN_STDOPT()) };
ok(($@ and $@ =~ /tainted/), 'Scan tainted croaks');

