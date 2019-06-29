use strict qw(vars subs);
use Canary::Stability EV => 1, 5.008002;
use Config;
use ExtUtils::MakeMaker;

sub have_inc($) {
   scalar grep -r "$_/$_[0]", $Config{usrinc}, split / /, $Config{incpth}
}

my $DEFINE;

unless (-e "libev/ev_linuxaio.c") {
   print <<EOF;

***
*** ERROR: libev is missing or damaged. If you used a CVS check-out of EV,
*** you also have to check-out the "libev" module from the same CVS
*** repository into the EV dir (i.e. EV/libev from outside).
***

EOF
   exit 1;
}

print <<EOF;

*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***


Welcome to EV configuration. If you are in a hurry, just press return here
and hope for the best. The defaults should usually do.

EOF

if (prompt ("Skip further questions and use defaults (y/n)?", "y") =~ /[yY]/) {
   $ENV{PERL_MM_USE_DEFAULT} = 1;
}

print <<EOF;

*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***


POSIX optionally offers support for a monotonic clock source. EV
can take advantage of this clock source to detect time jumps more
reliably. Unfortunately, some systems are bound to be broken, so you can
disable this here: you can completely disable the detection and use of
the monotonic clock by answering 'n' here. Support for this clock type
will otherwise be autodetected at both compile- and runtime. (this setting
currently affects the use of nanosleep over select as well).

EOF

unless (prompt ("Enable optional support for CLOCK_MONOTONIC (y/n)?", "y") =~ /[yY]/) {
   $DEFINE .= " -DEV_USE_MONOTONIC=0";
}

print <<EOF;

*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***


POSIX optionally offers support for a (potentially) high-resolution
realtime clock interface. In a good implementation, using it is faster
than the normal method of using gettimeofday. Unfortunately, this option
is also bound to be broken on some systems, and current EV versions do not
actually call gettimeofday very often, so it defaults to no.

EOF

$DEFINE .= " -DEV_USE_REALTIME=" . (0 + (prompt ("Prefer clock_gettime (CLOCK_REALTIME) over gettimeofday (y/n)?", "n") =~ /[yY]/));

print <<EOF;

*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***


EV can use various backends with various portability issues. The select
backend is the most portable and makes for a good fallback, but it can be
limited to a low number of file descriptors and/or might not compile. If
you have problems with compiling ev_select.c, you might try to play around
with disabling it here, or forcing it to use the fd_set provided by your
OS, via the next question. I highly recommend keeping it in.

EOF

if (prompt ("Enable select backend (y/n)?", "y") =~ /[yY]/) {
   $DEFINE .= " -DEV_USE_SELECT=1";

   print <<EOF;

*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***


The select backend can operate in two modes. One uses the system-provided
fd_set and is usually limited to 1024 file descriptors (64 on windows),
the other requires your header files to define NFDBITS and declare a
suitable fd_mask type. If you run into problems compiling ev_select.c, you
can try forcing the use of the system fd_set here.

EOF

   if (prompt ("Force use of system fd_set for select backend (y/n)?", "n") =~ /[yY]/) {
      $DEFINE .= " -DEV_SELECT_USE_FD_SET";
   }
} else {
   $DEFINE .= " -DEV_USE_SELECT=0";
}

print <<EOF;

*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***


