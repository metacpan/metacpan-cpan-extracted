#########################################################################################
# Package        HiPi::Utils::BitBuffer
# Description  : Bit Buffers
# Copyright    : Copyright (c) 2018-2020 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Utils::BitBuffer;

#########################################################################################

use strict;
use warnings;
use Bit::Vector;
use parent qw( HiPi::Class );

our $VERSION ='0.82';

__PACKAGE__->create_accessors ( qw( buffer y_buffer width height autoresize autoincrement ) );

sub new {
    my ( $class, %userparams ) = @_;
    
    my %params = (
        width       => 8,
        height      => 8,
        autoresize  => 0,
        autoincrement => 1
    );
    
     # get user params
    foreach my $key( keys (%userparams) ) {
        $params{$key} = $userparams{$key};
    }
    
    my $buffer = _create_new_buffer( $params{width}, $params{height} );
    
    $params{buffer} = $buffer;
    my $self = $class->SUPER::new( %params );
    
    return $self;
}

sub _create_new_buffer {
    my($w,$h, $val) = @_;
    $val ||= 0;
    my @buffer = ();
    for ( my $i = 0; $i < $h; $i++ ) {
        my $row = Bit::Vector->new( $w );
        push @buffer, $row;
    }
    
    return \@buffer;
}

sub set_bit {
    my ($self, $x, $y, $val) = @_;
    return if( $x < 0 || $y < 0 );
    
    # check if buffer needs resizing
    if(  $self->autoresize ) {
        my ($neww, $newh) = (0,0);
        if( $x >= $self->width ) {
            $neww = $x + $self->autoincrement;
        }
        if( $y >= $self->height ) {
            $newh = $y + 1;
        }
        if( $neww || $newh ) {
            $self->_reset_buffer( $neww || $self->width, $newh || $self->height );
        }
    } else {
        return if( $x >= $self->width || $y >= $self->height );
    }
    
    # set the bit
    if($val) {
        $self->buffer->[$y]->Bit_On($x);
    } else {
        $self->buffer->[$y]->Bit_Off($x);
    }
    return;
}

sub get_bit {
    my($self, $x, $y) = @_;
    return 0 if( $x < 0 || $x >= $self->width || $y < 0 || $y >= $self->height );
    return 0 + $self->buffer->[$y]->contains( $x );
}

sub _reset_buffer {
    my( $self, $w, $h ) = @_;
    
    # change the width ? extend each column vector
    if( $w > $self->width ) {
        for my $vector (  @{ $self->buffer } ) {
            $vector->Resize( $w );
        }
        $self->width( $w );
    }
    
    # change the height ? - add a new bit vector for every row
    if( $h > $self->height ) {
        for (my $i = 0; $i < $h - $self->height; $i++) {
            push @{ $self->buffer }, Bit::Vector->new( $self->width );
        }
        $self->height( $h );
    }
    
    return;
}

sub clear {
    my ( $self ) = @_;
    for (my $row = 0; $row < $self->height; $row ++) {
        $self->buffer->[$row]->Empty;
    }
}

sub fill {
    my ( $self ) = @_;
    for (my $row = 0; $row < $self->height; $row ++) {
        $self->buffer->[$row]->Fill;
    }
}

sub clone_buffer {
    my $self = shift;
    my $class = ref( $self );
    
    my $clone = $class->new(
        width => $self->width,
        height => $self->height,
        autoresize => $self->autoresize,
        autoincrement => $self->autoincrement,
    );
    
    my @newbuffer = ();
    for (my $i = 0; $i < $self->height; $i ++ ) {
        push @newbuffer, $self->buffer->[$i]->Clone;
    }
    $clone->buffer( \@newbuffer );
    
    return $clone;
}

sub scroll_x_y {
    my($self, $scrollx, $scrolly) = @_;
    $scrollx %= $self->width;
    $scrolly %= $self->height;
    return unless($scrollx || $scrolly);
    if( $scrolly ) {
        my @vals = splice( @{ $self->buffer }, 0, $scrolly );
        push @{ $self->buffer }, @vals;
    }
    if( $scrollx ) {
        for ( my $y = 0; $y < $self->height; $y ++ ) {
            $self->buffer->[$y]->Interval_Substitute($self->buffer->[$y],$self->buffer->[$y]->Size,$scrollx,0,$scrollx);
            $self->buffer->[$y]->Interval_Substitute($self->buffer->[$y],0,$scrollx,0,0);
        }
    }
    return;
}

sub mirror {
    my ($self, $shapex) = @_;
    $shapex //= 0;
    $shapex = abs($shapex);
    $shapex = $self->width if $shapex > $self->width;
    for ( my $y = 0; $y < $self->height; $y ++ ) {
        $self->buffer->[$y]->Reverse($self->buffer->[$y]);
    }
    $self->scroll_x_y( $self->width - $shapex, 0 ) if $shapex && $shapex != $self->width;
    return;
}

sub flip {
    my ($self, $shapex, $shapey) = @_;
    $shapey //= 0;
    $shapey = abs($shapey);
    $shapey = $self->height if $shapey > $self->height;
    my @newbuff;
    for (my $i = 0; $i < $self->height; $i ++) {
        unshift( @newbuff, $self->buffer->[$i] );
    }
    
    if( $shapey && $shapey != $self->height ) {
        my @vals = splice( @newbuff, 0, $self->height - $shapey );
        push @newbuff, @vals;
    }
    
    $self->buffer( \@newbuff );
    $self->mirror( $shapex, 0 );
    return;
}

1;