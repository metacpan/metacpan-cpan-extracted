package Hubot::Scripts::eval;
$Hubot::Scripts::eval::VERSION = '0.1.10';
use strict;
use warnings;
use JSON::XS;

sub load {
    my ( $class, $robot ) = @_;
    $robot->hear(
        qr/^eval:? on *$/i,
        sub {
            my $msg = shift;
            $robot->brain->{data}{eval}{ $msg->message->user->{name} }
                {recording} = 1;
            $msg->send( 'OK, recording '
                    . $msg->message->user->{name}
                    . "'s codes for evaluate" );
        }
    );

    $robot->hear(
        qr/^eval:? (?:off|finish|done) *$/i,
        sub {
            my $msg  = shift;
            my $code = join "\n",
                @{ $robot->brain->{data}{eval}{ $msg->message->user->{name} }
                    {code} ||= [] };
            $msg->http('http://api.dan.co.jp/lleval.cgi')
                ->query( { s => "#!/usr/bin/perl\n$code" } )->get(
                sub {
                    my ( $body, $hdr ) = @_;
                    return if ( !$body || $hdr->{Status} !~ m/^2/ );
                    my $data = decode_json($body);
                    $msg->send( split /\n/,
                        $data->{stdout} || $data->{stderr} );
                }
                );
            delete $robot->brain->{data}{eval}{ $msg->message->user->{name} };
        }
    );

    $robot->hear(
        qr/^eval:? cancel *$/i,
        sub {
            my $msg = shift;
            delete $robot->brain->{data}{eval}{ $msg->message->user->{name} };
            $msg->send( 'canceled '
                    . $msg->message->user->{name}
                    . "'s evaluation recording" );
        }
    );

    $robot->hear(
        qr/^eval:? (.+)/i,
        sub {
            my $msg  = shift;
            my $code = $msg->match->[0];
            if ( $code !~ m/^(?:on|off|finish|done|cancel)$/ ) {
                $msg->http('http://api.dan.co.jp/lleval.cgi')
                    ->query( { s => "#!/usr/bin/perl\n$code" } )->get(
                    sub {
                        my ( $body, $hdr ) = @_;
                        return if ( !$body || $hdr->{Status} !~ m/^2/ );
                        my $data = decode_json($body);
                        $msg->send( split /\n/,
                            $data->{stdout} || $data->{stderr} );
                    }
                    );
            }
        }
    );

    $robot->catchAll(
        sub {
            my $msg = shift;
            if ( $robot->brain->{data}{eval}{ $msg->message->user->{name} }
                {recording} )
            {
                if ( ref $msg->message eq 'Hubot::TextMessage' ) {
                    push @{ $robot->brain->{data}{eval}
                            { $msg->message->user->{name} }{code} ||= [] },
                        $msg->message->text
                        if $msg->message->text !~ /^eval:? on *$/;
                }
            }
        }
    );
}

1;

=head1 NAME

Hubot::Scripts::eval

=head1 VERSION

version 0.1.10

=head1 SYNOPSIS

    eval <code> - evaluate <code> and show the result
    eval on - start recording
    eval off|finish|done - evaluate recorded <code> and show the result
    eval cancel - cancel recording

=head1 AUTHOR

Hyungsuk Hong <hshong@perl.kr>

=cut
