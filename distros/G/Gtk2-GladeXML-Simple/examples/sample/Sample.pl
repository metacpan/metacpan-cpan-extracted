package Sample;

use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::GladeXML::Simple;

use base qw( Gtk2::GladeXML::Simple );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( 'sample.glade' );
    return $self;
}

sub on_button1_clicked {
    my $self = shift;
    my $buffer = $self->{textview1}->get_buffer;
    print $buffer->get_text( $buffer->get_start_iter, $buffer->get_end_iter, 0 );
}

sub on_button2_clicked {
    my $self = shift;
    Gtk2->main_quit;
}

1;

package main;

Sample->new->run;

1;
