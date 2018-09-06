# -*- perl -*-

# t/014_mixin.t

; use strict; use warnings
; use Test::More tests => 5

; use Data::Dumper

; package HOt::mixin::One

; use HO::class
    _rw => auto => sub { 'fiat' }

; package HOt::Dandy

; use HO::mixin 'HOt::mixin::One'

; package HOt::Rapper

; use parent -norequire => 'HOt::Dandy'

; use HO::class
    _rw => glamour => sub { 'gold' }

; package main;

; my $dandy = new HOt::Dandy::

; is($dandy->auto,'fiat')
; $dandy->auto('bmw')
; is $dandy->auto, 'bmw'

; my $star = new HOt::Rapper

; isa_ok($star, ref($dandy))

; is($star->auto,'fiat')
; is($star->glamour,'gold')
