package Ham::Resources::HamQTH;

use strict;
use warnings;

use LWP::UserAgent;
use XML::LibXML::Reader;
use vars qw($VERSION);
use Data::Dumper;

our $VERSION = '0.06';

my $qth_url = "http://www.hamqth.com";
my $site_name = 'HamQTH XML Database service';
my $default_timeout = 10;
my $default_strip_html = 1;


sub new 
{
	my $class = shift;
	my %args = @_;
	my $self = {};
	bless $self, $class;

	$self->_set_agent;
	$self->set_timeout($args{timeout});
	$self->set_callsign($args{callsign}) if $args{callsign}; 
	$self->set_username($args{username}) if $args{username};
	$self->set_password($args{password}) if $args{password};
	$self->set_strip_html($args{strip_html_bio});
	return $self;
}

sub login 
{
	my $self = shift;
	my $url = "$qth_url/xml.php?u=".$self->{_username}."&p=".$self->{_password};
	my $login = $self->_get_content($url);
}	 

sub set_callsign 
{
	my $self = shift;
	my $callsign = shift;
	$callsign =~ tr/a-z/A-Z/;
	$self->{_callsign} = $callsign;
}

sub set_username
{
	my $self = shift;
	my $username = shift;
	$self->{_username} = $username;
}

sub set_password
{
	my $self = shift;
	my $password = shift;
	$self->{_password} = $password;
}

sub set_strip_html
{
	my $self = shift;
	my $strip_html_bio = shift;
	
	if (!$strip_html_bio) 
	{
		$strip_html_bio = 0;
	} else {
		$strip_html_bio = $default_strip_html;
	}
	
	$self->{_strip_html} = $strip_html_bio;
}
sub set_key
{
	my $self = shift;
	my $key = shift;
	$self->{_key} = $key;
}

sub set_timeout
{
	my $self = shift;
	my $timeout = shift || $default_timeout;
	$self->{_timeout} = $timeout;
}

sub get_session
{
	my $self = shift;
	return $self->{session_id};
}

sub get_list
{
	my $self = shift;
	my @tags;
       
	if ($self->{error})
        {
                push(@tags, $self->{error});
        }
        else
        {
		foreach my $tag (sort keys %{$self})
		{
			push(@tags, $tag) if ($tag !~ m/^_.+/i && $tag !~ m/@.+/i && $tag ne "HamQTH" && $tag ne "search" && $tag ne "session");
		}	
	}
	return \@tags;
}

sub get_bio
{
	my $self = shift;
	my $result = {};
	
	if (!$self->{_callsign}) 
	{
		$self->{error} = "Ops!! ... Without a callsign I can not search anything";
		&_clean_response($self);
	}	

	&_check_session_id($self);	
	
	if (!$self->{_session_id}) 
	{
		$self->login;
	}
	
	if ($self->{error}) 
	{
		$result->{error} = $self->{error};
	} 
	else 
	{
		my $url = "$qth_url/xml.php?id=".$self->{_session_id}."&callsign=".$self->{_callsign}."&prg=".$self->{_agent};
		my $bio = $self->_get_content($url);
		$url = "$qth_url/xml_bio.php?id=".$self->{_session_id}."&callsign=".$self->{_callsign}."&prg=".$self->{_agent}."&strip_html=".$self->{_strip_html};
		$bio = $self->_get_content($url);
		
		if (!$bio->{_session_id}) {
			$self->{error} = $bio->{error};
			return undef;
		}
		$result = &_clean_response($bio);
	}
	return $result;
}

