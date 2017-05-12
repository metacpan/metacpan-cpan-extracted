package Hubot::Scripts::lessthanthree;
$Hubot::Scripts::lessthanthree::VERSION = '0.1.10';
use strict;
use warnings;

sub load {
    my ( $class, $robot ) = @_;
    $robot->respond(
        qr/(\<3|lessthanthree)$/i,
        sub {
          my $msg = shift;
          $msg->reply("<3 you too! http://youtu.be/4iHWZRqSTQ4");
        }
    );
}

1;

=head1 NAME

Hubot::Scripts::lessthanthree

=head1 VERSION

version 0.1.10

=head1 SYNOPSIS

hubot <3 - will respond with love. "from p5-hubot with love"

=head1 AUTHOR

Jonas Genannt <jonas@capi2name.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jonas Genannt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
