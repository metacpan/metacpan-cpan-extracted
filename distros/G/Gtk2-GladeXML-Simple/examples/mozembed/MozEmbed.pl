package MozEmbed;

use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::GladeXML::Simple;
use Gtk2::MozEmbed;

use base qw( Gtk2::GladeXML::Simple );

sub new { shift->SUPER::new( 'mozembed.glade' ) }
sub on_back_clicked { shift->{mozembed}->go_back }
sub on_forward_clicked { shift->{mozembed}->go_forward }
sub on_url_entry_activate { $_[0]->{mozembed}->load_url(
							$_[0]->{url_entry}->get_text
						       ) }
sub on_mozembed_location { $_[0]->{url_entry}->set_text(
							$_[0]->{mozembed}->get_location
						       ) }
sub gtk_main_quit { Gtk2->main_quit }
sub gtk_mozembed_new {
    my $self = shift;
    my $mozembed = Gtk2::MozEmbed->new;
    $mozembed->show_all;
    return $mozembed;
}

1;

package main;

MozEmbed->new->run;

1;
