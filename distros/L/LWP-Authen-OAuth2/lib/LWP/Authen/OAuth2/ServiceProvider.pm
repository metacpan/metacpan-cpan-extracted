package LWP::Authen::OAuth2::ServiceProvider;

use 5.006;
use strict;
use warnings;

use Carp qw(confess croak);
use JSON qw(decode_json);
use Memoize qw(memoize);
use Module::Load qw(load);
use URI;

our @CARP_NOT = qw(LWP::Authen::OAuth2 LWP::Authen::OAuth2::Args);

use LWP::Authen::OAuth2::Args qw(
    extract_option copy_option assert_options_empty
);

# Construct a new object.
sub new {
    my ($class, $opts) = @_;

    # I start as an empty hashref.
    my $self = {};

    # But what class am I supposed to actually be?
    if (not exists $opts->{service_provider}) {
        bless $self, $class;
    }
    else {
        # Convert "Google" to "LWP::Authen::OAuth2::ServiceProvider::Google"
        # Not a method because no object yet exists.
        $class = service_provider_class(delete $opts->{service_provider});
        my $client_type = delete $opts->{client_type};
        if (not defined($client_type)) {
            $client_type = "default";
        }
        bless $self, $class->client_type_class($client_type);
    }

    $self->init($opts);
}

sub init {
    my ($self, $opts) = @_;

    # Now let us consume options.  2 args = required, 3 = defaulted.
    # In general subclasses should Just Work.

    # need to read this first, since the later opts depend on it
    $self->copy_option($opts, 'use_test_urls') if defined $opts->{use_test_urls};

    # These are required, NOT provided by this class, but are by subclasses.
    for my $field (qw(token_endpoint authorization_endpoint)) {
        if ($self->can($field)) {
            $self->copy_option($opts, $field, $self->$field);
        }
        else {
            $self->copy_option($opts, $field);
        }
    }

    # These are defaulted by this class, maybe overridden by subclasses.
    for my $field (
        qw(required_init optional_init),
        map {
            ("$_\_required_params", "$_\_optional_params")
        } qw(authorization request refresh)
    ) {
        $self->copy_option($opts, $field, [$self->$field]);
    }

    # And hashrefs for default key/value pairs.
    for my $field (
        map "$_\_default_params", qw(authorization request refresh)
    ) {
        $self->copy_option($opts, $field, {$self->$field});
    }

    return $self;
}

sub authorization_url {
    my ($self, $oauth2, @rest) = @_;
    my $param
        = $self->collect_action_params("authorization", $oauth2, @rest);
    my $uri = URI->new($self->authorization_endpoint());
    $uri->query_form(%$param);
    return $uri->as_string;
}

sub request_tokens {
    my ($self, $oauth2, @rest) = @_;
    my $param = $self->collect_action_params("request", $oauth2, @rest);
    my $response = $self->post_to_token_endpoint($oauth2, $param);
    return $self->construct_tokens($oauth2, $response);
}

sub can_refresh_tokens {
    my ($self, $oauth2, %opt) = @_;
    my %default = $self->refresh_default_params;
    my $oauth2_args = $oauth2->for_service_provider;
    for my $param ($self->refresh_required_params) {
        if ( exists $default{$param}
          or exists $oauth2_args->{$param}
          or exists $opt{$param}
        ) {
            next;
        }
        else {
            return 0;
        }
    }
    return 1;
}

sub refreshed_tokens {
    my ($self, $oauth2, @rest) = @_;
    my $param = $self->collect_action_params("refresh", $oauth2, @rest);
    my $response = $self->post_to_token_endpoint($oauth2, $param);
    # Error message or object, this is what we return.
    return $self->construct_tokens($oauth2, $response);
}

