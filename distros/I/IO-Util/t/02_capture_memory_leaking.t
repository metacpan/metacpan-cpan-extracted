; use strict
; use warnings
; use Data::Dumper
; use Test::More tests => 1
                   
; use IO::Util


; $My::Test = 'A'


; sub IO::Util::WriteHandle::DESTROY
   { $My::Test .= 'B'
   }
   

; { my $out = IO::Util::capture { print 'test' } \*STDOUT
  }

; $My::Test .= 'C'

; is( $My::Test
    , 'ABC'
    , 'Memory leaking test'
    )





