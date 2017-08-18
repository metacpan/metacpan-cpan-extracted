package LWP::Authen::OAuth2;

use 5.006;
use strict;
use warnings;

use Carp qw(croak confess);
# LWP::UserAgent lazyloads these, but we always need it.
use HTTP::Request::Common;
use JSON qw(encode_json decode_json);
use LWP::UserAgent;
use Module::Load qw(load);

our @CARP_NOT = map "LWP::Authen::OAUth2::$_", qw(Args ServiceProvider);
use LWP::Authen::OAuth2::Args qw(
    extract_option copy_option assert_options_empty
);
use LWP::Authen::OAuth2::ServiceProvider;

sub new {
    my ($class, %opts) = @_;

    # Constructing the service provider can consume my options.
    my $service_provider = LWP::Authen::OAuth2::ServiceProvider->new(\%opts);
    my $self
        = bless {
              service_provider => $service_provider
          }, $service_provider->oauth2_class();
    $self->init(%opts, service_provider => $service_provider);
    return $self;
}

sub init {
    my ($self , %opts) = @_;

    # Collect arguments for the service providers.
    my $service_provider = $self->{service_provider};
    my $for_service_provider = LWP::Authen::OAuth2::Args->new();
    my %is_seen;
    for my $opt (@{ $service_provider->{required_init} }) {
        $is_seen{$opt}++;
        $for_service_provider->copy_option(\%opts, $opt);
    }
    for my $opt (@{ $service_provider->{optional_init} }) {
        if (not $is_seen{$opt}) {
            $is_seen{$opt}++;
            $for_service_provider->copy_option(\%opts, $opt, undef);
        }
    }
    $self->{for_service_provider} = $for_service_provider;

    $self->copy_option(\%opts, "early_refresh_time", 300);
    $self->copy_option(\%opts, "error_handler", undef);
    $self->copy_option(\%opts, "is_strict", 1);
    $self->copy_option(\%opts, "prerefresh", undef);
    $self->copy_option(\%opts, "save_tokens", undef);
    $self->copy_option(\%opts, "save_tokens_args", undef);
    $self->copy_option(\%opts, "token_string", undef);
    $self->copy_option(\%opts, "user_agent", undef);

    if ($self->{token_string}) {
        $self->load_token_string();
    }
}

# Standard shortcut request methods.
sub delete {
    my ($self, @parameters) = @_;
    my @rest = $self->user_agent->_process_colonic_headers(\@parameters,1);
    my $request = HTTP::Request::Common::DELETE(@parameters);
    return $self->request($request, @rest);
}

sub get {
    my ($self, @parameters) = @_;
    my @rest = $self->user_agent->_process_colonic_headers(\@parameters,1);
    my $request = HTTP::Request::Common::GET(@parameters);
    return $self->request($request, @rest);
}

sub head {
    my ($self, @parameters) = @_;
    my @rest = $self->user_agent->_process_colonic_headers(\@parameters,1);
    my $request = HTTP::Request::Common::HEAD(@parameters);
    return $self->request($request, @rest);
}

sub post {
    my ($self, @parameters) = @_;
    my @rest = $self->user_agent->_process_colonic_headers(\@parameters, (ref($parameters[1]) ? 2 : 1));
    my $request = HTTP::Request::Common::POST(@parameters);
    return $self->request($request, @rest);
}

sub put {
    my ($self, @parameters) = @_;
    my @rest = $self->user_agent->_process_colonic_headers(\@parameters, (ref($parameters[1]) ? 2 : 1));
    my $request = HTTP::Request::Common::PUT(@parameters);
    return $self->request($request, @rest);
}

sub request {
    my ($self, $request, @rest) = @_;
    return $self->access_token->request($self, $request, @rest);
}

# Now all of the methods that I need.
sub token_string {
    my $self = shift;
    if ($self->{access_token}) {
        my $ref = $self->{access_token}->to_ref;
        $ref->{_class} = ref($self->{access_token});
        return encode_json($ref);
    }
    else {
        return undef;
    }
}

# This does the actual saving.
sub _set_tokens {
    my ($self, %opts) = @_;

    my $tokens = $self->extract_option(\%opts, "tokens");
    my $skip_save = $self->extract_option(\%opts, "skip_save", 0);
    assert_options_empty(\%opts);

    if (ref($tokens)) {
        # Assume we have tokens.
        $self->{access_token} = $tokens;
        if ($self->{save_tokens} and not $skip_save) {
            my $as_string = $self->token_string;
            $self->{save_tokens}->($as_string, @{$self->{save_tokens_args}});
        }
        return;
    }
    else {
        # Assume we have an error message.
        return $self->error($tokens);
    }
}

