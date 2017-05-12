package TestHandler;
use strict;
use warnings;
use base 'Dezi::Bot::Handler::FileCacher';
use Carp;

my %handled = ();

sub handle {
    my $self = shift;
    my $bot  = shift or croak "Bot missing";
    my $doc  = shift or croak "Doc missing";
    $self->SUPER::handle( $bot, $doc );
    $handled{ $doc->url }->{ $bot->name }++;
}

sub handled {
    return \%handled;
}

1;
