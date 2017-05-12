# This file uses the "Perlish" coding style
# please read http://perl.4pro.net/perlish_coding_style.html

; use 5.006_001
; use ExtUtils::MakeMaker

; my $pm = 'lib/IO/Util.pm'

; WriteMakefile
   ( NAME           => 'IO::Util'
   , VERSION_FROM   => $pm
   , ( $] ge '5.005' )
     ? ( AUTHOR          => 'Domizio Demichelis - perl.4pro.net'
       , ABSTRACT_FROM   => $pm
       )
     : ()
   , PREREQ_PM      => { 'Time::HiRes'   => 0
                       , 'Sys::Hostname' => 0
                       }
   )


; 1

