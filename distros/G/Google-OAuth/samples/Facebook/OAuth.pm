package Facebook::OAuth ;
use base qw( Google::OAuth ) ;

our %facebook ;
$facebook{oauth} = 'https://www.facebook.com/dialog/oauth' ;
$facebook{token} = 'https://graph.facebook.com/oauth/access_token' ;


my %client ;

sub setclient {
	my $package = shift ;
	%client = Google::OAuth::Config->facebookclient ;
	Google::OAuth::Client->setclient( %client ) ;
	return undef ;
	}

sub classID {
	return 1 ;
	}

sub grant_type {
	return 'fb_exchange_token' ;
	}

sub scope {
	shift @_ if $_[0] eq __PACKAGE__ ;
	my $self = ref $_[0] eq __PACKAGE__? shift @_: undef ;
	my %args = map { $_ => 1 } ( @_, 'email' ) ;

	my $scope = join ',', @_, keys %args ;
	return $scope unless $self ;

	$self->{scope} = $scope ;
	return $self ;
	}

sub token_request {
	setclient() unless %client ;
	my $arg = shift ;
	my ( $package, $self ) = ref $arg?
			( ref $arg, $arg ): ( $arg, undef ) ;
	$self ||= $package->new->scope ;
	$self->{args} ||= $package->queryargs( qw( client_id redirect_uri ) ) ;

	return Google::OAuth::Client::token_request( 
			$self, @_, $facebook{oauth} ) ;
	}

sub grant_code {
	my $package = shift @_ ;
	my $code = shift ;
	my $token = $package->get_token( 'redirect_uri', { code => $code } ) ;

	return $token unless $token->{access_token} ;

	## Can FB be queried to determine the email address?
	$token->{emailkey} = shift @_ if @_ ;
	$token->{emailkey} ||= $token->content( 
			GET => 'https://graph.facebook.com/me' 
			)->{email} ;

	## Otherwise, pass as an argument
	return $token_>{emailkey}? 
			$package->SQLObject( $token->{emailkey} => $token ):
			$token ;
	}

sub get_token {
	setclient() unless %client ;
	my $arg = shift ;
	my ( $package, $self ) = ref $arg?
			( ref $arg, $arg ): ( $arg, undef ) ;
	$self ||= $package->new( 'client_id', 'client_secret', @_ ) ;

	my $out = Google::OAuth::Request->content( 
			GET => join( '?', $facebook{token},
			Google::OAuth::CGI->new( $self->{args} )->query_string
			) ) ;

	## returns a string on success, JSON on failure - crazy huh?

	return $out if ref $out ;
	return { text => $out } unless $out =~ /access_token=/ ;

	my %token = split /[=\&]/, $out ;
	$token{fb_exchange_token} = $token{access_token} ;
	$token{requested} = time ;
	return bless \%token, $package ;
	}

## If token expires, it's too late.  Facebook expiration is unrecoverable.

sub expired {
	my $self = shift ;
	return $self->{requested} +$self->{expires} < time ;
	}

## Facebook has no header requirements

sub headers {
	return () ;
	}

sub request {
	my $self = shift ;
	my $method = @_ > 1? shift @_: 'GET' ;
	my $url = shift ;

	my @url = split /\?/, $url ;
	$url[1] ||= '' ;
	my $where = join '&', sprintf( '%s?access_token=%s', $url[0],
			  $self->{access_token} ), $url[1] ;

	return Google::OAuth::Request::request( $self, $method, $where ) ;
	}

1 ;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Facebook::OAuth - Extends Google::OAuth for Facebook

=head1 SYNOPSIS

  use Facebook::OAuth;
  use base qw( Google::OAuth ) ;

  ## Get Grant Code
  $link = Facebook::OAuth->new->scope( ... )->token_request ;
  $link = Facebook::OAuth->token_request ;		## use defaults

  ## Generate Token
  Facebook::OAuth->grant_code( $code ) ;

  ## Access Facebook
  $fbo = Facebook::OAuth->token( $email )->content( GET => $url ) ;
  $fbo = Facebook::OAuth->token( $email )->content( $url ) ;

