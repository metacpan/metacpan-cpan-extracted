package LibreCat::Auth::SSO;

use Catmandu::Sane;
use Catmandu::Util qw(check_string);
use Carp;
use Moo::Role;
use namespace::clean;

our $VERSION = "0.01";

with "Catmandu::Logger";

has session_key => (
    is       => "ro",
    isa      => sub { check_string($_[0]); },
    lazy     => 1,
    default  => sub { "auth_sso" },
    required => 1
);
has authorization_path => (
    is       => "ro",
    isa      => sub { check_string($_[0]); },
    lazy     => 1,
    default  => sub { "/"; },
    required => 1
);
has id => (
    is => "ro",
    lazy => 1,
    builder => "_build_id"
);
has uri_base => (
    is       => "ro",
    isa      => sub { check_string($_[0]); },
    required => 1,
    default  => sub { "http://localhost:5000"; }
);

requires "to_app";

sub uri_for {
    my ($self, $path) = @_;
    $self->uri_base() . $path;
}

sub _build_id {
    ref($_[0]);
}

#check if $env->{psgix.session} is stored Plack::Session->session
sub _check_plack_session {
    defined($_[0]->session) or die("LibreCat::Auth::SSO requires a Plack::Session");
}

sub get_auth_sso {
    my ($self, $session) = @_;
    _check_plack_session($session);
    $session->get($self->session_key);
}

sub set_auth_sso {
    my ($self, $session, $value) = @_;
    _check_plack_session($session);
    $session->set($self->session_key, $value);
}

1;

=pod

=head1 NAME

LibreCat::Auth::SSO - role for Single Sign On (SSO) authentication

=head1 IMPLEMENTATIONS

* SSO for Central Authentication System (CAS): L<LibreCat::Auth::SSO::CAS>

* SSO for ORCID: L<LibreCat::Auth::SSO::ORCID>

* SSO for Shibboleth: L<LibreCat::Auth::SSO::Shibboleth>

=head1 SYNOPSIS

    package MySSOAuth;

    use Moo;
    use Catmandu::Util qw(:is);

    with "LibreCat::Auth::SSO";

    sub to_app {

        my $self = shift;

        sub {

            my $env = shift;
            my $request = Plack::Request->new($env);
            my $session = Plack::Session->new($env);

            #did this app already authenticate you?
            #implementation of LibreCat::Auth::SSO should write hash to session key,
            #configured by "session_key"
            my $auth_sso = $self->get_auth_sso($session);

            #already authenticated: what are you doing here?
            if( is_hash_ref($auth_sso) ){

                return [ 302, [ Location => $self->uri_for($self->authorization_path) ], [] ];

            }

            #not authenticated: do your internal work
            #..

            #everything ok: set auth_sso
            $self->set_auth_sso(
                $session,
                {
                    package => __PACKAGE__,
                    package_id => $self->id,
                    response => {
                        content => "Long response from external SSO application",
                        content_type => "text/xml"
                    },
                    uid => "<uid>",
                    info => {
                        attr1 => "attr1",
                        attr2 => "attr2"
                    },
                    extra => {
                        field1 => "field1"
                    }
                }
            );

            #redirect to other application for authorization:
            return [ 302, [ Location => $self->uri_for($self->authorization_path) ], [] ];

        };
    }

    1;


    #in your app.psgi

    builder {

        mount "/auth/myssoauth" => MySSOAuth->new(

            session_key => "auth_sso",
            authorization_path => "/auth/myssoauth/callback",
            uri_base => "http://localhost:5001"

        )->to_app;

        mount "/auth/myssoauth/callback" => sub {

            my $env = shift;
            my $session = Plack::Session->new($env);
            my $auth_sso = $session->get("auth_sso");

            #not authenticated yet
            unless($auth_sso){

                return [ 403, ["Content-Type" => "text/html"], ["forbidden"] ];

            }

            #process auth_sso (white list, roles ..)

            [ 200, ["Content-Type" => "text/html"], ["logged in!"] ];

        };

    };

=head1 DESCRIPTION

This is a Moo::Role for all Single Sign On Authentication packages. It requires
C<to_app> method, that returns a valid Plack application

An implementation is expected is to do all communication with the external
SSO application (e.g. CAS). When it succeeds, it should save the response
from the external service in the session, and redirect to the authorization
url (see below).

The authorization route must pick up the response from the session,
and log the user in.

This package requires you to use Plack Sessions.

=head1 CONFIG

=over 4

=item session_key

When authentication succeeds, the implementation saves the response
from the SSO application in this session key, together with extra information.

The response should look like this:

    {
        package => "<package-name>",
        package_id => "<package-id>",
        response => {
            content => "Long response from external SSO application like CAS",
            content_type => "<mime-type>"
        },
        uid => "<uid-in-external-app>",
        info => {
            attr1 => "attr1",
            attr2 => "attr2"
        },
        extra => {
            field1 => "field1"
        }
    }

This is usefull for several reasons:

    * the authorization application can distinguish between authenticated and not authenticated users

    * it can pick up the saved response from the session

    * it can lookup a user in an internal database, matching on the provided "uid" from the external service.

    * the key "package" tells which package authenticated the user; so the application can do an appropriate lookup based on this information.

    * the key "package_id" defaults to the package name, but is configurable. This is usefull when you have several external services of the same type,
      and your application wants to distinguish between them.

    * the original response is stored as text, along with the content type.

    * other attributes stored in the hash reference "info". It is up to the implementing package whether it should only used attributes as pushed during
      the authentication step (like in CAS), or do an extra lookup.

    * "extra" should be used to store request information.
        e.g. "ORCID" gives a "token".
        e.g. "Shibboleth" supplies the "Shib-Identity-Provider".

=item authorization_path

(internal) path of the authorization route. This path will be prepended by "uri_base" to
create the full url.

When authentication succeeds, this application should redirect you here

=item uri_for( path )

method that prepends your path with "uri_base".

=item id

identifier of the authentication module. Defaults to the package name.
This is handy when using multiple SSO instances, and you need to known
exactly which package authenticated the user.

This is stored in "auth_sso" as "package_id".

=item uri_base

base url of the Plack application

=back

=head1 METHODS

=head2 to_app

returns a Plack application

This must be implemented by subclasses

=head2 get_auth_sso($plack_session)

get saved SSO response from your session

=head2 set_auth_sso($plack_session,$hash)

save SSO response to your session

$hash should be a hash ref, and look like this:

    {
        package => __PACKAGE__,
        package_id => __PACKAGE__ ,
        response => {
            content => "Long response from external SSO application like CAS",
            content_type => "<mime-type>",
        },
        uid => "<uid>",
        info => {},
        extra => {}
    }

=head1 EXAMPLES

See examples/app1:

    #copy example config to required location
    $ cp examples/catmandu.yml.example examples/catmandu.yml

    #edit config
    $ vim examples/catmandu.yml

    #start plack application
    plackup examples/app1.pl

=head1 QUESTIONS

* Is this part of LibreCat project (L<https://github.com/LibreCat/LibreCat>)? Do I need LibreCat too?

No. There is no requirement for LibreCat.

I just needed a namespace, and Plack::Auth::SSO seemed too greedy.

=head1 AUTHOR

Nicolas Franck, C<< <nicolas.franck at ugent.be> >>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=head1 SEE ALSO

L<LibreCat::Auth::SSO::CAS>,
L<LibreCat::Auth::SSO::ORCID>
L<LibreCat::Auth::SSO::Shibboleth>

=cut
