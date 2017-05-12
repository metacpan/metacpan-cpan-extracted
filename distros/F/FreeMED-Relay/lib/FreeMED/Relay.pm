#!/usr/bin/perl
#
# $Id: Relay.pm 71 2007-08-14 00:33:05Z jeff $
#
# Authors:
#      Jeff Buchbinder <jeff@freemedsoftware.org>
#
# FreeMED Electronic Medical Record and Practice Management System
# Copyright (C) 1999-2006 FreeMED Software Foundation
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

#
#	FreeMED::Relay package for communicating with FreeMED 0.9.x+
#	

package FreeMED::Relay;

use LWP::UserAgent;
use HTTP::Request::Common;
use JSON;	# objToJson(), jsonToObj()
use HTTP::Cookies;

use vars qw{ $VERSION };
BEGIN {
	$VERSION = '0.2';
}

sub new {
	my $class = shift;
	my $debug = shift;
	my $self = {};
	bless $self, $class;
	$self->{'debug'} = $debug;
	$self->_init();
	$JSON::UnMapping = 1;
	$JSON::QuotApos = 1;
	$JSON::BareKey = 1;
	return $self;
}

sub set_credentials {
	my $self = shift;

	my ( $base_uri, $username, $password ) = @_;
	print "base_uri = $base_uri\n" if $self->{'debug'};
	print "username = $username\n" if $self->{'debug'};
	print "password = $password\n" if $self->{'debug'};
	$self->{base_uri} = $base_uri;
	$self->{username} = $username;
	$self->{password} = $password;
}

sub login {
	my $self = shift;
	if (!defined($self->{username}) or !defined($self->{password})) {
		die "login(): Must set credentials before logging in\n";
	}

	$self->_init() if (!defined($self->{ua}));
	my $login = $self->call(
		'org.freemedsoftware.public.Login.Validate',
		$self->{'username'},
		$self->{'password'},
	);
	$self->{'logged_in'} = true;
	return $login;
}

sub call {
	my $self = shift;
	my $method = shift;
	my @params = @_;

	if (!($method =~ /public/) && !$self->{'logged_in'}) {
		print "Must be logged in first\n" if $self->{'debug'};
		return undef;
	}

	my $count = 0; my %p;
	foreach my $param (@params) {
		print "param = '$param'\n";
		if ( $param =~ /^HASH\(/ && $param->{'@var'} ) {
			print "Found file upload var in $param->{'@var'}\n" if (@self->{debug});
			# Add file transfer under @var = var, @filename = filename
			$p{$param->{'@var'}} = [ $param->{'@filename'} ];
		} else {
			my $json = objToJson( $param );
			print "param = $param, count = $count, json = $json\n" if $self->{'debug'};
			$p{"param${count}"} = ($json ? $json : $param );
			$count++;
		}
	}
	my $res = $self->{ua}->request(
		POST $self->{base_uri}."/relay.php/json/${method}",
		Content_Type => 'form-data',
		Content => [ %p ]
	);
	$self->{'cookie_jar'}->save();
	print "content : ".$res->content."\n" if ($self->{debug});
	return jsonToObj ( $res->content );
}

sub _init {
	my $self = shift;
	$self->{'ua'} = LWP::UserAgent->new;
	$self->{'cookie_jar'} = HTTP::Cookies->new( 'autosave' => 1 );
	$self->{'ua'}->cookie_jar( $self->{'cookie_jar'} );
}

1;
__END__

=pod

=head NAME

FreeMED::Relay

=head1 SYNOPSIS

Provide access to FreeMED 0.9.x+ data relay

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item new ( %options )

Returns a FreeMED::Relay object.

C<new> takes "debug" as a boolean argument.

=item set_credentials ( $base_uri, $username, $password )

Sets the credentials used to access the FreeMED installation in question. The
C<$base_uri> variable should be the base name of the installation, such as
"http://localhost/freemed".

=item login ( )

Log into the specified installation of FreeMED. Returns true or false
depending on whether or not it is successful.

=item call ( $method, $params ... )

Execute a remote procedural call, translating to and from JSON transparently.
If an argument is a hash with the keys '@var' and '@filename' it is assumed
that the filename in question will be uploaded and attached to the form
variable '@var'.

=item _init ( )

Internal method for initializing the LWP user agent, cookie jar and other
special things.

=cut

