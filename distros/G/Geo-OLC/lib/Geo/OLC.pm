# Google's Open Location Code
# https://github.com/google/open-location-code

package Geo::OLC;

use strict;
use warnings;
use List::Util qw(min max);

=head1 NAME

Geo::OLC - API for Google's Open Location Codes

=head1 SYNOPSIS

Open Location Codes are a Google-created method of reducing a
Latitude/Longitude pair to a short string. This module implements the
recommended API from L<https://github.com/google/open-location-code>

    use Geo::OLC qw(encode decode shorten recover_nearest);
    use Geo::OLC qw(:all);

    $code = encode(34.6681375,135.502765625,11);
    # '8Q6QMG93+742'

    $ref = decode('8Q6QMG93+742');
    # @{$ref->{center}} == (34.6681375,135.502765625)

    $short = shorten('8Q6QMG93+742',34.6937048,135.5016142);
    # 'MG93+742' ("...in Osaka")
    $short = shorten('8Q6QMG93+742',34.6788184,135.4987303);
    # '93+742' ("...in Chuo Ward, Osaka")

    $full = recover_nearest('XQP5+',35.0060799,135.6909098);
    # '8Q6QXQP5+' (Kyoto Station, "XQP5+ in Kyoto")

By default, Geo::OLC does not export any functions.

=cut

BEGIN {
	require Exporter;
	our $VERSION = 1.00;
	our @ISA = qw(Exporter);
	our @EXPORT = qw();
	our @EXPORT_OK = qw(is_valid is_short is_full encode decode
		shorten shorten46 recover_nearest _code_digits);
	our %EXPORT_TAGS = (all => \@EXPORT_OK);
}

