# IUP->SetIdle Example
#
# Basic usage of idle callback

use strict;
use warnings;

use IUP ':all';

my $l = IUP::Label->new( TITLE=>"0", SIZE=>"150x" );
my $b = IUP::Button->new( TITLE=>"Go" );

my $active = 0;

sub idle_cb {
  if ($active) {
    my $v = int($l->TITLE) + 1;
    $l->TITLE($v);
    if ( $v >= 10000 ) {
      $active = 0;
    }
  }
  return IUP_DEFAULT;
}

$b->ACTION( sub {$l->TITLE(0);$active = 1;} );

my $dlg = IUP::Dialog->new( MARGIN=>"10x10", child=>IUP::Vbox->new([$l,$b]), TITLE=>"Idle Test" );

$dlg->ShowXY(IUP_CENTER, IUP_CENTER);

# Registers idle callback;
IUP->SetIdle(\&idle_cb);

IUP->MainLoop;
