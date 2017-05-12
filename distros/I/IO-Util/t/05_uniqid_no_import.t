#!perl -w
; use strict
; use Test::More tests => 15
  
; use IO::Util ()


; my $u1 = IO::Util::Tid
; my $u2 = IO::Util::Lid
; my $u3 = IO::Util::Uid

; ok $u1
; ok $u2
; ok $u3
; ok length($u1)<length($u2)
; ok length($u2)<length($u3)


; my $u4 = IO::Util::Tid chars=>'base62'
; my $u5 = IO::Util::Lid chars=>'base62'
; my $u6 = IO::Util::Uid chars=>'base62'

; my $rebase62 = qr/^[0-9a-zA-Z_]+$/
; like $u4, $rebase62
; like $u5, $rebase62
; like $u6, $rebase62
; ok length($u4)<length($u5)
; ok length($u5)<length($u6)

; my $u7 = IO::Util::Tid chars=>[0..9, 'A'..'F']
; my $u8 = IO::Util::Lid chars=>[0..9, 'A'..'F']
; my $u9 = IO::Util::Uid chars=>[0..9, 'A'..'F']
; my $reHex = qr/^[0-9A-F_]+$/

; like $u7, $reHex
; like $u8, $reHex
; like $u9, $reHex
; ok length($u7)<length($u8)
; ok length($u7)<length($u9)
 
