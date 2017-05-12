package Inline::CPR;

use strict;
require Inline;
use Data::Dumper;
use FindBin;
use Config;
use Carp;
use Cwd;

$Inline::CPR::VERSION = '0.12';
@Inline::CPR::ISA = qw(Inline);

#==============================================================================
# Register this module as an Inline language support module
#==============================================================================
sub register {
    return {
	    language => 'CPR',
	    type => 'compiled',
	    suffix => $Config{so},
	   };
}

#==============================================================================
# Validate the CPR config options
#==============================================================================
sub validate {
    my $o = shift;

    while (@_) {
	my ($key, $value) = (shift, shift);

	if ($key eq 'LIBS') {
	    push(@{$o->{ILSM}{makefile}{LIBS}}, 
		 (ref $value) ? (@$value) : ($value));
	    next;
	}
	if ($key eq 'INC') {
	    $o->{ILSM}{makefile}{INC} = $value;
	    next;
	}
	if ($key eq 'MYEXTLIB') {
	    $o->{ILSM}{makefile}{MYEXTLIB} .= ' ' . $value;
	    next;
	}
	if ($key eq 'LDFROM') {
	    $o->{ILSM}{makefile}{LDFROM} = $value;
	    next;
	}
	if ($key eq 'TYPEMAPS') {
	    push(@{$o->{ILSM}{makefile}{TYPEMAPS}}, 
		 (ref $value) ? (@$value) : ($value));
	    next;
	}
	if ($key eq 'AUTO_INCLUDE') {
	    chomp($value);
	    $o->{ILSM}{AUTO_INCLUDE} .= $value . "\n";
	    next;
	}
	croak "$key is not a valid config option for CPR\n";
    }
}

#==============================================================================
# Parse and compile CPR code
#==============================================================================
sub build {
    my $o = shift;
    $o->config;
    $o->parse;
    $o->write_XS;
    $o->write_CPR_headers;
    $o->write_Makefile_PL;
    $o->compile;
}

#==============================================================================
# Return a small report about the CPR code..
#==============================================================================
sub info {
    my $o = shift;
    my $text = '';
    $o->parse unless $o->{ILSM}{parser};
    if (defined $o->{ILSM}{parser}{data}{functions}) {
    }
    else {
	$text .= "No $o->{API}{language} functions have been successfully bound to Perl.\n\n";
    }
    return $text;
}

sub config {
    my $o = shift;
    $o->{ILSM}{auto_include} ||= <<END;
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "CPR.h"
END
}

