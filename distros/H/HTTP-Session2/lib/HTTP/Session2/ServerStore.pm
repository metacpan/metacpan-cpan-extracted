package HTTP::Session2::ServerStore;
use strict;
use warnings;
use utf8;
use 5.008_001;

our $VERSION = "1.10";

use Carp ();
use Digest::HMAC;
use Digest::SHA ();
use Cookie::Baker ();
use HTTP::Session2::Expired;
use HTTP::Session2::Random;

use Mouse;

extends 'HTTP::Session2::Base';

has store => (
    is => 'ro',
    required => 1,
    lazy => 1,
    default => sub {
        unless (defined $_[0]->get_store) {
            Carp::croak("store or get_store is required.");
        }
        $_[0]->get_store->()
    },
);

has get_store => (
    is => 'ro',
    isa => 'CodeRef',
    required => 0,
);

has xsrf_token => (
    is => 'ro',
    lazy => 1,
    builder => '_build_xsrf_token',
);

no Mouse;

sub load_session {
    my $self = shift;

    # Load from cookie.
    my $cookies = Cookie::Baker::crush_cookie($self->env->{HTTP_COOKIE});
    if (my $session_id = $cookies->{$self->session_cookie->{name}}) {
        # validate session_id
        return if $session_id =~/[\x00-\x20\x7f-\xff]/ || length($session_id) > 40;
        my $data = $self->store->get($session_id);
        if (defined $data) {
            $self->{id}   = $session_id;
            $self->{_data} = $data;
            return 1;
        }
    }
}

sub create_session {
    my $self = shift;

    $self->{id}   = HTTP::Session2::Random::generate_session_id();
    $self->{_data} = +{};
    $self->is_fresh(1);
}

sub regenerate_id {
    my ($self) = @_;

    # Load original session first.
    $self->load_session();

    # Remove original session from storage.
    my $cookies = Cookie::Baker::crush_cookie($self->env->{HTTP_COOKIE});
    if (my $session_id = $cookies->{$self->session_cookie->{name}}) {
        $self->store->remove($session_id);
    }

    # Clear XSRF token
    delete $self->{xsrf_token};

    # Create new session.
    $self->{id} = HTTP::Session2::Random::generate_session_id();
    $self->necessary_to_send(1);
    $self->is_dirty(1);
}

sub expire {
    my $self = shift;

    # Load original session first.
    # # Is this needed?
    $self->load_session();

    # Remove original session from storage.
    my $cookies = Cookie::Baker::crush_cookie($self->env->{HTTP_COOKIE});
    if (my $session_id = $cookies->{$self->session_cookie->{name}}) {
        $self->store->remove($session_id);
    }

    # Rebless to expired object.
    bless $self, 'HTTP::Session2::Expired';

    return;
}

sub _build_xsrf_token {
    my $self = shift;

    # @kazuho san recommend to change this code as `hmax(secret, id, hmac_function)`.
    # It makes secure. But we can't change this code for backward compatibility.
    # We should change this code at HTTP::Session3.
    Digest::HMAC::hmac_hex($self->id, $self->secret, $self->hmac_function);
}

sub save_data {
    my $self = shift;

    return unless $self->is_dirty;

    $self->store->set($self->id, $self->_data);
}

sub finalize {
    my $self = shift;
    $self->save_data();
    return $self->make_cookies();
}

sub make_cookies {
    my $self = shift;

    unless (
        ($self->is_dirty && $self->is_fresh)
        || $self->necessary_to_send
    ) {
        return ();
    }

    my @cookies;

    # Finalize session cookie
    {
        my %cookie = %{$self->session_cookie};
        my $name = delete $cookie{name};
        push @cookies, $name => +{
            %cookie,
            value => $self->id,
        };
    }

    # Finalize XSRF cookie
    {
        my %cookie = %{$self->xsrf_cookie};
        my $name = delete $cookie{name};
        push @cookies, $name => +{
            %cookie,
            value => $self->xsrf_token,
        };
    }

    return @cookies;
}

1;
__END__

=head1 NAME

HTTP::Session2::ServerStore - Session store

=head1 DESCRIPTION

This module is a part of HTTP::Session2 library.
This module saves the session data on server side storage.

=head1 CONSTRUCTOR PARAMETERS

=over 4

=item store: Object, optional

The storage object. You need to set 'store' or 'get_store'.

=item get_store : CodeRef,  optional

Callback function to get the storage object.

The storage object must have following 3 methods.

=over 4

=item $cache->get($key:Str)

=item $cache->set($key:Str, $value:Serializable)

=item $cache->remove($key:Str)

=back

And, cache object should be serialize/deserialize the data automatically.

L<CHI> supports all things. You can use any L<CHI> drivers.

But, I recommend to use C<Cache::Memcached::Fast>.

=back

=head1 METHODS

Methods are listed on L<HTTP::Session2::Base>.
