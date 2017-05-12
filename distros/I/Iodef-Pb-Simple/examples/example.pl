#!/usr/bin/perl -w

use strict;

use lib './lib';
use Data::Dumper;
use Iodef::Pb::Simple;

my $x = Iodef::Pb::Simple->new({
    service => "ssh",
    protocol    => 'tcp',
    portlist    => '22',
    contact => 'Wes Young',
    id      => '1234',
    address => '1.1.1.1',
    prefix  => '1.1.1.0/24',
    asn     => 'AS1234',
    cc      => 'US',
    assessment  => 'botnet',
    confidence  => '50',
    restriction     => 'private',
    method          => 'http://www.virustotal.com/analisis/02da4d701931b1b00703419a34313d41938e5bd22d336186e65ea1b8a6bfbf1d-1280410372',
    #Malware     => '/tmp/malware_test',
});

my $str = $x->encode();
warn Dumper($x);
warn Dumper(IODEFDocumentType->decode($str));
warn $str;
