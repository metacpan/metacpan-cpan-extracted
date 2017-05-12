#!/usr/bin/perl

# $Id: 01distribconf.t 56934 2006-08-21 10:16:29Z nanardon $

use strict;
use Test::More;
use MDV::Distribconf;

my @testdpath = grep { ! /SRPMS/ } glob('testdata/history/*/*/*');

plan tests => 6 * scalar(@testdpath);

foreach my $path (@testdpath) {
    ok(
        my $dconf = MDV::Distribconf->new($path),
        "Can get new MDV::Distribconf"
    );
    ok($dconf->load(), "can load $path");
    ok($dconf->listmedia(), "can list media");
    SKIP: {
        my $arch = $dconf->getvalue(undef, "arch");
        skip "undefined arch for in case", 2 unless(defined($arch));
    like($arch, '/.+/', "can get arch");
    like($dconf->getvalue(undef, "platform"), "/^$arch" . '-(mandriva|mandrake)-linux-gnu$/', "can get arch");
    }
    my $foundhd = 0;
    my $medias = 0;
    foreach my $m ($dconf->listmedia()) {
        $medias++;
        if (-f $dconf->getfulldpath($m, 'hdlist')) {
            $foundhd++;
        } else {
            print STDERR "$m " . $dconf->getfulldpath($m, 'hdlist') . " not found\n";
        }
    }
    is($foundhd, $medias, "All hdlists can be found");
}
