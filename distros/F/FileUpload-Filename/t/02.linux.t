#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 9;

#sub FileUpload::Filename::DEBUG { 1 };
use FileUpload::Filename;


my @tests = (

    [
        'Mozilla/4.0 (compatible; MSIE 6.0; X11; Linux i686) Opera 7.23  [en]',
        '/TrP/bubu/fs2td.jpg',
        'fs2td.jpg',
    ],
    [
        'Mozilla/4.0 (compatible; MSIE 6.0; X11; Linux i686) Opera 7.50  [en]',
        '/var/tmp/file.tar.gz',
        'file.tar.gz',
    ],
    [
        'Mozilla/4.0 (compatible; MSIE 6.0; X11; Linux i686) Opera 7.50  [en]',
        '/var/tmp/file.tar.gz',
        'file.tar.gz',
    ],
    [
        'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.7.12) Gecko/20051010 Firefox/1.0.7 (Ubuntu package 1.0.7)',
        '/tmp/a_long_File_with - spaces - inside.jpg',
        'a_long_File_with_-_spaces_-_inside.jpg',
    ],
    [
        'Emacs-W3/4.0pre.46 URL/p4.0pre.46 (i686-pc-linux; X11)',
        '/tmp/a_long_File_with - spaces - inside.jpg',
        'a_long_File_with_-_spaces_-_inside.jpg',
    ],
    [
        'Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.8.0.1) Gecko/Debian-1.8.0.1-5 Epiphany/1.8.5',
        '/tmp/a_long_File_with - spaces - inside.jpg',
        'a_long_File_with_-_spaces_-_inside.jpg',
    ],
    [
        'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.4.1) Gecko/20031114 Epiphany/1.0.4',
        '/tmp/a_long_File_with - spaces - inside.jpg',
        'a_long_File_with_-_spaces_-_inside.jpg',
    ],
    [
        'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.7.3) Gecko/20040913 Galeon/1.3.18',
        '/tmp/a_long_File_with - spaces - inside.jpg',
        'a_long_File_with_-_spaces_-_inside.jpg',
    ],
    [
        'Mozilla/5.0 (compatible; Konqueror/3.4; Linux) KHTML/3.4.3 (like Gecko) (Kubuntu package 4:3.4.3-0ubuntu1)',
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
