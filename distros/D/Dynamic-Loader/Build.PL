use strict;
use warnings;
use Module::Build;

my @scripts;
open (fd, "<MANIFEST") or die "cannot open MANIFEST: $!";
while(<fd>){
  chomp;
  next unless /^scripts\//;
  push @scripts, $_;
}
close fd;
my $builder = Module::Build->new(
    module_name         => 'Dynamic::Loader',
    license             => 'perl',
    create_makefile_pl => 'traditional',
    create_readme => 'README',
    dist_author         => 'Olivier Evalet <olivier.evalet@genebio.com>, Alexandre Masselot<alexandre.masselot@genebio.com>',
    dist_version_from   => 'lib/Dynamic/Loader.pm',
    build_requires => {
		       'Test::More' => 0,
		       'Env::Path' => 0,
		       'File::find::Rule' => 0,
    },
    script_files=>\@scripts,
    add_to_cleanup      => [ 'Dynamic-Loader-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
