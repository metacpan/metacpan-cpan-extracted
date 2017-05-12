package LiBot::Handler::URLFetcher;
use strict;
use warnings;
use utf8;

use LWP::UserAgent;
use HTTP::Response::Encoding;
use HTML::Entities;
use Encode;
use Furl;
use Text::Shorten qw(shorten_scalar);

use Mouse;

# TODO: max_size?

has prefix => (
    is => 'ro',
    default => sub { 'Title: ' },
);

has ua => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;

        Furl->new(
            agent => "LiBot/$LiBot::VERSION",
            timeout => 3,
        );
    },
);

no Mouse;

sub init {
    my ($self, $bot) = @_;

    $bot->register(
        qr/(s?https?:\/\/[-_.!~*'()a-zA-Z0-9;\/?:\@&=+\$,%#]+)/ => sub {
            my ( $cb, $event, $url ) = @_;
            my $res = $self->ua->get($url);
               $res = $res->as_http_response;
            if ($res->content =~ m{<title>\s*(.*?)\s*</title>}smi) {
                my $title = decode_entities($res->encoder->decode($1));
                $cb->($self->prefix() . shorten_scalar($title, 120));
            } else {
                $cb->('');
            }
        }
    );
}

1;
__END__

=head1 NAME

LiBot::Handler::URLFetcher - URL title fetcher

=head1 SYNOPSIS

    # config.pl
    +{
        'handlers' => [
            'URLFetcher'
        ]
    }

    # script
    <tokuhirom> http://www.quora.com/
    >bot< Title: Quora

=head1 DESCRIPTION

This bot tell me a C<< <title> >> from the URL.

=head1 CONFIGURATION

There is no configuration parameters.

