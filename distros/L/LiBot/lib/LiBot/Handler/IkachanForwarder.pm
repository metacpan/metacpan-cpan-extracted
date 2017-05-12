package LiBot::Handler::IkachanForwarder;
use strict;
use warnings;
use utf8;
use Furl;
use Text::Shorten qw(shorten_scalar);
use URI::Escape qw(uri_escape_utf8);

use Mouse;

has ua => (
    is => 'ro',
    lazy => 1,
    default => sub {
        Furl->new(agent => "LiBot/$LiBot::VERSION", timeout => 3);
    },
);

has url => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has channel => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

no Mouse;

sub init {
    my ($self, $bot) = @_;

    $bot->register(
        qr/@[a-zA-Z_-]+/ => sub {
            my ( $cb, $event, $arg ) = @_;

            print "Send mention\n";
            my $nickname = $event->nickname;
            substr($nickname, 1, 1) = '*'; # do not highlight me.
            my $msg = sprintf("(%s) %s", $nickname, $event->text);
            my $url = $self->url;
            $url =~ s!/$!!;
            $url .= sprintf("/privmsg?channel=%s&message=%s", uri_escape_utf8($self->channel), uri_escape_utf8($msg));
            my $res = $self->ua->post($url);
            print "IkachanForwarder: " . $res->status_line, "\n";
            $cb->('');
        }
    );
}

1;