#==============================================================================
# Parse the function definition information out of the CPR code
#==============================================================================
sub parse {
    my $o = shift;

#    return if $o->{ILSM}{parser};

    $o->{API}{code} =~ 
      s!int\s*main\s*\(\s*void\s*\)\s*\{!int cpr_main(void) {!ms;

}

#==============================================================================
# Generate the XS glue code
#==============================================================================
sub write_XS {
    my $o = shift;
    my ($pkg, $module, $modfname) = @{$o->{API}}{qw(pkg module modfname)};

    $o->{ILSM}{AUTO_INCLUDE} ||= '';
    $o->mkpath($o->{API}{build_dir});
    open XS, "> $o->{API}{build_dir}/$modfname.xs"
      or croak $!;
    print XS <<END;
$o->{ILSM}{auto_include}
$o->{ILSM}{AUTO_INCLUDE}
$o->{API}{code}

MODULE = $module     	PACKAGE = $pkg

PROTOTYPES: DISABLE

int
cpr_main()

END
    close XS;
}

#==============================================================================
# Generate the INLINE.h file.
#==============================================================================
sub write_CPR_headers {
    my $o = shift;

    open HEADER, "> $o->{API}{build_dir}/CPR.h"
      or croak;

    print HEADER <<'END';
#define CPR_eval(x) SvPVX(perl_eval_pv(x, 1))
END

    close HEADER;
}

#==============================================================================
# Generate the Makefile.PL
#==============================================================================
sub write_Makefile_PL {
    my $o = shift;

    $o->{ILSM}{makefile} ||= {};

    my %options = (
		   VERSION => '0.00',
		   %{$o->{ILSM}{makefile}},
		   NAME => $o->{API}{module},
		  );
    
    open MF, "> $o->{API}{build_dir}/Makefile.PL"
      or croak;
    
    print MF <<END;
use ExtUtils::MakeMaker;
my %options = %\{       
END

    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 1;
    print MF Data::Dumper::Dumper(\ %options);

    print MF <<END;
\};
WriteMakefile(\%options);
END
    close MF;
}

#==============================================================================
# Run the build process.
#==============================================================================
sub compile {
    my ($o, $perl, $make, $cmd, $cwd);
    $o = shift;
    my ($module, $modpname, $modfname, $build_dir, $install_lib) = 
      @{$o->{API}}{qw(module modpname modfname build_dir install_lib)};

    -f ($perl = $Config::Config{perlpath})
      or croak "Can't locate your perl binary";
    ($make = $Config::Config{make})
      or croak "Can't locate your make binary";
    $cwd = &cwd;
    for $cmd ("$perl Makefile.PL > out.Makefile_PL 2>&1",
	      \ &fix_make,   # Fix Makefile problems
	      "$make > out.make 2>&1",
	      "$make install > out.make_install 2>&1",
	     ) {
	if (ref $cmd) {
	    $o->$cmd();
	}
	else {
	    chdir $build_dir;
	    system($cmd) and do {
#		$o->error_copy;
		croak <<END;

A problem was encountered while attempting to compile and install your Inline
$o->{API}{language} code. The command that failed was:
  $cmd

The build directory was:
$build_dir

To debug the problem, cd to the build directory, and inspect the output files.

END
	    };
	    chdir $cwd;
	}
    }

    if ($o->{API}{cleanup}) {
	$o->rmpath($o->{API}{directory} . '/build/', $modpname);
	unlink "$install_lib/auto/$modpname/.packlist";
	unlink "$install_lib/auto/$modpname/$modfname.bs";
	unlink "$install_lib/auto/$modpname/$modfname.exp"; #MSWin32 VC++
	unlink "$install_lib/auto/$modpname/$modfname.lib"; #MSWin32 VC++
    }
}

#==============================================================================
# This routine fixes problems with the MakeMaker Makefile.
# Yes, it is a kludge, but it is a necessary one.
# 
# ExtUtils::MakeMaker cannot be trusted. It has extremely flaky behaviour
# between releases and platforms. I have been burned several times.
#
# Doing this actually cleans up other code that was trying to guess what
# MM would do. This method will always work.
# And, at least this only needs to happen at build time, when we are taking 
# a performance hit anyway!
#==============================================================================
my %fixes = (
	     INSTALLSITEARCH => 'install_lib',
	     INSTALLDIRS => 'installdirs',
	    );

sub fix_make {
    use strict;
    my (@lines, $fix);
    my $o = shift;

    $o->{ILSM}{install_lib} = $o->{API}{install_lib};
    $o->{ILSM}{installdirs} = 'site';
    
    open(MAKEFILE, "< $o->{API}{build_dir}/Makefile")
      or croak "Can't open Makefile for input: $!\n";
    @lines = <MAKEFILE>;
    close MAKEFILE;

    open(MAKEFILE, "> $o->{API}{build_dir}/Makefile")
      or croak "Can't open Makefile for output: $!\n";
    for (@lines) {
	if (/^(\w+)\s*=\s*\S+.*$/ and
	    $fix = $fixes{$1}
	   ) {
	    print MAKEFILE "$1 = $o->{ILSM}{$fix}\n"
	}
	else {
	    print MAKEFILE;
	}
    }
    close MAKEFILE;
}

1;

__END__
