package Egg::Response;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Response.pm 338 2008-05-19 11:22:55Z lushe $
#
use strict;
use warnings;

our $VERSION = '3.01';

our $CRLF= "\015\012";

our %Status= (
  200 => 'OK',
  301 => 'Moved Permanently',
  302 => 'Moved Temporarily',
  303 => 'See Other',
  304 => 'Not Modified',
  307 => 'Temporarily Redirect',
  400 => 'Bad Request',
  401 => 'Unauthorized',
  403 => 'Forbidden',
  404 => 'Not Found',
  405 => 'Method Not Allowed',
  500 => 'Internal Server Error',
  );

sub response { $_[0]->{response} ||= Egg::Response::handler->new(@_) }

*res= \&response;

package Egg::Response::handler;
use strict;
use warnings;
use Egg::Response::Headers;
use Egg::Response::TieCookie;
use CGI::Cookie;
use CGI::Util qw/ expires /;
use Carp qw/ croak /;
use base qw/ Egg::Base /;

{
	no strict 'refs';  ## no critic.
	no warnings 'redefine';
	for (['Window-Target'], ['Content-Encoding'],
	     ['Content-Disposition', sub { qq{attachment; filename=$_[0]} }],
	     ['P3P', sub { qq{policyref="/w3c/p3p.xml", CP="$_[0]"} }, sub {
			$_[1] ? join(' ', @_)
			: ref($_[0]) eq 'ARRAY' ? join(' ', @{$_[0]}) : ($_[0] || "");
	       } ] ) {
		my $name  = $_->[0];
		my $tcode = $_->[1] || sub { $_[0] };
		my $acode = $_->[2] || sub { $_[0] };
		my $lcname= lc($name); $lcname=~s{\-} [_]g;
		*{__PACKAGE__."::$lcname"}= sub {
			my $head= shift->headers;
			if (@_) {
				my $value= $acode->(@_);
				delete($head->{$name}) if $head->{$name};
				return $_[0] ? $head->{$name}= $tcode->($value): "";
			}
			my $a= $head->{$name} || return "";
			$a->[1];
		  };
	}
	*attachment= \&content_disposition;
  };

__PACKAGE__->mk_accessors(qw/ nph no_content_length 
  is_expires last_modified content_type content_language location /);

