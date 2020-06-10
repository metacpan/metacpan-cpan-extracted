#########################################################################################
# Package        HiPi::Interface::Common::HD44780
# Description  : Control a LCD based on HD44780
# Copyright    : Copyright (c) 2013-2017 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::Common::HD44780;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Interface );
use Carp;
use HiPi qw( :lcd );

our $VERSION ='0.81';

__PACKAGE__->create_accessors( qw(
    width lines backlightcontrol positionmap devicename serialbuffermode
) );


sub new {
    my ($class, %userparams ) = @_;
    
    my %params = (
        width            =>  undef,
        lines            =>  undef,
        backlightcontrol =>  0,
        device           =>  undef,
        positionmap      =>  undef,
    );
    
    # get user params
    foreach my $key( keys (%userparams) ) {
        $params{$key} = $userparams{$key};
    }
    
    croak('A derived class must provide a device') unless(defined($params{device}));
    
    unless( $params{positionmap} ) {   
        # setup default position map
        unless( $params{width} =~ /^(16|20)$/ && $params{lines} =~ /^(2|4)$/) {
            croak('HiPi::Interface::Common::HD44780 only supports default LCD types 16x2, 16x4, 20x2, 20x4' );
        }
        my (@pmap, @line1, @line2, @line3, @line4, @buffers);
        
        if( $params{width} == 16 && $params{serialbuffermode} ) {
            @line1 = (0..15);
            @line2 = (64..79);
            @line3 = (16..31);
            @line4 = (80..95);
        } else {
            @line1 = (0..19);
            @line2 = (64..83);
            @line3 = (20..39);
            @line4 = (84..103);
        }
        
        if( $params{lines} == 2 ) {
            @pmap = ( @line1, @line2 );
        } elsif( $params{lines} == 4 ) {
            @pmap = ( @line1, @line2, @line3, @line4 );
        }
        
        $params{positionmap} = \@pmap;
    }
    
    my $self = $class->SUPER::new(%params);
    
    $self->update_geometry; # will set cols / lines to controller
    
    return $self;
}

sub enable {
    my($self, $enable) = @_;
    $enable = 1 unless defined($enable);
    my $command = ( $enable ) ? HD44780_DISPLAY_ON : HD44780_DISPLAY_OFF;
    $self->send_command( $command ) ;
}

sub set_cursor_position {
    my($self, $col, $row) = @_;
    my $pos = $col + ( $row * $self->width ); 
    $self->send_command( HD44780_CURSOR_POSITION + $self->positionmap->[$pos] );
}

sub move_cursor_left  {
    $_[0]->send_command( HD44780_SHIFT_CURSOR_LEFT );
}

sub move_cursor_right  {
    $_[0]->send_command( HD44780_SHIFT_CURSOR_RIGHT );
}

sub home  { $_[0]->send_command( HD44780_HOME_UNSHIFT ); }

sub clear { $_[0]->send_command( HD44780_CLEAR_DISPLAY ); $_[0]->delayMicroseconds(2000); }

sub set_cursor_mode { $_[0]->send_command( $_[1] ); }

sub backlight { croak('backlight must be overriden in derived class'); }

sub send_text { croak('send_text must be overriden in derived class'); }

sub send_command { croak('send_command must be overriden in derived class'); }

sub update_baudrate { croak('update_baudrate must be overriden in derived class'); }

sub update_geometry { croak('update_geometry must be overriden in derived class'); }

1;

__END__
