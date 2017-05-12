#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 7;

#sub FileUpload::Filename::DEBUG { 1 };
use FileUpload::Filename;


my @tests = (

    [
        'Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en-US; rv:1.8.0.1) Gecko/20060118 Camino/1.0b2+',
        'TMP:Tesx2td.pdf',
        'Tesx2td.pdf',
    ],
    [
        'Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-US; rv:1.0.1) Gecko/20021104 Chimera/0.6',
        'Users Don\'t Cry:Tesx2td.pdf',
        'Tesx2td.pdf',
    ],
    [
        'Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.5b) Gecko/20030917 Camino/0.7+',
        'Users Don\'t Cry:Tesx2td.pdf',
        'Tesx2td.pdf',
    ],
    [
        'Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.8) Gecko/20051111 Firefox/1.5',
        'Users Don\'t Cry:Tesx2td.pdf',
        'Tesx2td.pdf',
    ],
    [
        'Opera/9.0 (Macintosh; PPC Mac OS X; U; en)',
        'Users Don\'t Cry:Tesx2td.pdf',
        'Tesx2td.pdf',
    ],
    [
        'Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) AppleWebKit/417.9 (KHTML, like Gecko) Safari/417.8',
        'Users Don\'t Cry:Tesx2td.pdf',
        'Tesx2td.pdf',
    ],
    [
        'Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) AppleWebKit/51 (like Gecko) Safari/51',
        'Users Don\'t Cry:Tesx2td.pdf',
        'Tesx2td.pdf',
    ],

);

for (@tests) {
    my $name = FileUpload::Filename->name({
        agent     => $_->[0],
        filename  => $_->[1],
    });
    is( $name, $_->[2], $_->[0] );
}
