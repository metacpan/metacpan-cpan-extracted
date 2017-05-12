package Device::Kiln;

use Device::DSE::Q1573;
use Device::Kiln::Orton;
use SVG::TT::Graph::TimeSeries;
use HTTP::Date qw(time2iso str2time);


use strict;

BEGIN {
	require Device::DSE::Q1573;
	use Exporter ();
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = '0.03';
	@ISA         = qw(Exporter);
	@EXPORT      = qw();
	@EXPORT_OK   = qw();
	%EXPORT_TAGS = ();

}

sub new {
	
	my $class = shift;
	my %config = %{$_[0]};
	


	my $self = bless( {}, ref($class) || $class );
	
	
	if( defined $config{'serialport'} ) {
		$self->{meter}      = Device::DSE::Q1573->new($config{serialport});
		$self->{serialport} = $config{serialport};
	}
		

	$self->{width}      = $config{'width'};
	$self->{height}     = $config{'height'};
	$self->{interval}   = $config{'interval'};
	$self->{rampuprate} = 150;
	$self->{tid}        = undef;
	$self->{datafile}   = '/tmp/q1573.tmp';
	$self->{cones}		= {
			'1 - 018' =>  	{ 
							60  => 712,
							100 => 722,
							150 => 732
							},
							
			'2 - 017' =>  	{
							60  => 736,
							100 => 748,
							150 => 761
							},
							
			'3 - 016' =>	{
							60  => 769,
							100 => 782,
							150 => 794
							},
							
						};
				
	$self->{maxtemp}	= [""];
	return $self;
}

sub run {


	my $self = shift;

	print $self->{file} . "\n";
	my $time  = 0;
	my $count = 0;

	my $fh;

	open( $fh, ">>", $self->{datafile} );
	$fh->autoflush(1);

	sleep 1;

	while (1) {
		
		my $time = time();
		my $raw = $self->{meter}->rawread();
		#print $raw. "\n";
		$self->{setting} = substr( $raw, 0,  2 );
		$self->{value}   = substr( $raw, 2,  7 ) + 0;
		$self->{units}   = substr( $raw, 11, 1 );

		$self->{value} =~ s/ //g;

		#print $self->{value} . " ";
		print time2iso() . "\n";

		print $fh time2iso() . "|" . $self->{value}  . "\n";
		
		
		while( time() < ($self->{interval} + $time) ){sleep 1;};
		print time() . " : $time\n";
		

	}

}

sub graph {

	my $self = shift;
	my $config = shift;
		
	my @data;
	my @ideal;
	my $fh;
	my ($startperiod, $startvalue);
	
	
	$config->{conemax} = Device::Kiln::Orton->hashref()->{$config->{cone}}->{$config->{conerate}};
	#$config->{conemax} = $self->{cones}->{$config->{cone}}->{$config->{conerate}};
	

	#@data = ( [ time2iso(), $self->{value} ] );
	
	open( $fh, "<", $self->{datafile} );
	my $count = 0;
	while(<$fh>) {


		chomp;
		push @data, [split /\|/, $_];
		
		
		if($count == 0 ) {
			$startperiod = $data[0][0];
			$startvalue = $data[0][1];
			$count++;
		}
		
				
	}

	debug("-------------------------");
	
	debug("Warmupramp :" . $config->{warmupramp});
	debug("Warmuptemp :" . $config->{warmuptemp});
	debug("Warmuptime :" . $config->{warmuptime});
	debug("Fireuprate :" . $config->{fireuprate});
	debug("Conerate   :" . $config->{conerate});
	debug("Cone       :" . $config->{cone});
	debug("Cone Max   :" . $config->{conemax});
	
	
	
	my $endperiod = @{@data[@data-1]}[0];
	my $duration = str2time($endperiod) - str2time($startperiod);
	
	my $value=$startvalue;

	debug("Duration " . $duration);
	
	push @ideal, [$startperiod,$value];
	debug( "Data : " . $ideal[@ideal-1][0] . ", " . $ideal[@ideal-1][1]);
	

	
	push @ideal, warmupramp($startvalue,$startperiod,$endperiod,$config);

	
	# Warm Up Time
	my $warmupsecs = $config->{warmuptime} * 60;
	
	if($duration > $config->{used} || $config->{fullgraph} == 0) {
		
		push @ideal, warmuptime($startvalue,$startperiod,$endperiod,$config);
		
		# Fire up to Pre Cone Fire	
		if( $duration > $config->{warmupramptime} + $warmupsecs && $config->{fullgraph} == 0) {
			push @ideal, fireuptime($startvalue,$startperiod,$endperiod,$config);
		
			if($duration > $config->{fireuptime}) {
				push @ideal, conefire($startvalue,$startperiod,$endperiod,$config);
			}
		}
	
	}
	
	
	
	my $graph = SVG::TT::Graph::TimeSeries->new(
		{

			# Optional - defaults shown
			'height' => 600,
			'width'  => 1024,

			'x_label_format' => '%H:%M:%S',
			'area_fill'      => 1,

			'max_time_span' => 0,
			'timescale_divisions' => '15 minutes',

		    'rollover_values'   => 1,
		    'show_data_points'  => 1,
		    'show_data_values'  => 1,

			# Stylesheet defaults
			'style_sheet'   => '/graph.css',    # internal stylesheet
			'random_colors' => 0,
			'compress'      => 0,
			'key'		=> 1,
			
		}
	);

	$graph->add_data(
		{
			'data'  => \@data,
			'title' => 'Temperature',
		}
	);
	
	$graph->add_data(
		{
			'data'  => \@ideal,
			'title' => 'Ideal',
		}
	);
	
	
	debug("-------------------------");

	
	return $graph->burn();
	

}


