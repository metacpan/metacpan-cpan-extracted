
; use strict
; use Test::More tests => 6

; use_ok('HO::class')

; package H::first
; use HO::class 
    _method => hw => sub { 'Hallo Welt!' },
    alias => hello => 'hw';

; package main
; my $o1 = H::first->new
; is($o1->hw,'Hallo Welt!')
; my $o2=$o1->new
; is($o2->hw,'Hallo Welt!')

; $o2->[$o2->_hw] = sub { 'Hello world!' }
; is($o2->hw,'Hello world!')

; is($o1->hello,'Hallo Welt!')
; is($o2->hello,'Hello world!')
