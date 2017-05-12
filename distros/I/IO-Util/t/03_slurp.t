#!perl -w
; use strict
; use Test::More tests => 11
; use IO::Util qw(slurp)

; BEGIN
   { chdir './t'
   }

; can_ok 'main', 'slurp'
; my $out = slurp 'test.txt'
; is $$out, "test\ntest\n", 'Simple slurp'

; slurp 'test.txt', \my $content1
; is $content1, "test\ntest\n", 'Simple slurp with scalar_ref'

; $out = slurp '0'
; is $$out, "test\ntest\n", 'File 0'

; eval { $out = slurp [1..3] }
; like $@, qr/^Wrong/, 'Wrong file argument'

;  eval { $out = slurp 'not_found' }
; ok $@, 'File not found'

; open TEST, 'test.txt'
; $out = slurp *TEST
; is $$out, "test\ntest\n", 'Handle slurp'

; open TEST, 'test.txt'
; slurp *TEST, \ my $content2  
; is $content2, "test\ntest\n", 'Handle slurp with scalar_ref'

; $_ =   'test.txt'
; $out = slurp
; is $$out, "test\ntest\n", 'Implicit slurp'

; slurp \my $content3
; is $content3, "test\ntest\n", 'Implicit slurp with scalar_ref'

; $out = slurp \*DATA
; is $$out, "data\ndata\n", 'DATA handle'

__DATA__
data
data
