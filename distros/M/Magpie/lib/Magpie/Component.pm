package Magpie::Component;
$Magpie::Component::VERSION = '1.163200';
# ABSTRACT: Base Class For All Magpie Pipeline Components
use Moose;
use Magpie::Constants;
use Magpie::Breadboard;

with qw(Magpie::Event MooseX::Traits);

has '+_trait_namespace' => ( default => 'Magpie::Plugin' );

has breadboard => (
    is      => 'rw',
    isa     => 'Magpie::Breadboard',
    default => sub { Magpie::Breadboard->new(); },
    lazy    => 1,
    handles => [
        qw( add_asset assets resolve_asset internal_assets resolve_internal_asset)
    ],
);

sub default_symbol_table {
    $_[0]->resolve_internal_asset( service => 'symbol_table' );
}

sub init_symbols {
    my ( $self, $context ) = @_;

    my @events           = ();
    my %processed_events = ();

    my @self_and_ancestors = $self->meta->linearized_isa;

# need the full list to cover overridden methods not registered (via register_events()) in component subclasses.

    foreach my $obj (@self_and_ancestors) {
        next unless $obj->can('registered_events');
        push @events, $obj->registered_events;
    }

    foreach my $obj ( $self->meta->linearized_isa ) {
        for ( my $i = 0; $i < scalar @events; $i++ ) {

            next if ref( $events[$i] ) eq 'CODE';
            next if defined $processed_events{ $events[$i] };

            if ( ref( $events[ $i + 1 ] ) eq 'CODE' ) {
                $self->add_symbol_handler( $events[$i] => $events[ $i + 1 ] );
                $processed_events{ $events[$i] }++;
            }
            elsif ( my $ref = $obj->can( $events[$i] ) ) {
                $self->add_symbol_handler( $events[$i] => $ref );
                $processed_events{ $events[$i] }++;
            }
        }
    }
}

# SEEALSO: Magpie, Magpie::Resource, Magpie::Transformer

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Magpie::Component - Base Class For All Magpie Pipeline Components

=head1 VERSION

version 1.163200

=head1 AUTHORS

=over 4

=item *

Kip Hampton <kip.hampton@tamarou.com>

=item *

Chris Prather <chris.prather@tamarou.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Tamarou, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
