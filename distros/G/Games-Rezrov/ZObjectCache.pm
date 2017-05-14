package Games::Rezrov::ZObjectCache;

use strict;

use Games::Rezrov::ZObjectStatus;
use Games::Rezrov::InlinedPrivateMethod;

Games::Rezrov::InlinedPrivateMethod->new("-names" =>
					 [ qw(
					      _last_object
					      _last_index
					      _names
					      _rooms
					      _items
					      _cache
					     )],
					);
#my $code = Games::Rezrov::MagicMethod->new("-manual" => 1);
#print $$code; die;

1;
__DATA__

sub last_object {
  return $_[0]->_last_object();
}

sub new {
  my $self = [];
  bless $self, shift;
  $self->_cache([]);
  return $self;
}

sub load_names {
  my $self = shift;
  return if $self->_names();

  my $header = Games::Rezrov::StoryFile::header();
  my $max_objects = $header->max_objects();
  
  my ($o, $desc, $ref);
  my $ztext = Games::Rezrov::StoryFile::ztext();
  my (@names, %rooms, %items);

  my $i;
  my $zos;
  my (%idesc, %rdesc);
  for ($i=1; $i <= $max_objects; $i++) {
    # decode the object table
#    $o = new Games::Rezrov::ZObject($i);
    $o = $self->get($i);
    $desc = $o->print($ztext);
#    if ($$desc =~ /\s{4,}/) {
    if ($$desc =~ /\s{5,}/) {
      # several sequential whitespace characters; consider the end.
      # 3 is not enough for Lurking Horror or AMFV
      # 4 is not enough for Sorcerer
      $self->_last_object($i - 1);
#     print STDERR "DEBUG: stopping obj table detection at index $i $$desc\n";
      last;
    } else {
      if (Games::Rezrov::StoryFile::likely_location($desc)) {
	# this is named like a room but might not be.
	# examples: proper names (Suspect: "Veronica"),
	# Zork 3's "Royal Seal of Dimwit Flathead",
	# Enchanter's "Legend of the Great Implementers"
	$zos = new Games::Rezrov::ZObjectStatus($i, $self);
	if ($zos->parent_room()) {
	  # aha: this object has a parent that itself looks like a room;
	  # consider this an object instead.
	  #
	  # example, zork 2:
	  #
	  #    Room 8 (196)
	  #     Frobozz Magic Grue Repellent (22)
	  # 
	  # Grue repellent is an item, though it's named like a room.
	  #  
          $items{$i} = 1;
	  $idesc{$$desc} = $i;
        } else {
#	  printf STDERR "%d: %s\n", $i, $$desc if $$desc =~ /veronica/i;
          $rooms{$i} = 1;
	  $rdesc{$$desc} = $i;
	}
      } else {
	# it's almost certainly not a room.
	$items{$i} = 1;
	$idesc{$$desc} = $i;
      }
      $names[$i] = $desc;
#      printf STDERR "%d: %s\n", $i, $$desc;
    }
  }
  $self->_last_object($i - 1) unless $self->_last_object();

  foreach (keys %rdesc) {
    # there are cases when multiple objects with a character's name
    # appear in the object table (e.g. characters from Suspect).
    # Because these proper names look like location names we can
    # have trouble identifying them.  Here, if we have evidence that
    # such a name is really an object (it has a parent room, see above)
    # discard the "rooms" entry.
    # 
    # Critical when trying to teleport to a character's location in Suspect;
    # without this we teleport into limbo.
    delete $rooms{$rdesc{$_}} if exists $idesc{$_};
#      printf STDERR "aha: $_\n";
  }

  if (0) {
    print "Rooms:\n";
    foreach (keys %rooms) {
      printf "  %s\n", ${$names[$_]};
    }
    print "Items:\n";
    foreach (keys %items) {
      printf "  %s\n", ${$names[$_]};
    }
  }
  
  $self->_names(\@names);
  $self->_rooms(\%rooms);
  $self->_items(\%items);
}

sub print {
  # get description for a given item
  return $_[0]->_names()->[$_[1]];
}

sub get_random {
  # get the name of a random room/item
  my ($self, %options) = @_;
  my $list = $options{"-room"} ? $self->_rooms() : $self->_items();
  my @list = keys %{$list};
  my $last_index = $self->_last_index();
  my $this_index;
  while (1) {
    $this_index = int(rand(scalar @list));
    last if !(defined($last_index)) or $this_index != $last_index;
  }
  $self->_last_index($this_index);
  return $self->_names()->[$list[$this_index]];
}

