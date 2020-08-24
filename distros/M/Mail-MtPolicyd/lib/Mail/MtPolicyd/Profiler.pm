package Mail::MtPolicyd::Profiler;

use strict;
use warnings;

use MooseX::Singleton;
use namespace::autoclean;

use Mail::MtPolicyd::Profiler::Timer;
use JSON;

our $VERSION = '2.05'; # VERSION
# ABSTRACT: a application level profiler for mtpolicyd

has 'root' => ( is => 'rw', isa => 'Mail::MtPolicyd::Profiler::Timer',
    lazy => 1,
    default => sub {
        Mail::MtPolicyd::Profiler::Timer->new( name => 'main timer' );
    },
);

has 'current' => (
    is => 'rw', isa => 'Mail::MtPolicyd::Profiler::Timer',
    handles => {
        'tick' => 'tick',
    },
    lazy => 1,
    default => sub {
        my $self = shift;
        return $self->root;
    },
);

sub reset {
    my ( $self, $name ) = @_;
    my $timer = Mail::MtPolicyd::Profiler::Timer->new( name => 'main timer' );

    $self->root( $timer );
    $self->current( $timer );

    return;
}

sub new_timer {
    my ( $self, $name ) = @_;
    my $timer = $self->current->new_child( name => $name );
    $self->current( $timer );
    return;
}

sub stop_current_timer {
    my ( $self, $name ) = @_;
    $self->current->stop;
    if( defined $self->current->parent ) {
        $self->current($self->current->parent);
    }
    return;
}

sub to_string {
    my $self = shift;
    return $self->root->to_string;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::MtPolicyd::Profiler - a application level profiler for mtpolicyd

=head1 VERSION

version 2.05

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
