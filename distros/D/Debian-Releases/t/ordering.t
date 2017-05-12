#!perl -w

use strict;
use warnings;

use Debian::Releases;
use Test::More tests => 40;

my $rels = {
    '1.1'       => 'buzz',
    '1.2'       => 'rex',
    '1.3'       => 'bo',
    '2.0'       => 'hamm',
    '2.1'       => 'slink',
    '2.2'       => 'potato',
    '3.0'       => 'woody',
    '3.1'       => 'sarge',
    '4.0'       => 'etch',
    '5.0'       => 'lenny',
    '6.0'       => 'squeeze',
    '7.0'       => 'wheezy',
    '8.0'       => 'jessie',
};

my $DR = Debian::Releases->new();

isa_ok($DR,'Debian::Releases');

foreach my $ver (keys %$rels) {
    my $code = $rels->{$ver};
    is($DR->version_compare($ver,$code),0,$ver.' is '.$code);
    is($DR->version_compare($ver,'sid'),-1,$ver.' < sid');
    is($DR->version_compare($code,'sid'),-1,$code.' < sid');
}
