package Graphics::ColorDeficiency;

use Graphics::ColorObject;
use Graphics::ColorDeficiency::Data;

@ISA = ('Graphics::ColorObject');
$VERSION = 0.05;

sub Clone {
	my ($self) = @_;
	my ($r,$g,$b) = $self->asRGB;
	return Graphics::ColorDeficiency->newRGB($r, $g, $b);
}

sub asProtanomaly {
	my ($self, $ratio) = @_;
	$ratio = 0.5 unless defined $ratio;
	my $temp = $self->asProtanopia;
	return $self->asMix($temp, $ratio);
}

sub asDeuteranomaly {
	my ($self, $ratio) = @_;
	$ratio = 0.5 unless defined $ratio;
	my $temp = $self->asDeutanopia;
	return $self->asMix($temp, $ratio);
}

sub asTritanomaly {
	my ($self, $ratio) = @_;
	$ratio = 0.5 unless defined $ratio;
	my $temp = $self->asTritanopia;
	return $self->asMix($temp, $ratio);
}

sub asProtanopia {
	return shift->asHash(0);
}

sub asDeutanopia {
	return shift->asHash(1);
}

sub asTritanopia {
	return shift->asHash(2);
}

sub asTypicalMonochrome {
	my ($self) = @_;
	my $val = $self->asGrey2;
	my ($h1, $s1, $v1) = $self->asHSV;
	my $temp = Graphics::ColorObject->newRGB($val, $val, $val);
	my ($h2, $s2, $v2) = $temp->asHSV;
	$temp->setHSV($h2, $s2, ($v1+$v2)/2);
	return $temp;
}

sub asAtypicalMonochrome {
	my ($self, $ratio) = @_;
	$ratio = 0.2 unless defined $ratio;
	my $temp = $self->asTypicalMonochrome;
	return $self->asMix($temp, 1 - $ratio);
}

sub asHash {
	my ($self, $id) = @_;

	my ($r, $g, $b) = $self->asRGB();

	my ($lo_r, $hi_r) = $self->getColorBounds($r);
	my ($lo_r_rat, $hi_r_rat) = $self->getMixRatios($r, $hi_r, $lo_r);

	my ($lo_g, $hi_g) = $self->getColorBounds($g);
	my ($lo_g_rat, $hi_g_rat) = $self->getMixRatios($g, $hi_g, $lo_g);

	my ($lo_b, $hi_b) = $self->getColorBounds($b);
	my ($lo_b_rat, $hi_b_rat) = $self->getMixRatios($b, $hi_b, $lo_b);

	my $lo_col = Graphics::ColorObject->newRGB($lo_r, $lo_g, $lo_b);
	my $hi_col = Graphics::ColorObject->newRGB($hi_r, $hi_g, $hi_b);

	my $from_lo = $Graphics::ColorDeficiency::Data::HASH->{substr(lc $lo_col->asHex,1)}[$id];
	my $from_hi = $Graphics::ColorDeficiency::Data::HASH->{substr(lc $hi_col->asHex,1)}[$id];

	my ($f_l_r, $f_l_g, $f_l_b) = map{hex($_) / 255} ($from_lo =~ /../g);
	my ($f_h_r, $f_h_g, $f_h_b) = map{hex($_) / 255} ($from_hi =~ /../g);

	my $r_out = ($f_l_r * $lo_r_rat) + ($f_h_r * $hi_r_rat);
	my $g_out = ($f_l_g * $lo_g_rat) + ($f_h_g * $hi_g_rat);
	my $b_out = ($f_l_b * $lo_b_rat) + ($f_h_b * $hi_b_rat);

	return Graphics::ColorObject->newRGB($r_out, $g_out, $b_out);
}

sub asMix {
	my ($self, $mix, $rat2) = @_;
	my $rat1 = 1 - $rat2;
	my ($r1, $g1, $b1) = $self->asRGB();
	my ($r2, $g2, $b2) = $mix->asRGB();
	return Graphics::ColorDeficiency->newRGB( ($r1*$rat1)+($r2*$rat2), ($g1*$rat1)+($g2*$rat2), ($b1*$rat1)+($b2*$rat2) );
}

sub getColorBounds {
	my ($self, $val) = @_;
	$val *= 10;
	my ($lo, $hi) = (0, 10);
	for(my $i=0; $i<=10; $i+=2){
		$lo = $i if $val >= $i;
		$hi = $i if $val <= $i && $i < $hi;
	}
	return ($lo/10, $hi/10);
}

sub getMixRatios {
	my ($self, $val, $hi, $lo) = @_;

	return (0.5, 0.5) if ($hi == $val);

	$r1 = ($val - $lo) / 0x33;
	return ($r1, 1-$r1);
}

=head1 NAME

Graphics::ColorDeficiency - Color Deficiency Simulation

=head1 SYNOPSIS

  use Graphics::ColorDeficiency;

  my $col = Graphics::ColorDeficiency->newRGB(0.5, 0.7, 1);

  my $col2 = $col->asProtanopia;

  print $col2->asHex;

=head1 DESCRIPTION

This module allows easy transformation of colors for color deficiency
simulation. All the known and theorhetical color deficiencies are
represented here, with the exception of 4-cone vision (tetrachromatism).

Each of the transformation methods returns a C<Graphics::ColorObject> object,
with the internal color values set. This can then be used to return the 
color in many different formats (see the C<Graphics::ColorObject> manpage).

=head1 METHODS

=over 4

=item C<asProtanopia()>

=item C<asDeutanopia()>

=item C<asTritanopia()>

The three dichromat methods return a C<Graphics::ColorObject> object,
simulated for the three dichromatic vision modes.

=item C<asProtanomaly( $amount )>

=item C<asDeuteranomaly( $amount )>

=item C<asTritanomaly( $amount )>

The three anomalous trichromat methods return a C<Graphics::ColorObject> object,
simulated for the three anomalous trichromatic vision modes. The optional
C<$amount> agrument allows you to specify the severity of anomaly, ranging
from 0 (trichromatic) to 1 (dichromatic). If not specified, it defaults to
0.5.

=item C<asTypicalMonochrome()>

Returns a C<Graphics::ColorObject> object in Typical Monochromatic (Rod
Monochromat) mode.

=item C<asAtypicalMonochrome( $amount )>

Returns a C<Graphics::ColorObject> object in Atypical Monochromatic (Cone 
Monochromat) mode. The amount specified in C<$amount> can vary between 1
(trichromatic) and 0 (monochromatic). The default is 0.2 (four fifths gray).

=item C<Clone()>

Clones the current object, returning a C<Graphics::ColorDeficiency> object
with the same color values as the current object.

=item C<asMix( $color, $amount )>

Returns a new C<Graphics::ColorDeficiency>, consisting of the current color
values, mixed with the values of the C<$color> object. C<$amount> specifies
the amount of the new color to mix in, from 0 (which is equal to 
C<$self.Clone()>), up to 1 (which is equal to C<$color.Clone()>). The mix
is a linear RGB interpolation.

This method is used internally.

=back

=head1 AUTHOR

Copyright (C) 2003 Cal Henderson <cal@iamcal.com>

=head1 SEE ALSO

L<Graphics::ColorObject>

L<http://www.iamcal.com/toys/colors/>

=cut
