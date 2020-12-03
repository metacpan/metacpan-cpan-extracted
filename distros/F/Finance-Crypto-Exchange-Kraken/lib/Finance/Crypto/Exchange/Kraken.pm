use utf8;

package Finance::Crypto::Exchange::Kraken;
our $VERSION = '0.002';
use Moose;
use namespace::autoclean;
use LWP::UserAgent;
use MooseX::Types::URI qw(Uri);
use JSON qw(decode_json);
use Try::Tiny;
use MIME::Base64 qw(decode_base64url);
use Time::HiRes qw(gettimeofday);

# ABSTRACT: A Perl implementation of the Kraken REST API

has ua => (
    is      => 'ro',
    isa     => 'LWP::UserAgent',
    lazy    => 1,
    builder => '_build_ua',
);

sub _build_ua {
    my $self = shift;
    my $ua   = LWP::UserAgent->new(
        agent             => sprintf("%s/%s", __PACKAGE__, $VERSION),
        timeout           => 10,
        protocols_allowed => ['https'],
        max_redirect      => 0,
        ssl_opts          => { verify_hostname => 1 },
    );
    return $ua;
}

has _uri => (
    is       => 'ro',
    isa      => Uri,
    coerce   => 1,
    default  => 'https://api.kraken.com',
    init_arg => 'base_uri',
);

has key => (
    is       => 'ro',
    isa      => 'Str',
    predicate => 'has_key',
);

has secret => (
    is       => 'ro',
    isa      => 'Str',
    predicate => 'has_secret',
);

sub nonce {
    my $self = shift;
    return gettimeofday() * 100000;
}

sub call {
    my ($self, $req) = @_;

    foreach (qw(Content-Type Content-Length)) {
        $req->headers->remove_header($_);
    }

    $req->headers->header(Accept => 'application/json');

    my $response = $self->ua->request($req);

    if ($response->is_success) {
        my $data;
        try {
            $data = decode_json($response->decoded_content);
        }
        catch {
            die "Unable to decode JSON from Kraken!", $/;
        };

        if (@{$data->{error}}) {
            if (@{$data->{error}} > 1) {
                die "Multiple errors occurred: " .
                join($/, @{$data->{error}})
                , $/;
            }
            else {
                die $data->{error}[0], $/;
            }
        }
        return $data->{result};
    }
    die "Error calling Kraken: " . $response->status_line, $/;

}

around 'BUILDARGS' => sub {
    my ($orig, $class, %args) = @_;
    if (my $secret = delete $args{secret}) {
        $args{secret} = decode_base64url($secret);
    }
    return $class->$orig(%args);
};


with qw(
    Finance::Crypto::Exchange::Kraken::REST::Public
    Finance::Crypto::Exchange::Kraken::REST::Private
);

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::Crypto::Exchange::Kraken - A Perl implementation of the Kraken REST API

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    package Foo;
    use Finance::Crypto::Exchange::Kraken;

    my $kraken = Finance::Crypto::Exchange::Kraken->new(
        key    => 'your very secret key',
        secret => 'your very secret secret',
    );

    # For all methods, please visit the documentation
    $kraken->get_server_time;

=head1 DESCRIPTION

Talk to the Kraken REST API within Perl

=head1 METHODS

=head2 call

    my $req = HTTP::Request->new(GET, ...);
    $self->call($req);

A very simple API call function.
Decodes the JSON for you on success, otherwise dies a horrible death with the
error Kraken gives back to you.

You should not be needing this method, this function is public because all the
roles use it.

=head2 nonce

Create a nonce

=head1 SEE ALSO

=over

=item L<Finance::Crypto::Exchange::Kraken::REST::Public>

=item L<Finance::Crypto::Exchange::Kraken::REST::Private>

=item L<Finance::Crypto::Exchange::Kraken::REST::Private::User::Data>

=item L<Finance::Crypto::Exchange::Kraken::REST::Private::User::Trading>

=item L<Finance::Crypto::Exchange::Kraken::REST::Private::User::Funding>

=item L<Finance::Crypto::Exchange::Kraken::REST::Private::Websockets>

=back

There is another module that does more or less the same:
L<Finance::Bank::Kraken> but it requires a more hands on approach.

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
