package Ham::Reference::Solar;

# --------------------------------------------------------------------------
# Ham::Reference::Solar - A scraper to return solar data useful for
# Amateur Radio applications.
#
# Copyright (c) 2008-2010 Brad McConahay N8QQ.
# Cincinnat, Ohio USA
#
# This module is free software; you can redistribute it and/or
# modify it under the terms of the Artistic License 2.0. For
# details, see the full text of the license in the file LICENSE.
# 
# This program is distributed in the hope that it will be
# useful, but it is provided "as is" and without any express
# or implied warranties. For details, see the full text of
# the license in the file LICENSE.
# --------------------------------------------------------------------------

use strict;
use warnings;
require LWP::UserAgent;
use vars qw($VERSION);

our $VERSION = '0.03';

my $solar_url = 'http://www.wm7d.net/hamradio/solar';
my $site_name = 'wm7d.net';
my $default_timeout = 10;

my $items =
{
	'sfi'             => 'SFI: <font.*?><b>\s*(.*?)\s*</b></font>',
	'a-index'         => 'A-index: <font.*?><b>\s*(.*?)\s*</b></font>',
	'a-index-text'    => -1, # calculated field
	'k-index'         => 'K-Index: <font.*?><b>\s*(.*?)\s*</b></font>',
	'k-index-text'    => -1, # calculated field
	'forecast'        => '<b>Forecast for the next 24 hours:</b><br>\s*(.*?)\s*<br>',
	'summary'         => '<b>Summary for the past 24 hours:</b><br>\s*(.*?)\s*<br>',
	'sunspots'        => '<a .*?>Current Sunspot Count:\s*(.*?)\s*</a>',
	'image'           => -1, # calculated field
	'image_thumbnail' => '(http://umbra.nascom.nasa.gov.*?\.gif)',
	'time'            => '<font.*?>Report last updated:\s*(.*?)\s*</font>'
};	

sub new
{
	my $class = shift;
	my %args = @_;
	my $self = {};
	$self->{timeout} = $args{timeout} || $default_timeout;
    bless $self, $class;
	_solar_init($self);
	return $self;
}

sub get
{
	my $self = shift;
	my $item = shift;
	$self->{$item};
}

sub set
{
	my $self = shift;
	my $item = shift;
	my $value = shift;
	# $self->{$item} = _remove_markup($value);
	$self->{$item} = $value;
}

sub get_hashref
{
	my $self = shift;
	my $items = $self->all_item_names;
	my $hash = {};
	foreach (sort @$items) { $hash->{$_} = $self->{$_} }
	return $hash;	
}

sub all_item_names
{
	my $self = shift;
	my @item_names;
	foreach (sort(keys %$items)) { push @item_names, $_ }
	return \@item_names;
}

sub is_error { my $self = shift; $self->{error_message} }
sub error_message { my $self = shift; $self->{error_message} }

# -----------------------
#	PRIVATE
# -----------------------

