package Gtk::Atoms;

require Gtk;
use Exporter ();
use Tie::Hash;

use strict;
use vars qw(%ATOMS @ISA @EXPORT);

@ISA = qw(Exporter Tie::StdHash);

@EXPORT = qw();

sub FETCH {
    my $self = shift;
    my $key = shift;

    if ( !exists $self->{$key} ) {
	$self->{$key} = Gtk::Gdk::Atom->intern($key,0);
    }
    
    $self->{$key};
}

tie (%Gtk::Atoms, 'Gtk::Atoms');

1;
