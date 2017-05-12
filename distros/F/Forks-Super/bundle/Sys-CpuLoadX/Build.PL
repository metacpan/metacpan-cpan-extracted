use strict;
use warnings;
use Module::Build 0.25;
use Module::Build::ConfigData;
use Carp;


#############################################################################

my $moduleName = 'Sys::CpuLoadX';
my $pmFileName = 'lib/Sys/CpuLoadX.pm';

my $builderclass = Module::Build->subclass(

    class => 'Sys::CpuLoadX::Custom::Builder',
    code => <<'__CUSTOM_BUILD_CODE__,',
    my $xsFileName = 'lib/Sys/CpuLoadX.xs';
    sub ACTION_build {
	use File::Copy;
	my $self = shift;
	foreach my $required_dir (qw(lib/xs contrib/ok contrib/fail)) {
	    mkdir $required_dir unless -d $required_dir;
	}

	### STEP 1: Try to compile each .xs file in ./contrib/ ###
	if (!glob("contrib/fail/*.xs") && ! -f $xsFileName) {
	    foreach my $contrib_file (glob("contrib/*.xs")) {
		my $xs_file = $contrib_file;
		$xs_file =~ s!contrib!lib/xs!;
		File::Copy::copy($contrib_file, $xs_file);
		local $@ = undef;
		eval { $self->ACTION_code() };
		if ($@) {
		    print "\n\nFailed to compile $xs_file\n\n";
		    print $@ if $ENV{BUILD_DEBUG};
		    File::Copy::move($xs_file, "contrib/fail/");
		} else {
		    print "\n\nSuccessfully compiled $xs_file\n\n";
		    File::Copy::move($xs_file, "contrib/ok/");
		}
		unlink <lib/xs/*>;
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
		    } else {
			push @PREMOD, $_;
		    }
		}
		close $xs_fh;
		print "Incorporating $xs into $xsFileName\n";
	    }
	    unlink <contrib/ok/*.xs>,<contrib/fail/*.xs>,$xsFileName;
	    if (@POSTMOD) {
		open my $xs_fh, '>', $xsFileName or croak $!;
		print $xs_fh @INCLUDE, @PREMOD, $MODULE, @POSTMOD, "\n\n\n";
		close $xs_fh;
	    }
	}

	unlink glob("lib/xs/*.xs"), glob("lib/xs/*.o"), glob("lib/xs/*.c");
	$self->ACTION_code();
	return $self->SUPER::ACTION_build(@_);
    }

__CUSTOM_BUILD_CODE__,
 
);

#############################################################################

mkdir 'lib/xs' unless -d 'lib/xs';
open(FOO, '>>', 'lib/xs/foo') && close FOO unless -f 'lib/xs/foo';
my $bugtracker_url 
    = 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Sys-CpuLoadX';

my $builder = $builderclass->new(
	module_name         => 'Sys::CpuLoadX',
	license             => 'perl',
	dist_author         => q[Marty O'Brien <mob@cpan.org>],
	dist_version_from   => $pmFileName,
	build_requires      => {
		'Module::Build'      => 0.25,
		'Test::More'         => 0,
	},
	recommends          => {
		'ExtUtils::CBuilder' => 0.15,
	},
	meta_merge => {
	    resources       => { bugtracker  => $bugtracker_url },
	    keywords        => [ qw/cpu load/ ],
	},
	add_to_cleanup      => [ 'Sys-CpuLoadX-*', '_build', 'Build', 
			         '*.xs.o', 'lib/xs/*.xs', 'blib',
				 'lib/Sys/CpuLoadX.c',
				 'lib/Sys/CpuLoadX.o',
				 'lib/Sys/CpuLoadX.xs',
                                 'contrib/ok/*.*', 'contrib/fail/*.*',
                                 'pod2htm*.*',
				 ],
	create_makefile_pl  => 'passthrough',
        include_dirs => ['include'],
	sign                => 0,
);

# if $^O =~ /irix/, then we want to compile with  -lcpuset

$builder->create_build_script();

__END__


The Sys::CpuLoadX module contains several small XS/C functions
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
      .xs file (lib/Sys/CpuLoadX.xs). Erase all traces of
      the individual .xs units.

   5) Call ACTION_code one more time to compile the
      installation-specific .xs file and continue the build.

