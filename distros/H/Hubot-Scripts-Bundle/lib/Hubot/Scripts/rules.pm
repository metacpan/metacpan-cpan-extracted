package Hubot::Scripts::rules;
$Hubot::Scripts::rules::VERSION = '0.1.10';
use strict;
use warnings;

my @rules = (
    "1. A robot may not injure a human being or, through inaction, allow a human being to come to harm.",
    "2. A robot must obey any orders given to it by human beings, except where such orders would conflict with the First Law.",
    "3. A robot must protect its own existence as long as such protection does not conflict with the First or Second Law."
);

sub load {
    my ( $class, $robot ) = @_;
    $robot->respond(
        qr/(what are )?the (three |3 )?(rules|laws)/i,
        sub {
            shift->send(@rules);
        }
    );
}

1;

=head1 NAME

Hubot::Scripts::rules

=head1 VERSION

version 0.1.10

=head1 SYNOPSIS

    hubot the rules - make sure hubot still knows the rules.

=head1 AUTHOR

Jonas Genannt <jonas.genannt@capi2name.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jonas Genannt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
