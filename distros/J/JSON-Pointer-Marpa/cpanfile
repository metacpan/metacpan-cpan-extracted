use strict;
use warnings;

on configure => sub {
  requires 'ExtUtils::MakeMaker' =>
    '6.76';    # Offers the RECURSIVE_TEST_FILES feature
  requires 'ExtUtils::MakeMaker::CPANfile' =>
    '0';       # Needs at least ExtUtils::MakeMaker 6.52
  requires 'File::Spec' => '0';
  requires 'strict'     => '0';
  requires 'warnings'   => '0'
};

on runtime => sub {
  # https://github.com/jeffreykegler/Marpa--R2/issues/297
  # Question: Too many dependencies?
  requires 'Marpa::R2'   => '0';
  requires 'URI::Escape' => '0';
  requires 'constant'    => '0';
  requires 'strict'      => '0';
  requires 'subs'        => '0';
  requires 'warnings'    => '0'
};

on test => sub {
  requires 'JSON::PP'    => '0';
  requires 'Test::Fatal' => '0';
  requires 'Test::More' => '1.001005'    # Subtests accept args
}
