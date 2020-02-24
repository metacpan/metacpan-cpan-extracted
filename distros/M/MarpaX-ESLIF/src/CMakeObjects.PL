#!env perl
use strict;
use diagnostics;
use Config;
use Config::AutoConf;
use Config::AutoConf::INI;
use ExtUtils::CBuilder;
use File::chdir;
use File::Basename qw/basename dirname/;
use File::Find qw/find/;
use File::Path qw/make_path/;
use File::Copy qw/copy/;
use File::Copy::Recursive qw/dircopy/;
use File::Temp qw/tempfile/;
use IPC::Run qw/run/;
use Perl::OSType qw/is_os_type/;
use POSIX qw/EXIT_SUCCESS strftime/;
use Try::Tiny;

#
# Move to current dir of this script
#
my $okupdir = dirname($0);
chdir($okupdir) || die "Cannot move to $okupdir, $!";

print "Working directory set to $okupdir\n";

my $isc99 = 0;
my %cbuilder_config = ExtUtils::CBuilder->new()->get_config;
if (($cbuilder_config{cc} // 'cc') ne 'cl') {
    print "Checking if C99 is enabled by default: ";
    if (try_compile("#if !defined(__STDC_VERSION__) || __STDC_VERSION__ < 199901L\n#error \"C99 is not enabled\"\n#endif\nint main(){return 0;}")) {
        print "yes\n";
        $isc99 = 1;
    } else {
        print "no\n";
        print "Checking what CFLAGS is required for C99:\n";
        foreach my $flag (qw/-std=gnu99 -std=c99 -c99 -AC99 -xc99=all -qlanglvl=extc99/) {
            print "Checking if flag $flag works: ";
            if (try_compile("#if !defined(__STDC_VERSION__) || __STDC_VERSION__ < 199901L\n#error \"C99 is not enabled\"\n#endif\nint main(){return 0;}", $flag)) {
                print "yes\n";
                $ENV{CFLAGS} .= " $flag";
                $isc99 = 1;
                last;
            } else {
                print "no\n";
            }
        }
    }
}

if ($^O eq "netbsd" && ! $isc99) {
    #
    # We need long long, that C99 guarantees, else _NETBSD_SOURCE will do it
    #
    print "NetBSD platform and no c99: Append _NETBSD_SOURCE to CFLAGS to have long long\n";
    $ENV{CFLAGS} .= " -D_NETBSD_SOURCE";
}

make_path(File::Spec->catdir('output', '3rdparty'));

# ------------------------------------------------------------
# Generation of objects using perl setup, for use in perl's XS
# ------------------------------------------------------------
my ($MARPAESLIF_VERSION, $MARPAESLIF_VERSION_MAJOR, $MARPAESLIF_VERSION_MINOR, $MARPAESLIF_VERSION_PATCH) = get_version();
print "Generating config for marpaESLIF version $MARPAESLIF_VERSION (major=$MARPAESLIF_VERSION_MAJOR, minor=$MARPAESLIF_VERSION_MINOR, patch=$MARPAESLIF_VERSION_PATCH)\n";

# ------------------------
# Write configuration file
# ------------------------
my $config_h_in = File::Spec->catfile('include', 'config.h.in');
my $config_h    = File::Spec->catfile('include', 'marpaESLIF', 'internal', 'config.h');
make_path(dirname($config_h));

{
    my $ac = Config::AutoConf::INI->new(logfile => 'config.log');
    foreach (['double', ''], ['long double', 'L'], ['float', 'F']) {
        my ($variable_type, $extension) = @{$_};
        $ac->msg_checking("for working HUGE_VAL${extension}");
        if (get_math_constant($variable_type, "HUGE_VAL${extension}")) {
            $ac->msg_result('yes');
            $ac->define_var("C_HAVE_HUGE_VAL${extension}", 1);
        } else {
            $ac->msg_result('no');
            $ac->msg_checking("for HUGE_VAL${extension} replacement");
            if (get_math_constant($variable_type, "HUGE_VAL${extension}", '__builtin_huge_val' . lc($extension) . '()')) {
                $ac->msg_result('yes');
                $ac->define_var("C_HAVE_HUGE_VAL${extension}_REPLACEMENT", 1);
            } else {
                $ac->msg_result('no');
            }
        }
    }

    $ac->msg_checking("for working INFINITY");
    if (get_math_constant('float', "INFINITY")) {
        $ac->msg_result('yes');
        $ac->define_var("C_HAVE_INFINITY", 1);
    } else {
        $ac->msg_result('no');
        $ac->msg_checking("for INFINITY replacement");
        if (get_math_constant('float', "INFINITY", '__builtin_inff()')) {
            $ac->msg_result('yes');
            $ac->define_var("C_HAVE_INFINITY_REPLACEMENT", 1);
        } else {
            $ac->msg_result('no');
            $ac->msg_checking("for INFINITY replacement using division");
            if (get_math_constant('float', "INFINITY", '1.0 / 0.0')) {
                $ac->msg_result('yes');
                $ac->define_var("C_HAVE_INFINITY_REPLACEMENT_USING_DIVISION", 1);
            } else {
                $ac->msg_result('no');
            }
        }
    }

    $ac->msg_checking("for working isinf()");
    if (get_math_function('short', 'isinf', '(0.0)')) {
        $ac->msg_result('yes');
        $ac->define_var("C_HAVE_ISINF", 1);
    } else {
        $ac->msg_result('no');
        $ac->msg_checking("for isinf replacement");
        if (get_math_function('short', 'isinf', '(0.0)', '__builtin_isinf')) {
            $ac->msg_result('yes');
            $ac->define_var("C_HAVE_ISINF_REPLACEMENT", 1);
        } else {
            $ac->msg_result('no');
        }
    }

    $ac->msg_checking("for working NAN");
    if (get_math_constant('float', "NAN")) {
        $ac->msg_result('yes');
        $ac->define_var("C_HAVE_NAN", 1);
    } else {
        $ac->msg_result('no');
        $ac->msg_checking("for NAN replacement");
        if (get_math_constant('float', "NAN", '__builtin_nanf("")')) {
            $ac->msg_result('yes');
            $ac->define_var("C_HAVE_NAN_REPLACEMENT", 1);
        } else {
            $ac->msg_result('no');
            $ac->msg_checking("for NAN replacement using division");
            if (get_math_constant('float', "NAN", '0.0 / 0.0')) {
                $ac->msg_result('yes');
                $ac->define_var("C_HAVE_NAN_REPLACEMENT_USING_DIVISION", 1);
            } else {
                $ac->msg_result('no');
            }
        }
    }

    $ac->msg_checking("for isnan()");
    if (get_math_function('short', 'isnan', '(0.0)')) {
        $ac->msg_result('yes');
        $ac->define_var("C_HAVE_ISNAN", 1);
    } else {
        $ac->msg_result('no');
        $ac->msg_checking("for isnan replacement");
        if (get_math_function('short', 'isnan', '(0.0)', '__builtin_isnan')) {
            $ac->msg_result('yes');
            $ac->define_var("C_HAVE_ISNAN_REPLACEMENT", 1);
        } else {
            $ac->msg_result('no');
        }
    }

    $ac->check;
    write_config($MARPAESLIF_VERSION, $MARPAESLIF_VERSION_MAJOR, $MARPAESLIF_VERSION_MINOR, $MARPAESLIF_VERSION_PATCH, $config_h_in, $config_h);
}
# -------------
# Fake export.h
# -------------
my $export_h = File::Spec->catfile('output', 'include', 'marpaESLIF', 'export.h');
make_path(dirname($export_h));
open(my $fh, '>', $export_h) || die "Cannot open $export_h, $!";
print $fh "#define marpaESLIF_EXPORT\n";
print $fh "#define MARPAESLIF_NO_EXPORT\n";
close($fh) || warn "Cannot close $export_h, $!";

my @additional_includes = ();
my @additional_srcdir = ();

# ------------------------
# We provide ourself PCRE2
# ------------------------
{
    local $CWD = File::Spec->catdir('3rdparty', 'untar', 'pcre2-10.23');
    print "... Compiling pcre2\n";
    my $fh;
    open($fh, '>', 'config_autoconf.ini') || die "Cannot open config_autoconf.ini, $!";

    print $fh <<AUTOCONF;
[headers]
dirent.h = 1
stdint.h = 1
inttypes.h = 1
sys/stat.h = 1
sys/types.h = 1
unistd.h = 1
windows.h = 1

[funcs]
bcopy = 1
memmove = 1
strerror = 1

[outputs]
config.h = 1
AUTOCONF
    close($fh) || warn "Cannot close config_autoconf.ini, $!";
    my $ac = Config::AutoConf::INI->new(logfile => 'config.log');
    $ac->define_var('SUPPORT_PCRE2_8', 1);
    #
    # SUPPORT_UNICODE and EBCDIC are not compatible
    #
    if ($Config{ebcdic}) {
        $ac->define_var('EBCDIC', 1);
    } else {
        $ac->define_var('SUPPORT_UNICODE', 1);
    }
    $ac->define_var('LINK_SIZE', 2);
    $ac->define_var('MATCH_LIMIT', 10000000);
    $ac->define_var('MATCH_LIMIT_RECURSION', 10000000);
    $ac->define_var('NEWLINE_DEFAULT', 2,'LF');
    $ac->define_var('PARENS_NEST_LIMIT', 250);
    $ac->define_var('PCRE2GREP_BUFSIZE', 20480);
    $ac->define_var('MAX_NAME_SIZE', 32);
    $ac->define_var('MAX_NAME_COUNT', 10000);
    $ac->check();

    copy(File::Spec->catfile('src', 'pcre2.h.in'), 'pcre2.h');
    open($fh, '<', 'pcre2.h') || die "Cannot open pcre2.h, $!";
    my $content = do { local $/; <$fh> };
    close($fh) || warn "Cannot close pcre2.h, $!";
    $content =~ s/\@PCRE2_MAJOR\@/10/g;
    $content =~ s/\@PCRE2_MINOR\@/22/g;
    $content =~ s/\@PCRE2_PRERELEASE\@//g;
    $content =~ s/\@PCRE2_DATE\@/2016-07-29/g;
    open($fh, '>', 'pcre2.h') || die "Cannot open pcre2.h, $!";
    print $fh $content;
    close($fh) || warn "Cannot close pcre2.h, $!";

    copy(File::Spec->catfile('src', 'pcre2_chartables.c.dist'), File::Spec->catfile(File::Spec->curdir, 'pcre2_chartables.c'));
    my @pcre2_src = map { File::Spec->catfile('src', $_) } qw/pcre2_auto_possess.c
  pcre2_compile.c
  pcre2_config.c
  pcre2_context.c
  pcre2_dfa_match.c
  pcre2_error.c
  pcre2_find_bracket.c
  pcre2_jit_compile.c
  pcre2_maketables.c
  pcre2_match.c
  pcre2_match_data.c
  pcre2_newline.c
  pcre2_ord2utf.c
  pcre2_pattern_info.c
  pcre2_serialize.c
  pcre2_string_utils.c
  pcre2_study.c
  pcre2_substitute.c
  pcre2_substring.c
  pcre2_tables.c
  pcre2_ucd.c
  pcre2_valid_utf.c
  pcre2_xclass.c/;
  push(@pcre2_src, File::Spec->catfile(File::Spec->curdir, 'pcre2_chartables.c'));
  my $cbuilder = ExtUtils::CBuilder->new();
  my @objects;
  my $obj_dir = File::Spec->catfile('output', 'obj4perl');
  make_path($obj_dir);
  foreach my $source (@pcre2_src) {
    my $obj = basename($cbuilder->object_file($source));
    $obj = File::Spec->catfile($obj_dir, basename($cbuilder->object_file($source)));
    $cbuilder->compile(
	source        => $source,
	object_file   => $obj,
        extra_compiler_flags => "-DHAVE_CONFIG_H -DPCRE2_CODE_UNIT_WIDTH=8 -DPCRE2_STATIC -DSUPPORT_JIT=1",
	include_dirs  => [ File::Spec->curdir, 'src' ]
	);
  }
}
push(@additional_includes, File::Spec->catdir('3rdparty', 'untar', 'pcre2-10.23'));

# -------------------------------------------
# marpaESLIF embeds my unpanic version of lua
# -------------------------------------------
push(@additional_includes, File::Spec->catdir('3rdparty', 'github', 'luaunpanic', 'include', 'luaunpanic', 'lua'));
push(@additional_includes, File::Spec->catdir('output', '3rdparty', 'luaunpanic', 'output', 'include', 'luaunpanic', 'lua')); # for luaconf.h

# ------------------------------
# marpaESLIF embeds lua bindings
# ------------------------------
push(@additional_includes, File::Spec->catdir('src', 'bindings', 'lua', 'include'));

# ----------------------------------------------------------------
# We depend on these* stuff that can manage themselves, eventually
# ----------------------------------------------------------------
foreach (qw/genericLogger genericStack genericHash marpaWrapper tconv luaunpanic/) {
    print "... Copying $_\n";
    if (! dircopy(File::Spec->catdir('3rdparty', 'github', $_),
                  File::Spec->catdir('output', '3rdparty', $_))) {
        die "Failed to copy $_";
    }
    my $CMakeObjects = File::Spec->catfile('output', '3rdparty', $_, 'CMakeObjects.PL');
    if (-e $CMakeObjects) {
        print "... Executing $CMakeObjects\n";
        my $in;
        my $out;
        my $err;
        {
            local $CWD = dirname($CMakeObjects);
            run([$^X, basename($CMakeObjects)], \$in, \$out, \$err) || die "Failed to execute $CMakeObjects" . ($err ? "\n$err" : '');
        }
        if ($out) {
            foreach (grep {defined} split(/\R/, $out)) {
                print "... ... $_\n";
            }
        }
        my $inc = File::Spec->catdir('output', '3rdparty', $_, 'output', 'include');
        push(@additional_includes, $inc) if (-d $inc);
    }
    my $inc = File::Spec->catdir('output', '3rdparty', $_, 'include');
    push(@additional_includes, $inc) if (-d $inc);
}

# ----------------
# Get source files
# ----------------
my @sources = File::Spec->catfile('src', 'marpaESLIF.c');

# ----------------------------------------------------------------------------------------
# Generate objects
# Our embedded lua requires some public C flags that we cannot invent
# ----------------------------------------------------------------------------------------
my $cbuilder = ExtUtils::CBuilder->new();
my $obj_dir = File::Spec->catfile('output', 'obj4perl');
make_path($obj_dir);
foreach my $source (@sources) {
    my $is_cplusplus = ($source =~ /\.cpp$/i || $source =~ /\.c\+\+$/i);
    my $obj = basename($cbuilder->object_file($source));
    $obj = File::Spec->catfile($obj_dir, basename($cbuilder->object_file($source)));
    $cbuilder->compile(
	source        => $source,
	object_file   => $obj,
        extra_compiler_flags => "-DPCRE2_CODE_UNIT_WIDTH=8 -DPCRE2_STATIC -DMARPAESLIF_BUFSIZ=1048576 -DMARPAESLIF_NTRACE=1 -DMARPAESLIFLUA_EMBEDDED", #  -DLUA_32BITS -DLUA_USE_C89
	include_dirs  => [ 'include', File::Spec->catdir('output', 'include'), @additional_includes ],
	'C++'         => $is_cplusplus
	);
}

# ----
# Done
# ----
exit(EXIT_SUCCESS);

sub get_version {
    my ($major, $minor, $patch);
    open(my $fh, '<', 'CMakeLists.txt') || die "Cannot open CMakeLists.txt, $!";
    my $content = do { local $/; <$fh>; };
    close($fh) || warn "Failed to close CMakeLists.txt, $!";

    my @rc;
    if ($content =~ /^MYPACKAGESTART\s*\(\s*marpaESLIF\s+(\d+)\s+(\d+)\s+(\d+)\s*\)/sm) {
        @rc = ($major = $1, $minor = $2, $patch = $3);
    } else {
        foreach (qw/MARPAESLIF_VERSION_MAJOR MARPAESLIF_VERSION_MINOR MARPAESLIF_VERSION_PATCH/) {
            if ($content =~ /^SET\s*\(\s*$_\s*(\d+)\s*\)/sm) {
                push(@rc, $1);
                if ($_ eq 'MARPAESLIF_VERSION_MAJOR') {
                    $major = $1;
                } elsif ($_ eq 'MARPAESLIF_VERSION_MINOR') {
                    $minor = $1;
                } elsif ($_ eq 'MARPAESLIF_VERSION_PATCH') {
                    $patch = $1;
                }
            } else {
                die "Failed to find $_",
            }
        }
    }

    return (join('.', @rc), $major, $minor, $patch)
}

sub write_config {
    my ($version, $major, $minor, $patch, $input, $output) = @_;

    make_path(dirname($output));
    open(my $fh, '<', $input) || die "Cannot open $input, $!";
    my $source = do { local $/; <$fh>; };
    close($fh) || warn "Cannot close $input, $!";

    $source =~ s/^[ \t]*#[ \t]*cmakedefine[ \t]+(\w+)+[ \t]+\@([^ \t@]*)\@//smg;
    $source =~ s/^[ \t]*typedef.*$//mg;

    open($fh, '>', $output) || die "Cannot open $output, $!";
    print $fh <<CONFIG;
#ifndef MARPAESLIF_CONFIG_WRAPPER_H
#define MARPAESLIF_CONFIG_WRAPPER_H

#include <marpaESLIF/config_autoconf.h>

#define MARPAESLIF_VERSION "$version"
#define MARPAESLIF_VERSION_MAJOR $major
#define MARPAESLIF_VERSION_MINOR $minor
#define MARPAESLIF_VERSION_PATCH $patch
   
#define MARPAESLIFLUA_VERSION MARPAESLIF_VERSION
#define MARPAESLIFLUA_VERSION_MAJOR MARPAESLIF_VERSION_MAJOR
#define MARPAESLIFLUA_VERSION_MINOR MARPAESLIF_VERSION_MINOR
#define MARPAESLIFLUA_VERSION_PATCH MARPAESLIF_VERSION_PATCH
   
$source

#if defined(SIZEOF_UINT32_T) && (SIZEOF_UINT32_T == 4)
typedef uint32_t marpaESLIF_uint32_t;
#else
#  if defined(SIZEOF__UINT32_T) && (SIZEOF__UINT32_T == 4)
typedef _uint32_t marpaESLIF_uint32_t;
#  else
#    if defined(SIZEOF___UINT32_T) && (SIZEOF___UINT32_T == 4)
typedef __uint32_t marpaESLIF_uint32_t;
#      if defined(SIZEOF_UNSIGNED_LONG) && (SIZEOF_UNSIGNED_LONG == 4)
typedef unsigned long marpaESLIF_uint32_t;
#      else
#        if defined(SIZEOF_UNSIGNED_INT) && (SIZEOF_UNSIGNED_INT == 4)
typedef unsigned int marpaESLIF_uint32_t;
#        else
#          error "Cannot determine marpaESLIF_uint32_t"
#        endif
#      endif
#    endif
#  endif
#endif

#ifdef C_HAVE_HUGE_VAL_REPLACEMENT
# define C_HUGE_VAL_REPLACEMENT
#endif
#ifdef C_HAVE_HUGE_VAL
# define C_HUGE_VAL HUGE_VAL
#endif

#ifdef C_HAVE_HUGE_VALF_REPLACEMENT
# define C_HUGE_VALF_REPLACEMENT
#endif
#ifdef C_HAVE_HUGE_VALF
# define C_HUGE_VALF HUGE_VALF
#endif

#ifdef C_HAVE_HUGE_VALL_REPLACEMENT
# define C_HUGE_VALL_REPLACEMENT
#endif
#ifdef C_HAVE_HUGE_VALL
# define C_HUGE_VALL HUGE_VALL
#endif

#ifdef C_HAVE_INFINITY_REPLACEMENT_USING_DIVISION
#define C_INFINITY_REPLACEMENT_USING_DIVISION
#endif
#ifdef C_HAVE_INFINITY_REPLACEMENT
# define C_INFINITY_REPLACEMENT
#endif
#ifdef C_HAVE_INFINITY
# define C_INFINITY INFINITY
#endif

#ifdef C_HAVE_NAN_REPLACEMENT_USING_DIVISION
#define C_NAN_REPLACEMENT_USING_DIVISION
#endif
#ifdef C_HAVE_NAN_REPLACEMENT
# define C_NAN_REPLACEMENT
#endif
#ifdef C_HAVE_NAN
# define C_NAN NAN
#endif

#ifdef C_HAVE_NAN_REPLACEMENT
# define C_NAN_REPLACEMENT
#endif
#ifdef C_HAVE_NAN
# define C_NAN NAN
#endif

#ifdef C_HAVE_ISINF_REPLACEMENT
#  define C_ISINF_REPLACEMENT
#endif
#ifdef C_HAVE_ISINF
#  define C_ISINF isinf
#endif

#ifdef C_HAVE_ISNAN_REPLACEMENT
#  define C_ISNAN_REPLACEMENT
#endif
#ifdef C_HAVE_ISNAN
#  define C_ISNAN isnan
#endif

#ifdef HAVE_FPCLASSIFY
#  define C_FPCLASSIFY fpclassify
#else
#  ifdef HAVE__FPCLASSIFY
#    define C_FPCLASSIFY _fpclassify
#  else
#    ifdef HAVE___FPCLASSIFY
#      define C_FPCLASSIFY __fpclassify
#    else
#      ifdef HAVE_FPCLASS
#        define C_FPCLASSIFY fpclass
#      else
#        ifdef HAVE__FPCLASS
#          define C_FPCLASSIFY _fpclass
#        else
#          ifdef HAVE___FPCLASS
#            define C_FPCLASSIFY __fpclass
#          else
#          endif
#        endif
#      endif
#    endif
#  endif
#endif
#ifdef HAVE_FP_NAN
#  define C_FP_NAN FP_NAN
#endif
#ifdef HAVE__FPCLASS_SNAN
#  define C__FPCLASS_SNAN _FPCLASS_SNAN
#endif
#ifdef HAVE__FPCLASS_QNAN
#  define C__FPCLASS_QNAN _FPCLASS_QNAN
#endif
#ifdef HAVE_FP_INFINITE
#  define C_FP_INFINITE FP_INFINITE
#endif
#ifdef HAVE__FPCLASS_NINF
#  define C__FPCLASS_NINF _FPCLASS_NINF
#endif
#ifdef HAVE__FPCLASS_PINF
#  define C__FPCLASS_PINF _FPCLASS_PINF
#endif

#ifdef HAVE_STRTOLD
#  define C_STRTOLD strtold
#else
#  ifdef HAVE__STRTOLD
#    define C_STRTOLD _strtold
#  else
#    ifdef HAVE___STRTOLD
#      define C_STRTOLD __strtold
#    endif
#  endif
#endif

#ifdef HAVE_STRTOD
#  define C_STRTOD strtod
#else
#  ifdef HAVE__STRTOD
#    define C_STRTOD _strtod
#  else
#    ifdef HAVE___STRTOD
#      define C_STRTOD __strtod
#    endif
#  endif
#endif

#ifdef HAVE_STRTOF
#  define C_STRTOF strtof
#else
#  ifdef HAVE__STRTOF
#    define C_STRTOF _strtof
#  else
#    ifdef HAVE___STRTOF
#      define C_STRTOF __strtof
#    endif
#  endif
#endif

#endif /* MARPAESLIF_CONFIG_WRAPPER_H */
CONFIG
    close($fh) || warn "Cannot close $output, $!";
}

sub try_compile {
    my ($csource, $extra_compiler_flags) = @_;

    my $fh = File::Temp->new(UNLINK => 0, SUFFIX => '.c');
    print $fh "$csource\n";
    close($fh);
    my $source = $fh->filename;
    my $rc = 0;

    try {
        my $cbuilder = ExtUtils::CBuilder->new(quiet => 1);
        my $obj = basename($cbuilder->object_file($source));
        $cbuilder->compile(
            source               => $source,
            object_file          => $obj,
            extra_compiler_flags => $extra_compiler_flags
            );
        $rc = 1;
    };
    unlink $fh->filename;

    return $rc;
}

sub get_math_constant {
    my ($variable_type, $constant, $constant_replacement_value) = @_;

    my $CONSTANT = uc($constant);
    $constant = lc($constant);
    my $extra_compiler_flags = " -DC_${CONSTANT}=${CONSTANT}";
    if (defined($constant_replacement_value)) {
        $extra_compiler_flags   .= " -DHAVE_${CONSTANT}_REPLACEMENT";
    } else {
        $constant_replacement_value = 'UNDEFINED';
    }

    my $source .= "
#include <math.h>
#ifdef HAVE_${CONSTANT}_REPLACEMENT
#  undef ${CONSTANT}
#  define ${CONSTANT} ($constant_replacement_value)
#endif
int main() {
  ${variable_type} x = C_${CONSTANT};
  return 0;
}
";
    my $rc =  eval {
        my $cbuilder = ExtUtils::CBuilder->new(quiet => 1);
        my ($fh, $filename) = tempfile(SUFFIX => '.c', UNLINK => 0);
        print $fh $source;
        close($fh) || warn "Cannot close $filename, $!";

        my $obj = $cbuilder->object_file($filename);
        $cbuilder->compile(
            source        => $filename,
            extra_compiler_flags => $extra_compiler_flags,
            object_file   => $obj,
            'C++'         => 0
            );
        $cbuilder->link_executable(
            module_name => 'ICONV::TEST',
            objects => $obj
            );
        system($cbuilder->exe_file($obj), 'unused', 'parameter');
        my $exitcode =  $? >> 8;
        unlink $cbuilder->exe_file($obj);
        unlink $obj;
        unlink $filename;
        $exitcode ? 0 : 1;
    } // 0;

    print $@ if $@;

    return $rc;
}

sub get_math_function {
    my ($variable_type, $function, $function_parameters, $replacement) = @_;

    $replacement //= '';
    my $FUNCTION = uc($function);
    my $extra_compiler_flags = $replacement ? " -DHAVE_${FUNCTION}_REPLACEMENT=1" : " -DC_${FUNCTION}=${function}";

    my $source .= "
#include <math.h>
#ifdef HAVE_${FUNCTION}_REPLACEMENT
#  undef C_${FUNCTION}
#  define C_${FUNCTION}(x) (${replacement}(x))
#endif
int main() {
  ${variable_type} x = C_${FUNCTION}${function_parameters};
  return 0;
}
";
    my $rc =  eval {
        my $cbuilder = ExtUtils::CBuilder->new(quiet => 1);
        my ($fh, $filename) = tempfile(SUFFIX => '.c', UNLINK => 0);
        print $fh $source;
        close($fh) || warn "Cannot close $filename, $!";

        my $obj = $cbuilder->object_file($filename);
        $cbuilder->compile(
            source        => $filename,
            extra_compiler_flags => $extra_compiler_flags,
            object_file   => $obj,
            'C++'         => 0
            );
        $cbuilder->link_executable(
            module_name => 'ICONV::TEST',
            objects => $obj
            );
        system($cbuilder->exe_file($obj), 'unused', 'parameter');
        my $exitcode =  $? >> 8;
        unlink $cbuilder->exe_file($obj);
        unlink $obj;
        unlink $filename;
        $exitcode ? 0 : 1;
    } // 0;

    print $@ if $@;

    return $rc;
}
