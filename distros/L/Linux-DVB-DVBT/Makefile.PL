use 5.006;
use ExtUtils::MakeMaker qw(prompt WriteMakefile);
use Config;
use strict;

use lib './plib' ;
use Makeutils ;

	my $clib = "./clib" ;

	# Set up info for this module
	my $modinfo_href = init('Linux-DVB-DVBT') ;

	# See if newer version is available
	check_new_version() ;

	## Options
	get_makeopts() ;

	## Check for current settings
	get_config() ;

	## Programs to install
	add_install_progs("script/", [
		qw/dvbt-epg dvbt-ffrec dvbt-record dvbt-scan dvbt-devices dvbt-chans dvbt-multirec dvbt-strength dvbt-tsid-qual/
	]);

	## Defines
	add_defines({
		'HAVE_DVB'		=> 1,
		'HAVE_MPEG2'		=> 0,
		'HAVE_AUDIO'		=> 0,
		'_LARGEFILE_SOURCE'	=> '',			
		'_FILE_OFFSET_BITS'	=> 64,			
		'_GNU_SOURCE'		=> '',			
	}) ;
	
	
	## Add libraries
	add_clibs($clib, {
		'dvb_lib'			=> 1,
		'libng'				=> 1,
		'libmpeg2_stubs'	=> 1,
		'mpeg2audio_stubs'	=> 1,
		'dvb_ts_lib'	=> { 
			'config'		=> {
				'file'			=> 'config.h',
				'func'			=> \&create_ts_config_h,
			},
		},
	}) ;

	## Do any cleanup
	process_makeopts() ;


	## Write Makefile
	
	# See lib/ExtUtils/MakeMaker.pm for details of how to influence
	# the contents of the Makefile that is written.
	WriteMakefile(
	    NAME              => $modinfo_href->{'mod'},
	    VERSION_FROM      => "lib/$modinfo_href->{'modpath'}.pm", # finds $VERSION
	    PREREQ_PM         => {
			'Cwd'					=> 0,
			'File::Basename'		=> 0,
			'File::Path' 			=> 0,
			'File::Spec' 			=> 0,
			'POSIX'					=> 0,
			'Data::Dumper'			=> 0,
			'Test::Pod::Coverage'	=> 1.08,
			'Pod::Coverage' 		=> 0.18,
			'Test::Pod' 			=> 1.22,
	    }, # e.g., Module::Name => 1.1
	    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
	      (ABSTRACT_FROM  => "lib/$modinfo_href->{'modpath'}.pm", # retrieve abstract from module
	       AUTHOR         => 'Steve Price <cpan@sdprice.plus.com>') : ()),
	    LIBS              => ['-lrt'], # e.g., '-lm'
	    DEFINE            => $modinfo_href->{'mod_defines'},
	    INC               => $modinfo_href->{'includes'},
	    EXE_FILES         => $modinfo_href->{'programs'},
	 
	    CCFLAGS			  => $modinfo_href->{'CCFLAGS'},
	    OPTIMIZE	  	  => $modinfo_href->{'OPTIMIZE'},
	    OBJECT            => $modinfo_href->{'objects'}, 
	);


	exit 0 ;

#-----------------------------------------------------------------------------------------------------------------------
sub MY::makemakerdflt 
{
	my $makemakerdflt = get_makemakerdflt() ;
	return $makemakerdflt ;
}

#-----------------------------------------------------------------------------------------------------------------------
sub MY::postamble {
'

## Optional doxygen documentation 
doxygen: FORCE
	cd doxygen && doxygen

## Author target: preview CPAN documentation
cpandoc: FORCE
	perl -MPod::Simple::HTMLBatch -e Pod::Simple::HTMLBatch::go . pod/batch
	cp pod/html_files/style.css pod/batch/_black_with_blue_on_white.css

';
}

#-----------------------------------------------------------------------------------------------------------------------
sub MY::clean_subdirs {
'

## Clean out objects
clean_subdirs: 
	$(RM_F) clib/*/*.o

';
}



#-----------------------------------------------------------------------------------------------------------------------
sub create_ts_config_h
{
	my ($fname, %current_config) = @_ ;

	open my $fh, ">$fname" or die "Error: Unable to write $fname : $!" ;

	#-------------------------------------------------------------
	## File
	print $fh <<CONFIG_H ;
/* $Config{archname} */
#ifndef CONFIG_H
#define CONFIG_H
	
/* Architecture */
#define $current_config{ARCH}

/* Define to 1 if you have the <inttypes.h> header file. */
$current_config{HAVE_INTTYPES_H}

/* Define to 1 if you have the <stdint.h> header file. */
$current_config{HAVE_STDINT_H}

/* Define to 1 if you have the <stdlib.h> header file. */
$current_config{HAVE_STDLIB_H}

/* Define to 1 if you have the <strings.h> header file. */
$current_config{HAVE_STRINGS_H}

/* Define to 1 if you have the <string.h> header file. */
$current_config{HAVE_STRING_H}

/* Define to 1 if the system has the type `struct timeval'. */
$current_config{HAVE_STRUCT_TIMEVAL}

/* Define to 1 if you have the <sys/stat.h> header file. */
$current_config{HAVE_SYS_STAT_H}

/* Define to 1 if you have the <sys/timeb.h> header file. */
$current_config{HAVE_SYS_TIMEB_H}

/* Define to 1 if you have the <sys/time.h> header file. */
$current_config{HAVE_SYS_TIME_H}

/* Define to 1 if you have the <sys/types.h> header file. */
$current_config{HAVE_SYS_TYPES_H}

/* Define to 1 if you have the <time.h> header file. */
$current_config{HAVE_TIME_H}

/* Define to 1 if you have the <unistd.h> header file. */
$current_config{HAVE_UNISTD_H}


/* Set up large file support */
$current_config{off64_t}
$current_config{lseek64}

// If large file support is not included, then make the value do nothing
#ifndef O_LARGEFILE
#define O_LARGEFILE	0
#endif

#ifndef O_BINARY
#define O_BINARY	0
#endif


#endif

CONFIG_H

	close $fh ;
}
