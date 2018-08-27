
; use strict
; use Test::More tests => 11
; use Data::Dumper

; use_ok('HO::class')

; package H::first
; use HO::class
    _method => hw => sub { 'Hallo Welt!' },
    alias => hello => 'hw';

; package H::first::one
; our $VERSION = 0.002

; package H::second
; our @ISA = ('H::first')
; use HO::class
    _ro     => dummy => '$',
    _rw     => ooh => '$',
    _method => hw => sub { 'Hello World (O)!' }

; package main
; my $o1 = H::first->new
; is($o1->hw,'Hallo Welt!')
; my $o2=$o1->new
; is($o2->hw,'Hallo Welt!')

; $o2->[$o2->_hw] = sub { 'Hello world!' }
; is($o2->hw,'Hello world!')

; is($o1->hello,'Hallo Welt!')
; is($o2->hello,'Hallo Welt!')

; my $o3 = H::second->new
# durch den indirekten Methodenaufruf wird nicht die Methode der Basisklasse
# aufgerufen, was passiert also wenn sich der Index ändert?
; is($o3->hello,'Hallo Welt!')
; is($o3->hw,'Hello World (O)!')
; is($o3->[$o3->__hw]->(),'Hello World (O)!')

; my $o4 = H::first->new
; is($o4->hw,'Hallo Welt!')
; is($o4->hello,'Hallo Welt!')

; if(0) { no strict 'refs'
  ; print Dumper( [$o3,$o4, \%{"H::first\::"}, \%{"H::second\::"}] )
  }

