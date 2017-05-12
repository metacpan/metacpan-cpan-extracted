package Games::Perlwar::Array;

our $VERSION = '0.03';

use strict;
use warnings;
use Carp;
use utf8;

use Class::Std;
use Games::Perlwar::Cell;

my %cells_of          ;
my %size_of           : ATTR( :name<size> :default<100> );

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub START {
    my( $self, $id ) = @_;

    my @cells;

    push @cells, Games::Perlwar::Cell->new for 1..$size_of{ $id };

    $cells_of{ $id } = \@cells;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub load_from_xml {
    my( $self, $xml ) = @_;
    my $id = ident $self;

    for my $cell ( $xml->findnodes( '//agent' ) ) {
        my $position = $cell->findvalue( '@position' );
		my $owner = $cell->findvalue( '@owner' );
		my $facade = 
            $cell->findvalue( '@facade' );
		my $code = $cell->findvalue( "text()" );
        utf8::decode( $code );

        $self->set_cell( $position => {
                owner => $owner,
                code => $code,
                facade => $facade,
        } );
    }
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub set_cell {
    my( $self, $position, $ref_args ) = @_;
    my $id = ident $self;

    $self->get_cell( $position )->set( $ref_args );
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub clear {
    my $self = shift;

    $_->clear for @{$cells_of{ ident $self }};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub run_cell {
    my( $self, $cell_id, $vars_ref ) = @_;
    my %vars;
    %vars = %$vars_ref if $vars_ref;

    my $cell = $self->get_cell( $cell_id );

    return $cell->run({
        %vars,
        '@_' => [ $self->get_cells_code( $cell_id ) ],
        '@o' => [ $self->get_facades( $cell_id ) ],
        });
   
    
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub get_cell {
    my( $self, $position ) = @_;
    my $id = ident $self;

    $position %= $size_of{ $id };

    return $cells_of{ $id }[ $position ];
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub get_cells_code {
    my( $self, $base ) = @_;
    my $id = ident $self;

    my $last_index = $size_of{ $id } - 1;
    return map { $_->get_code  } 
               @{$cells_of{ $id }}[ $base..$last_index, 0..($base-1) ];

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub get_facades {
    my( $self, $base ) = @_;
    my $id = ident $self;

    my $last_index = $size_of{ $id } - 1;
    return map { $_->get_facade } 
               @{$cells_of{ $id }}[ $base..$last_index, 0..($base-1) ];
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub census {
    my ( $self ) = @_;
    my $id = ident $self;

    my %census;
    my @cells = @{ $cells_of{ $id } };

    for my $cell ( @cells ) {
        my $owner = $cell->get_owner;
        $census{ $owner }++ if $owner;
    }

    return %census;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub empty_cells {
    my $self = shift;
    my $id = ident $self;
    
    return grep { $cells_of{$id}[$_]->is_empty } 0..$size_of{ $id }-1;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub cells_belonging_to {
    my( $self, $player ) = @_;
    my $id = ident $self;

    return grep { $_->get_owner eq $player } @{ $cells_of{$id} };
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub cell { $_[0]->get_cell( $_[1] ); }

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub reset_operational {
    my( $self ) = @_;
    my $id = ident $self;

    $_->set_operational( 1 ) for @{ $cells_of{ $id } };
}

sub save_as_xml {
    my( $self, $writer ) = @_;
    my $id = ident $self;
        
	$writer->startTag( 'theArray', size => $size_of{ $id } );
    for my $id ( 0..@{$cells_of{ $id}} ) {
        my $cell = $self->cell( $id );
        next if $cell->is_empty;

        my $owner = $cell->get_owner;
        my $facade = $cell->get_facade;

        $facade = undef if $facade eq $owner;

        $writer->dataElement( 'agent', $cell->get_code,
                                        position => $id, 
                                        owner => $owner,
                                        ( facade => $facade ) x !!$facade,
                            );
    }
    $writer->endTag;
}   

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

1;
