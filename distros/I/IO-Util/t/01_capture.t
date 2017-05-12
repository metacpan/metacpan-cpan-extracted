#!perl -w
; use strict
; use Test::More tests => 10


; use IO::Util qw(capture)


; sub print_something
   { print shift()
   }

; can_ok 'main', 'capture'
; my $out = capture { print_something('a'); print_something('b')}
; is $$out, 'ab', 'Simple capture'

; select STDERR

; $out = capture { print_something('c'); print_something('d')} \*STDERR
; is  $$out, 'cd', 'Explicit handle'


; capture { print_something('c'); print_something('d')} \*STDERR, \my $captured1
; is  $captured1, 'cd', 'Explicit handle with scalar_ref'

; select STDOUT


; { package test_tie
  ; sub TIEHANDLE { bless \ my $s, shift }
  }

; tie *STDOUT, 'test_tie'

; capture { print_something('e'); print_something('f')} \ my $captured2

; is $captured2, 'ef', 'Tied handle content'
; isa_ok tied *STDOUT, 'test_tie', 'Restore tied handle'


; untie *STDOUT

; $, = '*'
; $\ = '#'

; $out = capture { print 'X', 'Y'
                 ; printf '<%6s>', "a"
                 ; print_something('Z');
                 }
; is $$out, 'X*Y#<     a>Z#', 'Separators'

; $out = capture { syswrite STDOUT, 'X'
                 ; syswrite STDOUT, 'Y'
                 }

; is $$out, 'XY', 'syswrite()'

; $, = undef
; $\ = undef

   
; my $cap  = capture { print 'b'
                     ; return_captured()
                     }
; is $$cap, 'b', 'Outer capture'

; sub return_captured
   { my $captured = capture { print 'a' }
   ; is $$captured, 'a', 'Inner capture'
   ; $captured
   }
   