sub new {
	my($class, $e)= @_;
	bless {
	  e => $e,
	  body=> undef,
	  status=> 0,
	  location => "",
	  parameters=> {},
	  content_type => "",
	  content_language => "",
	  no_content_length => 0,
	  set_modified => ($e->config->{set_modified_constant} || 0),
	  }, $class;
}
sub body {
	my $res= shift;
	return ($res->{body} || undef) unless @_;
	$res->{body}= $_[0] ? (ref($_[0]) ? $_[0]: \$_[0]): undef;
}
sub headers {
	$_[0]->{__headers} ||= Egg::Response::Headers->new($_[0]);
}
sub header {
	my $res = shift;
	my $body= shift || $res->body;
	my $e   = $res->e;
	my $header;
	my $headers= $res->{__headers} || {};
	my($status, $content_type);
	if ($res->nph) {
		$header.= ($e->request->protocol || 'HTTP/1.0')
		       .  ' '. ($res->status || '200 OK'). $CRLF
		       .  'Server: '. $e->request->server_software
		       .  $CRLF;
	}
	if ($status= $res->status) {
		$header = "Status: ${status}". $res->status_string. $CRLF;
		$header.= 'Location: '
		       . $res->location. $CRLF if $status=~/^30[1237]/;
		if ($content_type= $res->content_type || "") {
			$header.= "Content-Type: "
			       .  "@{[ $res->_ctype_check($content_type) ]}$CRLF";
		}
	} else {
		$content_type= $res->_ctype_check( $res->content_type
		  || $res->content_type($e->config->{content_type} || 'text/html') );
		$header.= "Content-Type: ${content_type}$CRLF";
	}
	my $regext= $e->config->{no_content_length_regex}
	         || qr{(?:^text/|/(?:rss\+)?xml)};
	if ($content_type=~m{$regext}i) {
		if (my $language= $res->content_language) {
			$header.= "Content-Language: ${language}$CRLF";
		}
	} elsif ($body and
	  ! $e->request->is_head and ! $res->no_content_length) {
		$header.= "Content-Length: ". length($$body). $CRLF;
	}
	my $cookie_ok;
	if (my $cookies= $res->{Cookies}) {
		while (my($name, $hash)= each %$cookies) {
			if (ref($hash) eq 'ARRAY') {
				for (@$hash) {
					my $obj= $_->{obj} || next;
					$header.= "Set-Cookie: ". $obj->as_string. $CRLF;
				}
			} else {
				my $cookie= $hash->{obj} || CGI::Cookie->new(
				  '-name'    => $name,
				  '-value'   => $hash->{value},
				  '-expires' => $hash->{expires},
				  '-domain'  => $hash->{domain},
				  '-path'    => $hash->{path},
				  '-secure'  => $hash->{secure},
				  '-max-age' => $hash->{max_age},
				  '-httponly'=> $hash->{httponly},
				  ) || next;
				$header.= "Set-Cookie: ". $cookie->as_string. $CRLF;
			}
			++$cookie_ok;
		}
		if ($cookie_ok and ! $headers->{P3P}
		    and my $p3p= $e->config->{p3p_policy}) {
			$res->p3p($p3p);
		}
	}
	$header.= 'Date: '. expires(0,'http'). $CRLF
	    if ($cookie_ok or $res->is_expires or $res->nph);
	$header.= 'Expires: '. expires($res->is_expires). $CRLF
	    if $res->is_expires;
	$header.= 'Last-Modified: '. expires($res->last_modified). $CRLF
	    if $res->last_modified;
	$header.= "Pragma: no-cache$CRLF"
	       .  "Cache-Control: no-cache, no-store, must-revalidate$CRLF"
	    if $res->no_cache;

	for my $h (values %$headers) {
		$header.= "$h->[0]\: $_$CRLF"
		  for (ref($h->[1]) eq 'ARRAY' ? @{$h->[1]}: $h->[1]);
	}
	$res->{header}= $header
	  . 'X-Egg-'. $e->namespace. ': '. $e->VERSION. $CRLF. $CRLF;
	\$res->{header};
}
sub _ctype_check {
	return $_[1] unless $_[1]=~m{^text/};
	return $_[1] if $_[1]=~m{\;\s+charset=}i;
	my $charset= $_[0]->charset || return $_[1];
	qq{$_[1]; charset="${charset}"};
}
sub charset {
	my $e= $_[0]->e;
	$e->stash->{charset_out} || $e->config->{charset_out} || (undef);
}
sub cookies {
	my($res)= @_;
	$res->{Cookies} ||= do {
##		$res->{cookies_ok}= 1;
		my $p3p;
		if (! $res->p3p and $p3p= $res->e->config->{p3p_policy}) {
			$res->p3p($p3p);
		}
		my %cookies;
		tie %cookies, 'Egg::Response::TieCookie', $res->e;
		\%cookies;
	  };
}
sub cookie {
	my $res= shift;
	return keys %{$res->cookies} if @_< 1;
	my $key= shift || return 0;
	if (@_) {
		if (scalar(@_)== 1) {
			$res->cookies->{$key}= shift;
		} else {
			my $hash= { $key, @_ };
			$key= $hash->{name} || croak q{I want param name.};
			$res->cookies->{$key}= $hash;
		}
	} else {
		$res->cookies->{$key};
	}
}
sub no_cache {
	my $res= shift;
	return $res->{no_cache} || 0 unless @_;
	if ($_[0]) {
		$_[1] ? $res->is_expires($_[1])
		      : ($res->is_expires || $res->is_expires('-1d'));
		$_[2] ? $res->last_modified($_[1])
		      : ($res->last_modified || $res->last_modified('-1d'));
		$res->{no_cache}= 1;
	} else {
		$res->is_expires(0);
		$res->last_modified(0);
		$res->{no_cache}= 0;
	}
}
sub status {
	my $res= shift;
	return $res->{status} unless @_;
	if (my $status= shift) {
		my($state, $string)=
		   $status=~/^(\d+)(?: +(.+))?/ ? ($1, ($2 || 0)): (200, 0);
		$res->{status_string}= $string || $Status{$state} || "";
		return $res->{status}= $state;
	} else {
		$res->{status}= $res->{status_string}= "";
		return 0;
	}
}
sub status_string {
	$_[0]->{status_string} ? " $_[0]->{status_string}": "";
}
sub redirect {
	my $res= shift;
	return ($res->location || undef) unless @_;
	return $_[0] ? do {
		$res->location( shift || '/' );
		my $status= shift || 302;
		my $o= $_[1] ? {@_}: $_[0];
		$res->window_target($o->{target}) if $o->{target};
		$res->e->finished($status);
	  }: do {
		$res->status(0);
		$res->window_target(0);
		$res->location("");
		$res->e->finished(0);
	  };
}
sub clear_body {
	my($res)= @_;
	$res->{body}= undef if $res->{body};
}
sub clear_cookies {
	return 0 unless $_[0]->{Cookies};
	my($res)= @_;
	tied(%{$res->{Cookies}})->_clear;
	delete($res->headers->{P3P}) if $res->headers->{P3P};
	1;
}
sub clear {
	my($res)= @_;
	$res->$_(0) for (qw/ redirect
	   no_cache no_content_length content_type content_language nph /);
	$res->headers->clear if $res->{__headers};
	undef($res->{header});
	$res->clear_cookies;
	1;
}
sub DESTROY {
	my($res)= @_;
	untie %{$res->{Cookies}} if $res->{Cookies};
}

