# IUP::Text + MASK example
#
# Creates an IUP::Text that accepts only numbers

use strict;
use warnings;

use IUP ':all';

my $txt = IUP::Text->new( MASK=>'/d*', EXPAND=>"YES" );

my $dg = IUP::Dialog->new( child=>$txt, TITLE=>"MASK (numbers only)", SIZE=>"200x" );
$dg->Show();

IUP->MainLoop();
