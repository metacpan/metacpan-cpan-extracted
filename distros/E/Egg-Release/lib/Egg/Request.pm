package Egg::Request;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Request.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;

our $VERSION= '3.02';

our $MP_VERSION= 0;

sub mp_version { $MP_VERSION }

{
	my $r_class;
	sub _import {
		my($e)= @_;
		$r_class= Egg::Request::handler->_import($e);
		no warnings 'redefine';
		*request= sub { $_[0]->{request} ||= $r_class->new(@_) };
		*req= \&request;
		$e->next::method;
	}
	sub _setup_comp {
		my $e= shift;
		$r_class->_setup_request($e, @_);
		$e->next::method(@_);
	}
  };

package Egg::Request::handler;
use strict;
use warnings;
use CGI::Cookie;
use CGI::Util qw/ unescape /;
use base qw/ Egg::Base /;
use Carp qw/ croak /;

__PACKAGE__->mk_accessors(qw/ r path /);

{
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	for ( qw{ REMOTE_USER SCRIPT_NAME
	  REQUEST_URI PATH_INFO HTTP_REFERER HTTP_ACCEPT_ENCODING },
	  [qw{ REMOTE_ADDR 127.0.0.1 }],    [qw{ REQUEST_METHOD GET }],
	  [qw{ SERVER_NAME localhost }],    [qw{ SERVER_SOFTWARE cmdline }],
	  [qw{ SERVER_PROTOCOL HTTP/1.1 }], [qw{ HTTP_USER_AGENT local }],
	  [qw{ SERVER_PORT 80 }] ) {
		my($key, $accessor, $default)=
		   ref($_) ? ($_->[0], lc($_->[0]), $_->[1]): ($_, lc($_), "");
		*{__PACKAGE__."::$accessor"}= sub { $ENV{$key} || $default };
	}
  };

*agent    = \&http_user_agent;  *user_agent = \&http_user_agent;
*protocol = \&server_protocol;  *user       = \&remote_user;
*method   = \&request_method;   *port       = \&server_port;
*addr     = \&remote_addr;      *address    = \&remote_addr;
*referer  = \&http_referer;     *url        = \&uri;
*accept_encoding = \&http_accept_encoding;
*mp_version = \&Egg::Request::mp_version;

sub host { $ENV{HTTP_HOST} || $ENV{SERVER_NAME} || 'localhost' }
sub args { $ENV{QUERY_STRING} || $ENV{REDIRECT_QUERY_STRING} || "" }

