package t::PluginEntryPoints::ListeningService;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
);

extends 'Lemonldap::NG::Portal::Main::Plugin';

has _log => ( is => 'rw', builder => sub { [] } );

sub init {
    1;
}

sub notify {
    my ( $self, @content ) = @_;
    push @{ $self->_log }, [@content];
}

sub get_log {
    my ($self) = @_;
    return [
        map {
            my $obj = shift @$_;
            [ ref($obj), @$_ ]
        } @{ $self->_log() }
    ];
}

1;
