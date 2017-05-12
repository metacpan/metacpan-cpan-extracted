package LiBot::Provider::Lingr;
use strict;
use warnings;
use utf8;

use Mouse;

has host => (
    is => 'ro',
    required => 1,
);

has port => (
    is => 'ro',
    required => 1,
);

no Mouse;

use Plack::Request;
use JSON qw(decode_json);
use Encode qw(encode_utf8 decode_utf8);
use Twiggy::Server;
use Plack::Builder;
use Module::Runtime;

use LiBot::Message;

sub handle_request {
    my ($self, $bot, $json) = @_;

    return sub {
        my $respond = shift;
        my $callback = sub {
            my $ret = shift;
            $ret =~ s!\n+$!!;
            $respond->([200, ['Content-Type' => 'text/plain'], [encode_utf8($ret || '')]]);
        };
        if ( $json && $json->{events} ) {
            for my $event ( @{ $json->{events} } ) {
                my $msg = LiBot::Message->new(
                    text     => $event->{message}->{text},
                    nickname => $event->{message}->{nickname},
                );
                my $proceeded = eval {
                    $bot->handle_message($callback, $msg)
                };
                if ($@) {
                    print STDERR $@;
                    die $@;
                } else {
                    if ($proceeded) {
                        return;
                    }
                }
            }
        }

        # Not proceeeded.
        $respond->([200, ['Content-Type' => 'text/plain'], ['']]);
    };
}

sub to_app {
    my ($self, $bot) = @_;

    sub {
        my $req = Plack::Request->new(shift);

        if ($req->method eq 'POST') {
            my $json = decode_json($req->content);
            return $self->handle_request($bot, $json);
        } else {
            # lingr server always calls me by POST method.
            # This is human's health check page.
            return [200, ['Content-Type' => 'text/plain'], ["I'm lingr bot"]];
        }
    };
}

sub run {
    my ($self, $bot) = @_;

    my $server = Twiggy::Server->new(
        host => $self->host,
        port => $self->port,
    );
    $bot->log->info("Lingr bot server: http://%s:%s/\n", $self->host, $self->port);
    $server->register_service(builder {
        enable 'AccessLog';
        $self->to_app($bot);
    });
    return $server;
}

1;
__END__

=encoding utf-8

=head1 NAME

LiBot::Provider::Lingr - Lingr provider for LiBot

=head1 SYNOPSIS

    # Your config.pl
    +{
        providers => [
            'Lingr' => {
                host => '127.0.0.1',
                port => 1199,
            },
        ],
        'handlers' => [
            ...
        ],
    };

=head1 DESCRIPTION

You can connect LiBot with Lingr.

=head1 CONFIGURATION

=over 4

=item host

Bind host name in string. Required.

=item port

Listen port number in Int. Required.

=back
