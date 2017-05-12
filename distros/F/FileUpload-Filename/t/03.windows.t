#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 10;

#sub FileUpload::Filename::DEBUG { 1 };
use FileUpload::Filename;


my @tests = (

    [
        'Mozilla/4.0 (compatible; MSIE 5.5; Windows 95)', 
        'C:\TMP\Tesx2td.pdf',
        'Tesx2td.pdf',
    ],
    [
        'Mozilla/4.0 (compatible; MSIE 5.5; Windows 95)', 
        'Z:\TrP\es2td.TXT',
        'es2td.TXT',
    ],
    [
        'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)',
        '\TrP\bubu\es2td.jpg',
        'es2td.jpg',
    ],
    [
        'Mozilla/4.0 (compatible; MSIE 5.0; Windows 98; DigExt)',
        '\TrP\bubu\Blah Blah - Bu Bu.mp3',
        'Blah_Blah_-_Bu_Bu.mp3',
    ],
    [
        'ELinks/0.10.5 (textmode; CYGWIN_NT-5.0 1.5.18(0.132/4/2) i686; 143x51-2)',
        '\TrP\bubu\Blah Blah - Bu Bu.mp3',
        'Blah_Blah_-_Bu_Bu.mp3',
    ],
    [
        'Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.9a1) Gecko/20051102 Firefox/1.6a1',
        '\TrP\bubu\Blah Blah - Bu Bu.mp3',
        'Blah_Blah_-_Bu_Bu.mp3',
    ],
    [
        'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8b5) Gecko/20051019 Flock/0.4 Firefox/1.0+',
        'C:\TrP\bubu\Blah Blah - Bu Bu.mp3',
        'Blah_Blah_-_Bu_Bu.mp3',
    ],
    [
        'ICE Browser/5.05 (Java 1.4.0; Windows 2000 5.0 x86)',
        'C:\TrP\bubu\Blah Blah - Bu Bu.mp3',
        'Blah_Blah_-_Bu_Bu.mp3',
    ],
    [
        'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)',
        'C:\TrP\bubu\Blah Blah - Bu Bu.mp3',
        'Blah_Blah_-_Bu_Bu.mp3',
    ],
    [
        'Opera/9.0 (Windows NT 5.1; U; en)',
        'C:\TrP\bubu\Blah Blah - Bu Bu.mp3',
        'Blah_Blah_-_Bu_Bu.mp3',
    ],

);

for (@tests) {
    my $name = FileUpload::Filename->name({
        agent     => $_->[0],
        filename  => $_->[1],
    });
    is( $name, $_->[2], $_->[0] );
}
