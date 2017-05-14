#!env perl
use strict;
use diagnostics;
use Archive::Tar;
use Config::AutoConf::INI;
use ExtUtils::CBuilder;
use File::chdir;
use File::Basename qw/basename dirname/;
use File::Find qw/find/;
use File::Path qw/make_path remove_tree/;
use File::Copy qw/copy/;
use File::Copy::Recursive qw/dircopy/;
use File::Temp qw/tempfile/;
use IPC::Run qw/run/;
use Perl::OSType qw/is_os_type/;
use POSIX qw/EXIT_SUCCESS/;
use IO::Handle;

autoflush STDOUT 1;

our $DATA = do { local $/; <DATA>; };

# ------------------------------------------------------------
# Generation of objects using perl setup, for use in perl's XS
# ------------------------------------------------------------
my $version = get_version();
print "Generating config for tconv version $version\n";

# ------------------------
# Write configuration file
# ------------------------
my $config_h_in = File::Spec->catfile('include', 'tconv_config.h.in');
my $config_h    = File::Spec->catfile('output', 'include', 'tconv_config.h');
make_path(dirname($config_h));

my $ac = Config::AutoConf::INI->new(logfile => 'config.log');
$ac->define_var('TCONV_NTRACE', 1);
$ac->check;
write_config($version, $config_h_in, $config_h);

# -------------
# Fake export.h
# -------------
my $export_h = File::Spec->catfile('output', 'include', 'tconv', 'export.h');
make_path(dirname($export_h));
open(my $fh, '>', $export_h) || die "Cannot open $export_h, $!";
print $fh "#define tconv_EXPORT\n";
print $fh "#define TCONV_NO_EXPORT\n";
close($fh) || warn "Cannot close $export_h, $!";

my @additional_includes = ();
my @additional_srcdir = ();

# -----------------------------------------------------
# We depend on cchardet that is in the form of a tar.gz
# -----------------------------------------------------
my $tar=Archive::Tar->new();
my $cchardet_tar = File::Spec->catfile('3rdparty', 'tar', 'cchardet-1.0.0.tar.gz');
$tar->read($cchardet_tar);
print "... Extracting $cchardet_tar in 3rdparty/output\n";
make_path(File::Spec->catdir('3rdparty', 'output'));
{
    local $CWD = File::Spec->catdir('3rdparty', 'output');
    $tar->extract();
}
undef $tar;
#
# nspr-emu mess, we fix it by generating ourself what is needed
#
my $libcharsetdetect = File::Spec->catdir('3rdparty', 'output', 'cchardet-1.0.0', 'src', 'ext', 'libcharsetdetect');
my $nspremu = File::Spec->catdir($libcharsetdetect, 'nspr-emu');
print "... Suppress directory $nspremu\n";
remove_tree($nspremu);
print "... Generate directory $nspremu\n";
make_path($nspremu);
#
# nsDebug.h.in have no dependency on cmake discoveries
#
my $nsDebug = File::Spec->catfile($nspremu, 'nsDebug.h');
print "... Generate file $nsDebug\n";
copy(File::Spec->catfile('include', 'nsDebug.h.in'), $nsDebug);
#
# prmem.h.in have no dependency on cmake discoveries
#
my $prmem = File::Spec->catfile($nspremu, 'prmem.h');
print "... Generate file $prmem\n";
copy(File::Spec->catfile('include', 'prmem.h.in'), $prmem);
#
# nscore.h.in depend on some type sizes
#
my $nscore = File::Spec->catfile($libcharsetdetect, 'nscore.h');
print "... Suppress file $nscore\n";
unlink($nscore);
print "... Generate file $nscore\n";
write_nscore(File::Spec->catfile('include', 'nscore.h.in'), $nscore);

push(@additional_srcdir, File::Spec->catdir('3rdparty', 'output', 'cchardet-1.0.0', 'src', 'ext', 'libcharsetdetect', 'mozilla', 'extensions', 'universalchardet', 'src', 'base'));
push(@additional_srcdir, File::Spec->catfile($libcharsetdetect, 'charsetdetect.cpp'));
push(@additional_includes, File::Spec->catdir($libcharsetdetect, 'mozilla', 'extensions', 'universalchardet', 'src', 'base'));
push(@additional_includes, File::Spec->catdir($libcharsetdetect, 'nspr-emu'));
push(@additional_includes, $libcharsetdetect);

