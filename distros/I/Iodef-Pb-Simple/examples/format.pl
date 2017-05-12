#!/usr/bin/perl -w

use strict;

use lib './lib';

use Iodef::Pb::Simple;
use Iodef::Pb::Format;
use Data::Dumper;

my $i = Iodef::Pb::Simple->new({
    address     => '1.2.3.4',
    confidence  => 50,
    severity    => 'high',
    restriction => 'need-to-know',
    contact     => 'Wes Young',
    assessment  => 'botnet',
    description => 'spyeye',
    alternativeid  => 'example2.com',
    id          => '1234',
    portlist    => '443,8080',
    protocol    => 'tcp',
    asn         => '1234',
    guid        => 'root',
});

#warn Dumper($i);

my $ret = Iodef::Pb::Format->new({
    driver  => 'Snort',
    data    => [$i,$i],
    #data    => $i,
});

warn $ret;