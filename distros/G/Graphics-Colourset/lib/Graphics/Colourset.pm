package Graphics::Colourset;
use strict;
use warnings;

=head1 NAME

Graphics::Colourset - create sets of colours.

=head1 VERSION

This describes version B<0.02> of Graphics::Colourset.

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use Graphics::Colourset;

    my $cs1 = Graphics::Colourset->new(hue=>60, shade=>1);

    my $col_str = $cs1->as_hex_string('foreground');

    my $cs2 = $cs1->new_alt_colourset(shade=>4);

    my @colsets = $cs1->new_alt_coloursets(3);

=head1 DESCRIPTION

This module generates the colour definitions of a set of colours
suitable for using as the basis of a colour-scheme for an X-Windows
window-manager. They can also be used for CSS colour descriptions for
Web-pages.  The colours are defined as the usual "hex string",
or as the more recent "rgb string".

The aim of this is to avoid having to generate harmonious colour schemes
by hand but to input a minimum number of parameters and to create all
the colours from that.

=head1 DETAILS

=head2 Coloursets

A "colourset" is a set of five colours, suitable for defining one type
of component in a window-manager or web-site "theme" or "colour scheme".
All colours in a colourset have the same hue, but have different
saturation and value (different "strengths") in keeping with their
different roles.

They are oriented towards being used for generating colours for buttons
and borders.

=over

=item background

The background colour is the main colour of the colourset, to be used
for the background of the "component" (whatever that may be).

=item topshadow

The topshadow colour is a colour slightly lighter than the background
colour, suitable for using to define a "top shadow" colour.

=item bottomshadow

The bottomshadow colour is a colour slightly darker than the background
colour, suitable for using to define a "bottom shadow" colour.

=item foreground

The foreground colour is the colour designated to be used for the
foreground, for text and the like.  It is either much lighter or much
darker than the background colour, in order to contrast suitably.

=item foreground_inactive

The "inactive" foreground colour is a colour which is intended to be
used for things which are "greyed out", or not active. It is a colour
which contrasts with the background, but not as much as the "foreground"
colour.

=back

There are two parameters which determine the colours of a colourset.

=over

=item hue

The hue in a 360 degree colour wheel.  As a special tweak, if the hue
equals 360, it is taken to be no hue at all (grey).  This doesn't
actually lose any hues, since 360 is normally exactly the same as zero
(red).

=item shade

The general "lightness" of the background.  This is a range from 1 to 4, with 1
being the darkest and 4 being the lightest.  This also determines the
foreground colour, since a dark background will need a light foreground and
visa-versa.

If the shade is outside this range, a random shade will be picked.

=back

=head2 Base and Alternative Coloursets

The "base" colourset is considered to be the main colourset; additional
coloursets can be generated which are related to the base colourset in a
contrasting-but-harmonious way.

One test for the harmoniousness is to compare two coloursets and decide
whether they would be "ugly" together.  This is done in a rule-of-thumb
way, which isn't perfect.

=cut

use Graphics::ColorObject;

=head1 CLASS METHODS

=head2 new

Create a new colourset, given an input hue, and foreground/background
disposition.

$my colset = Graphics::Colourset->new(
	hue=>$hue,
	shade=>1,
    );

=cut