sub collect_action_params {
    my $self = shift;
    my $action = shift;
    my $oauth2 = shift;
    my $oauth2_args = $oauth2->for_service_provider;
    my @rest = @_;
    my $opt = {@_};

    my $default = $self->{"$action\_default_params"};

    if ($oauth2->is_strict) {
        # We copy one by one with testing.
        my $result = {};
        for my $param (@{ $self->{"$action\_required_params"}}) {
             if (exists $opt->{$param}) {
                 if (defined $opt->{$param}) {
                     $result->{$param} = delete $opt->{$param};
                 }
                 else {
                     croak("Cannot pass undef for required param '$param'");
                 }
             }
             elsif (defined $oauth2_args->{$param}) {
                 $result->{$param} = $oauth2_args->{$param};
             }
             elsif (defined $default->{$param}) {
                 $result->{$param} = $default->{$param};
             }
             else {
                 croak("Missing required param '$param'");
             }
        }

        for my $param (@{ $self->{"$action\_optional_params"} }) {
            for my $source ($result, $opt, $oauth2_args, $default) {
                if (exists $source->{$param}) {
                    # Only add it if it is not undef.  Else hide.
                    if (defined $source->{$param}) {
                        $result->{$param} = $source->{$param};
                    }

                    # For opt only, delete if it was found.
                    if ($opt == $source) {
                        delete $opt->{$param};
                    }

                    last; # source
                    # (undef is deliberate override, which is OK)
                }
            }
        }

        $self->assert_options_empty($opt);

        # End of strict section.
        return $result;
    }
    else {
        # Not strict  just bulk copy.
        my $result = {
            %$default,
            (
                map {($_, $oauth2_args->{$_})}
                    @{ $self->{"$action\_required_params"} },
                    @{ $self->{"$action\_optional_params"} }
            ),
            %$opt
        };
        for my $key (keys %$result) {
            if (not defined($result->{$key})) {
                delete $result->{$key};
            }
        }
        return $result;
    }
}

sub post_to_token_endpoint {
    my ($self, $oauth2, $param) = @_;
    my $ua = $oauth2->user_agent();
    return $ua->post($self->token_endpoint(), [%$param]);
}

sub api_url_base { return '' } # override in subclass

sub access_token_class {
    my ($self, $type) = @_;

    if ("bearer" eq $type) {
        return "LWP::Authen::OAuth2::AccessToken::Bearer";
    }
    else {
        return "Token type '$type' not yet implemented";
    }
}

# Attempts to construct tokens, returns the access_token (which may have a
# request token embedded).
sub construct_tokens {
    my ($self, $oauth2, $response) = @_;

    # The information that I need.
    my $content = eval {$response->decoded_content};
    if (not defined($content)) {
        $content = '';
    }
    my $data = eval {decode_json($content)};
    my $parse_error = $@;
    my $token_endpoint = $self->token_endpoint();

    # Can this have done wrong?  Let me list the ways...
    if ($parse_error) {
        # "Should not happen", hopefully just network.
        # Tell the programmer everything.
        my $status = $response->status_line;
        return <<"EOT"
Token endpoint gave invalid JSON in response.

Endpoint: $token_endpoint
Status: $status
Parse error: $parse_error
JSON:
$content
EOT
    }
    elsif ($data->{error}) {
        # Assume a valid OAuth 2 error message.
        my $message = "OAuth2 error: $data->{error}";

        # Do we have a mythical service provider that gives us more?
        if ($data->{error_uri}) {
            # They seem to have a web page with detail.
            $message .= "\n$data->{error_uri} may say more.\n";
        }

        if ($data->{error_description}) {
            # Wow!  Thank you!
            $message .= "\n\nDescription: $data->{error_description}\n";
        }
        return $message;
    }
    elsif (not $data->{token_type}) {
        # Someone failed to follow the spec...
        return <<"EOT";
Token endpoint missing expected token_type in successful response.

Endpoint: $token_endpoint
JSON:
$content
EOT
    }

    my $type = $self->access_token_class(lc($data->{token_type}));
    if ($type !~ /^[\w\:]+\z/) {
        # We got an error. :-(
        return $type;
    }

    eval {load($type)};
    if ($@) {
        # MAKE THIS FATAL.  (Clearly Perl code is simply wrong.)
        confess("Loading $type for $data->{token_type} gave error: $@");
    }

    # Try to make an access token.
    my $access_token = $type->from_ref($data);

    if (not ref($access_token)) {
        # This should be an error message of some sort.
        return $access_token;
    }
    else {
        # WE SURVIVED!  EVERYTHING IS GOOD!
        if ($oauth2->access_token) {
            $access_token->copy_refresh_from($oauth2->access_token);
        }
        return $access_token;
    }
}

