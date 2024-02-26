#!env perl
use strict;
use diagnostics;

#
# This script is supposed to be run at the TOP of the distribution directory, i.e.:
#
# perl etc/compile_marpaESLIF.pl
#
# Tarballs are expected to in etc/tarballs directory. They will be extracted in extract
# directory that is first purged.
#
# Eventual extra includes are generated in inc/include directory.
#
# Object files are in objs directory
#
# Library files are in libs directory
#

my $have_cppguess;
BEGIN {
    use File::Spec;                     # Formally it is not necessary I believe to do it here
    # Make sure we have our 'inc' directory prepended the perl search path
    my $inc_dir = File::Spec->catdir(File::Spec->curdir, 'inc');
    unshift(@INC, $inc_dir);
    #
    # ExtUtils::CppGuess does not install everywhere.
    # This is why we provide it explicitely, we are ok if it fails at run-time
    # by enclosing its usage in try/catch
    #
    $have_cppguess = eval 'use ExtUtils::CppGuess 0.26; 1;';
}

use Archive::Tar;
use Carp qw/croak/;
use Config;
use Config::AutoConf;
use Cwd qw/abs_path/;
use ExtUtils::CBuilder 0.280224; # 0.280224 is to make sure we have the support of $ENV{CXX};
use File::chdir;
use File::Basename;
use File::Copy;
use File::Find;
use File::Path qw/make_path remove_tree/;
use File::Spec;
use File::Which;
use File::Temp;
use IO::Handle;
use Perl::OSType qw/is_os_type/;
use POSIX qw/EXIT_SUCCESS/;
use Try::Tiny;

our $EXTRA_INCLUDE_DIR = File::Spec->catdir('inc', 'include');
our $CONFIG_H = File::Spec->catfile($EXTRA_INCLUDE_DIR, 'marpaESLIFPerl_autoconf.h'); # The file that we generate
our $EXTRACT_DIR = 'extract';
our $TARBALLS_DIR = File::Spec->catdir('etc', 'tarballs');
our $OBJS_DIR = 'objs';
our $IS_WINDOWS = is_os_type('Windows');

$| = 1;

#
# A global flag coming from environment that disabled JIT in PCRE2. This should never be needed, but JIT
# MAY not compile on your architecture.
#
our $JIT = $ENV{MARPAESLIFPERL_JIT} // 1;

#
# Our distribution have both C and CPP files, and we want to make sure that modifying
# CFLAGS will not affect cpp files. Since we require a version of ExtUtils::CBuilder
# that support the environment variables, explicitely setting the environment variables
# from default ExtUtils::Cbuilder will ensure cc and cpp settings will become independant
# if we are doing to modify any of them.
# We do that for linker settings as well for coherency although we will NEVER touch them.
# OTHERLDFLAGS will be specific to this makefile.
#
# Take care: with ExtUtils::CBuilder, $ENV{CFLAGS} and $ENV{LDFLAGS} are appended to default perl compile flags, not the others
#
#
my %cbuilder_config = ExtUtils::CBuilder->new()->get_config;
$ENV{CC} = $cbuilder_config{cc} // 'cc';
$ENV{CFLAGS} //= '';
$ENV{CFLAGS} .= ' -DNDEBUG -DNTRACE';
$ENV{CXX} = $cbuilder_config{cxx} // $ENV{CC};
$ENV{CXXFLAGS} = $cbuilder_config{cxxflags} // $cbuilder_config{ccflags} // '';
$ENV{LD} = $cbuilder_config{ld} // $ENV{CC};
$ENV{LDFLAGS} //= '';
my @OTHERLDFLAGS = ();
my $optimize;