sub new {
    my $class = shift;
    my %parameters = @_;
    my $self = bless ({%parameters}, ref ($class) || $class);
    $self->{hue} ||= 0;
    $self->{shade} = 0 if !defined $self->{shade};

    if ($self->{shade} < 1 or $self->{shade} > 4)
    {
	$self->{shade} = int(rand(4)) + 1;
    }

    if ($self->{hue} == 360) # make it grey
    {
	if ($self->{shade} == 1) # darkest
	{
	    $self->{foreground} =
		Graphics::ColorObject->new_HSV([0, 0, 0.99]);
	    $self->{foreground_inactive} =
		Graphics::ColorObject->new_HSV([0, 0, 0.70]);
	    $self->{background} =
		Graphics::ColorObject->new_HSV([0, 0, 0.20]);
	    $self->{topshadow} =
		Graphics::ColorObject->new_HSV([0, 0, 0.30]);
	    $self->{bottomshadow} =
		Graphics::ColorObject->new_HSV([0, 0, 0.10]);
	}
	elsif ($self->{shade} == 2)
	{
	    $self->{foreground} =
		Graphics::ColorObject->new_HSV([0, 0, 0.95]);
	    $self->{foreground_inactive} =
		Graphics::ColorObject->new_HSV([0, 0, 0.80]);
	    $self->{background} =
		Graphics::ColorObject->new_HSV([0, 0, 0.50]);
	    $self->{topshadow} =
		Graphics::ColorObject->new_HSV([0, 0, 0.70]);
	    $self->{bottomshadow} =
		Graphics::ColorObject->new_HSV([0, 0, 0.30]);
	}
	elsif ($self->{shade} == 3)
	{
	    $self->{foreground} =
		Graphics::ColorObject->new_HSV([0, 0, 0.05]);
	    $self->{foreground_inactive} =
		Graphics::ColorObject->new_HSV([0, 0, 0.60]);
	    $self->{background} =
		Graphics::ColorObject->new_HSV([0, 0, 0.75]);
	    $self->{topshadow} =
		Graphics::ColorObject->new_HSV([0, 0, 0.85]);
	    $self->{bottomshadow} =
		Graphics::ColorObject->new_HSV([0, 0, 0.65]);
	}
	elsif ($self->{shade} == 4) # lightest
	{
	    $self->{foreground} =
		Graphics::ColorObject->new_HSV([0, 0, 0.20]);
	    $self->{foreground_inactive} =
		Graphics::ColorObject->new_HSV([0, 0, 0.55]);
	    $self->{background} =
		Graphics::ColorObject->new_HSV([0, 0, 0.88]);
	    $self->{topshadow} =
		Graphics::ColorObject->new_HSV([0, 0, 0.96]);
	    $self->{bottomshadow} =
		Graphics::ColorObject->new_HSV([0, 0, 0.78]);
	}
    }
    else # coloured
    {
	if ($self->{shade} == 1) # darkest
	{
	    $self->{foreground} =
		Graphics::ColorObject->new_HSV([$self->{hue},
					       0.10, 0.99]);
	    $self->{foreground_inactive} =
		Graphics::ColorObject->new_HSV([$self->{hue},
					       0.30, 0.80]);
	    $self->{background} =
		Graphics::ColorObject->new_HSV([$self->{hue},
					       0.90, 0.35]);
	    $self->{topshadow} =
		Graphics::ColorObject->new_HSV([$self->{hue},
					       0.50, 0.45]);
	    $self->{bottomshadow} =
		Graphics::ColorObject->new_HSV([$self->{hue},
					       0.90, 0.25]);
	}
	elsif ($self->{shade} == 2)
	{
	    $self->{foreground} =
		Graphics::ColorObject->new_HSV([$self->{hue},
					       0, 0.99]);
	    $self->{foreground_inactive} =
		Graphics::ColorObject->new_HSV([$self->{hue},
					       0.30, 0.90]);
	    $self->{background} =
		Graphics::ColorObject->new_HSV([$self->{hue},
					       0.80, 0.50]);
	    $self->{topshadow} =
		Graphics::ColorObject->new_HSV([$self->{hue},
					       0.50, 0.65]);
	    $self->{bottomshadow} =
		Graphics::ColorObject->new_HSV([$self->{hue},
					       0.80, 0.45]);
	}
	elsif ($self->{shade} == 3)
	{
	    if ($self->{hue} > 220 && $self->{hue} < 280)
	    {
		# blue/purple are too dark to deal with this
		$self->{foreground} =
		    Graphics::ColorObject->new_HSV([$self->{hue},
						   0.99, 0.05]);
		$self->{foreground_inactive} =
		    Graphics::ColorObject->new_HSV([$self->{hue},
						   0.90, 0.60]);
		$self->{background} =
		    Graphics::ColorObject->new_HSV([$self->{hue},
						   0.50, 0.85]);
		$self->{topshadow} =
		    Graphics::ColorObject->new_HSV([$self->{hue},
						   0.50, 0.95]);
		$self->{bottomshadow} =
		    Graphics::ColorObject->new_HSV([$self->{hue},
						   0.70, 0.75]);
	    }
	    else
	    {
		$self->{foreground} =
		    Graphics::ColorObject->new_HSV([$self->{hue},
						   0.99, 0.05]);
		$self->{foreground_inactive} =
		    Graphics::ColorObject->new_HSV([$self->{hue},
						   0.90, 0.60]);
		$self->{background} =
		    Graphics::ColorObject->new_HSV([$self->{hue},
						   0.75, 0.75]);
		$self->{topshadow} =
		    Graphics::ColorObject->new_HSV([$self->{hue},
						   0.45, 0.85]);
		$self->{bottomshadow} =
		    Graphics::ColorObject->new_HSV([$self->{hue},
						   0.70, 0.65]);
	    }
	}
	elsif ($self->{shade} == 4) # lightest
	{
	    $self->{foreground} =
		Graphics::ColorObject->new_HSV([$self->{hue},
					       0.90, 0.20]);
	    $self->{foreground_inactive} =
		Graphics::ColorObject->new_HSV([$self->{hue},
					       0.40, 0.55]);
	    $self->{background} =
		Graphics::ColorObject->new_HSV([$self->{hue},
					       0.30, 0.92]);
	    $self->{topshadow} =
		Graphics::ColorObject->new_HSV([$self->{hue},
					       0.20, 0.97]);
	    $self->{bottomshadow} =
		Graphics::ColorObject->new_HSV([$self->{hue},
					       0.40, 0.75]);
	}
    }
    return ($self);
} # new