sub _import {
	my($class, $e)= @_;
	my $r_class= $e->global->{request_class}=
	   $ENV{ uc($e->project_name). '_REQUEST_CLASS'} || do {
		($ENV{MOD_PERL} and ModPerl::VersionUtil->require) ? do {
			my $mp_util= 'ModPerl::VersionUtil';
			$MP_VERSION= $mp_util->mp_version;
			  $MP_VERSION  > 2  ? 'Egg::Request::Apache::MP20' :
			  $mp_util->is_mp2  ? 'Egg::Request::Apache::MP20' :
			  $mp_util->is_mp19 ? 'Egg::Request::Apache::MP19' :
			  $mp_util->is_mp1  ? 'Egg::Request::Apache::MP13' :
			  do {
				$MP_VERSION= 0;
				warn qq{ Unsupported mod_perl v$MP_VERSION };
				'Egg::Request::CGI';
			  };
		  }: 'Egg::Request::CGI';
	  };
	$r_class->require or die $@;
	no warnings 'redefine';
	*params= $r_class->can('parameters');
	$r_class->_init_handler($e);
	$r_class;
}
sub _init_handler {
	my($class, $e)= @_;
	no strict 'refs';  ## no critic.
	no warnings 'redefine';
	*{$e->namespace. '::handler'}=
	     $e->can('run') || die q{ $e->run is not found. };
}
sub is_get {
	$_[0]->method=~m{^GET}i ? 1: 0;
}
sub is_post {
	$_[0]->method=~m{^POST}i ? 1: 0;
}
sub is_head {
	$_[0]->method=~m{^HEAD}i ? 1: 0;
}
sub _setup_request {
	my($class, $e)= @_;
	my $pname= $e->project_name;
	no strict 'refs';  ## no critic.
	no warnings 'redefine';
	if (my $max= $e->config->{max_snip_deep}) {
		*{"${pname}::___request_max_snip_deep"}= sub {
			my($egg, $snip)= @_;
			$egg->finished('403 Forbidden') if $max < scalar(@$snip);
		  };
	} else {
		*{"${pname}::___request_max_snip_deep"}= sub { };
	}
	if (my $regexp= $e->config->{request_path_trim}) {
		*{"${pname}::___request_path_trim"}= sub {
			my($egg, $path)= @_;
			$$path=~s{$regexp} [];
		  };
	} else {
		*{"${pname}::___request_path_trim"}= sub { };
	}
	@_;
}
sub new {
	my($class, $e)= @_;
	my $req= bless { e=> $e }, $class;
	my $path;
	if ($ENV{REDIRECT_URI}) {
		$path= $ENV{PATH_INFO} || $ENV{REDIRECT_URI} || '/';
	} else {
		$path = $ENV{SCRIPT_NAME} || "";
		$path =~s{/+$} [];
		$path.= $ENV{PATH_INFO} if $ENV{PATH_INFO};
	}
	$e->___request_path_trim(\$path);
	$req->path( $path=~m{^/} ? $path: "/$path" );
	# Request parts are generated.
	$path=~s{\s+} []g; $path=~s{^/+} []; $path=~s{/+$} [];
	$e->___request_max_snip_deep( $e->snip([ split /\/+/, $path ]) );
	$e->debug_out("# + Request Path : /$path");
	$req;
}
sub parameters {
	my($req)= @_;
	$req->{parameters} ||= do {
		my $r= $req->r;
		my %params;
		$params{$_}= $r->param($_) for $r->param;
		\%params;
	  };
}
sub snip {
	shift->e->snip(@_);
}
sub cookies {
	my($req)= @_;
	$req->{cookies} ||= do { fetch CGI::Cookie || {} };
}
sub cookie {
	my $req= shift;
	my $cookie= $req->cookies;
	return keys %$cookie if @_== 0;
	($_[0] && exists($cookie->{$_[0]})) ? $cookie->{$_[0]}: undef;
}
sub cookie_value {
	my $req= shift;
	my $key= shift || return "";
	my $cookie= $req->cookies->{$key} || return "";
	$cookie->value || "";
}
sub cookie_more {
	my $req= shift;
	my $key= shift || croak 'I want cookie key.';
	my $val= defined($_[0]) ? $_[0]: croak 'I want cookie value.';
	if (ref($val) ne 'ARRAY') {
		my @tmp= map{ unescape($_) }(split( /[&;]/, $val. '&dmy'));
		pop @tmp;
		$val= \@tmp;
	}
	$req->cookies->{$key}= CGI::Cookie->new( -name=> $key, -value=> $val );
}
sub secure {
	$_[0]->{secure} ||= (
	     ($ENV{HTTPS} && lc($ENV{HTTPS}) eq 'on')
	  || ($ENV{SERVER_PORT} && $ENV{SERVER_PORT}== 443)
	  ) ? 1: 0;
}
sub scheme {
	$_[0]->{scheme} ||= $_[0]->secure ? 'https': 'http';
}
sub uri {
	my($req)= @_;
	$req->{uri} ||= do {
		require URI;
		my $uri = URI->new;
		my $path= $req->path; $path=~s{^/} [];
		$uri->scheme($req->scheme);
		$uri->host($req->host);
		$uri->port($req->port);
		$uri->path($path);
		$ENV{QUERY_STRING} and $uri->query($ENV{QUERY_STRING});
		$uri->canonical;
	 };
}
sub remote_host {
	my($req)= @_;
	$req->{remote_host} ||= do {
		$ENV{REMOTE_HOST}
		 || gethostbyaddr(pack("C*", split(/\./, $req->remote_addr)), 2)
		 || $req->remote_addr;
	 };
}
sub host_name {
	my($req)= @_;
	$req->{host_name} ||= do {
		my $host= $req->host;
		$host=~s{\:\d+$} [];
		$host;
	  };
}
sub output {
	my $req   = shift;
	my $header= shift || \"";
	my $body  = shift || \"";
	CORE::print STDOUT $$header, ($$body || "");
}
sub result  {
	my($req)= @_;
	my $code= $req->e->response->status || return 0;
	$code== 200 ? 0: $code;
}

1;

__END__

=head1 NAME

Egg::Request - WEB request processing for Egg. 

=head1 SYNOPSIS

  # The object is acquired.
  my $req= $e->request;
    
  # The query data is acquired specifying the name.
  my $data= $req->param('query_name');
    
  # The mass of the query data is obtained. 
  my $params= $req->params;
    
  # Passing the requested place is obtained.
  my $path= $req->path
  
  # Cookie is acquired specifying the name.
  my $cookie= $req->cookie('cookie_name');
  
  # The mass of Cookie is acquired.
  my $cookies= $req->cookies;
  
  # The content of cookie is acquired. $cookie-E<gt>value is done at the same time.
  my $cookie_value= $req->cookie_value('cookie_name');

=head1 DESCRIPTION

The WEB request processing for the Egg framework is done.

If mod_perl can be used, it is composed by L<Egg::Request::Apache> system class
though this module is usually composed in the shape succeeded to to L<Egg::Request::CGI>.

