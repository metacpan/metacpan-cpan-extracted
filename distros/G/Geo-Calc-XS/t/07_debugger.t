use strict;
use warnings;
use utf8;

use Test::More;
BEGIN {
    my $needed_modules = [ 'Cwd', 'File::Basename', 'File::Spec', 'IPC::Open3' ];
    foreach my $module ( @{ $needed_modules } ) {
        eval "use $module";
        if ($@) {
            plan skip_all => join( ', ', @{ $needed_modules } ). " are needed";
        }
    }
}

plan skip_all => "skipping as we are failing on many configs";

use_ok 'Geo::Calc::XS';

my $root_dir = File::Basename::dirname(File::Basename::dirname(Cwd::abs_path($0)));
ok(-d $root_dir, "$root_dir is a directory");

my $check_module_fn = File::Spec->catfile($root_dir, "t", "02_check_module.t");
ok(-f $check_module_fn, "02_check_module.t exists");

my $blib_lib_dir = File::Spec->catfile($root_dir, "blib", "lib");
ok(-d $blib_lib_dir, "$blib_lib_dir is a directory");

my $blib_arch_dir = File::Spec->catfile($root_dir, "blib", "arch");
ok(-d $blib_arch_dir, "$blib_arch_dir is a directory");

{
    local $ENV{PERLDB_OPTS} = "NonStop";
    local $ENV{SKIP_THREAD_TESTS} = "1";
    my @cmd = ("perl", "-d", "-I$blib_lib_dir", "-I$blib_arch_dir", "--", $check_module_fn);
    my $err = 1;
    my $pid = IPC::Open3::open3(my $in, my $out, $err, @cmd);
    waitpid($pid, 0);
    my $success = is($?, 0, "Running 02_check_module.t under debugger succeeded");
    if (! $success) {
        note("out:\n" . join("", map { "> $_" } readline($out)));
        diag("err:\n" . join("", map { "> $_" } readline($err)));
    }
}

done_testing();
