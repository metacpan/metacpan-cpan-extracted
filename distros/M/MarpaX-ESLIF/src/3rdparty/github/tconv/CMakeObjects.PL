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
use Try::Tiny;

autoflush STDOUT 1;

#
# ExtUtils::CBuilder custom configuration from environment:
# Any environment variable PERL_EXTUTILS_CBUILDER_CONFIG_\w+ is
# considered
#
my %EXTUTILS_BUILDER_CONFIG =
    map {
        my $key = $_;
        $key =~ s/^PERL_EXTUTILS_CBUILDER_CONFIG_//;
        $key => $ENV{$_}
    }
    grep {
        $_ =~ /^PERL_EXTUTILS_CBUILDER_CONFIG_\w+/
    } keys %ENV;

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

$ac->msg_checking("for __builtin_expect()");
my $__builtin_expect = <<__BUILTIN_EXPECT;
#include <stdlib.h>

#define C__BUILTIN_EXPECT __builtin_expect
#define C_LIKELY(x)    C__BUILTIN_EXPECT(!!(x), 1)
#define C_UNLIKELY(x)  C__BUILTIN_EXPECT(!!(x), 0)

/* Copied from https://kernelnewbies.org/FAQ/LikelyUnlikely */
int main(char *argv[], int argc)
{
   int a;

   /* Get the value from somewhere GCC can't optimize */
   a = atoi (argv[1]);

   if (C_UNLIKELY(a == 2))
      a++;
   else
      a--;

   return 0;
}
__BUILTIN_EXPECT
if (try_link($__builtin_expect)) {
    $ac->msg_result('yes');
    $ac->define_var("C___BUILTIN_EXPECT", "__builtin_expect");
} else {
    $ac->msg_result('no');
}

foreach my $inline_keyword (qw/inline __inline__ inline__ __inline/) {
    $ac->msg_checking("for $inline_keyword");
    my $inline_source = <<INLINE_SOURCE;
typedef int foo_t;
static $inline_keyword foo_t static_foo() {
  return 0;
}
foo_t foo() {
  return 0;
}
int main(int argc, char *argv[]){
  return 0;
}
INLINE_SOURCE
    if (try_compile($inline_source)) {
        $ac->msg_result('yes');
        $ac->define_var("C_INLINE", $inline_keyword);
        if ($inline_keyword eq 'inline') {
            $ac->define_var("C_INLINE_IS_INLINE", $inline_keyword);
        }
        last;
    } else {
        $ac->msg_result('no');
    }
}
$ac->check;
write_tconv_config($version, $config_h_in, $config_h);

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
my $extra_compiler_flags = '';

