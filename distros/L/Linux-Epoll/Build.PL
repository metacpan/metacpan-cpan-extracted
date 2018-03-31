use 5.006;
use strict;
use warnings;
use Module::Build;

if ($^O ne 'linux') {
	die "No support for OS\n";
}

my $builder = Module::Build->new(
	module_name => 'Linux::Epoll',
	  'build_requires' => {
    'Module::Build' => '0.28',
    'POSIX' => '0',
    'Scalar::Util' => '0',
    'Socket' => '0',
    'Test::More' => '0',
    'Time::HiRes' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.28'
  },
  'requires' => {
    'IO::Handle' => '0',
    'parent' => '0',
    'perl' => '5.010',
    'strict' => '0',
    'warnings' => '0'
  },
	
);

$builder->create_build_script();
