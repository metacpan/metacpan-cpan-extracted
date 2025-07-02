use strict;
use warnings;

on 'configure' => sub {
  requires 'Config'                        => '0';
  requires 'ExtUtils::MakeMaker'           => '6.76';     # Offers the RECURSIVE_TEST_FILES feature
  requires 'ExtUtils::MakeMaker::CPANfile' => '0';
  requires 'File::Spec::Functions'         => '0';
  requires 'strict'                        => '0';
  requires 'version'                       => '0.9915';
  requires 'warnings'                      => '0'
};

on 'runtime' => sub {
  requires 'Marpa::R2'   => '0';
  requires 'URI::Escape' => '0';
  requires 'constant'    => '0';
  requires 'strict'      => '0';
  requires 'subs'        => '0';
  requires 'version'     => '0.9915';
  requires 'warnings'    => '0'
};

on 'test' => sub {
  requires 'JSON::PP'      => '0';
  requires 'Test::Fatal'   => '0';
  requires 'Test::Harness' => '3.50';
  requires 'Test::Needs'   => '0';
  requires 'Test::More' => '1.001005'    # Subtests accept args
};

on develop => sub {
  requires 'Devel::Cover'       => '1.33';       # Fix cover -test with Build.PL
  requires 'Perl::Tidy'         => '20250311';
  requires 'Template'           => '0';
  requires 'Test::Needs'        => '0';
  requires 'Test::Perl::Critic' => '0';
  requires 'Test::Pod'          => '1.26'
}
