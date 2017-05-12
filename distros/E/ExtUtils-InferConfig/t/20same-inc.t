#!perl -w
use strict;
use Test::More tests => scalar(grep {not ref($_)} @INC) + 4;

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
  skip "Can't run the currently running perl. Your environment must be broken", scalar(grep {not ref($_)} @INC) + 4
    if not defined $perl;

  use_ok('ExtUtils::InferConfig');

  my $eic = ExtUtils::InferConfig->new(
      perl => $perl,
      ($ENV{EUI_DEBUG} ? (debug => 1) : ()),
  );
  isa_ok($eic, 'ExtUtils::InferConfig');

  my $inc = $eic->get_inc;
  ok(ref($inc) eq 'ARRAY', '->get_inc returns array ref');

  my @local_inc = grep {not ref($_)} @INC;
  ok(
      scalar(@local_inc) == scalar(@$inc),
      'Same number of non-ref @INC entries'
  );

  foreach my $path (@local_inc) {
      my $inc_path = shift @$inc;
      is($inc_path, $path);
  }
};

