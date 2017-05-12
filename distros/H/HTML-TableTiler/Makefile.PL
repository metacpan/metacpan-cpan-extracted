# This file uses the "Perlish" coding style
# please read http://perl.4pro.net/perlish_coding_style.html

; use ExtUtils::MakeMaker

; my $pm = 'lib/HTML/TableTiler.pm'

; WriteMakefile
   ( NAME           => 'HTML::TableTiler'
   , VERSION_FROM   => $pm
   , ($] ge '5.005')
     ? ( AUTHOR        => 'Domizio Demichelis - perl.4pro.net'
       , ABSTRACT_FROM => $pm
       )
     : ()
   , PREREQ_PM	     => { 'HTML::PullParser' => '1.0'
                       , 'IO::Util'         => '1.2'
                       }
   )


; 1