The second very portable backend is poll(2). It does not exist on windows
and various versions of Mac OS X (and on the other versions it simply
doesn't work), but works basically everywhere else. It is recommended to use
the default here unless you run into compile problems in ev_poll.c.

EOF

$DEFINE .= " -DEV_USE_POLL=" . (0 + (prompt ("Enable poll backend (y/n)?", (have_inc "poll.h") ? "y" : "n") =~ /[yY]/));

print <<EOF;

*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***


Select and poll make it hard to write efficient servers, especially if the
number of active connections is much lower than the watched ones. GNU/Linux
systems have a more scalable method called "epoll", which EV can use. For
this to work, both your kernel and glibc have to support epoll, but if you
can compile it, the detection will be done at runtime, and EV will safely
fall back to using select when epoll isn't available. If unsure, accept
the default.

EOF

my $can_epoll = have_inc "sys/epoll.h";
$can_epoll = $ENV{EV_EPOLL} if exists $ENV{EV_EPOLL};
$DEFINE .= " -DEV_USE_EPOLL=" . (0 + (prompt ("Enable epoll backend (y/n)?", $can_epoll ? "y" : "n") =~ /[yY]/));

print <<EOF;

*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***


Linux 4.18 introduced another event polling interface, this time using
the Linux AIO API. While this API is far superior to epoll and almost
rivals kqueue, it also suffers from the same issues as kqueue typically
does: only a subset of file types are supported (as of 4.19, I have seen
eventfd, pipes, sockets files and some devices, but no ttys). It also
is subject arbitrary system-wide limits imposed on it. Therefore, this
backend is not used by default, even when it is compiled in, and you have
to request it explicitly, e.g. with LIBEV_FLAGS=64. If unsure, accept the
default.

EOF

my $can_linuxaio = have_inc "linux/aio_abi.h";
$can_linuxaio = $ENV{EV_LINUXAIO} if exists $ENV{EV_LINUXAIO};
$can_linuxaio = 0 + (prompt ("Enable linux aio backend (y/n)?", $can_linuxaio ? "y" : "n") =~ /[yY]/);
$DEFINE .= " -DEV_USE_LINUXAIO=$can_linuxaio";

if ($can_linuxaio) {
print <<EOF;

*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***


The previously mentioned Linux AIO backend is experimental and will not
be used unless requested explicitly. You can, howeer, choose to make ti a
recommended basckend, which means it will be chosen if available even when
not explicitly asked for, in preference to epoll on GNU/Linux. This option
is likely temporary. When unsure, accept the default.

EOF

my $recommend_linuxaio = 0;
$recommend_linuxaio = $ENV{EV_RECOMMEND_LINUXAIO} if exists $ENV{EV_RECOMMEND_LINUXAIO};
$recommend_linuxaio = 0 + (prompt ("Treat linux aio as a recommended backend (y/n)?", $recommend_linuxaio ? "y" : "n") =~ /[yY]/);
$DEFINE .= " -DEV_RECOMMEND_LINUXAIO=$recommend_linuxaio";
}

print <<EOF;

*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***


Similarly to the epoll backend above, EV can take advantage of kqueue on
many BSD systems. Support for kqueue will be detected at runtime, with a
safe fallback to other methods when it cannot be used.

Note that kqueue is broken on most operating systems, so by default it
won't be used on many platforms, but you can still create your own event
loop with kqueue backend if you ask specifically for it.

Here is what we know:

NetBSD:  partially working in at least 3.1 and later. Yeah! :)
FreeBSD: broken on at least 6.2-STABLE, spotty in later versions,
         sockets *likely* work, ptys definitely don't.
OpenBSD: reports indicate that it likely doesn't work
         (similar problems as on FreeBSD).
OS X:    completely, utterly broken on at least <= 10.6.

EOF

my $can_kqueue = have_inc "sys/event.h";
$can_kqueue = $ENV{EV_KQUEUE} if exists $ENV{EV_KQUEUE};
$DEFINE .= " -DEV_USE_KQUEUE=" . (0 + (prompt ("Enable kqueue backend (y/n)?", $can_kqueue ? "y" : "n") =~ /[yY]/));

print <<EOF;

*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***


Similarly to the kqueue backend above, EV can take advantage of the
solaris 10 event port interface. Support for event ports will be detected
at runtime, with a safe fallback to other methods when it cannot be used.

EOF

$DEFINE .= " -DEV_USE_PORT=" . (0 + (prompt ("Enable event port backend (y/n)?", (have_inc "sys/port.h") ? "y" : "n") =~ /[yY]/));

print <<EOF;

*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***


EV needs the functions pthread_atfork and clock_gettime. On most systems
you need some special libraries for this (such as -lrt and -lpthread). You
can specify additional libraries to provide these calls (and any other
required by EV) now, or accept the default.

On GNU/Linux systems, EV uses the LSB 3.1 __register_atfork function
to avoid the dependency on libpthread, and directly uses the clock_gettime
syscall to avoid a dependency on librt.

EOF

my $solaris_libs = $^O =~ /solaris/i ? "-lsocket -lnsl" : "";
my $librt = $^O =~ /linux/i ? "" : "-lpthread -lrt";
my $LIBS = exists $ENV{EV_LIBS} ? $ENV{EV_LIBS} : "$librt $solaris_libs";
$LIBS = prompt "Extra libraries for pthread_atfork and clock_gettime?", $LIBS;


print <<EOF;

*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***


A backend of a different kind is the Linux inotify(7) interface, which can
be used to speed up (and reduce resource consumption) of stat watchers. If
you have the include file and libc support for it, it is usually a good
idea to enable it, as kernel availability is detected at runtime.

EOF

my $can_inotify = have_inc "sys/inotify.h";
$can_inotify = $ENV{EV_INOTIFY} if exists $ENV{EV_INOTIFY};
$DEFINE .= " -DEV_USE_INOTIFY=" . (0 + (prompt ("Enable inotify support (y/n)?", $can_inotify ? "y" : "n") =~ /[yY]/));