# -----------------------------------------------------
# We depend on libiconv that is in the form of a tar.gz
# -----------------------------------------------------
{
    my $tar=Archive::Tar->new();
    my $libiconv_tar = File::Spec->catfile('3rdparty', 'tar', 'libiconv-1.15.tar.gz');
    $tar->read($libiconv_tar);
    print "... Extracting $libiconv_tar in 3rdparty/output\n";
    make_path(File::Spec->catdir('3rdparty', 'output'));
    {
        local $CWD = File::Spec->catdir('3rdparty', 'output');
        $tar->extract();
    }
    undef $tar;
    #
    # We take care to rename config.h to iconv_config.h everwhere in libiconv
    #
    find(
        {
            no_chdir => 1,
            wanted => sub {
                my $file = File::Spec->canonpath($_);
                if (-f $file && ($file =~ /\.c$/ || $file =~ /\.h$/)) {
                    open(my $in, '<', $file) || die "Failed to open $file, $!";
                    my $content = do { local $/; <$in>; };
                    close($in) || warn "Failed to close $file, $!";
                    my $orig = $content;
                    $content =~ s/"config\.h"/"iconv_config.h"/g;
                    $content =~ s/<config\.h>/<iconv_config.h>/g;
                    if ($orig ne $content) {
                        open(my $out, '>', $file) || die "Failed to open $file, $!";
                        print $out $content;
                        close($out) || warn "Failed to close $file, $!";
                        print STDERR "... Replaced config.h by iconv_config.h in $file\n";
                    }
                }
            },
        },
        File::Spec->catdir('3rdparty', 'output', 'libiconv-1.15'));

    my $config_h = File::Spec->catfile('3rdparty', 'output', 'libiconv-1.15', 'include', 'iconv_config.h');
    print "... Generate file $config_h\n";
    open(my $fd, '>', $config_h) || die "Failed to open $config_h, $!";
    print $fd "
/* Generated file */
/* localcharset.c will play itself with WIN32_LEAN_AND_MEAN... */
#undef WIN32_LEAN_AND_MEAN
\n";
    close($fd) || warn "Failed to close $config_h, $!";

    my $iconv_h_in = File::Spec->catfile('3rdparty', 'output', 'libiconv-1.15', 'include', 'iconv.h.in');
    my $iconv_h = File::Spec->catfile('3rdparty', 'output', 'libiconv-1.15', 'include', 'iconv.h');
    print "... Generate file $iconv_h\n";
    write_iconv_h($iconv_h_in, $iconv_h);

    my $localcharset_h_in = File::Spec->catfile('3rdparty', 'output', 'libiconv-1.15', 'libcharset', 'include', 'localcharset.h.in');
    my $localcharset_h = File::Spec->catfile('3rdparty', 'output', 'libiconv-1.15', 'libcharset', 'include', 'localcharset.h');
    print "... Generate file $localcharset_h\n";
    write_localcharset_h($localcharset_h_in, $localcharset_h);

    print "... Checking for nl_langinfo(CODESET)\n";
    $extra_compiler_flags .= " -DHAVE_LANGINFO_CODESET" if get_have_langinfo_codeset();

    my $have_decl_getc_unlocked;
    $ac->check_func('getc_unlocked', {    # and not check_decl
        action_on_false => sub { $have_decl_getc_unlocked = 0 },
        action_on_true  => sub { $have_decl_getc_unlocked = 1 } } );
    $extra_compiler_flags .= " -DHAVE_DECL_GETC_UNLOCK" if $have_decl_getc_unlocked;

    print "... Checking for endianness\n";
    $extra_compiler_flags .= " -DWORDS_LITTLEENDIAN" unless get_is_big_endian();

    $extra_compiler_flags .= " -DICONV_CONST=";
    $extra_compiler_flags .= " -DLIBDIR=\\\"\\\"";
    $extra_compiler_flags .= " -DHAVE_WORKING_O_NOFOLLOW=0";
    $extra_compiler_flags .= " -DENABLE_EXTRA";
    

    push(@additional_srcdir, File::Spec->catfile('3rdparty', 'output', 'libiconv-1.15', 'libcharset', 'lib', 'localcharset.c'));
    push(@additional_srcdir, File::Spec->catfile('3rdparty', 'output', 'libiconv-1.15', 'lib', 'relocatable.c'));
    push(@additional_srcdir, File::Spec->catfile('3rdparty', 'output', 'libiconv-1.15', 'lib', 'iconv.c'));

    push(@additional_includes, File::Spec->catfile('3rdparty', 'output', 'libiconv-1.15', 'include'));
    push(@additional_includes, File::Spec->catfile('3rdparty', 'output', 'libiconv-1.15', 'libcharset', 'include'));
}

# -----------------------------------------------------
# We depend on cchardet that is in the form of a tar.gz
# -----------------------------------------------------
{
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
}

