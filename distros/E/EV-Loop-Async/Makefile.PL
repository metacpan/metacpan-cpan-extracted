use ExtUtils::MakeMaker;
use EV::MakeMaker;

print <<EOF;

***
*** This module requires phreads (listening to -lpthread)
*** A pthreads implementation for windows can be found at
*** http://sourceware.org/pthreads-win32/
***
*** Due to bugs in perl, this module does not currently work on windows.
***

EOF

if ($^O =~ /win32/i or $^O =~ /mswin/) {

   # configuration on windows is hardcoded - as always

   warn "your platform is not standards-compliant, you have to port this module first\n";
   warn "using some hardcoded config that will not work on your system\n";
   warn "hint: edit the Makefile.PL\n\n";

   $INC  = "-I/sdk/include -I/vc98/include -I/gtk/include";
   $LIBS = ["-L/gtk/lib -lpthreadVC2"];
} else {
   $INC = "";
   $LIBS = ['-lpthread'],
}

my $mm = MM->new({EV::MakeMaker::ev_args (
    dist         => {
       PREOP	=> 'pod2text Async.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
       COMPRESS	=> 'gzip -9v',
       SUFFIX	=> '.gz',
	            },
    NAME         => "EV::Loop::Async",
    VERSION_FROM => "Async.pm",
    INC          => $INC,
    LIBS         => $LIBS,
    PREREQ_FATAL => 1,
    PREREQ_PM    => {
       EV                  => 4.00,
       Async::Interrupt    => 0.5,
       common::sense       => 0,
    },
    CONFIGURE_REQUIRES => {
       EV                  => 4.00,
       Async::Interrupt    => 0.5,
       common::sense       => 0,
    },
)});

$mm->flush;