sub get_dxcc
{
	my $self = shift;
	my $result = {};
	
	if (!$self->{_callsign}) 
	{
		$self->{error} = "Ops!! ... Without a callsign I can not search anything";
		&_clean_response($self);
	}	

	&_check_session_id($self);	
	
	if (!$self->{_session_id}) 
	{
		$self->login;
	}
	
	if ($self->{error}) 
	{
		$result->{error} = $self->{error};
	} 
	else 
	{
		#my $url = "$qth_url/xml.php?id=".$self->{_session_id}."&callsign=".$self->{_callsign}."&prg=".$self->{_agent};
		#my $bio = $self->_get_content($url);
		my $url = "$qth_url/dxcc.php?id=".$self->{_session_id}."&callsign=".$self->{_callsign}."&prg=".$self->{_agent};
		my $bio = $self->_get_content($url);
		
		if (!$bio->{_session_id}) {
			$self->{error} = $bio->{error};
			return undef;
		}
		
		if ($self->{adif} == 0) 
			{
				$self->{error} = "Not a valid DXCC";
				&_clean_response($self);
		}	
		
		$result = &_clean_response($bio);
	}
	return $result;
}


# -----------------------
#	PRIVATE SUBS
# -----------------------

sub _set_agent
{
	my $self = shift;
	$self->{_agent} = "Ham-Resources-HamQTH-$VERSION";
}

sub _get_content
{
	my ($self, $url) = @_;
	my $ua = LWP::UserAgent->new( timeout=>$self->{_timeout} );
	$ua->agent( $self->{_agent} );
	my $request = HTTP::Request->new('GET', $url);
	my $response = $ua->request($request);

	if (!$response->is_success) 
	{
		$self->{error} = "Ops! ... ".$response->{_msg}." - ".HTTP::Status::status_message($response->code);
		return undef;
	}

	my $content = $response->content;
	$content =~ s/&/&amp;/; # this character will crash the parser
	my $reader = XML::LibXML::Reader->new( encoding => 'UTF-8', string => $content );
	my $tag_name;
	
	while ($reader->read) 
	{
		$tag_name = $reader->name if ($reader->nodeType == 1);
		$self->{_session_id} = $reader->value if ($reader->nodeType == 3 && $tag_name eq "session_id");
		$self->{$tag_name} = $reader->value if ($reader->nodeType == 3 && $tag_name ne "session_id");
	}
	if (!$self->{error} || $self->{error} ne 'Callsign not found' || $self->{error} eq '' ) {

		$self->{link} = $qth_url."/".$self->{_callsign} if length($self->{_callsign}) > 3;
	}
	&_save_session_id($self); # save SESSION ID
	return $self;
}

sub _clean_response 
{
	my $self = shift;
	my $result = {};
	foreach (sort keys %{$self})
	{
		if ($_ !~ m/^_.+/i && $_ !~ m/@.+/i && $_ ne "HamQTH" && $_ ne "search" && $_ ne "session" ) 
		{
			$result->{$_} = $self->{$_};
		}
	}
	return $result;
}

sub _check_session_id
{
	my $self = shift;
	
	if (-e "hamqth_session.id") {
	   open my $record_load, '<', 'hamqth_session.id' or $self->{error} = "Cannot open filename: $!";
		if (not $self->{error}) { return; }
		($self->{_session_id},$self->{_timestamp}) = split("-", $record_load);
		close $record_load;
		&_check_timestamp($self);
	} 
	else
	{
		$self->login;
	}
}	

sub _check_timestamp
{
	my $self = shift;
	my $time_actual_epoch = time();
	my $timestamp_epoch = $self->{_timestamp} || 0;
	my $timestamp_epoch_plus_1h = $timestamp_epoch + (1*60*60);

	if ($time_actual_epoch > $timestamp_epoch_plus_1h or $time_actual_epoch < $timestamp_epoch)
	{
		$self->login;
	}
}
	
sub _save_session_id
{
	my $self = shift;

   open my $record_session, '>', 'hamqth_session.id' or $self->{error} = "Cannot open filename: $!";
		my $my_session = $self->{_session_id}."-".time();
		print $record_session $my_session;
	close $record_session;	
	return $self;
}	


1;
__END__

=head1 NAME

Ham::Resources::HamQTH - A simple and easy object oriented front end for HAMQTH.COM Amateur Radio callsign free database service.

=head1 VERSION

Version 0.06

