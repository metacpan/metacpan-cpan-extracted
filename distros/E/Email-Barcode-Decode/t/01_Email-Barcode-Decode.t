#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 11;

use FindBin qw($Bin);
use lib "$Bin/lib";

use Path::Class qw(file);
use File::Which qw(which);

BEGIN {
    use_ok ( 'Email::Barcode::Decode' ) or exit;
}

EMAIL_WITH_IMAGE: {
    my $msg01 = file($Bin,'tdata','msg01.eml')->slurp;

    my $ebd = Email::Barcode::Decode->new(email => $msg01);
    my @attached = @{$ebd->attached_files};
    is(scalar(@attached), 1, 'one attachment msg01.eml');

    my @symbols = $ebd->get_symbols;
    is(scalar(@symbols), 1, 'one barcode');
    is_deeply($symbols[0],{
        filename => 'barcode01.jpg',
        type     => 'QR-Code',
        data     => 'eusa:mpsexp:9',
    }, 'decoded data');
}

EMAIL_WITH_IMAGE2: {
    my $msg03 = file($Bin,'tdata','msg03.eml')->slurp;

    my $ebd = Email::Barcode::Decode->new(email => $msg03);
    my @attached = @{$ebd->attached_files};
    is(scalar(@attached), 1, 'one attachment msg03.eml');

    my @symbols = $ebd->get_symbols;
    is(scalar(@symbols), 1, 'one barcode');
    is_deeply($symbols[0],{
        filename => 'DPD-IMG_0013.jpg',
        type     => 'CODE-128',
        data     => 'eusa:mpsexp:939',
    }, 'decoded data');
}

if (which('gs')) {
    EMAIL_WITH_PDF: {
        my $msg02 = file($Bin,'tdata','msg02.eml')->slurp;

        my $ebd = Email::Barcode::Decode->new(email => $msg02);
        my @attached = @{$ebd->attached_files};
        is(scalar(@attached), 2, 'two pages');

        my @symbols = $ebd->get_symbols;
        is(scalar(@symbols), 2, 'two barcode');
        is_deeply($symbols[0],{
            filename => 'vcard-pdf-page1.jpg',
            type     => 'QR-Code',
            data     => 'BEGIN:VCARD
N:Jozef Kutej
ORG:meon
TITLE:IT Development
TEL:+4369918141077
URL:http://www.meon.eu/
EMAIL:jozef.kutej@meon.eu
ADR:Praterstrasse 15/3/22\\, 1020 Vienna\\, Austria
END:VCARD',
        }, 'decoded data 1');
        is_deeply($symbols[1],{
            filename => 'vcard-pdf-page2.jpg',
            type     => 'QR-Code',
            data     => 'http://search.cpan.org/perldoc?Email%3A%3ABarcode%3A%3ADecode',
        }, 'decoded data 2');
    }
} else {
    SKIP: {
        skip '- no `gs` found. Is Ghostscript installed?', 4;
    }
}
