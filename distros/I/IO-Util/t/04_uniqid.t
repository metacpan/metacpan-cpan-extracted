#!perl -w
; use strict
; use Test::More tests => 16

; use IO::Util qw(Tid Lid Uid)

; can_ok 'main', qw(Tid Lid Uid)


; my $u1 = Tid
; my $u2 = Lid
; my $u3 = Uid

; ok $u1
; ok $u2
; ok $u3
; ok length($u1)<length($u2)
; ok length($u2)<length($u3)


; my $u4 = Tid chars=>'base62'
; my $u5 = Lid chars=>'base62'
; my $u6 = Uid chars=>'base62'

; my $rebase62 = qr/^[0-9a-zA-Z_]+$/
; like $u4, $rebase62
; like $u5, $rebase62
; like $u6, $rebase62
; ok length($u4)<length($u5)
; ok length($u5)<length($u6)

; my $u7 = Tid chars=>[0..9, 'A'..'F']
; my $u8 = Lid chars=>[0..9, 'A'..'F']
; my $u9 = Uid chars=>[0..9, 'A'..'F']
; my $reHex = qr/^[0-9A-F_]+$/

; like $u7, $reHex
; like $u8, $reHex
; like $u9, $reHex
; ok length($u7)<length($u8)
; ok length($u7)<length($u9)
 
