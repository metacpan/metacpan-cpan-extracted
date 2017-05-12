package KGS::Listener::Debug;

use base KGS::Listener;

sub dumphex($) {
   my ($data) = @_;
   my $dump;

   for (my $ofs = 0; $ofs < length $data; $ofs += 16) {
      my $sub = substr $data, $ofs, 16;
      my $hex = unpack "H*", $sub;
      $sub =~ y/\x20-\x7e\xa0-\xff/./c;
      $dump .= sprintf "%04x: %-8s %-8s %-8s %-8s %s\n",
               $ofs,
               (substr $hex,  0, 8), (substr $hex,  8, 8),
               (substr $hex, 16, 8), (substr $hex, 24, 8),
               $sub;
   }

   $dump;
}

=item dumpval any-perl-ref

Tries to dump the given perl-ref into a nicely-formatted
human-readable-format (currently uses either Data::Dumper or Dumpvalue)
but tries to be I<very> robust about internal errors, i.e. this functions
always tries to output as much usable data as possible without die'ing.

=cut

sub dumpval($) {
   eval {
      local $SIG{__DIE__};
      my $d;
      require Data::Dumper;
      $d = new Data::Dumper([$_[0]], ["*var"]);
      $d->Terse(1);
      $d->Indent(2);
      $d->Quotekeys(0);
      $d->Useqq(0);
      $d = $d->Dump();
      $d =~ s/([\x00-\x07\x09\x0b\x0c\x0e-\x1f])/sprintf "\\x%02x", ord($1)/ge;
      $d;
   } || "[unable to dump $_[0]: '$@']";
}

sub KGS::User::dump {
   my ($self, $i) = @_;

   (
       (sprintf "%s (%08lx)", $self->{name}, $self->{flags}),
       1,
   )
}

sub KGS::GameRecord::dump {
   my ($self, $i) = @_;

   (
       (sprintf "komi %s size %d flags %04x", $self->komi, $self->size, $self->{flags}),
       0,
   )
}

sub dumpmsg_($$) {
   my ($indent, $val) = @_;
   $indent++;

   if (ref $val) {
      my $i = "   " x $indent;
      my $r = "$val ";

      if (my $can = UNIVERSAL::can ($val, "dump")) {
         my ($r_, $done) = $can->($val, "$i   ");
         return $r_ if $done;
         $r .= $r_;
      }

      $r .= "\n";

      if (UNIVERSAL::isa ($val, HASH::)) {
         for my $k (sort keys %$val) {
            $r .= sprintf "%s%s => %s\n", $i, $k, dumpmsg_ ($indent, $val->{$k});
         }
      } elsif (UNIVERSAL::isa ($val, ARRAY::)) {
         for (0 .. $#$val) {
            $r .= sprintf "%s%03d: %s\n", $i, $_, dumpmsg_ ($indent, $val->[$_]);
         }
      } else {
         $r .= "$i\{$val\}\n";
      }
      substr $r, 0, -1;
   } else {
      if ($val =~ /^-?[0-9]+$/) {
         sprintf "%s%s (=%x)", $i, $val, $val;
      } else {
         $val =~ s/[\x00-\x1f\x7f-\x9f]/sprintf "\x{%02x}", ord $1/ge;
         "\"$val\"";
      }
   }
}

sub dumpmsg($$) {
   my ($header, $msg) = @_;

   $msg = { %$msg };
   my $data = delete $msg->{DATA};
   my $trail = delete $msg->{TRAILING_DATA};

   "$header\: TYPE " . (delete $msg->{type}) . "\n"
   . (dumphex $data)
   . (length $trail ? "TRAILING DATA:\n" . dumphex $trail : "")
   . (dumpmsg_ 0, $msg) . "\n";
}

sub inject_any {
   my ($self, $msg) = @_;

   if (exists $msg->{channel}) {
      if ($msg->{type} eq "upd_games") {
      } elsif ($msg->{type} eq "join") {
      } elsif ($msg->{type} eq "part") {
      } elsif ($msg->{type} eq "pubmsg") {
      } elsif ($msg->{type} eq "del_game") {
      } elsif ($msg->{type} eq "upd_game") {
      } elsif ($msg->{type} eq "set_tree") {
      } elsif ($msg->{type} eq "join_room") {
      } elsif ($msg->{type} eq "part_room") {
      } elsif ($msg->{type} eq "desc_room") {
      } elsif ($msg->{type} eq "msg_room") {
      #} elsif ($msg->{type} eq "upd_tree") {
      } elsif ($msg->{type} eq "set_node") {
      } elsif ($msg->{type} eq "set_tree") {
      } elsif ($msg->{type} eq "upd_observers") {
      } elsif ($msg->{type} eq "del_observer") {
      } else {
         warn "receivedC $msg->{type} ". dumpval($msg);
      }
   } else {
      if ($msg->{type} eq "login") {
      } elsif ($msg->{type} eq "list_rooms") {
      } elsif ($msg->{type} eq "upd_rooms") {
      } elsif ($msg->{type} eq "chal_defaults") {
      } elsif ($msg->{type} eq "timewarning_default") {
      } else {
         warn "receivedG $msg->{type} ". dumpval($msg);
      }
   }
   #warn "received* $msg->{type} ". dumpval($msg);
}

1;



