
use strict; use warnings;

package main;

use Test::More tests => 10;

; package T::without_init

; Test::More::use_ok 'HO::class', _ro => name => '$'

; package T::with_init

; sub init 
    { my $self = shift
    ; $self->[&_name] = (shift || 'midas');
    ; return $self
    }
  
; Test::More::use_ok 'HO::class', _ro => name => '$'

; package main

; my $without  = T::without_init -> new ('jaguar')

; isa_ok($without,'T::without_init')
; is($without->name,undef)
; ok(!$without->can('init'))
; is @{$without},1

; my $with1 = T::with_init->new
; isa_ok($with1,'T::with_init')
; is($with1->name,'midas')
; is @{$with1},1

; my $with2 = T::with_init->new('puma')
; is($with2->name,'puma')