sub find {
  # return object ID of an object containing specified text
  # Searches for the literal text and also regexp'ed whitespace.
  # ie "golden canary" matches "golden clockwork canary".
  my ($self, $what, %options) = @_;
  (my $what2 = $what) =~ s/\s+/.*/g;
  my $names = $self->_names();
  my %hits;
  my $desc;
  my $list;
  my $rooms = $self->_rooms();
  my $items = $self->_items();

  if ($options{"-all"}) {
    $list = { %{$rooms}, %{$items} };
  } elsif ($options{"-room"}) {
    $list = $rooms;
  } else {
    $list = $items;
  }

  foreach my $i (keys %{$list}) {
    my $d = $names->[$i];
    $desc = $$d;
    next if $desc =~ /^\d/;
    # begins with a number, ignore --
    # zork 1, #82: "2m cbroken clockwork canary"

    if ($desc =~ /$what/i or $desc =~ /$what2/i) {
      if (exists $hits{$desc}) {
	# try to resolve duplicate names; give preference to objects
	# having a parent that looks legit.  Example: "Deadline" has
	# multiple entries for Mrs. Rourke, #148 and #149.
	# #149 looks like the "real" one as she's a child of "Kitchen"
	# location while #148 is in limbo: parent description is junk
	# ("   yc ")
	my $o1 = $self->get($hits{$desc}->[0]);
	my $o2 = $self->get($i);
	my $preferred;
	foreach ($o1, $o2) {
	  my $p = $self->get($_->get_parent_id()) || next;
	  my $desc = $p->print();
	  if ($p and $$desc =~ /^[A-Z]/) {
	    $preferred = $_;
	  } else {
#	    printf STDERR "No pref for %d (%s, p=%s)\n", $_->object_id(), ${$_->print}, $$desc;
	  }
	}
	if ($preferred) {
	  $hits{$desc} = [ $preferred->object_id(), $desc ];
	}
      } else {
	$hits{$desc} = [ $i, $desc ];
      }
    }
  }

  if (scalar keys %hits > 1) {
    my (%h2, %h3);
    foreach (values %hits) {
#      my $regexp = '^$what$';
#      study $regexp;
      if ($_->[1] =~ /^$what$/i) {
        $h2{$_->[1]} = $_;
      }
      foreach my $word (split(/\s+/, $_->[1])) {
	if (lc($word) eq lc($what)) {
	  $h3{$_->[1]} = $_;
	}
      }
    }
    if (scalar keys %h2 == 1) {
      # if there's an exact match for the string, use that.
      # Example: Zork I, if user enters "forest" and we have "forest" and 
      # "forest path", assume user meant "forest".
      %hits = %h2;
    } elsif (scalar keys %h3 == 1) {
      # Give preference to exact whole-word hits.
      # Example: Infidel, "pilfer ring" should assume "jeweled ring" and
      # not even consider "glittering leaf".
      %hits = %h3;
    }
  }

  return values %hits;
}

sub get {
  # fetch the specified object
  my $cache = $_[0]->_cache();
  if (defined $cache->[$_[1]]) {
#    printf STDERR "cache hit for %s\n", $_[1];
    return $cache->[$_[1]];
  } else {
#    printf STDERR "new instance for %s\n", $_[1];
    my $zo = new Games::Rezrov::ZObject($_[1]);
    $cache->[$_[1]] = $zo;
    return $zo;
  }
}

sub get_rooms {
  my $self = shift;
  my $names = $self->_names();
  my %rooms = map {${$names->[$_]} => 1} keys %{$self->_rooms()};
  return sort keys %rooms;
}

sub get_items {
  my $self = shift;
  my $names = $self->_names();
  my %items = map {${$names->[$_]} => 1} keys %{$self->_items()};
  return sort keys %items;
}

sub is_room {
  my ($self, $id) = @_;
  my $rooms = $self->_rooms();
  if ($rooms) {
    # we've fully analyzed the object table
    return exists $rooms->{$id};
  } else {
    # guess
    if (my $zo = $self->get($id)) {
      my $desc = $zo->print();
      return Games::Rezrov::StoryFile::likely_location($desc);
    } else {
      # object 0 or other "invalid" object
      return undef;
    }
  }
}

1;