# Override for your client_types if you have multiple.
sub client_type_class {
    my ($class, $name) = @_;
    if ("default" eq $name) {
        return $class;
    }
    else {
        croak("Flow '$name' not defined for '$class'");
    }
}

# Override should you need the front-end LWP::Authen::OAuth object to have
# methods for service provider specific functionality.
#
# This is not expected to be a common need.
sub oauth2_class {
    return "LWP::Authen::OAuth2";
}

memoize("service_provider_class");
sub service_provider_class {
    my $short_name = shift;
    eval {
        load("LWP::Authen::OAuth2::ServiceProvider::$short_name");
    };
    if (not $@) {
        return "LWP::Authen::OAuth2::ServiceProvider::$short_name";
    }
    elsif ($@ =~ /Compilation failed/) {
        confess($@);
    }
    else {
        eval {
            load($short_name);
        };
        if (not $@) {
            return $short_name;
        }
        elsif ($@ =~ /Compilation failed/) {
            confess($@);
        }
        else {
            croak("Service provider '$short_name' not found");
        }
    }
}

# DEFAULTS (can be overridden)
sub authorization_endpoint {
    my $self = shift;
    return $self->{"authorization_endpoint"};
}

sub token_endpoint {
    my $self = shift;
    return $self->{"token_endpoint"};
}

# DEFAULTS (should be overridden)
sub required_init {
    return qw(client_id client_secret);
}

sub optional_init {
    return qw(redirect_uri scope);
}

sub authorization_required_params {
    return qw(response_type client_id);
}

sub authorization_optional_params {
    return qw(redirect_uri state scope);
}

sub authorization_default_params {
    return qw(response_type code);
}

sub request_required_params {
    return qw(grant_type client_id client_secret code);
}

sub request_optional_params {
    return qw(state);
}

sub request_default_params {
    return qw(grant_type authorization_code);
}

sub refresh_required_params {
        return qw(grant_type refresh_token client_id client_secret);
}

sub refresh_optional_params {
        return qw();
}

sub refresh_default_params {
    return qw(grant_type refresh_token);
}

=head1 NAME

LWP::Authen::OAuth2::ServiceProvider - Understand OAuth2 Service Providers

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

This is a base module for representing an OAuth 2 service provider.  It is
implicitly constructed from the parameters to C<LWP::Authen::OAuth2-E<gt>new>,
and is automatically delegated to when needed.

The first way to try to specify the service provider is with the parameters
C<service_provider> and possibly C<client_type>:

    LWP::Authen::OAuth2->new(
        ...
        service_provider => "Foo",
        client_type => "bar", # optional
        ...
    );

The first parameter will cause L<LWP::Authen::OAuth2::ServiceProvider> to
look for either C<LWP::Authen::OAuth2::ServiceProvider::Foo>, or if that is
not found, for C<Foo>.  (If neither is present, an exception will be thrown.)
The second parameter will be passed to that module which can choose to
customize the service provider behavior based on the client_type.

The other way to specify the service provider is by passing in sufficient
parameters to create a custom one on the fly:

    LWP::Authen::OAuth2->new(
        ...
        authorization_endpoint => $authorization_endpoint,
        token_endpoint => $token_endpoint,

        # These are optional but let you get the typo checks of strict mode
        authorization_required_params => [...],
        authorization_optional_params => [...],
        ...
    );

See L<LWP::Authen::OAuth2::Overview> if you are uncertain how to figure out
the I<Authorization Endpoint> and I<Token Endpoint> from the service
provider's documentation.

=head1 KNOWN SERVICE PROVIDERS

