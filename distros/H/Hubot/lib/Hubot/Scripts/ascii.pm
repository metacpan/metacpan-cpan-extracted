package Hubot::Scripts::ascii;
$Hubot::Scripts::ascii::VERSION = '0.2.8';
use strict;
use warnings;

sub load {
    my ( $class, $robot ) = @_;
    $robot->hear(
        qr/^ascii:?( me)? (.+)/i,
        sub {
            my $msg = shift;

            $msg->http('http://www.kammerl.de/ascii/AsciiSignature.php')->post(
                { figletfont => "3", figlettext => $msg->match->[1] },
                sub {
                    my ( $body, $hdr ) = @_;
                    return if ( !$body || !$hdr->{Status} =~ /^2/ );
                    my ($ascii) = $body =~ m/<small>(.*?)<\/small><br\/>/is;
                    $msg->send( split( /\n/, $ascii ) );
                }
            );
        }
    );
}

1;

=pod

=encoding utf-8

=head1 NAME

Hubot::Scripts::ascii

=head1 VERSION

version 0.2.8

=head1 SYNOPSIS

    ascii me <text> - Show text in ascii art

=head1 AUTHOR

Hyungsuk Hong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Hyungsuk Hong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