# set up the radix-20 digits
#
my $radix = '23456789CFGHJMPQRVWX';
my @rchar = split(//,$radix);
my $_i=0;
my %rval = map(($_=>$_i++),@rchar);

# calculate size of grid for each length (lat/lon differ after 10)
#
my @LAT;
my @LON;
my $m = 20;
foreach my $i (2,4,6,8,10) {
	$LAT[$i] = $m;
	$LON[$i] = $m;
	$m /= 20;
}
foreach my $i (11..16) {
	$LAT[$i] = $LAT[$i-1]/5;
	$LON[$i] = $LON[$i-1]/4;
}

=head1 FUNCTIONS

=head2 is_valid($code)

Returns 1 if $code is a valid short, full, or zero-padded OLC.

=cut

sub is_valid {
	my ($code) = @_;
	my $plus = index($code,'+');
	return 0 unless grep($_ == $plus,0,2,4,6,8);
	$code =~ tr/a-z/A-Z/;
	my ($pre,$post) = split(/\+/,$code,2);
	if (index($code,'0') > -1) {
		return 0 if $post ne '';
		$pre =~ tr/0//d;
	}
	if ($pre) {
		return 0 if length($pre) % 2;
		return 0 if $pre !~ /^[$radix]+$/o;
	}
	if ($post) {
		return 0 if length($post) == 1;
		return 0 if $post !~ /^[$radix]+$/o;
	}
	return 0 if $pre.$post eq '';
	return 1;
}

=head2 is_short($code)

Returns 1 if $code is a valid shortened code.

=cut

sub is_short {
	my ($code) = @_;
	return 0 unless is_valid($code);
	return 1 - is_full($code);
}

=head2 is_full($code)

Returns 1 if $code is a valid full-length code, and has lat < 90
and lon < 180.

=cut

sub is_full {
	my ($code) = @_;
	return 0 unless is_valid($code);
	return 0 unless index($code,'+') == 8;
	# check for lat/lon out of range
	# CVXXXXXX+XXX == 89.999975,179.99996875
	return 0 if uc(substr($code,0,1)) gt 'C';
	return 0 if uc(substr($code,1,1)) gt 'V';
	return 1;
}

=head2 encode($lat,$lon,[$len])

Encodes a location as OLC. $len can be 2, 4, 6, 8, 10, or 11-16.
The default $len is 10, which is approximately 13.9x13.9 meters
at the equator; 11 brings that down to 3.5x2.8 meters, and 12
is about 0.9x0.6 meters, so there's not much point in going past
that. I only go to 16 because there's a test case for the Ruby
API that uses 15.

=cut

sub encode {
	my ($lat,$lon,$len) = _norm(@_);
	my $code;
	foreach my $i (0..4) {
		$code .= '+' if $i==4;
		my $tmplat = int($lat / $LAT[($i+1)*2]);
		$code .= $rchar[$tmplat];
		$lat -= $tmplat * $LAT[($i+1)*2];
		my $tmplon = int($lon / $LON[($i+1)*2]);
		$code .= $rchar[$tmplon];
		$lon -= $tmplon * $LON[($i+1)*2];
	}
	if ($len < 10) {
		$code = substr($code,0,$len) . ('0' x (8 - $len)) . '+';
	}elsif ($len > 10) {
		foreach my $i (11..$len) {
			my $gridlat = int($lat / $LAT[$i]);
			$lat -= $gridlat * $LAT[$i];
			my $gridlon = int($lon / $LON[$i]);
			$lon -= $gridlon * $LON[$i];
			$code .= $rchar[$gridlat*4+$gridlon];
		}
	}
	return $code;
}

=head2 decode($code)

Decodes a valid OLC into its location, returned as three pairs of
lat/lon coordinates, plus the length of the original code. 'lower'
and 'upper' are the bounding-box of the OLC grid, and 'center' is
the target location.

  $ref = decode('8Q6QMG93+742');

  $ref = {
    lower => [34.668125,135.50275],
    center=> [34.6681375,135.502765625],
    upper => [34.66815,135.50278125],
    length=> 11,
  };

=cut

sub decode {
	my ($code) = @_;
	if (!is_full($code)) {
		warn "decode(): invalid or short code '$code'\n";
		return undef;
	}
	$code =~ tr/a-z/A-Z/;
	$code =~ tr/+0//d;
	my ($lat,$lon) = (0,0);
	my $len = length($code);
	my $origlen = $len;
	while ($len > 10) {
		my $n = $rval{chop($code)};
		my $latoffset = int($n/4);
		my $lonoffset = $n - $latoffset * 4;
		$lat += $latoffset * $LAT[$len];
		$lon += $lonoffset * $LON[$len];
		$len -= 1;
	}
	foreach my $i (2,4,6,8,10) {
		last if $i > $len;
		my $latchar = substr($code,$i-2,1);
		$lat += $rval{$latchar} * $LAT[$i];
		my $lonchar = substr($code,$i-1,1);
		$lon += $rval{$lonchar} * $LON[$i];
	}
	my $latsize = $LAT[$origlen];
	my $lonsize = $LON[$origlen];
	return {
		lower => [_denorm($lat,$lon)],
		center => [_denorm($lat+$latsize/2,$lon+$lonsize/2)],
		upper => [_denorm($lat+$latsize,$lon+$lonsize)],
		length => $origlen,
	};
}

=head2 shorten($code,$latref,$lonref)

Shortens a valid full-length code based on the reference location;
returns the original code if it can't be shortened.

Note that removing 2 or 8 digits is not necessarily practical, since
there may not be useful names for the area covered, but it's necessary
for API testing. I recommend using shorten46() instead.

=cut

sub shorten {
	return _shorten(@_,8,6,4,2);
}

=head2 shorten46($code,$latref,$lonref)

Shortens a valid full-length code by 4 or 6 digits, based on the
reference location.

=cut

sub shorten46 {
	return _shorten(@_,6,4);
}

# common code used by shorten and shorten46
#
sub _shorten {
	my ($code,$lat,$lon,@lengths) = @_;
	return undef if !is_valid($code);
	return $code if !is_full($code);
	my $ref = decode($code);
	($lat,$lon) = _denorm(_norm($lat,$lon,_code_digits($code)));
	my $distance = max(abs($lat - $ref->{center}->[0]),
		abs($lon - $ref->{center}->[1]));
	foreach my $dist (@lengths) {
		return substr($code,$dist) if $distance < $LON[$dist] * 0.3;
	}
	return $code;
}


=head2 recover_nearest($shortcode,$latref,$lonref)

Converts a shortened OLC back into a full-length code, using the
reference location to supply the missing digits. Note that the
resulting code will not necessarily have the same leading digits
as the reference location, if it's not in the same grid.

=cut

sub recover_nearest {
	my ($code,$lat,$lon) = @_;
	if (!is_valid($code)) {
		warn "recover_nearest(): invalid code '$code'\n";
		return undef;
	}
	return $code if is_full($code);

	($lat,$lon) = _denorm(_norm($lat,$lon));
	my $removed = 8 - index($code,'+');
	my $size = $LAT[$removed];
	my $distance = 9999;
	my $closest = '';
	foreach my $latoff (-$size, 0, $size) {
		foreach my $lonoff (-$size, 0, $size) {
			my $refcode = encode($lat + $latoff,$lon + $lonoff);
			my $testcode = substr($refcode,0,$removed) . $code;
			my $testloc = decode($testcode);
			my $latdiff = $testloc->{center}->[0] - $lat;
			my $londiff = $testloc->{center}->[1] - $lon;
			my $tmpdist = sqrt($latdiff**2 + $londiff**2);
			if ($tmpdist < $distance) {
				$distance = $tmpdist;
				$closest = $testcode;
			}
		}
	}
	return $closest;
}

=head2 _code_digits($code)

Returns number of non-padded digits in a code; used internally by
shorten() and shorten46(), and useful for testing.

=cut

sub _code_digits {
	my ($code) = @_;
	if ($code =~ /(0+)\+$/) {
		return 8 - length($1);
	}else{
		return length($code) - 1;
	}
}

# normalize lat/lon for use in encoding
#
sub _norm {
	my ($lat,$lon,$len) = @_;
	$len ||= 10;
	if ($len <= 10 && $len % 2) {
		warn "invalid code length '$len', setting to 10\n";
		$len = 10;
	}
	$lat = min(90,max(-90,$lat));
	$lat -= $LAT[$len] if $lat == 90;
	while ($lon <= -180) {
		$lon += 360;
	}
	while ($lon >= 180) {
		$lon -= 360;
	}
	return ($lat+90,$lon+180,$len);
}

# restore lat/lon to standard range
#
sub _denorm {
	my ($lat,$lon) = @_;
	return (_defloat($lat-90),_defloat($lon-180));
}

# hide floating-point artifacts; cheaper than using bignums
#
sub _defloat {
	my ($n) = @_;
	$n =~ s/(\.\d+?)(0{4,}[12])$/$1/;
	return $n;
}

=head1 AUTHOR

J Greely, C<< <jgreely at cpan.org> >>

=head1 LOCATIONS

8Q6QMG93+742 is Tenka Gyoza in Osaka, home of the best one-bite
gyoza you'll ever devour multiple plates of ("+742 Dotonbori Osaka").

8FW4V75V+ is the Eiffel Tower ("V75V+ Paris").

86HJW8XV+ is Wrigley Field ("W8XV+8Q Chicago").

849VCRVJ+CHV is a pair of ATMs at Stanford Mall, Palo Alto, CA
("CRVJ+CHV Palo Alto").

=head1 BUGS

The off-by-one-cell code in recover_nearest() is largely untested,
because there are no test cases for it. The "XQP5+ in Kyoto" case
in the synopsis is a simple test I came up with, since most of
Kyoto is in 8Q7Q0000+, but the station is just across the border
in 8Q6Q0000+.

=cut

1;