print <<EOF;

*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***


Another useful bit of functionality is the Linux eventfd, which is useful
for faster signal handling (don't care) and intra-thread communications
(more relevant). Kernel support for this will be probed at runtime, but
your libc must contain the necessary wrapper. Glibc 2.7 and later should
have this wrapper.

EOF

my $can_eventfd = have_inc "sys/eventfd.h";
$can_eventfd = $ENV{EV_EVENTFD} if exists $ENV{EV_EVENTFD};
$DEFINE .= " -DEV_USE_EVENTFD=" . (0 + (prompt ("Enable linux eventfd support (y/n)?", $can_eventfd ? "y" : "n") =~ /[yY]/));

print <<EOF;

*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***


Another sometimes useful bit of functionality is the Linux signalfd, which
is useful for faster signal handling (don't care). Kernel support for
this will be probed at runtime, but your libc must contain the necessary
wrapper. Glibc 2.7 and later should have this wrapper.

EOF

my $can_signalfd = have_inc "sys/signalfd.h";
$can_signalfd = $ENV{EV_SIGNALFD} if exists $ENV{EV_SIGNALFD};
$DEFINE .= " -DEV_USE_SIGNALFD=" . (0 + (prompt ("Enable linux signalfd support (y/n)?", $can_signalfd ? "y" : "n") =~ /[yY]/));

print <<EOF;

*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***


Libev contains numerous internal assert() invocations to check for
consistency and user errors. These are normally enabled, but most
perl builds disable this error reporting mechanism by default. You
can re-enable these asserts here. Enabling them might help you catch
programming bugs earlier, but might cause a small slowdown. Also, failures
will be reported by aboritng your program, instead of throwing a perl
exception.

If unsure, enable this if you only use this perl installation for
development, and leave it off for use in production environments.

EOF

my $enable_assertions = 0;
$enable_assertions = 0 + (prompt ("Make sure assertions are enabled? (y/n)?", $enable_assertions ? "y" : "n") =~ /[yY]/);
$DEFINE .= " -DEV_ENABLE_ASERTIONS=1" if $enable_assertions;

print <<EOF;

*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***


Very rarely, people want to tweak EV even more, e.g. to exclude
or include certain watcher types or backends. This can be done by adding
extra -D options here, or via the EV_EXTRA_DEFS environment variable.

For example, if you run into compile problems because of missing memory
fences (or you just want extra performance), you can tell EV to not support
smp and threads via -DEV_NO_THREADS.

Normal persons just press enter.

EOF

$DEFINE .= " " . prompt "Any extra -D options?", "$ENV{EV_EXTRA_DEFS}";

print <<EOF;

*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***


EOF

my @anyevent = eval { require AnyEvent; $AnyEvent::VERSION < 5.29 } ? (AnyEvent => 5.29) : ();

WriteMakefile(
    dist	=> {
	            PREOP	=> 'pod2text EV.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    depend => {
       "EV.c" => "EV/EVAPI.h "
               . "libev/ev.c libev/ev.h libev/ev_epoll.c libev/ev_select.c libev/ev_kqueue.c libev/ev_poll.c "
               . "libev/ev_vars.h libev/ev_wrap.h",
    },
    INC       => "-Ilibev",
    DEFINE    => "$DEFINE",
    NAME => "EV",
    LIBS => [$LIBS],
    PREREQ_PM => {
       @anyevent,
       "common::sense" => 0,
    },
    CONFIGURE_REQUIRES => { "ExtUtils::MakeMaker" => 6.52, "Canary::Stability" => 0 },
    VERSION_FROM => "EV.pm",
    PM           => {
		    'EV.pm'		=> '$(INST_LIB)/EV.pm',
		    'EV/EVAPI.h'	=> '$(INST_LIB)/EV/EVAPI.h',
		    'EV/MakeMaker.pm'	=> '$(INST_LIB)/EV/MakeMaker.pm',
		    'libev/ev.h'	=> '$(INST_LIB)/EV/ev.h',
		    'libev/ev.pod'	=> '$(INST_LIB)/EV/libev.pod',
                 },
    MAN3PODS => {
                    'EV.pm'           => '$(INST_MAN3DIR)/EV.$(MAN3EXT)',
                    'EV/MakeMaker.pm' => '$(INST_MAN3DIR)/EV::MakeMaker.$(MAN3EXT)',
                    'libev/ev.pod'    => '$(INST_MAN3DIR)/EV::libev.$(MAN3EXT)',
                },
);


