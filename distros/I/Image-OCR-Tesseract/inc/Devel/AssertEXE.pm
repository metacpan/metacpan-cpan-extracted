package Devel::AssertEXE;
use strict;


sub import {
   shift;
   die("Devel::AssertEXE needs at least one parameter\n") unless (@_);
   have_exe_or_exit(@_);
}


sub have_exe_or_exit {
   for my $exe (@_){
      have_exe($exe)
         or exit;
   }
}

sub have_exe {
   my $exe = shift;
   `which $exe 2> /dev/null`
      or warn("Cannot find $exe executable.\n")
      and return;
   return 1;
}


1;

