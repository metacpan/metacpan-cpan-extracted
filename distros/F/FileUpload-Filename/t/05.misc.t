#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 9;

#sub FileUpload::Filename::DEBUG { 1 };
sub FileUpload::Filename::VERBOSE { 0 };
use FileUpload::Filename;


my @tests = (

    [
        'Mozilla/5.0 (BeOS; U; BeOS BePC; en-US; rv:1.9a1) Gecko/20051002 Firefox/1.6a1',
        'a_long_File_with_-_spaces_-_inside.jpg',
        'a_long_File_with_-_spaces_-_inside.jpg',
    ],
    [
        'Mozilla/5.0 (X11; U; SunOS i86pc; en-US; rv:1.8) Gecko/20051130 Firefox/1.5',
        'a_long_File_with_-_spaces_-_inside.jpg',
        'a_long_File_with_-_spaces_-_inside.jpg',
    ],
    [
        'Mozilla/5.0 (X11; U; FreeBSD i386; en-US; rv:1.7.12) Gecko/20051105 Firefox/1.0.7',
        '/tmp/a_long_File_with_-_spaces_-_inside.jpg',
        'a_long_File_with_-_spaces_-_inside.jpg',
    ],
    [
        'Mozilla/5.0 (OS/2; U; Warp 4.5; en-US; rv:1.7.12) Gecko/20050922 Firefox/1.0.7',
        'a_long_File_with_-_spaces_-_inside.jpg',
        'a_long_File_with_-_spaces_-_inside.jpg',
    ],
    [
        'Mozilla/5.0 (X11; U; FreeBSD i386; en-US; rv:1.7.12) Gecko/20051105 Galeon/1.3.21',
        '/tmp/a_long_File_with_-_spaces_-_inside.jpg',
        'a_long_File_with_-_spaces_-_inside.jpg',
    ],
    [
        'Mozilla/5.0 (compatible; Konqueror/3.4; FreeBSD) KHTML/3.4.3 (like Gecko)',
        '/tmp/a_long_File_with_-_spaces_-_inside.jpg',
        'a_long_File_with_-_spaces_-_inside.jpg',
    ],
    [
        'Lynx/2.8.5dev.16 libwww-FM/2.14 SSL-MM/1.4.1 OpenSSL/0.9.6b',
        '/tmp/a_long_File_with_-_spaces_-_inside.jpg',
        'a_long_File_with_-_spaces_-_inside.jpg',
    ],
    [
        'VMS_Mosaic/3.8-1 (Motif;OpenVMS V7.3-2 DEC 3000 - M700) libwww/2.12_Mosaic',
        '/tmp/a_long_File_with_-_spaces_-_inside.jpg',
        'a_long_File_with_-_spaces_-_inside.jpg',
    ],
    [
        'Mozilla/5.0 (BeOS; U; BeOS BePC; en-US; rv:1.9a1) Gecko/20051002 Firefox/1.6a1',
        '/tmp/a_long_File_with - spaces - inside.jpg',
        'a_long_File_with_-_spaces_-_inside.jpg',
    ],

);

for (@tests) {
    my $name = FileUpload::Filename->name({
        agent     => $_->[0],
        filename  => $_->[1],
    });
    is( $name, $_->[2], $_->[0] );
}
