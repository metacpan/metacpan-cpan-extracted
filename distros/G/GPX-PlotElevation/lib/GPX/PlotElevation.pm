package GPX::PlotElevation;
# ABSTRACT: create elevation graphs from GPX files


=head1 NAME
  
GPX::PlotElevation - a perl module for creating elevation graphs
  
=head1 SYNOPSIS

use GPX::PlotElevation;
    
my $plot = GPX::PlotElevation->new(
  'gpxfile' => $ARGV[0],
  'output' => 'transalp-2009.png',
  'width' => 40,
  'height' => 10,
);
$plot->calc();
$plot->plot();

=head1 FUNCTIONS

=cut

use strict;
use warnings;

our $VERSION = '1.01'; # VERSION

use IO::File;
use Geo::Gpx;
use Geo::Distance;
use Chart::Gnuplot;

sub new {
	my $invocant = shift();
	my $class = ref($invocant) || $invocant;

	my $self = {
		gpxfile => undef,
		gpxfh => undef,
		gpx => undef,
		title => "Hoehenprofil",
		xlabel => 'Entfernung [km]',
		ylabel => 'Hoehe [m]',
		output => undef,
		fileformat => 'png',
		width => 10,
		height => 7,
		formula => 'hsin',
		_points => [],
		_wp_points => [],
		_total_dist => 0,
		_gpx => undef,
		_geodist => Geo::Distance->new(),
		@_
	};
	bless($self, $class);

	$self->{'_geodist'}->formula($self->{'formula'});
	$self->_load_gpx();
	$self->fileformat($self->{'fileformat'});

	return($self);
}

sub fileformat {
	my $self = shift();
	my $fileformat = shift();

	if($fileformat !~ m/^(png)$/) {
		die("unsupported output fileformat: ".$fileformat);
	}
	$self->{'fileformat'} = $fileformat;
}

sub _load_gpx {
	my $self = shift();
	my $infh;

	if(defined $self->{'gpx'}) {
		$self->{'_gpx'} = Geo::Gpx->new( xml => $self->{'gpx'});
		return();
	}
	if(defined $self->{'gpxfile'}) {
		$infh = IO::File->new("<".$self->{'gpxfile'});
		$self->{'_gpx'} = Geo::Gpx->new( input => $infh );
		$infh->close();
		return();
	}
	if(defined $self->{'gpxfh'}) {
		$self->{'_gpx'} = Geo::Gpx->new( input => $self->{'gpxfh'} );
		return();
	}

	die('No GPX input given.');
}

=head2 calc()

Calculate the distance between points in tracks and assig
the waypoints to trackpoints.

=cut

sub calc {
	my $self = shift();

	$self->_calculate_distances();
	$self->_assign_waypoints();
}

sub _calculate_distances {
	my $self =  shift();
	my $tracks = $self->{'_gpx'}->tracks();
	my $dist;
	my $lastpoint = undef;

	foreach my $track (@$tracks) {
		my $segments = $track->{'segments'};
		foreach my $segment (@$segments) {
			my $points = $segment->{'points'};
			foreach my $point (@$points) {
				if(defined $lastpoint) {
					$dist = $self->{'_geodist'}->distance('kilometer',
						$lastpoint->{'lon'},$lastpoint->{'lat'} => 
							$point->{'lon'},$point->{'lat'});
					$self->{'_total_dist'} += $dist;
					$point->{'dist'} = $self->{'_total_dist'}."";
					$point->{'dist'} =~ s/^(\d+\.\d{2})\d+$/$1/;
				} else {
					$point->{'dist'} = 0;
				}
				$lastpoint = $point;
				push(@{$self->{'_points'}}, $point);
			}
		}
	}
}

# find nearest track point for each waypoint
sub _assign_waypoints {
	my $self = shift();
	my $waypoints = $self->{'_gpx'}->waypoints();
	my $dist;
	my $nearest;
	my $nearest_dist;

	foreach my $wp (@$waypoints) {
		$nearest = undef;
		$nearest_dist = undef;
		foreach my $point (@{$self->{'_points'}}) {
			if( $point->{'lat'} > ( $wp->{'lat'} - 0.05 ) &&
					$point->{'lat'} < ( $wp->{'lat'} + 0.05 ) &&
					$point->{'lon'} > ( $wp->{'lon'} - 0.05 ) &&
					$point->{'lon'} < ( $wp->{'lon'} + 0.05 ) ) {
				$dist = $self->{'_geodist'}->distance('kilometer',
					$point->{'lon'},$point->{'lat'} => $wp->{'lon'},$wp->{'lat'});
				if(!defined $nearest) {
					$nearest = $point;
					$nearest_dist = $dist;
					next;
				}
				if($dist < $nearest_dist) {
					$nearest = $point;
					$nearest_dist = $dist;
				}
			}
		}
		if(defined $nearest) {
			if(!defined $nearest->{'waypoints'}) {
				$nearest->{'waypoints'} = [];
			}
			push(@{$nearest->{'waypoints'}}, $wp);
			push(@{$self->{'_wp_points'}}, $nearest);
		}
	}
}

=head2 print_datfile()

Output a datfile for futher usage. eg. with GNUplot to STDOUT.

=cut

sub print_datfile {
	my $self = shift();

	foreach my $point (@{$self->{'_points'}}) {
		print $point->{'dist'}." ".$point->{'ele'};
		if(defined $point->{'waypoints'}) {
			print ' "'.join(',', map {$_->{'name'}} @{$point->{'waypoints'}}).'"';
		}
		print "\n";
	}
}

=head2 plot()

Generate the plot and write to the output file.

=cut

sub plot {
	my $self = shift();
	my $fileformat = $self->{'fileformat'};
	my $last_point = $self->{'_points'}->[@{$self->{'_points'}} - 1 ];
	my $chart = Chart::Gnuplot->new(
		title => $self->{'title'},
		output => $self->{'output'},
		xlabel => $self->{'xlabel'},
		ylabel => $self->{'ylabel'},
		imagesize => $self->{'width'}.','.$self->{'height'},
		grid => ' xtics ytics x2tics',
		xtics => 'on',
		x2tics => 'on',
		xrange => [0, $last_point->{'dist'}],
		x2range => [0, $last_point->{'dist'}],
	);
	$chart->convert($fileformat);

	my $ele_data = Chart::Gnuplot::DataSet->new(
		title => 'Hoehenprofil',
		style => 'lines',
		xdata => [ map {$_->{'dist'}} @{$self->{'_points'}}],
		ydata => [ map {$_->{'ele'}} @{$self->{'_points'}}],
	);
	foreach my $point (@{$self->{'_wp_points'}}) {
		$chart->label(
			text => join(',', map {$_->{'name'}} @{$point->{'waypoints'}})." (".int($point->{'ele'}).'m)',
			rotate => 45,
			position => $point->{'dist'}.','.$point->{'ele'},
			offset => "1,1",
		);
	}
	my $wp_data = Chart::Gnuplot::DataSet->new(
		title => 'Wegpunkte',
		style => 'points',
		xdata => [ map {$_->{'dist'}} @{$self->{'_wp_points'}}],
		ydata => [ map {$_->{'ele'}} @{$self->{'_wp_points'}}],
		using => '1:2:xticlabels(1)',
		pointsize => 3,
		pointtype => 3,
	);

	$chart->plot2d($ele_data, $wp_data);
}

=head1 SEE ALSO

plot-gpx

=head1 COPYRIGHT & LICENSE

Copyright 2009 Markus Benning <me@w3r3wolf.de, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
