package Gtk3::ImageView::Tool;

use warnings;
use strict;
use Glib qw(TRUE FALSE);    # To get TRUE and FALSE

our $VERSION = '10';

sub new {
    my $class = shift;
    my $view  = shift;
    return bless { _view => $view, }, $class;
}

sub view {
    my $self = shift;
    return $self->{_view};
}

sub button_pressed {
    my $self  = shift;
    my $event = shift;
    return FALSE;
}

sub button_released {
    my $self  = shift;
    my $event = shift;
    return FALSE;
}

sub motion {
    my $self  = shift;
    my $event = shift;
    return FALSE;
}

sub cursor_at_point {
    my ( $self, $x, $y ) = @_;
    my $display     = Gtk3::Gdk::Display::get_default;
    my $cursor_type = $self->cursor_type_at_point( $x, $y );
    if ( defined $cursor_type ) {
        return Gtk3::Gdk::Cursor->new_from_name( $display, $cursor_type );
    }
    return;
}

sub cursor_type_at_point {
    my ( $self, $x, $y ) = @_;
    return;
}

# compatibility layer

sub signal_connect {
    my ( $self, @args ) = @_;
    return $self->view->signal_connect(@args);
}

sub signal_handler_disconnect {
    my ( $self, @args ) = @_;
    return $self->view->signal_handler_disconnect(@args);
}

1;
