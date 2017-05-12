package Image::OpenALPR::PlateResult;

use 5.014000;
use strict;
use warnings;

use overload '""' => sub { shift->plate }, fallback => 1;
use parent qw/Class::Accessor::Fast/;

our $VERSION = '0.001001';

__PACKAGE__->mk_ro_accessors(qw/plate confidence matches_template/);

sub coordinates {
	my $coords = shift->{coordinates};
	return unless $coords;
	my @result = map { [$_->{x}, $_->{y}] } @$coords;
	wantarray ? @result : \@result
}

sub candidates {
	my $cands = shift->{candidates};
	return unless $cands;
	my @result = map { __PACKAGE__->new($_) } @$cands;
	wantarray ? @result : \@result
}

1;
__END__

=encoding utf-8

=head1 NAME

Image::OpenALPR::PlateResult - a license plate, as identified by OpenALPR

=head1 SYNOPSIS

  my $plate = $alpr->recognise('t/example.jpg');
  say $plate;             # ZP36709
  say $plate->plate;      # ZP36709
  say $plate->confidence; # 92.373634
  my @coords     = $plate->coordinates; # [306, 351], [476, 351], [476, 384], [306, 384]
  my @candidates = $plate->candidates;
  say $candidates[1]->plate;      # ZP367O9
  say $candidates[1]->confidence; # 89.812302

=head1 DESCRIPTION

Image::OpenALPR::PlateResult is a class representing a plate
identified by OpenALPR. It offers the following methods:

=over

=item $plate->B<plate>

The plate number that has the highest confidence value (likelihood of
being correct). An object of this class will stringify to the return
value of this method.

=item $plate->B<confidence>

The confidence value of the plate number returned by B<plate>.

=item $plate->B<matches_template>

True if the plate matches the plate pattern chosen via the
B<set_default_region> in L<Image::OpenALPR>, false otherwise (or if no
region was chosen).

=item $plate->B<coordinates>

In list context, returns a four element list representing the vertices
of the license plate, numbered clock-wise from top-left. Each element
is an arrayref with two elements: the X coordinate followed by the Y
coordinate.

In scalar context, returns an arrayref to an array containing the list
described above.

=item $plate->B<candidates>

In list context, returns a list of candidate license numbers, in
decreasing order of confidence. The first element coincides with the
plate/confidence pair returned by the B<plate> and B<confidence>
methods. Each element is a partial Image::OpenALPR::PlateResult object
-- only the B<plate>, B<confidence> and B<matches_template> methods
will return a meaningful value.

=back

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Marius Gavrilescu

This file is part of Image-OpenALPR.

Image-OpenALPR is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Image-OpenALPR is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with Image-OpenALPR.  If not, see <http://www.gnu.org/licenses/>


=cut
