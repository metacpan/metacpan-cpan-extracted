use Canary::Stability IO::AIO => 1, 5.008002;

use ExtUtils::MakeMaker;

use Config;

if ($^O eq "MSWin32") {
   # configuration on windows is hardcoded - as always

   print STDERR <<EOF;

***
*** Your platform is not standards compliant. To get this module working, you need to
*** download and install win32 pthread (http://sourceware.org/pthreads-win32/).
***

EOF

   if(0){
      if ($Config{cc} =~ /(?:^|\\|\/)gcc(?:|.*\.exe)$/) {
         $INC  = "$ENV{INC} -I/gtk/include";
         $LIBS = ["$ENV{LIBS} -L/gtk/lib -lpthreadGC2"];
      } else {
         $INC  = "$ENV{INC} -I/sdk/include -I/vc98/include -I/gtk/include";
         $LIBS = ["$ENV{LIBS} -L/gtk/lib -lpthreadVC2"];
      }
   }

   open my $fh, ">config.h"
      or die "config.h: $!";
   print $fh <<EOF;
EOF

} else {

   $INC  = "";
   $LIBS = ['-lpthread', '-lpthreads', ''];

   if ($^O =~ /bsd/i) {
      print <<EOF;

If you have problems with deadlocks or crashes on your system,
make sure your perl has been linked with -lpthread (you might try
LD_PRELOAD=/path/to/libpthread.so as a workaround). Also, pthread support
under many BSDs is not the best - before reporting a bug in this module,
make sure it's not an OS bug.

EOF
   }

   {
      local %ENV = %ENV;

      while (my ($k, $v) = each %Config) {
         $ENV{$k} = $v;
      }

      $ENV{MAKE}     = $Config{make};
      $ENV{SHELL}    = $Config{sh};
      $ENV{CC}       = $Config{cc};
      $ENV{CPPFLAGS} = "$Config{cppflags} -I$Config{archlibexp}/CORE";
      $ENV{CFLAGS}   = $Config{ccflags};
      $ENV{LDFLAGS}  = "$Config{ldflags} $Config{ccdlflags}";
      $ENV{LINKER}   = $Config{ld}; # nonstandard
      $ENV{LIBS}     = "-L$Config{archlibexp}/CORE -L$Config{privlibexp} -lperl $Config{perllibs}";

      system $ENV{SHELL}, -c => "./configure --prefix \Q$Config{prefixexp}\E"
         and exit $? >> 8;
   }
}

if ($^O =~ /linux/ && $Config{usemymalloc} eq "y") {
   print <<EOF;

***
*** WARNING:
***
*** Your perl uses its own memory allocator (-Dusemymalloc=y),
*** which is known not to be threadsafe on GNU/Linux and probably
*** other platforms (even when not used concurrently, it trashes
*** the data structures of the system malloc running concurrently),
*** for perls up to 5.8.8 and possibly later versions.
***
*** If you are unsure wether your perl has been fixed, your system
*** is safe for other reasons, or you experience spurious segfaults,
*** please compile your perl with -Dusemymalloc=n.
***

EOF
}

my $mm = MM->new({
    dist         => {
       PREOP	=> 'pod2text AIO.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
       COMPRESS	=> 'gzip -9v',
       SUFFIX	=> '.gz',
    },
    depend => {
       "AIO.c" => "schmorp.h libeio/eio.h libeio/xthread.h libeio/etp.c libeio/eio.c config.h",
    },
    NAME         => "IO::AIO",
    VERSION_FROM => "AIO.pm",
    INC          => $INC,
    LIBS         => $LIBS,
    EXE_FILES    => ["bin/treescan"],
    PM           => {
       'AIO.pm'		=> '$(INST_LIB)/IO/AIO.pm',
    },
    CONFIGURE_REQUIRES => { ExtUtils::MakeMaker => 6.52, Canary::Stability => 2001 },
    PREREQ_PM => {
       "common::sense" => 0,
    },
    clean        => { FILES => "config.h libeio/config.h libeio/config.log libeio/config.status" },
});

$mm->flush;

