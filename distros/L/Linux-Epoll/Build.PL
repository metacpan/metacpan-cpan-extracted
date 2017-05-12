use 5.006;
use strict;
use warnings;
use Module::Build;

if ($^O ne 'linux') {
	print "No support for OS\n";
	exit 0;
}

my $builder = Module::Build->new(
	module_name => 'Linux::Epoll',
	  'build_requires' => {
    'File::Spec' => '0',
    'IO::Handle' => '0',
    'IPC::Open3' => '0',
    'Module::Build' => '0.28',
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
