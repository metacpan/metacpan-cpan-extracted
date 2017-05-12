package Hubot::Scripts::tweet;
$Hubot::Scripts::tweet::VERSION = '0.2.8';
use strict;
use warnings;
use JSON::XS;
use AnyEvent::HTTP::ScopedClient;
use URI::Escape;

sub load {
    my ( $class, $robot ) = @_;

    my $authorization;
    $robot->hear(
        qr/https?:\/\/(mobile\.)?twitter\.com\/.*?\/status\/([0-9]+)/i,
        sub {
            my $msg = shift;

            return unless $authorization;

            $msg->http('https://api.twitter.com/1.1/statuses/show.json')
                ->header( { 'Authorization' => $authorization } )
                ->query( 'id' => $msg->match->[1] )->get(
                sub {
                    my ( $body, $hdr ) = @_;
                    return if ( !$body || !$hdr->{Status} =~ /^2/ );
                    my $tweet = decode_json($body);
                    my $text  = "$tweet->{user}{screen_name}: $tweet->{text}";
                    $msg->send( split /\n/, $text );
                }
                );
            $msg->message->finish;
        }
    );

    return
        unless $ENV{HUBOT_TWITTER_CONSUMER_KEY}
        && $ENV{HUBOT_TWITTER_CONSUMER_SECRET};

    my $client = AnyEvent::HTTP::ScopedClient->new(
        'https://api.twitter.com/oauth2/token',
        options => {
            auth => uri_escape( $ENV{HUBOT_TWITTER_CONSUMER_KEY} ) . ':'
                . uri_escape( $ENV{HUBOT_TWITTER_CONSUMER_SECRET} )
        }
    );

    $client->post(
        { grant_type => 'client_credentials' },
        sub {
            my ( $body, $hdr ) = @_;

            return if !$body;

            my $data = decode_json($body);
            if ( $hdr->{Status} =~ /^2/ ) {
                my ( $token_type, $access_token )
                    = ( $data->{token_type}, $data->{access_token} );
                $authorization = ucfirst $token_type . " $access_token";
            }
            else {
                print STDERR __PACKAGE__ . " - $data->{errors}[0]{message}\n";
            }
        }
    );
}

1;

=pod

=encoding utf-8

=head1 NAME

Hubot::Scripts::tweet

=head1 VERSION

version 0.2.8

=head1 SYNOPSIS

    <tweeturl> - Display tweet content

=head1 CONFIGURATION

=over

=item HUBOT_TWITTER_CONSUMER_KEY

=item HUBOT_TWITTER_CONSUMER_SECRET

=back

=head1 DESCRIPTION

Detect tweet URL and send tweet content

=head1 AUTHOR

Hyungsuk Hong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Hyungsuk Hong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
