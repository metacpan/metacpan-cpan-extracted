#######################################
# Module  : Deco::Dive::Table.pm
# Author  : Jaap Voets
# Date    : 10-10-2006
#######################################
package Deco::Dive::Table;

use strict;
use warnings;
use Carp;

use constant INITIAL_NODECO => 1000000;
our $VERSION = '0.2';


# Constructor
sub new {
    my $class = shift;
    my $dive = shift;   

    croak "Please provide a Deco::Dive object for plotting" unless ref($dive) eq 'Deco::Dive';

    my $self = { dive => $dive };
		
    # depth in meters, we will use these for the table
    # can be overridden by ->setdepths
    $self->{depths} = [10, 12, 14, 16, 18, 20, 24, 27, 30, 33, 36, 40, 42, 45, 50];
    
    # the controlling tissue
    $self->{controlling_tissue} = undef;
    $self->{excess_pressure_step_size} = 0.05;  # in bar, which is 1/2 meter
    $self->{start_pressure} = undef;
    $self->{end_pressure} = undef;
    # place to store our numbers
    $self->{nodeco_table} = undef;
    $self->{table} = undef;
    bless $self, $class;
    
    return $self;
}

# what tissue controls the repetitive group behaviour?
sub controlling_tissue {
    my $self = shift;
    my $tissue_num = shift;

    if (defined $tissue_num) {
	# we want to set the tissue
	my $found = 0;
	# check if it really exists
	foreach my $tissue ( @{ $self->{dive}->{tissues} } ) {
	    next if ! defined $tissue;
	    if ( $tissue->nr() == $tissue_num ) {
		$found = 1;
    		$self->{start_pressure} = 1; # shall we do 1 bar, or topside pressure?
    		$self->{end_pressure} = $tissue->M( depth => 0 );  # get the allowed surfacing tension
    		$self->{controlling_tissue} = $tissue;
    		last;	
	    }	
	}

	croak "The tissue number $tissue_num is not valid" unless $found;
    }
    # if the tissue was not set before, croak if someone want to retrieve it
    croak "No controlling tissue set" unless ref($self->{controlling_tissue}) eq 'Deco::Tissue';	

    return $self->{controlling_tissue};
}

# set / get the pressure step size used for each group
sub pressure_step {
    my $self = shift;
    my $stepsize = shift;
	
    if (defined $stepsize) {
	croak "Provide a step size in bar " unless ($stepsize =~ /^\d+\.?\d*/);
	$self->{excess_pressure_step_size} = $stepsize;
    }
    return $self->{excess_pressure_step_size};		
}

# set the depths for the table you want
sub setdepths {
    my $self = shift;
    $self->{depths} = \@_;
}

# calculate the no-stop times
sub _calculate_nostop {
    my $self = shift;
    
    foreach my $depth ( @{ $self->{depths} } ) {
    	my $nodeco_min = INITIAL_NODECO;
    	foreach my $tissue ( @{ $self->{dive}->{tissues} } ) {
    	    next if ! defined $tissue;   # first array element is empty
    	    
    	    # we go instantly to the depth and ask for the no_deco time
    	    $tissue->point( 0, $depth );	
    	    
    	    # we like to have 
    	    # no_deco time, is special, it can return - for not applicable
    	    my $nodeco = $tissue->nodeco_time();
    	    $nodeco = undef if $nodeco eq '-';
    	    
    	    if ($nodeco) {
        		if ($nodeco < $nodeco_min) {
        		    $nodeco_min = int($nodeco);	
        		}	
    	    } 
        }
        if ($nodeco_min == INITIAL_NODECO) {
    	    my $nodeco_min = '-';
        }
    	
    	$self->{nodeco_table}->{$depth} = $nodeco_min; 
    }
    
}


