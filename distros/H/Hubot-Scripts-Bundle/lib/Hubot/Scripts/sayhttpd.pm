package Hubot::Scripts::sayhttpd;
$Hubot::Scripts::sayhttpd::VERSION = '0.1.10';
use strict;
use warnings;
use Encode qw/decode_utf8/;
use JSON;

sub load {
    my ( $class, $robot ) = @_;
    $robot->httpd->reg_cb(
        '/hubot/say' => sub {
            my ( $httpd, $req ) = @_;
            my $json = undef;

            eval { $json = decode_json( $req->{content} ); };
            if ($@) {
                $req->respond(
                    [
                        400,
                        'Bad Request',
                        { content => 'text/json' },
                        "{ 'status': 'error', 'error': 'could not parse json' }"
                    ]
                );
                return;
            }
            my $helper = Hubot::Scripts::sayhttpd::helper->new();

            if ( !$helper->checkRoom( $json->{'room'} ) ) {
                $req->respond(
                    [
                        400, 'Bad Request',
                        { content => 'text/json' },
                        "{ 'status': 'error', 'error': 'missing room' }"
                    ]
                );
                return;
            }
            if ( !$helper->checkSecret( $json->{'secret'} ) ) {
                $req->respond(
                    [
                        401,
                        'Unauthorized',
                        { content => 'text/json' },
                        "{ 'status': 'error', 'error': 'Secret missing/wrong/not set in ENV' }"
                    ]
                );
                return;
            }
            if ( !$helper->checkMessage( $json->{'message'} ) ) {
                $req->respond(
                    [
                        400, 'Bad Request',
                        { content => 'text/json' },
                        "{ 'status': 'error', 'error': 'missing message' }"
                    ]
                );
                return;
            }
            my $user = Hubot::User->new( { 'room' => $json->{'room'} } );
            $robot->adapter->send( $user, decode_utf8( $json->{'message'} ) );
            $req->respond(
                { content => ['text/json', "{ 'status': 'OK' }"] } );
        }
    );
}


package Hubot::Scripts::sayhttpd::helper;
$Hubot::Scripts::sayhttpd::helper::VERSION = '0.1.10';
use strict;
use warnings;

sub new {
    my $class = shift;
    my $self = { _secret => $ENV{HUBOT_SAY_HTTP_SECRET} };
    bless $self, $class;
    return $self;
}

sub checkSecret {
    my ( $class, $secret ) = @_;
    unless ($secret) {
        return undef;
    }
    unless ( $class->{_secret} ) {
        return undef;
    }
    if ( $secret eq $class->{_secret} ) {
        return 1;
    }
    return undef;
}

sub checkRoom {
    my ( $class, $room ) = @_;
    if ( $room && $room =~ m /../ ) {
        return 1;
    }
    return undef;
}

sub checkMessage {
    my ( $class, $message ) = @_;
    if ( $message && $message =~ m /../ ) {
        return 1;
    }
    return undef;
}

1;

=pod

=encoding utf-8

=head1 NAME

Hubot::Scripts::sayhttpd

=head1 VERSION

version 0.1.10

=head1 SYNOPSIS

=head1 CONFIGURATION

=over

=item HUBOT_SAY_HTTP_SECRET

=back

=head1 DESCRIPTION

HTTP Say Interface with SERECT file.

=head1 JSON API

  Please ensure that the http client sending Content-Type "application/json".

  curl -H 'Content-Type: application/json' -d '{"room": "#test-channel", "secret": "foobar", "message": "Hello from JSON" }' http://localhost:8080/hubot/say

=head1 AUTHOR

Jonas Genannt <jonas@capi2name.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jonas Genannt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
