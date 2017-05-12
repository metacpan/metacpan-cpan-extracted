use strict;
use warnings;
use Test::More;
use Dist::Zilla::App::Tester;

plan skip_all => 'Test requires Dist::Zilla::PluginBundle::Alien'
  unless eval q{ require Dist::Zilla::PluginBundle::Alien; 1 };
plan tests => 6;

delete $ENV{$_} for qw( ALIEN_FORCE ALIEN_INSTALL_TYPE );

subtest normal => sub {
  my $output = test_dzil('corpus/dist1', ['aliendeps'])->output;
  chomp $output;
  is_deeply [split /\n/, $output], [qw( Alien::bar Alien::foo )], "expexted alien prereqs";
};

subtest 'env ALIEN_FORCE=undef' => sub {
  my $output = test_dzil('corpus/dist1', ['aliendeps', '--env'])->output;
  chomp $output;
  is_deeply [split /\n/, $output], [qw( Alien::bar Alien::foo )], "expexted alien prereqs";
};

subtest 'env ALIEN_FORCE=1' => sub {
  local $ENV{ALIEN_FORCE} = 1;
  my $output = test_dzil('corpus/dist1', ['aliendeps', '--env'])->output;
  chomp $output;
  is_deeply [split /\n/, $output], [qw( Alien::bar Alien::foo )], "expexted alien prereqs";
};

subtest 'env ALIEN_FORCE=0' => sub {
  local $ENV{ALIEN_FORCE} = 0;
  my $output = test_dzil('corpus/dist1', ['aliendeps', '--env'])->output;
  chomp $output;
  is_deeply [split /\n/, $output], [], "expexted alien prereqs";
};

subtest 'env ALIEN_INSTALL_TYPE=share' => sub {
  local $ENV{ALIEN_FORCE} = 'share';
  my $output = test_dzil('corpus/dist1', ['aliendeps', '--env'])->output;
  chomp $output;
  is_deeply [split /\n/, $output], [qw( Alien::bar Alien::foo )], "expexted alien prereqs";
};

subtest 'env ALIEN_INSTALL_TYPE=system' => sub {
  local $ENV{ALIEN_INSTALL_TYPE} = 'system';
  my $output = test_dzil('corpus/dist1', ['aliendeps', '--env'])->output;
  chomp $output;
  is_deeply [split /\n/, $output], [], "expexted alien prereqs";
};
