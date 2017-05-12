# Ex2.pl
#
# This example creates a simple dashboard with 2 HorizontalBars
# based on the m2.jpg graphic.  I did the m2.jpg so it is, um,
# not professional :)
#
# 01/10/02  daf  initial revision
#

use GD::Dashboard;
use strict;

#
# First create the dashboard.  It serves as a 
# container for the various gauges.
#
my $dash = new GD::Dashboard( FNAME=>'m2.jpg' );


#
# Now create some a meter (in this cause a HorizontalBar).  This
# gauge will register values between 0 and 20, so to display a value
# of 5%, you would set a value of 1.
#

my $g1 = new GD::Dashboard::HorizontalBar(
            NX => 8,     # Upper left corner X to start drawing
            NY => 23,    # Upper left corner Y to start drawing
            MIN => 0,    # Value corresponding to no bars
            MAX => 20,   # Value corresponding to all bars
            SPACING => 1 # 1 pixel blank space between bars
            );

$g1->add_bars(20,             # Add 20 bars
        'barlight_on.jpg',    # With this graphic representing 'on'
        'barlight_off.jpg'    # and this one representing 'off'
        );

# Let's light up half of them
$g1->set_reading(10);

# Associate the meter with the dashboard
$dash->add_meter('meter1',$g1);


#
# Create a second meter, also a horizontal bar, this time without
# all the comments.  This time we have 3 different types of
# bars, possibly corresponding to good, warning, and bad.
#

my $g2 = new GD::Dashboard::HorizontalBar(
            NX => 8,     
            NY => 44,    
            MIN => 0,    
            MAX => 20,   
            SPACING => 1 
            );

# Add a group of 8 green bars

$g2->add_bars(8,             # Add 5 bars
        'green_on.jpg',    # With this graphic representing 'on'
        'green_off.jpg'    # and this one representing 'off'
        );

# Add a group of 3 yellow bars

$g2->add_bars(3,             # Add 5 bars
        'yellow_on.jpg',    # With this graphic representing 'on'
        'yellow_off.jpg'    # and this one representing 'off'
        );

# Add a group of 2 red bars (oh no!  Not red bars!)

$g2->add_bars(2,             # Add 5 bars
        'red_on.jpg',    # With this graphic representing 'on'
        'red_off.jpg'    # and this one representing 'off'
        );

$g2->set_reading(19);

$dash->add_meter('meter2',$g2);

#
# Finally, write the dashboard out to a jpeg.
#
$dash->write_jpeg('ex2.jpg');
