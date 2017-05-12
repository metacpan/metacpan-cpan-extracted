package Ham::Resources::Propagation;

use strict;
use warnings;
use LWP::UserAgent;
use XML::Reader::PP;

use Data::Dumper;

use vars qw($VERSION);

our $VERSION = '0.04';

my $data_url = 'http://www.hamqsl.com/solarxml.php';
my $site_name = 'hamqsl.com';
my $default_timeout = 10;
my $default_description = 'text'; # maybe 'text' or 'numeric'

my @items = ('solar_data', 'hf', 'vhf', 'extended');
my @scale = ('Normal', 'Active', 'Minor', 'Moderate', 'Strong', 'Severe', 'Extreme');

sub new
{
	my $class = shift;
	my %args = @_;
	my $self = {};
	$self->{timeout} = $args{timeout} || $default_timeout;
	$self->{description} = $args{description} || $default_description;

    bless $self, $class;
	_data_init($self);
	return $self;
}

sub get_groups
{
	return \@items;
}

sub get
{
	my ($self, $item) = @_;
	$self->{solar_data}->{$item} || $self->{hf}->{$item} || $self->{vhf}->{$item} || $self->{extended}->{$item} || return ($self->{error_mesage} = "Don't found this key ".$item);
}

sub all_item_names
{
	my ($self, @item_names) = @_;
   foreach my $key (sort(@items)){
		foreach (sort keys %{$self->{$key}})
		{
			push @item_names, $_; 
		}	
	}
	return \@item_names;
}

sub is_error { my $self = shift; $self->{error_message} }
sub error_message { my $self = shift; $self->{error_message} }

# -----------------------
#	PRIVATE SUBS
# -----------------------

sub _data_init
{
	my $self = shift;
	my $content = $self->_get_content($data_url) or return 0;
	my $data;

	my $xml = XML::Reader::PP->new(\$content) or return $self->{error_message} = "Error to read XML of $site_name - ".$!;	
	my $p_data;

	while ($xml->iterate) {
		# Solar datas	
		if ($xml->value ne '' && $xml->path !~ /calculated/ && $xml->tag ne '@url' && $xml->tag ne 'source') 
		{		
			# Rules for add text to some value items 
			$data = $xml->value;	# data by default, without text
			if($xml->tag eq 'xray') { $data = $self->_add_xray_text($xml->value); }		
			if($xml->tag eq 'kindex') { $data = $self->_add_kindex_text($xml->value); }		
			if($xml->tag eq 'aindex') { $data = $self->_add_aindex_text($xml->value); }		
			if($xml->tag eq 'protonflux') { $data = $self->_add_protonflux_text($xml->value); }	
			if($xml->tag eq 'electonflux') { $data = $self->_add_electronflux_text($xml->value); }
			if($xml->tag eq 'solarflux') { $data = $self->_add_solarflux_text($xml->value); }
		
			$self->{solar_data}->{$xml->tag} = $data;
		}

		# Propagation		
		if ($xml->path =~ /calculated/) {
			$p_data .= $xml->value;
			if ($xml->tag =~ /\@/) {
				$p_data .= " ";
			} else {
				# create a list for HF conditions
				if ($p_data =~ m/(\d+)m(\-\d+m) (day|night) (.+)/i) {
					my $hf_tag = $1.$2."_".$3;
					$self->{hf}->{$hf_tag} = $4;							
				}
				# create a list for VHF conditions
				if ($p_data =~ /^(.+)(Band .+)/) {
					$self->{vhf}->{$1} = $2;
				}
				$p_data = undef;
			}
		}
	}
}

sub _get_content
{
	my ($self, $url) = @_;
	my $browser = LWP::UserAgent->new( timeout=>$self->{timeout} );
	$browser->agent("Ham/Resources/Propagation.pm $VERSION");
	my $response = $browser->get($url);

	if (!$response->is_success)
	{
		$self->{is_error} = 1;
		$self->{error_message} = "Error at $site_name - ".$response->status_line;
		return 0;
	}
	
	return $response->content;
}

sub _add_aindex_text
{
	my ($self, $num) = @_;
	return $num if $self->{description} eq 'numeric';
	return '('.$num.') quiet' if $num <= 7;
	return '('.$num.') unsettled' if $num >= 8 and $num <= 15;
	return '('.$num.') active' if $num >= 16 and $num <= 29;
	return '('.$num.') minor storm' if $num >= 30 and $num <= 49;
	return '('.$num.') major storm' if $num >= 50 and $num <= 99;
	return '('.$num.') severe storm' if $num >= 100 and $num <= 400;
}

