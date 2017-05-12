########################################################################
#
# $Id: SocksChain10.pm,v 1.7 2009-11-21 20:25:47 gosha Exp $
#
# Copyright (C) Igor V. Okunev gosha<at>prv.mts-nn.ru 2005
#
#      All rights reserved. This library is free software;
#      you can redistribute it and/or modify it under the
#               same terms as Perl itself.
#
########################################################################

package LWP::Protocol::https::SocksChain10;

use strict;
use vars qw( @ISA $VERSION @EXTRA_SOCK_OPTS );

use Net::SC;

use HTTP::Response;
use HTTP::Status;
use IO::Select;
use IO::Socket::SSL;
use LWP::Protocol;

($VERSION='$Revision: 1.7 $')=~s/^\S+\s+(\S+)\s+.*/$1/;

local $^W = 1;

@ISA = qw(
				LWP::Protocol
				IO::Socket::SSL
		);

sub IO::Socket::SSL::SSL_HANDLE::READ { ${shift()}->read     (@_) }

my $CRLF = "\015\012";

sub _new_socket
{
	my($self, $host, $port, $timeout ) = @_;

	my %cfg = (
				PeerHost	=> $host,
				PeerPort	=> $port,
				timeout		=> $timeout,
				$self->_extra_sock_opts($host, $port) );

	#
	# client certificate support
	#
	if ( defined $ENV{HTTPS_KEY_FILE} and not exists $cfg{SSL_key_file} ) {
		$cfg{SSL_key_file} = $ENV{HTTPS_KEY_FILE};
	}

	if ( defined $ENV{HTTPS_CA_DIR} and not exists $cfg{SSL_ca_path} ) {
		$cfg{SSL_ca_path} = $ENV{HTTPS_CA_DIR}; 
	}

	if ( defined $ENV{HTTPS_CA_FILE} and not exists $cfg{SSL_ca_file} ) {
		$cfg{SSL_ca_file} = $ENV{HTTPS_CA_FILE};
	}

	if ( defined $ENV{HTTPS_CERT_FILE} and not exists $cfg{SSL_cert_file} ) {
		$cfg{SSL_cert_file} = $ENV{HTTPS_CERT_FILE};
	}

	if ( not exists $cfg{SSL_use_cert} and exists $cfg{SSL_cert_file} ) {
		$cfg{SSL_use_cert} = 1
	}

	my $sc = Net::SC->new( %cfg ) || die $!;

	unless ( ( my $rc = $sc->connect( $host, $port ) ) == SOCKS_OKAY ) {
		die socks_error($rc) . "\n";
	}

	my $obj = bless $sc->sh;

	if ( $IO::Socket::SSL::VERSION > 0.97 ) {
		$obj->configure_SSL( \%cfg ) && $obj->connect_SSL();
	} else {
		$obj->configure_SSL( \%cfg ) && $obj->connect_SSL($sc->sh);
	}

	unless ($obj) {
# IO::Socket leaves additional error messages in $@
		$@ =~ s/^.*?: //;
		die "Can't connect to $host:$port ($@)";
	}

# perl 5.005's IO::Socket does not have the blocking method.
	eval { $obj->blocking(0); };

	return $obj;
}

sub _extra_sock_opts  # to be overridden by subclass
{
	return @EXTRA_SOCK_OPTS;
}

sub _check_sock
{
    my($self, $req, $sock) = @_;
    my $check = $req->header("If-SSL-Cert-Subject");
    if (defined $check) {
	my $cert = $sock->get_peer_certificate ||
	    die "Missing SSL certificate";
	my $subject = $cert->subject_name;
	die "Bad SSL certificate subject: '$subject' !~ /$check/"
	    unless $subject =~ /$check/;
	$req->remove_header("If-SSL-Cert-Subject");  # don't pass it on
    }
}

sub _get_sock_info
{
    my $self = shift;
    #$self->SUPER::_get_sock_info(@_);
    my($res, $sock) = @_;
    $res->header("Client-SSL-Cipher" => $sock->get_cipher);
    my $cert = $sock->get_peer_certificate;
    if ($cert) {
	$res->header("Client-SSL-Cert-Subject" => $cert->subject_name);
	$res->header("Client-SSL-Cert-Issuer" => $cert->issuer_name);
    }
    $res->header("Client-SSL-Warning" => "Peer certificate not verified");
}

