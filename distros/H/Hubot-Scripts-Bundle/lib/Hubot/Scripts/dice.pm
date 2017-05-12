package Hubot::Scripts::dice;
$Hubot::Scripts::dice::VERSION = '0.1.10';
use strict;
use warnings;
use List::Util qw/shuffle/;

sub load {
    my ( $class, $robot ) = @_;

    my $default = 6;
    $robot->respond(
        qr/dice *(\d+)?/i,
        sub {
            my $msg = shift;
            my $max = $msg->match->[0] || $default;
            my $num = roll($max);
            $msg->send($num);
        }
    );
}

sub roll {
    my $max  = shift;
    my @pool = shuffle 1 .. $max;
    return pop @pool;
}

1;

=head1 NAME

Hubot::Scripts::dice

=head1 VERSION

version 0.1.10

=head1 SYNOPSIS

  hubot dice - roll a dice and print a number between 1 and 6
  hubot dice <number> - roll a dice and print a number between 1 and <number>

=head1 AUTHOR

Hyungsuk Hong <hshong@perl.kr>

=cut
