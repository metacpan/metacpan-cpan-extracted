#!/usr/bin/env perl
package UpperCaser;
use Moose;
use namespace::autoclean;
use lib '../lib';
extends 'IO::Multiplex::Intermediary::Client';

=head1 INSTRUCTIONS

Run this:

    perl -Ilib bin/intermediary.pl 3030

Then run this module, like so:

    perl -MUpperCaser -e 'UpperCaser->new->run'

Then connect remotely
    
    telnet localhost 3030

And start typing stuff in!
Anything you type in should come back uppercase.

    hai
    HAI

=cut

around build_response => sub {
    my $orig = shift;
    my $self = shift;

    return uc($self->$orig(@_));
};

__PACKAGE__->meta->make_immutable;

1;