Please set environment variable [PROJECT_NAME]_REQUEST_CLASS when you use another
request class.
Please look at the source of 'bin/dispatch.fcgi' about the use example.
After L<Egg::Request::FastCGI> is set to the environment variable in the BEGIN
block, it starts.

=head1 METHODS

The main body of this module is built into the component of the project.

=head2 request

The handler object of this module is returned.

=over 4

=item * Alias = req

=back

=head1 HANDLER METHODS

=head2 new

Constructor. It is not necessary to call from the application.

  my $req= $e->request;

=head2 r

The object that is basic of the processing of this module is returned.
In a word, the object of CGI.pm or L<Apache::Request> is restored.

=head2 mp_version

The version of mod_perl is returned.

0 returns whenever it is not composed of the Egg::Apache system.

=head2 is_get

When the request method is GET, true is restored.

=head2 is_post

When the request method is POST, true is restored.

=head2 is_head

The request method returns and GET and POST return HEAD request and considering
true when not is.

Please use 'request_method' or 'Method' when you want to check the request method in detail.

=head2 parameters

The mass of request query is returned by the HASH reference.

  $e->parameters->{'query_name'};

=over 4

=item * Alias = params 

=back

=head2 param ([KEY], [VALUE])

When the argument is omitted, the list of the key to the request query is 
returned.

When KEY is given, the content of the corresponding request query is returned.

When VALUE is given, the request query is set.

  my @key_list= $req->param;
  
  my $hoge= $req->param('hoge');
  
  $req->param( hoge => 'boo' );

=head2 snip

It relays it to $e-E<gt>snip. Please look at the document of L<Egg::Util>.

=head2 cookies

The data received with cookie is returned.
The object of L<CGI::Cookie> is restored.

  while (my($key, $value)= each %{$req->cookies}) {
    $cookie{$key}= $value->value;
  }

=head2 cookie ([KEY])

The content of cookie specified with KEY is acquired.

It is necessary to use the value method further for obtaining data.

  my $gao= $req->cookie('gao')->value;

This method doesn't support the set of the value.

Cookie returned with the response header must be used and set must use the cookie
method of L<Egg::Response>.

=head2 cookie_value ([KEY])

Cookie specified with KEY is returned and the result of receipt value is 
returned.

  my $gao= $req->cookie_value('gao');

=head2 path

Passing information on the requested place is returned.

=head2 remote_user

The content of environment variable REMOTE_USER is returned.

=over 4

=item * Alias = user

=back

=head2 script_name

The content of environment variable SCRIPT_NAME is returned.

=head2 request_uri

The content of environment variable REQUEST_URI is returned.

=head2 path_info

The content of environment variable PATH_INFO is returned.

=head2 http_referer

The content of environment variable HTTP_REFERER is returned.

=over 4

=item * Alias = referer

=back

=head2 http_accept_encoding

The content of environment variable HTTP_ACCEPT_ENCODING is returned.

=over 4

=item * Alias = accept_encoding

=back

=head2 remote_addr

The content of environment variable REMOTE_ADDR is returned.

Default is '127.0.0.1'.

=over 4

=item * Alias = addr

=back

=head2 request_method

The content of environment variable REQUEST_METHOD is returned.

Default is GET.

=over 4

=item * Alias = method

=back

=head2 server_name

The content of environment variable SERVER_NAME is returned.

Default is localhost.

=head2 server_software

The content of environment variable SERVER_SOFTWARE is returned.

Default is cmdline.

=head2 server_protocol

The content of environment variable SERVER_PROTOCOL is returned.

Default is 'HTTP/1.1'.

=over 4

=item * Alias = protocol

=back

=head2 http_user_agent

The content of environment variable HTTP_USER_AGENT is returned.

Default is local.

=over 4

=item * Alias = agent, user_agent

=back

=head2 server_port

The content of environment variable SERVER_PORT is returned.

Default is 80.

=over 4

=item * Alias = port

=back

=head2 secure

True is returned if the request is due to SSL.

=head2 scheme

The URI scheme when requesting it is returned.

=head2 uri

It composes of information that receives requested URI again and it returns it.

=over 4

=item * Alias = url

=back

=head2 remote_host

Host information on the requested client is returned. Remote_addr is returned
when not obtaining it.

=head2 host

Host information on the WEB server under operation is returned.

=head2 host_name

When the port number is included in the content of host, the value in which it
is excluded is returned.

=head2 output ([HEDER_SCALAR_REF], [BODY_SCALAR_REF])

The received content is output to STDOUT.

=head2 result

The response status is returned from L<Egg::Response> as a receipt result code.

When the response status is undefined or 200, 0 is always returned.

=head2 SEE ALSO

L<Egg::Release>
L<Egg::Request::CGI>,
L<Egg::Request::FastCGI>,
L<Egg::Request::Apache>,
L<Egg::Base>,
L<ModPerl::VersionUtil>,
L<URI>

=head2 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head2 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

