use strict;
use warnings;
use Module::Build 0.25;
use Module::Build::ConfigData;
use Carp;


if ($ENV{AUTOMATED_TESTING} && !$ENV{BUILD_EVEN_IF_AUTOMATED_TESTING}) {

  # in general, it should be OK to install this distribution on 
  # a single-processor system. However many of the tests are
  # either skipped or dumbed down for single-processor systems,
  # and the resulting PASS reports from the CPAN testers are
  # not so valuable.

  # Some systems may require the XS code to be built before the
  # number of processors can be detected (Irix is like that),
  # so this gate check won't always work.

  use Config;
  my $status = system($Config{perlpath}, "-Ilib", "-MSys::CpuAffinity",
		      "-e", "exit Sys::CpuAffinity::getNumCpus()");

  if ($status >> 8 == 1) {

    print STDERR <<"___";

Single processor system with automated smoke testing detected.
Aborting build because many tests in this distribution are skipped
or dumbed down for single-processor systems, and the resulting
PASS reports from the CPAN testers are not as helpful.

Set \$ENV{AUTOMATED_TESTING} to a false value OR
\$ENV{BUILD_EVEN_IF_AUTOMATED_TESTING} to a true value
if you really wish to build and install this module as 
opposed to just testing it.

___
  ;

    # a CPAN tester hack to get an NA report
    # instead of a FAIL report
    die "No support for OS - one processor and automated testing";

  }
}


# some platform specific notes ...

print "\n";
if ($^O =~ /aix/i) {
  print <<"";
$^O users: this platform's  bindprocessor(1)  utility and  bindprocessor(2)
library function only allow a process to be bound to a single
CPU. Calls to  &Sys::CpuAffinity::setAffinity  that specify more than
one but fewer than all processors might have the effect of only
binding the process to a single processor.

;                                                                     #';
}
if ($^O =~ /irix/i) {
  print <<"";
$^O users: this platform generally only allows a process to be bound
to a single CPU. Calls to  &Sys::CpuAffinity::setAffinity  that specify
more than one processor might only bind the process to a single
processor. Also note that the XS functions in this distribution for
$^O may be, ahem, under-tested.

;
}

if ($^O =~ /netbsd/i) {
  print <<"";
$^O users: the  Sys::CpuAffinity::getAffinity  and  setAffinity  methods
on this platform generally
    * can only get/set the CPU affinity of the calling process
    * can only be used by the super-user

;
}
print "\n";

if ($^O =~ /darwin|MacOS|openbsd/i) {
    print <<"";
$^O users: no known method to support getting and setting CPU affinity
on this platform. You should only expect the  Sys::CpuAffinity::getNumCpus
function from this distribution to work.

;
}


unlink "lib/Sys/CpuAffinity.xs";


#############################################################################