sub _add_kindex_text
{
	my ($self, $num) = @_;
	return $num if $self->{description} eq 'numeric';
	return '('.$num.') quiet' if $num <= 2;
	return '('.$num.') unsettled' if $num == 3;
	return '('.$num.') active' if $num == 4;
	return '('.$num.') minor storm' if $num == 5;
	return '('.$num.') major storm' if $num == 6;
	return '('.$num.') severe storm' if $num >= 7 and $num <= 9;
}


sub _add_xray_text
{
	my ($self, $num) = @_;
	my %xray_defs = (
		'A|B'			=> $scale[0].'| No or small flare. No or very minor impact to HF signals.',
		'C'			=> $scale[1].'| Moderate flare Low absortion of HF signals.',
		'M[1-4]'		=> $scale[2].'| 2000 flares per cycle. Occasional loss of radio contact on sunlit side.',
		'M[5-9]'		=> $scale[3].'| 350 flares per cycle. Limited HF blackout on sunlit side for tens of minutes.',
		'X[1-9?]'	=> $scale[4].'| 175 flares per cycle. Wide area HF blackout for about an hour on sunlit side.',
		'X1[0-9]'	=> $scale[5].'| 8 flares per cycle. HF blackout on most of sunlit side for 1 to 2 hours.',
		'X2[0-9?]'	=> $scale[6].'| 1 flare per cycle. Complete HF blackout on entire sunlit side lasting hours.',
	);
	
	foreach my $xray_key (keys %xray_defs)
	{
		if ($num =~ /$xray_key/i) 
		{ 
			my $xray_complete_data = "(".$num.") ".$xray_defs{$xray_key};
	
			my $radioblackout = $xray_complete_data;
			my ($category, $text) = $radioblackout	 =~ /^\(.+\)(.+)\|(.+)/;
			$radioblackout = $category.'.'.$text;
			$self->{extended}->{radioblackout} = $radioblackout;
			my ($xray_resume_data) = $xray_complete_data =~ /^(.+)\|.+/;
			$num = $xray_resume_data if $self->{description} ne 'numeric';
			return $num;
		}
	}
	return $num;
}

sub _add_protonflux_text
{
	my ($self, $num) = @_;

	my $exponentation = substr $num, -2;

	my %proton_defs = (
		'00'	=> $scale[0].'| No impacts on HF.',
		'01'	=> $scale[1].'| Very minor impacts on HF in polar regions.',
		'02'	=> $scale[2].'| 50 storms per cycle. Minor impacts on HF in polar regions.',
		'03'	=> $scale[3].'| 25 storms per cycle. Small effects on HF in polar regions.',
		'04'	=> $scale[4].'| 10 storms per cycle. Degraded HF propagation in polar regions.',
		'05'	=> $scale[5].'| 3 storms per cycle. Partial HF blackout in polar regions.',
		'06'	=> $scale[6].'| 1 storm per cycle. Complete HF blackout in polar regions.',
	);
	
	my $proton_complete_data = "(".$num.") ".$proton_defs{$exponentation};
		
	my $solarradiotion = $proton_complete_data;
	my ($category, $text) = $solarradiotion	 =~ /^\(.+\)(.+)\|(.+)/;
	$solarradiotion = $category.'.'.$text;
	$self->{extended}->{solarradiation} = $solarradiotion;
	my ($proton_resume_data) = $proton_complete_data =~ /^(.+)\|.+/;
	$num = $proton_resume_data if $self->{description} ne 'numeric';
	return $num;
}

sub _add_electronflux_text
{
	my ($self, $num) = @_;
	
	my $electron_def;
	$electron_def = $scale[0].'| No impacts on HF.' if $num < 1.0e+01;
	$electron_def = $scale[2].'| Minor impacts on HF in polar regions.' if $num > 1.0e+01 && $num < 1.0e+02;
	$electron_def = $scale[2].'| Degraded HF propagation in polar regions.' if $num > 1.0e+02 && $num < 1.0e+03;
	$electron_def = 'Alert'.'| Partial HF blackout in polar regions.' if $num > 1.0e+03;
	
	my $electron_complete_data = "(".$num.") ".$electron_def;
		
	my $electronalert = $electron_complete_data;
	my ($category, $text) = $electronalert	 =~ /^\(.+\)(.+)\|(.+)/;
	$electronalert = $category.'.'.$text;
	$self->{extended}->{electronalert} = $electronalert;
	my ($electron_resume_data) = $electron_complete_data =~ /^(.+)\|.+/;
	$num = $electron_resume_data if $self->{description} ne 'numeric';
	return $num;

}