sub authorization_url {
    my ($self, %opts) = @_;

    # If we get here, the service provider does it.
    my $url = $self->{service_provider}->authorization_url($self, %opts);
    if ($url =~ / /) {
        # Assume an error.
        return $self->error($url);
    }
    else {
        return $url;
    }
}

sub api_url_base {
    my $self = shift;
    return $self->{service_provider}->api_url_base || '';
}

sub make_api_call {
    my ($self, $uri, $params, $headers) = @_;
    my $url = $uri =~ m|^http| ? $uri : $self->api_url_base.$uri;
    if ($self->{service_provider}->can('default_api_headers')) {
        my $service_provider_headers = $self->{service_provider}->default_api_headers;
        $headers = ref $headers eq 'HASH' ? { %$headers, %$service_provider_headers } : $service_provider_headers || {};
    }

    my $response = $params ? $self->post($url, Content => encode_json($params), %$headers) : $self->get($url, %$headers);

    if (! $response->is_success()) {
        #$self->error('failed call to: '.$url.'; status_line='.$response->status_line.'; full error='.$response->error_as_HTML.'; content='.$response->content);
        $self->{'_api_call_error'} = $response->error_as_HTML || $response->status_line;
        return undef;
    }

    my $content = $response->content;
    return 1 if ! $content; # success
    return eval { decode_json($content) }; # return decoded JSON if response has a body
}

sub api_call_error { return shift->{'_api_call_error'}; }

sub request_tokens {
    my ($self, %opts) = @_;

    # If we get here, the service provider does it.
    my $tokens = $self->{service_provider}->request_tokens($self, %opts);
    # _set_tokens will set an error if needed.
    return $self->_set_tokens(tokens => $tokens);
}

sub can_refresh_tokens {
    my $self = shift;
    if (not $self->{access_token}) {
        return 0;
    }
    else {
        my %opts = ($self->{access_token}->for_refresh(), @_);
        return $self->{service_provider}->can_refresh_tokens($self, %opts);
    }
}

sub refresh_access_token {
    my $self = shift;
    if (not $self->{access_token}) {
        croak("Cannot try to refresh access token without tokens");
    }
    my %opts = ($self->{access_token}->for_refresh(), @_);

    # Give a chance for the hook to do it.
    if ($self->{prerefresh}) {
        my $tokens = $self->{prerefresh}->($self, %opts);
        if ($tokens) {
            if (not (ref($tokens))) {
                # Did I get JSON?
                my $data = eval {decode_json($tokens)};
                if ($data and not $@) {
                    # Assume I got it.
                    $tokens = $data;
                }
            }
            return $self->_set_tokens(tokens => $tokens, skip_save => 1);
        }
    }

    my $tokens = $self->{service_provider}->refreshed_tokens($self, %opts);
    # _set_tokens will set an error if needed.
    return $self->_set_tokens(tokens => $tokens);
}

sub access_token {
    my $self = shift;

    return $self->{access_token};
}

sub should_refresh {
    my $self = shift;

    return $self->access_token->should_refresh($self->{early_refresh_time});
}

sub expires_time {
    my $self = shift;
    return 0 if ! $self->{access_token};
    return $self->access_token->expires_time;
}

sub set_early_refresh_time {
    my ($self, $early_refresh_time) = @_;
    $self->{early_refresh_time} = $early_refresh_time;
}

sub set_is_strict {
    my ($self, $strict) = @_;
    $self->{is_strict} = $strict;
}

sub is_strict {
    my $self = shift;
    return $self->{is_strict};
}

sub set_error_handler {
    my ($self, $handler) = @_;
    $self->{error_handler} = @_;
}

sub error {
    my $self = shift;
    if ($self->{error_handler}) {
        return $self->{error_handler}->(@_);
    }
    else {
        croak(@_);
    }
}

sub for_service_provider {
    my $self = shift;
    return $self->{for_service_provider} ||= {};
}

sub set_prerefresh {
    my ($self, $prerefresh) = @_;
    $self->{prerefresh} = $prerefresh;
}

