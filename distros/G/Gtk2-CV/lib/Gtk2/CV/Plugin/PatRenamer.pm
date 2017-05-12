package Gtk2::CV::Plugin::PetRenamer;

use common::sense;
use IO::AIO;
use Gtk2::SimpleList;

use Gtk2::CV::Jobber;

use Glib::Object::Subclass
   Gtk2::Dialog::,
   properties => [
      Glib::ParamSpec->object ("schnauzer", "Schnauzer", "Schnauzer Window", Gtk2::CV::Schnauzer::, [qw(construct-only readable writable)]),
   ];

sub match_cfc {
   my ($first, @names) = @_;

   my $len = length $first;
   my ($l, $o, $s);

   for $l (reverse 1 .. $len - 1) {
      outer:
      for $o (0 .. $len - $l) {
         $s = substr $first, $o, $l;
         0 <= index $_, $s
            or next outer
            for @names;

         # match found, now split
         my (%pfx, %sfx);

         for ($first, @names) {
            $o = index $_, $s;
            undef $pfx{substr $_, 0, $o};
            undef $sfx{substr $_, $o + $l};
         }

         return ([keys %pfx], $s, [keys %sfx]);
      }
   }

   ()
}

sub split_cfc;
sub split_cfc {
   my ($names) = @_;

   if (my ($pfx, $fixed, $sfx) = match_cfc @$names) {
      ((split_cfc $pfx), [$fixed], (split_cfc $sfx))
   } else {
      $names
   }
}

sub split_names {
   my @names = @_
      or return [];

   @names > 1
      or return [\@names];

   # find longest prefix/suffix (split_fcf)
   my $str = join "\x00", @names;
   study $str;

   $str =~ /^
      ([^\x00]*)
      (?:[^\x00]+?)
      ([^\x00]*)

   (?:
      \x00
      \1
      [^\x00]*
      \2
   )+
   $/x
      or die;

   my $pfx = $1;
   my $sfx = $2;

   # now reduce to c
   if (length $sfx) {
      $_ = substr $_, length $pfx, -length $sfx
         for @names;
   } else {
      $_ = substr $_, length $pfx
         for @names;
   }

   # now recursively split cfc
   [[$pfx], (split_cfc \@names), [$sfx]]
}

#my $res = split_names @names;

sub INIT_INSTANCE {
   my ($self) = @_;

   $self->signal_connect (destroy => sub { %{+shift} = () });
}

