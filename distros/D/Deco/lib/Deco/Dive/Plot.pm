#######################################
# Module  : Deco::Dive::Plot.pm
# Author  : Jaap Voets
# Date    : 02-06-2006
#######################################
package Deco::Dive::Plot;

use strict;
use warnings;
use Carp;
use GD::Graph::lines;
use GD::Graph::bars;

our $VERSION = '0.3';

# some constants used 
use constant DEFAULT_WIDTH  => 600;
use constant DEFAULT_HEIGHT => 400;

# Constructor
sub new {
    my $class = shift;
    my $dive = shift;   

    croak "Please provide a Deco::Dive object for plotting" unless ref($dive) eq 'Deco::Dive';

    my $self = { dive => $dive };
    
    bless $self, $class;
    
    return $self;
}

# plot the depth versus time 
sub depth {
    my $self = shift;
    my %opt  = @_;
    
    # divide the seconds by 60 to get minutes
    my @times = map { $_ / 60 } @{ $self->{dive}->{timepoints} };
    croak "There are no timestamps set for this dive" if ( scalar( @times ) == 0);

    # multiply the depths by -1 to get a nicer picture
    my @depths  = map { -1 * $_ } @{ $self->{dive}->{depths} };
    croak "There are no depth points set for this dive" if ( scalar( @depths ) == 0);

    my $width  = $opt{width}  || DEFAULT_WIDTH;
    my $height = $opt{height} || DEFAULT_HEIGHT;
    my $outfile = $opt{file}  || 'depth.png';

    my $graph =  GD::Graph::lines->new($width, $height);
    $graph->set(
             x_label           => 'Time (minutes)',
             y_label           => 'Depth (meter)',
             title             => 'Depth profile',
	     y_max_value       => 0,	
	    ) or die $graph->error;

    my @data = (\@times, \@depths);

    my $gd = $graph->plot(\@data) or die $graph->error;
    open(IMG, ">$outfile") or die $!;
    binmode IMG;
    print IMG $gd->png;
    close IMG;

}

# plot the percentage saturation of each tissue
# this will be a bar graph using the tissue nr for the x-axis
sub percentage {
	my $self = shift;	
	my %opt  = @_;
	
	# at what point of the dive do we
	my $plot_time;
	if (! defined $opt{time} ) {
		# take the last one
		$plot_time = pop @{ $self->{dive}->{timepoints} };
	} else {
	    # find the corresponding time in seconds in the time array
		my $time = 60 * $opt{time}; # time in minutes
		foreach my $timestamp ( @{ $self->{dive}->{timepoints} } ) {
			if ($timestamp <= $time ) {
				$plot_time = $timestamp;
			}	
		}	
	}
	 
	# get the data
	my @nrs;
	my @percentages;
	foreach my $tissue ( @{ $self->{dive}->{tissues} } ) {
		next if ! defined $tissue;
		# fill the X-axis with the tissue numbers
		my $num  = $tissue->nr;
		push @nrs, $num;	
		# peek inside the Dive object to get the precalculated percentages  
		push @percentages, sprintf('%.0f', $self->{dive}->{info}->{$num}->{$plot_time}->{percentage});
	}
    croak "There is nothing to display for this dive" if ( scalar( @percentages ) == 0);
    
    my $width  = $opt{width}  || DEFAULT_WIDTH;
    my $height = $opt{height} || DEFAULT_HEIGHT;
    my $outfile = $opt{file}  || 'percentage.png';
	
	my $graph =  GD::Graph::bars->new($width, $height);
    $graph->set(
             x_label           => 'Tissue',
             y_label           => 'Percentage',
             title             => 'Tissue saturation',
	     	 y_min_value       => 0,	
	    ) or die $graph->error;

    my @data = (\@nrs, \@percentages);
    my $gd = $graph->plot(\@data) or die $graph->error;
    open(IMG, ">$outfile") or die $!;
    binmode IMG;
    print IMG $gd->png;
    close IMG;
}

# create a graph of the internal pressures of each tissue
# note that you can restrict the tissues displayed by doing something like
# pressures( tissues => [1, 5, 7] )  to get tissues  1, 5 and 7 instead of all of them
sub pressures {
    my $self = shift;
    my %opt  = @_;

    $opt{y_label} = 'Internal Pressure (bar)';
    $self->_info( 'pressure',  %opt );
}