my $extra_compiler_flags = '';
# ------------------------------------------------
# On Windows, we will use dlfcn-win32 and winiconv
# ------------------------------------------------
my @additional = ();
my $winiconv = 0;
if (is_os_type('Windows')) {
    push(@additional, 'dlfcn-win32');
    push(@additional, 'winiconv');
    #
    # This depend on psapi, and perl's cflags always include that by default
    #
    push(@additional_srcdir, File::Spec->catdir('output', '3rdparty', 'dlfcn-win32', 'dlfcn.c'));
    push(@additional_srcdir, File::Spec->catdir('output', '3rdparty', 'winiconv', 'win_iconv.c'));
    #
    # Well, dlfcn.h is at dlfcn-win32 level
    #
    push(@additional_includes, File::Spec->catdir('output', '3rdparty', 'dlfcn-win32'));
    #
    # And we want to make sure we will get the iconv.h from winiconv, not the one from the system
    #
    push(@additional_includes, File::Spec->catdir('output', '3rdparty', 'winiconv'));
    $extra_compiler_flags = "-DICONV_SECOND_ARGUMENT_IS_CONST";
    $winiconv = 1;
}

# --------------------------------------------------------------------------------
# getopt is only used for the tconv binary - not needed from library point of view
# --------------------------------------------------------------------------------

