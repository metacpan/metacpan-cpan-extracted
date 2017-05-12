#!/usr/bin/env perl
use strict; use warnings;
use Test::Exception tests => 2;
use Device::OUI;

throws_ok { Device::OUI->new( 'FOO' ) } qr/Invalid OUI format/;

my $empty = Device::OUI->new;
throws_ok { $empty->oui } qr/Object does not have an OUI/;

# This is an exceptional situation, even though it doesn't actually throw one
Device::OUI->cache_db( '/tmp/this/file/better/not/exist!!!' );
Device::OUI->cache_handle;
