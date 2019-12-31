# -*- perl -*-

# t/014_mixin.t

; use strict; use warnings
; use Test::More tests => 13

; use Data::Dumper

; package HOt::mixin::One

; use HO::class
    _rw => auto => sub { 'fiat' }

; package HOt::Dandy

; use HO::mixin 'HOt::mixin::One'

; use HO::class

; package HOt::Rapper

; use parent -norequire => 'HOt::Dandy'

; use HO::class
    _rw => glamour => sub { 'gold' },
    _method => skill => sub { reverse @_ }

; sub beat { [1..3,@_,2..5] }

; package HOt::Song

; use HO::class
; use HO::mixin 'HOt::Rapper'

; package HOt::Lyrics
; use HO::class
; use HO::mixin 'HOt::Song', without => ['beat']

; package main;

; my $dandy = new HOt::Dandy::

; is($dandy->auto,'fiat')
; $dandy->auto('bmw')
; is $dandy->auto, 'bmw'

; my $star = new HOt::Rapper

; is_deeply(['HOt::Dandy'], \@HOt::Rapper::ISA)
; isa_ok($star, ref($dandy))

; is($star->auto,'fiat')
; is($star->glamour,'gold')

; my $hit = HOt::Song->new
; is_deeply([], \@HOt::Song::ISA)

; can_ok($hit,'new')
; ok(!$hit->can('auto'),'no car')
; ok(!$hit->can('glamour'),'no glamour song')
; ok(!$hit->can('skill'),'no skill')
; can_ok($hit,'beat')

; my $txt = HOt::Lyrics->new
; ok(!$txt->can('beat'),'no lyrics beat');

