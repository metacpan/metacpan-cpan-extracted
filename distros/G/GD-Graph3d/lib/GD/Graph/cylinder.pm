# $File: //depot/RG/rg/lib/RG/lib/GD/Graph/cylinder.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 370 $ $DateTime: 2002/07/17 20:38:38 $

package GD::Graph::cylinder;

use strict;

use GD::Graph::axestype3d;
use GD::Graph::utils qw(:all);
use GD::Graph::colour qw(:colours);

use base qw/GD::Graph::bars3d/;
$GD::Graph::cylinder::VERSION = '0.63';

my %Defaults = (
	# Spacing between the bars
	bar_spacing 	=> 0,

	# The 3-d extrusion depth of the bars
	bar_depth => 10,
);

sub initialise
{
	my $self = shift;

	my $rc = $self->SUPER::initialise();
	$self->set(correct_width => 1);

	while( my($key, $val) = each %Defaults ) { 
		$self->{$key} = $val 
	} # end while

	return $rc;
} # end initialise

sub draw_bar_h {
    my $self = shift;
    my $g = shift;
    my( $l, $t, $r, $b, $dsci, $brci, $neg ) = @_;
    my $fnord = $g->colorAllocate(0,0,0);

    my $depth = $self->{bar_depth};

    my ($lighter, $darker) = ($dsci, $dsci);
    if ($self->{'3d_shading'}) {
	$lighter = $self->{'3d_highlights'}[$dsci];
	$darker = $self->{'3d_shadows'}[$dsci];
    }
    $g->line($l+$depth, $t+1, $r+$depth, $t+1, $dsci);
    $g->line($l+$depth, $b, $r+$depth, $b, $dsci);
    $g->arc($r+$depth, ($t+$b)/2, $depth*2, ($b-$t), 270, 90, $dsci);
    $g->arc($l+$depth, ($t+$b)/2, $depth*2, ($b-$t), 90, 270, $dsci);
    # find border
    my $foo = $l+$depth;
    --$foo
	until $foo == $l || $g->getPixel($foo, $t+($b-$t)/5) == $dsci;
    my $bar = $foo+1;
    ++$bar
	until $bar == $foo || $g->getPixel($bar, $t+($b-$t)/5) == $dsci;
    $g->line($foo, $t+($b-$t)/5, $bar, $t+($b-$t)/5, $dsci);
    $g->line($foo, $b-($b-$t)/5, $bar, $b-($b-$t)/5, $dsci);
    $g->fillToBorder($l+$depth, ($t+$b)/2, $dsci, $dsci);
    $g->arc($l+$depth, ($b+$t)/2, $depth*2, ($b-$t), 90, 270, $dsci);
    if ($foo < $bar + 3) {
	$g->fillToBorder(($l+$r)/2+$depth, $t+($b-$t)/5-1, $dsci, $lighter)
	    unless $g->getPixel(($l+$r)/2+$depth, $t+($b-$t)/5-1) == $dsci;
	$g->fillToBorder(($l+$r)/2+$depth, $b-($b-$t)/5+1, $dsci, $darker)
	    unless $g->getPixel(($l+$r)/2+$depth, $b-($b-$t)/5+1) == $dsci;
	$g->fillToBorder(($l+$r)/2, ($t+$b)/2, $dsci, $dsci);
    }
    $g->arc($l+$depth, ($b+$t)/2, $depth*2, ($b-$t), 90, 270, $brci);
    $g->arc($r+$depth, ($b+$t)/2, $depth*2, ($b-$t), 0, 360, $brci);
    $g->line($l+$depth, $t+1, $r+$depth, $t+1, $brci);
    $g->line($l+$depth, $b, $r+$depth, $b, $brci);
    $g->fillToBorder($r+$depth, ($b+$t)/2, $brci, $dsci);
}

sub draw_bar {
	my $self = shift;
	return $self->draw_bar_h(@_) if $self->{rotate_chart};
	my $g = shift;
	my( $l, $t, $r, $b, $dsci, $brci, $neg ) = @_;
	my $fnord = $g->colorAllocate(0,0,0);

	my $depth = $self->{bar_depth};

	my ($lighter, $darker) = ($dsci, $dsci);
	if ($self->{'3d_shading'}) {
	    $lighter = $self->{'3d_highlights'}[$dsci];
	    $darker = $self->{'3d_shadows'}[$dsci];
	}

	$g->line($l+1, $t-$depth, $l+1, $b-$depth, $dsci);
	$g->line($r, $t-$depth, $r, $b-$depth, $dsci);

	$g->arc(($l+$r)/2, $t-$depth, ($r-$l), $depth*2, 180, 360, $dsci);
	$g->arc(($l+$r)/2, $b-$depth, ($r-$l), $depth*2, 0, 180, $dsci);
	# find border
	my $foo = $b-$depth+1;
	++$foo
	    until $foo == $b || $g->getPixel($l+($r-$l)/5,$foo) == $dsci;
	my $bar = $foo-1;
	--$bar
	    until $bar == $foo || $g->getPixel($l+($r-$l)/5,$bar) == $dsci;
	$g->line($l+($r-$l)/5, $bar, $l+($r-$l)/5, $foo, $dsci);
	$g->line($r-($r-$l)/5, $bar, $r-($r-$l)/5, $foo, $dsci);
	$g->fillToBorder(($l+$r)/2, $t-$depth, $dsci, $dsci);
	$g->arc(($l+$r)/2, $b-$depth, ($r-$l), $depth*2, 0, 180, $dsci);
	if ($foo > $bar + 3) {
	    $g->fillToBorder($l+($r-$l)/5-1, ($foo+$bar)/2, $dsci, $lighter)
		unless $g->getPixel($l+($r-$l)/5-1, ($foo+$bar)/2) == $dsci;
	    $g->fillToBorder($r-($r-$l)/5+1, ($foo+$bar)/2, $dsci, $darker)
		unless $g->getPixel($r-($r-$l)/5+1, ($foo+$bar)/2) == $dsci;
	    $g->fillToBorder(($l+$r)/2, ($t+$b)/2, $dsci, $dsci);
	}
	$g->arc(($l+$r)/2, $b-$depth, ($r-$l), $depth*2, 0, 180, $brci);
	$g->arc(($l+$r)/2, $t-$depth, ($r-$l), $depth*2, 0, 360, $brci);
	$g->line($l+1, $t-$depth, $l+1, $b-$depth, $brci);
	$g->line($r, $t-$depth, $r, $b-$depth, $brci);
	$g->fillToBorder(($l+$r)/2, $t-$depth, $brci, $dsci);
}

1;