=head2 make_n_coloursets

my @colsets = Graphics::Colourset::make_n_coloursets(number=>$num,
    shades=>[1,0,3,4],
    hues=>[10,50,undef,undef]);

Make $num coloursets, based on the given shades and hues; if a shade is
zero or undef, a random shade will be chosen; if a hue is undef, a random
hue will be chosen.  The coloursets will be generated, but checked with
is_ugly to ensure that it isn't ugly.  They will also be checked to make
sure that they aren't the same as the other coloursets.

Note that larger numbers will take longer and be more difficult to generate.

=cut
sub make_n_coloursets {
    my %args = (
	number=>1,
	shades=>undef,
	hues=>undef,
	@_
    );

    my @colsets = ();
    while (!@colsets)
    {
	@colsets = attempt_n_coloursets(%args);
    }
    return @colsets;
} # make_n_coloursets

=head2 attempt_n_coloursets

my @colsets = Graphics::Colourset::make_n_coloursets(number=>$num,
    shades=>[1,0,3,4],
    hues=>[10,50,undef,undef]);

Make $num coloursets, based on the given shades and hues; if a shade is
zero or undef, a random shade will be chosen; if a hue is undef, a random
hue will be chosen.  The coloursets will be generated, but checked with
is_ugly to ensure that it isn't ugly.  They will also be checked to make
sure that they aren't the same as the other coloursets.

If a colourset is ugly, an empty set is returned.

Note that larger numbers will take longer and be more difficult to generate.

=cut
sub attempt_n_coloursets {
    my %args = (
	number=>1,
	shades=>undef,
	hues=>undef,
	@_
    );

    my $num_colsets = $args{number};

    # set an array of shades; by default zero means random
    my @shades = ();
    for (my $i = 0; $i < $num_colsets; $i++)
    {
	$shades[$i] = 0;
    }
    # if shades are passed in, use them
    if (defined $args{shades})
    {
	for (my $i = 0; $i < @{$args{shades}}; $i++)
	{
	    $shades[$i] = $args{shades}->[$i];
	}
    }
    # set an array of hues; by default undefined means random
    my @hues = ();
    for (my $i = 0; $i < $num_colsets; $i++)
    {
	$hues[$i] = undef;
    }
    # if hues are passed in, use them
    if (defined $args{hues})
    {
	for (my $i = 0; $i < @{$args{hues}}; $i++)
	{
	    $hues[$i] = $args{hues}->[$i];
	}
    }

    my @styles = qw(complement splitcomp triad tetrad analog);
    my %intervals = (
	complement=>[0, 180],
	splitcomp=>[0, 180-24, 180+24],
	triad=>[0, 120, 240],
	tetrad=>[0, 90, 180, 240],
	analog=>[0, -30, 30, -60, 60],
	mono=>[0, 0, 0, 0],
    );
    # add mono to the styles if there are few enough coloursets
    if ($num_colsets <= @{$intervals{mono}})
    {
	push @styles, 'mono';
    }

    my $style = $styles[int(rand(@styles))];
    my $num_intervals = @{$intervals{$style}};
    print STDERR "style:$style, num_intervals:$num_intervals\n";
    if ($style eq 'mono')
    {
	# set the shades for mono, dark to light
	for (my $i = 0; $i < $num_colsets; $i++)
	{
	    $shades[$i] = $i + 1;
	}
    }

    my @colsets = ();
    my $basehue = (defined $hues[0] ? $hues[0] : int(rand(360)));

    while (@colsets < $num_colsets)
    {
	my $next_cs;
	# get the index of the next colset
	my $ind = @colsets; 
	$shades[$ind] = int(rand(4)) + 1 if $shades[$ind] == 0;
	while ($ind >= $num_intervals
	       and $shades[$ind] == $shades[$ind - $num_intervals])
	{
	    $shades[$ind] = int(rand(4)) + 1;
	}
	my $shade = $shades[$ind];
	my $hue = $hues[$ind];
	if (!defined $hue)
	{
	    if ($ind < $num_intervals)
	    {
		$hue = $basehue + $intervals{$style}->[$ind];
	    }
	    else
	    {
		$hue = $basehue + $intervals{$style}->[$ind %
		    $num_intervals];
	    }
	    $hue += 360 if ($hue < 0);
	    $hue -= 360 if ($hue > 360);
	}
	print STDERR "[$ind] HUE: $hue, SHADE: $shade\n";
	$next_cs = Graphics::Colourset->new(hue=>$hue, shade=>$shade);
	if ($ind > 0 and $next_cs->is_ugly($colsets[$ind - 1]))
	{
	    return ();
	}
	push @colsets, $next_cs;
    }

    return @colsets;
} # attempt_n_coloursets