# -----------------------------------
# On Windows, we will use dlfcn-win32
# -----------------------------------
my @additional = ();
if (is_os_type('Windows')) {
    push(@additional, 'dlfcn-win32');
    #
    # This depend on psapi, and perl's cflags always include that by default
    #
    push(@additional_srcdir, File::Spec->catdir('output', '3rdparty', 'dlfcn-win32', 'src', 'dlfcn.c'));
    #
    # Well, dlfcn.h is at dlfcn-win32/src level
    #
    push(@additional_includes, File::Spec->catdir('output', '3rdparty', 'dlfcn-win32', 'src'));
    #
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
                # We know that *ICU.c are exceptions
                #
                my $bfile = basename($file);
                if (! ($file =~ /ICU\.c$/)) {
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
my $cbuilder = ExtUtils::CBuilder->new(config => \%EXTUTILS_BUILDER_CONFIG);
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

sub try_compile {
    my ($csource, $extra_compiler_flags, $link) = @_;

    $link //= 0;
    my $fh = File::Temp->new(UNLINK => 0, SUFFIX => '.c');
    print $fh "$csource\n";
    close($fh);
    my $source = $fh->filename;
    my $rc = 0;

    try {
        my $cbuilder = ExtUtils::CBuilder->new(config => \%EXTUTILS_BUILDER_CONFIG, quiet => 1);
        my $obj = basename($cbuilder->object_file($source));
        $cbuilder->compile(
            source               => $source,
            object_file          => $obj,
            extra_compiler_flags => $extra_compiler_flags
            );
        if ($link) {
            $cbuilder->link_executable(
                objects              => [ $obj ],
                );
        }
        $rc = 1;
    };
    unlink $fh->filename;

    return $rc;
}

sub try_link {
    my ($csource, $extra_compiler_flags) = @_;

    return try_compile($csource, $extra_compiler_flags, 1);
}

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

sub write_tconv_config {
    my ($version, $input, $output) = @_;

    make_path(dirname($output));
    open(my $fh, '<', $input) || die "Cannot open $input, $!";
    my $source = do { local $/; <$fh>; };
    close($fh) || warn "Cannot close $input, $!";

    $source =~ s/^[ \t]*#[ \t]*cmakedefine[ \t]+(\w+)+[ \t]+\@([^ \t@]*)\@//smg;

    open($fh, '>', $output) || die "Cannot open $output, $!";
    print $fh <<CONFIG;
#ifndef TCONV_CONFIG_WRAPPER_H
#define TCONV_CONFIG_WRAPPER_H

#include <tconv/config_autoconf.h>

#define TCONV_C_INLINE
#define TCONV_HAVE_ICONV 1
#define TCONV_VERSION "$version"

$source

#endif /* TCONV_CONFIG_WRAPPER_H */
CONFIG
    close($fh) || warn "Cannot close $output, $!";
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

sub write_iconv_h {
    my ($input, $output) = @_;

    make_path(dirname($output));
    open(my $fh, '<', $input) || die "Cannot open $input, $!";
    my $source = do { local $/; <$fh>; };
    close($fh) || warn "Cannot close $input, $!";

    $source =~ s/\@DLL_VARIABLE\@//smg;
    $source =~ s/\@EILSEQ\@/134679/smg;
    $source =~ s/\@ICONV_CONST\@//smg;
    $source =~ s/\@USE_MBSTATE_T\@/0/smg;
    $source =~ s/\@HAVE_WCHAR_T\@/0/smg;

    open($fh, '>', $output) || die "Cannot open $output, $!";
    print $fh $source;
    close($fh) || warn "Cannot close $output, $!";
}

sub write_localcharset_h {
    my ($input, $output) = @_;

    make_path(dirname($output));
    open(my $fh, '<', $input) || die "Cannot open $input, $!";
    my $source = do { local $/; <$fh>; };
    close($fh) || warn "Cannot close $input, $!";

    open($fh, '>', $output) || die "Cannot open $output, $!";
    print $fh $source;
    close($fh) || warn "Cannot close $output, $!";
}

sub get_have_langinfo_codeset {
    my $source .= q'
#include <stdlib.h>
#include <langinfo.h>
int main(int ac, char **av)
{
  char *cs = nl_langinfo(CODESET);
  exit(0);
}';

    my $rc =  eval {
        my $cbuilder = ExtUtils::CBuilder->new(config => \%EXTUTILS_BUILDER_CONFIG);
        my ($fh, $filename) = tempfile(SUFFIX => '.c', UNLINK => 0);
        print $fh $source;
        close($fh) || warn "Cannot close $filename, $!";

        my $obj = $cbuilder->object_file($filename);
        $cbuilder->compile(
            source        => $filename,
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

sub get_is_big_endian {
    my $source .= q'
#include <stdlib.h>
const int i = 1;
#define is_bigendian() ( (*(char*)&i) == 0 )
int main(int ac, char **av)
{
  exit(is_bigendian() ? 0 : 1);
}';

    my $cbuilder = ExtUtils::CBuilder->new(config => \%EXTUTILS_BUILDER_CONFIG);
    my ($fh, $filename) = tempfile(SUFFIX => '.c', UNLINK => 0);
    print $fh $source;
    close($fh) || warn "Cannot close $filename, $!";

    my $obj = $cbuilder->object_file($filename);
    $cbuilder->compile(
        source        => $filename,
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
    my $rc = $exitcode ? 0 : 1;
    unlink $filename;

    return $rc;
}
