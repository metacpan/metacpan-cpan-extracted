package Image::OpenALPR;

use 5.014000;
use strict;
use warnings;

use Image::OpenALPR::PlateResult;
use JSON::MaybeXS qw/decode_json/;
use XSLoader;

BEGIN {
	our $VERSION = '0.001001';
	XSLoader::load('Image::OpenALPR', $VERSION);
	*initialise         = \&initialize;
	*is_loaded          = \&isLoaded;
	*get_version        = \&getVersion;
	*set_country        = \&setCountry;
	*set_prewarp        = \&setPrewarp;
	*set_default_region = \&setDefaultRegion;
	*set_top_n          = \&setTopN;
}

sub new {
	my $alpr = initialise (@_[1..$#_]);
	die "Failed to load OpenALPR\n" unless $alpr->is_loaded;
	$alpr
}

sub recognise {
	my ($alpr, $data) = @_;
	my $json = ref $data eq 'SCALAR' ? $alpr->recognizeArray($$data) : $alpr->recognizeFile($data);
	$json = decode_json $json;
	my @plates = map { Image::OpenALPR::PlateResult->new($_) } @{$json->{results}};
	wantarray ? @plates : shift @plates
}

sub DESTROY { shift->dispose }

package AlprPtr;
our @ISA = qw/Image::OpenALPR/;

1;
__END__

=encoding utf-8

=head1 NAME

Image::OpenALPR - Perl binding for Automatic License Plate Recognition library

=head1 SYNOPSIS

  use Image::OpenALPR;
  my $alpr = Image::OpenALPR->new('eu');
  $alpr->get_version; # 2.2.4
  my (@plates) = $alpr->recognise('many_plates.jpg');
  say 'Plates found: ', join ' ', map { $_->plate } @plates;

  $alpr->set_top_n(2);
  my $data = read_file 'one_plate.gif';
  my $a_plate  = $alpr->recognise(\$data);
  my @cnd = @{$a_plate->candidates};
  say $cnd[0]->plate, ' ', $cnd[0]->confidence;
  say $cnd[1]->plate, ' ', $cnd[1]->confidence;

=head1 DESCRIPTION

OpenALPR is an automatic license plate recognition library that
extracts license plate numbers from images.

The following methods are available:

=over

=item Image::OpenALPR->B<new>(I<$country>, I<$config>, I<$runtime_data>)

Takes one mandatory argument (the country rules to use, such as C<eu>
or C<us>) and two optional arguments: a path to the configuration
file, and a path to the runtime_data directory.

Returns a new Image::OpenALPR instance. If initialisation fails (for
example, if the chosen country is not available) an exception is
thrown.

=item $alpr->B<recognise>(I<$file>)

=item $alpr->B<recognise>(I<\$data>)

Takes a path to an image file or a reference to the contents of an
image file and tries to find license plates in the image. In list
context, it returns a list of L<Image::OpenALPR::PlateResult> objects,
one for each plate found. In scalar context it returns only one such
object (the first plate found), or undef if no plates were found.

=item $alpr->B<get_version>

=item $alpr->B<getVersion>

Returns the version of the OpenALPR library.

=item $alpr->B<set_country>(I<$country>)

=item $alpr->B<setCountry>(I<$country>)

Changes the country rules in use.

=item $alpr->B<set_prewarp>(I<$prewarp>)

=item $alpr->B<setPrewarp>(I<$prewarp>)

Sets the camera calibration values, as obtained from the
C<openalpr-utils-calibrate> utility. Can also be set in the
configuration file.

=item $alpr->B<set_default_region>(I<$region>)

=item $alpr->B<setDefaultRegion>(I<$region>)

Sets the expected region for pattern matching. This improves accuracy.
The B<matches_template> flag is set on plates that match this pattern.

=item $alpr->B<set_top_n>(I<$n>)

=item $alpr->B<setTopN>(I<$n>)

Sets the maximum number of candidates to return for one plate. Default
is 10.

=back

=head1 SEE ALSO

L<http://www.openalpr.com>, L<https://github.com/openalpr/openalpr>

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
