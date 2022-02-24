use 5.006;
use strict;
use warnings;
use Module::Build;

if ($^O ne 'linux' && $^O ne 'freebsd') {
	print "No support for OS\n";
	exit 0;
}

my $builder = Module::Build->new(
	module_name         => 'Linux::FD::Mem',
	  'build_requires' => {
    'Module::Build' => '0.28',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.28'
  },
  'requires' => {
    'XSLoader' => '0',
    'strict' => '0',
    'warnings' => '0'
  },
	
);

$builder->create_build_script();