sub set_save_tokens {
    my ($self, $save_tokens) = @_;
    $self->{save_tokens} = $save_tokens;
}

sub set_user_agent {
    my ($self, $agent) = @_;
    $self->{user_agent} = $agent;
}

sub load_token_string {
    my ($self, $token_string) = @_;
    $token_string ||= $self->{token_string};

    # Probably not the object that I need in access_token.
    my $tokens = eval{ decode_json($token_string) };
    if ($@) {
        croak("While decoding token_string: $@");
    }

    my $class = $tokens->{_class}
        or croak("No _class in token_string '$token_string'");

    eval {load($class)};
    if ($@) {
        croak("Can't load access token class '$class': $@");
    }

    # I will assume this works.
    $self->{access_token} = $class->from_ref($tokens);
}

sub user_agent {
    my $self = shift;
    return $self->{user_agent} ||= LWP::UserAgent->new();
}

=head1 NAME

LWP::Authen::OAuth2 - Make requests to OAuth2 APIs.

=head1 VERSION

Version 0.13

=cut

our $VERSION = '0.14';


=head1 SYNOPSIS

OAuth 2 is a protocol that lets a I<user> tell a I<service provider> that a
I<consumer> has permission to use the I<service provider>'s APIs to do things
that require access to the I<user>'s account.  This module tries to make life
easier for someone who wants to write a I<consumer> in Perl.

Specifically it provides convenience methods for all of the requests that are
made to the I<service provider> as part of the permission handshake, and
after that will proxy off of L<LWP::UserAgent> to let you send properly
authenticated requests to the API that you are trying to use.  When possible,
this will include transparent refresh/retry logic for access tokens
expiration.

For a full explanation of OAuth 2, common terminology, the requests that get
made, and the necessary tasks that this module does not address, please see
L<LWP::Authen::OAuth2::Overview>

This module will not help with OAuth 1.  See the similarly named but
unrelated L<LWP::Authen::OAuth> for a module that can help with that.

Currently L<LWP::Authen::OAuth2> provides ready-to-use classes to use OAuth2 with

=over

=item * Dwolla

L<LWP::Authen::OAuth2::ServiceProvider::Dwolla>

implemented by L<Adi Fairbank|https://github.com/adifairbank>

=item * Google

L<LWP::Authen::OAuth2::ServiceProvider::Google>

=item * Line

L<LWP::Authen::OAuth2::ServiceProvider::Line>

implemented by L<Adam Millerchip|https://github.com/amillerchip>

=item * Strava

L<LWP::Authen::OAuth2::ServiceProvider::Strava>

implemented by L<Leon Wright|https://github.com/techman83>

=back

You can also access any other OAuth2 service by setting up a plain C<LWP::Authen::OAuth2> object. If you do, and the service provider might be of interest to other people, please submit a patch so we can include it in this distribution, or release it as a standalone package.

Here are examples of simple usage.

    use LWP::Authen::OAuth2;

    # Constructor
    my $oauth2 = LWP::Authen::OAuth2->new(
                     client_id => "Public from service provider",
                     client_secret => "s3cr3t fr0m svc prov",
                     service_provider => "Google",
                     redirect_uri => "https://your.url.com/",

                     # Optional hook, but recommended.
                     save_tokens => \&save_tokens,
                     save_tokens_args => [ $dbh ],

                     # This is for when you have tokens from last time.
                     token_string => $token_string.
                 );

    # URL for user to go to to start the process.
    my $url = $oauth2->authorization_url();

    # The authorization_url sends the user to the service provider to
    # say that you want to be authorized.  After the user confirms that
    # request, the service provider sends the user back to you with a
    # code.  This might be a CGI parameter, something that the user is
    # supposed to paste to you - that's between you and the service
    # provider.

    # Assuming that you have your code, get your tokens from the service
    # provider.
    $oauth2->request_tokens(code => $code);

    # Get your token as a string you can easily store, pass around, etc.
    # If you have a save_tokens callback, that gets passed this string
    # whenever the tokens change.
    #
    # This string bears a suspicious resemblance to serialized JSON.
    my $token_string = $oauth2->token_string,

    # Access the API.  Consult the service_provider's documentation for when
    # to use which type of request.  Note that argument processing is the
    # same as in LWP.  Thus the parameters array and headers hash are both
    # optional.
    $oauth2->get($url, %header);
    $oauth2->post($url, \@parameters, %header);
    $oauth2->put($url, %header);
    $oauth2->delete($url, %header);
    $oauth2->head($url, %header);

    # And if you need more flexibility, you can use LWP::UserAgent's request
    # method
    $oauth2->request($http_request, $content_file);

    # In some flows you can refresh tokens, in others you have to go through
    # the handshake yourself.  This method lets you know whether a refresh
    # looks possible.
    $oauth2->can_refresh_tokens();

    # This method lets you know when it is time to reauthorize so that you
    # can find out in a nicer way than failing an API call.
    $oauth2->should_refresh();

