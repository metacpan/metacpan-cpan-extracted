# ABSTRACT: A simple entity registry for ECS designs
package Game::Entities;

use strict;
use warnings;

use Carp         ();
use Data::Dumper ();
use List::Util   ();
use Scalar::Util ();

use experimental 'signatures';

# The main entity registry, inspired by https://github.com/skypjack/entt

use constant {
    SPARSE     => 0,
    DENSE      => 1,
    COMPONENTS => 2,

    # Entity GUIDs are 32 bit integers:
    # * 12 bits used for the entity version (used for recycing entities)
    # * 20 bits used for the entity number
    ENTITY_MASK  => 0xFFFFF, # Used to convert GUIDs to entity numbers
    VERSION_MASK => 0xFFF,   # Used to convert GUIDs to entity versions
    ENTITY_SHIFT => 20,      # The size of the entity number within a GUID
};

## Entity "methods"

my $version = sub ($e) { $e >> ENTITY_SHIFT };
my $entity  = sub ($e) { $e &  ENTITY_MASK  };
my $is_null = sub ($e) { $e->$entity == ENTITY_MASK  };
my $format  = sub ($e) { sprintf '%012b:%020b', $e->$version, $e->$entity };

## Private, hidden methods

my $add_version = sub ($self, $index) {
    $index | ( $self->{entities}[$index]->$version << ENTITY_SHIFT )
};

