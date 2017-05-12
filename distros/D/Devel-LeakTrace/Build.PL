use strict;
use Module::Build;

my $cmd = 'pkg-config --modversion glib-2.0';
die "You don't seem to have glib installed (couldn't run $cmd), stopping\n"
  unless `$cmd`;

my $build = Module::Build->new(
    module_name  => "Devel::LeakTrace",
    dynamic_config => 1,
    license      => 'perl',
    requires     => {
        'Module::Build' => '0.19', # xs
        'Test::More' => 0,
    },
    extra_compiler_flags => ''.`pkg-config --cflags glib-2.0`,
    extra_linker_flags   => ''.`pkg-config --libs glib-2.0`,
    create_makefile_pl   => 'passthrough',
   );

$build->create_build_script;