=head1 CONSTRUCTOR

When you call C<LWP::Authen::OAuth2-E<gt>new(...)>, arguments are passed as a
key/value list.  They are processed in the following phases:

=over 4

=item Construct service provider

=item Service provider collects arguments it wants

=item L<LWP::Authen::OAuth2> overrides defaults from arguments

=item Sanity check

=back

Here are those phases in more detail.

=over 4

=item Construct service provider

There are two ways to construct a service provider.

=over 4

=item Prebuilt class

To load a prebuilt class you just need one or two arguments.

=over 4

=item C<< service_provider => $Foo, >>

In the above construct, C<$Foo> identifies the base class for your service
provider.  The actual class will be the first of the following two classes
that can be loaded.  Failure to find either is an error.

    LWP::Authen::OAuth2::ServiceProvider $Foo
    $Foo

A list of prebuilt service provider classes is in
L<LWP::Authen::OAuth2::ServiceProvider> as well as instructions for making a
new one.

=item C<< client_type => $name_of_client_type >>

Some service providers will keep track of your client type ("webserver"
application, "installed" application, etc), and will treat them differently.
A base service provider class can choose to accept a C<client_type> parameter
to let it know what to expect.

Whether this is done, and the allowable values, are up to the service
provider class.

=back

=item Built on the fly

The behavior of simple service providers can be described on the fly without
needing a prebuilt class.  To do that, the following arguments can be filled
with arguments from your service provider:

=over 4

=item C<authorization_endpoint =E<gt> $auth_url,>

This is the URL which the user is directed to in the authorization request.

=item C<token_endpoint =E<gt> $token_url,>

This is the URL which the consumer goes to for tokens.

=item Various optional fields

L<LWP::Authen::OAuth2::ServiceProvider> documents many methods that are
available to customize the actual requests made, and defaults available.
Simple service providers can likely get by without this, but here is a list
of those methods that can be specified instead in the constructor:

    # Arrayrefs
    required_init
    optional_init
    authorization_required_params
    authorization_optional_params
    request_required_params
    request_optional_params
    refresh_required_params
    refresh_optional_params

    # Hashrefs
    authorization_default_params
    request_default_params
    refresh_default_params

=back

=item Service provider collects arguments it wants

In general, arguments passed into the constructor do not have to be passed
into individual method calls.  Furthermore in order to be able to do the
automatic token refresh for you, the constructor must include the arguments
that will be required.

By default you are required to pass your C<client_id> and C<client_secret>.
And optionally can pass a C<redirect_uri> and C<scope>.  (The omission of
C<state> is a deliberate hint that if you use that field, you should be
generating random values on the fly.  And not trying to go to some reasonable
default.)

However what is required is up to the service provider.

=item L<LWP::Authen::OAuth2> overrides defaults from arguments

The following defaults are available to be overridden in the constructor, or
can be overridden later.  In the unlikely event that there is a conflict with
the service provider's arguments, these will have to be overridden later.

=over 4

=item C<error_handler =E<gt> \&error_handler,>

Specifies the function that will be called when errors happen.  The default
is C<Carp::croak>.

=item C<is_strict =E<gt> $bool,>

Is strict mode on?  If it is, then excess parameters to requests that are
part of the authorization process will trigger errors.  If it is not, then
excess arguments are passed to the service provider as is, who
according to the specification is supposed to ignore them.

Strict mode is the default.

=item C<early_refresh_time =E<gt> $seconds,>

How many seconds before the end of estimated access token expiration you
will have C<should_refresh> start returning true.

=item C<prerefresh =E<gt> \&prerefresh,>

A handler to be called before attempting to refresh tokens.  It is passed the
C<$oauth2> object.  If it returns a token string, that will be used to
generate tokens instead of going to the service provider.

