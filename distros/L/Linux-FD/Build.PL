use 5.006;
use strict;
use warnings;
use Module::Build;

if ($^O ne 'linux') {
	print "No support for OS\n";
	exit 0;
}

my $builder = Module::Build->new(
	module_name         => 'Linux::FD',
	  'build_requires' => {
    'IO::Select' => '0',
    'Module::Build' => '0.28',
    'POSIX' => '0',
    'Test::Exception' => '0',
    'Test::More' => '0.89',
    'Time::HiRes' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.28'
  },
  'requires' => {
    'Sub::Exporter' => '0',
    'XSLoader' => '0',
    'perl' => '5.006',
    'strict' => '0',
    'warnings' => '0'
  },
	
);

$builder->create_build_script();
