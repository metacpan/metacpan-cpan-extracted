=head1 NAME

Gtk2::CV::PrintDialog - the CV print dialog widget

=head1 SYNOPSIS

  use Gtk2::CV::PrintDialog;

=head1 DESCRIPTION

=head2 METHODS

=over 4

=cut

package Gtk2::CV::PrintDialog;

use common::sense;
use Gtk2;
use Gtk2::Gdk::Keysyms;

use Gtk2::CV;
use Gtk2::CV::PostScript;

use Gtk2::GladeXML;

sub new {
   my $class = shift;
   my $self = bless { @_ }, $class;

   $self->{dialog} = my $d = new Gtk2::GladeXML Gtk2::CV::find_rcfile "cv.glade", "PrintDialog";
   #$d->signal_connect_all ...

   $d->get_widget ("destination")->set (text => $ENV{CV_PRINT_DESTINATION} || "| lpr");

   my $menu = new Gtk2::Menu;
   for (Gtk2::CV::PostScript->papersizes) {
      my ($code, $name, $w, $h) = @$_;
      $menu->append (my $item = new Gtk2::MenuItem $name);
      $item->set_name ($code);
   }
   $menu->show_all;
   $d->get_widget ("papersize")->set_menu ($menu);

   $d->get_widget ("papersize")->set_history (0);

   $d->get_widget ("PrintDialog")->signal_connect (close => sub {
      $_[0]->destroy;
   });

   $d->get_widget ("PrintDialog")->signal_connect (response => sub {
      if ($_[1] eq "ok") {
         $self->print (
            size        => (Gtk2::CV::PostScript->papersizes)[$d->get_widget ("papersize")->get_history],
            margin      => $d->get_widget ("margin")->get_value,
            color       => $d->get_widget ("type_color")->get ("active"),
            interpolate => $d->get_widget ("interpolate_enable")->get ("active")
                              ? $d->get_widget ("interpolate_mb")->get_value
                              : 0,
            dest_type   => (qw(perl file pipe))[$d->get_widget ("dest_type")->get_history],
            destination => $d->get_widget ("destination")->get ("text"),
            binary      => $d->get_widget ("encoding_binary")->get ("active"),
         );
      }
      $_[0]->destroy;
   });

   $self;
}

sub print {
   my ($self, %arg) = @_;

   my $fh;

   if ($arg{dest_type} eq "file") {
      open $fh, ">", $arg{destination};
   } elsif ($arg{dest_type} eq "pipe") {
      open $fh, "-|", $arg{destination};
   } else {
      open $fh, $arg{destination};
   }

   $fh or die "$arg{destination}: $!";

   (new Gtk2::CV::PostScript fh => $fh, %arg, %$self)->print;

   close $fh or warn "$arg{destination}: $!";
}

=back

=head1 AUTHOR

Marc Lehmann <schmorp@schmorp.de>

=cut

1