sub warmupramp {

	my ($startvalue,$startperiod,$endperiod,$config) = @_;
	
	my @ideal;
	my $duration = str2time($endperiod) - str2time($startperiod);
	
	#
	# Warmup Ramp
	#
	debug( "-----> warmupramp ");
	$config->{warmupramptime} = ($config->{warmuptemp}-$startvalue)/($config->{warmupramp})*60*60;
	
	
	if($duration <= $config->{warmupramptime} && $config->{fullgraph} == 0) {
		my $value = ($duration/3600) * $config->{warmupramp} + $startvalue;
		push @ideal, [$endperiod,$value];
		debug( "Data : " . $ideal[@ideal-1][0] . ", " . $ideal[@ideal-1][1]);
		$config->{used} = $duration;
		
	} else {
		push @ideal, [time2iso($config->{warmupramptime}+str2time($startperiod)),$config->{warmuptemp}];
		$config->{used} = $config->{warmupramptime};
		debug( "Data : " . $ideal[@ideal-1][0] . ", " . $ideal[@ideal-1][1]);
		
	}
	return @ideal;
}

sub warmuptime {
	
	my ($startvalue,$startperiod,$endperiod,$config) = @_;
	my $warmupsecs = $config->{warmuptime} * 60;
	my $duration = str2time($endperiod) - str2time($startperiod);
	my @ideal;
		
	if( $duration < $config->{used} + $warmupsecs && $config->{fullgraph} == 0) {
		
		push @ideal, [$endperiod,$config->{warmuptemp}];
		$config->{used} = $duration;
		
	} else {

		push @ideal, [time2iso($config->{warmupramptime}+str2time($startperiod)+ $warmupsecs),$config->{warmuptemp}];
		$config->{used} = $config->{used} + $warmupsecs; 
		
	}	

	debug( "Data : " . $ideal[@ideal-1][0] . ", " . $ideal[@ideal-1][1]);
	return @ideal;
	
}	



sub fireuptime {
	
	my ($startvalue,$startperiod,$endperiod,$config) = @_;
	my $duration = str2time($endperiod) - str2time($startperiod);
	
	my @ideal;
	
	my $endtemp = $config->{conemax} - 100;
	my $risetemp = $endtemp - $config->{warmuptemp};
	
		
	my $endfireuptime = $config->{used} + ($risetemp / $config->{fireuprate}) * 3600;
	
	
	if($duration < $endfireuptime ) {
		my $leftover = $duration - $config->{used};
		my $value = $leftover * ($config->{fireuprate} / 3600) + $config->{warmuptemp};
		push @ideal, [$endperiod, $value];
		$config->{used} = $duration;
		
	} else {
		
		
		push @ideal, [time2iso($endfireuptime + str2time($startperiod)),$endtemp];
		$config->{used} = $endfireuptime;
		$config->{fireuptemp} = $endtemp;
	}
	
	
	debug( "Data : " . $ideal[@ideal-1][0] . ", " . $ideal[@ideal-1][1]);
	return @ideal;	
	
}


sub conefire {
	
	my ($startvalue,$startperiod,$endperiod,$config) = @_;
	my $duration = str2time($endperiod) - str2time($startperiod);
	my @ideal;
	my $fullconetime = 100 / $config->{conerate} * 3600;
	
	if( $duration < $config->{used} + $fullconetime ) {
	 
		push @ideal, [$endperiod, $config->{fireuptemp} + 100 * (($duration-$config->{used})/$fullconetime) ];
		$config->{used} = $duration;
		
	} else {
		
		
		push @ideal, [time2iso($config->{used} + 3600 + str2time($startperiod)), $config->{conemax}];
		$config->{used} += $fullconetime; 
		debug("in");
	}
	
	debug( "Data : " . $ideal[@ideal-1][0] . ", " . $ideal[@ideal-1][1]);
	return @ideal;
	
}

sub debug {
	
	my $msg = shift;
	
	open( my $dfh, ">>", "/tmp/kilnserver.dbg");
	print $dfh (scalar localtime) . " : " . $msg . "\n";
	close($dfh);
	
}

=head1 NAME

Device::Kiln - Graph kiln firing use Data logged from Device::DSE::Q1573 

=head1 SYNOPSIS

  use Device::Kiln;
  my $meter = Device::Kiln->new("/dev/ttyS0");
  


=head1 DESCRIPTION

Sets up a connection to a DSE Q1573 or Metex ME-22 
Digital Multimeter, and allows then plots data to a png file
at regular intervals. 
=head1 USAGE

=head2 new(serialport)

 Usage     : my $meter=Device::Kiln->new("/dev/ttyS0")
 Purpose   : Opens the meter on the specified serial port
 Returns   : object of type Device::Kiln
 Argument  : serial port
 
=head2 rawread();

 Usage     : my $meter->rawread()
 Purpose   : Returns the raw 14 byte string from the meter.
 
=head1 EXAMPLE

use Device::DSE::Q1573;

my $meter = Device::Kiln->new( "/dev/ttyS0" );

while(1) {
	my $data = $meter->read();
	print $data . "\n";
	sleep(1);
}


=head1 AUTHOR

    David Peters
    CPAN ID: DAVIDP
    davidp@electronf.com
    http://www.electronf.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

#################### main pod documentation end ###################

1;
