#######################################
# Module  : Deco::Dive.pm
# Author  : Jaap Voets
# Date    : 27-05-2006
# $Revision$
#######################################
package Deco::Dive;

use strict;
use warnings;
use Carp;
use Config::General;
use Deco::Tissue;

our $VERSION = '0.4';

our @MODELS = ('haldane', 'padi', 'usnavy');

# Constructor
sub new {
    my $class = shift;
    my %args  = @_;

    my $self = {};

    # the data points for the dive, both arrays
    $self->{timepoints} = [];
    $self->{depths}     = [];

    # an array of tissues to use
    $self->{tissues}    = ();
    
    # super structure to remember all tissue info per timepoint
    $self->{info}       = {};

    # where can we find the config?
    $self->{config_dir} = $args{configdir} || '.';

    # theoretical tissue model we'll be using
    $self->{model}        = '';
    $self->{model_name}   = '';
    bless $self, $class;
    
    return $self;
}

# load the dive profile data from a file
sub load_data_from_file {
    my $self = shift;
    my %opt  = @_;

    my $file = $opt{file};
    croak "No file specified, to load dive profile" unless $file;
    # check whether the file exists
    croak "File $file does not exist" unless ( -e $file);

    # field separator
    my $sep        = $opt{separator} || ';';
    my $timefield  = $opt{timefield} || '0';
    my $depthfield = $opt{depthfield} || 1;
    my $timefactor = $opt{timefactor} || 1; # factor to get each time point in seconds

    my (@times, @depths);
    open (IN, $file) || croak "Can't open file $file for reading";
    while (my $line = <IN>) {
	chomp($line);
	next if $line =~ /^\s*#/; # skip comment lines
	next if $line =~ /^\s+$/; # skip empty lines
	my @fields = split(/$sep/, $line);
	push @times, $timefactor * $fields[$timefield];
	my $depth = $fields[$depthfield];
	if ($depth < 0) {
	    $depth = -1 * $depth;
	}
	push @depths, $depth;
    }
    close(IN);
    
    $self->{depths}     = \@depths;
    $self->{timepoints} = \@times;
    
}

# set a time, depth point
sub point {
    my $self = shift;
    my ($time, $depth) = @_;
    push @{ $self->{depths} }, $depth;
    push @{ $self->{timepoints} }, $time;
}

# pick a model and load the corresponding config
# this will create a list of tissues
# either specify a config file and read the model from there
#  - or - specify a model and read in the default file
sub model {
    my $self = shift;
    my %opt  = @_;

    my ($config_file, $model);
    if ( $opt{config} ) {
	$config_file = $opt{config};
	# model will be read from config
    } elsif ( $opt{model} ) {
	$model = lc( $opt{model} );
	$config_file = $self->{config_dir} . "/$model.cnf";
    } else {
	croak "Please specify the config file or model to use!";
    }

    # load the config
    my $conf   = new Config::General(  -ConfigFile => $config_file,  -LowerCaseNames => 1 );
    my %config = $conf->getall;
 
    $model = lc($config{model});

    # remember the model we use
    $self->{model}      = $model;
    $self->{model_name} = $config{name};

    croak "Invalid model $model" unless grep { $_ eq $model } @MODELS;
    
    # cleanup first
    $self->{tissues} = ();

    # create all the tissues
    foreach my $num (keys %{ $config{tissue} }) {
	$self->{tissues}[$num] = new Deco::Tissue( halftime => $config{tissue}{$num}{halftime}, 
						   M0       => $config{tissue}{$num}{m0}, 
						   deltaM   => $config{tissue}{$num}{deltam} ,
						   nr       => $num,
						   );
    }
    
    return 1;
}

# run the simulation
sub simulate {
    my $self = shift;
    my %opt  = @_;

    # model passed to us takes precedence, if that is not present
    # we see if the model was already set, otherwise we default to haldane
    my $model = lc($opt{model}) || $self->{model} || 'haldane';
    croak "Invalid model $model" unless grep { $_ eq $model } @MODELS;
    
    # first load the model
    $self->model( model => $model,  config => $self->{config_dir} . '/' . $model . '.cnf');
    
    # then check whether we loaded data
    if ( scalar( @{ $self->{timepoints} } ) == 0 ) {
	croak "No dive profile data present, forgot to call dive->load_data_from_file() ?";
    }
    
    # step through all the timepoints & depths
    my $i = 0;
    my @times  = @{ $self->{timepoints} };
    my @depths = @{ $self->{depths} };
    foreach my $time ( @times ) {
	# get the corresponding depth
	my $depth = $depths[$i];
	$i++;

	my $nodeco_dive          = 1000000;
	my $leading_tissue_deco  = '';

	my $safe_depth_dive      = 0;
	my $leading_tissue_depth = '';

	# loop over all the tissues
	foreach my $tissue ( @{ $self->{tissues} } ) {
	    next if ! defined $tissue;

	    my $num  = $tissue->nr;

	    $tissue->point( $time, $depth );
	    
	    # we like to have 
	    # no_deco time, is special, it can return - for not applicable
	    my $nodeco = $tissue->nodeco_time();
	    $nodeco = undef if $nodeco eq '-';
	    $self->{info}->{$num}->{$time}->{nodeco_time}    = $nodeco; 
	    if ($nodeco) {
		if ($nodeco < $nodeco_dive) {
		    $nodeco_dive         = $nodeco;
		    $leading_tissue_deco = $tissue->nr();
		}
	    }

	    # safe depth, meters, positive
	    my $safe_depth = $tissue->safe_depth();
	    $self->{info}->{$num}->{$time}->{safe_depth} =  $safe_depth;
	    if ($safe_depth > $safe_depth_dive) {
		$safe_depth_dive      = $safe_depth;
		$leading_tissue_depth = $tissue->nr();
	    }

	    # percentage filled compared to M0 pressure
	    $self->{info}->{$num}->{$time}->{percentage} =  $tissue->percentage();

	    # internal pressure
	    $self->{info}->{$num}->{$time}->{pressure}   = $tissue->internalpressure();

	    # OTU's
	    $self->{info}->{$num}->{$time}->{pressure}   = $tissue->calculate_otu();

	}
	if ($nodeco_dive == 1000000) {
	    $nodeco_dive = '-';
	}
	$self->{info}->{dive}->{$time}->{nodeco}             = $nodeco_dive;
	$self->{info}->{dive}->{$time}->{leadingtissuedeco}  = $leading_tissue_deco;
	$self->{info}->{dive}->{$time}->{safedepth}          = $safe_depth_dive;
	$self->{info}->{dive}->{$time}->{leadingtissuedepth} = $leading_tissue_depth;

    }
    
}