sub _add_solarflux_text
{
	my ($self, $num) = @_;
		
	my @sn_ratio = ('0-10', '10-35', '35-70', '70-105', '105-160', '160-250');

	my $solarflux_def;
	if ($num <= 70) 
	{ 
		$solarflux_def = $scale[0].'| Bands above 40m unusuable.'; 
		$self->{solar_data}->{SN} = $sn_ratio[0]; 
	};
	if ($num > 70 && $num <= 90) 
	{
		$solarflux_def = $scale[1].'| Poor to fair conditions all bands up through.'; 
		$self->{solar_data}->{SN} = $sn_ratio[1]; 
	};
	if ($num > 90 && $num <= 120) 
	{
		$solarflux_def = $scale[2].'| Fair conditions all bands up through 15m.'; 
		$self->{solar_data}->{SN} = $sn_ratio[2]; 
	};
	if ($num > 120 && $num <= 150) 
	{
		$solarflux_def = $scale[3].'| Fair to good conditions all bands up through 10m.'; 
		$self->{solar_data}->{SN} = $sn_ratio[3]; 
	};
	if ($num > 150 && $num <= 200) 
	{
		$solarflux_def = $scale[4].'| Excelent conditions all bands up through 10m w/6m openings.'; 
		$self->{solar_data}->{SN} = $sn_ratio[4]; 
	};
	if ($num > 200) 
	{
		$solarflux_def = $scale[5].'| Reliable communications all bands up through 6m.'; 
		$self->{solar_data}->{SN} = $sn_ratio[5]; 
	};

	my $solarflux_complete_data = "(".$num.") ".$solarflux_def;
		
	my $bandopenings = $solarflux_complete_data;
	my ($category, $text) = $bandopenings	 =~ /^\(.+\)(.+)\|(.+)/;
	$bandopenings = $category.'.'.$text;
	$self->{extended}->{bandopenings} = $bandopenings;
		 
	my ($solarflux_resume_data) = $solarflux_complete_data =~ /^(.+)\|.+/;
 	$num = $solarflux_resume_data if $self->{description} ne 'numeric';
	return $num;
	
}


1;

__END__

=head1 NAME

Ham::Resources::Propagation - Get Solar and propagation data from web that's useful for Amateur Radio applications.

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

  use Ham::Propagation;

  my $propagation = new Ham::resources::Propagation;
  die $propagation->error_message if $propagation->is_error;

  # access to all data: Solar, HF, VHF and extended

  foreach (sort @{$propagation->all_item_names})
  {
     print "$_ = ".$propagation->get($_)."\n";
  }

  # Access data by category

  my $category = "vhf"; # categories may be solar, hf, vhf and extended
  foreach (sort keys %{$propagation->{$category}})
  {
	 print $_.": ".$propagation->{$category}->{$_}."\n";
  } 

  # Access to unique data item
	# for direct access to Solar data
  print "Update: ".$propagation->{solar_data}->{updated}."\n"; 
	
	# or access to data using get method if you don't know the category of an item
  print "80-40m at night: ".$propagation->get('80-40m_night');
  


=head1 DESCRIPTION

The C<Ham::Resources::Propagation> module provides a simple and easy to use interface to obtain and explain data from N0NBH's solar resource website that's useful for Radio Amateur applications.

This module provides not only the same values from the website but it makes a categorization based on a simplified scale.

Also, this module offers you an interpretation of some values, like solar or electron flux.

This module don't use a static data structure to create the data object, if not, when it creates the hash with the XML data using the names of the labels to create their own structure. This means that if the original XML is modified by a new value, the resulting object displays the new value without changing the internal structure of the module.

The original data structure has 3 groups of information: solar, HF and VHF propagation. But this module adds a new group (call extended) interpreting some values, like band openings, electron alert, radio blackouts and solar radiation, and his impact on HF.

This module is based on XML::Reader to obtain a hash from the original XML website resource. So you can call not only all data but a specific group of data or an specific item too.

For example:

	$propagation->{solar_data}->{aindex}, returns the A-Index value from the Solar group

	$propagation->get(aindex), returns the A-Index value without need to add the group

	$propagation->get(vhf), returns all data that this group.

There are 4 groups to call: solar, hf, vhf and extended.

You can use the all_item_names method for obtain a list of all item names of data and to pass to get method, for example:

	foreach (@{$propagation->all_item_names}) 
	{
		  print "$_ = ".$propagation->get($_)."\n";
	}

It is highly recommended don't use 'sort' in this foreach.


=head1 CONSTRUCTOR

=head2 new()

 Usage    : my $propagation = Ham::Resources::Propagation->new();
 Function : creates a new Ham::Propagation object
 Returns  : a Ham::Propagation object
 Args     : a hash:
            key       required?   value
            -------   ---------   -----
            timeout   no          an integer of seconds to wait for
                                  the timeout of the web site
                                  default = 10                               

	  description no	  an string 'numeric', return only 
	  			  numeric data, 'text' returns
				  values with text index,
				  Default value is 'text'
											
