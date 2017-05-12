# Ex1.pl
#
# This example creates a simple dashboard with 1 gauge 
# based on the m1.jpg graphic.
#
# 01/10/02  daf  initial revision
#

use GD::Dashboard;
use strict;

#my $val = 0;
my $val = 50;
#my $val = 100;

#
# First create the dashboard.  It serves as a 
# container for the various gauges.
#
my $dash = new GD::Dashboard( FNAME=>'m1.jpg' );


#
# Now create some a meter (in this cause a Gauge).  This
# gauge will register values between 0 and 100, similar to
# how you might set up a gauge to display percentages.
#
# I set the gauge's value in the constructor with VAL=>$val.
#
# NA1 and NA2 are easily determined by trial and error.
#
# The black/yellow/red thing on m1.jpg is not perfectly
# circular.  To see this, view the output when the needle
# is at 0 and then again at 50.  At 0 the tip of the needle
# covers the scale, but at 50 it is about 5 pixels lower than
# the scale.  
#

my $g1 = new GD::Dashboard::Gauge(
             MIN=>0,                 # Leftmost needle position corresponds
                                     # to a value of 0
             MAX=>100,               # Rightmost needle position corresponds
                                     # to a value of 100
             VAL=>$val,
             NA1=>3.14/2+0.95,       # min angle straight up - 50 degrees
             NA2=>3.14/2-0.95,       # max angle straight up + 50 degrees 
             NX=>51,                 # needle base at x=51 on m1.jpg
             NY=>77,                 # needle base at y=77 on m1.jpg
             NLEN=>45,               # needle will be 50 pixels long
             NCOLOR=>[247,91,19]     # needle color will be redish orange
         );


#
# Associate the meter with the dashboard
#
$dash->add_meter('meter1',$g1);

#
# Finally, write the dashboard out to a jpeg.
#
$dash->write_jpeg('ex1.jpg');