# set gas fractions
sub gas {
    my $self = shift;
    my %gaslist = @_;
    # just pass it off to each tissue
    foreach my $tissue ( @{ $self->{tissues} } ) {
        next if ! defined $tissue;

	# the tissue module will croak on setting wrong gas
	# just let it bubble up to the calling script from here
	$tissue->gas( %gaslist );
    }
}

# calculate the no-deco time for the dive
# this will be the smalles value of the nodeco times of
# the tissues of this model
#
# time is minutes, it takes the current depth and time of the tissue
# second return value is the tissue nr that gave the minimal nodeco_time
sub nodeco_time {
    my $self = shift;
    # loop over all the tissues
    my $nodeco_time = 1000000; # start with absurd high value for easy comparing
    my $tissue_nr   = '';
    foreach my $tissue ( @{ $self->{tissues} } ) {
    	next if ! defined $tissue;
        my $time = $tissue->nodeco_time();
    	if ($time ne '-') {
    	    if ($time < $nodeco_time) {
    	    	$nodeco_time = $time;
    		    $tissue_nr   = $tissue->nr();
    	    }
    	}
    }
    if ($nodeco_time == 1000000) {
    	$nodeco_time = '-';
    }
    return ($nodeco_time, $tissue_nr);
}

# return a tissue by number
sub tissue {
    my $self =shift;
    my $tissue_num = shift;
    
    croak "Please specify a tissue nr" unless defined $tissue_num;
    
    foreach my $tissue ( @{ $self->{tissues} } ) {
	    next if ! defined $tissue;
	    if ( $tissue->nr() == $tissue_num ) { 
            return $tissue;	    
	    }
    }
    
    # if we make it to here the tissue is not known
    croak "Tissue nr $tissue_num is unknown";
}
1;


__END__

=head1 NAME

Dive - Simulate a dive and corresponding tissues

=head1 SYNOPSIS

    use Deco::Dive;
my $dive = new Deco::Dive( );
$dive->load_data_from_file( file => $file);
$dive->model( config => '/path/to/my/model.cnf' );
$dive->simulate( );


=head1 DESCRIPTION

The Dive model can be used to simulate a dive. You add data points, set some properties and call the simulate method to calculate the entire dive.

After simulating, you can retrieve info in several ways from the dive.



=head2 METHODS

=over 4

=item new()

The constructor of the class.

=item $dive->load_data_from_file( file => $file , timefield => 0, depthfield => 1, timefactor => 1, separator => ';');

Load data from a csv file. You HAVE to specify the filename. Additional options are timefield, the 0 based field number where the  timestamps are stored. Depthfield, field number where the depth (in meters is stored), separator, the fieldseparator and timefactor, the factor to multiply the time field with to transform them to seconds.

=item $dive->model( model => 'padi', config => $file );

Set the model to use. If you specify one of the known models and the config dir has been set right,
then the method will load the corresponding config file and set up the tissues for this model.

Alternatively you can specify your own config file to use.

=item $dive->simulate( model => 'haldane' );

This method does the simulation for all tissues for the chosen model. It will run along all the time and depth
points of the dive and calculate gas loading for all the tissues of the model.

=item $dive->nodeco_time();
This function will loop over all the tissues of the model, calling the LDeco::Tissue::nodeco_time() function on them. The lowest value will be stored, together with the associated tissue nr.  

=item $dive->gas( 'O2' => 45, 'n2' => 0.55);

Set the gases used during this dive. Currently supported are 02, N2 and He. Enter the fraction of the gas either as real fraction, or as a percentage.

=item $dive->point($time, $depth);

Adds a new point to the dive. Use it if you don't want to load data from a file but iterate over your own values. Time should be in seconds, depth in meters.
 
=item $dive->tissue( $tissue_nr );

Returns the tissue as defined in the config by numer $tissue_nr. The function will croak when nothing is found.

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<Deco>, L<Deco::Tissue>, L<Deco::Dive::Plot>. L<SCUBA::Table::NoDeco> might be of interest to you as well.
In the docs directory you will find an extensive treatment of decompression theory in the file Deco.pdf. A lot of it has been copied from the www.deepocean.net website.

=head1 AUTHOR

Jaap Voets, E<lt>narked@xperience-automatisering.nlE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Jaap Voets

=cut
