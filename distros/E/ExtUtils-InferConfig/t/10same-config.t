#!perl -w
use strict;
use lib 'lib';
use Config;
use Test::More tests => scalar(keys(%Config))*2 + 4;


sub _MI_can_run {
  require ExtUtils::MakeMaker;
  my ($cmd) = @_;

  my $_cmd = $cmd;
  return $_cmd if (-x $_cmd or $_cmd = MM->maybe_command($_cmd));

  for my $dir ((split /$Config::Config{path_sep}/, $ENV{PATH}), '.') {
    my $abs = File::Spec->catfile($dir, $cmd);
    return $abs if (-x $abs or $abs = MM->maybe_command($abs));
  }

  return;
}

my $perl = _MI_can_run($^X);

SKIP: {
  skip "Can't run the currently running perl. Your environment must be broken", 4+scalar(keys(%Config)*2) if not defined $perl;

  use_ok('ExtUtils::InferConfig');
  my $eic = ExtUtils::InferConfig->new(
      perl => $perl,
      ($ENV{EUI_DEBUG} ? (debug => 1) : ()),
  );
  isa_ok($eic, 'ExtUtils::InferConfig');

  my $cfg = $eic->get_config;
  ok(ref($cfg) eq 'HASH', '->Config returns hash ref');

  is(
      scalar(keys(%Config)), scalar(keys(%$cfg)),
      'Same number of config entries'
  );

  foreach my $key (keys %$cfg) {
      ok(exists($Config{$key}), "Key '$key' exists in both configs");
      is($cfg->{$key}, $Config{$key}, "Value for key '$key' same in both configs.");
  }

};