sub _solar_init
{
	my $self = shift;
	my $content = $self->_get_content($solar_url) || return 0;
	chomp $content;
	$content =~ tr/\r\n//;
	foreach my $item (keys %$items)
	{
		next if $item eq "-1"; # don't parse calculated fields
		if ($content =~ s#$items->{$item}##i)
		{
			$self->set($item,$1)
		}
	}
	_calc_fields($self);
	if (!$self->{sfi})
	{
		$self->{is_error} = 1;
		$self->{error_message} = "Data Parsing error - Format at $site_name may have changed";
		return 0;
	}
}

sub _calc_fields
{
	my $self = shift;
	$self->{'a-index-text'} = _get_a_text($self->{'a-index'});
	$self->{'k-index-text'} = _get_k_text($self->{'k-index'});
	$self->{'image'} = $self->{'image_thumbnail'};
	$self->{'image'} =~ s/_thumbnail//;
}

sub _get_content
{
	my $self = shift;
	my $url = shift;
	my $ua = LWP::UserAgent->new( timeout=>$self->{timeout} );
	$ua->agent("Ham/Reference/Solar.pm $VERSION");
	my $request = HTTP::Request->new('GET', $url);
	my $response = $ua->request($request);
	if (!$response->is_success)
	{
		$self->{is_error} = 1;
		$self->{error_message} = "Error at $site_name - ".HTTP::Status::status_message($response->code);
		return 0;
	}
	return $response->content;
}

#sub _items
#{
#	my $self = shift;
#	my @item_names;
#	my $items = $self->all_item_names;
#	foreach (sort @$items) { push @item_names, $_ if $self->{$_} }
#	return \@item_names;
#}

sub _remove_markup
{
	my $text = shift;
	$text =~ s/<.*?>//g;
	return $text;
}

sub _get_a_text
{
	my $num = shift;
	return 'quiet' if $num >= 0 and $num <= 7;
	return 'unsettled' if $num >= 8 and $num <= 15;
	return 'active' if $num >= 16 and $num <= 29;
	return 'minor storm' if $num >= 30 and $num <= 49;
	return 'major storm' if $num >= 50 and $num <= 99;
	return 'severe storm' if $num >= 100 and $num <= 400;
}

sub _get_k_text
{
	my $num = shift;
	my @text = (
		'inactive',
		'very quiet',
		'quiet',
		'unsettled',
		'active',
		'minor storm',
		'major storm',
		'severe storm',
		'very severe storm',
		'extremely severe storm',
	);
	return $text[$num];
}

1;
__END__

=head1 NAME

Ham::Reference::Solar - Get basic solar data from the web that's useful for Amateur Radio applications.

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

  use Ham::Reference::Solar;

  my $solar = new Ham::Reference::Solar;
  die $solar->error_message if $solar->is_error;

  # access data with a hash reference

  foreach (sort keys %{$solar->get_hashref})
  {
     print "$_ = $solar->{$_}\n";
  }

  # or access data with the get method

  foreach (sort @{$solar->all_item_names})
  {
     print "$_ = ".$solar->get($_)."\n";
  }

=head1 DESCRIPTION

The C<Ham::Reference::Solar> module makes use of WM7D's Solar Resource Page to "scrape" (parse) data
and return it for your use.

Please note that this module depends on the current formatting of the web site, and if it changes, this
module will no longer work until I have a chance to update it.

=head1 CONSTRUCTOR

=head2 new()

 Usage    : my $solar = Ham::Reference::Solar->new();
 Function : creates a new Ham::Reference::Solar object
 Returns  : a Ham::Reference::Solar object
 Args     : a hash:
            key       required?   value
            -------   ---------   -----
            timeout   no          an integer of seconds to wait for
                                  the timeout of the web site
                                  default = 10

=head1 METHODS

=head2 get()

 Usage    : my $sunspots = $solar->get( $data_item_name );
 Function : gets a single item of solar data
 Returns  : a Ham::Reference::Solar object
 Args     : a single item from the list of data items below

=head2 set()

 Usage    : $solar->set( $data_item_name, $new_value );
 Function : gets a single item of solar data
 Returns  : n/a
 Args     : data-item: see the list of data items below
            data-value: any value with which you'd like to override the actual value

=head2 get_hashref()

 Usage    : my $hashref = $solar->get_hashref();
 Function : get all current solar data
            (this is probably the easiest way to access data)
 Returns  : a hash reference
 Args     : n/a

=head2 all_item_names()

 Usage    : my $arrayref = $solar->all_item_names();
 Function : get an array reference of all solar data items available
            from the object   
 Returns  : an array reference
 Args     : n/a

=head2 is_error()

 Usage    : if ( $solar->is_error() )
 Function : test for an error if one was returned from the call to the web site
 Returns  : a string, the error message
 Args     : n/a

=head2 error_message()

 Usage    : my $err_msg = $solar->error_message();
 Function : if there was an error message when trying to call the site, this is it
 Returns  : a string, the error message
 Args     : n/a

=head1 DATA ITEMS

The following items are available from the object.  Use them with the get() method
or access them with the get_hashref() method.

=over 4

=item sfi

Solar flux index.

=item a-index

The A-index number.

=item a-index-text

The text interpretation of the A-index.

=item k-index

The K-index number.

=item k-index-text

The text interpretation of the K-index.

=item forecast

Brief text forecast for the next 24 hours

=item summary

Bried text summary for the past 24 hours.

=item sunspots

Current sunspot count.

=item image

URL for the current solar image from the Solar and Heliosphereic Observatory.

=item image_thumbnail

URL for the current thumbnail sized solar image from the Solar and Heliosphereic Observatory.

=item time

Time of the last update.

=back

=head1 TODO

=over 4

=item * Convert date to something more useful.

=item * Add more data items.

=item * Improve documentation and error checking.

=item * Maybe improve the synopsis.

=back

=head1 ACKNOWLEDGEMENTS

This module gets its data from WM7D's Solar Resource Page at http://www.wm7d.net/hamradio/solar.
Thanks to Mark A. Downing!

=head1 AUTHOR

Brad McConahay N8QQ <brad@n8qq.com>

=head1 COPYRIGHT AND LICENSE

C<Ham::Reference::Solar> is Copyright (C) 2008-2010 Brad McConahay N8QQ.

This module is free software; you can redistribute it and/or
modify it under the terms of the Artistic License 2.0. For
details, see the full text of the license in the file LICENSE.

This program is distributed in the hope that it will be
useful, but it is provided "as is" and without any express
or implied warranties. For details, see the full text of
the license in the file LICENSE.