The purpose of this hook is so that, even if you have multiple processes
accessing an API simultaneously, only one of them will try to refresh tokens
with the service provider.  (Service providers may dislike having multiple
refresh requests arrive at once from the same consumer for the same user.)

By default this is not provided.

=item C<save_tokens =E<gt> \&save_tokens,>

Whenever tokens are returned from the service provider, this callback will
receive a token string that can be stored and then retrieved in another
process that needs to construct a C<$oauth2> object.

By default this is not provided.  However if you intend to access the
API multiple times from multiple processes, it is recommended.

=item C<save_tokens_args =E<gt> [ args ],>

Additional arguments passed to the save_tokens callback function after the
token string. This can be used to pass things like database handles or
other data to the callback along with the token string. Provide a reference
to an array of arguments in the constructure. When the callback is
called the arguments are passed to the callback as an array, so in the
example below $arg1 will be "foo" and $arg2 will be "bar"

    ...
    save_tokens => \&save_tokens,
    save_tokens_args => [ "foo", "bar" ],
    ...

    sub save_tokens {
        my ($token_string, $arg1, $arg2) = @_;

        ...
    }

=item C<token_string =E<gt> $token_string,>

Supply tokens generated in a previous request so that you don't have to ask
the service provider for new ones.  Some service providers refuse to hand out
tokens too quickly, so this can be important.

=item C<user_agent =E<gt> $ua,>

What user agent gets used under the hood?  Defaults to a new
L<lWP::UserAgent> created on the fly.

=back

=item Sanity check

Any arguments that are left over are assumed to be mistakes and a fatal
warning is generated.

=back

=over 4

=back

=back

=head1 METHODS

Once you have an object, the following methods may be useful for writing a
consumer.

=head2 C<$oauth2-E<gt>authorization_url(%opts)>

Generate a URL for the user to go to to request permissions.  By default the
C<response_type> and C<client_id> are defaulted, and all of C<redirect_uri>,
C<state> and C<scope> are optional but not required.  However in practice
this all varies by service provider and client type, so look for
documentation on that for the actual list that you need.

=head2 C<$oauth2-E<gt>request_tokens(%opts)>

Request tokens from the service provider (if possible).  By default the
C<grant_type>, C<client_id> and C<client_secret> are defaulted, and the
C<scope> is required.  However in practice this all varies by service
provider and client type, so look for documentation on that for the actual
list that you need.

=head2 C<$oauth2-E<gt>get(...)>

Issue a C<get> request to an OAuth 2 protected URL, just like you would
using L<LWP::UserAgent> to a normal URL.

=head2 C<$oauth2-E<gt>head(...)>

Issue a C<head> request to an OAuth 2 protected URL, just like you would
using L<LWP::UserAgent> to a normal URL.

=head2 C<$oauth2-E<gt>post(...)>

Issue a C<post> request to an OAuth 2 protected URL, just like you would
using L<LWP::UserAgent> to a normal URL.

=head2 C<$oauth2-E<gt>delete(...)>

Issue a C<delete> request to an OAuth 2 protected URL, similar to the
previous examples.  (This shortcut is not by default available with
L<LWP::UserAgent>.)

=head2 C<$oauth2-E<gt>put(...)>

Issue a C<put> request to an OAuth 2 protected URL, similar to the
previous examples.  (This shortcut is not by default available with
L<LWP::UserAgent>.)

=head2 C<$oauth2-E<gt>request(...)>

Issue any C<request> that you could issue with L<LWP::UserAgent>,
except that it will be properly signed to go to an OAuth 2 protected URL.

=head2 C<$oauth2-E<gt>make_api_call($uri, $params, $headers)>

This is a convenience method which makes a call to an OAuth2 API endpoint
given by $uri, and returns the JSON response decoded to a hash.  If the
$params hashref arg is set, its contents will be JSON encoded and sent as
POST request content; otherwise it will make a GET request.
Optional $headers may be sent which will be passed through to
C<$oauth-E<gt>get()> or C<$oauth-E<gt>post()>.

If the call succeeds, it will return the response's JSON content decoded
as hash, or if no response body was returned, a value of 1 to indicate success.
On failure returns undef, and error message is available from
C<$oauth2-E<gt>api_call_error()>.

=head2 C<$oauth2-E<gt>api_call_error()>