# -----------------------------------------------------------------
# We depend on these* stuff that can manage themselvess, eventually
# -----------------------------------------------------------------
foreach (qw/genericLogger/, @additional) {
    if (! dircopy(File::Spec->catdir('3rdparty', 'github', $_),
                  File::Spec->catdir('output', '3rdparty', $_))) {
        die "Failed to copy $_";
    }
    print "... Copying $_\n";
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

# ------------------------------------------------
# Everything is in place: check iconv capabilities
# ------------------------------------------------
my $twobytes_ok = "\"!!\"";
my $twobytes_ko = "\"\\xa0\\xa1\"";

$ac->define_var('TCONV_HAVE_ICONV', 1);

print "\n";
print "..........................................................\n";
print " Checking iconv location\n";
print "..........................................................\n";
print "\n";

my $extra_linker_flags = '';
if (! is_os_type('Windows')) {
    foreach my $this_lib ('', 'iconv', 'iconv-2') {
	$ac->msg_checking(sprintf "iconv is in %s library", $this_lib || 'standard');
	my $conftest = $ac->lang_build_program("#include <stdlib.h>\n#include <iconv.h>", "{iconv_t cd; iconv(cd, NULL, NULL, NULL, NULL);}");
	$ac->push_libraries($this_lib) if $this_lib;
	if ($ac->link_if_else($conftest)) {
	    $ac->msg_result('yes');
	    $extra_linker_flags = "-l${this_lib}" if $this_lib;
	    last;
	} else {
	    $ac->msg_result('no');
	}
    }
}

print "\n";
print "..........................................................\n";
print " Checking iconv capability - please ignore the next lines \n";
print "..........................................................\n";
print "\n";

my $iconv_can_translit = get_iconv_capability("ASCII//TRANSLIT", "UTF-8", $twobytes_ok, $winiconv, $extra_compiler_flags, $extra_linker_flags, @additional_includes);
my $iconv_can_ignore   = get_iconv_capability("ASCII//IGNORE",   "UTF-8", $twobytes_ok, $winiconv, $extra_compiler_flags, $extra_linker_flags, @additional_includes);

print "\n";
print " The iconv we are using triggered the following settings:\n";
print "\n";

$ac->msg_checking('ICONV_CAN_TRANSLIT');
if ($iconv_can_translit) {
  $ac->define_var('ICONV_CAN_TRANSLIT', 1);
  $ac->msg_result('yes');
} else {
  $ac->msg_result('no');
}

$ac->msg_checking('ICONV_CAN_IGNORE');
if ($iconv_can_ignore) {
  $ac->define_var('ICONV_CAN_IGNORE', 1);
  $ac->msg_result('yes');
} else {
  $ac->msg_result('no');
}

print "\n";
print "..........................................................\n";
print " Checking iconv capability done                           \n";
print "..........................................................\n";
print "\n";

$ac->write_config_h(File::Spec->catfile('output', 'include', 'tconv', 'config_autoconf.h'));

# ----------------
# Get source files
# ----------------
my @sources;
find(
    {
	no_chdir => 1,
	wanted => sub {
	    my $file = File::Spec->canonpath($_);
	    if (-f $file && ($file =~ /\.c$/ || $file =~ /\.cpp$/)) {
                #
                # We know that ICU.c is an exception
                #
                if (basename($file) ne 'ICU.c') {
                    push(@sources, $file)
                }
	    }
	},
    },
    'src', @additional_srcdir);

# ----------------------------------------------------------------------------------------
# Generate objects
# (individually- not efficient but I do not see how CBuilder mixes C and C++ source files)
# ----------------------------------------------------------------------------------------
my $cbuilder = ExtUtils::CBuilder->new();
my @objects;
my $obj_dir = File::Spec->catfile('output', 'obj4perl');

make_path($obj_dir);
foreach my $source (@sources) {
    my $is_cplusplus = ($source =~ /\.cpp$/i || $source =~ /\.c\+\+$/i);
    my $obj = File::Spec->catfile($obj_dir, basename($cbuilder->object_file($source)));
    push(@objects, $cbuilder->object_file($source));
    $cbuilder->compile(
                       source        => $source,
                       extra_compiler_flags => $extra_compiler_flags,
                       object_file   => $obj,
                       include_dirs  => [ 'include', File::Spec->catdir('output', 'include'), @additional_includes ],
                       'C++'         => $is_cplusplus
                      );
}

# ----
# Done
# ----
exit(EXIT_SUCCESS);

sub get_version {
    open(my $fh, '<', 'CMakeLists.txt') || die "Cannot open CMakeLists.txt, $!";
    my $content = do { local $/; <$fh>; };
    close($fh) || warn "Failed to close CMakeLists.txt, $!";

    my @rc;
    if ($content =~ /^MYPACKAGESTART\s*\(\s*tconv\s+(\d+)\s+(\d+)\s+(\d+)\s*\)/sm) {
        @rc = ($1, $2, $3);
    } else {
        foreach (qw/TCONV_VERSION_MAJOR TCONV_VERSION_MINOR TCONV_VERSION_PATCH/) {
            if ($content =~ /^SET\s*\(\s*$_\s*(\d+)\s*\)/sm) {
                push(@rc, $1);
            } else {
                die "Failed to find $_",
            }
        }
    }

    return join('.', @rc)
}

sub write_config {
    my ($version, $input, $output) = @_;

    make_path(dirname($output));
    open(my $fh, '<', $input) || die "Cannot open $input, $!";
    my $source = do { local $/; <$fh>; };
    close($fh) || warn "Cannot close $input, $!";

    $source =~ s/^[ \t]*#[ \t]*cmakedefine[ \t]+(\w+)+[ \t]+\@([^ \t@]*)\@//smg;

    open($fh, '>', $output) || die "Cannot open $output, $!";
    my $c_va_copy = get_C_WRAPPER('va_copy');
    print $fh <<CONFIG;
#ifndef TCONV_CONFIG_WRAPPER_H
#define TCONV_CONFIG_WRAPPER_H

#include <tconv/config_autoconf.h>

#define TCONV_C_INLINE
#define TCONV_HAVE_ICONV 1
#define TCONV_VERSION "$version"

$c_va_copy

#ifdef C_VA_COPY
#define TCONV_C_VA_COPY C_VA_COPY
#endif

#ifdef HAVE__STRNICMP
#define C_STRNICMP _strnicmp
#else
  #ifdef HAVE_STRNICMP
  #define C_STRNICMP strnicmp
  #else
    #ifdef HAVE_STRNCASECMP
    #define C_STRNICMP strncasecmp
    #else
    #define C_STRNICMP _tconv_strnicmp
    #endif
  #endif
#endif

$source

#endif /* TCONV_CONFIG_WRAPPER_H */
CONFIG
    close($fh) || warn "Cannot close $output, $!";
}

sub get_C_WRAPPER {
    my ($what, $required) = @_;

    $required //= 1;

    my $WHAT = uc($what);
    my $error = $required ? "#error \"C_$WHAT is undefined\"" : '';

    my $c_wrapper = <<C_WRAPPER;
#ifdef HAVE_$WHAT
#  define C_$WHAT $what
#else
#  ifdef HAVE__$WHAT
#    define C_$WHAT _$what
#  else
#    ifdef HAVE___$WHAT
#      define C_$WHAT __$what
#    else
$error
#    endif
#  endif
#endif
C_WRAPPER
    return $c_wrapper
}

sub write_nscore {
    my ($input, $output) = @_;

    make_path(dirname($output));
    open(my $fh, '<', $input) || die "Cannot open $input, $!";
    my $source = do { local $/; <$fh>; };
    close($fh) || warn "Cannot close $input, $!";

    $source =~ s/^[ \t]*#[ \t]*cmakedefine\b.*?$//smg;
    $source =~ s/^[ \t]*#[ \t]*define\s+SIZEOF.*?$//smg;

    open($fh, '>', $output) || die "Cannot open $output, $!";
    print $fh <<NSCORE;
#ifndef NSCORE_WRAPPER_H
#define NSCORE_WRAPPER_H

#include <tconv/config_autoconf.h>

$source

#endif /* TCONV_CONFIG_WRAPPER_H */
NSCORE
    close($fh) || warn "Cannot close $output, $!";
}

sub get_iconv_capability {
  my ($tocharset, $fromcharset, $twobytes, $winiconv, $extra_compiler_flags, $extra_linker_flags, @additional_includes) = @_;

  my $include_winiconv = $winiconv ? '#include <win_iconv.c>' : '';
  my $source = <<SOURCE_HEADERS;
  #include <stdlib.h>
  #include <stdio.h>
  #include <stddef.h>
  #include <string.h>
  $include_winiconv
  #include <iconv.h>
SOURCE_HEADERS
  $source .= q'
  int main(){
    iconv_t  conv;
    char    *src = "123456" ';
  $source .= ${twobytes};
  my $data = $DATA;
  $data =~ s/__TO__/$tocharset/;
  $data =~ s/__FROM__/$fromcharset/;
  $source .= $data;
  # print $source;
  my $cbuilder = ExtUtils::CBuilder->new();
  my ($fh, $filename) = tempfile(SUFFIX => '.c', UNLINK => 0);
  print $fh $source;
  close($fh) || warn "Cannot close $filename, $!";

  my $obj = $cbuilder->object_file($filename);
  $cbuilder->compile(
                     source        => $filename,
                     extra_compiler_flags => $extra_compiler_flags,
                     object_file   => $obj,
                     include_dirs  => [ 'include', File::Spec->catdir('output', 'include'), @additional_includes ],
                     'C++'         => 0
                    );
  $cbuilder->link_executable(
                             module_name => 'ICONV::TEST',
                             extra_linker_flags =>, $extra_linker_flags,
                             objects => $obj
                            );
  system($cbuilder->exe_file($obj), 'unused', 'parameter');
  my $exitcode =  $? >> 8;
  unlink $cbuilder->exe_file($obj);
  unlink $obj;
  my $rc = $exitcode ? 0 : 1;
  unlink $filename;

  return $rc;
}

__DATA__
; /* In UTF8: 123, euro sign, 456 */
    char     dst[1024];
    char    *inp = src;                             /* Input moving pointer */
    char    *outp = dst;                            /* Output moving pointer */
    size_t   inl = 8;                               /* 6 + 2 */
    size_t   outl = 1024;                           /* 1024 bytes available in output buffer */

    memset((void *) dst, '\0', 1024);
    conv = iconv_open("__TO__", "__FROM__");
    if (conv == (iconv_t)-1) { perror("iconv_open"); return 1; }
    if (iconv(conv, &inp, &inl, &outp, &outl) == (size_t)-1)  { perror("iconv"); return 1; }
    /* Flush */
    if (iconv(conv, NULL, NULL, &outp, &outl) == (size_t)-1)  { perror("iconv"); return 1; }
    if (iconv_close(conv) == -1)  { perror("iconv_close"); return 1; }
    fprintf(stdout, "%s\n", dst);
    return 0;
  }
