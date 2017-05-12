package Hubot::Scripts::macboogi;
$Hubot::Scripts::macboogi::VERSION = '0.1.10';
use utf8;
use strict;
use warnings;
use Encode qw/decode_utf8 encode_utf8/;
use Lingua::KO::Hangul::Util qw(:all);

my $JONGSUNG_BEGIN  = 0x11A8;
my $JONGSUNG_END    = 0x11FF;
my $JONGSUNG_DIGEUG = 0x11AE;                              # ㄷ
my $JONGSUNG_BIEUP  = 0x11B8;                              # ㅂ
my $JONGSUNG_JIEUT  = 0x11BD;                              # ㅈ
my $SELLABLE_BEGIN  = 0x3131;
my $INTERVAL        = $SELLABLE_BEGIN - $JONGSUNG_BEGIN;

sub load {
    my ( $class, $robot ) = @_;
    $robot->hear(
        qr/^(.*)\.mac$/i,
        sub {
            my $msg = shift;
            macboogify( $msg, $msg->match->[0] );
        }
    );
}

sub macboogify {
    my ( $res, $msg ) = @_;
    my @chars = split //, $msg;
    my @mac_chars;
    for my $char (@chars) {
        my $ord = ord $char;
        if ( $ord >= 97 && $ord <= 122 ) {    # a..z
            push @mac_chars, uc $char;
            next;
        }
        elsif ( $ord >= 65 && $ord <= 90 ) {    # A..Z
            push @mac_chars, $char;
            next;
        }

        my @jamo = split //, decomposeSyllable($char);
        for (@jamo) {
            my $code = unpack 'U*', $_;
            if ( $code >= $JONGSUNG_BEGIN && $code <= $JONGSUNG_DIGEUG ) {
                $code += $INTERVAL;
            }
            elsif ( $code > $JONGSUNG_DIGEUG && $code <= $JONGSUNG_BIEUP ) {
                $code += $INTERVAL + 1;
            }
            elsif ( $code > $JONGSUNG_BIEUP && $code <= $JONGSUNG_JIEUT ) {
                $code += $INTERVAL + 2;
            }
            elsif ( $code > $JONGSUNG_JIEUT && $code <= $JONGSUNG_END ) {
                $code += $INTERVAL + 3;
            }

            $_ = pack 'U*', $code;
        }

        push @mac_chars, composeSyllable( join '', @jamo );
    }

    my $macboogify = join '', @mac_chars;
    $res->send($macboogify);
}

1;

=head1 NAME

Hubot::Scripts::macboogi

=head1 VERSION

version 0.1.10

=head1 SYNOPSIS

    <text>.mac - print macboogified <text>

=head1 AUTHOR

Hyungsuk Hong <hshong@perl.kr>

=cut
