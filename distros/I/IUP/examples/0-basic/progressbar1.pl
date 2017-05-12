# IUP::Progressbar example

use strict;
use warnings;

use IUP ':all';

my $progressbar = IUP::ProgressBar->new(MIN=>0, MAX=>1);
my $timer = IUP::Timer->new(ACTION_CB=>\&idle_cb, TIME=>100, RUN=>'YES');
my $dlg = IUP::Dialog->new( child=>$progressbar, TITLE=>"IUP::ProgressBar");

sub idle_cb {
  my $value = $progressbar->VALUE;
  if ( $value >= 1 ) {
   $value = 0.01;
  }
  else {
   $value += 0.01;
  }
  $progressbar->VALUE($value);
  return IUP_DEFAULT;
}

$dlg->ShowXY(IUP_CENTER, IUP_CENTER);
IUP->MainLoop;
