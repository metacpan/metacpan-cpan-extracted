#use 5.008008;
use 5.006;
use ExtUtils::MakeMaker qw(prompt WriteMakefile);
use Config;
use strict;

use lib './plib' ;
use Makeutils ;

	my $clib = "./clib" ;

	# Set up info for this module
	my $modinfo_href = init('Linux-DVB-DVBT-TS') ;

	# See if newer version is available
	check_new_version() ;

	## Options
	get_makeopts() ;

	## Check for current settings
	get_config() ;

	## Programs to install
	add_install_progs("script/", [
		qw/dvbt-ts-repair dvbt-ts-pics dvbt-ts-cut dvbt-ts-info/
	]);

	## Defines
	add_defines({
		'HAVE_MPEG2'		=> 1,
		'HAVE_AUDIO'		=> 1,
		'_LARGEFILE_SOURCE'	=> '',			
		'_FILE_OFFSET_BITS'	=> 64,			
		'_GNU_SOURCE'		=> '',			
	}) ;
	
	
	## Add libraries
	add_clibs($clib, {
		'dvb_ts_lib'	=> { 
			'config'		=> {
				'file'			=> 'config.h',
				'func'			=> \&create_ts_config_h,
			},
		},
		'libmpeg2'		=> { 
			'config'		=> {
				'file'			=> 'include/config.h',
				'func'			=> \&create_libmpeg2_config_h,
			},
		},
		'mpeg2audio'	=> {
			'config'		=> {
				'file'			=> 'config.h',
				'func'			=> \&create_mpeg2audio_config_h,
			},
		},
	}) ;

	if (arch_name() eq 'ARCH_ARM')
	{
		add_objects($clib, [qw(libmpeg2/motion_comp_arm_s.o)]) ;
	}


	## Do any cleanup
	process_makeopts() ;
	
	
	## Write Makefile
	my $MYEXTLIB = 'clib/dummy_lib$(LIB_EXT)' ;
	
	# See lib/ExtUtils/MakeMaker.pm for details of how to influence
	# the contents of the Makefile that is written.
	WriteMakefile(
	    NAME              => $modinfo_href->{'mod'},
	    VERSION_FROM      => "lib/$modinfo_href->{'modpath'}.pm", # finds $VERSION
	    PREREQ_PM         => {
			'File::Basename'	=> 0,
			'File::Path' 		=> 0,
			'File::Spec' 		=> 0,
			'POSIX'			=> 0,
			'Test::Pod::Coverage'	=> 1.08,
			'Pod::Coverage' => 0.18,
			'Test::Pod' => 1.22,
	    }, # e.g., Module::Name => 1.1
	    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
	      (ABSTRACT_FROM  => "lib/$modinfo_href->{'modpath'}.pm", # retrieve abstract from module
	       AUTHOR         => 'Steve Price <cpan@sdprice.plus.com>') : ()),
	    LIBS              => [], # e.g., '-lm'
	    DEFINE            => $modinfo_href->{'mod_defines'},
	    INC               => $modinfo_href->{'includes'},
	    EXE_FILES         => $modinfo_href->{'programs'},
	 
	    CCFLAGS			  => '-o $@',
	    OPTIMIZE	  	  => '-ggdb',
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
sub create_libmpeg2_config_h
{
	my ($fname, %current_config) = @_ ;

	open my $fh, ">$fname" or die "Error: Unable to write $fname : $!" ;

	#-------------------------------------------------------------
	## File
	print $fh <<CONFIG_H ;
/* $Config{archname} */
#ifndef CONFIG_H
#define CONFIG_H
	
/* autodetect accelerations */
#define ACCEL_DETECT 

/* Define if building universal (internal helper macro) */
#undef AC_APPLE_UNIVERSAL_BUILD

/* alpha architecture */
#undef ARCH_ALPHA

/* ARM architecture */
#undef ARCH_ARM 

/* ppc architecture */
#undef ARCH_PPC

/* sparc architecture */
#undef ARCH_SPARC

/* x86 architecture */
#undef ARCH_X86

#define $current_config{ARCH}

/* Operating system */
#define $current_config{OS}


/* maximum supported data alignment */
#define ATTRIBUTE_ALIGNED_MAX $current_config{ALIGN_BYTES}

/* debug mode configuration */
#undef DEBUG

/* Define to 1 if you have the <altivec.h> header. */
/* #undef HAVE_ALTIVEC_H */

/* Define if you have the `__builtin_expect' function. */
$current_config{HAVE_BUILTIN_EXPECT}

/* Define to 1 if you have the `ftime' function. */
$current_config{HAVE_FTIME}

/* Define to 1 if you have the `gettimeofday' function. */
$current_config{HAVE_GETTIMEOFDAY}

/* Define to 1 if you have the <inttypes.h> header file. */
$current_config{HAVE_INTTYPES_H}

/* Define to 1 if you have the <io.h> header file. */
$current_config{HAVE_IO_H}

/* Define to 1 if you have the <memory.h> header file. */
$current_config{HAVE_MEMORY_H}

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


/* mpeg2dec profiling */
#undef MPEG2DEC_GPROF

/* Name of package */
#define PACKAGE "libmpeg2"

/* Define to the address where bug reports for this package should be sent. */
#define PACKAGE_BUGREPORT ""

/* Define to the full name of this package. */
#define PACKAGE_NAME "libmpeg2"

/* Define to the full name and version of this package. */
#define PACKAGE_STRING "libmpeg2 0.5.1"

/* Define to the one symbol short name of this package. */
#define PACKAGE_TARNAME "libmpeg2"

/* Define to the version of this package. */
#define PACKAGE_VERSION "0.5.1"



/* Define as the return type of signal handlers - this is now ALWAYS 'void' */
$current_config{RETSIGTYPE}


/* Define WORDS_BIGENDIAN to 1 if your processor stores words with the most
   significant byte first (like Motorola and SPARC, unlike Intel). */
$current_config{ENDIAN}

/* Number of bits in a file offset, on hosts where this is settable. */
#define _FILE_OFFSET_BITS 64

/* Define for large files, on AIX-style hosts. */
$current_config{_LARGE_FILES}

/* Define to empty if `const' does not conform to ANSI C. */
$current_config{const}

/* Define to `__inline__' or `__inline' if that's what the C compiler
   calls it, or to nothing if 'inline' is not supported under any name.  */
#ifndef __cplusplus
$current_config{inline}
#endif

/* Define as `__restrict' if that's what the C compiler calls it, or to
   nothing if it is not supported. */
#define restrict $current_config{restrict}

/* Work around a bug in Sun C++: it does not support _Restrict, even
   though the corresponding Sun C compiler does, which causes
   "#define restrict _Restrict" in the previous line.  Perhaps some future
   version of Sun C++ will work with _Restrict; if so, it'll probably
   define __RESTRICT, just as Sun C does.  */
#if defined __SUNPRO_CC && !defined __RESTRICT
# define _Restrict
#endif

/* Define to `unsigned int' if <sys/types.h> does not define. */
$current_config{size_t}

/* Define to empty if the keyword `volatile' does not work. Warning: valid
   code using `volatile' can become incorrect without. Disable with care. */
$current_config{volatile}

#endif

CONFIG_H

	close $fh ;
}