my $generate_guid = sub ($self) {
    die 'Exceeded maximum number of entities'
        if @{ $self->{entities} //= [] } >= ENTITY_MASK - 1;

    my $guid = @{ $self->{entities} };
    push @{ $self->{entities} }, $guid;

    return $guid;
};

my $recycle_guid = sub ($self) {
    my $next = $self->{available};

    die 'Cannot recycle GUID if none has been released'
        if $next->$is_null;

    my $ver = $self->{entities}[$next]->$version;

    $self->{available} = $self->{entities}[$next]->$entity;

    return $self->{entities}[$next] = $next | ( $ver << ENTITY_SHIFT );
};

my $get = sub ( $self, $unsafe, $guid, @types ) {
    my $index = $guid->$entity;

    my @got = map {
        my $set    = $self->{components}{"$_"};
        my $sparse = $set->[SPARSE][$index];

        defined($sparse) && ( $unsafe || $self->check( $guid, $_ ) )
            ? $set->[COMPONENTS][$sparse] : undef
    } @types;

    return $got[0] if @types == 1;
    return @got;
};

## Public methods

sub new ( $class ) {
    bless { available => ENTITY_MASK }, $class;
}

sub created ($self) { scalar @{ $self->{entities} // [] } }

# Get the number of created entities that are still valid; that is, that have
# not been deleted.
sub alive ($self) {
    my $size = @{ $self->{entities} // [] };
    my $current = $self->{available};

    until ( $current->$is_null ) {
        $size--;
        $current = $self->{entities}[ $current->$entity ];
    }

    return $size;
}

# Reset the registry internal storage. All entities will be deleted, and all
# entity IDs will be made available.
sub clear ($self) {
    delete $self->{view_cache};

    # Keys in this hash are component type names (ie. the result of ref),
    # and values are sparse sets of entities that "have" that component.
    delete $self->{components};

    # Parameters used for recycling entity GUIDs
    # See https://skypjack.github.io/2019-05-06-ecs-baf-part-3
    delete $self->{entities};
    $self->{available} = ENTITY_MASK;

    return;
}

# Create a new entity
sub create ( $self, @components ) {
    Carp::croak 'Component must be a reference'
        if List::Util::any { !ref } @components;

    my $guid = $self->{available}->$is_null
        ? $self->$generate_guid : $self->$recycle_guid;

    $self->add( $guid, @components );

    return $guid;
}

sub check ( $self, $guid, $type ) {
    Carp::croak 'GUID must be defined' unless defined $guid;
    Carp::croak 'Component name must be defined and not a reference'
        if ! defined $type || ref $type;

    my $index  = $guid->$entity;
    my $set    = $self->{components}{"$type"};
    my $sparse = $set->[SPARSE][$index] // return;
    return ( $set->[DENSE][$sparse] // $index + 1 ) == $index;
}

# Add or replace a component for an entity
sub add ( $self, $guid, @components ) {
    Carp::croak 'GUID must be defined' unless defined $guid;

    my $index = $guid->$entity;
    for my $component (@components) {
        my $name = ref($component) || Carp::croak 'Component must be a reference';

        #                                SPARSE  DENSE   COMPONENTS
        #                                      \   |    /
        for ( $self->{components}{$name} //= [ [], [], [] ] ) {
            # Replace component
            if ( $self->check( $guid => $name ) ) {
                $_->[COMPONENTS][ $_->[SPARSE][$index] ] = $component;
            }

            # Add component
            else {
                push @{ $_->[COMPONENTS] }, $component;
                push @{ $_->[DENSE     ] }, $index;

                $_->[SPARSE][$index] = $#{ $_->[DENSE] };
            }
        }

        # Adding a component invalidates any cached view that uses it
        delete $self->{view_cache}{$_} for
            grep { index( $_, "|$name|" ) != -1 }
            keys %{ $self->{view_cache} },
    }

    return;
}

# Get a component for an entity
# The public version of this method forwards to the "safe" flavour of the
# private one
sub get ( $self, $guid, @types ) {
    Carp::croak 'GUID must be defined' unless defined $guid;

    Carp::croak 'Component name must be defined and not a reference'
        if List::Util::any { !defined || ref } @types;

    $self->$get( 0, $guid, @types );
}

sub delete ( $self, $guid, @types ) {
    Carp::croak 'GUID must be defined' unless defined $guid;

    unless (@types) {
        # Remove an entity and all its components
        if ( my @all = keys %{ $self->{components} } ) {
            $self->delete( $guid, @all );
        }

        # We mark an entity as available by splitting the entity and the version
        # and storing the incremented version only in the entities list, and the
        # available entity ID in the 'available' slot

        my $ent = $guid->$entity;
        my $ver = $guid->$version + 1;

        $self->{entities}[$ent] = $self->{available} | ( $ver << ENTITY_SHIFT );
        $self->{available} = $ent;

        return;
    }

    Carp::croak 'Component name must not be a reference'
        if List::Util::any { ref } @types;

    for my $name (@types) {
        next unless $self->check( $guid, $name );

        my $e = $guid->$entity;

        for ( $self->{components}{$name} ) {
            my ( $i, $j ) = ( $_->[SPARSE][$e], $#{ $_->[DENSE] } );

            for ( $_->[DENSE], $_->[COMPONENTS] ) {
                @{ $_ }[ $i, $j ] = @{ $_ }[ $j, $i ];
                pop @$_;
            }

            $j = $_->[DENSE][$i] // next;

            $_->[SPARSE][$j] = $i;
        }

        # Deleting a component invalidates any cached view that uses it
        delete $self->{view_cache}{$_} for
            grep { index( $_, "|$name|" ) != -1 }
            keys %{ $self->{view_cache} },
    }

    return;
}

# Checks if an entity identifier refers to a valid entity; that is, one that
# has been created and not deleted.
sub valid ( $self, $guid ) {
    Carp::croak 'GUID must be defined' unless defined $guid;

    my $pos = $guid->$entity;
    $pos < @{ $self->{entities} }
        && ( $self->{entities}[$pos] // $guid + 1 ) == $guid;
}

package
    Game::Entities::View {
    no overloading;

    use overload
        bool  => sub { 1 },
        '@{}' => sub ($self, @) {
            [ List::Util::pairs @$self ];
        };

    sub new ( $class, @view ) { bless \@view, $class }

    sub each ( $self, $code ) {
        $code->( $_->[0], @{ $_->[1] } ) for List::Util::pairs @$self
    }

    sub entities   ($self) { ( List::Util::pairkeys   @$self ) }
    sub components ($self) { ( List::Util::pairvalues @$self ) }
}

sub view ( $self, @types ) {
    # Return a view for all entities
    # The view of all entities is never cached
    unless (@types) {
        return Game::Entities::View->new(
            map {; $self->$add_version( $_->$entity ) => [] }
                grep $self->valid( $_ ),
                @{ $self->{entities} }
        )
    }

    # Return a view for a single component
    if ( @types == 1 ) {
        my ($name) = @types;

        return $self->{view_cache}{"|$name|"} //= do {
            my $set   = $self->{components}{$name};
            my $comps = $set->[COMPONENTS];

            Game::Entities::View->new(
                map {
                    my ( $i, $e ) = ( $_, $set->[DENSE][$_] );
                    $self->$add_version($e) => [ $comps->[$i] ];
                } 0 .. $#{ $set->[DENSE] }
            )
        };
    }

    # Return a view for entities that have the specified set of components
    return $self->{view_cache}{'|' . join( '|', @types ) . '|' } //= do {
        my $map = $self->{components};

        my ( $short, @rest ) = sort {
            @{ $map->{$a}[DENSE] // [] } <=> @{ $map->{$b}[DENSE] // [] }
        } @types;

        my $set   = $self->{components}{$short};
        my $comps = $set->[COMPONENTS];

        my @view;
        while ( my ( $i, $e ) = each @{ $set->[DENSE] } ) {
            my $guid = $self->$add_version($e);

            next unless List::Util::all { $self->check( $guid => $_ ) } @rest;

            push @view, $guid => [
                map {
                    $_ eq $short
                        ? $comps->[$i]
                        : $self->$get( 1, $guid, $_ )
                } @types
            ];
        }

        Game::Entities::View->new(@view);
    };
}

sub _dump_entities ( $self, @types ) {
    local $Data::Dumper::Terse  = 1;
    local $Data::Dumper::Indent = 0;

    my @names = @types || keys %{ $self->{components} };

    my $print = ! defined wantarray;
    open my $fh, '>', \my $out or $print = 1;
    $fh = *STDOUT if $print;

    my $index;
    for (@names) {
        next unless my $set = $self->{components}{$_};
        next unless @{ $set->[SPARSE] // [] };

        print $fh "# [$_]\n" if !@types || @names > 1;
        print $fh "# SPARSE DENSE WHERE        COMPONENT\n";

        for ( 0 .. $#{ $set->[SPARSE] } ) {
            my $component = $set->[COMPONENTS][$_];

            print $fh sprintf "# %6s %5s %12X %s\n",
                $set->[SPARSE][$_] // '---',
                $set->[DENSE][$_]  // '---',
                Scalar::Util::refaddr($component) // 0,
                defined $component
                    ? Data::Dumper::Dumper($component) =~ s/[\n\r]//gr : '---';
        }

        print $fh "#\n" if $index++ < $#names;
    }

    $out unless $print;
}

# Clean our namespace
delete $Game::Entities::{$_} for qw(
    COMPONENTS
    DENSE
    ENTITY_MASK
    ENTITY_SHIFT
    SPARSE
    VERSION_MASK
);

1;
