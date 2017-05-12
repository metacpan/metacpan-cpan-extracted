package Hubot::Scripts::print;
$Hubot::Scripts::print::VERSION = '0.1.10';
use strict;
use warnings;
use JSON::XS;

sub load {
    my ( $class, $robot ) = @_;
    $robot->hear(
        qr/^(?:print|say):? (.+)/i,
        sub {
            my $msg  = shift;
            my $code = $msg->match->[0];
            $msg->http('http://api.dan.co.jp/lleval.cgi')
                ->query( { s => "#!/usr/bin/perl\nprint $code\n" } )->get(
                sub {
                    my ( $body, $hdr ) = @_;
                    return if ( !$body || $hdr->{Status} !~ m/^2/ );
                    my $data = decode_json($body);
                    $msg->send( split /\n/,
                        $data->{stdout} || $data->{stderr} );
                }
                );
        }
    );
}

1;

=head1 NAME

Hubot::Scripts::print

=head1 VERSION

version 0.1.10

=head1 SYNOPSIS

    print <code> - evaluate <code> and show the result
    say <code> - evaluate <code> and show the result

=head1 AUTHOR

Hyungsuk Hong <hshong@perl.kr>

=cut
