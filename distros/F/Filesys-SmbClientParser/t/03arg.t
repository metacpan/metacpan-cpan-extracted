#!/usr/bin/env perl -w
# Test args methods: Host User Share Password Workgroup IpAdress

use strict;
use Test::More;
plan tests => 6;
use Filesys::SmbClientParser;

my $s = Filesys::SmbClientParser->new; # create an object
$s->Host('toto');
is($s->Host,'toto','Host method');

$s->User('toto');
is($s->User,'toto','User method');

$s->Share('toto');
is($s->Share,'toto','Share method');

$s->Password('toto');
is($s->Password,'toto','Password method');

$s->Workgroup('toto');
is($s->Workgroup,'toto','Workgroup method');

$s->IpAdress('toto');
is($s->IpAdress,'toto','IpAdress method');
