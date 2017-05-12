package Gtk2::CV::Plugin::RCluster;

use strict;

use common::sense;
use File::Temp;

use Gtk2::CV;
use Gtk2::CV::Plugin;

sub clusterise {
   my ($pics) = @_;

   #my $hists = make_histograms $pics;
   my $hists = extract_features $pics;

   my ($fh, $datafile) = File::Temp::tempfile;
      for (0 .. $#$hists) {
         print $fh "$_\t" . (join "\t", unpack "f*", $hists->[$_]) . "\n";
      }
   close $fh;

   my ($fh, $rfile) = File::Temp::tempfile;
      print $fh <<EOF;
         library(cluster)
         data <- read.table(file="$datafile", sep="\\t", row.names = 1)
         res <- agnes(data, diss=FALSE, metric = "euclidean")
         write.table(res\$order.lab, file="$datafile", sep="\\t", quote=FALSE, col.names = FALSE,row.names = FALSE)
EOF
   close $fh;

   system "R CMD BATCH --slave --vanilla $rfile /dev/null";
   #$? && die ...;#TODO

   unlink $rfile;

   open my $fh, "<", $datafile
      or die "$datafile: $!";
   unlink $datafile;
   
   [ do { local $/; split /\n/, <$fh> } ]
}

sub histsort_selected {
   my ($schnauzer) = @_;

   my $sel   = $schnauzer->{sel};
   my $entry = $schnauzer->{entry};

   my @ent;
   my @pic;
   my @idx;

   for my $i (sort { $a <=> $b } keys %$sel) {
      my $entry = $entry->[$i];

      next unless $entry->[2] & Gtk2::CV::Schnauzer::F_HASXVPIC;

      $schnauzer->force_pixmap ($entry);
      
      my $pb = Gtk2::Gdk::Pixbuf->get_from_drawable ($entry->[3], undef, 0, 0, 0, 0, -1, -1);

      push @idx, $i;
      push @ent, $entry;
      push @pic, $pb->get_pixels;
   }

   my $sorted = clusterise \@pic;

   for (0 .. $#idx) {
      $entry->[ $idx[$_] ] = $ent[ $sorted->[$_] ];
   }

   $schnauzer->entry_changed;
   $schnauzer->invalidate_all;
}

sub new_schnauzer {
   my ($self, $schnauzer) = @_;

   $schnauzer->signal_connect (popup => sub {
      my ($self, $menu, $cursor, $event) = @_;
      
      $menu->append (my $i_up = new Gtk2::MenuItem "Image clustering (GNU-R)...");
      $i_up->signal_connect (activate => sub {
         histsort_selected $schnauzer;
      });
   });
}

=head1 AUTHORS

Robin Redeker, Marc Lehmann

=cut

1