1;

__END__

=head1 NAME

Egg::Response - WEB response processing for Egg.

=head1 SYNOPSIS

  # The object is acquired.
  my $res= $e->response;
  
  # The contents type is set.
  $res->content_type('text/plain');
   
  # The cache control is set.
  $res->no_cache(1);
    
  # The output contents are set.
  $res->body('Hell world !!');
  
  # The enhancing header is set.
  $res->headers->{'My-Header'}= 'OK';
  
  # Cookie is set.
  $res->cookie( hoge => 'boo' );
  
  # It redirects it.
  $res->redirect('http://ho.com/hellow.html', '302');
  
  # The response header is generated.
  my $scalar_ref= $res->header;

=head1 DESCRIPTION

The WEB response processing for the Egg framework is done. 

=head1 METHODS

The main body of this module is built into the component of the project.

=head2 response

The handler object of this module is returned.

=over 4

=item * res

=back

=head1 HANDLER METHODS

=head2 new

Constructor. It is not necessary to call from the application.

  my $res= $e->response;

=head2 body ([BODY_STRING])

Output contents are maintained.

The maintained data is always done by the SCALAR reference.

Undef is set when 0 is given to BODY_STRING and it initializes it.

  my $scalar_ref= $res->body(<<END_BODY);
  Hellow world !!
  END_BODY

=head2 headers

L<Egg::Response::Headers> object is returned.

The response header not supported by this module can be set by this.

  $res->headers->{'X-MyHader'}= 'hoge';

=head2 header ([BODY_SCALAR_REF])

It returns it making the response header.
Egg calls this by a series of processing. It is not necessary to call it from
the project.

To measure Content-Length, BODY_SCALAR_REF is passed.
$res-E<gt>body is used when omitted.

The returned value is SCALAR always reference.

=head2 content_type ([STRING])

To generate the Content-Type header by the header method, it sets it.

It can be overwrited that content_type is set to the configuration though default
is 'text/html'.

Moreover, when the contents type of default is output, it is not necessary to
call 'content_type'.

  $res->content_type('text/javascript');

=head2 content_language ([STRING])

To generate the Content-Language header by the header method, it sets it.

The Content-Language header is not usually output because there is no default.

  $res->content_language('ja');

=head2 no_cache ([BOOL])

It is a flag to generate the header for the cash control by the header method.

  $res->no_cache(1);

=head2 nph ([BOOL])

It is a flag to generate the header of NPH scripting by the header method.

  $res->nph(1);

* However, please note the thing not behaving like the NPH script in usual
 processing about Egg.

=head2 no_content_length ([BOOL])

It is a flag so as not to output the Content-Length header.

  $e->no_content_length(1);

The Content-Length header is not output at the following time.

=over 4

=item * It is possible to overwrite in 'no_content_length_regex' of the
 configuration though default is qr{(?:^text/|/(?:rss\+)?xml)} when matching
 it to the putter of $res-E<gt>{no_content_length_regex}.

