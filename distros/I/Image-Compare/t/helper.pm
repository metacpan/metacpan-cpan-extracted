# Helper methods for making images etc

use warnings;
use strict;

sub make_image {
	my $channels = 4;
	unless (ref $_[0]) {
		my %args = @_;
		$channels = $args{channels} || 4;
		@_ = @{$args{pixels}};
	}
	my $img = Imager->new(
		xsize    => scalar(@_),
		ysize    => scalar(@{$_[0]}),
		channels => $channels,
	);
	for my $x (0 .. $#_) {
		for my $y (0 .. $#{$_[0]}) {
			$img->setpixel(x => $x, y => $y, color => [($_[$x][$y]) x 3]);
		}
	}
	return $img;
}

sub approx_equal {
	my $expected = shift;
	my $actual = shift;
	my $max_diff = shift || 2;
	my $diff = abs($expected - $actual);
	if ($diff > $max_diff) {
		warn "Exp: $expected  Act: $actual  Diff: $diff\n";
		return 0;
	}
	return 1;
}

sub verify_image {
	my($name, $img, $expected) = @_;
	for my $x (0 .. $#{$expected}) {
		for my $y (0 .. $#{$expected->[$x]}) {
			my $expect = $expected->[$x][$y];
			unless (ref $expect) {
				$expect = [($expect) x 3];
			}
			my @got = $img->getpixel(x => $x, y => $y)->rgba();
			for my $c (0 .. 2) {
				ok(
          # We do an approximate equality because it's hard to predict how
					# rounding will affect the final result.
					approx_equal($expect->[$c], $got[$c]),
					"$name\[$x, $y\]: " .
					"color element $c, " .
					"got $got[$c], " .
					"expected $expect->[$c]",
				);
			}
		}
	}
}

1;
