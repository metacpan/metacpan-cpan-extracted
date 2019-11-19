#!env perl
use strict;
use diagnostics;
use Config;
use Config::AutoConf::INI;
use ExtUtils::CBuilder;
use File::chdir;
use File::Basename qw/basename dirname/;
use File::Find qw/find/;
use File::Path qw/make_path/;
use File::Copy::Recursive qw/dircopy/;
use File::Temp qw/tempfile/;
use IPC::Run qw/run/;
use POSIX qw/EXIT_SUCCESS/;
use Perl::OSType qw/is_os_type/;
use Try::Tiny;

# ------------------------------------------------------------
# Generation of objects using perl setup, for use in perl's XS
# ------------------------------------------------------------
my $version = get_version();
print "Generating config for luaunpanic version $version\n";

# ------------------------
# Write configuration file
# ------------------------
my $config_h_in = File::Spec->catfile('include', 'luaunpanic', 'internal', 'luaconf.h.in');
my $config_h    = File::Spec->catfile('output', 'include', 'luaunpanic', 'lua', 'luaconf.h');
make_path(dirname($config_h));

my $ac = Config::AutoConf::INI->new(logfile => 'config.log');
my @extra_compiler_flags = ();
my %cbuilder_config = ExtUtils::CBuilder->new()->get_config;
my $isc99 = 0;
if (($cbuilder_config{cc} // 'cc') ne 'cl') {
    $ac->msg_checking("Checking if C99 is enabled by default:");
    if (try_compile("#if !defined(__STDC_VERSION__) || __STDC_VERSION__ < 199901L\n#error \"C99 is not enabled\"\n#endif\nint main(){return 0;}")) {
        $ac->msg_result('yes');
        $isc99 = 1;
    } else {
        $ac->msg_result('no');
        $ac->msg_notice("Checking what CFLAGS is required for C99:");
        foreach my $flag (qw/-std=gnu99 -std=c99 -c99 -AC99 -xc99=all -qlanglvl=extc99/) {
            $ac->msg_checking("Checking if flag $flag works:");
            if (try_compile("#if !defined(__STDC_VERSION__) || __STDC_VERSION__ < 199901L\n#error \"C99 is not enabled\"\n#endif\nint main(){return 0;}", $flag)) {
                $ac->msg_result('yes');
                push(@extra_compiler_flags, $flag);
                $isc99 = 1;
                last;
            } else {
                $ac->msg_result('no');
            }
        }
    }
}

if ($^O eq "netbsd" && ! $isc99) {
    #
    # We need long long, that C99 guarantees, else _NETBSD_SOURCE will do it
    #
    $ac->msg_notice("NetBSD platform and no c99: Append _NETBSD_SOURCE to CFLAGS to have long long");
    push(@extra_compiler_flags, '-D_NETBSD_SOURCE');
}
#
# Lua defaults are ok in most applications
# push(@extra_compiler_flags, "-DLUA_32BITS", "-DLUA_USE_C89");
#
if (is_os_type('Windows')) {
    push(@extra_compiler_flags, '-DLUA_DL_DLL');
} else {
    push(@extra_compiler_flags, '-DLUA_DL_DLOPEN');
    push(@extra_compiler_flags, '-DLUA_USE_POSIX');
}

my $extra_compiler_flags = join(' ', @extra_compiler_flags);
$ac->check;
write_config($version, $config_h_in, $config_h);

# -------------
# Fake export.h
# -------------
my $export_h = File::Spec->catfile('output', 'include', 'luaunpanic', 'export.h');
make_path(dirname($export_h));
open(my $fh, '>', $export_h) || die "Cannot open $export_h, $!";
print $fh "#define luaunpanic_EXPORT\n";
print $fh "#define LUAUNPANIC_NO_EXPORT\n";
close($fh) || warn "Cannot close $export_h, $!";

# ----------------
# Get source files
# ----------------
my @sources = map { File::Spec->catfile('src', $_) }
qw/
    lapi.c
    lauxlib.c
    lbaselib.c
    lbitlib.c
    lcode.c
    lcorolib.c
    lctype.c
    ldblib.c
    ldebug.c
    ldo.c
    ldump.c
    lfunc.c
    lgc.c
    linit.c
    liolib.c
    llex.c
    lmathlib.c
    lmem.c
    loadlib.c
    lobject.c
    lopcodes.c
    loslib.c
    lparser.c
    lstate.c
    lstring.c
    lstrlib.c
    ltable.c
    ltablib.c
    ltm.c
    lundump.c
    lutf8lib.c
    lvm.c
    lzio.c
    luaunpanic.c
    /;

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
    my $obj = basename($cbuilder->object_file($source));
    $obj = File::Spec->catfile($obj_dir, basename($cbuilder->object_file($source)));
    push(@objects, $cbuilder->object_file($source));
    $cbuilder->compile(
	source        => $source,
	object_file   => $obj,
        extra_compiler_flags => $extra_compiler_flags,
	include_dirs  => [ 'include', File::Spec->catdir('output', 'include'), File::Spec->catdir('include', 'luaunpanic', 'lua'), File::Spec->catdir('output', 'include', 'luaunpanic', 'lua') ],
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
    if ($content =~ /^MYPACKAGESTART\s*\(\s*luaunpanic\s+(\d+)\s+(\d+)\s+(\d+)\s*\)/sm) {
        @rc = ($1, $2, $3);
    } else {
        foreach (qw/LUA_VERSION_MAJOR LUA_VERSION_MINOR LUA_VERSION_PATCH/) {
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
    my $c_log2 = get_C_WRAPPER('log2', 0);
    my $c_log2f = get_C_WRAPPER('log2f', 0);
    my $c_log2l = get_C_WRAPPER('log2l', 0);
    print $fh <<CONFIG;
#ifndef LUAUNPANIC_CONFIG_WRAPPER_H
#define LUAUNPANIC_CONFIG_WRAPPER_H

#include <luaunpanic/config_autoconf.h>

#define LUAUNPANIC_VERSION "$version"
   
$c_va_copy
$c_log2
$c_log2f
$c_log2l

$source

#endif /* LUA_CONFIG_WRAPPER_H */
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
        my $cbuilder = ExtUtils::CBuilder->new();
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