=head1 OBJECT METHODS

=head2 as_hex_string

my $colstr = $self->as_hex_string('foreground');

Return the given colour as a hex colour string
such as #99FF00

=cut

sub as_hex_string {
    my $self = shift;
    my $colour = shift;

    my $hex = $self->{$colour}->as_RGBhex();
    return "#$hex";
} # as_hex_string

=head2 as_rgb_string

my $colstr = $self->as_rgb_string('foreground');

Return the given colour as an X colour string
such as rgb:99/FF/00

=cut

sub as_rgb_string {
    my $self = shift;
    my $colour = shift;

    my ($r, $g, $b) = @{$self->{$colour}->as_RGB255()};
    return sprintf("rgb:%02X/%02X/%02X", $r, $g, $b);
} # as_rgb_string

=head2 equals

Checks if the given colourset equals the passed-in one.

if ($colset->equals($other_colset))
{
    ...
}

=cut
sub equals {
    my $self = shift;
    my $colset2 = shift;

    return ($self->{hue} == $colset2->{hue}
	&& $self->{shade} == $colset2->{shade});
} # equals

=head2 is_ugly

my $ret = $colset1->is_ugly($colset2);

Compares two coloursets and declares whether they would be ugly
together.  This is naturally a subjective assessment on the part of
the author, but hopefully helpful.