If an error occurred in C<$oauth2-E<gt>make_api_call()>, this method will
return it.  The error message comes from C<HTTP::Response-E<gt>error_as_HTML()>.

=head2 C<$oauth2-E<gt>api_url_base()>

Returns the base URL of the service provider, which is sometimes useful to be
used in the content of OAuth2 API calls.

=head2 C<$oauth2-E<gt>can_refresh_tokens>

Is sufficient information available to try to refresh tokens?

=head2 C<$oauth2-E<gt>should_refresh()>

Is it time to refresh tokens?

=head2 C<$oauth2-E<gt>set_early_refresh_time($seconds)>

Set how many seconds before the end of token expiration the method
C<should_refresh> will start turning true.  Values over half the initial
expiration time of access tokens will be ignored to avoid refreshing too
often.  This defaults to 300.

=head2 C<$oauth2-E<gt>expires_time()>

Returns the raw epoch expiration time of the current access token.
Typically this is 3600 seconds greater than the time of token creation.

=head2 C<$oauth2-E<gt>set_is_strict($mode)>

Set strict mode on/off.  See the discussion of C<is_strict> in the
constructor for an explanation of what it does.

=head2 C<$oauth2-E<gt>set_error_handler(\&error_handler)>

Set the error handler.  See the discussion of C<error_handler> in the
constructor for an explanation of what it does.

=head2 C<$oauth2-E<gt>set_prerefresh(\&prerefresh)>

Set the prerefresh handler.  See the discussion of C<prerefresh_handler> in
the constructor for an explanation of what it does.

=head2 C<$oauth2-E<gt>set_save_tokens($ua)>

Set the save tokens handler.  See the discussion of C<save_tokens> in the
constructor for an explanation of what it does.

=head2 C<$oauth2-E<gt>set_user_agent($ua)>

Set the user agent.  This should respond to the same methods that a
L<LWP::UserAgent> responds to.

=head2 C<$oauth2-E<gt>user_agent()>

Get the user agent.  The default if none was explicitly set is a new
L<LWP::UserAgent> object.

=head1 AUTHOR

Ben Tilly, C<< <btilly at gmail.com> >>

currently maintained by Thomas Klausner, C<< <domm@cpan.org> >>

=head2 Contributors

=over

=item * L<Leon Wright|https://github.com/techman83>

=item * L<Thomas Klausner|https://github.com/domm>

=item * L<Alexander Dutton|https://github.com/alexsdutton>

=item * L<Chris|https://github.com/TheWatcher>

=item * L<Adi Fairbank|https://github.com/adifairbank>

=item * L<Adam Millerchip|https://github.com/amillerchip>

=back

=head1 BUGS

Please report any bugs or feature requests to
C<bug-lwp-authen-oauth2 at rt.cpan.org>, or through
the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LWP-Authen-OAuth2>.  I will
be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LWP::Authen::OAuth2

You can also look for information at:

=over 4

=item Github (submit patches here)

L<https://github.com/btilly/perl-oauth2>

=item RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=LWP-Authen-OAuth2>

=item AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/LWP-Authen-OAuth2>

=item CPAN Ratings

L<http://cpanratings.perl.org/d/LWP-Authen-OAuth2>

=item Search CPAN

L<http://search.cpan.org/dist/LWP-Authen-OAuth2/>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to L<Rent.com|http://www.rent.com> for their generous support in
letting me develop and release this module.  My thanks also to Nick
Wellnhofer <wellnhofer@aevum.de> for Net::Google::Analytics::OAuth2 which
was very enlightening while I was trying to figure out the details of how to
connect to Google with OAuth2.

Thanks to

=over

=item * 

L<Thomas Klausner|https://github.com/domm> for reporting that client
type specific parameters were not available when the client type was properly
specified

=item * L<Alexander Dutton|https://github.com/alexsdutton> for making
C<ServiceProvider> work without requiring subclassing.

=item * L<Leon Wright|https://github.com/techman83> for adding a L<Strava | http://strava.com> Service Provider and various bug fixes

=item * L<Adi Fairbank|https://github.com/adifairbank> for adding a L<Dwolla | https://www.dwolla.com/> Service Provider and some other improvements

=item * L<Adam Millerchip|https://github.com/amillerchip> for adding a L<Line | https://line.me> Service Provider and some refactoring

=item * Nick Morrott for fixing some documentation typos

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Rent.com.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of LWP::Authen::OAuth2