=head1 DESCRIPTION

Facebooks's OAuth implementation is much simpler than Google's, so this
interface may be over-generalized.  The advantage lies in code reuse, and
a consistent interface that ultimately provides an effective general 
purpose OAuth client.

The Google::OAuth setup includes a Facebook configuration to establish 
Facebook credentials.  The configuration assumes a single data source
for all OAuth tokens that can support a variety of web services.

Additionally, the L<SYNOPSIS> demonstrates an API showing the 3 phases
of data access:

=head2 Acquire a Grant Code

In order to generate a I<Grant Code>, users log into Facebook and the grant 
code is transmitted to a I<redirect_uri> defined in the credentials.  All the
credentials are passed as query parameters in a single URI link.

Facebook uses quite a few permission settings, any number of which can be
passed as arguments to the C<scope()> method.  This interface always requests
the I<email> permisssion.

  ## Get Grant Code
  $link = Facebook::OAuth->token_request ;

=head2 Acquire a Token

Facebook returns a temporary I<grant code> that needs to be resubmitted to
obtain a token.  The grant code is transmitted to a webserver via the 
I<redirect_uri> so the token is usually acquired by a process owned by the 
webserver.

  ## Generate Token
  Facebook::OAuth->grant_code( $code ) ;

The C<grant_code> method saves the results in the data source.  Since it
normally returns a volatile object, the following invocation is recommended 
to examine the results:

  %status = %{ Facebook::OAuth->grant_code( $code, $email ) } ;

=head2 Refresh Token - Access Facebook

A Facebook token can be renewed indefinitely, but the expiration policy is
I<Use it or lose it>.  Google requires that a token be renewed before using.
Use the same approach to ensure that a Facebook token is continuously renewed
as follows:

  ## $fobj - Facebook data object 
  ## $url - Use Facebook API

  $fobj = Facebook::OAuth->token( $email )->content( GET => $url ) ;

  ## If necessary, select an email key from a list:

  @email = Facebook::OAuth->token_list ;

  ## If the token is to be reused:

  $token = Facebook::OAuth->token( $email ) ;
  $fobj = $token->content( GET => $url ) ;

  ## GET is the default method, so the following works:
  $fobj = $token->content( $url ) ;

=head1 METHODS

The following methods are overridden in the Facebook::OAuth subclass:

=over 8

=item setclient()

C<setclient()> replaces the Google configuration parameters with their 
Facebook equivalents.

=item classID()

C<classID()> returns constant integer 1.

=item grant_type()

C<grant_type()> returns constant string 'fb_exchange_token'.

=item scope()

Facebook permissions are defined as simple terms so these are not predefined 
in the package as Google's are.  Any permission value can be used.  See
Facebook's documentation L<https://developers.facebook.com/docs/reference/login/#permissions>.

Additionally, terms are represented differently in the URI.  And finally,
C<scope()> defines a default appropriate for Facebook.

=item token_request()

The overridden C<token_request()> method replaces the built in URI link and
requires few arguments than Google.  

=item grant_code()

C<grant_code()> is overloaded to define its own process for determining the
email key.   If necessary, one can be manually assigned as a method argument.

=item get_token()

C<get_token()> has a few differences with the superclass Google::OAuth method:

The target URL (Facebook versus Google) is built into the method definition.

Facebook uses an HTTP GET request instead of a POST.

Facebook does not return JSON when a token request succeeds.

The overridden method copies the token into an element named 
I<fb_exchange_token>.

=item expired()

C<expired()> uses the Facebook token element named I<expires>.

=item headers()

The overridden C<headers()> method has no body because Facebook has no 
special header requirements.

=item request()

The C<request()> method is overridden to append the token as a query parameter
to the URL argument.  In Google::OAuth, the token is passed as an HTTP
header.

=back 8

=head1 EXPORT

None by default.


=head1 SEE ALSO

=over 8

=item Google::OAuth

=back 8

=head1 AUTHOR

Jim Schueler, E<lt>jim@tqis.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Jim Schueler

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.


=cut
