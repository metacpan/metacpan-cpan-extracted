package Image::ColorCollection;


use 5.006;
use strict;
use warnings FATAL => 'all';
use Data::Dumper;
use Imager;
use Imager::Fill;
use List::Util qw(sum);

our $VERSION = '0.02';

sub new {
	my $class = shift;
	my $self = {
		centroid => {
			r => int(rand(255)),
			g => int(rand(255)),
			b => int(rand(255)),
		},
		colors => []
	};
	bless $self, $class;
	return $self;
}
#store the centroid here..
#store belongstome
sub getCentroid {
	my $class = shift;
	return $class->{centroid};
}
sub addColor {
	my ($class, $c) = @_;
	push @{$class->{colors}}, $c;
}
sub updateCentroid {
		my ($class, $c) = @_;
		my $shift = 0;
		my @colors = @{$class->{colors}};
		if(scalar(@colors) == 0)
		{
			return 0;
		}
		my $rAvg = int(sum(map {$_->{r}} @colors)/@colors);
		$shift += $class->{centroid}->{r} - $rAvg;
		
		my $gAvg = int(sum(map {$_->{g}} @colors)/@colors);
		$shift += $class->{centroid}->{g} - $gAvg;
			
		my $bAvg = int(sum(map {$_->{b}} @colors)/@colors);
		$shift += $class->{centroid}->{b} - $bAvg;
		
		$class->{centroid} = {
				r => int($rAvg),
				g => int($gAvg),
				b => int($bAvg),
		};
		return $shift;
}

sub clear {
	my ($class, $c) = @_;
	$class->{colors} = [];
}

1; # End of Image::ColorCollection
__END__


=head1 NAME

Image::ColorCollection - Internal Class to represent centroids.

=head1 VERSION

Version 0.01
