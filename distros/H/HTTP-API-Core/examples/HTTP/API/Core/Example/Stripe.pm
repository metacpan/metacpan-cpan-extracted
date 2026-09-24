package HTTP::API::Core::Example::Stripe;

use strict;
use warnings;

use HTTP::API::Core;
use HTTP::API::Core::Auth qw(bearer_auth);
use HTTP::API::Core::Form qw(form_urlencode);

sub new {
    my ($class, %args) = @_;
    my $token = delete $args{token};
    die "token is required\n" if !defined($token) || $token eq '';

    my $api = HTTP::API::Core->new(
        base_url => delete($args{base_url}) || 'https://api.stripe.com/v1',
        hooks => { before_request => bearer_auth($token) },
        %args,
    );
    return bless { api => $api }, $class;
}

sub customers_pager {
    my ($self, %query) = @_;
    return $self->{api}->paginate(
        '/customers',
        mode => 'cursor',
        items => 'data',
        next => sub {
            my ($json) = @_;
            return undef if !$json->{has_more};
            return undef if ref($json->{data}) ne 'ARRAY' || !@{ $json->{data} };
            return $json->{data}[-1]{id};
        },
        cursor_param => 'starting_after',
        query => \%query,
    );
}

sub create_customer {
    my ($self, %args) = @_;
    my $idempotency_key = delete $args{idempotency_key};
    my $content = form_urlencode(\%args);

    return $self->{api}->post(
        '/customers',
        headers => { 'content-type' => 'application/x-www-form-urlencoded' },
        content => $content,
        (defined($idempotency_key) ? (
            idempotency => {
                key => $idempotency_key,
                header => 'Idempotency-Key',
            },
        ) : ()),
    );
}

1;