sub start {
   my ($self, $schnauzer) = @_;
   $self->{schnauzer} = $schnauzer;

   $self->vbox->add (my $window = new Gtk2::ScrolledWindow);
   $window->add_with_viewport (my $vbox = new Gtk2::VBox);

   my $sel = $schnauzer->{sel};
   my @ents = @{$schnauzer->{entry}}[sort { $a <=> $b } keys %$sel];

   my @names = map $_->[1], @ents;
   my $pat = split_names @names;
   my $rows = List::Util::max map scalar @$_, @$pat;
   my @rep = map { { map { $_ => $_ } @$_ } } @$pat;
   my @kil;

   my $regex = join "", map "(" . (join "|", map "\Q$_", @$_) . ")", @$pat;
   $regex = qr<^$regex$>;

   if ($rows > 100) {
      for (@$pat) {
         if (@$_ > 100) {
            warn "sorry, gtk+ tables are not fast enough for more than 100 rows...\n";
            $rows = 100;
            splice @$_, 100;
         }
      }
   }

   my @repnames;
   my @replabels;

   my $table = new Gtk2::Table 1 + scalar @$pat, $rows + 1;
   $vbox->pack_start ($table, 1, 1, 0);

   my $check_group;

   my $update = sub {
      $check_group->cancel if $check_group;
      $check_group = IO::AIO::aio_group;

      @repnames = map {
         /$regex/ or die "FATAL: $_ does not match $regex";#d#
         join "", map { $kil[$_] ? "" : $rep[$_]{${$_ + 1}} } 0..$#$pat
      } @names;

      for my $i (0 .. $rows - 1) {
         add $check_group IO::AIO::aio_stat "$ents[$i][0]/$repnames[$i]", sub {
            $replabels[$i]->set_text ((-e _ ? "[EXISTS] " : "") . $repnames[$i]);
         };
      }
   };

   my $activate = sub {
      $self->destroy;

      for (0 .. $#names) {
         my $src = $names    [$_];
         my $dst = $repnames [$_];
         my $ent = $ents     [$_];
         my $dir = $ent->[0];

         #TODO: everything is async, yes?
         unless (-e "$dir/$dst") {
            # workaroudn for perl bug 77798
            utf8::downgrade $dir;
            utf8::downgrade $src;
            utf8::downgrade $dst;

            print "$dir/$src => $dir/$dst\n";
            rename "$dir/$src", "$dir/$dst";
            rename "$dir/.xvpics/$src", "$dir/.xvpics/$dst";
            $ent->[1] = $dst;
         }
      }

#         Gtk2::CV::Jobber::submit mv => "$e->[0]/$e->[1]", $path;

      $schnauzer->entry_changed;
      $schnauzer->emit_sel_changed;
      $schnauzer->invalidate_all;
   };

   for my $col (0 .. $#$pat) {
      my $w = new Gtk2::ToggleButton "kil";
      $w->signal_connect (toggled => sub {
         $kil[$col] = $_[0]->get_active;
         $update->();
      });
      $table->attach ($w, $col, $col + 1, 0, 1, ['fill'], ['fill'], 0, 0);
   }

   for my $row (0 .. $rows - 1) {
      for my $col (0 .. $#$pat) {
         my $dat = $pat->[$col];
         my $w;

         if (@$dat > $row) {
            my $part = $dat->[$row];
            $w = new Gtk2::Entry;
            $w->set (
               shadow_type => "in",
               width_chars => length $part,
               text => $part,
            );
            $w->signal_connect (changed => sub {
               utf8::downgrade ($rep[$col]{$part} = $_[0]->get_text);
               $update->();
            });
            $w->signal_connect (activate => $activate);
            $table->attach ($w, $col, $col + 1, $row + 1, $row + 2, ['fill'], ['fill'], 0, 0);
         } else {
            $w = new Gtk2::Label $dat->[-1];
            $w->set_alignment (0, 1);
            $table->attach ($w, $col, $col + 1, $row + 1, $row + 2, ['fill'], ['fill'], 4, 2);
         }
      }

      push @replabels, my $w = new Gtk2::Label $names[$row];
      $table->attach ($w, scalar @$pat, 1 + scalar @$pat, $row + 1, $row + 2, ['fill'], ['fill'], 4, 2);
   }

   $update->();
   $self->show_all;
}

#############################################################################

use Gtk2::CV::Plugin;

sub new_renamer {
   my ($schnauzer) = @_;

   my $renamer = new Gtk2::CV::Plugin::PetRenamer
      schnauzer => $schnauzer,
      modal => 1,
      default_width => 1500, default_height => 1100,
      window_position => "mouse";
   $renamer->start ($schnauzer);
}

sub new_schnauzer {
   my ($self, $schnauzer) = @_;

   $schnauzer->signal_connect (key_press_event => sub {
      my ($self, $event) = @_;
      my $key = $_[1]->keyval;
      my $state = $_[1]->state;
   
      1 <= scalar keys %{ $schnauzer->{sel} }
         or return;

      my $ctrl = grep $_ eq "control-mask", @{$_[1]->state};
      if ($ctrl && $key == $Gtk2::Gdk::Keysyms{r}) {
         new_renamer $schnauzer;
      } else {
         return 0;
      }

      1
   });

   $schnauzer->signal_connect (popup => sub {
      my ($self, $menu, $cursor, $event) = @_;

      2 <= scalar keys %{ $schnauzer->{sel} }
         or return;

      $menu->append (my $item = new Gtk2::MenuItem "Pattern Rename...");
      $item->signal_connect (activate => sub {
         new_renamer $schnauzer;
      });
   });
}

1