=item * When $e-E<gt>request-E<gt>is_head returns ture. 

=item * When $res-E<gt>body returns undefined.

=back

=head2 is_expires ([ARGS])

To generate the Expires header by the header method, it sets it.

ARGS is a value passed to the expires function of L<CGI::Util>.

  $res->is_expires('+1D');

=head2 last_modified ([ARGS])

To generate the Last-Modified header by the header method, it sets it.

ARGS is a value passed to the expires function of L<CGI::Util>.

  $res->last_modified('+1D');

=head2 cookies

The HASH reference to set Cookie is returned.

Returned HASH is the one having made it by L<Egg::Response::TieCookie>.

  $res->cookies->{'Hoo'}= '123';

When 'p3p_policy' of the configuration is defined, the value is set if the p3p
method is still undefined.
Please set 'p3p_policy' to the configuration when you want to transmit the P3P
header when Cookie is output.

  package MyApp::config;
  sub out { {
    .............
    ........
    p3p_policy => 'UNI CUR OUR',
    ........
  } }

=head2 cookie ([KEY], [VALUE])

The list of the key to the data that has been set to omit the argument is 
returned.

The content of Cookie that corresponds more than the data set to give KEY is 
returned.

When VALUE is given, Cookie is set.

  my @key_list= $res->cookie;
  
  my $hoo= $res->cookie('Hoo');
  
  $res->cookie( Boo => '456' );

=head2 status ([STATUS])

The response status is set.

The following forms are accepted.

  $res->status(403);
  $res->status('403 Forbiden');
  $res->status(403, 'Forbiden');

When the text part is omitted, the value corresponding to status is set from
%Egg::Response::Status. The response code not supported by this module can be
customized by adding it to %Egg::Response::Status.

0 Is initialized when giving it. 

=head2 status_string

The text defined by the status method is returned. When the returned value exists,
half angle space is sure to be included in the head.

  my $status= 'Status: '. $res->status. $res->status_string;

=head2 redirect ([URI], [STATUS_CODE], [OPTION_HASH])

It is prepared to generate Ridairectoheddar.

URL is concretely set in the location method, and STATUS_CODE is set in the
status method.  And, the result of $e->finished is returned at the end.

There is no default of URL. Please specify it.

The default of STATUS_CODE is 302.

The window target can be specified with OPTION_HASH.

  $res->redirect('/hoge', 302, target=> '_top' );

0 Is canceled when giving it.

=head2 location ([URI])

To generate the Location header with the header, it sets it.

This is usually called in the redirect method and set.

Please note no desire as redirecting even if only this method is set.

The value that has already been set is returned at the URI unspecification.

=head2 window_target ([TARGET_STRING])

Window-Target is set.

  $res->window_target('foo');

* Because it is the one set in the response header, this is evaluated depending
on a browser of the client.  Especially, this header might been deleted as for
the client that is via the proxy. I do not think that it is in certain target
specification.

=head2 content_encoding ([ENCODING_STRING])

Content-Encoding is set.

  $res->content_encoding('identity');

=head2 content_disposition ([FILE_NAME])

Content-Disposition is set.

This is used to specify the file name when it is made to download.

  $res->content_disposition('myname.txt');
  
  # It is output to the header as follows. 
  Content-Disposition: attachment; filename=myname.txt

=over 4

=item * Alias = attachment

=back

=head2 p3p ([SIMPLE_POLICY])

P3P is set.

SIMPLE_POLICY gives the character string of the ARRAY reference or the half angle
space district switching off.

  $res->p3p('UNI CUR OUR');
  
  # It is output to the header as follows.
  P3P: policyref="/w3c/p3p.xml", CP="UNI CUR OUR"

=head2 clear_body

Undef is set in the value of body and it initializes it. 

=head2 clear_cookies

The set Cookie data is annulled. And, if the P3P header is set, it also initializes it.

=head2 clear

no_cache, no_content_length, content_type, content_language, nph, headers, and
clear_cookies are done in this method.

Please note that body is not cleared.

=head1 SEE ALSO

L<Egg::Release>
L<Egg::Response::Headers>,
L<Egg::Response::TieCookie>,
L<CGI::Cookie>,
L<CGI::Util>,
L<Egg::Base>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

