#!env perl
use strict;
use diagnostics;
use Config::AutoConf::INI;
use ExtUtils::CBuilder;
use File::Basename;
use File::Find qw/find/;
use File::Path qw/make_path/;
use POSIX qw/EXIT_SUCCESS/;
use Try::Tiny;

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
print "Generating config for genericLogger version $version\n";

# ------------------------
# Write configuration file
# ------------------------
my $config_h_in = File::Spec->catfile('include', 'genericLogger_config.h.in');
my $config_h    = File::Spec->catfile('output', 'include', 'genericLogger', 'config.h');
make_path(dirname($config_h));
my $ac = Config::AutoConf::INI->new(logfile => 'config.log');
$ac->msg_checking("for __builtin_expect()");
my $__builtin_expect = <<__BUILTIN_EXPECT;
#include <stdlib.h>

#define C__BUILTIN_EXPECT __builtin_expect
#define C_LIKELY(x)    C__BUILTIN_EXPECT(!!(x), 1)
#define C_UNLIKELY(x)  C__BUILTIN_EXPECT(!!(x), 0)

/* Copied from https://kernelnewbies.org/FAQ/LikelyUnlikely */
int main(int argc, char *argv[])
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
my $cbuilder = ExtUtils::CBuilder->new(config => \%EXTUTILS_BUILDER_CONFIG);
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
    if ($content =~ /^\s*PROJECT\s*\(\s*genericLogger\s+VERSION\s+(\d+)\.(\d+)\.(\d+)/smi) {
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
