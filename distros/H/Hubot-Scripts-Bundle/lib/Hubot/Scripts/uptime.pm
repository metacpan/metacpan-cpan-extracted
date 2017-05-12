package Hubot::Scripts::uptime;
$Hubot::Scripts::uptime::VERSION = '0.1.10';
use strict;
use warnings;
use DateTime;
use DateTime::Format::Duration;

sub load {
    my ( $class, $robot ) = @_;
    my $start = DateTime->now;
    $robot->respond(
        qr/uptime/i,
        sub {
            my $msg = shift;
            uptimeMe( $msg, $start, sub { $msg->send(shift) } );
        }
    );
}

sub uptimeMe {
    my ( $msg, $start, $cb ) = @_;
    my $now      = DateTime->now;
    my $duration = $now - $start;
    my $d
        = DateTime::Format::Duration->new(
        pattern => '%Y years, %m months, %e days, '
            . '%H hours, %M minutes, %S seconds' );
    $d->set_normalizing(1);
    $cb->( "I've been sentient for " . $d->format_duration($duration) );
}

1;

=head1 NAME

Hubot::Scripts::uptime

=head1 VERSION

version 0.1.10

=head1 SYNOPSIS

  hubot uptime - display robot's uptime

=head1 AUTHOR

Hyungsuk Hong <hshong@perl.kr>

=cut