=cut
sub is_ugly {
    my $colset1 = shift;
    my $colset2 = shift;

    if (($colset1->{hue} == 360
	 && $colset2->{hue} >= 50
	 && $colset2->{hue} <= 80)
	|| ($colset2->{hue} == 360
	    && $colset1->{hue} >= 50
	    && $colset1->{hue} <= 80))
    {
	# yellow doesn't go with grey
	return 1;
    }
    elsif (($colset1->{hue} == 360
	 && $colset2->{hue} > 10
	 && $colset2->{hue} < 50
	 && $colset2->{shade} > 1)
	|| ($colset2->{hue} == 360
	    && $colset1->{hue} > 10
	    && $colset1->{hue} < 50
	    && $colset1->{shade} > 1))
    {
	# orange only looks good if it's dark
	return 1;
    }
    elsif ($colset1->{hue} == 360
	|| $colset2->{hue} == 360)
    {
	# everything else goes with grey
	return 0;
    }
    # all colours within 30 degrees of each other look good
    my $hdiff = abs($colset1->{hue} - $colset2->{hue});
    if ($hdiff <= 30)
    {
	return 0;
    }
    
    if (($colset1->{hue} >= 0
	 && $colset1->{hue} < 10
	 && $colset1->{shade} == 4
	 && $colset2->{hue} >= 60
	 && $colset2->{hue} < 70
	 && $colset2->{shade} != 4)
	|| ($colset2->{hue} >= 0
	    && $colset2->{hue} < 10
	    && $colset2->{shade} == 4
	    && $colset1->{hue} >= 60
	    && $colset1->{hue} < 70
	    && $colset1->{shade} != 4))
    {
	# rose doesn't go with yellow or green
	return 1;
    }
    if (($colset1->{hue} > 10
	 && $colset1->{hue} <= 40
	 && $colset1->{shade} > 1
	 && $colset1->{shade} < 4
	 && $colset2->{hue} > 60
	 && $colset2->{hue} <= 100)
	|| ($colset2->{hue} > 10
	    && $colset2->{hue} <= 40
	    && $colset2->{shade} > 1
	    && $colset2->{shade} < 4
	    && $colset1->{hue} > 60
	    && $colset1->{hue} <= 100))
    {
	# orange doesn't go with green
	return 1;
    }
    if (($colset1->{hue} >= 270
	 && $colset1->{hue} < 280
	 && $colset2->{hue} >= 330
	 && $colset2->{hue} < 340
	 && $colset2->{shade} > 1)
	|| ($colset2->{hue} >= 270
	    && $colset2->{hue} < 280
	    && $colset1->{hue} >= 330
	    && $colset1->{hue} < 340
	    && $colset1->{shade} > 1))
    {
	# purple doesn't go with pinky-red
	return 1;
    }
    if (($colset1->{hue} >= 280
	 && $colset1->{hue} < 360
	 && (($colset2->{hue} >= 340
	      && $colset2->{hue} < 360)
	     || ($colset2->{hue} >= 0
		 && $colset2->{hue} < 50))
	)
	|| ($colset2->{hue} >= 280
	    && $colset2->{hue} < 360
	    && (($colset1->{hue} >= 340
		 && $colset1->{hue} < 360)
		|| ($colset1->{hue} >= 0
		    && $colset1->{hue} < 50))
	   )
       )
    {
	# violet doesn't go with pink/red
	return 1;
    }
    if (($colset1->{hue} > 10
	 && $colset1->{hue} <= 40
	 && ($colset1->{shade} == 2
	     || $colset1->{shade} == 3)
	 && $colset2->{hue} > 100
	 && $colset2->{hue} <= 130)
	|| ($colset2->{hue} > 10
	    && $colset2->{hue} <= 40
	    && ($colset2->{shade} == 2
		|| $colset2->{shade} == 3)
	    && $colset1->{hue} > 100
	    && $colset1->{hue} <= 130))
    {
	# orange doesn't go with green
	return 1;
    }
    if (($colset1->{hue} >= 260
	 && $colset1->{hue} < 280
	 && (($colset2->{hue} >= 350
	      && $colset2->{hue} < 360)
	     || ($colset2->{hue} >= 0
		 && $colset2->{hue} <= 10)))
	|| ($colset2->{hue} >= 260
	    && $colset2->{hue} < 280
	    && (($colset1->{hue} >= 350
		 && $colset1->{hue} < 360)
		|| ($colset1->{hue} >= 0
		    && $colset1->{hue} <= 10))))
    {
	# purple doesn't go with tomato-red or rose
	return 1;
    }
    if (($colset1->{hue} >= 280
	 && $colset1->{hue} < 350
	 && $colset2->{hue} >= 10
	 && $colset2->{hue} < 80)
	|| ($colset2->{hue} >= 280
	    && $colset2->{hue} < 350
	    && $colset1->{hue} >= 10
	    && $colset1->{hue} < 80))
    {
	# purple & pink don't go with orange, yellow or green
	return 1;
    }
    if (($colset1->{hue} > 10
	 && $colset1->{hue} < 90
	 && $colset1->{shade} != 1
	 && $colset2->{hue} > 130
	 && $colset2->{hue} < 210
	 && $colset2->{shade} != 1)
	|| ($colset2->{hue} > 10
	    && $colset2->{hue} < 90
	    && $colset2->{shade} != 1
	    && $colset1->{hue} > 130
	    && $colset1->{hue} < 210
	    && $colset1->{shade} != 1))
    {
	# orange & yellow don't go with green or cyan
	return 1;
    }
    if (($colset1->{hue} > 50
	 && $colset1->{hue} < 70
	 && $colset1->{shade} == 1
	 && $colset2->{hue} > 130
	 && $colset2->{hue} < 210
	 && $colset2->{shade} != 1)
	|| ($colset2->{hue} > 50
	    && $colset2->{hue} < 70
	    && $colset2->{shade} == 1
	    && $colset1->{hue} > 130
	    && $colset1->{hue} < 210
	    && $colset1->{shade} != 1))
    {
	# Khaki doesn't go with green or cyan
	return 1;
    }
    if (($colset1->{hue} > 150
	 && $colset1->{hue} < 200
	 && $colset2->{hue} > 270
	 && $colset2->{hue} < 320)
	|| ($colset2->{hue} > 150
	    && $colset2->{hue} < 200
	    && $colset1->{hue} > 270
	    && $colset1->{hue} < 320))
    {
	# turquoise/cyan doesn't go with orchid
	return 1;
    }
    if (($colset1->{hue} > 240
	 && $colset1->{hue} < 290
	 && $colset2->{hue} > 0
	 && $colset2->{hue} < 50)
	|| ($colset2->{hue} > 240
	    && $colset2->{hue} < 290
	    && $colset1->{hue} > 0
	    && $colset1->{hue} < 50))
    {
	# blue/purple doesn't go with orange
	return 1;
    }
    if ($colset1->{hue} >= 290
	&& $colset1->{hue} < 350
	&& $colset2->{hue} >= 50
	&& $colset2->{hue} < 110)
    {
	# violet/pink doesn't go with yellow/green
	return 1;
    }
    
    # glary colour don't do well with dull or pale
    # unless they're the same hue
    if ((($colset1->{shade} == 3
	 && ($colset1->{hue} < 200
	     || $colset1->{hue} > 280)
	 && ($colset2->{shade} == 2
	     || $colset2->{shade} == 4))
	|| ($colset2->{shade} == 3
	    && ($colset2->{hue} < 200
		|| $colset2->{hue} > 280)
	    && ($colset1->{shade} == 2
		|| $colset1->{shade} == 4)))
	&& $colset1->{hue} != $colset2->{hue})
    {
	return 1;
    }
    # pink doesn't go with green or yellow, even though red does
    if (($colset1->{hue} >= 0
	 && $colset1->{hue} < 30
	 && $colset1->{shade} == 4
	 && $colset2->{hue} > 60
	 && $colset2->{hue} <= 120
	 && $colset2->{shade} != 4)
	|| ($colset2->{hue} >= 0
	    && $colset2->{hue} < 30
	    && $colset2->{shade} == 4
	    && $colset1->{hue} > 60
	    && $colset1->{hue} <= 120
	    && $colset1->{shade} != 4))
    {
	return 1;
    }
    # pale orange doesn't go with green
    if (($colset1->{hue} >= 30
	 && $colset1->{hue} < 50
	 && $colset1->{shade} == 4
	 && $colset2->{hue} > 90
	 && $colset2->{hue} <= 130
	 && $colset2->{shade} != 4)
	|| ($colset2->{hue} >= 30
	    && $colset2->{hue} < 50
	    && $colset2->{shade} == 4
	    && $colset1->{hue} > 90
	    && $colset1->{hue} <= 130
	    && $colset1->{shade} != 4))
    {
	return 1;
    }
    # glary red don't like khaki
    if (($colset1->{hue} >= 0
	 && $colset1->{hue} < 30
	 && $colset1->{shade} == 3
	 && $colset2->{hue} > 50
	 && $colset2->{hue} < 70
	 && $colset2->{shade} != 3)
	|| ($colset2->{hue} >= 0
	    && $colset2->{hue} < 30
	    && $colset2->{shade} == 3
	    && $colset1->{hue} > 50
	    && $colset1->{hue} < 70
	    && $colset1->{shade} != 3))
    {
	return 1;
    }

    return 0;
} # is_ugly

