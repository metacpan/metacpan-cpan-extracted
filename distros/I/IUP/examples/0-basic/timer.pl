# IUP::Timer example
#
# Two timers:
# 1/ each 0.5s prints a message
# 2/ after 3s prints a message + quits the program

use strict;
use warnings;

use IUP ':all';

my $timer1 = IUP::Timer->new(TIME=>500);
my $timer2 = IUP::Timer->new(TIME=>3000);

$timer1->ACTION_CB( sub {
  print("timer 1 called\n");
  return IUP_DEFAULT;
} );


$timer2->ACTION_CB( sub {
  print("timer 2 called\n");
  return IUP_CLOSE;
} );

# can only be set after the time is created;
$timer1->RUN("YES");
$timer2->RUN("YES");

my $dg = IUP::Dialog->new( child=>IUP::Label->new( TITLE=>"Wait..." ), TITLE=>"Timer example", SIZE=>"QUARTER" );
$dg->Show();

IUP->MainLoop;