sub _fixup_header
{
	my($self, $h, $url) = @_;

	$h->remove_header('Connection');  # need support here to be useful

# HTTP/1.1 will require us to send the 'Host' header, so we might
# as well start now.
	my $hhost = $url->authority;
	
	$hhost =~ s/^([^\@]*)\@//;  # get rid of potential "user:pass@"
	$h->header('Host' => $hhost) unless defined $h->header('Host');

# add authorization header if we need them.  HTTP URLs do
# not really support specification of user and password, but
# we allow it.
	if (defined($1) && not $h->header('Authorization')) {
		require URI::Escape;
		$h->authorization_basic(map URI::Escape::uri_unescape($_),
				split(":", $1, 2));
	}
}

sub request
{
	my($self, $request, undef, $arg, $size, $timeout) = @_;

	$size ||= 4096;

# check method
	my $method = $request->method;

	unless ($method =~ /^[A-Za-z0-9_!\#\$%&\'*+\-.^\`|~]+$/) {  # HTTP token
		return new HTTP::Response &HTTP::Status::RC_BAD_REQUEST,
				   'Library does not allow method ' .
				   "$method for 'http:' URLs";
	}

	my $url = $request->url;

	my $host = $url->host;
	my $port = $url->port;
	my $fullpath = $url->path_query;

	$fullpath = "/" unless length $fullpath;

# connect to remote site
	my $socket = $self->_new_socket( $host, $port, $timeout );

	$self->_check_sock($request, $socket);

	my $sel = IO::Select->new($socket) if $timeout;

	my $request_line = "$method $fullpath HTTP/1.0$CRLF";

	my $h = $request->headers->clone;
	my $cont_ref = $request->content_ref;

	$cont_ref = $$cont_ref if ref($$cont_ref);
	
	my $ctype = ref($cont_ref);

# If we're sending content we *have* to specify a content length
# otherwise the server won't know a messagebody is coming.
	if ($ctype eq 'CODE') {
		die 'No Content-Length header for request with dynamic content'
			unless defined($h->header('Content-Length')) ||
				$h->content_type =~ /^multipart\//;
# For HTTP/1.1 we could have used chunked transfer encoding...
	} else {
		$h->header('Content-Length' => length $$cont_ref)
			if defined($$cont_ref) && length($$cont_ref);
	}

	$self->_fixup_header($h, $url);

	my $buf = $request_line . $h->as_string($CRLF) . $CRLF;
	my $n;  # used for return value from syswrite/sysread
		my $length;
	my $offset;

# syswrite $buf
	$length = length($buf);
	$offset = 0;
	
	while ( $offset < $length ) {
		die "write timeout" if $timeout && !$sel->can_write($timeout);
		$n = $socket->syswrite($buf, $length-$offset, $offset );
		die $! unless defined($n);
		$offset += $n;
	}
	
	if ($ctype eq 'CODE') {
		while ( ($buf = &$cont_ref()), defined($buf) && length($buf)) {
# syswrite $buf
			$length = length($buf);
			$offset = 0;
			while ( $offset < $length ) {
				die "write timeout" if $timeout && !$sel->can_write($timeout);
				$n = $socket->syswrite($buf, $length-$offset, $offset );
				die $! unless defined($n);
				$offset += $n;
			}
		}
	} elsif (defined($$cont_ref) && length($$cont_ref)) {
# syswrite $$cont_ref
		$length = length($$cont_ref);
		$offset = 0;
		while ( $offset < $length ) {
			die "write timeout" if $timeout && !$sel->can_write($timeout);
			$n = $socket->syswrite($$cont_ref, $length-$offset, $offset );
			die $! unless defined($n);
			$offset += $n;
		}
	}

# read response line from server

	my $response;
	$buf = '';

# Inside this loop we will read the response line and all headers
# found in the response.
	while (1) {
		die "read timeout" if $timeout && !$sel->can_read($timeout);
		$n = $socket->sysread($buf, $size, length($buf));
		die $! unless defined($n);
		die "unexpected EOF before status line seen" unless $n;

		if ($buf =~ s/^(HTTP\/\d+\.\d+)[ \t]+(\d+)[ \t]*([^\012]*)\012//) {
# HTTP/1.0 response or better
			my($ver,$code,$msg) = ($1, $2, $3);
			$msg =~ s/\015$//;
			$response = HTTP::Response->new($code, $msg);
			$response->protocol($ver);

# ensure that we have read all headers.  The headers will be
# terminated by two blank lines
			until ($buf =~ /^\015?\012/ || $buf =~ /\015?\012\015?\012/) {
# must read more if we can...
				die "read timeout" if $timeout && !$sel->can_read($timeout);
				my $old_len = length($buf);
				$n = $socket->sysread($buf, $size, $old_len);
				die $! unless defined($n);
				die "unexpected EOF before all headers seen" unless $n;
			}

# now we start parsing the headers.  The strategy is to
# remove one line at a time from the beginning of the header
# buffer ($res).
			my($key, $val);
			while ($buf =~ s/([^\012]*)\012//) {
				my $line = $1;

# if we need to restore as content when illegal headers
# are found.
				my $save = "$line\012"; 
	
				$line =~ s/\015$//;
				last unless length $line;

				if ($line =~ /^([a-zA-Z0-9_\-.]+)\s*:\s*(.*)/) {
					$response->push_header($key, $val) if $key;
					($key, $val) = ($1, $2);
				} elsif ($line =~ /^\s+(.*)/ && $key) {
					$val .= " $1";
				} else {
					$response->push_header("Client-Bad-Header-Line" => $line);
				}
			}
			$response->push_header($key, $val) if $key;
			last;
	
		} elsif ((length($buf) >= 5 and $buf !~ /^HTTP\//) or
			$buf =~ /\012/ ) {
# HTTP/0.9 or worse
			$response = HTTP::Response->new(&HTTP::Status::RC_OK, "OK");
			$response->protocol('HTTP/0.9');
			last;

		} else {
# need more data
		}
	};
	$response->request($request);
	$self->_get_sock_info($response, $socket);

	if ($method eq "CONNECT") {
		$response->{client_socket} = $socket;  # so it can be picked up
			$response->content($buf);     # in case we read more than the headers
			return $response;
	}

	my $usebuf = length($buf) > 0;
	$response = $self->collect($arg, $response, sub {
			if ($usebuf) {
				$usebuf = 0;
				return \$buf;
			}
			die "read timeout" if $timeout && !$sel->can_read($timeout);
			my $n = $socket->sysread($buf, $size);
			die $! unless defined($n);
			return \$buf;
		} );

#	$socket->close;

	$response;
}

1;

__END__

=head1 NAME

LWP::Protocol::https::SocksChain10 - Speak HTTPs through Net::SC

=head1 SYNOPSIS

 use LWP::Protocol::https::SocksChain10;
 LWP::Protocol::implementor( https => 'LWP::Protocol::https::SocksChain10' );

 @LWP::Protocol::https::SocksChain10::EXTRA_SOCK_OPTS = ( Chain_len    => 2,
                                                         Random_Chain => 0,
                                                         ... );
 ....

=head1 DESCRIPTION

LWP::Protocol::https::SocksChain10 enables you to speak HTTPs through SocksChain ( Net::SC ).
To use it you need to overwrite the implementor class of the LWP 'https' scheme.

The interface of LWP::Protocol::https::SocksChain10 is similar to
LWP::Protocol::http10. To enable the new HTTP/1.1 protocol driver
instead of the old HTTP/1.0 driver use LWP::Protocol::https::SocksChain.

=head1 SEE ALSO

LWP, LWP::Protocol, Net::SC


=head1 AUTHOR

 Igor V. Okunev  mailto:igor<at>prv.mts-nn.ru
                 http://www.mts-nn.ru/~gosha
                 icq:106183300


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 - 2008  by Igor V. Okunev

All rights reserved. This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