sub nodeco {
    my $self = shift;
    my %opt  = @_;

    $opt{y_label} = 'No deco time (minutes)';
    $self->_info( 'nodeco_time',  %opt );
}


# plot a certain info series for all tissues
# after simulating a dive, there are arrays of information setup
# throught this routine you can get the series of each info
sub _info {
    my $self = shift;
    my $what = shift; # one of nodeco_time, safe_depth, percentage or pressure
    my %opt  = @_;

    # could be we want to restrict to one or more tissues
    my @tissues; 
    if ( defined $opt{tissues} ) {
	@tissues = @{ $opt{tissues} };
    }
    my @times = @{ $self->{dive}->{timepoints} };
    croak "There are no timestamps set for this dive" if ( scalar( @times ) == 0);
    
    # divide the seconds by 60 to get minutes
    my @minutes = map { $_ / 60 } @{ $self->{dive}->{timepoints} };
    
    my $width  = $opt{width}  || DEFAULT_WIDTH;
    my $height = $opt{height} || DEFAULT_HEIGHT;
    my $outfile = $opt{file}  || $what . '.png';
    
    my $y_label = $opt{y_label} || 'Depth (meter)';
    my $graph =  GD::Graph::lines->new($width, $height);
    $graph->set(
		x_label           => 'Time (minutes)',
		y_label           => $y_label,
		title             => "$what profile",
		) or die $graph->error;
    
    my @data;
    push @data, \@minutes; # load the time values

    foreach my $tissue ( @{ $self->{dive}->{tissues} } ) {
    	next if ! defined $tissue;   # first array element is empty
    	my $num = $tissue->nr;
    
    	if (scalar(@tissues) > 0) {
        	# we want to restrict to one or more tissues
        	# so skip the ones that are not in our tissues list
            next if ( ! grep ($num, @tissues) );	
    	}
    	my @y = ();
    	foreach my $time (@times) {
    	    push @y, $self->{dive}->{info}->{$num}->{$time}->{$what};
    	}
    
    	# add the series to the plot data
    	push @data, \@y;
    }
    
    my $gd = $graph->plot(\@data) or die $graph->error;
    open(IMG, ">$outfile") or die $!;
    binmode IMG;
    print IMG $gd->png;
    close IMG;

}

1;


__END__

=head1 NAME

Dive - Simulate a dive and corresponding tissues

=head1 SYNOPSIS

    use Deco::Dive;
    use Deco::Dive::Plot;
    
    my $dive = new Deco::Dive( );
    $dive->load_data_from_file( file => $file);
    $dive->simulate( model => 'haldane');

    my $diveplot = new Deco::Dive::Plot( dive => $dive );
    $diveplot->depth( file => 'depth.png' );
    $diveplot->pressures( file => 'pressures.png' );

=head1 DESCRIPTION

This package will plot the profile of the dive and internal pressures of the tissues of the model.


=head2 METHODS

=over 4

=item new( dive => $dive )

The constructor of the class. Takes a required parameter: a Deco::Dive object.

=item $diveplot->depth( width=> $width, height => $height, file => $file );

Plots the depth versus time graph of the dive. It will default to a file called depth.png in 
the current directory, with a size of 600 x 400 pixels.

=item $diveplot->pressures( width=> $width, height => $height, file => $file );

This method will plot the internal pressures of all the tissues of the model during the dive.

=item $diveplot->percentage( time => $time, width=> $width, height => $height, file => $file );

This function will plot a bar graph of the pertenage of saturation (o fthe allowed value per tissue).
You can specify the time in minutes for the point in the dive where you want to see the percentages for.

=item $diveplot->nodeco( width=> $width, height => $height, file => $file );

This method will plot the no deco time during the dive for each tissue

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<Deco>, L<Deco::Tissue>, L<Deco::Dive>. L<SCUBA::Table::NoDeco> might be of interest to you as well.

In the docs directory you will find an extensive treatment of decompression theory in the file Deco.pdf. A lot of it has been copied from the www.deepocean.net website.

=head1 AUTHOR

Jaap Voets, E<lt>narked@xperience-automatisering.nlE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Jaap Voets

=cut