=head1 REQUIRES

    Graphics::ColorObject
    Getopt::Long
    Getopt::ArgvFile
    Pod::Usage
    Test::More

=head1 INSTALLATION

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Or, if you're on a platform (like DOS or Windows) that doesn't like the
"./" notation, you can do this:

   perl Build.PL
   perl Build
   perl Build test
   perl Build install

In order to install somewhere other than the default, such as
in a directory under your home directory, like "/home/fred/perl"
go

   perl Build.PL --install_base /home/fred/perl

as the first step instead.

This will install the files underneath /home/fred/perl.

You will then need to make sure that you alter the PERL5LIB variable to
find the modules, and the PATH variable to find the script.

Therefore you will need to change:
your path, to include /home/fred/perl/script (where the script will be)

	PATH=/home/fred/perl/script:${PATH}

the PERL5LIB variable to add /home/fred/perl/lib

	PERL5LIB=/home/fred/perl/lib:${PERL5LIB}

=head1 SEE ALSO

perl(1).

=head1 BUGS

Please report any bugs or feature requests to the author.

=head1 AUTHOR

    Kathryn Andersen (RUBYKAT)
    perlkat AT katspace dot com
    http://www.katspace.com

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2005 by Kathryn Andersen

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Graphics::Colourset
__END__
