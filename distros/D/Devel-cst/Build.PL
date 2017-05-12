use strict;
use warnings;
use Module::Build;

my @extra_linker_flags = $^O =~ m/ ^ (?! gnuk) .* bsd $ /xmsi ? qw/-lexecinfo/ : ();

my $builder = Module::Build->new(
  module_name         => 'Devel::cst',
    'build_requires' => {
    'Module::Build' => '0.28'
  },
  'configure_requires' => {
    'Module::Build' => '0.28',
    'perl' => '5.006'
  },
  'requires' => {
    'Exporter' => '5.57',
    'XSLoader' => '0',
    'perl' => '5.006',
    'strict' => '0',
    'warnings' => '0'
  },
  'test_requires' => {
    'POSIX' => '0',
    'Test::More' => '0.89',
    'perl' => '5.006'
  },
  
  extra_linker_flags  => \@extra_linker_flags,
);

$builder->create_build_script();
