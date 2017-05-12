package Hubot::Scripts::bugzilla;
$Hubot::Scripts::bugzilla::VERSION = '0.1.10';
use utf8;
use strict;
use warnings;
use JSON;
use URI;

my %PRIORITY_MAP = (
    '---'   => '☆☆☆☆☆',
    Lowest  => '★☆☆☆☆',
    Low     => '★★☆☆☆',
    Normal  => '★★★☆☆',
    High    => '★★★★☆',
    Highest => '★★★★★',
);

sub load {
    my $client = JSONRPC->new( { url => $ENV{HUBOT_BZ_JSONPRC_URL} } );

    my ( $class, $robot ) = @_;
    $robot->hear(
        qr/b(?:ug|z) ([0-9a-z-A-Z ]+)/i,
        sub {
            my $msg = shift;
            for my $query ( split / /, $msg->match->[0] ) {
                $client->call(
                    'Bug.get',
                    { ids => [$query] },
                    sub {
                        my ( $body, $hdr ) = @_;
                        speak_bug( $msg, $body, $hdr, $client );
                    }
                );
            }
        }
    );

    $robot->hear(
        qr/^b(?:ug|z) search (.+)/,
        sub {
            my $msg = shift;
            $client->call(
                'Bug.search',
                { summary => $msg->match->[0] },
                sub {
                    my ( $body, $hdr ) = @_;
                    speak_bug( $msg, $body, $hdr, $client );
                }
            );
        }
    );

    $robot->hear(
        qr/show_bug\.cgi\?id=([0-9]+)/,
        sub {
            my $msg = shift;
            $msg->message->finish;
            $client->call(
                'Bug.get',
                { ids => [$msg->match->[0]] },
                sub {
                    my ( $body, $hdr ) = @_;
                    speak_bug( $msg, $body, $hdr, $client );
                }
            );
        }
    );
}

sub speak_bug {
    my ( $msg, $body, $hdr, $client ) = @_;
    my $data = decode_json($body);
    my $bug = @{ $data->{result}{bugs} ||= [] }[0];

    if ($bug) {
        $msg->send(
            sprintf "#%s [%s-%s] %s - [%s, %s, %s]",
            $bug->{id},
            $bug->{product},
            $bug->{component},
            $bug->{summary},
            $bug->{status},
            $bug->{assigned_to},
            $PRIORITY_MAP{ $bug->{priority} }
        );

        if ( $client->{quickserarch_url} ) {
            $msg->send( sprintf $client->{quickserarch_url}, $bug->{id} );
        }
    }
}

package JSONRPC;
$JSONRPC::VERSION = '0.1.10';
use strict;
use warnings;
use AnyEvent::HTTP::ScopedClient;
use JSON::XS;

sub new {
    my ( $class, $ref ) = @_;
    $ref->{http} = AnyEvent::HTTP::ScopedClient->new( $ref->{url} );
    $ref->{username} ||= $ENV{HUBOT_BZ_USERNAME};
    $ref->{password} ||= $ENV{HUBOT_BZ_PASSWORD};

    my $u = URI->new( $ref->{url} );
    if ( $u->path eq '/jsonrpc.cgi' ) {
        $u->path('/buglist.cgi');
        $u->query('quicksearch=%s');
        $ref->{quickserarch_url} = $u;
    }

    my $self = bless $ref, $class;
    $self->login if $ref->{username} && $ref->{password};
    return $self;
}

sub call {
    my ( $self, $method, $params, $cb ) = @_;
    $params->{Bugzilla_token} = $self->{token} if $self->{token};
    $params = encode_json(
        { method => $method, params => $params, version => '1.1' } );
    $self->{http}->header(
        {
            cookie => $self->{cookie} || '',
            Accept => 'application/json',
            'Content-Type' => 'application/json',
            'User-Agent'   => 'p5-hubot-bugzilla-script-jsonrpc-client',
        }
        )->post(
        $params,
        sub {
            my ( $body, $hdr ) = @_;
            $cb->( $body, $hdr ) if $hdr->{Status} =~ m/^2/;
        }
        );
}

sub set_cookies_or_token {
    my ( $self, $hdr, $body ) = @_;
    if ( $hdr->{'set-cookie'} ) {
        $self->set_cookies($hdr);
    }
    else {
        my $data = decode_json($body);
        $self->set_token( $data->{result}{token} );
    }
}

sub set_token {
    my ( $self, $token ) = @_;
    $self->{token} = $token;
}

sub set_cookies {
    my ( $self, $hdr ) = @_;
    $self->{cookie} = $hdr->{'set-cookie'};
}

sub login {
    my $self = shift;
    $self->call(
        'User.login',
        { login => $self->{username}, password => $self->{password} },
        sub {
            my ( $body, $hdr ) = @_;
            $self->set_cookies_or_token( $hdr, $body );
        }
    );
}

1;

=head1 NAME

Hubot::Scripts::bugzilla

=head1 VERSION

version 0.1.10

=head1 SYNOPSIS

    bug(or bz) (<bug id>|<keyword>) - retrun bug summary, status, assignee and priority if exist
    bug(or bz) search <keyword>     - retrun bug summary, status, assignee and priority if exist
    bug(or bz) <number> - show the bug title. (support multiple)

=head1 CONFIGURATION

=over

=item * HUBOT_BZ_JSONRPC_URL

=item * HUBOT_BZ_USERNAME

=item * HUBOT_BZ_PASSWORD

=back

=head1 AUTHOR

Hyungsuk Hong <hshong@perl.kr>

=cut
