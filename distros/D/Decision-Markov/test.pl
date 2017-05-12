#!/usr/bin/perl -w

use Test::Simple tests => 10;
use FileHandle;
use strict;

use Decision::Markov;
ok(1, "Can use Decision::Markov");
my $model = new Decision::Markov;
ok(defined $model, "new() returned something");
ok($model->isa('Decision::Markov'), " and it's the right class");
my $well = $model->AddState("Well", 1);
my $disabled = $model->AddState("Disabled", .5);
my $dead = $model->AddState("Dead", 0);
ok(defined($well) && defined($disabled) && defined($dead),
	"AddState returned some things");
ok($well->isa('Decision::Markov::State') &&
   $disabled->isa('Decision::Markov::State') &&
   $dead->isa('Decision::Markov::State'), " and they're the right class");
my $error = $model->AddPath($well,$disabled,.2);
$error = $model->AddPath($well,$dead,.05) || $error;
$error = $model->AddPath($well,$well,.75) || $error;
$error = $model->AddPath($disabled,$dead,.25) || $error; 
$error = $model->AddPath($disabled,$disabled,.75) || $error;
$error = $model->AddPath($dead,$dead,1) || $error;
ok(!$error, "Transitions were added correctly");
$error = $model->AddPath($well,$disabled,.7);
ok($error, " and redundant transitions are correctly disallowed");
$error = $model->Check;
ok(!$error, "The model checks out");

$model->Reset($well,1000);
my $patients_left = $model->PatientsLeft;
my $cycle = 0;
while ($patients_left) {
  $patients_left = $model->EvalCohStep($cycle);
  $cycle++;
}
my $avg_util_cohort = $model->CumUtility / 1000;
ok((abs($avg_util_cohort - 5.096) < .001), "Cohort simulation worked");

my $numruns = 2;
my $avg_util_mc = 0;
foreach (1..$numruns) {
  $model->Reset($well);
  $cycle = 0;
  my $state = $model->CurrentState;
  while (not $state->FinalState) {
    $state = $model->EvalMCStep($cycle);
    $cycle++;
  }
  $avg_util_mc += $model->CumUtility;
}
$avg_util_mc /= $numruns;
ok(defined $avg_util_mc, "Monte carlo simulation worked");