my $builderclass = Module::Build->subclass(

 class => 'Sys::CpuAffinity::Custom::Builder',
 code => <<'__CUSTOM_BUILD_CODE__,',
 sub ACTION_build {
   use File::Copy;
   my $self = shift;
   my @successfully_compiled;
   my $DEBUG = $ENV{DEBUG};

   ### STEP 1: Try to compile each .xs file in ./contrib/ ###
   if (!glob("contrib/fail/*.xs") && ! -f 'lib/Sys/CpuAffinity.xs') {
     foreach my $contrib_file (glob("contrib/*.xs")) {
       mkdir 'lib/xs' unless -d 'lib/xs';
       my $xs_file = $contrib_file;
       $xs_file =~ s!contrib!lib/xs!;
       File::Copy::copy($contrib_file, $xs_file);
       local $@ = undef;
       eval { $self->ACTION_code() };
       if ($@) {
           print "\n\nFailed to compile $xs_file\n\n";
           print "$@\n" if $DEBUG;
           File::Copy::move($xs_file, "contrib/fail/");
       } else {
           print "\n\n---------------\nSuccessfully compiled $xs_file\n";
           print "---------------\n\n";
           push @successfully_compiled, $xs_file;
           File::Copy::move($xs_file, "contrib/ok/");
       }
       unlink <lib/xs/*>;
     }
     if (@successfully_compiled == 0) {
       warn q[
None of the XS code snippets successfully compiled.
Perhaps you don't have a compiler on your system, or
perhaps it is not configured correctly.

On some systems and configuration, this module might
still work without any XS code, so let's not worry
about this just yet.
];
     } else {
       print "======================================\n";
       print "Successfully compiled:\n\n\t";
       print join "\n\t", @successfully_compiled;
       print "\n======================================\n";
     }
   }

   ### STEP 2: Combine contrib/ok/.xs files ###
   if (glob("contrib/ok/*.xs")) {
     my (@INCLUDE,%INCLUDE,$MODULE,@PREMOD,@POSTMOD);
     foreach my $xs (glob("contrib/ok/*.xs")) {
       open my $xs_fh, '<', $xs;
       while (<$xs_fh>) {
	 if (m"#include") {
	   next if $INCLUDE{$_}++;
	   push @INCLUDE, $_;
	 } elsif (/^MODULE/) {
	   $MODULE = $_;
	   push @POSTMOD, <$xs_fh>;
           push @POSTMOD, "\n\n";
	 } else {
	   push @PREMOD, $_;
	 }
       }
       close $xs_fh;
       print "Incorporating $xs into lib/Sys/CpuAffinity.xs\n";
     }
     print "\n";
     unlink <contrib/ok/*.xs>,<contrib/fail/*.xs>,'lib/Sys/CpuAffinity.xs';
     if (@POSTMOD) {
       open my $xs_fh, '>', 'lib/Sys/CpuAffinity.xs' or croak $!;
       print $xs_fh @INCLUDE, @PREMOD, $MODULE, @POSTMOD, "\n\n\n";
       close $xs_fh;
     }
   }

   unlink glob("lib/xs/*.xs"), glob("lib/xs/*.o"), glob("lib/xs/*.c");
   $self->ACTION_code();
   return $self->SUPER::ACTION_build(@_);
 }
  sub ACTION_dist {
    my $self = shift;
    foreach my $foodir (qw(lib/xs contrib/ok contrib/fail)) {
      mkdir $foodir unless -d $foodir;
      open FOO, '>>', "$foodir/foo";
      close FOO;
    }
    $self->SUPER::ACTION_dist(@_);
  }

__CUSTOM_BUILD_CODE__,
 
);

#############################################################################

mkdir 'lib/xs' unless -d 'lib/xs';
unless (-f 'lib/xs/foo') {
  my $fooh;
  open($fooh, '>>', 'lib/xs/foo') && close $fooh;
}
my $bugtracker_url 
  = 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Sys-CpuAffinity';

my $extra_compiler_flags = '';
my $extra_linker_flags = '';
if ($^O =~ /irix/) {
  # $extra_linker_flags = '-lcpuset';
}
if ($^O =~ /netbsd/i) {
  $extra_linker_flags = '-lpthread';
}

my $recommends = { 'ExtUtils::CBuilder' => 0.15 };
if ($^O =~ /freebsd/i) {
   $recommends->{'BSD::Process::Affinity'} = 0.04;
}
if ($^O eq 'MSWin32' || $^O =~ /cygwin/i) {
   $recommends->{'Win32::API'} = 0.51;
}

my $builder = $builderclass->new(
	module_name         => 'Sys::CpuAffinity',
	license             => 'perl',
	dist_author         => q[Marty O'Brien <mob@cpan.org>],
        #dist_version        => '1.12',
	dist_version_from   => 'lib/Sys/CpuAffinity.pm',
	build_requires      => {
		'Module::Build'      => 0.25,
		'Test::More'         => 0,
	},
	configure_requires      => {
		'Module::Build'      => 0.25,
	},
	recommends          => $recommends,
	meta_merge => {
	    resources       => { bugtracker  => $bugtracker_url },
	    keywords        => [ qw/affinity/ ],
	},
        add_to_cleanup      => [ 'Sys-CpuAffinity-*', '_build', '*.exp',
                                 '*.exp_old',
			         '*.xs.o', 'lib/xs/*', 
				 'lib/Sys/CpuAffinity.c',
				 'lib/Sys/CpuAffinity.o',
				 'lib/Sys/CpuAffinity.xs',
                                 'contrib/ok/*.xs', 'contrib/fail/*.xs',
                                 'lib*.def', 'ipc.*',
                                 'blib', 'pod2htm*',
                                 'Makefile', 'Build', 'Build.bat',
                                 'perl*.stackdump', 'libcompilet*',
				 ],
	create_makefile_pl  => 'passthrough',
	extra_compiler_flags => $extra_compiler_flags,
	extra_linker_flags   => $extra_linker_flags,
	sign                 => 0,
);

$builder->create_build_script();

__END__


The Sys::CpuAffinity module contains several small XS/C functions
that target features on many different operating systems. On any
particular system, most of the XS files won't compile.

So we use a pretty radical build process to find the largest
subset of valid XS files for each installation. This file
overloads the Module::Build::ACTION_build method with a procedure
that:

   1) Copies all .xs files from the ./contrib directory
      into the ./lib/xs/ directory.

   2) Calls the Module::Build::ACTION_code method. This will
      invoke the ExtUtils::CBuilder module to attempt to
      compile all the .xs files under the lib/ directory.

   3) When ACTION_code fails, parse the error message (in $@)
      to determine which .xs file could not be compiled.
      Erase that file and repeat step 2.

   4) Combine all the remaining valid .xs files into a single
      .xs file (lib/Sys/CpuAffinity.xs). Erase all traces of
      the individual .xs units.

   5) Call ACTION_code one more time to compile the
      installation-specific .xs file and continue the build.