The following service providers are provided in this distribution, with
hopefully useful configuration and documentation:

=over 4

=item L<LWP::Authen::OAuth2::ServiceProvider::Dwolla|Dwolla>

=item L<LWP::Authen::OAuth2::ServiceProvider::Google|Google>

=item L<LWP::Authen::OAuth2::ServiceProvider::Line|Line>

=item L<LWP::Authen::OAuth2::ServiceProvider::Strava|Strava>

=item L<LWP::Authen::OAuth2::ServiceProvider::Yahoo|Yahoo>

=back

=head1 SUBCLASSING

Support for new service providers can be added with subclasses.  To do that
it is useful to understand how things get delegated under the hood.

First L<LWP::Authen::OAuth2> asks L<LWP::Authen::OAuth2::ServiceProvider> to
construct a service provider.  Based on the C<service_provider> argument, it
figures out that it needs to load and use your base class.  A service
provider might need different behaviors for different client types.  You
are free to take the client type and dynamically decide which subclass of
yours will be loaded instead to get the correct flow.  Should your subclass
need to, it can decide that that a subclass of L<LWP::Authen::OAuth2> should
be used that actually knows about request types that are specific to your
service provider.  Hopefully most service providers do not need this, but
some do.

For all of the potential complexity that is supported, B<most> service
provider subclasses should be simple.  Just state what fields differ from the
specification for specific requests and client types, then include
documentation.  However even crazy service providers should be supportable.

Here are the methods that were designed to be useful to override.  See the
source if you have a need that none of these address.  But if you can do what
you need to do through these, please do.

=over 4

=item C<authorization_endpoint>

Takes no arguments, returns the URL for the Authorization Endpoint for the
service provider.  Your subclass cannot function without this.

=item C<token_endpoint>

Takes no arguments, returns the URL for the Token Endpoint for the service
provider.  Your subclass cannot function without this.

=item C<client_type_class>

This method receives your class name and the passed in C<client_type>.
It is supposed to make sure that the class that handles that
C<client_type> is loaded, and then return it.  This lets you handle service
providers with different behavior for different types of clients.

The base implementation just returns your class name.

If the programmer does not pass an explicit C<client_type> the value that is
passed in is C<default>.  So that should be mapped to a reasonable client
type.  This likely is something along the line of "webserver".  That way
your module can be used without specifying a C<client_type>.

=item C<init>

After C<new> has figured out the right class to load, it immediately calls
C<$self-e<gt>init($opts)> with C<$opts> being a hashref of all options passed
to C<LWP::Authen::OAuth2-E<gt>new(...)> that were not consumed in figuring
out the service provider.  This method can then extract any parameters that
it wants to before anything else happens.

If you only want to require/allow a few parameters to be extracted into the
service provider object, then there is no need to write your own C<init>.
But if you want additional logic depending on passed in parameters, you can.

To consume options and copy them to C<$self> please use the following
methods:

    $self->copy_option($opts, $required_field);
    $self->copy_option($opts, $optional_field, $default);

If you want to consume options and return them as values instead:

    my $value1 = $self->extract_option($opts, $required_field);
    my $value2 = $self->extract_option($opts, $optional_field, $default);

These methods delete from the hash, so do not try to consume an option twice.

=item C<required_init>

The parameters that must be passed into C<LWP::Authen::OAuth2-E<gt>new(...)>
to initialize the service provider object.  The default required parameters
are C<client_id> and C<client_secret>, which in turn get used as default
arguments inside of methods that need them.  In general it is good to only
require arguments that are needed to generate refreshed tokens.  If you will
not get a C<refresh_token> in your flow, then you should require nothing.

=item C<optional_init>

The parameters that can be passed into C<LWP::Authen::OAuth2-E<gt>new(...)> to
initialize the service provider object.  The default optional parameters are
C<redirect_uri> and C<scope> which, if passed, do not have to be passed into
other method calls.

The C<state> is not included as an explicit hint that you should not simply
use a default value.

