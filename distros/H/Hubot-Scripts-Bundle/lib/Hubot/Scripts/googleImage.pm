package Hubot::Scripts::googleImage;
$Hubot::Scripts::googleImage::VERSION = '0.1.10';
use strict;
use warnings;
use JSON::XS;

sub load {
    my ( $class, $robot ) = @_;
    $robot->respond(
        qr/(image|img)( me)? (.*)/i,
        sub {
            my $msg = shift;
            imageMe( $msg, $msg->match->[2], sub { $msg->send(shift) } );
            $msg->message->finish;
        }
    );

    $robot->respond(
        qr/animate(?: me)? (.*)/i,
        sub {
            my $msg = shift;
            imageMe( $msg, $msg->match->[0], 1, sub { $msg->send(shift) } );
            $msg->message->finish;
        }
    );

    $robot->respond(
        qr/(?:mo?u)?sta(?:s|c)he?(?: me)? (.*)/i,
        sub {
            my $msg        = shift;
            my $type       = int( rand(3) );
            my $mustachify = "http://mustachify.me/$type?src=";
            my $imagery    = $msg->match->[0];

            if ( $imagery =~ /https?:\/\//i ) {
                $msg->send("$mustachify$imagery");
            }
            else {
                imageMe( $msg, $imagery, 0, 1,
                    sub { $msg->send("$mustachify$imagery") } );
            }

            $msg->message->finish;
        }
    );
}

sub imageMe {
    my ( $msg, $query, $animated, $faces, $cb ) = @_;
    $cb = $animated if ref $animated eq 'CODE';
    $cb = $faces if defined $faces && ref $faces eq 'CODE';
    my $q = { v => '1.0', rsz => '8', q => $query, safe => 'active' };
    $q->{as_filetype} = 'gif'
        if defined $animated && ref $animated ne 'CODE' && $animated == 1;
    $q->{imgtype} = 'face'
        if defined $faces && ref $faces ne 'CODE' && $faces == 1;
    $msg->http('http://ajax.googleapis.com/ajax/services/search/images')
        ->query($q)->get(
        sub {
            my ( $body, $hdr ) = @_;
            my $images = decode_json($body);
            $images = $images->{responseData}{results};
            if (@$images) {
                my $image = $msg->random(@$images);
                $cb->( $image->{unescapedUrl} );
            }
        }
        );
}

1;

=head1 NAME

Hubot::Scripts::googleImage - A way to interact with the Google Images API.

=head1 VERSION

version 0.1.10

=head1 SYNOPSIS

    # required Hubot v0.0.9 or higher
    hubot image me <query> - The Original. Queries Google Images for <query> and returns a random top result.
    hubot animate me <query> - The same thing as `image me`, except adds a few parameters to try to return an animated GIF instead.
    hubot mustache me <url> - Adds a mustache to the specified URL.
    hubot mustache me <query> - Searches Google Images for the specified query and mustaches it.

=head1 AUTHOR

Hyungsuk Hong <hshong@perl.kr>

=cut