print "==========================================\n";
print "Original compilers and linker settings as per ExtUtils::CBuilder\n";
print "\n";
print "CC           (overwrite) $ENV{CC}\n";
print "CFLAGS       (    fixed) " . ($cbuilder_config{ccflags} // '') . "\n";
print "CFLAGS       (   append) $ENV{CFLAGS}\n";
print "CXX          (overwrite) $ENV{CXX}\n";
print "CXXFLAGS     (overwrite) $ENV{CXXFLAGS}\n";
print "LD           (overwrite) $ENV{LD}\n";
print "LDFLAGS      (    fixed) " . ($cbuilder_config{ldflags} // '') . "\n";
print "LDFLAGS      (   append) $ENV{LDFLAGS}\n";
print "==========================================\n";
print "\n";

my $ac = Config::AutoConf->new();
# goto jdd;
$ac->check_cc;
#
# Guess CXX configuration
#
# Sun C compiler is a special case, we know that guess_compiler will always get it wrong
#
my $sunc = 0;
$ac->msg_checking(sprintf "if this is Sun C compiler");
if ($ac->link_if_else("#ifdef __SUNPRO_C\n#else\n#error \"this is not Sun C compiler\"\n#endif\nint main() { return 0; }")) {
    $ac->msg_result('yes');
    my $cc = which($ENV{CC}) || '';
    if (! $cc) {
        #
        # Should never happen since we checked that the compiler works
        #
        $ac->msg_notice("Warning! Sun C compiler working but which() on its location returned false !?");
    } else {
        #
        # $cc should be a full path
        #
        $cc = abs_path($cc);
        my $ccdir = dirname($cc) || File::Spec->curdir();
        #
        # We always give precedence to CC that should be at the same location of the C compiler
        #
        my $cxx = File::Spec->catfile($ccdir, 'CC');
        if (! which($cxx)) {
            #
            # No CC at the same location?
            #
            $ac->msg_notice("Warning! Sun C compiler detected but no CC found at the same location - trying with default search path");
            $cxx = 'CC';
        } else {
            #
            # Could it be that this CC is also the one that is, eventually, in the path?
            #
            my $cxxfromPATH = which('CC') || '';
            if ($cxxfromPATH) {
                $cxxfromPATH = abs_path($cxxfromPATH);
                my $cxxfromWhich = abs_path($cxx);
                if ($cxxfromWhich eq $cxxfromPATH) {
                    $ac->msg_notice("Sun C compiler detected and its CC counterpart is already in the search path");
                    $cxx = 'CC';
                }
            }
        }
        if (which($cxx)) {
            $ac->msg_notice("Forcing CXX to $cxx");
            $ENV{CXX} = $cxx;
            #
            # We got "CC" executable - no need of eventual -x c++ that perl may have add
            #
            if ($ENV{CXXFLAGS} =~ s/\-x\s+c\+\+\s*//) {
                $ac->msg_notice("Removed -x c++ from CXXFLAGS");
            }
        } else {
            $ac->msg_notice("Warning! Sun C compiler detected but no CC found neither in path neither where is the C compiler");
        }
        #
        # In any case, add -lCrun and do not execute guess_compiler - cross fingers if we did not managed to find CXX
        #
        $ac->msg_notice("Adding -lCrun to OTHERLDFLAGS");
        push(@OTHERLDFLAGS, '-lCrun');
        $sunc = 1;
    }
} else {
    $ac->msg_result('no');
}

if ($have_cppguess && ! $sunc) {
    try {
        my ($cxx_guess, $extra_cxxflags_guess, $extra_ldflags_guess) = guess_compiler($ac);
        if (defined($cxx_guess) && (length($cxx_guess) > 0) && which($cxx_guess)) {
            $ac->msg_notice("Setting CXX to $cxx_guess");
            $ENV{CXX} = $cxx_guess;
            if (defined($extra_cxxflags_guess) && (length($extra_cxxflags_guess) > 0)) {
                $ac->msg_notice("Appending $extra_cxxflags_guess to CXXFLAGS");
                $ENV{CXXFLAGS} .= " $extra_cxxflags_guess";
            }
            if (defined($extra_ldflags_guess) && (length($extra_ldflags_guess) > 0)) {
		#
		# If $extra_ldflags_guess matches -lc++ or -lstdc++ remember this is a guess.
		# It can be one or the other, and we use the standard ciso646 with _LIBCPP_VERSION technique
		# to decide
		#
		if ($extra_ldflags_guess =~ /\-l(?:c|stdc)++/) {
		    $ac->msg_checking(sprintf "Checking which C++ library is correct between -lc++ and -lstdc++");
		    my $check_libcpp = <<RAISE_ERROR_IF_NOT_LIBCPP;
#include <ciso646>
#ifdef _LIBCPP_VERSION
#else
#  error "Not libc++"
#endif
RAISE_ERROR_IF_NOT_LIBCPP
		    if (try_compile($check_libcpp, { 'C++' => 1 })) {
			$ac->msg_result('-lc++');
			$extra_ldflags_guess =~ s/\-l(?:c|stdc)\+\+/-lc++/;
		    } else {
			$ac->msg_result('-lstdc++');
			$extra_ldflags_guess =~ s/\-l(?:c|stdc)\+\+/-lstdc++/;
		    }
		}
                $ac->msg_notice("Pushing $extra_ldflags_guess to OTHERLDFLAGS");
                push(@OTHERLDFLAGS, $extra_ldflags_guess)
            }
        }
    }
    catch {
        warn "caught error: $_"; # not $@
    };
}

if ((! "$ENV{CXX}") || (! which($ENV{CXX}))) {
    $ac->msg_notice("Fallback mode trying to guess from C compiler");
    my $cc_basename = basename($ENV{CC});
    my $cc_dirname = dirname($ENV{CC});
    #
    # Traditionally xxxxcc becomes xxxx++
    #
    if ($cc_basename =~ /cc$/i) {
        my $cxx_basename = $cc_basename;
        $cxx_basename =~ s/cc$/++/;
        my $cxx = File::Spec->catfile($cc_dirname, $cxx_basename);
        if (which($cxx)) {
            $ac->msg_notice("Setting CXX to found $cxx");
            $ENV{CXX} = $cxx;
        }
    }
    #
    # Or xxxxlang becomes lang++
    #
    elsif ($cc_basename =~ /lang$/i) {
        my $cxx_basename = $cc_basename;
        $cxx_basename .= "++";
        my $cxx = File::Spec->catfile($cc_dirname, $cxx_basename);
        if (which($cxx)) {
            $ac->msg_notice("Setting CXX to found $cxx");
            $ENV{CXX} = $cxx;
        }
    }
    #
    # Cross fingers, and use C compiler
    #
    else {
        $ac->msg_notice("Setting CXX to fallback $ENV{CC}");
        $ENV{CXX} = $ENV{CC};
    }
}

# -------------
# CC and CFLAGS
# --------------
#
my $isc99 = 0;
if (($cbuilder_config{cc} // 'cc') ne 'cl') {
    $ac->msg_checking("if C99 is enabled by default:");
    if (try_compile("#if !defined(__STDC_VERSION__) || __STDC_VERSION__ < 199901L\n#error \"C99 is not enabled\"\n#endif\nint main(){return 0;}")) {
        $ac->msg_result('yes');
        $isc99 = 1;
    } else {
        $ac->msg_result('no');
        $ac->msg_notice("what CFLAGS is required for C99:");
        $ac->msg_result('');
        foreach my $flag (qw/-std=gnu99 -std=c99 -c99 -AC99 -xc99=all -qlanglvl=extc99/) {
            $ac->msg_checking("if flag $flag works");
            if (try_compile("#if !defined(__STDC_VERSION__) || __STDC_VERSION__ < 199901L\n#error \"C99 is not enabled\"\n#endif\nint main(){return 0;}", { extra_compiler_flags => $flag })) {
                $ac->msg_result('yes');
                $ENV{CFLAGS} .= " $flag";
                $isc99 = 1;
                last;
            } else {
                $ac->msg_result('no');
            }
        }
    }
}

#
# When the compiler is clang, there is a bug with inlining, c.f. for example
# https://sourceforge.net/p/resil/tickets/6/
#
if (is_os_type('Unix', 'darwin') && ! $isc99)
{
  $ac->msg_checking(sprintf "if this is clang compiler");
  if ($ac->link_if_else("#ifndef __clang__\n#error \"this is not clang compiler\"\n#endif\nint main() { return 0; }")) {
      $ac->msg_result('yes');
      #
      # C.f. http://clang.llvm.org/compatibility.html#inline
      #      https://bugzilla.mozilla.org/show_bug.cgi?id=917526
      #
      $ac->msg_notice("Adding -std=gnu89 to CFLAGS for inline semantics");
      $ENV{CFLAGS} .= ' -std=gnu89';
  } else {
      $ac->msg_result('no');
  }
}

if ($^O eq "netbsd" && ! $isc99) {
    #
    # We need long long, that C99 guarantees, else _NETBSD_SOURCE will do it
    #
    $ac->msg_notice("NetBSD platform: Append _NETBSD_SOURCE to CFLAGS to have long long");
    $ENV{CFLAGS} .= ' -D_NETBSD_SOURCE';
}

my $has_Werror = 0;
if(! defined($ENV{MARPAESLIFPERL_OPTIM}) || $ENV{MARPAESLIFPERL_OPTIM}) {
    if(defined($ENV{MARPAESLIFPERL_OPTIM_FLAGS})) {
	$optimize = "$ENV{MARPAESLIFPERL_OPTIM_FLAGS}";
	$ac->msg_notice("Forced optimization flags: $optimize");
    } else {
	$ac->msg_checking("optimization flags:");
	$ac->msg_result('');
	if (($cbuilder_config{cc} // 'cc') eq 'cl') {
	    foreach my $flag ("/O2") {
		$ac->msg_checking("if flag $flag works:");
		if (try_compile("#include <stdlib.h>\nint main() {\n  exit(0);\n}\n", { extra_compiler_flags => $flag })) {
		    $ac->msg_result('yes');
		    $optimize .= " $flag";
		    last;
		} else {
		    $ac->msg_result('no');
		}
	    }
	} else {
	    #
	    # Some versions of gcc may not yell with bad options unless -Werror is set.
	    # Check that flag and set it temporarly.
	    #
	    my $tmpflag = '-Werror';
	    $ac->msg_checking("if flag $tmpflag works:");
	    if (try_compile("#include <stdlib.h>\nint main() {\n  exit(0);\n}\n", { extra_compiler_flags => $tmpflag })) {
		$ac->msg_result('yes');
		$has_Werror = 1;
	    } else {
		$ac->msg_result('no');
		$tmpflag = '';
	    }
	    #
	    # We test AIX case first because it overlaps with general O3
	    #
            my @flag_candidates = ();
            if ($sunc) {
                push(@flag_candidates, "-xO3"); # CC
            } else {
                push(@flag_candidates, "-O3 -qstrict"); # xlc
                push(@flag_candidates, "-O3"); # cl, gcc, clang
            }
	    foreach my $flag (@flag_candidates) {
		$ac->msg_checking("if flag $flag works:");
		if (try_compile("#include <stdlib.h>\nint main() {\n  exit(0);\n}\n", { extra_compiler_flags => "$tmpflag $flag" })) {
		    $ac->msg_result('yes');
		    $optimize .= " $flag";
		    last;
		} else {
		    $ac->msg_result('no');
		}
	    }
	}
    }
}

my $OTHERLDFLAGS = join(' ', @OTHERLDFLAGS);
print "\n";
print "==========================================\n";
print "Tweaked compilers and linker settings\n";
print "\n";
print "CC           (overwrite) $ENV{CC}\n";
print "CFLAGS       (    fixed) " . ($cbuilder_config{ccflags} // '') . "\n";
print "CFLAGS       (   append) $ENV{CFLAGS}\n";
print "CXX          (overwrite) $ENV{CXX}\n";
print "CXXFLAGS     (overwrite) $ENV{CXXFLAGS}\n";
print "LD           (overwrite) $ENV{LD}\n";
print "LDFLAGS      (    fixed) " . ($cbuilder_config{ldflags} // '') . "\n";
print "LDFLAGS      (   append) $ENV{LDFLAGS}\n";
print "OTHERLDFLAGS             $OTHERLDFLAGS\n";
print "==========================================\n";
print "\n";

my %HAVE_HEADERS = ();
$ac->check_all_headers(
    qw{
        ctype.h
            dlfcn.h
            errno.h
            fcntl.h
            features.h
            float.h
            inttypes.h
            io.h
            langinfo.h
            limits.h
            locale.h
            math.h
            memory.h
            poll.h
            process.h
            pwd.h
            regex.h
            signal.h
            stdarg.h
            stddef.h
            stdint.h
            stdio.h
            stdlib.h
            string.h
            strings.h
            sys/inttypes.h
            sys/stat.h
            sys/stdint.h
            sys/time.h
            sys/types.h
            time.h
            unistd.h
            utime.h
            wchar.h
            wctype.h
            windows.h
    }, { action_on_header_true => sub { my $header = shift; $HAVE_HEADERS{$header} = 1 } } );
#
# Private extra checks that Config::AutoConf::INI cannot do
#
check_math($ac);
check_ebcdic($ac);
check_inline($ac);
check_forceinline($ac);
check_va_copy($ac);
check_vsnprintf($ac);
check_fileno($ac);
check_localtime_r($ac);
check_write($ac);
check_log2($ac);
check_log2f($ac);
my $char_bit = check_CHAR_BIT($ac);
check_strtold($ac);
check_strtod($ac);
check_strtof($ac);
if (! check_HUGE_VAL($ac, 'C_HUGE_VAL', 'HUGE_VAL', { extra_compiler_flags => '-DC_HUGE_VAL=HUGE_VAL' })) {
    check_HUGE_VAL($ac, 'C_HUGE_VAL_REPLACEMENT', 1, { extra_compiler_flags => '-DHAVE_HUGE_VAL_REPLACEMENT' });
}
if (! check_HUGE_VALF($ac, 'C_HUGE_VALF', 'HUGE_VALF', { extra_compiler_flags => '-DC_HUGE_VALF=HUGE_VALF' })) {
    check_HUGE_VALF($ac, 'C_HUGE_VALF_REPLACEMENT', 1, { extra_compiler_flags => '-DHAVE_HUGE_VALF_REPLACEMENT' });
}
if (! check_HUGE_VALL($ac, 'C_HUGE_VALL', 'HUGE_VALL', { extra_compiler_flags => '-DC_HUGE_VALL=HUGE_VALL' })) {
    check_HUGE_VALL($ac, 'C_HUGE_VALL_REPLACEMENT', 1, { extra_compiler_flags => '-DHAVE_HUGE_VALL_REPLACEMENT' });
}
if (! check_INFINITY($ac, 'C_INFINITY', 'INFINITY', { extra_compiler_flags => '-DC_INFINITY=INFINITY' })) {
    if (! check_INFINITY($ac, 'C_INFINITY_REPLACEMENT', 1, { extra_compiler_flags => '-DHAVE_INFINITY_REPLACEMENT' })) {
        check_INFINITY($ac, 'C_INFINITY_REPLACEMENT_USING_DIVISION', 1, { extra_compiler_flags => '-DHAVE_INFINITY_REPLACEMENT_USING_DIVISION' });
    }
}
if (! check_NAN($ac, 'C_NAN', 'NAN', { extra_compiler_flags => '-DC_NAN=NAN' })) {
    if (! check_NAN($ac, 'C_NAN_REPLACEMENT', 1, { extra_compiler_flags => '-DHAVE_NAN_REPLACEMENT' })) {
        check_NAN($ac, 'C_NAN_REPLACEMENT_USING_DIVISION', 1, { extra_compiler_flags => '-DHAVE_NAN_REPLACEMENT_USING_DIVISION' });
    }
}
if (! check_isinf($ac, 'C_ISINF', 'isinf', { extra_compiler_flags => '-DC_ISINF=isinf' })) {
    if (! check_isinf($ac, 'C_ISINF', '_isinf', { extra_compiler_flags => '-DC_ISINF=_isinf' })) {
        if (! check_isinf($ac, 'C_ISINF', '__isinf', { extra_compiler_flags => '-DC_ISINF=__isinf' })) {
            check_isinf($ac, 'C_ISINF_REPLACEMENT', 1, { extra_compiler_flags => '-DHAVE_ISINF_REPLACEMENT' });
        }
    }
}
if (! check_isnan($ac, 'C_ISNAN', 'isnan', { extra_compiler_flags => '-DC_ISNAN=isnan' })) {
    if (! check_isnan($ac, 'C_ISNAN', '_isnan', { extra_compiler_flags => '-DC_ISNAN=_isnan' })) {
        if (! check_isnan($ac, 'C_ISNAN', '__isnan', { extra_compiler_flags => '-DC_ISNAN=__isnan' })) {
            check_isnan($ac, 'C_ISNAN_REPLACEMENT', 1, { extra_compiler_flags => '-DHAVE_ISNAN_REPLACEMENT' });
        }
    }
}
check_strtoll($ac);
check_strtoull($ac);
check_fpclassify($ac);
foreach (
    ['C_FP_NAN' => 'FP_NAN'],
    ['C__FPCLASS_SNAN' => '_FPCLASS_SNAN'],
    ['C__FPCLASS_QNAN' => '_FPCLASS_QNAN'],
    ['C_FP_INFINITE' => 'FP_INFINITE'],
    ['C__FPCLASS_NINF' => '_FPCLASS_NINF'],
    ['C__FPCLASS_PINF' => '_FPCLASS_PINF']
    ) {
    my ($what, $value) = @{$_};
    check_fp_constant($ac, $what, $value, { extra_compiler_flags => "-D$what=$value" });
}
check_const($ac);
check_c99_modifiers($ac);
check_restrict($ac);
check_builtin_expect($ac);
check_signbit($ac);
check_copysign($ac);
check_copysignf($ac);
check_copysignl($ac);
check_nl_langinfo($ac);
my $have_getc_unlocked = check_getc_unlocked($ac);
my $is_big_endian = check_big_endian($ac);
my $have__O_BINARY = $ac->check_decl('_O_BINARY', { prologue => "#include <fcntl.h>" });
my $have_wcrtomb = $ac->check_decl('wcrtomb', { prologue => "#include <wchar.h>" });
my $have_mbrtowc = $ac->check_decl('mbrtowc', { prologue => "#include <wchar.h>" });
my $broken_wchar = check_broken_wchar($ac);
my $is_gnu = check_compiler_is_gnu($ac);
my $is_clang = check_compiler_is_clang($ac);
if($has_Werror) {
    my $tmpflag = '-Werror=attributes';
    my $has_Werror_attributes = 0;
    $ac->msg_checking("if flag $tmpflag works:");
    if (try_compile("#include <stdlib.h>\nint main() {\n  exit(0);\n}\n", { extra_compiler_flags => $tmpflag })) {
        $ac->msg_result('yes');
        $has_Werror_attributes = 1;
    } else {
        $ac->msg_result('no');
        $tmpflag = '';
    }
    if ($has_Werror_attributes && ($is_gnu || $is_clang)) {
        foreach my $attribute (qw/alias aligned alloc_size always_inline artificial cold const constructor_priority constructor deprecated destructor dllexport dllimport error externally_visible fallthrough flatten format gnu_format format_arg gnu_inline hot ifunc leaf malloc noclone noinline nonnull noreturn nothrow optimize pure sentinel sentinel_position returns_nonnull unused used visibility warning warn_unused_result weak weakref/) {
            my $attribute_toupper = uc($attribute);
            check_compiler_function_attribute($ac, "C_GCC_FUNC_ATTRIBUTE_${attribute_toupper}", "__attribute__((${attribute}))", $attribute, { extra_compiler_flags => "-Werror=attributes -DTEST_GCC_FUNC_ATTRIBUTE_${attribute_toupper}=1" });
        }
    }
}
check_gnu_source($ac);

my %sizeof = ();
foreach my $what ('char', 'short', 'int', 'long', 'long long', 'float', 'double', 'long double', 'unsigned char', 'unsigned short', 'unsigned int', 'unsigned long', 'unsigned long long', 'size_t', 'void *', 'ptrdiff_t', 'wchar_t') {
    my $prologue = <<PROLOGUE;
#ifdef HAVE_CTYPE_H
#include <ctype.h>
#endif
#ifdef HAVE_ERRNO_H
#include <fcntl.h>
#endif
#ifdef HAVE_FCNTL_H
#include <fcntl.h>
#endif
#ifdef HAVE_FEATURES_H
#include <features.h>
#endif
#ifdef HAVE_FLOAT_H
#include <float.h>
#endif
#ifdef HAVE_INTTYPES_H
#include <inttypes.h>
#endif
#ifdef HAVE_IO_H
#include <io.h>
#endif
#ifdef HAVE_LANGINFO_H
#include <langinfo.h>
#endif
#ifdef HAVE_LIMITS_H
#include <limits.h>
#endif
#ifdef HAVE_LOCALE_H
#include <locale.h>
#endif
#ifdef HAVE_MATH_H
#include <math.h>
#endif
#ifdef HAVE_MEMORY_H
#include <memory.h>
#endif
#ifdef HAVE_POLL_H
#include <poll.h>
#endif
#ifdef HAVE_PROCESS_H
#include <process.h>
#endif
#ifdef HAVE_PWD_H
#include <pwd.h>
#endif
#ifdef HAVE_REGEX_H
#include <regex.h>
#endif
#ifdef HAVE_SIGNAL_H
#include <signal.h>
#endif
#ifdef HAVE_STDARG_H
#include <stdarg.h>
#endif
#ifdef HAVE_STDDEF_H
#include <stddef.h>
#endif
#ifdef HAVE_STDINT_H
#include <stdint.h>
#endif
#ifdef HAVE_STDIO_H
#include <stdio.h>
#endif
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif
#ifdef HAVE_STRING_H
#include <string.h>
#endif
#ifdef HAVE_STRINGS_H
#include <strings.h>
#endif
#ifdef HAVE_SYS_INTTYPES_H
#include <sys/inttypes.h>
#endif
#ifdef HAVE_SYS_STAT_H
#include <sys/stat.h>
#endif
#ifdef HAVE_SYS_STDINT_H
#include <sys/stdint.h>
#endif
#ifdef HAVE_SYS_TIME_H
#include <sys/time.h>
#endif
#ifdef HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif
#ifdef HAVE_TIME_H
#include <time.h>
#endif
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#ifdef HAVE_UTIME_H
#include <utime.h>
#endif
#ifdef HAVE_WCHAR_H
#include <wchar.h>
#endif
#ifdef HAVE_WCTYPE_H
#include <wctype.h>
#endif
#ifdef HAVE_WINDOWS_H
#include <windows.h>
#endif
PROLOGUE
    my $WHAT = ($what eq 'void *') ? uc("void star") : uc($what);
    $WHAT =~ s/ /_/g;
    #
    # Note that $c caches also the result
    #
    $sizeof{$WHAT} = $ac->check_sizeof_type($what, { prologue => $prologue });
    if ($sizeof{$WHAT}) {
        $ac->define_var("HAVE_SIZEOF_${WHAT}", 1);
        $ac->define_var("SIZEOF_${WHAT}", $sizeof{$WHAT});
    }
}
my %_MYTYPEMINMAX = ();
foreach my $_sign ('', 'u') {
    #
    # Remember that CHAR_BIT minimum value is 8 -;
    #
    foreach my $_size (8,16,32,64) {
        my $_sizeof = $_size / $char_bit;
        #
        # Speciying a MIN for unsigned case is meaningless (it is always zero) and not in the standard.
        # We neverthless set it, well, to zero.
        #
        my $_mytypemin = "CMAKE_HELPERS_${_sign}int${_size}_min";
        my $_MYTYPEMIN = uc($_mytypemin);
        my $_mytypemax = "CMAKE_HELPERS_${_sign}int${_size}_max";
        my $_MYTYPEMAX = uc($_mytypemax);
        #
        # Always define the CMAKE_HELPERS_XXX_MIN and CMAKE_HELPERS_XXX_MAX
        #
        foreach my $_c ('char', 'short', 'int', 'long', 'long long') {
            #
            # Without an extension, integer literal is always int,
            # so we have to handle the case of "long" and "long long"
            #
            my $_extension;
            if ($_c eq 'char') {
                $_extension = '';
            } elsif ($_c eq 'short') {
                $_extension = '';
            } elsif ($_c eq 'int') {
                $_extension = '';
            } elsif ($_c eq 'long') {
                if ("x${_sign}" eq "x") {
                    $_extension = 'L';
                } elsif ($_sign eq 'u') {
                    $_extension = 'UL';
                } else {
                    die "Unsupported size ${_size}";
                }
            } elsif($_c eq 'long long') {
                #
                # By definition, if this C supports "long long", it must support the "LL" suffix
                #
                if ("x${_sign}" eq "x") {
                    $_extension = 'LL';
                } elsif ($_sign eq 'u') {
                    $_extension = 'ULL';
                } else {
                    die "Unsupported size ${_size}";
                }
            } else {
                die "Unsupported c ${_c}";
            }
            my $_C = uc($_c);
            $_C =~ s/ /_/g;
            if (defined($sizeof{$_C})) {
                if ($sizeof{$_C} == ${_sizeof}) {
                    #
                    # In C language, a decimal constant without a u/U is always signed,
                    # but an hexadecimal constant is signed or unsigned, depending on value and integer type range
                    #
                    if ($_size == 8) {
                        if ("x${_sign}" eq "x") {
                            $_MYTYPEMINMAX{"${_MYTYPEMIN}"} = "(-127${_extension} - 1${_extension})";
                            $_MYTYPEMINMAX{"${_MYTYPEMAX}"} = "127${_extension}";
                        } elsif (${_sign} eq "u") {
                            $_MYTYPEMINMAX{"${_MYTYPEMIN}"} = "0x00${_extension}";
                            $_MYTYPEMINMAX{"${_MYTYPEMAX}"} = "0xFF${_extension}";
                        } else {
                            die "Unsupported size ${_size}";
                        }
                    } elsif ($_size == 16) {
                        if ("x${_sign}" eq "x") {
                            $_MYTYPEMINMAX{"${_MYTYPEMIN}"} = "(-32767${_extension} - 1${_extension})";
                            $_MYTYPEMINMAX{"${_MYTYPEMAX}"} = "32767${_extension}";
                        } elsif (${_sign} eq "u") {
                            $_MYTYPEMINMAX{"${_MYTYPEMIN}"} = "0x0000${_extension}";
                            $_MYTYPEMINMAX{"${_MYTYPEMAX}"} = "0xFFFF${_extension}";
                        } else {
                            die "Unsupported size ${_size}";
                        }
                    } elsif ($_size == 32) {
                        if ("x${_sign}" eq "x") {
                            $_MYTYPEMINMAX{"${_MYTYPEMIN}"} = "(-2147483647${_extension} - 1${_extension})";
                            $_MYTYPEMINMAX{"${_MYTYPEMAX}"} = "2147483647${_extension}";
                        } elsif (${_sign} eq "u") {
                            $_MYTYPEMINMAX{"${_MYTYPEMIN}"} = "0x00000000${_extension}";
                            $_MYTYPEMINMAX{"${_MYTYPEMAX}"} = "0xFFFFFFFF${_extension}";
                        } else {
                            die "Unsupported size ${_size}";
                        }
                    } elsif ($_size == 64) {
                        if ("x${_sign}" eq "x") {
                            $_MYTYPEMINMAX{"${_MYTYPEMIN}"} = "(-9223372036854775807${_extension} - 1${_extension})";
                            $_MYTYPEMINMAX{"${_MYTYPEMAX}"} = "9223372036854775807${_extension}";
                        } elsif (${_sign} eq "u") {
                            $_MYTYPEMINMAX{"${_MYTYPEMIN}"} = "0x0000000000000000${_extension}";
                            $_MYTYPEMINMAX{"${_MYTYPEMAX}"} = "0xFFFFFFFFFFFFFFFF${_extension}";
                        } else {
                            die "Unsupported size ${_size}";
                        }
                    } else {
                        die "Unsupported size ${_size}";
                    }
                }
            }
        }
        #
        # We handle the _least and _fast variations
        #
        my %_HAVES = ();
        my %_MYTYPEDEFS = ();
        my %_SIZEOFS = ();
        foreach my $_variation ('', '_least', '_fast') {
            my $_ctype =  "${_sign}int${_variation}${_size}_t";
            my $_CTYPE = uc($_ctype);

            my $_mytype = "CMAKE_HELPERS_${_sign}int${_variation}${_size}";
            my $_MYTYPE = uc($_mytype);

            my $_MYTYPEDEF = "${_MYTYPE}_TYPEDEF";

            my $_found_type = 0;
            foreach my $_underscore ('', '_', '__') {
                my $_type = "${_underscore}${_sign}int${_variation}${_size}_t";
                my $_TYPE = uc(${_type});
                $ac->check_sizeof_type($_type, { action_on_true => sub { $_HAVES{"HAVE_${_TYPE}"} = 1 } });
                if ($_HAVES{"HAVE_${_TYPE}"}) {
                    $_HAVES{"HAVE_${_MYTYPE}"} = 1;
                    $_SIZEOFS{"SIZEOF_${_MYTYPE}"} = $_sizeof;
                    $_MYTYPEDEFS{"${_MYTYPEDEF}"} = ${_type};
                    if (${_type} eq ${_ctype}) {
                        $_HAVES{"HAVE_${_CTYPE}"} = 1;
                    } else {
                        $_HAVES{"HAVE_${_CTYPE}"} = 0;
                    }
                    last;
                }
            }

            if (! $_HAVES{"HAVE_${_MYTYPE}"}) {
                #
                # Try with C types
                #
                my $_found_type = 0;
                foreach ('char', 'short', 'int', 'long', 'long long') {
                    my $_c = $_; # Because a foreach my $_c would have made $_c a readonly variable
                    if ($_sign eq "u") {
                        $_c = "unsigned ${_c}";
                    }
                    my $_C = uc(${_c});
                    $_C =~ s/ /_/g;
                    $_HAVES{"HAVE_SIZEOF_${_C}"} = (exists($sizeof{$_C}) && $sizeof{$_C}) ? 1 : 0;
                    if ($_HAVES{"HAVE_SIZEOF_${_C}"}) {
                        if ("x${_variation}" eq "x") {
                            $_SIZEOFS{"SIZEOF_${_C}"} = $sizeof{$_C};
                            if ($_SIZEOFS{"SIZEOF_${_C}"} == ${_sizeof}) {
                                $_HAVES{"HAVE_${_MYTYPE}"} = 1;
                                $_SIZEOFS{"SIZEOF_${_MYTYPE}"} = ${_sizeof};
                                $_MYTYPEDEFS{"${_MYTYPEDEF}"} = ${_c};
                                last;
                            }
                        } elsif ($_variation eq "_least") {
                            $_SIZEOFS{"SIZEOF_${_C}"} = $sizeof{$_C};
                            if ($_SIZEOFS{"SIZEOF_${_C}"} >= ${_sizeof}) {
                                $_HAVES{"HAVE_${_MYTYPE}"} = 1;
                                $_SIZEOFS{"SIZEOF_${_MYTYPE}"} = ${_sizeof};
                                $_MYTYPEDEFS{"${_MYTYPEDEF}"} = ${_c};
                                last;
                            }
                        } elsif ($_variation eq "_fast") {
                            #
                            # We give the same result as _least
                            #
                            $_SIZEOFS{"SIZEOF_${_C}"} = $sizeof{$_C};
                            if ($_SIZEOFS{"SIZEOF_${_C}"} >= ${_sizeof}) {
                                $_HAVES{"HAVE_${_MYTYPE}"} = 1;
                                $_SIZEOFS{"SIZEOF_${_MYTYPE}"} = ${_sizeof};
                                $_MYTYPEDEFS{"${_MYTYPEDEF}"} = ${_c};
                                last;
                            }
                        } else {
                            die "Unsupported variation ${_variation}";
                        }
                    }
                }
            }
            if ($_HAVES{"HAVE_${_MYTYPE}"}) {
                $ac->define_var("HAVE_${_MYTYPE}", $_HAVES{"HAVE_${_MYTYPE}"});
                $ac->define_var("SIZEOF_${_MYTYPE}", $_SIZEOFS{"SIZEOF_${_MYTYPE}"});
                $ac->define_var("HAVE_${_CTYPE}", $_HAVES{"HAVE_${_CTYPE}"});
                $ac->define_var("${_MYTYPEDEF}", $_MYTYPEDEFS{"${_MYTYPEDEF}"});
                $ac->define_var("${_MYTYPEMIN}", $_MYTYPEMINMAX{"${_MYTYPEMIN}"});
                $ac->define_var("${_MYTYPEMAX}", $_MYTYPEMINMAX{"${_MYTYPEMAX}"});
            }
        }
    }
}
#
# Integer type capable of holding object pointers
#
foreach my $_sign ('', 'u') {
    my $_sizeof = $sizeof{VOID_STAR};
    my $_ctype =  "${_sign}intptr_t";
    my $_CTYPE = uc($_ctype);
    my $_mytype = "CMAKE_HELPERS_${_sign}intptr";
    my $_MYTYPE = uc($_mytype);
    my $_MYTYPEDEF = "${_MYTYPE}_TYPEDEF";

    my %_HAVES = ();
    my %_MYTYPEDEFS = ();
    my %_SIZEOFS = ();

    my $_type = "${_sign}intptr_t";
    my $_TYPE = uc(${_type});
    $ac->check_sizeof_type($_type, { action_on_true => sub { $_HAVES{"HAVE_${_TYPE}"} = 1 } });
    if ($_HAVES{"HAVE_${_TYPE}"}) {
        $_HAVES{"HAVE_${_MYTYPE}"} = 1;
        $_SIZEOFS{"SIZEOF_${_MYTYPE}"} = $_sizeof;
        $_MYTYPEDEFS{"${_MYTYPEDEF}"} = ${_type};
        if (${_type} eq ${_ctype}) {
            $_HAVES{"HAVE_${_CTYPE}"} = 1;
        } else {
            $_HAVES{"HAVE_${_CTYPE}"} = 0;
        }
    }
    if (! $_HAVES{"HAVE_${_MYTYPE}"}) {
        #
        # Try with C types
        #
        foreach ('char', 'short', 'int', 'long', 'long long') {
            my $_c = $_; # Because a foreach my $_c would have made $_c a readonly variable
            if ($_sign eq "u") {
                $_c = "unsigned ${_c}";
            }
            my $_C = uc(${_c});
            $_C =~ s/ /_/g;
            $_HAVES{"HAVE_SIZEOF_${_C}"} = (exists($sizeof{$_C}) && $sizeof{$_C}) ? 1 : 0;
            if ($_HAVES{"HAVE_SIZEOF_${_C}"}) {
                $_SIZEOFS{"SIZEOF_${_C}"} = $sizeof{$_C};
                if ($_SIZEOFS{"SIZEOF_${_C}"} == ${_sizeof}) {
                    $_HAVES{"HAVE_${_MYTYPE}"} = 1;
                    $_SIZEOFS{"SIZEOF_${_MYTYPE}"} = ${_sizeof};
                    $_MYTYPEDEFS{"${_MYTYPEDEF}"} = ${_c};
                    last;
                }
            }
        }
    }
    if ($_HAVES{"HAVE_${_MYTYPE}"}) {
        $ac->define_var("HAVE_${_MYTYPE}", $_HAVES{"HAVE_${_MYTYPE}"});
        $ac->define_var("SIZEOF_${_MYTYPE}", $_SIZEOFS{"SIZEOF_${_MYTYPE}"});
        $ac->define_var("HAVE_${_CTYPE}", $_HAVES{"HAVE_${_CTYPE}"});
        $ac->define_var("${_MYTYPEDEF}", $_MYTYPEDEFS{"${_MYTYPEDEF}"});
    }
}
$ac->check_func('bcopy', { action_on_true => $ac->define_var('HAVE_BCOPY', 1) });
$ac->check_func('memmove', { action_on_true => $ac->define_var('HAVE_MEMMOVE', 1) });
$ac->check_func('strerror', { action_on_true => $ac->define_var('HAVE_STRERROR', 1) });
$ac->check_func('memfd_create', { action_on_true => $ac->define_var('HAVE_MEMFD_CREATE', 1) });
$ac->check_func('secure_getenv', { action_on_true => $ac->define_var('HAVE_SECURE_GETENV', 1) });
#
# Prune work directories
#
print "Pruning directory $EXTRA_INCLUDE_DIR\n";
remove_tree($EXTRA_INCLUDE_DIR, { safe => 1 });
make_path($EXTRA_INCLUDE_DIR);

print "Pruning directory $EXTRACT_DIR\n";
remove_tree($EXTRACT_DIR, { safe => 1 });
make_path($EXTRACT_DIR);

print "Pruning directory $OBJS_DIR\n";
remove_tree($OBJS_DIR, { safe => 1 });
make_path($OBJS_DIR);
#
# Write config file
#
print "Generating $CONFIG_H\n";
$ac->write_config_h($CONFIG_H);
$ac->msg_notice("Append -I$EXTRA_INCLUDE_DIR to compile flags");
$ENV{CFLAGS} .= " -I$EXTRA_INCLUDE_DIR";
$ENV{CXXFLAGS} .= " -I$EXTRA_INCLUDE_DIR";
#
# Generate extra headers eventually
#
if (! $HAVE_HEADERS{"stdint.h"}) {
    configure_file($ac, File::Spec->catfile('etc', 'stdint.h.in'), File::Spec->catfile($EXTRA_INCLUDE_DIR, 'stdint.h'));
}
if (! $HAVE_HEADERS{"inttypes.h"}) {
    configure_file($ac, File::Spec->catfile('etc', 'inttypes.h.in'), File::Spec->catfile($EXTRA_INCLUDE_DIR, 'inttypes.h'));
}

#
# General flags that we always set
#
foreach my $flag (qw/_REENTRANT _THREAD_SAFE/) {
    $ac->msg_notice("Append $flag to compile flags");
    $ENV{CFLAGS} .= " -D$flag";
    $ENV{CXXFLAGS} .= " -D$flag";
}
#
# Specific flags for cl
#
if ($ENV{CC} =~ /\bcl\b/) {
    foreach my $flag (qw/WIN32_LEAN_AND_MEAN CRT_SECURE_NO_WARNINGS _CRT_NONSTDC_NO_DEPRECATE/) {
        $ac->msg_notice("Append $flag to compile flags");
        $ENV{CFLAGS} .= " -D$flag";
        $ENV{CXXFLAGS} .= " -D$flag";
    }
}
#
# Extract and process tarballs in an order that we know in advance
#
sub get_object_file {
    my ($source) = @_;

    return File::Spec->catfile($OBJS_DIR, sprintf("%s.o", basename($source)));
}

process_genericLogger($ac);
process_tconv($ac);
process_genericStack($ac);
process_genericHash($ac);
process_genericSparseArray($ac);
process_marpaWrapper($ac);
process_marpaESLIF($ac);
#
# Write LDFLAGS and OTHERLDFLAGS to OTHERLDFLAGS.txt
#
my $otherldflags = 'OTHERLDFLAGS.txt';
open(my $otherldflags_fd, '>', $otherldflags) || die "Cannot open $otherldflags, $!";
foreach (@OTHERLDFLAGS) {
    print $otherldflags_fd "$_\n";
}
print $otherldflags_fd "$ENV{LDFLAGS}\n";
close($otherldflags_fd) || warn "Cannot close $otherldflags, $!";

#
# Write CFLAGS to CFLAGS.txt
#
my $cflags = 'CFLAGS.txt';
open(my $cflags_fd, '>', $cflags) || die "Cannot open $cflags, $!";
print $cflags_fd "$ENV{CFLAGS}\n";
close($cflags_fd) || warn "Cannot close $cflags, $!";

exit(EXIT_SUCCESS);

sub guess_compiler {
  my ($ac) = @_;

  my $guesser = ExtUtils::CppGuess->new(cc => $ENV{CC});
  #
  # We work quite like Module::Build in the sense that we are appending
  # flags.
  #
  my %module_build_options = $guesser->module_build_options;
  my $cxx_guess            = $module_build_options{config}->{cc} // '';
  my $extra_cxxflags_guess = $module_build_options{extra_compiler_flags} // '';
  my $extra_ldflags_guess  = $module_build_options{extra_linker_flags} // '';
  $ac->msg_notice("ExtUtils::CppGuess says \$cxx_guess=$cxx_guess, \$extra_cxxflags_guess=$extra_cxxflags_guess, \$extra_ldflags_guess=$extra_ldflags_guess");

  return ($cxx_guess, $extra_cxxflags_guess, $extra_ldflags_guess);
}

sub try_compile {
    no warnings 'once';
    
    my ($csource, $options) = @_;

    $options //= {};
    my $extra_compiler_flags = $options->{extra_compiler_flags};
    my $link = $options->{link} // 0;
    my $run = $options->{run} // 0;
    my $cbuilder_extra_config = $options->{cbuilder_extra_config};
    my $output_ref = $options->{output_ref};
    my $silent = $options->{silent} // $ENV{COMPILE_MARPAESLIF_SILENT} // 1;
    my $quiet = $options->{quiet} // $ENV{COMPILE_MARPAESLIF_QUIET} // 1;
    my $compile_error_is_fatal = $options->{compile_error_is_fatal} // 0;
    my $link_error_is_fatal = $options->{link_error_is_fatal} // 0;
    my $run_error_is_fatal = $options->{run_error_is_fatal} // 0;
    my $cplusplus = $options->{'C++'} // 0;

    my $stderr_and_stdout_txt = "stderr_and_stdout.txt";
    #
    # We do not want to be polluted in any case, redirect stdout and stderr
    # to the same output using method as per perlfunc open
    #
    open(my $oldout, ">&STDOUT") or die "Can't dup STDOUT: $!";
    open(OLDERR, ">&", \*STDERR) or die "Can't dup STDERR: $!";
    if ($silent) {
        open(STDOUT, '>', $stderr_and_stdout_txt) or die "Can't redirect STDOUT: $!";
        open(STDERR, ">&STDOUT") or die "Can't dup STDOUT: $!";
        select STDERR; $| = 1;  # make unbuffered
        select STDOUT; $| = 1;  # make unbuffered
    }

    $link //= 0;
    $cbuilder_extra_config //= {};
    my $fh = File::Temp->new(UNLINK => 0, SUFFIX => '.c');
    print $fh "$csource\n";
    close($fh);
    my $source = $fh->filename;
    my $rc = 0;
    #
    # Default is compile at least
    #
    my $object_file;
    my $exe_file;
    my $have_compile_error = 1;
    my $have_link_error = 0;
    my $have_run_error = 0;
    try {
        my $cbuilder = ExtUtils::CBuilder->new(config => $cbuilder_extra_config, quiet => $quiet);
        $object_file = basename($cbuilder->object_file($source));
        $cbuilder->compile(
            source               => $source,
            object_file          => $object_file,
            extra_compiler_flags => $extra_compiler_flags,
	    'C++'                => $cplusplus
            );
        $have_compile_error = 0;
	print "... Compilation successful\n" if (! $silent);
	#
	# Optionally link
	#
        if ($link) {
            $have_link_error = 1;
            $exe_file = basename($cbuilder->exe_file($object_file));
            my $exe = $cbuilder->link_executable(
                objects              => [ $object_file ],
                exe_file             => $exe_file
                );
            $have_link_error = 0;
	    print "... Link successful\n" if (! $silent);
	    #
	    # Optionnally run
	    #
	    if($run) {
                if (! File::Spec->file_name_is_absolute($exe)) {
                    $exe = File::Spec->rel2abs($exe);
                }
                $have_run_error = 1;
                my $output = `$exe`;
		if ($? == -1) {
		    croak "Failed to execute, $!\n";
		} elsif ($? & 127) {
		    croak "Child died with signal %d, %s coredump\n", ($? & 127),  ($? & 128) ? 'with' : 'without';
		} else {
                    #
                    # Child exited normally
                    #
		    my $exit_code = $? >> 8;
		    printf "child exited with value %d\n", $exit_code if (! $silent);
                    $have_run_error = 0;
                    $rc = ($exit_code == EXIT_SUCCESS) ? 1 : 0;
		}
                if ($output_ref) {
                    ${$output_ref} = $output;
                }
	    } else {
		$rc = 1;
	    }
        } else {
	    $rc = 1;
	}
    }
    catch {
	warn "caught error: $_" if (! $silent);
    }
    finally {
        if ($object_file) {
            unlink($object_file);
        }
        if ($exe_file) {
            unlink($exe_file);
        }
    };
    unlink $fh->filename;

    open(STDOUT, ">&", $oldout) or die "Can't dup \$oldout: $!";
    open(STDERR, ">&OLDERR") or die "Can't dup OLDERR: $!";
    unlink $stderr_and_stdout_txt;

    if ($have_compile_error && $compile_error_is_fatal) {
        die "Compilation error and this is fatal";
    }
    if ($have_link_error && $link_error_is_fatal) {
        die "Link error and this is fatal";
    }
    if ($have_run_error && $run_error_is_fatal) {
        die "Run error and this is fatal";
    }

    return $rc;
}

sub try_link {
    my ($csource, $options) = @_;

    $options //= {};

    return try_compile($csource, { %$options, link => 1 });
}

sub try_run {
    my ($csource, $options) = @_;

    $options //= {};

    return try_compile($csource, { %$options, link => 1, run => 1 });
}

sub try_output {
    my ($csource, $output_ref, $options) = @_;

    $options //= {};

    return try_compile($csource, { %$options, link => 1, run => 1, output_ref => $output_ref });
}

sub check_math {
    my ($ac) = @_;

    #
    # log/exp and math lib
    #
    my $lm = $ac->check_lm() // '';
    $ac->msg_checking("for math library:");
    if($lm) {
	$ac->msg_result("$lm");
	$ac->search_libs('log', $lm, { action_on_true => $ac->define_var("HAVE_LOG", 1) });
	$ac->search_libs('exp', $lm, { action_on_true => $ac->define_var("HAVE_EXP", 1) });
        $ac->msg_notice("Append -l$lm to LDFLAGS");
	$ENV{LDFLAGS} .= " -l$lm";
    } else {
	$ac->msg_result("not needed");
	$ac->search_libs('log', { action_on_true => $ac->define_var("HAVE_LOG", 1) });
	$ac->search_libs('exp', { action_on_true => $ac->define_var("HAVE_EXP", 1) });
    }
}

sub check_ebcdic {
    my ($ac) = @_;
    #
    # EBCDIC (We could have used $Config{ebcdic} as well
    # --------------------------------------------------
    $ac->msg_checking("EBCDIC");
    my $prologue = <<PROLOGUE;
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif
PROLOGUE
    my $body = <<BODY;
if ('M'==0xd4) {
  exit(0);
} else {
  exit(1);
}
BODY
    my $program = $ac->lang_build_program($prologue, $body);
    if (try_run($program)) {
	$ac->msg_result("yes");
	$ac->define_var("EBCDIC", 1)
    } else {
	$ac->msg_result("no");
    }
}

sub check_inline {
    my ($ac) = @_;

    foreach my $value (qw/inline __inline__ inline__ __inline/) {
	$ac->msg_checking($value);
	my $prologue = <<PROLOGUE;
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

typedef int foo_t;
static $value foo_t static_foo() {
  return 0;
}
foo_t foo() {
  return 0;
}
PROLOGUE
	my $program = $ac->lang_build_program($prologue);
	if (try_run($program)) {
	    $ac->msg_result("yes");
	    $ac->define_var("C_INLINE", $value);
	    if ($value eq 'inline') {
		$ac->define_var("C_INLINE_IS_INLINE", 1);
	    }
	    last;
	} else {
	    $ac->msg_result("no");
	}
    }
}

sub check_forceinline {
    my ($ac) = @_;

    foreach my $value (qw/forceinline __forceinline__ forceinline__ __forceinline/) {
	$ac->msg_checking($value);
	my $prologue = <<PROLOGUE;
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

typedef int foo_t;
static $value foo_t static_foo() {
  return 0;
}
foo_t foo() {
  return 0;
}
PROLOGUE
	my $program = $ac->lang_build_program($prologue);
	if (try_run($program)) {
	    $ac->msg_result("yes");
	    $ac->define_var("C_FORCEINLINE", $value);
	    last;
	} else {
	    $ac->msg_result("no");
	}
    }
}

sub check_va_copy {
    my ($ac) = @_;

    foreach my $value (qw/va_copy _va_copy __va_copy/) {
	$ac->msg_checking($value);
	my $prologue = <<PROLOGUE;
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

#ifdef HAVE_STDARG_H
#include <stdarg.h>
#endif

static void f(int i, ...) {
  va_list args1, args2;

  va_start(args1, i);
  $value(args2, args1);

  if (va_arg(args2, int) != 42 || va_arg(args1, int) != 42) {
    exit(1);
  }

  va_end(args1);
  va_end(args2);
}

PROLOGUE
	my $body = <<BODY;
  f(0, 42);
  exit(0);
BODY
	my $program = $ac->lang_build_program($prologue, $body);
	if (try_run($program)) {
	    $ac->msg_result("yes");
	    $ac->define_var("C_VA_COPY", $value);
	    last;
	} else {
	    $ac->msg_result("no");
	}
    }
}

sub check_vsnprintf {
    my ($ac) = @_;

    foreach my $value (qw/vsnprintf _vsnprintf __vsnprintf/) {
	$ac->msg_checking($value);
	my $prologue = <<PROLOGUE;
#ifdef HAVE_STDIO_H
#include <stdio.h>
#endif
#ifdef HAVE_STDARG_H
#include <stdarg.h>
#endif
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

static void vsnprintftest(char *string, char *fmt, ...)
{
   va_list ap;

   va_start(ap, fmt);
   $value(string, 10, fmt, ap);
   va_end(ap);
}

PROLOGUE
	my $body = <<BODY;
  char p[100];
  vsnprintftest(p, "%s", "test");
  exit(0);
BODY
	my $program = $ac->lang_build_program($prologue, $body);
	if (try_run($program)) {
	    $ac->msg_result("yes");
	    $ac->define_var("C_VSNPRINTF", $value);
	    last;
	} else {
	    $ac->msg_result("no");
	}
    }
}

sub check_fileno {
    my ($ac) = @_;

    foreach my $value (qw/fileno _fileno __fileno/) {
	$ac->msg_checking($value);
	my $prologue = <<PROLOGUE;
#ifdef HAVE_STDIO_H
#include <stdio.h>
#endif

#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

PROLOGUE
	my $body = <<BODY;
  $value(stdin);
  exit(0);
BODY
	my $program = $ac->lang_build_program($prologue, $body);
	if (try_run($program)) {
	    $ac->msg_result("yes");
	    $ac->define_var("C_FILENO", $value);
	    last;
	} else {
	    $ac->msg_result("no");
	}
    }
}

sub check_localtime_r {
    my ($ac) = @_;

    foreach my $value (qw/localtime_r _localtime_r __localtime_r/) {
	$ac->msg_checking($value);
	my $prologue = <<PROLOGUE;
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

#ifdef HAVE_TIME_H
#include <time.h>
#endif

PROLOGUE
	my $body = <<BODY;
  time_t time;
  struct tm result;
  $value(&time, &result);
  exit(0);
BODY
	my $program = $ac->lang_build_program($prologue, $body);
	if (try_run($program)) {
	    $ac->msg_result("yes");
	    $ac->define_var("C_LOCALTIME_R", $value);
	    last;
	} else {
	    $ac->msg_result("no");
	}
    }
}

sub check_write {
    my ($ac) = @_;

    foreach my $value (qw/write _write __write/) {
	$ac->msg_checking($value);
	my $prologue = <<PROLOGUE;
#ifdef HAVE_STDIO_H
#include <stdio.h>
#endif

#ifdef HAVE_IO_H
#include <io.h>
#endif

#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif

PROLOGUE
	my $body = <<BODY;
  if ($value(1, "This will be output to standard out\\n", 36) != 36) {
    exit(1);
  }
  exit(0);
BODY
	my $program = $ac->lang_build_program($prologue, $body);
	if (try_run($program)) {
	    $ac->msg_result("yes");
	    $ac->define_var("C_WRITE", $value);
	    last;
	} else {
	    $ac->msg_result("no");
	}
    }
}

sub check_log2 {
    my ($ac) = @_;

    foreach my $value (qw/log2/) {
	$ac->msg_checking($value);
	my $prologue = <<PROLOGUE;
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

#ifdef HAVE_MATH_H
#include <math.h>
#endif

PROLOGUE
	my $body = <<BODY;
  double x = $value(1.0);
  exit(0);
BODY
	my $program = $ac->lang_build_program($prologue, $body);
	if (try_run($program)) {
	    $ac->msg_result("yes");
	    $ac->define_var("C_LOG2", $value);
	    last;
	} else {
	    $ac->msg_result("no");
	}
    }
}

sub check_log2f {
    my ($ac) = @_;

    foreach my $value (qw/log2f/) {
	$ac->msg_checking($value);
	my $prologue = <<PROLOGUE;
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

#ifdef HAVE_MATH_H
#include <math.h>
#endif

PROLOGUE
	my $body = <<BODY;
  float x = $value(1.0);
  exit(0);
BODY
	my $program = $ac->lang_build_program($prologue, $body);
	if (try_run($program)) {
	    $ac->msg_result("yes");
	    $ac->define_var("C_LOG2F", $value);
	    last;
	} else {
	    $ac->msg_result("no");
	}
    }
}

sub check_CHAR_BIT {
    my ($ac) = @_;

    my $char_bit = 0;

    foreach my $value (qw/CHAR_BIT/) {
	$ac->msg_checking($value);
	my $prologue = <<PROLOGUE;
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif
#ifdef HAVE_STDIO_H
#include <stdio.h>
#endif
#ifdef HAVE_LIMITS_H
#include <limits.h>
#endif

PROLOGUE
	my $body = <<BODY;
  fprintf(stdout, "%d", $value);
  exit(0);
BODY
	my $program = $ac->lang_build_program($prologue, $body);
        if (try_output($program, \$char_bit) && defined($char_bit)) {
	    $ac->msg_result($char_bit);
	    last;
	} else {
            $char_bit = 8;
	    $ac->msg_result("no - Assuming $char_bit");
	}
    }
    #
    # It is impossible to have less than 8
    #
    if ($char_bit < 8) {
        die "CHAR_BIT size is $char_bit < 8";
    }
    $ac->define_var("C_CHAR_BIT", $char_bit);

    return $char_bit;
}

sub check_strtold {
    my ($ac) = @_;

    foreach my $value (qw/strtold _strtold __strtold/) {
	$ac->msg_checking($value);
	my $prologue = <<PROLOGUE;
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

PROLOGUE
	my $body = <<BODY;
  char *string = "3.14Stop";
  char *stopstring = NULL;

  $value(string, &stopstring);
  exit(0);
BODY
	my $program = $ac->lang_build_program($prologue, $body);
	if (try_run($program)) {
	    $ac->msg_result("yes");
	    $ac->define_var("C_STRTOLD", $value);
	    last;
	} else {
	    $ac->msg_result("no");
	}
    }
}

sub check_strtod {
    my ($ac) = @_;

    foreach my $value (qw/strtod _strtod __strtod/) {
	$ac->msg_checking($value);
	my $prologue = <<PROLOGUE;
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

PROLOGUE
	my $body = <<BODY;
  char *string = "3.14Stop";
  char *stopstring = NULL;

  $value(string, &stopstring);
  exit(0);
BODY
	my $program = $ac->lang_build_program($prologue, $body);
	if (try_run($program)) {
	    $ac->msg_result("yes");
	    $ac->define_var("C_STRTOD", $value);
	    last;
	} else {
	    $ac->msg_result("no");
	}
    }
}

sub check_strtof {
    my ($ac) = @_;

    foreach my $value (qw/strtof _strtof __strtof/) {
	$ac->msg_checking($value);
	my $prologue = <<PROLOGUE;
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

PROLOGUE
	my $body = <<BODY;
  char *string = "3.14Stop";
  char *stopstring = NULL;

  $value(string, &stopstring);
  exit(0);
BODY
	my $program = $ac->lang_build_program($prologue, $body);
	if (try_run($program)) {
	    $ac->msg_result("yes");
	    $ac->define_var("C_STRTOF", $value);
	    last;
	} else {
	    $ac->msg_result("no");
	}
    }
}

sub check_HUGE_VAL {
    my ($ac, $what, $value, $options) = @_;

    $ac->msg_checking($what);
    my $rc = 0;
    my $prologue = <<PROLOGUE;
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

#ifdef HAVE_MATH_H
#include <math.h>
#endif

#ifdef HAVE_HUGE_VAL_REPLACEMENT
#  define C_HUGE_VAL (__builtin_huge_val())
#endif

PROLOGUE
	my $body = <<BODY;
  double x = -C_HUGE_VAL;
  exit(0);
BODY
    my $program = $ac->lang_build_program($prologue, $body);
    if (try_run($program, $options)) {
        $ac->msg_result("yes");
        $ac->define_var($what, $value);
        $rc = 1;
    } else {
        $ac->msg_result("no");
        $rc = 0;
    }

    return $rc;
}

sub check_HUGE_VALF {
    my ($ac, $what, $value, $options) = @_;

    $ac->msg_checking($what);
    my $rc = 0;
    my $prologue = <<PROLOGUE;
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

#ifdef HAVE_MATH_H
#include <math.h>
#endif

#ifdef HAVE_HUGE_VALF_REPLACEMENT
#  define C_HUGE_VALF (__builtin_huge_valf())
#endif

PROLOGUE
	my $body = <<BODY;
  float x = -C_HUGE_VALF;
  exit(0);
BODY
    my $program = $ac->lang_build_program($prologue, $body);
    if (try_run($program, $options)) {
        $ac->msg_result("yes");
        $ac->define_var($what, $value);
        $rc = 1;
    } else {
        $ac->msg_result("no");
        $rc = 0;
    }

    return $rc;
}

sub check_HUGE_VALL {
    my ($ac, $what, $value, $options) = @_;

    $ac->msg_checking($what);
    my $rc = 0;
    my $prologue = <<PROLOGUE;
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

#ifdef HAVE_MATH_H
#include <math.h>
#endif

#ifdef HAVE_HUGE_VALL_REPLACEMENT
#  define C_HUGE_VALL (__builtin_huge_vall())
#endif

PROLOGUE
	my $body = <<BODY;
  long double x = -C_HUGE_VALL;
  exit(0);
BODY
    my $program = $ac->lang_build_program($prologue, $body);
    if (try_run($program, $options)) {
        $ac->msg_result("yes");
        $ac->define_var($what, $value);
        $rc = 1;
    } else {
        $ac->msg_result("no");
        $rc = 0;
    }

    return $rc;
}

sub check_INFINITY {
    my ($ac, $what, $value, $options) = @_;

    $ac->msg_checking($what);
    my $rc = 0;
    my $prologue = <<PROLOGUE;
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

#ifdef HAVE_MATH_H
#include <math.h>
#endif

#ifdef HAVE_INFINITY_REPLACEMENT_USING_DIVISION
#  define C_INFINITY (1.0 / 0.0)
#else
#  ifdef HAVE_INFINITY_REPLACEMENT
#    define C_INFINITY (__builtin_inff())
#  endif
#endif

PROLOGUE
	my $body = <<BODY;
  float x = -C_INFINITY;
  exit(0);
BODY
    my $program = $ac->lang_build_program($prologue, $body);
    if (try_run($program, $options)) {
        $ac->msg_result("yes");
        $ac->define_var($what, $value);
        $rc = 1;
    } else {
        $ac->msg_result("no");
        $rc = 0;
    }

    return $rc;
}

sub check_NAN {
    my ($ac, $what, $value, $options) = @_;

    $ac->msg_checking($what);
    my $rc = 0;
    my $prologue = <<PROLOGUE;
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

#ifdef HAVE_MATH_H
#include <math.h>
#endif

#ifdef HAVE_NAN_REPLACEMENT_USING_DIVISION
#  define C_NAN (0.0 / 0.0)
#else
#  ifdef HAVE_NAN_REPLACEMENT
#    define C_NAN (__builtin_nanf(""))
#  endif
#endif

PROLOGUE
	my $body = <<BODY;
  float x = C_NAN;
  exit(0);
BODY
    my $program = $ac->lang_build_program($prologue, $body);
    if (try_run($program, $options)) {
        $ac->msg_result("yes");
        $ac->define_var($what, $value);
        $rc = 1;
    } else {
        $ac->msg_result("no");
        $rc = 0;
    }

    return $rc;
}

sub check_isinf {
    my ($ac, $what, $value, $options) = @_;

    $ac->msg_checking($what);
    my $rc = 0;
    my $prologue = <<PROLOGUE;
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

#ifdef HAVE_MATH_H
#include <math.h>
#endif

#ifdef HAVE_ISINF_REPLACEMENT
#  undef C_ISINF
#  define C_ISINF(x) (__builtin_isinf(x))
#endif

PROLOGUE
	my $body = <<BODY;
  short x = C_ISINF(0.0);
  exit(0);
BODY
    my $program = $ac->lang_build_program($prologue, $body);
    if (try_run($program, $options)) {
        $ac->msg_result("yes");
        $ac->define_var($what, $value);
        $rc = 1;
    } else {
        $ac->msg_result("no");
        $rc = 0;
    }

    return $rc;
}

sub check_isnan {
    my ($ac, $what, $value, $options) = @_;

    $ac->msg_checking($what);
    my $rc = 0;
    my $prologue = <<PROLOGUE;
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

#ifdef HAVE_MATH_H
#include <math.h>
#endif

#ifdef HAVE_ISNAN_REPLACEMENT
#  undef C_ISNAN
#  define C_ISNAN(x) (__builtin_isnan(x))
#endif

PROLOGUE
	my $body = <<BODY;
  short x = C_ISNAN(0.0);
  exit(0);
BODY
    my $program = $ac->lang_build_program($prologue, $body);
    if (try_run($program, $options)) {
        $ac->msg_result("yes");
        $ac->define_var($what, $value);
        $rc = 1;
    } else {
        $ac->msg_result("no");
        $rc = 0;
    }

    return $rc;
}

sub check_strtoll {
    my ($ac) = @_;

    foreach my $value (qw/strtoll _strtoll __strtoll strtoi64 _strtoi64 __strtoi64/) {
	$ac->msg_checking($value);
	my $prologue = <<PROLOGUE;
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

#if defined(_MSC_VER) || defined(__BORLANDC__)
/* Just because these compilers might not have long long, but they always have __int64. */
/*   Note that on Windows short is always 2, int is always 4, long is always 4, __int64 is always 8 */
#  define LONG_LONG __int64
#else
#  define LONG_LONG long long
#endif

PROLOGUE
	my $body = <<BODY;
  char      *p = "123";
  char      *endptrp;
  LONG_LONG  ll;

  ll = $value(p, &endptrp, 10);
  exit(0);
BODY
	my $program = $ac->lang_build_program($prologue, $body);
	if (try_run($program)) {
	    $ac->msg_result("yes");
	    $ac->define_var("C_STRTOLL", $value);
	    last;
	} else {
	    $ac->msg_result("no");
	}
    }
}

sub check_strtoull {
    my ($ac) = @_;

    foreach my $value (qw/strtoull _strtoull __strtoull strtou64 _strtou64 __strtou64/) {
	$ac->msg_checking($value);
	my $prologue = <<PROLOGUE;
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

#if defined(_MSC_VER) || defined(__BORLANDC__)
/* Just because these compilers might not have long long, but they always have __int64. */
/*   Note that on Windows short is always 2, int is always 4, long is always 4, __int64 is always 8 */
#  define ULONG_LONG unsigned __int64
#else
#  define ULONG_LONG unsigned long long
#endif

PROLOGUE
	my $body = <<BODY;
  char      *p = "123";
  char      *endptrp;
  ULONG_LONG ull;

  ull = $value(p, &endptrp, 10);
  exit(0);
BODY
	my $program = $ac->lang_build_program($prologue, $body);
	if (try_run($program)) {
	    $ac->msg_result("yes");
	    $ac->define_var("C_STRTOLL", $value);
	    last;
	} else {
	    $ac->msg_result("no");
	}
    }
}

sub check_fpclassify {
    my ($ac) = @_;

    foreach my $value (qw/fpclassify _fpclassify __fpclassify fpclass _fpclass __fpclass/) {
	$ac->msg_checking($value);
	my $prologue = <<PROLOGUE;
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

#ifdef HAVE_MATH_H
#include <math.h>
#endif

#ifdef HAVE_FLOAT_H
#include <float.h>
#endif

PROLOGUE
	my $body = <<BODY;
  int x = $value(0.0);
  exit(0);
BODY
	my $program = $ac->lang_build_program($prologue, $body);
	if (try_run($program)) {
	    $ac->msg_result("yes");
	    $ac->define_var("C_FPCLASSIFY", $value);
	    last;
	} else {
	    $ac->msg_result("no");
	}
    }
}

sub check_fp_constant {
    my ($ac, $what, $value, $options) = @_;

    $ac->msg_checking($value); # and not $what, we know what we are doing
    my $rc = 0;
    my $prologue = <<PROLOGUE;
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

#ifdef HAVE_MATH_H
#include <math.h>
#endif

#ifdef HAVE_FLOAT_H
#include <float.h>
#endif

#define $what $value

PROLOGUE
	my $body = <<BODY;
  short x = $what;
  exit(0);
BODY
    my $program = $ac->lang_build_program($prologue, $body);
    if (try_run($program, $options)) {
        $ac->msg_result("yes");
        $ac->define_var($what, $value);
        $rc = 1;
    } else {
        $ac->msg_result("no");
        $rc = 0;
    }

    return $rc;
}

sub check_const {
    my ($ac) = @_;

    foreach my $value (qw/const/) {
	$ac->msg_checking($value);
	my $prologue = <<PROLOGUE;
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

PROLOGUE
	my $body = <<BODY;
  $value int i = 1;
  exit(0);
BODY
	my $program = $ac->lang_build_program($prologue, $body);
	if (try_run($program)) {
	    $ac->msg_result("yes");
	    $ac->define_var("C_CONST", $value);
	    last;
	} else {
	    $ac->msg_result("no");
	}
    }
}

sub check_c99_modifiers {
    my ($ac) = @_;

    $ac->msg_checking('C99 modifiers');
    my $prologue = <<PROLOGUE;
#ifdef HAVE_STDLIB_H
#  include <stdlib.h>
#endif

#ifdef HAVE_STDINT_H
#  include <stdint.h>
#endif

#ifdef HAVE_STDDEF_H
#  include <stddef.h>
#endif

#ifdef HAVE_SYS_STDINT_H
#  include <sys/stdint.h>
#endif

#ifdef HAVE_STDIO_H
#include <stdio.h>
#endif

#ifdef HAVE_STRING_H
#include <string.h>
#endif

PROLOGUE
	my $body = <<BODY;
  char buf[64];

  if (sprintf(buf, "%zu", (size_t)1234) != 4) {
    exit(1);
  }
  else if (strcmp(buf, "1234") != 0) {
    exit(2);
  }

  exit(0);
BODY
    my $program = $ac->lang_build_program($prologue, $body);
    if (try_run($program)) {
        $ac->msg_result("yes");
        $ac->define_var("HAVE_C99MODIFIERS", 1);
    } else {
        $ac->msg_result("no");
    }
}

sub check_restrict {
    my ($ac) = @_;

    foreach my $value (qw/__restrict __restrict__ _Restrict restrict/) {
	$ac->msg_checking($value);
	my $prologue = <<PROLOGUE;
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

static int foo (int *$value ip);
static int bar (int ip[]);

static int foo (int *$value ip) {
  return ip[0];
}

static int bar (int ip[]) {
  return ip[0];
}

PROLOGUE
	my $body = <<BODY;
  int s[1];
  int *$value t = s;
  t[0] = 0;
  exit(foo (t) + bar (t));
BODY
	my $program = $ac->lang_build_program($prologue, $body);
	if (try_run($program)) {
	    $ac->msg_result("yes");
	    $ac->define_var("C_RESTRICT", $value);
	    last;
	} else {
	    $ac->msg_result("no");
	}
    }
}

sub check_builtin_expect {
    my ($ac) = @_;

    foreach my $value (qw/__builtin_expect/) {
	$ac->msg_checking($value);
	my $prologue = <<PROLOGUE;
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

#define C_LIKELY(x)    $value(!!(x), 1)
#define C_UNLIKELY(x)  $value(!!(x), 0)

/* Copied from https://kernelnewbies.org/FAQ/LikelyUnlikely */
int test_expect(char *s)
{
   int a;

   /* Get the value from somewhere GCC can't optimize */
   a = atoi(s);

   if (C_UNLIKELY(a == 2)) {
      a++;
   } else {
      a--;
   }
}

PROLOGUE
	my $body = <<BODY;
  test_expect("1");
  exit(0);
BODY
	my $program = $ac->lang_build_program($prologue, $body);
	if (try_run($program)) {
	    $ac->msg_result("yes");
	    $ac->define_var("C___BUILTIN_EXPECT", $value);
	    last;
	} else {
	    $ac->msg_result("no");
	}
    }
}

sub check_signbit {
    my ($ac) = @_;

    foreach my $value (qw/signbit _signbit __signbit/) {
	$ac->msg_checking($value);
	my $prologue = <<PROLOGUE;
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

#ifdef HAVE_MATH_H
#include <math.h>
#endif

PROLOGUE
	my $body = <<BODY;
  float f = -1.0;
  int i = $value(f);

  exit(0);
BODY
	my $program = $ac->lang_build_program($prologue, $body);
	if (try_run($program)) {
	    $ac->msg_result("yes");
	    $ac->define_var("C_SIGNBIT", $value);
	    last;
	} else {
	    $ac->msg_result("no");
	}
    }
}

sub check_copysign {
    my ($ac) = @_;

    foreach my $value (qw/copysign _copysign __copysign/) {
	$ac->msg_checking($value);
	my $prologue = <<PROLOGUE;
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

#ifdef HAVE_MATH_H
#include <math.h>
#endif

PROLOGUE
	my $body = <<BODY;
  double neg = -1.0;
  double pos = 1.0;
  double res = $value(pos, neg);

  exit(0);
BODY
	my $program = $ac->lang_build_program($prologue, $body);
	if (try_run($program)) {
	    $ac->msg_result("yes");
	    $ac->define_var("C_COPYSIGN", $value);
	    last;
	} else {
	    $ac->msg_result("no");
	}
    }
}

sub check_copysignf {
    my ($ac) = @_;

    foreach my $value (qw/copysignf _copysignf __copysignf/) {
	$ac->msg_checking($value);
	my $prologue = <<PROLOGUE;
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

#ifdef HAVE_MATH_H
#include <math.h>
#endif

PROLOGUE
	my $body = <<BODY;
  float neg = -1.0;
  float pos = 1.0;
  float res = $value(pos, neg);

  exit(0);
BODY
	my $program = $ac->lang_build_program($prologue, $body);
	if (try_run($program)) {
	    $ac->msg_result("yes");
	    $ac->define_var("C_COPYSIGNF", $value);
	    last;
	} else {
	    $ac->msg_result("no");
	}
    }
}

sub check_copysignl {
    my ($ac) = @_;

    foreach my $value (qw/copysignl _copysignl __copysignl/) {
	$ac->msg_checking($value);
	my $prologue = <<PROLOGUE;
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

#ifdef HAVE_MATH_H
#include <math.h>
#endif

PROLOGUE
	my $body = <<BODY;
  long double neg = -1.0;
  long double pos = 1.0;
  long double res = $value(pos, neg);

  exit(0);
BODY
	my $program = $ac->lang_build_program($prologue, $body);
	if (try_run($program)) {
	    $ac->msg_result("yes");
	    $ac->define_var("C_COPYSIGNL", $value);
	    last;
	} else {
	    $ac->msg_result("no");
	}
    }
}

sub check_nl_langinfo {
    my ($ac) = @_;

    $ac->msg_checking("langinfo's CODESET");
    my $prologue = <<PROLOGUE;
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

#ifdef HAVE_LANGINFO_H
#include <langinfo.h>
#endif

PROLOGUE
    my $body = <<BODY;
  char *cs = nl_langinfo(CODESET);
  exit(0);
BODY
    my $program = $ac->lang_build_program($prologue, $body);
    if (try_run($program)) {
        $ac->msg_result("yes");
        $ac->define_var("HAVE_LANGINFO_CODESET", 1);
    } else {
        $ac->msg_result("no");
    }
}

sub check_getc_unlocked {
    my ($ac) = @_;

    my $rc;
    $ac->msg_checking('getc_unlocked');
    my $prologue = <<PROLOGUE;
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

#ifdef HAVE_STDIO_H
#include <stdio.h>
#endif

PROLOGUE
    my $body = <<BODY;
  getc_unlocked(stdin);
  exit(0);
BODY
    my $program = $ac->lang_build_program($prologue, $body);
    if (try_compile($program)) {
        $ac->msg_result("yes");
        $ac->define_var("HAVE_DECL_LANGINFO_CODESET", 1);
        $rc = 1;
    } else {
        $ac->msg_result("no");
        $rc = 0;
    }

    return $rc;
}

sub check_broken_wchar {
    my ($ac) = @_;

    my $rc;
    $ac->msg_checking('broken wchar.h');
    my $prologue = <<PROLOGUE;
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

#ifdef HAVE_WCHAR_H
#include <wchar.h>
#endif

wchar_t w;

PROLOGUE
    my $body = <<BODY;
  exit(0);
BODY
    my $program = $ac->lang_build_program($prologue, $body);
    if (try_compile($program)) {
        $ac->msg_result("no");
        $rc = 0;
    } else {
        $ac->msg_result("yes");
        $rc = 1;
    }

    return $rc;
}

sub check_gnu_source {
    my ($ac) = @_;

    $ac->msg_checking('__GNU_LIBRARY__');
    my $prologue = <<PROLOGUE;
#ifdef HAVE_FEATURES_H
#include <features.h>
#endif

PROLOGUE
    my $body = <<BODY;
  int gnu_library = __GNU_LIBRARY__;
  exit(gnu_library ? 0 : 1);
BODY
    my $program = $ac->lang_build_program($prologue, $body);
    if (try_run($program)) {
        $ac->msg_result("yes");
        $ac->msg_notice("Append _GNU_SOURCE to compile flags");
        $ENV{CFLAGS} .= ' -D_GNU_SOURCE';
        $ENV{CXXFLAGS} .= ' -D_GNU_SOURCE';
    } else {
        $ac->msg_result("no");
    }
}

sub check_compiler_is_gnu {
    my ($ac) = @_;

    $ac->msg_checking('GNU compiler');
    my $rc;
    my $prologue = <<PROLOGUE;
#if !defined(__GNUC__)
# error "__GNUC__ is not defined"
#endif

PROLOGUE
    my $program = $ac->lang_build_program($prologue);
    if (try_run($program)) {
        $ac->msg_result("yes");
        $ac->define_var("C_COMPILER_IS_GNU", 1);
        $rc = 1;
    } else {
        $ac->msg_result("no");
        $rc = 0;
    }

    return $rc;
}

sub check_compiler_is_clang {
    my ($ac) = @_;

    $ac->msg_checking('Clang compiler');
    my $rc;
    my $prologue = <<PROLOGUE;
#if !defined(__clang__)
# error "__clang__ is not defined"
#endif

PROLOGUE
    my $program = $ac->lang_build_program($prologue);
    if (try_run($program)) {
        $ac->msg_result("yes");
        $ac->define_var("C_COMPILER_IS_CLANG", 1);
        $rc = 1;
    } else {
        $ac->msg_result("no");
        $rc = 0;
    }

    return $rc;
}

sub check_compiler_function_attribute {
    my ($ac, $what, $value, $attribute, $options) = @_;

    $ac->msg_checking("function attribute $attribute");
    my $rc = 0;
    my $prologue = <<PROLOGUE;
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_ALIAS
  int foo( void ) { return 0; }
  int bar( void ) __attribute__((alias("foo")));
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_ALIGNED
  int foo( void ) __attribute__((aligned(32)));
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_ALLOC_SIZE
  void *foo(int a) __attribute__((alloc_size(1)));
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_ALWAYS_INLINE
inline __attribute__((always_inline)) int foo( void ) { return 0; }
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_ARTIFICIAL
inline __attribute__((artificial)) int foo( void ) { return 0; }
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_COLD
  int foo( void ) __attribute__((cold));
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_CONST
  int foo( void ) __attribute__((const));
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_CONSTRUCTOR_PRIORITY
  int foo( void ) __attribute__((__constructor__(65535/2)));
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_CONSTRUCTOR
  int foo( void ) __attribute__((constructor));
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_DEPRECATED
  int foo( void ) __attribute__((deprecated("")));
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_DESTRUCTOR
  int foo( void ) __attribute__((destructor));
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_DLLEXPORT
__attribute__((dllexport)) int foo( void ) { return 0; }
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_DLLIMPORT
  int foo( void ) __attribute__((dllimport));
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_ERROR
  int foo( void ) __attribute__((error("")));
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_EXTERNALLY_VISIBLE
  int foo( void ) __attribute__((externally_visible));
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_FALLTHROUGH
  int foo( void ) {switch (0) { case 1: __attribute__((fallthrough)); case 2: break ; }};
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_FLATTEN
  int foo( void ) __attribute__((flatten));
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_FORMAT
  int foo(const char *p, ...) __attribute__((format(printf, 1, 2)));
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_GNU_FORMAT
  int foo(const char *p, ...) __attribute__((format(gnu_printf, 1, 2)));
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_FORMAT_ARG
char *foo(const char *p) __attribute__((format_arg(1)));
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_GNU_INLINE
inline __attribute__((gnu_inline)) int foo( void ) { return 0; }
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_HOT
  int foo( void ) __attribute__((hot));
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_IFUNC
  int my_foo( void ) { return 0; }
  static int (*resolve_foo(void))(void) { return my_foo; }
  int foo( void ) __attribute__((ifunc("resolve_foo")));
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_LEAF
__attribute__((leaf)) int foo( void ) { return 0; }
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_MALLOC
  void *foo( void ) __attribute__((malloc));
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_NOCLONE
  int foo( void ) __attribute__((noclone1));
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_NOINLINE
__attribute__((noinline1)) int foo( void ) { return 0; }
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_NONNULL
  int foo(char *p) __attribute__((nonnull(1)));
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_NORETURN
  void foo( void ) __attribute__((noreturn));
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_NOTHROW
  int foo( void ) __attribute__((nothrow1));
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_OPTIMIZE
__attribute__((optimize(3))) int foo( void ) { return 0; }
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_PURE
  int foo( void ) __attribute__((pure));
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_SENTINEL
  int foo(void *p, ...) __attribute__((sentinel));
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_SENTINEL_POSITION
  int foo(void *p, ...) __attribute__((sentinel_position(1)));
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_RETURNS_NONNULL
  void *foo( void ) __attribute__((returns_nonnull));
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_UNUSED
  int foo( void ) __attribute__((unused));
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_USED
  int foo( void ) __attribute__((used));
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_VISIBILITY
  int foo_def( void ) __attribute__((visibility("default")));
  int foo_hid( void ) __attribute__((visibility("hidden")));
  int foo_int( void ) __attribute__((visibility("internal")));
  int foo_pro( void ) __attribute__((visibility("protected")));
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_WARNING
  int foo( void ) __attribute__((warning1("")));
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_WARN_UNUSED_RESULT
  int foo( void ) __attribute__((warn_unused_result));
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_WEAK
  int foo( void ) __attribute__((weak));
  int test_attribute() { exit(0); }
#endif

#ifdef TEST_GCC_FUNC_ATTRIBUTE_WEAKREF
  static int foo( void ) { return 0; }
  static int bar( void ) __attribute__((weakref("foo")));
  int test_attribute() { exit(0); }
#endif

PROLOGUE
	my $body = <<BODY;
  test_attribute();
  exit(1);
BODY
    my $program = $ac->lang_build_program($prologue, $body);
    if (try_run($program, $options)) {
        $ac->msg_result("yes");
        $ac->define_var($what, $value);
        $rc = 1;
    } else {
        $ac->msg_result("no");
        $rc = 0;
    }

    return $rc;
}

sub configure_file {
    my ($ac, $in, $out) = @_;

    print "Generating $out\n";

    #
    # We want to look to:
    # #cmakedefine[01] XXX
    # #cmakedefine XXX @YYY@
    #

    my $in_define = basename($out);
    $in_define =~ s/[^a-zA-Z0-9_]/_/g;
    my $IN_DEFINE = uc($in_define);
    #
    # We always prepend with:
    #
    # #include $CONFIG_H
    #
    open(my $fhout, '>', $out) || die "Cannot open for writing $out, $!";
    print $fhout "#include <" . basename($CONFIG_H) . ">\n";
    #
    # Do input replacement and write it
    #
    open(my $fhin, '<', $in) || die "Cannot open for reading $in, $!";
    while (defined(my $line = <$fhin>)) {
        #
        # We ignore all lines that start with #cmakedefine: our config.h is doing all the #define's
        #
        if ($line =~ /^\s*#\s*cmakedefine(?:01)?\b/) {
            next;
        }
        #
        # Replace @XXX@ with XXX anyway if it exist. We support only one occurence.
        #
        if ($line =~ /\@([a-zA-Z0-9_]+)\@/) {
            if (! exists($ac->{defines}->{$1}) || ! defined($ac->{defines}->{$1})) {
                next;
            }
            my $value = $ac->{defines}->{$1}->[0];
            $line =~ s/\@([a-zA-Z0-9_]+)\@/$value/;
        }
        
        print $fhout "$line";
    }
    close($fhin) || warn "Cannot close $in, $!";
    close($fhout) || warn "Cannot close $out, $!";
}

sub process_genericStack {
    my ($ac) = @_;

    my $tar = Archive::Tar->new;
    my $input = File::Spec->catfile($TARBALLS_DIR, 'genericstack-src.tar.gz');
    $tar->read($input);
    my $outdir = File::Spec->catdir($EXTRACT_DIR, 'genericStack');
    print "Extracting $input\n";
    make_path($outdir);
    {
        local $CWD = $outdir;
        $tar->extract();
    }
}

sub process_genericHash {
    my ($ac) = @_;

    my $tar = Archive::Tar->new;
    my $input = File::Spec->catfile($TARBALLS_DIR, 'generichash-src.tar.gz');
    $tar->read($input);
    my $outdir = File::Spec->catdir($EXTRACT_DIR, 'genericHash');
    print "Extracting $input\n";
    make_path($outdir);
    {
        local $CWD = $outdir;
        $tar->extract();
    }
}

sub process_genericSparseArray {
    my ($ac) = @_;

    my $tar = Archive::Tar->new;
    my $input = File::Spec->catfile($TARBALLS_DIR, 'genericsparsearray-src.tar.gz');
    $tar->read($input);
    my $outdir = File::Spec->catdir($EXTRACT_DIR, 'genericSparseArray');
    print "Extracting $input\n";
    make_path($outdir);
    {
        local $CWD = $outdir;
        $tar->extract();
    }
}

sub process_genericLogger {
    my ($ac) = @_;

    my $tar = Archive::Tar->new;
    my $input = File::Spec->catfile($TARBALLS_DIR, 'genericlogger-src.tar.gz');
    $tar->read($input);
    my $outdir = File::Spec->catdir($EXTRACT_DIR, 'genericLogger');
    print "Extracting $input\n";
    make_path($outdir);
    {
        local $CWD = $outdir;
        $tar->extract();
    }
    #
    # Get project, version and generate compile flag, export.h
    #
    my ($project, $version, $major, $minor, $patch) = get_project_and_version($ac, $outdir);
    my $PROJECT = uc($project);
    my @extra_compiler_flags = ("-D${PROJECT}_NTRACE");
    generate_export_h($ac, $outdir, $project, $version, $major, $minor, $patch);
    #
    # Add include directory to compile flags
    #
    my @include_dirs = ( File::Spec->catdir($outdir, 'include') );
    #
    # Configure
    #
    configure_file
        (
         $ac,
         File::Spec->catfile($outdir, 'include', 'genericLogger', 'internal', 'config.h.in'),
         File::Spec->catfile($outdir, 'include', 'genericLogger', 'internal', 'config.h')
        );

    #
    # Compile
    #
    my $b = get_cbuilder();
    my @sources = ( File::Spec->catfile($outdir, 'src', 'genericLogger.c') );
    foreach my $source (@sources) {
        $b->compile
            (
             source => $source,
             include_dirs => \@include_dirs,
             object_file => get_object_file($source),
             extra_compiler_flags => \@extra_compiler_flags
            );
    }
}

sub process_tconv {
    my ($ac) = @_;

    my $tar = Archive::Tar->new;
    my $input = File::Spec->catfile($TARBALLS_DIR, 'tconv-src.tar.gz');
    $tar->read($input);
    my $outdir = File::Spec->catdir($EXTRACT_DIR, 'tconv');
    print "Extracting $input\n";
    make_path($outdir);
    {
        local $CWD = $outdir;
        $tar->extract();
    }
    #
    # Inside tconv there is libiconv
    #
    process_libiconv($ac);
    #
    # Inside tconv there is cchardet
    #
    process_cchardet($ac);
    #
    # Inside tconv there is dlfcn-win32
    #
    if (! $HAVE_HEADERS{"dlfcn.h"}) {
	#
	# It makes non-sense to compile dlfcn-win32 in this not a Windows platform
	# (Note that dlcfn-win32 compiles fine with gcc/mingw-gcc on Win32)
	#
	if (! $IS_WINDOWS) {
	    $ac->msg_notice("Attempting to compile dlfcn-win32 even if the OS type does not seems to be Windows - please install dlfcn library and header otherwise");
	}
	process_dlfcn_win32($ac);
    }
    #
    # Get project, version and generate compile flag, export.h
    #
    my ($project, $version, $major, $minor, $patch) = get_project_and_version($ac, $outdir);
    my $PROJECT = uc($project);
    my @extra_compiler_flags = (
        '-DTCONV_HAVE_ICONV=1',
        '-DICONV_CAN_TRANSLIT=1',
        '-DICONV_CAN_IGNORE=1',
        "-D${PROJECT}_NTRACE"
        );
    generate_export_h($ac, $outdir, $project, $version, $major, $minor, $patch);
    #
    # Configure
    #
    configure_file
        (
         $ac,
         File::Spec->catfile($outdir, 'include', 'tconv', 'internal', 'config.h.in'),
         File::Spec->catfile($outdir, 'include', 'tconv', 'internal', 'config.h')
        );
    #
    # Compile
    #
    my $b = get_cbuilder();
    my @sources =
        (
         File::Spec->catfile($outdir, 'src', 'tconv.c'),
         File::Spec->catfile($outdir, 'src', 'tconv', 'charset', 'tconv_charset_cchardet.c'),
         File::Spec->catfile($outdir, 'src', 'tconv', 'convert', 'tconv_convert_iconv.c'),
        );
    my @include_dirs = (
	File::Spec->catdir($EXTRACT_DIR, 'genericLogger', 'include'),
	File::Spec->catdir($EXTRACT_DIR, 'libiconv-1.17', 'include'),
	File::Spec->catdir($EXTRACT_DIR, 'cchardet-1.0.0', 'src', 'ext', 'libcharsetdetect'),
	File::Spec->catdir($outdir, 'include')
	);
    if (! $HAVE_HEADERS{"dlfcn.h"}) {
	push(@include_dirs, File::Spec->catdir($EXTRACT_DIR, 'dlfcn-win32-1.4.1', 'src'));
    }
    foreach my $source (@sources) {
        $b->compile
            (
             source => $source,
             object_file => get_object_file($source),
             include_dirs => \@include_dirs,
             extra_compiler_flags => \@extra_compiler_flags
            );
    }
}

sub process_marpaWrapper {
    my ($ac) = @_;

    my $tar = Archive::Tar->new;
    my $input = File::Spec->catfile($TARBALLS_DIR, 'marpawrapper-src.tar.gz');
    $tar->read($input);
    my $outdir = File::Spec->catdir($EXTRACT_DIR, 'marpaWrapper');
    print "Extracting $input\n";
    make_path($outdir);
    {
        local $CWD = $outdir;
        $tar->extract();
    }
    #
    # Get project, version and generate compile flag, export.h
    #
    my ($project, $version, $major, $minor, $patch) = get_project_and_version($ac, $outdir);
    my $PROJECT = uc($project);
    my @extra_compiler_flags = (
        "-D${PROJECT}_NTRACE",
        "-DMARPA_LIB_MAJOR_VERSION=MARPA_MAJOR_VERSION",
        "-DMARPA_LIB_MINOR_VERSION=MARPA_MINOR_VERSION",
        "-DMARPA_LIB_MICRO_VERSION=MARPA_MICRO_VERSION",
        );
    generate_export_h($ac, $outdir, $project, $version, $major, $minor, $patch);
    #
    # Configure
    #
    configure_file
        (
         $ac,
         File::Spec->catfile($outdir, 'include', 'marpaWrapper', 'internal', 'config.h.in'),
         File::Spec->catfile($outdir, 'include', 'marpaWrapper', 'internal', 'config.h')
        );
    #
    # Compile
    #
    my $b = get_cbuilder();
    my @sources =
        (
         File::Spec->catfile($outdir, 'amalgamation', 'marpaWrapper.c')
        );
    my @include_dirs =
        (
         File::Spec->catdir($outdir, 'libmarpa', 'work', 'stage'),
         File::Spec->catdir($outdir, 'include', 'marpaWrapper', 'internal'),
         File::Spec->catdir($EXTRACT_DIR, 'genericLogger', 'include'),
         File::Spec->catdir($EXTRACT_DIR, 'genericStack', 'include'),
         File::Spec->catdir($EXTRACT_DIR, 'genericHash', 'include'),
         File::Spec->catdir($EXTRACT_DIR, 'genericSparseArray', 'include'),
         File::Spec->catdir($outdir, 'include')
        );

    foreach my $source (@sources) {
        $b->compile
            (
             source => $source,
             object_file => get_object_file($source),
             include_dirs => \@include_dirs,
             extra_compiler_flags => \@extra_compiler_flags
            );
    }
}

sub process_marpaESLIF {
    my ($ac) = @_;

    my $tar = Archive::Tar->new;
    my $input = File::Spec->catfile($TARBALLS_DIR, 'marpaeslif-src.tar.gz');
    $tar->read($input);
    my $outdir = File::Spec->catdir($EXTRACT_DIR, 'marpaESLIF');
    print "Extracting $input\n";
    make_path($outdir);
    {
        local $CWD = $outdir;
        $tar->extract();
    }
    #
    # We depend on pcre2 object that we distribute
    #
    process_pcre2($ac);
    #
    # We depend on luaunpanic
    #
    process_luaunpanic($ac);
    #
    # We depend on luaunpanic
    #
    process_marpaESLIFLua($ac);
    #
    # Get project, version and generate compile flag, export.h
    #
    my ($project, $version, $major, $minor, $patch) = get_project_and_version($ac, $outdir);
    my $PROJECT = uc($project);
    $ac->define_var("MARPAESLIF_UINT32_T", "CMAKE_HELPERS_UINT32_TYPEDEF");
    $ac->define_var("MARPAESLIF_UINT64_T", "CMAKE_HELPERS_UINT64_TYPEDEF");
    my @extra_compiler_flags = ();
    push(@extra_compiler_flags, "-D${PROJECT}_NTRACE");
    if ($IS_WINDOWS) {
	#
	# DLL platform
	#
        push(@extra_compiler_flags, "-DLUA_DL_DLL=1");
    } else {
        push(@extra_compiler_flags, "-DLUA_USE_DLOPEN=1");
        push(@extra_compiler_flags, "-DLUA_USE_POSIX=1");
    }
    push(@extra_compiler_flags, "-DMARPAESLIFLUA_EMBEDDED=1");
    push(@extra_compiler_flags, "-DMARPAESLIF_BUFSIZ=1048576");
    push(@extra_compiler_flags, "-DPCRE2_CODE_UNIT_WIDTH=8");
    push(@extra_compiler_flags, "-DPCRE2_STATIC=1");
    #
    # We want to align lua integer type with perl ivtype
    #
    my $ivtype = $Config{ivtype} || '';
    if ($ivtype eq 'int') {
        push(@extra_compiler_flags, "-DLUA_INT_TYPE=1");
    } elsif ($ivtype eq 'long') {
        push(@extra_compiler_flags, "-DLUA_INT_TYPE=2");
    } elsif ($ivtype eq 'long long') {
        push(@extra_compiler_flags, "-DLUA_INT_TYPE=3");
    } else {
        $ac->msg_notice("No exact map found in lua for perl integer type \"$ivtype\": use long long for lua_Integer");
        push(@extra_compiler_flags, "-DLUA_INT_TYPE=3");
    }
    #
    # We want to align lua float type with perl nvtype
    #
    my $nvtype = $Config{nvtype} || '';
    if ($nvtype eq 'float') {
        push(@extra_compiler_flags, "-DLUA_FLOAT_TYPE=1");
    } elsif ($nvtype eq 'double') {
        push(@extra_compiler_flags, "-DLUA_FLOAT_TYPE=2");
    } elsif ($nvtype eq 'long double') {
        push(@extra_compiler_flags, "-DLUA_FLOAT_TYPE=3");
    } else {
        $ac->msg_notice("No exact map found in lua for perl double type \"$nvtype\": use long double for lua_Number");
        push(@extra_compiler_flags, "-DLUA_FLOAT_TYPE=3");
    }
    my $extra_defines = <<EXTRA_DEFINES;
#define MARPAESLIFLUA_VERSION_MAJOR $major
#define MARPAESLIFLUA_VERSION_MINOR $minor
#define MARPAESLIFLUA_VERSION_PATCH $patch
#define MARPAESLIFLUA_VERSION "$version"
EXTRA_DEFINES
    generate_export_h($ac, $outdir, $project, $version, $major, $minor, $patch, $extra_defines);
    #
    # Configure
    #
    configure_file
        (
         $ac,
         File::Spec->catfile($outdir, 'include', 'marpaESLIF', 'internal', 'config.h.in'),
         File::Spec->catfile($outdir, 'include', 'marpaESLIF', 'internal', 'config.h')
        );
    #
    # Compile
    #
    my $b = get_cbuilder();
    my @sources =
        (
         File::Spec->catfile($outdir, 'src', 'marpaESLIF.c')
        );
    my @include_dirs =
        (
         File::Spec->catdir($EXTRACT_DIR, 'marpaWrapper', 'include'),
         File::Spec->catdir($EXTRACT_DIR, 'tconv', 'include'),
         File::Spec->catdir($EXTRACT_DIR, 'pcre2-10.42', 'src'),
         File::Spec->catdir($EXTRACT_DIR, 'luaunpanic', 'include', 'luaunpanic', 'lua'), # For luaconf.h
         File::Spec->catdir($EXTRACT_DIR, 'luaunpanic', 'include'),
         File::Spec->catdir($EXTRACT_DIR, 'luaunpanic', 'src'), # For luaunpanic_amalgamation.c
         File::Spec->catdir($EXTRACT_DIR, 'marpaESLIFLua', 'include'), # For marpaESLFLua.h
         File::Spec->catdir($EXTRACT_DIR, 'marpaESLIFLua', 'src'), # For marpaESLFLua.c
         File::Spec->catdir($EXTRACT_DIR, 'genericLogger', 'include'),
         File::Spec->catdir($EXTRACT_DIR, 'genericStack', 'include'),
         File::Spec->catdir($EXTRACT_DIR, 'genericHash', 'include'),
         File::Spec->catdir($outdir, 'include')
        );

    foreach my $source (@sources) {
        $b->compile
            (
             source => $source,
             object_file => get_object_file($source),
             include_dirs => \@include_dirs,
             extra_compiler_flags => \@extra_compiler_flags
            );
    }
}

sub process_libiconv {
    my ($ac) = @_;

    my $tar = Archive::Tar->new;
    my $input = File::Spec->catfile($EXTRACT_DIR, 'tconv', '3rdparty', 'tar', 'libiconv-1.17.tar.gz');
    $tar->read($input);
    my $outdir = $EXTRACT_DIR; # libiconv-1.17 is part of the tar
    print "Extracting $input\n";
    make_path($outdir);
    {
        local $CWD = $outdir;
        $tar->extract();
    }
    $outdir = File::Spec->catdir($outdir, 'libiconv-1.17');
    my $config_h_in = File::Spec->catfile($outdir, 'config.h.in');
    my $config_h_in_cmake = File::Spec->catfile($outdir, 'config.h.in.cmake');
    print "Generating $config_h_in_cmake\n";
    open(my $config_h_in_fd, '<', $config_h_in) || die "Cannot open $config_h_in, $!";
    open(my $config_h_in_cmake_fd, '>', $config_h_in_cmake) || die "Cannot open $config_h_in_cmake, $!";
    while (defined(my $line = <$config_h_in_fd>)) {
        foreach my $_need_replacement ('ICONV_CONST') {
            $line =~ s/^\s*#\s*undef[ \t]+${_need_replacement}/#cmakedefine ${_need_replacement} \@${_need_replacement}\@/;
        }
        foreach my $_need_boolean ('HAVE_WCRTOMB', 'HAVE_MBRTOWC', 'ENABLE_EXTRA', 'WORDS_LITTLEENDIAN') {
            $line =~ s/^\s*#\s*undef[ \t]+${_need_boolean}/#cmakedefine01 ${_need_boolean}/;
        }
        $line =~ s/^\s*#\s*undef[ \t]+HAVE_([a-zA-Z0-9_]+)/#cmakedefine01 HAVE_$1/;
        $line =~ s/^\s*#\s*undef/#cmakedefine/;
        #
        # Skip anything with DLL_VARIABLE, ICONV_CONST
        #
        if ($line =~ /DLL_VARIABLE/) {
            next;
        }
        if ($line =~ /ICONV_CONST/) {
            next;
        }
        print $config_h_in_cmake_fd $line;
    }
    #print $config_h_in_cmake_fd "#define DLL_VARIABLE\n";
    #print $config_h_in_cmake_fd "#define ICONV_CONST\n";
    close($config_h_in_cmake_fd) || warn "Cannot close $config_h_in_cmake, $!";
    close($config_h_in_fd) || warn "Cannot close $config_h_in, $!";

    my $config_h = File::Spec->catfile($outdir, 'config.h');
    configure_file($ac, $config_h_in_cmake, $config_h);

    my $iconv_h_in = File::Spec->catfile($outdir, 'include', 'iconv.h.in');
    my $iconv_h_in_cmake = File::Spec->catfile($outdir, 'include', 'iconv.h.in.cmake');
    print "Generating $iconv_h_in_cmake\n";
    open(my $iconv_h_in_fd, '<', $iconv_h_in) || die "Cannot open $iconv_h_in, $!";
    open(my $iconv_h_in_cmake_fd, '>', $iconv_h_in_cmake) || die "Cannot open $iconv_h_in_cmake, $!";
    while (defined(my $line = <$iconv_h_in_fd>)) {
        $line =~ s/#define _LIBICONV_H/#define _LIBICONV_H\n#include <libiconv\/export.h>\n/;
        $line =~ s/^\s*extern[ \t]+([a-zA-Z_])/extern libiconv_EXPORT $1/;
        $line =~ s/LIBICONV_DLL_EXPORTED/libiconv_EXPORT/;
        $line =~ s/\@EILSEQ\@/ENOENT/;
        $line =~ s/\@DLL_VARIABLE\@/libiconv_EXPORT/;
        $line =~ s/\@([^@]+)\@/$1/;
        print $iconv_h_in_cmake_fd $line;
    }
    close($iconv_h_in_cmake_fd) || warn "Cannot close $iconv_h_in_cmake, $!";
    close($iconv_h_in_fd) || warn "Cannot close $iconv_h_in, $!";
    
    my $iconv_h = File::Spec->catfile($outdir, 'include', 'iconv.h');
    configure_file($ac, $iconv_h_in_cmake, $iconv_h);

    my $localcharset_h_in = File::Spec->catfile($outdir, 'libcharset', 'include', 'localcharset.h.in');
    my $localcharset_h = File::Spec->catfile($outdir, 'libcharset', 'include', 'localcharset.h');
    configure_file($ac, $localcharset_h_in, $localcharset_h);

    my @extra_compiler_flags;
    push(@extra_compiler_flags, "-DNO_I18N=1");
    push(@extra_compiler_flags, "-DENABLE_NLS=0");
    push(@extra_compiler_flags, "-DHAVE_WCHAR_T=" . ((exists($sizeof{'WCHAR_T'}) && $sizeof{'WCHAR_T'}) ? 1 : 0));
    push(@extra_compiler_flags, "-DO_BINARY=" . ($have__O_BINARY ? 1 : 0));
    push(@extra_compiler_flags, "-DHAVE_SETLOCALE=1") if (exists($HAVE_HEADERS{'locale.h'}) && $HAVE_HEADERS{'locale.h'});
    push(@extra_compiler_flags, "-DHAVE_DECL_GETC_UNLOCKED=1") if ($have_getc_unlocked);
    push(@extra_compiler_flags, "-DWORDS_LITTLEENDIAN=" . ($is_big_endian ? 0 : 1));
    push(@extra_compiler_flags, "-DENABLE_EXTRA=1");
    push(@extra_compiler_flags, "-DHAVE_WCRTOMB=" . ($have_wcrtomb ? 1 : 0));
    push(@extra_compiler_flags, "-DHAVE_MBRTOWC=" . ($have_mbrtowc ? 1 : 0));
    push(@extra_compiler_flags, "-DUSE_MBSTATE_T=" . (($have_wcrtomb && $have_mbrtowc) ? 1 : 0));
    push(@extra_compiler_flags, "-DBROKEN_WCHAR_H=" . ($broken_wchar ? 1 : 0));
    push(@extra_compiler_flags, "-DICONV_CONST=");
    push(@extra_compiler_flags, "-DDLL_VARIABLE=");

    if ($ENV{CC} =~ /\bcl\b/) {
        #
        # Too much noise with cl
        #
        push(@extra_compiler_flags, '/wd4311');
    }
    #
    # Compile
    #
    my $b = get_cbuilder();
    my @sources = (
        File::Spec->catfile($outdir, 'libcharset', 'lib', 'localcharset.c'),
        File::Spec->catfile($outdir, 'lib', 'relocatable.c'),
        File::Spec->catfile($outdir, 'lib', 'iconv.c'),
        );
    generate_export_h($ac, $outdir, 'libiconv', undef, undef, undef, undef, "#define ICONV_CONST\n");
    foreach my $source (@sources) {
        $b->compile
            (
             source => $source,
             object_file => get_object_file($source),
             include_dirs => [
                 File::Spec->catdir($outdir, 'libcharset', 'include'),
                 File::Spec->catdir($outdir, 'include'),
             ],
             extra_compiler_flags => \@extra_compiler_flags
            );
    }
}

sub process_cchardet {
    my ($ac) = @_;

    my $tar = Archive::Tar->new;
    my $input = File::Spec->catfile($EXTRACT_DIR, 'tconv', '3rdparty', 'tar', 'cchardet-1.0.0.tar.gz');
    $tar->read($input);
    my $outdir = $EXTRACT_DIR; # cchardet-1.0.0 is part of the tar
    print "Extracting $input\n";
    make_path($outdir);
    {
        local $CWD = $outdir;
        $tar->extract();
    }
    $outdir = File::Spec->catdir($outdir, 'cchardet-1.0.0');
    my $nspr_emu_dir = File::Spec->catdir($outdir, 'src', 'ext', 'libcharsetdetect', 'nspr-emu');
    print "Suppress directory $nspr_emu_dir\n";
    remove_tree($nspr_emu_dir, { safe => 1 });
    print "Created directory $nspr_emu_dir\n";
    make_path($nspr_emu_dir);
    my $nsDebug_h = File::Spec->catdir($nspr_emu_dir, 'nsDebug.h');
    print "Creating $nsDebug_h\n";
    open(my $nsDebug_h_fd, '>', $nsDebug_h) || die "Cannot open $nsDebug_h, $!";
    print $nsDebug_h_fd <<NSDEBUG_H;
#ifndef NSDEBUG_H
#define NSDEBUG_H

#endif /* NSDEBUG_H */
NSDEBUG_H
    close($nsDebug_h_fd) || warn "Cannot close $nsDebug_h, $!";
    my $prmem_h = File::Spec->catdir($nspr_emu_dir, 'prmem.h');
    print "Creating $prmem_h\n";
    open(my $prmem_h_fd, '>', $prmem_h) || die "Cannot open $prmem_h, $!";
    print $prmem_h_fd <<PRMEM_H;
#ifndef PRMEM_H
#define PRMEM_H

/* Technically, this is the same as the original prmem.h */

#include "nscore.h"

PR_BEGIN_EXTERN_C
#include <stdlib.h>
PR_END_EXTERN_C

#define PR_Malloc  malloc
#define PR_Calloc  calloc
#define PR_Realloc realloc
#define PR_Free    free

#define PR_MALLOC(_bytes) (PR_Malloc((_bytes)))
#define PR_NEW(_struct) ((_struct *) PR_MALLOC(sizeof(_struct)))
#define PR_REALLOC(_ptr, _size) (PR_Realloc((_ptr), (_size)))
#define PR_CALLOC(_size) (PR_Calloc(1, (_size)))
#define PR_NEWZAP(_struct) ((_struct*)PR_Calloc(1, sizeof(_struct)))
#define PR_DELETE(_ptr) { PR_Free(_ptr); (_ptr) = NULL; }
#define PR_FREEIF(_ptr) if (_ptr) PR_DELETE(_ptr)

#endif /* PRMEM_H */
PRMEM_H
    close($prmem_h_fd) || warn "Cannot close $prmem_h, $!";
    my $nscore_h = File::Spec->catdir($outdir, 'src', 'ext', 'libcharsetdetect', 'nscore.h');
    print "Removing $nscore_h\n";
    unlink($nscore_h);
    configure_file($ac, File::Spec->catfile($EXTRACT_DIR, 'tconv', 'include', 'nscore.h.in'), $nscore_h);
    my @sources = ();
    find({ wanted => sub { push(@sources, $_) if ($_ =~ /\.cpp$/) }, no_chdir => 1 }, File::Spec->catdir($outdir, 'src', 'ext', 'libcharsetdetect', 'mozilla', 'extensions', 'universalchardet', 'src', 'base'));
    push(@sources, File::Spec->catfile($outdir, 'src', 'ext', 'libcharsetdetect', 'charsetdetect.cpp'));
    #
    # Compile
    #
    my $b = get_cbuilder();
    my @include_dirs = (
        File::Spec->catdir($outdir, 'src', 'ext', 'libcharsetdetect', 'mozilla', 'extensions', 'universalchardet', 'src', 'base'),
        File::Spec->catdir($outdir, 'src', 'ext', 'libcharsetdetect', 'nspr-emu'),
        File::Spec->catdir($outdir, 'src', 'ext', 'libcharsetdetect'),
        );
    foreach my $source (@sources) {
        $b->compile
            (
             source => $source,
             object_file => get_object_file($source),
             include_dirs => \@include_dirs,
             'C++' => 1
            );
    }
}

sub process_dlfcn_win32 {
    my ($ac) = @_;

    my $tar = Archive::Tar->new;
    my $input = File::Spec->catfile($EXTRACT_DIR, 'tconv', '3rdparty', 'tar', 'dlfcn-win32-1.4.1.tar.gz');
    $tar->read($input);
    my $outdir = $EXTRACT_DIR; # dlfcn-win32-1.4.1 is part of the tar
    print "Extracting $input\n";
    make_path($outdir);
    {
        local $CWD = $outdir;
        $tar->extract();
    }
    $outdir = File::Spec->catdir($outdir, 'dlfcn-win32-1.4.1');
    my @sources = ();
    push(@sources, File::Spec->catfile($outdir, 'src', 'dlfcn.c'));
    #
    # Compile
    #
    my $b = get_cbuilder();
    my @include_dirs = (
        File::Spec->catdir($outdir, 'src'),
        );
    foreach my $source (@sources) {
        $b->compile
            (
             source => $source,
             object_file => get_object_file($source),
             include_dirs => \@include_dirs
            );
    }
}

sub process_pcre2 {
    my ($ac) = @_;

    my $tar = Archive::Tar->new;
    my $input = File::Spec->catfile($EXTRACT_DIR, 'marpaESLIF', '3rdparty', 'tar', 'pcre2-10.42-patched.tar.gz');
    $tar->read($input);
    my $outdir = $EXTRACT_DIR; # pcre2-10.42 is part of the tar
    print "Extracting $input\n";
    make_path($outdir);
    {
        local $CWD = $outdir;
        $tar->extract();
    }
    $outdir = File::Spec->catfile($outdir, 'pcre2-10.42');
    configure_file
        (
         $ac,
         File::Spec->catfile($outdir, 'config-cmake.h.in'),
         File::Spec->catfile($outdir, 'src', 'config.h')
        );

    my $pcre2_h_in = File::Spec->catfile($outdir, 'src', 'pcre2.h.in');
    my $pcre2_h = File::Spec->catfile($outdir, 'src', 'pcre2.h');
    print "Generating $pcre2_h\n";
    copy($pcre2_h_in, $pcre2_h);
    open(my $fh, '<', $pcre2_h) || die "Cannot open $pcre2_h, $!";
    my $content = do { local $/; <$fh> };
    close($fh) || warn "Cannot close $pcre2_h, $!";
    $content =~ s/\@PCRE2_MAJOR\@/10/g;
    $content =~ s/\@PCRE2_MINOR\@/42/g;
    $content =~ s/\@PCRE2_PRERELEASE\@//g;
    $content =~ s/\@PCRE2_DATE\@/2016-07-29/g;
    open($fh, '>', $pcre2_h) || die "Cannot open $pcre2_h, $!";
    print $fh $content;
    close($fh) || warn "Cannot close $pcre2_h, $!";

    my $b = get_cbuilder();
    my @include_dirs = ( File::Spec->catfile($outdir, 'src') );
    copy(File::Spec->catfile($outdir, 'src', 'pcre2_chartables.c.dist'), File::Spec->catfile($outdir, 'src', 'pcre2_chartables.c'));
    my @sources =
        (
         File::Spec->catfile($outdir, 'src', 'pcre2_auto_possess.c'),
         File::Spec->catfile($outdir, 'src', 'pcre2_compile.c'),
         File::Spec->catfile($outdir, 'src', 'pcre2_config.c'),
         File::Spec->catfile($outdir, 'src', 'pcre2_context.c'),
         File::Spec->catfile($outdir, 'src', 'pcre2_convert.c'),
         File::Spec->catfile($outdir, 'src', 'pcre2_dfa_match.c'),
         File::Spec->catfile($outdir, 'src', 'pcre2_error.c'),
         File::Spec->catfile($outdir, 'src', 'pcre2_extuni.c'),
         File::Spec->catfile($outdir, 'src', 'pcre2_find_bracket.c'),
         File::Spec->catfile($outdir, 'src', 'pcre2_jit_compile.c'),
         File::Spec->catfile($outdir, 'src', 'pcre2_maketables.c'),
         File::Spec->catfile($outdir, 'src', 'pcre2_match.c'),
         File::Spec->catfile($outdir, 'src', 'pcre2_match_data.c'),
         File::Spec->catfile($outdir, 'src', 'pcre2_newline.c'),
         File::Spec->catfile($outdir, 'src', 'pcre2_ord2utf.c'),
         File::Spec->catfile($outdir, 'src', 'pcre2_pattern_info.c'),
         File::Spec->catfile($outdir, 'src', 'pcre2_script_run.c'),
         File::Spec->catfile($outdir, 'src', 'pcre2_serialize.c'),
         File::Spec->catfile($outdir, 'src', 'pcre2_string_utils.c'),
         File::Spec->catfile($outdir, 'src', 'pcre2_study.c'),
         File::Spec->catfile($outdir, 'src', 'pcre2_substitute.c'),
         File::Spec->catfile($outdir, 'src', 'pcre2_substring.c'),
         File::Spec->catfile($outdir, 'src', 'pcre2_tables.c'),
         File::Spec->catfile($outdir, 'src', 'pcre2_ucd.c'),
         File::Spec->catfile($outdir, 'src', 'pcre2_valid_utf.c'),
         File::Spec->catfile($outdir, 'src', 'pcre2_xclass.c'),
         File::Spec->catfile($outdir, 'src', 'pcre2_chartables.c')
        );
    my @extra_compiler_flags = ();
    push(@extra_compiler_flags, "-DDHAVE_CONFIG_H=1");
    push(@extra_compiler_flags, "-DPCRE2_CODE_UNIT_WIDTH=8");
    push(@extra_compiler_flags, "-DPCRE2_STATIC=1");
    if ($JIT) {
	push(@extra_compiler_flags, "-DSUPPORT_JIT=1");
    }
    push(@extra_compiler_flags, "-DDHAVE_CONFIG_H=1");
    #
    # SUPPORT_UNICODE and EBCDIC are not compatible
    #
    if ($Config{ebcdic}) {
        push(@extra_compiler_flags, '-DEBCDIC=1');
    } else {
        push(@extra_compiler_flags, '-DSUPPORT_UNICODE=1');
    }
    push(@extra_compiler_flags, '-DLINK_SIZE=2');
    push(@extra_compiler_flags, '-DMATCH_LIMIT=10000000');
    push(@extra_compiler_flags, '-DMATCH_LIMIT_DEPTH=10000000');
    push(@extra_compiler_flags, '-DMATCH_LIMIT_RECURSION=10000000');
    push(@extra_compiler_flags, '-DHEAP_LIMIT=20000000');
    push(@extra_compiler_flags, '-DNEWLINE_DEFAULT=2');
    push(@extra_compiler_flags, '-DPARENS_NEST_LIMIT=250');
    push(@extra_compiler_flags, '-DPCRE2GREP_BUFSIZE=20480');
    push(@extra_compiler_flags, '-DMAX_NAME_SIZE=32');
    push(@extra_compiler_flags, '-DMAX_NAME_COUNT=10000');
    foreach my $source (@sources) {
        $b->compile
            (
             source => $source,
             object_file => get_object_file($source),
             include_dirs => \@include_dirs,
             extra_compiler_flags => \@extra_compiler_flags
            );
    }
}

sub process_luaunpanic {
    my ($ac) = @_;

    my $tar = Archive::Tar->new;
    my $input = File::Spec->catfile($TARBALLS_DIR, 'luaunpanic-src.tar.gz');
    $tar->read($input);
    my $outdir = File::Spec->catdir($EXTRACT_DIR, 'luaunpanic');
    print "Extracting $input\n";
    make_path($outdir);
    {
        local $CWD = $outdir;
        $tar->extract();
    }
    my $luaconf_h_in = File::Spec->catfile($outdir, 'include', 'luaunpanic','internal', 'luaconf.h.in');
    my $luaconf_h = File::Spec->catfile($outdir, 'include', 'luaunpanic','lua', 'luaconf.h');
    configure_file($ac, $luaconf_h_in, $luaconf_h);
    my ($project, $version, $major, $minor, $patch) = get_project_and_version($ac, $outdir);
    generate_export_h($ac, $outdir, $project);
}

sub process_marpaESLIFLua {
    my ($ac) = @_;

    my $tar = Archive::Tar->new;
    my $input = File::Spec->catfile($TARBALLS_DIR, 'marpaesliflua-src.tar.gz');
    $tar->read($input);
    my $outdir = File::Spec->catdir($EXTRACT_DIR, 'marpaESLIFLua');
    print "Extracting $input\n";
    make_path($outdir);
    {
        local $CWD = $outdir;
        $tar->extract();
    }
}

sub get_project_and_version {
    my ($ac, $dir) = @_;

    my ($project, $version, $major, $minor, $patch);

    my $CMakeLists = File::Spec->catfile($dir, 'CMakeLists.txt');
    if (-r $CMakeLists) {
        open(my $fh, '<', $CMakeLists) || die "Cannot open $CMakeLists, $!";
        while (defined(my $line = <$fh>)) {
            if ($line =~ /^\s*project\s*\(\s*(\w+).+VERSION\s*(\d+)\.(\d+)\.(\d+)/) {
                ($project, $version, $major, $minor, $patch) = ($1, "$2.$3.$4", $2, $3, $4);
                my $PROJECT = uc($project);
                print "... Project $project, version $version\n";
                last;
            }
        }
        close($fh) || warn "Cannot close $CMakeLists, $!";
    }

    return ($project, $version, $major, $minor, $patch);
}

sub generate_export_h {
    my ($ac, $dir, $project, $version, $major, $minor, $patch, $extra_defines) = @_;

    my $export = File::Spec->catfile($dir, 'include', $project, 'export.h');
    make_path(dirname($export));
    print "Generating $export\n";
    my $PROJECT = uc($project);
    #
    # There is a problem with quoting version, so we put that in export.h whenever possible
    #
    my $DEFINE_VERSION = (defined($version)) ? "#define ${PROJECT}_VERSION \"$version\"" : "";
    my $DEFINE_MAJOR = (defined($major)) ? "#define ${PROJECT}_VERSION_MAJOR $major" : "";
    my $DEFINE_MINOR = (defined($minor)) ? "#define ${PROJECT}_VERSION_MINOR $minor" : "";
    my $DEFINE_PATCH = (defined($patch)) ? "#define ${PROJECT}_VERSION_PATCH $patch" : "";
    $extra_defines //= '';
    open(my $fh, '>', $export) || die "Cannot open $export, $!";
    print $fh <<EXPORT;
#ifndef ${project}_EXPORT_H
#define ${project}_EXPORT_H

${DEFINE_MAJOR}
${DEFINE_MINOR}
${DEFINE_PATCH}
${DEFINE_VERSION}
${extra_defines}
/* We enforce static mode */
#define ${project}_EXPORT
#define ${PROJECT}_NO_EXPORT

#endif /* ${project}_EXPORT_H */
EXPORT
    close($fh) || "Cannot close $export, $!";
}

sub check_big_endian {
    my ($ac) = @_;

    my $rc;
    $ac->msg_checking('big endianness');
    my $prologue = <<PROLOGUE;
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif
#ifdef HAVE_STDIO_H
#include <stdio.h>
#endif

const int i = 1;
#define is_bigendian() ( (*(char*)&i) == 0 )
PROLOGUE
    my $body = <<BODY;
  fprintf(stdout, "%d", is_bigendian() ? 1 : 0);
  exit(0);
BODY
    my $program = $ac->lang_build_program($prologue, $body);
    #
    # We do not accept any compile, link or run error
    #
    my $is_bigendian;
    try_output($program, \$is_bigendian, { compile_error_is_fatal => 1, link_error_is_fatal => 1, run_error_is_fatal => 1 });
    if ($is_bigendian) {
        $ac->define_var("WORDS_BIGENDIAN", 1);
        $ac->msg_result("yes");
        $rc = 1;
    } else {
        $ac->msg_result("no");
        $rc = 0;
    }
}

#
# A specialized ExtUtils::CBuilder new wrapper, that gets optimize flag but do not propagate it to the caller via CFLAGS.txt
#
sub get_cbuilder {
    my %EXTUTILS_BUILDER_CONFIG = ();
    if ($optimize) {
        $EXTUTILS_BUILDER_CONFIG{optimize} = $optimize;
    }

    return ExtUtils::CBuilder->new(config => \%EXTUTILS_BUILDER_CONFIG);
}
