# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use Git::DescribeVersion::App ();

my %defaults = %Git::DescribeVersion::Defaults;

# Ensure that the arguments are processed in the correct order: %ENV, @ARGV, @_
my @tests = (
  {env => {}, argv => [], args => [], exp => {}},

  {env => {first_version => '1st'}, argv => [], args => [], exp => {first_version => '1st'}},
  {env => {first_version => '1st'}, argv => ['--first-version' => '2nd'], args => [], exp => {first_version => '2nd'}},
  {env => {first_version => '1st'}, argv => ['--first-version' => '2nd'], args => ['first_version' => '3rd'], exp => {first_version => '3rd'}},

  {env => {format => 'normal'}, argv => [], args => [], exp => {format => 'normal'}},
  {env => {format => 'normal'}, argv => ['--format' => 'decimal'], args => [], exp => {format => 'decimal'}},
  {env => {format => 'cheesy'}, argv => ['--format' => 'stinky'], args => ['format' => 'no-v'], exp => {format => 'no-v'}},

  {
    argv => ['--format' => 'stinky', '--match'        => 'MPA'],
    env  => {   format  => 'cheesy',    match_pattern => 'MPE'},
    args => [  'format' => 'no-v',      match_pattern => 'MP_'],
    exp  => {   format  => 'no-v',      match_pattern => 'MP_'},
  },
  {
    args => [  'format' => 'no-v',      match_pattern => 'MP_'],
    argv => ['--format' => 'stinky', '--match'        => ''],
    env  => {   format  => 'cheesy',    match_pattern => 'MPE'},
    exp  => {   format  => 'no-v',      match_pattern => 'MP_'},
  },
  {
    argv => ['--format' => 'stinky', '--match'        => ''],
    env  => {   format  => 'cheesy',    match_pattern => 'MPE'},
    exp  => {   format  => 'no-v',      match_pattern => ''},
    args => [  'format' => 'no-v',      match_pattern => ''],
  },
  {
    exp  => {   format  => 'no-v',                         },
    env  => {   format  => 'cheesy',          pattern => 'MPE'}, # unknown arg
    argv => ['--format' => 'stinky',                       ],
    args => [  'format' => 'no-v',                         ],
  },
);

plan tests => @tests * 2;

foreach my $test ( @tests ){
  my ($env, $argv, $args, $exp) = @$test{qw(env argv args exp)};
  $env->{"GIT_DV_\U$_"} = delete $env->{$_} for keys %$env;

  local %ENV = (%ENV, %$env);

  local @ARGV = @$argv;
  is_deeply(Git::DescribeVersion::App::options(@$args), $exp, 'got expected options as function');
  local @ARGV = @$argv;
  is_deeply(Git::DescribeVersion::App->options(@$args), $exp, 'got expected options as class method');
}
