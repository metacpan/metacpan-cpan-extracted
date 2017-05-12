#!env perl
use strict;
use diagnostics;
use Config::AutoConf::INI;
use ExtUtils::CBuilder;
use File::Basename;
use File::Find qw/find/;
use File::Path qw/make_path/;
use POSIX qw/EXIT_SUCCESS/;

# ------------------------------------------------------------
# Generation of objects using perl setup, for use in perl's XS
# ------------------------------------------------------------
my $version = get_version();
print "Generating config for genericLogger version $version\n";

# ------------------------
# Write configuration file
# ------------------------
my $config_h_in = File::Spec->catfile('include', 'genericLogger_config.h.in');
my $config_h    = File::Spec->catfile('output', 'include', 'genericLogger', 'config.h');
make_path(dirname($config_h));
Config::AutoConf::INI->new(logfile => 'config.log')->check;
write_config($version, $config_h_in, $config_h);

# -------------
# Fake export.h
# -------------
my $export_h = File::Spec->catfile('output', 'include', 'genericLogger', 'export.h');
make_path(dirname($export_h));
open(my $fh, '>', $export_h) || die "Cannot open $export_h, $!";
print $fh "#define genericLogger_EXPORT\n";
close($fh) || warn "Cannot close $export_h, $!";

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
		push(@sources, $file)
	    }
	},
    },
    'src');

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
	include_dirs  => [ 'include', File::Spec->catdir('output', 'include') ],
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
    if ($content =~ /^MYPACKAGESTART\s*\(\s*genericLogger\s+(\d+)\s+(\d+)\s+(\d+)\s*\)/sm) {
        @rc = ($1, $2, $3);
    } else {
        foreach (qw/GENERICLOGGER_VERSION_MAJOR GENERICLOGGER_VERSION_MINOR GENERICLOGGER_VERSION_PATCH/) {
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
    my $c_fileno = get_C_WRAPPER('fileno');
    my $c_vsnprintf = get_C_WRAPPER('vsnprintf');
    my $c_localtime_r = get_C_WRAPPER('localtime_r', 0);
    my $c_write = get_C_WRAPPER('write');
    print $fh <<CONFIG;
#ifndef GENERICLOGGER_CONFIG_WRAPPER_H
#define GENERICLOGGER_CONFIG_WRAPPER_H

#include <genericLogger/config_autoconf.h>

#define C_INLINE
#define GENERICLOGGER_VERSION "$version"
   
$c_va_copy
$c_fileno
$c_vsnprintf
$c_localtime_r
$c_write

$source

#endif /* GENERICLOGGER_CONFIG_WRAPPER_H */
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
