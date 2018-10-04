# This is a test for module Lingua::EN::ABC.

use warnings;
use strict;
use Test::More;
use Lingua::EN::ABC ':all';

my $american;
my $british;

$american = 'I realize the color and flavor in the center of my pajamas';
$british = a2b ($american);
is ($british, 'I realise the colour and flavour in the centre of my pyjamas');
$american = 'I realize you like this flavor';
$british = a2b ($american, oxford => 1);
is ($british, 'I realize you like this flavour'); 

my $canadian = 'the centre of the program is ten metres';
$american = c2a ($canadian);
like ($american, qr/center/);
$british = c2b ($canadian);
like ($british, qr/programme/);

my $canadian2 = a2c ($american);

is ($canadian2, $canadian);

$canadian2 = b2c ($british);

is ($canadian2, $canadian);

my $aluminum_in = 'aluminum airplane';
my $aluminum_out = a2b ($aluminum_in, s => 1);
is ($aluminum_out, $aluminum_in, "spelling-only does not change $aluminum_in"); 

my $aluminium_in = 'aluminium aeroplane';
my $aluminium_out = a2b ($aluminium_in, s => 1);
is ($aluminium_out, $aluminium_in, "spelling-only does not change $aluminium_in"); 

my $sc = 'somber-colored';
my $sc_out = a2b ($sc);
is ($sc_out, 'sombre-coloured', "coloured");

my $vp = 'vaporized';
my $vp_out = a2b ($vp);
is ($vp_out, 'vapourised');

# Github issue 1.

TODO: {
    local $TODO='case sensitivity';
    my $am = 'The Color Purple.';
    my $br = a2b ($am);
    is ($br, 'The Colour Purple.');
};

# Implement a warning about ambiguous words

TODO: {
    local $TODO='ambiguity';
    my $am = 'program';
    my $warning;
    local $SIG{__WARN__} = sub {$warning = "@_"};
    my $br = a2b ($am, warn => 1);
    ok ($warning, "Got warning");
    like ($warning, qr/ambiguous/i, "Warning has correct form");
};

#TODO: {
#    local $TODO = 'plurals';
    my $behaviors = 'behaviors';
    my $behaviours = a2b ($behaviors);
    is ($behaviours, 'behaviours');
    my $behaviorsround = b2a ($behaviours);
    is ($behaviorsround, $behaviors);

    my $colors = 'colors';
    my $colours = a2b ($colors);
    is ($colours, 'colours');
    my $colorsround = b2a ($colours);
    is ($colorsround, $colors);
#};

done_testing ();


# Local variables:
# mode: perl
# End:
