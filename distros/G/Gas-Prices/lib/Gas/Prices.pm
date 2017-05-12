package Gas::Prices;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.4');

# Other recommended modules (uncomment to use):
#  use IO::Prompt;
#  use Perl6::Export;
#  use Perl6::Slurp;
#  use Perl6::Say;
use HTTP::Lite;	

# Module implementation here

sub new
{
	my $class = shift;
	my $self = {};

	bless $self;
	$self->{zip} = shift;

	my $http = new HTTP::Lite;
	my $req = $http->request(
		"http://autos.msn.com/everyday/GasStations.aspx?m=1&l=1&zip=" . 
		$self->{zip});
	my $body = $http->body();
	$body =~ s/\n/ /g;
	$body =~ s/\r/ /g;
	$body =~ s/\cM/ /g;

	$self->{units} = undef;
	
	if($body =~ /<table id="tblDetail".*?<\/tr>(.*?)<\/table>/)
	{
		my $data = $1;
		$data =~ s/^\s+//;
		$data =~ s/\s+$//;
		
		my @units = ();
		
		while ($data =~ /<tr>(.*?)<\/tr>/g)
		{
			my $unit = $1;
			if($unit =~
				 /<span class="text-subheadBold">(.*?)<\/span>.*?<span class="text-captionPlain">(.*?)<\/span>.*?<span class="text-captionPlain">(.*?)<\/span>.*?<span class="text-subheadBold">(.*?)<\/span>.*?<span class="text-captionPlain">(.*?)<\/span>.*?<span class="text-subheadBold">(.*?)<\/span>.*?<span class="text-captionPlain">(.*?)<\/span>.*?<span class="text-subheadBold">(.*?)<\/span>.*?<span class="text-captionPlain">(.*?)<\/span>.*?<span class="text-subheadBold">(.*?)<\/span>.*?<span class="text-captionPlain">(.*?)<\/span>/)
			{
				my $station_info =
				{
					station_name => $1,
					station_address => "$2, $3",
					unleaded_price => $4,
					unleaded_date => $5,
					plus_price => $6,
					plus_date => $7,
					premium_price => $8,
					premium_date => $9,
					diesel_price => $10,
					diesel_date => $11
				};
				
				
				$station_info->{unleaded_price} = $1 
					if ($station_info->{unleaded_price} =~ 
						/\$(.*)/);
				
				$station_info->{plus_price} = $1
					if ($station_info->{plus_price} =~
						/\$(.*)/);
				
				$station_info->{premium_price} = $1
					if ($station_info->{premium_price} =~
						/\$(.*)/);

				$station_info->{diesel_price} = $1
					if ($station_info->{diesel_price} =~
						/\$(.*)/);
				
				push @units, $station_info;
			}
		}
		
		$self->{units} = \@units;

		#use Data::Dumper;
		#print Dumper @units;
		
		return $self;
	}
	return undef;
}

sub get_stations
{
	my $self = shift;
	return $self->{units};
}

sub get_cheapest_station
{
	my $self = shift;
	my $type = shift;
	
	my @units = @{$self->{units}};

	my $lowest_price = undef;
	my $cheapest_station = undef;
	

	foreach(@units)
	{
		$cheapest_station = $_ if(!$cheapest_station);
		if($self->is_less( $_->{$type . "_price"}, 
				$cheapest_station->{$type . "_price"}))
		{
			#print "Replacing " . $cheapest_station->{$type . "_price"} . " with " . $_->{$type . "_price"} . "\n";
			$cheapest_station = $_;
		}
		#print $_->{$type . "_price"} . "\n";
		$lowest_price = $cheapest_station->{$type . "_price"};
	}

	return $cheapest_station;
}

sub get_most_expensive_station
{
	my $self = shift;
	my $type = shift;
	
	my @units = @{$self->{units}};
	
	my $highest_price = undef;
	my $most_expensive_station = undef;
	
	
	foreach(@units)
	{
		$most_expensive_station = $_ if(!$most_expensive_station);
		if($self->is_greater($_->{$type . "_price"}, 
				$most_expensive_station->{$type . "_price"}))
		{
			$most_expensive_station = $_;
		}
		
		$highest_price = $most_expensive_station->{$type . "_price"};
	}
	
	return $most_expensive_station;

}

sub is_greater
{
	my ($self, $first, $second) = @_;

	$first = $1 if($first =~ /\$(.*)/);
	$second = $1 if($second =~ /\$(.*)/);
	
	#print "Comparing $first with $second\n";
	
	return 0 if($first =~ /N\/A/);
	return 0 if($first =~/nbsp/);

	return 1 if($second =~ /N\/A/);
	return 1 if($second =~/nbsp/);

	return 1 if($first > $second);
	return 0;
}

sub is_less
{
	my ($self, $first, $second) = @_;
	
	$first = $1 if($first =~ /\$(.*)/);
	$second = $1 if($second =~ /\$(.*)/);
	
	#print "Comparing $first with $second\n";
	
	return 0 if($first =~ /N\/A/);
	return 0 if($first =~/nbsp/);
	
	return 1 if($second =~ /N\/A/);
	return 1 if($second =~/nbsp/);
	
	return 1 if($first < $second);
	return 0;
}
										
1; # Magic true value required at end of module
__END__

=head1 NAME

Gas::Prices - Perl Module to get the gas prices around a particular zip code


=head1 VERSION

This document describes Gas::Prices version 0.0.1


=head1 SYNOPSIS

    use Gas::Prices;
    my $gp = new Gas::Prices("75023"); #or any other 

  
=head1 DESCRIPTION

Please use module WWW::Fuel::US::Prices instead. This module will no longer be supported.

The module gets gas prices for a given zip code. It gets its data by scraping msn autos webpage.

It retrieves a bunch of gas stations around the particular zip code, and for each gas station, it retrives the following data

=head2 EXAMPLE
	
The usage is as follows

    use Gas::Prices;
    my $gp = new Gas::Prices("75023"); #or any other zip code
    my @gas_stations = @{$gp->get_stations};
    
    foreach(@gas_stations)
    {
        print   "Station name:" . $_->{station_name} . "\n" .
	        "Station address:" . $_->{station_address} . "\n" .
		"Unleaded price:" . $_>{unleaded_price} . "\n" .
		"Unleaded date:" . $_->{unleaded_date} . "\n" .
		"Plus price:" . $_->{plus_price} . "\n" .
		"Plus date:" . $_->{plus_date} . "\n" .
		"Premium price:" . $_->{premium_price} . "\n" .
		"Premium_date:" . $_->{premium_date} . "\n" .
		"Diesel price:" . $_->{diesel_price} . "\n" .
		"Diesel date:" . $_->{diesel_date} . "\n";
    }
    
    my $cheapest_unleaded = $gp->get_cheapest_station("unleaded");
    print "The cheapest unleaded grade gas near 75023 is " . $cheapest_unleaded->{station_name} . " at " . $cheapest_unleaded->{station_address} . ' for $' . $cheapest_unleaded->{unleaded_price} . "/gallon.";


=head1 INTERFACE 

=head2 new

Creates a new Gas::Prices object, and fetches data.
my $gp = new Gas::Prices("75023");

=head2 get_cheapest_station

Gets the gas stations with the cheapest price for a give type of gas
my $unleaded_station = $gp->get_cheapest_station("unleaded");
my $diesel_station = $gp->get_cheapest_station("diesel");

The only valid values for the parameter are
- unleaded
- plus
- premium
- diesel

=head2 get_most_expensive_station

Works the same way as get_cheapest_station, but returns the station with the most expensive fuel for the given type.

=head2 get_stations

Gets all gas station info around the zip code

=head2 is_less

Used internally. Need a better way to do this.

=head2 is_greater

Same as is_less

=head1 CONFIGURATION AND ENVIRONMENT

Gas::Prices requires no configuration files or environment variables.


=head1 DEPENDENCIES

Gas::Prices uses HTTP::Lite.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-gas-prices@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Ashish Kasturia  C<< <ashoooo@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Ashish Kasturia C<< <ashoooo@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