=head1 METHODS

=head2 get()

 Usage    : my $sunspots = $propagation->get( sunspots );
 Function : gets a single item of solar data
 Returns  : a Ham::Propagation object
 Args     : a single item from the list of data items below

=head2 get_groups

 Usage    : my $sunspots = $propagation->get_groups;
 Function : gets an array of existing groups of data
 Returns  : an array reference
 Args     : n/a

=head2 all_item_names

 Usage    : $propagation->all_item_names
 Function : get an array reference of all solar and propagation data items available
            from the object   
 Returns  : an array reference
 Args     : n/a

=head2 is_error()

 Usage    : $propagation->is_error()
 Function : test for an error if one was returned from the call to the resource site
 Returns  : a string, the error message
 Args     : n/a

=head2 error_message()

 Usage    : $propagation->error_message()
 Function : if there was an error message when trying to call the resource site, this is it
 Returns  : a string, the error message
 Args     : n/a



=head1 DATA ITEMS

The following items are available from the object.  Use them with the get() method.

There are four groups of data items: Solar, Hf, VHF and Extended.


=head2 SOLAR DATA

The current list of items for solar data are like as follows, but it will be increased (or decreased) depends from XML data source:

=over

=item aindex

=item aurora

=item electonflux

=item heliumline

=item kindex

=item kindexnt

=item latdegree

=item magneticfield

=item normalization

=item protonflux

=item solarflux

=item solarwind

=item sunspots

=item updated

=item xray

=item geomagfield

=item signalnoise

=item fof2

=back

=head2 HF PROPAGATION DATA

  The category 'hf' show  the state of propagation in decametric bands, separated by the day and night. 
  
  Possible values are: Good, Fair and Poor.

=over

=item 12-10m_day

Propagation condition at the day from 10 to 12 meters band.

=item 12-10m_night

Propagation condition at the night from 10 to 12 meters band.

=item 17-15m_day

Propagation condition at the day from 15 to 17 meters band.

=item 17-15m_night

Propagation condition at the night from 15 to 17 meters band.

=item 30-20m_day

Propagation condition at the day from 20 to 30 meters band.

=item 30-20m_night

Propagation condition at the night from 20 to 30 meters band.

=item 80-40m_day

Propagation condition at the day from 40 to 80 meters band.

=item 80-40m_night

Propagation condition at the night from 40 to 80 meters band.

=back

=head2 VHF PROPAGATION DATA

  The category 'vhf' show  the state of some atmospheric phenomena which may be involved in the propagation on metric bands. Each item show open or closed band.

=over

=item europe E-Skip

Possibility of use skips through ionospheric 'E' layer in Europe.

=item europe_4m E-Skip

Possibility of use skips on 4 meters band through ionospheric 'E' layer in Europe. 

=item europe_6m E-Skip

Possibility of use skips on 6 meters band through ionospheric 'E' layer in Europe. 

=item north_america E-Skip

Possibility of use skips through ionospheric 'E' layer in North America. 

=item northern_hemi vhf-aurora

How it affects the aurora in DX-type communications in the northern hemisphere.

=back

=head2 EXTENDED DATA

The category "extended" shows a human explanation interpreting some of the solar data.
  
=over  

=item radioblackouts

This item calculated a category index of the Solar X-Ray and his iteraction over HF transmisions.

=item solarradiation

This item calculated a category index of the severity of solar proton events and his impact on polar regions.

=item bandopenings

This item calculated a category index of band opening based on the Solar flux index.

=item electronalert

This item warn you when the electron flux will be dangerous for propagation.

=back

=head1 TODO

=over

=item * Add more data items or new sources for more information.

=item * Improve more error checking.

=item * Add option to add the unit of measurement from any values when description argument is 'text'.


=back

=head1 ACKNOWLEDGEMENTS

This module gets its data from N0NBH's Propagation Resource Page at http://www.hamqsl.com.

Thanks to Paul L Herrman N0NBH!

=head1 AUTHOR

Carlos Juan Diaz, EA3HMB <ea3hmb at gmail.com>

=head1 COPYRIGHT AND LICENSE

C<Ham::Resources::Propagation> is Copyright (C) 2011-2012 Carlos Juan Diaz, EA3HMB.

This module is free software; you can redistribute it and/or
modify it under the terms of the Artistic License 2.0. For
details, see the full text of the license in the file LICENSE.

This program is distributed in the hope that it will be
useful, but it is provided "as is" and without any express
or implied warranties. For details, see the full text of
the license in the file LICENSE.