# calculate the table with repetive groups
sub calculate {
    my $self = shift;
    
    my $tissue = $self->controlling_tissue();
    my %groups;
    my $num = 65; # ascii for A
    
    # fill the pressure groups
    for (my $pressure = $self->{start_pressure}; $pressure <= $self->{end_pressure}; 
			$pressure += $self->pressure_step() ) {	
	my $letter = chr($num);
	$groups{$letter} = $pressure;
	$num++;
	
    }
    # save the group letters
    $self->{groups} = \%groups;
    
    foreach my $depth ( @{ $self->{depths} } ) {
		
	# we go instantly to the depth and ask for the time_until_pressure
	$tissue->point( 0, $depth );	
	foreach my $letter ( keys %groups ) {

	    my $time_until = $tissue->time_until_pressure( pressure => $groups{$letter} );
	    if ($time_until ne '-') {
		$time_until = sprintf('%.0f', $time_until);
	    }
	    $self->{table}->{$letter}->{$depth} = $time_until;
	} 
    }
}

# generate the output of the table calculation
# this will return a string containing the entire table
sub output {
    my $self = shift;
    my $output = 'Group: ';
    
    my %groups = %{ $self->{groups} };
    foreach my $depth ( @{ $self->{depths} } ){
	    $output .= $depth . " |";
    }
    
    foreach my $letter ( sort keys %groups ) {
    	$output .= "$letter	 :";
    	foreach my $depth ( @{ $self->{depths} } ){
    	    $output .= $self->{table}->{$letter}->{$depth} . " |";
    	}
    	$output .= "\n";
    }
    
    return $output;	
}

# output the list of no-stop times
sub no_stop {
    my $self = shift;
    my %opt  = @_;
    
    my $template = $opt{'template'};
    if (! $template ) {
	    $template = "No Decompression limit #DEPTH#: #TIME#\n";
    }

    my $output = '';
    
    foreach my $depth ( @{ $self->{depths} }) {
    	my $row = $template;
    	$row =~ s/#DEPTH#/$depth/gi;
    	$row =~ s/#TIME#/$self->{nodeco_table}->{$depth}/gi;
    	$output .= $row;
    }	
    
    return $output;
}
1;


__END__

=head1 NAME

Deco::Dive::Table - Generate a list of no stop limits for your model 

=head1 SYNOPSIS

    use Deco::Dive;
    use Deco::Dive::Table;
    
    my $dive = new Deco::Dive( );
    $dive->model( config => './conf/haldane.cnf');

    my $divetable = new Deco::Dive::Table( dive => $dive );    $divetable->calculate();
    my $table = $divetable->output();

=head1 DESCRIPTION

This package will plot the profile of the dive and internal pressures of the tissues of the model.


=head2 METHODS

=over 4

=item $divetable->new( dive => $dive );

The constructor of the class. There is only one parameter: a Deco::Dive object.

=item $divetable->setdepths( $depth1, $depth2, $depth3, ....  );

Set the list of depths you want the table to be for manually. There is a default list provided, but with this method you can overrule it. Depths should be entered in B<meters>

=item $divetable->controlling_tissue( $tissue_nr );

Set the tissue by its number that will control the table. Usually this is the tissue with the longest halftime

=item $divetable->pressure_step( 0.2 );

Set the step size in bar for which we want to calculate the table. The table will start with 1.0 bar and run up using this step size to the maximum allowed pressure at the surface (M0)

=item $divetable->calculate();

Performs the calculation of the table. You will need to call this function before retrieving output.

=item $divetable->no_stop( template => $template  );

Retrieve the no stop times table as a string. Optionally you can supply your own template for each line of output.
The placeholders #DEPTH# and #TIME# will be replaced by the actual values for the depth (in meters) and time (in minutes) that you can stay at that depth without required decompression stops. 


=item $divetable->output( );

Retrieve the output of the table calculation.

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

In the docs directory you will find an extensive treatment of decompression theory in the file Deco.pdf. A lot of it has been copied from the www.deepocean.net website.

=head1 AUTHOR

Jaap Voets, E<lt>narked@xperience-automatisering.nlE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Jaap Voets

=cut