=head1 SYNOPSIS

	use Ham::Resources::HamQTH;

	my $qth = Ham::Resources::HamQTH->new(
		callsign => 'callsign to find',
		username => 'your HamQTH username',
		password => 'your HamQTH password'
	);

	# get information from one callsign found
	my $bio = $qth->get_bio;
	foreach (sort keys %{$bio}){
		print $_.": ".$bio->{$_}."\n";
	}
	
	# get DXCC information from one callsign found
	my $dxcc = $qth->get_dxcc;
	foreach (sort keys %{$dxcc}){
		print $_.": ".$dxcc->{$_}."\n";
	}
	
	# print a specific info
	my $bio = $qth->get_bio;
	print "grid: ".$bio->{grid};
	
	# get a list of available elements
	my $bio = $qth->get_list;
	
	
=head1 DESCRIPTION

The C<Ham::Resources::HamQTH> module provides an easy way to access Amateur 
Radio callsign data from the HamQTH.COM online free database.

This module uses the HamQTH XML database service, which requires a valid user 
account. Create an account is free.

The number of response elements by the XML database can be different between 
each callsign, depending if it has any information of a callsign or not. 

The duration of the SESSION is 1 hour, so the module save it a SESSION_ID and a 
timestamp into a file to check when is neccesary turn on login or use the 
saved SESSION_ID. 

=head1 CONSTRUCTOR

=head2 new()
	
 Usage	: my $qth = Ham::Resources::HamQTH->new(
		callsign => 'callsign  or DXCC code to search',
		username => 'your HamQTH username',
		password => 'your HamQTH password'
		);
 Funtion : creates a new Ham::Resources::HamQTH object
 Returns : an object
 Args	 : a hash:
	
 key		required?	value
 -------  	---------	-----
 callsign	yes		a text with the callsign or DXCC code to find
 username	yes		a text with a valid username HamQTH.com  account
 password	yes		a text with a valid password HamQTH.com  account
 timeout	no		an integer of seconds to wait for the timeout of the XML service. By default = 10
 strip_html_bio	no		binary for strip HTML code from the bio. By default = 0 (HTML code) 

=head1 METHODS

=head2 get_list()

 Usage	  : my $bio = $qth->get_list;
 Function : gets a list of elements (tags) availables of a callsign found 
 Returns  : an array
 Args	  : n/a

=head2 get_bio()		

 Usage	  : my $bio = $qth->get_bio;
 Function : retrieves data of a XML query, that is, all the data found a callsign or error occurred
 Returns  : a hash
 Args	  : n/a

=head2 get_dxcc()

 Usage: my $dxcc = $qth->get_dxcc;
 Function: provides detail info of a DXCC
 Returns: a hash
 Args: n/a 

=head2 error()

 Usage	  : my $error = $bio->{error}
 Function : retrieves an error message if not callsign found, lost internet connection, don't access to session file, fail on server response or run it without a callsign to find
 Returns  : a string, the error message. Only after call get_bio() method
 Args	  : n/a

=head1 EXPORT

None by default.

=head1 REQUIRES

=over 4

=item * LWP::UserAgent

=item * XML::LibXML::Reader;

=item * Internet connection

=back 


=head1 ACKNOWLEDGEMENTS

This module accesses the data provided free by Petr (OK2CQR). See L<http://www.hamqth.com>
DXCC tables provided by Martin (OK1RR).

=head1 SEE ALSO

You can view a complete example of use at L<http://cjuan.wordpress.com/hamresourceshamqth>

You can also find a test script in test folder, you just need to edit and add your user account HamQTH.com to work. The callsign is passed as an argument to the script from the command line.

You can create an account for use this module at L<http://www.hamqth.com>

=head1 AUTHOR

Carlos Juan, E<lt>ea3hmb_at_gmail.com> | E<lt>cjuan_at_cpan.org>

=head1 COPYRIGHT AND LICENSE

This module is free software; you can redistribute it and/or
modify it under the terms of the Artistic License 2.0. For
details, see the full text of the license in the file LICENSE.

This program is distributed in the hope that it will be
useful, but it is provided "as is" and without any express
or implied warranties. For details, see the full text of
the license in the file LICENSE.

Copyright (C) 2012-2014 by Carlos Juan Diaz (CJUAN) - EA3HMB E<lt>ea3hmb_at_gmail.com | E<lt>cjuan_at_cpan.org>



=cut
