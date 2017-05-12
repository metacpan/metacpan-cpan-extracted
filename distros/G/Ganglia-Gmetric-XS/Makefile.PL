use inc::Module::Install;
use Getopt::Long;

name        'Ganglia-Gmetric-XS';
all_from    'lib/Ganglia/Gmetric/XS.pm';

build_requires 'Test::More'      => 0;

GetOptions(
    "ganglia-dir=s"      => \my $ganglia_dir,
    "diag"               => \my $diagnostic,
    "debug"              => \my $debug,
   );
$ganglia_dir ||= $ENV{GANGLIA_DIR} if $ENV{GANGLIA_DIR};

my @defines;
die "missing option: --ganglia-dir=/path/to/ganglia-3.0.x" unless $ganglia_dir;
my $ganglia_version = 0; # 3.0, 3.1
open my $configure, '<', "$ganglia_dir/configure" or die $!;
while (<$configure>) {
    if (/^GANGLIA_MAJOR_VERSION=(\d+)/) {
        $ganglia_version += $1;
    } elsif (/^GANGLIA_MINOR_VERSION=(\d+)/) {
        $ganglia_version += $1*0.1;
    }
}
close $configure;
print "ganglia version: $ganglia_version\n";

my @static_libs;
my @inc_paths;
my $libs;
if ($ganglia_version == 3.0) {
    push @defines, '-DGANGLIA30';
    @static_libs = qw(
                         lib/.libs/libganglia.a
                         srclib/apr/.libs/libapr-0.a
                         srclib/confuse/src/.libs/libconfuse.a
                    );
    @inc_paths = ("$ganglia_dir/lib", "$ganglia_dir/srclib/apr/include");
    $libs = "-lrt";
} elsif ($ganglia_version >= 3.1) {
    push @defines, '-DGANGLIA31';
    @static_libs = qw(
                         lib/.libs/libganglia.a
                    );
    @inc_paths = ("$ganglia_dir/include", "$ganglia_dir/lib");
    $libs = "-lrt -lconfuse -lapr-1";
}

my @myextlibs;
for my $lib (@static_libs) {
    my $lib_path = "$ganglia_dir/$lib";
    if(not -r $lib_path) {
        die "$lib_path: cannot find";
    }
    push @myextlibs, $lib_path;
}

can_cc or die "This module requires a C compiler";
cc_optimize_flags "-O2";
cc_inc_paths @inc_paths;
#cc_lib_paths "";
libs $libs;;

makemaker_args "MYEXTLIB" => join(" ", @myextlibs);
if ($diagnostic) {
    cc_optimize_flags "-g";
    push @defines, "-DDIAG";
}
if ($debug) {
    cc_optimize_flags "-g";
}
makemaker_args "DEFINE" => join(" ", @defines);

use_test_base;
auto_install;
WriteAll;
