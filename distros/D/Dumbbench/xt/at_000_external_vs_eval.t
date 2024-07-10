use strict;
use warnings;
use Dumbbench;

use Test::More tests => 2;
our $PlotTimings = defined $ENV{DUMBBENCH_PLOT_TIMINGS} ? $ENV{DUMBBENCH_PLOT_TIMINGS} : 1;

my $soot_available = eval { require SOOT };
if( $PlotTimings ) {
  print "plot timings were enabled but SOOT is not available. No plots for you.\n";
  $PlotTimings = 0;
}

my $b = Dumbbench->new(
  verbosity => 0,
);

$b->add_instances(
  Dumbbench::Instance::PerlEval->new(
    name         => 'eval',
    code         => 'my $i;foreach (1..1e7){$i++}',
    dry_run_code => 'my $i;foreach (1..0){$i++}',
  ),
  Dumbbench::Instance::Cmd->new(
    name            => 'cmd',
    command         => [$^X, '-e', 'my $i;foreach (1..1e7){$i++}'],
    dry_run_command => [$^X, '-e', 'my $i;foreach (1..0){$i++}'],
  ),
);
$b->run();

use Capture::Tiny 'capture';
my ($stderr, $stdout) = capture {
  $b->report($PlotTimings);
};

diag($stdout);
diag($stderr);

my @res;
foreach my $instance ($b->instances) {
  push @res, $instance->result;
}

# This test appears to be very fragile as it differs in milliseconds,
# so other things can interfere to move the numbers around.
TODO: {
local $TODO = "Unpredictable timings, so this doesn't quite work";
cmp_ok(
  $res[0]->number + 2*$res[0]->error->[0],
  '>=',
  $res[1]->number - 2*$res[1]->error->[0]
);
cmp_ok(
  $res[0]->number - 2*$res[0]->error->[0],
  '<=',
  $res[1]->number + 2*$res[1]->error->[0]
);
}

if ($PlotTimings) {
  foreach my $instance ($b->instances) {
    foreach my $src (qw(dry_timings_as_histogram timings_as_histogram)) {
      my $hist = $instance->$src;
      if (defined $hist) {
        my $cv = TCanvas->new->keep;
        $cv->cd;
        $hist->Draw;
        $hist->keep;
        $cv->Update;
      }
    }
  }

  defined($SOOT::gApplication) && 1; # silence warnings;
  $SOOT::gApplication->Run();
}

