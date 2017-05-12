#!/usr/bin/perl

use strict;
use warnings;

use Tickit;
use Tickit::Widgets qw( GridBox Button CheckButton Static );
use Device::FTDI::MPSSE qw( DBUS CBUS );

Tickit::Style->load_style( <<'EOSTYLE' );
Button {
  bg: "black"; fg: "white";
}
Button:current {
  bg: "white"; fg: "black";
}
Button:read {
  bg: "red"; fg: "black";
}
EOSTYLE

my $bb = Device::FTDI::MPSSE->new;

my $grid = Tickit::Widget::GridBox->new(
    style => {
        row_spacing => 1,
        col_spacing => 1,
    },
);

my @dirbuttons;
my @levelbuttons;

sub make_buttons
{
    my ( $port, $bit, $mask ) = @_;

    my $check;
    my @buttons;
    @{ $levelbuttons[$port][$bit] } = @buttons = map {
        my $hi = ( $_ eq "HI" );

        Tickit::Widget::Button->new(
            label    => $_,
            on_click => sub {
                my $self = shift;
                return if $check->is_active;

                $bb->write_gpio( $port, $hi ? 0xFF : 0, $mask )->get;

                $_->set_style_tag( current => 0 ) for @buttons;
                $self->set_style_tag( current => 1 );
            },
        )
    } qw( HI LO );

    $dirbuttons[$port][$bit] = $check = Tickit::Widget::CheckButton->new(
        label => "read",
        on_toggle => sub {
            my $self = shift;
            if( $self->is_active ) {
                $_->set_style_tag( current => 0 ) for @buttons;
                $bb->tris_gpio( $port, $mask )->get;
            }
            else {
                $_->set_style_tag( read => 0 ) for @buttons;
                $bb->write_gpio( $port, 0, $mask )->get;
            }
        },
    ),

    return @buttons, $check;
}

foreach my $bit ( reverse 0 .. 7 ) {
    my $mask = 1 << $bit;

    $grid->append_col( [
        # DBUS
        Tickit::Widget::Static->new( text => "D$bit" ),
        make_buttons( DBUS, $bit, $mask ),

        # CBUS
        Tickit::Widget::Static->new( text => "C$bit" ),
        make_buttons( CBUS, $bit, $mask ),
    ] );

    $dirbuttons[DBUS][$bit]->activate;
    $dirbuttons[CBUS][$bit]->activate;
}

# All pins inputs
Future->needs_all(
    $bb->tris_gpio( DBUS, 0xFF ),
    $bb->tris_gpio( CBUS, 0xFF ),
)->get;

my $tickit = Tickit->new( root => $grid );

sub update_buttons
{
    my ( $port ) = @_;

    my $mask = 0;
    $dirbuttons[$port][$_]->is_active and $mask |= ( 1 << $_ )
        for 0 .. 7;

    $bb->read_gpio( $port, $mask )->on_done( sub {
        my ( $val ) = @_;

        foreach my $bit ( 0 .. 7 ) {
            my $bitval = $val & ( 1 << $bit );
            next unless $dirbuttons[$port][$bit]->is_active;

            # HI
            $levelbuttons[$port][$bit][0]->set_style_tag(
                read => !!$bitval,
            );
            # LO
            $levelbuttons[$port][$bit][1]->set_style_tag(
                read =>  !$bitval,
            );
        }
    });
}

sub read_pins
{
    Future->needs_all(
        update_buttons( DBUS ),
        update_buttons( CBUS ),
    )->get;

    $tickit->timer( after => 0.05, \&read_pins );
}
read_pins;

$tickit->run;