#-----------------------------------------------------------------------------------------------------------------------
sub create_mpeg2audio_config_h
{
	my ($fname, %current_config) = @_ ;

	open my $fh, ">$fname" or die "Error: Unable to write $fname : $!" ;

	#-------------------------------------------------------------
	## File
	print $fh <<CONFIG_H ;
/* $Config{archname} */
#ifndef CONFIG_H
#define CONFIG_H
	
/* autodetect accelerations */
#define ACCEL_DETECT 

/* Define if building universal (internal helper macro) */
#undef AC_APPLE_UNIVERSAL_BUILD

/* alpha architecture */
#undef ARCH_ALPHA

/* ARM architecture */
#undef ARCH_ARM 

/* ppc architecture */
#undef ARCH_PPC

/* sparc architecture */
#undef ARCH_SPARC

/* x86 architecture */
#undef ARCH_X86

#define $current_config{ARCH}

/* Operating system */
#define $current_config{OS}


/* maximum supported data alignment */
#define ATTRIBUTE_ALIGNED_MAX $current_config{ALIGN_BYTES}

/* debug mode configuration */
#undef DEBUG

/* Define to 1 if you have the <altivec.h> header. */
/* #undef HAVE_ALTIVEC_H */

/* Define if you have the `__builtin_expect' function. */
$current_config{HAVE_BUILTIN_EXPECT}

/* Define to 1 if you have the `ftime' function. */
$current_config{HAVE_FTIME}

/* Define to 1 if you have the `lrintf' function. */
/* $current_config{HAVE_LRINTF} */
#define HAVE_LRINTF 1



/* Define to 1 if you have the `gettimeofday' function. */
$current_config{HAVE_GETTIMEOFDAY}

/* Define to 1 if you have the <inttypes.h> header file. */
$current_config{HAVE_INTTYPES_H}

/* Define to 1 if you have the <io.h> header file. */
$current_config{HAVE_IO_H}

/* Define to 1 if you have the <memory.h> header file. */
$current_config{HAVE_MEMORY_H}

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

/* Define to 1 if you have the <getopt.h> header file. */
$current_config{HAVE_GETOPT_H}




/* mpeg2dec profiling */
#undef MPEG2DEC_GPROF

/* Name of package */
#define PACKAGE "mpeg2dec"

/* Define to the address where bug reports for this package should be sent. */
#define PACKAGE_BUGREPORT ""

/* Define to the full name of this package. */
#define PACKAGE_NAME "mpeg2dec"

/* Define to the full name and version of this package. */
#define PACKAGE_STRING "mpeg2dec 0.4.1-cvs"

/* Define to the one symbol short name of this package. */
#define PACKAGE_TARNAME "mpeg2dec"

/* Define to the version of this package. */
#define PACKAGE_VERSION "0.4.1-cvs"



/* Define as the return type of signal handlers - this is now ALWAYS 'void' */
$current_config{RETSIGTYPE}


/* Define WORDS_BIGENDIAN to 1 if your processor stores words with the most
   significant byte first (like Motorola and SPARC, unlike Intel). */
$current_config{ENDIAN}

/* Number of bits in a file offset, on hosts where this is settable. */
#define _FILE_OFFSET_BITS 64

/* Define for large files, on AIX-style hosts. */
$current_config{_LARGE_FILES}

/* Define to empty if `const' does not conform to ANSI C. */
$current_config{const}

/* Define to `__inline__' or `__inline' if that's what the C compiler
   calls it, or to nothing if 'inline' is not supported under any name.  */
#ifndef __cplusplus
$current_config{inline}
#endif

/* Define as `__restrict' if that's what the C compiler calls it, or to
   nothing if it is not supported. */
#define restrict $current_config{restrict}

/* Work around a bug in Sun C++: it does not support _Restrict, even
   though the corresponding Sun C compiler does, which causes
   "#define restrict _Restrict" in the previous line.  Perhaps some future
   version of Sun C++ will work with _Restrict; if so, it'll probably
   define __RESTRICT, just as Sun C does.  */
#if defined __SUNPRO_CC && !defined __RESTRICT
# define _Restrict
#endif

/* Define to `unsigned int' if <sys/types.h> does not define. */
$current_config{size_t}

/* Define to empty if the keyword `volatile' does not work. Warning: valid
   code using `volatile' can become incorrect without. Disable with care. */
$current_config{volatile}

#ifndef _WIN32

#include <stdarg.h> /* for va_start, va_end */
#include <unistd.h> /* for usleep */
#include <string.h> /* for memset (ZeroMemory macro) */

/* type/function remappings */
#define LLD_FORMAT "%lld"
#define __int64 long long
#define _write write
#define _close close
#define _cprintf printf
#define _getcwd getcwd
#define _read read
#define _stat stat
#define _lseeki64 fseeko
#define _fseeki64 fseeko
#define _ftelli64 ftello
#define _flushall() fflush(0)
#define Sleep(a) usleep(1000*(a))
#define vo_wait()
#define vo_refresh()

#define MAX_PATH 2048

#define UNALIGNED
#define boolean unsigned char
#define BYTE unsigned char
#define BOOL unsigned char
#define CHAR unsigned char
#define WORD short /* two bytes */
#define DWORD unsigned long  /* four bytes */

#ifndef true
#define true 1
#endif
#ifndef false
#define false 0
#endif

#define __forceinline inline
#define max(a,b) ((a)>(b)?(a):(b))
#define min(a,b) ((a)<(b)?(a):(b))
#define ZeroMemory(buf,len) memset(buf,0,len)

//#define USE_ASF 0


#else
#define LLD_FORMAT "%I64d"
#define USE_ASF 1
#endif


#endif

CONFIG_H

	close $fh ;
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

/* Operating system */
#define $current_config{OS}


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