Note that these lists are deduped, so there is no harm in parameters being
both required and optional, or appearing multiple times.

=item C<{authorization,request,refresh}_required_params>

These three methods list parameters that B<must> be included in the
authorization url, the post to request tokens, and the post to refresh
tokens respectively.  Supplying these can give better error messages if
they are left out.

=item C<{authorization,request,refresh}_optional_params>

These three methods list parameters that B<can> be included in the
authorization url, the post to request tokens, and the post to refresh
tokens respectively.  In strict mode, supplying any parameters not
included in more or required params will be an error.  Otherwise this has
little effect.

=item C<{authorization,request,refresh}_default_params>

These three methods returns a list of key/value pairs mapping parameters to
B<default> values in the authorization url, the post to request tokens, and
the post to get refreshed tokens respectively.  Supplying these can stop
people from having to supply the parameters themselves.

An example where this could be useful is to support a flow that uses
different types of requests than normal.  For example with some client types
and service providers, you might use a type of request with a
C<grant_type> of C<password> or C<client_credentials>.

=item C<post_to_token_endpoint>

When a post to a token endpoint is constructed, this actually sends the
request.  The specification allows service providers to require
authentication beyond what the specification requires, which may require
cookies, specific headers, etc.  This method allows you to address that case.

=item C<access_token_class>

Given a C<token_type>, what class implements access tokens of that type?  If
your provider creates a new token type, or implements an existing token type
in a quirky way that requires a nonstandard model to handle, this method can
let you add support for that.

The specification says that all the C<token_type> must be case insensitive,
so all types are lower cased for you.

If the return value does not look like a package name, it is assumed to be
an error message.  As long as you have spaces in your error messages and
normal looking class names, this should DWIM.

See L<LWP::Authen::OAuth2::AccessToken> for a description of the interface
that your access token class needs to meet.  (You do not have to subclass
that - just duck typing here.)

=item C<oauth2_class>

Override this to cause C<LWP::Authen::OAuth2-E<gt>new(...)> to return an object
in a custom class.  This would be appropriate if people using your service
provider need methods exposed that are not in L<LWP::Authen::OAuth2>.

Few service provider classes should find a reason to do this, but it can be
done if you need.

=item C<collect_action_params>

This is the method that processes parameters for a given action.  Should
your service provider support a new kind of request, you can use this along
with the C<*_{required,more,default}_params> functions to support it.

The implementation of C<request_tokens> in this module give an example of
how to use it.

=back

=head1 CONTRIBUTING

Patches contributing new service provider subclasses to this distributions
are encouraged.  Should you wish to do so, please submit a git pull request
that does the following:

=over 4

=item Implement your provider

The more completely implemented, the better.

=item Name it properly

The name should be of the form:

    LWP::Authen::OAuth2::ServiceProvider::$ServiceProvider

=item List it

It needs to be listed as a known service provider in this module.

=item Test it

It is impossible to usefully test a service provider module without client
secrets.  However you can have public tests that it compiles, and private
tests that will, if someone supplies the necessary secrets, run fuller tests
that all works.  See the existing unit tests for examples.

=item Include it

Your files need to be included in the C<MANIFEST> in the root directory.

=item Document Client Registration

A developer should be able to read your module and know how to register
themselves as a client of the service provider.

=item List Client Types

Please list the client types that the service provider uses, with just
enough detail that a developer can figure out which one to use.  Listed
types should, of course, either be implemented or be documented as not
implemented.

=item Document important quirks

If the service provider requires or allows useful parameters, try to mention
them in your documentation.

=item Document limitations

If there are known limitations in your implementation, please state them.

=item Link to official documentation

If the service provider provides official OAuth 2 documentation, please link
to it.  Ideally a developer will not need to refer to it, but should know how
to find it.

=back

=head1 AUTHOR

Ben Tilly, C<< <btilly at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-lwp-authen-oauth2 at rt.cpan.org>, or through
the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LWP-Authen-OAuth2>.  I will
be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LWP::Authen::OAuth2::ServiceProvider

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

1
