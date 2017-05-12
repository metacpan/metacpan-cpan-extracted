package Math::Matlab::Remote;

use strict;
use vars qw($VERSION $URI $TIMEOUT $USER $PASS);

BEGIN {
	$VERSION = sprintf "%d.%03d", q$Revision: 1.6 $ =~ /: (\d+)\.(\d+)/;
}

use Math::Matlab;
use base qw( Math::Matlab );

use HTTP::Request;
use HTTP::Response;
use LWP::UserAgent;
use URI::URL;

##-----  assign defaults, unless already set externally  -----
$URI		= ''	unless defined $URI;
$TIMEOUT	= 300	unless defined $TIMEOUT;	## default = 5 min
$USER		= ''	unless defined $USER;
$PASS		= ''	unless defined $PASS;

##-----  Public Class Methods  -----
sub new {
	my ($class, $href) = @_;
	my $self	= {
		uri		=> defined($href->{uri})		? $href->{uri}		: $URI,
		timeout	=> defined($href->{timeout})	? $href->{timeout}	: $TIMEOUT,
		user	=> defined($href->{user})		? $href->{user}		: $USER,
		pass	=> defined($href->{pass})		? $href->{pass}		: $PASS,
		err_msg	=> '',
		result	=> ''
	};

	bless $self, $class;
}

##-----  Public Object Methods  -----
sub execute {
	my ($self, $code, $rel_mwd) = @_;
	
	## set up the request
	my %form = (
		'RAW_OUTPUT'	=> 1,
		'CODE'			=> $code,
		'REL_MWD'		=> $rel_mwd || ''
	);
	my $request = new HTTP::Request('POST' => $self->uri);
	$request->content_type('application/x-www-form-urlencoded');
	my $curl = new URI::URL('http:');
	$curl->query_form( %form );
	$request->content($curl->equery);
 	$request->authorization_basic($self->user, $self->pass)	if $self->user;

	## set up the user agent
	my $ua = new LWP::UserAgent;
	$ua->agent( __PACKAGE__ . "/$VERSION " . $ua->agent);
	$ua->timeout($self->timeout);

	## do the request
	my $response = $ua->request($request);
	
	if ($response->is_error) {
		$self->err_msg( $response->status_line );
		return 0;
	} else {
		$self->{'result'} = $response->content;
		return 1;
	}
}

sub uri {		my $self = shift; return $self->_getset('uri',		@_); }
sub timeout {	my $self = shift; return $self->_getset('timeout',	@_); }
sub user {		my $self = shift; return $self->_getset('user',		@_); }
sub pass {		my $self = shift; return $self->_getset('pass',		@_); }

1;
__END__

=head1 NAME

Math::Matlab::Remote - Interface to a remote Matlab process.

=head1 SYNOPSIS

  use Math::Matlab::Remote;
  $matlab = Math::Matlab::Remote->new({
      uri     => 'https://server1.mydomain.com',
      timeout => 300,
      user    => 'me',
      pass    => 'my_password'
  });
  
  my $code = q/fprintf( 'Hello world!\n' );/
  if ( $matlab->execute($code) ) {
      print $matlab->fetch_result;
  } else {
      print $matlab->err_msg;
  }

=head1 DESCRIPTION

Math::Matlab::Remote implements an interface to a remote Matlab server
(see C<Math::Matlab::Server>). It uses the LWP package to access the
server via the HTTP protocol. The Remote object has the URI of the
server, a timeout value for the requests and a user name and password
used for basic authentication of the request.

The URI specifies the server to pass the request to along with some
optional PATH_INFO which is prepended to the relative Matlab working
directory passed through the exectute() method. The server has it's own
Math::Matlab object (typically Local or Pool), which it uses to perform
the computation and send back the resulting raw output.

E.g. If a server is set up with it's base URL at
'http://my.server.com/matlab/', corresponding to a Math::Matlab::Local
object with root_mwd '/opt/matlab-server', then passing 'bar' as the
relative Matlab working directory to the execute() method of a Remote
whose uri field is set to 'http://my.server.com/matlab/foo' will cause
the Local object on the server to attempt to change to the directory
'/opt/matlab-server/foo/bar' before attemptting to exectute the code.

=head1 Attributes

=over 4

=item uri

A string containing the URI of the corresponding Matlab server (see
Math::Matlab::Server). Any PATH_INFO in the URI beyond the root URI of
the server will be prepended to the relative Matlab working directory
passed through the exectute command.

The default is taken from the package variable $URI.

=item timeout

The maximum time the remote should wait for a response from the server
(in seconds) before giving up. The default is taken from the package
variable $TIMEOUT, whose default value is 300.

=item user

A string containing the user name to use for basic authentication when
making a request to the server. The default is taken from the package
variable $USER.

=item pass

A string containing the password to use for basic authentication when
making a request to the server. The default is taken from the package
variable $PASS.

=back

=head1 METHODS

=head2 Public Class Methods

=over 4

=item new

 $matlab = Math::Matlab::Remote->new;
 $matlab = Math::Matlab::Remote->new( {
    uri     => '/usr/local/matlab -nodisplay -nojvm',
    timeout => '/root/matlab/working/directory/'
    user    => 'me',
    pass    => 'my_password'
 } )

Constructor: creates an object which can run Matlab programs and return
the output. Attributes 'uri', 'timeout', 'user' and 'pass' can be
initialized via a hashref argument to new(). Defaults for these values
are taken from the package variables $URI, $TIMEOUT, $USER and $PASS,
respectively.

=back

=head2 Public Object Methods

=over 4

=item execute

 $TorF = $matlab->execute($code)
 $TorF = $matlab->execute($code, $relative_mwd)

Takes a string containing Matlab code and sends it to a Matlab server
(see Math::Matlab::Server) for execution. It stores the returned result
in the object. The optional second argument specifies the Matlab working
directory relative relative to the URI being accessed. Returns true if
successful, false otherwise.

=item uri

 $uri = $matlab->uri
 $uri = $matlab->uri($uri)

Get or set the URI attribute.

=item timeout

 $timeout = $matlab->timeout
 $timeout = $matlab->timeout($timeout)

Get or set the timeout value.

=item user

 $user = $matlab->user
 $user = $matlab->user($user)

Get or set the user for basic authentication of server request.

=item pass

 $pass = $matlab->pass
 $pass = $matlab->pass($pass)

Get or set the password for basic authentication of server request.

=back

=head1 CHANGE HISTORY

=over 4

=item *

10/16/02 - (RZ) Created.

=back

=head1 COPYRIGHT

Copyright (c) 2002 PSERC. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

  Ray Zimmerman, <rz10@cornell.edu>

=head1 SEE ALSO

  perl(1), Math::Matlab

=cut
