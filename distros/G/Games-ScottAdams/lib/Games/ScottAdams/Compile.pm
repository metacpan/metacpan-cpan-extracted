# $Id: Compile.pm,v 1.3 2006-11-01 23:57:42 mike Exp $

# Compile.pm - back-end compilation functions for Scott Adams game files.

package Games::ScottAdams::Game;
use strict;


sub compile {
    my $this = shift();
    my $strict = $this->{-strict};

    if (0) {
	print STDERR "debugging aliases:\n";
	my $nv = $this->{nvocab};
	foreach my $word (keys %$nv) {
	    print STDERR "$word -> ", join(',', @{ $nv->{$word} }), "\n";
	}
    }

    my $lightsource = $this->{lightsource};
    if (defined $lightsource) {
	# Swap nominated item with #9 (1-based)
	# May need to pad list so we can swap with the 9th
	while (@{ $this->{items} } <= 9) {
	    push @{ $this->{items} }, new Games::ScottAdams::Item('', '', 0);
	}

	my $slot = $this->resolve_item($lightsource, 'light source');
	$this->swap_items($slot, 9);
    }

    # Compile actions before emitting header so we know the values
    # we'll need for $nactions and $nmessages.  ($nactions is NOT in
    # general the size of $this->{actions}, since that may contain big
    # actions that have to be broken across two or more actions in the
    # compiled form.)
    my $nvocab = $this->_compile_vocab();
    my(@compiled_actions, @compiled_comments);
    foreach my $action (@{ $this->{actions} }) {
	my @tmp = $action->compile($this);
	push @compiled_actions, @tmp;
	my $comment = $action->comment() || '';
	$comment =~ s/\"/\'/g;
	push @compiled_comments, $comment, map { '' } 1..(@tmp-1);
    }

    my $nitems = @{ $this->{items} } - 1;
    my $nactions = @compiled_actions - 1;
    my $nrooms = @{ $this->{rooms} } - 1;

    my $maxload = $this->{maxload};
    if (!defined $maxload) {
	_fatal("maximum load not defined") if $strict;
	$maxload = 6;		# default from Adventureland
    }

    my $start = $this->{start};
    $start = $this->{_roomname1}
	if !defined $start && !$strict;
    $start = $this->resolve_room($start, 'start');

    my $ntreasures = $this->{ntreasures};

    my $wordlen = $this->{wordlen};
    if (!defined $wordlen) {
	_fatal("word length not defined") if $strict;
	$wordlen = 3;		# default from Adventureland
    }

    my $lighttime = $this->{lighttime};
    if (!defined $lighttime) {
	_fatal("light duration not defined") if $strict;
	$lighttime = 125;	# default from Adventureland
    }

    my $nmessages = @{ $this->{messages} } - 1;

    my $treasury = $this->{treasury};
    $treasury = $this->{_roomname1}
	if !defined $treasury && !$strict;
    $treasury = $treasury eq "-" ? 255 :
	$this->resolve_room($treasury, 'treasury');

    my $ident = $this->{ident};
    if (!defined $ident) {
	_fatal("adventure identifier not defined") if $strict;
	$ident = 1;		# default from Adventureland
    }
    my $version = $this->{version};
    if (!defined $version) {
	_fatal("version number not defined") if $strict;
	$version = 416;		# default from Adventureland
    }

    # Header of 16-bit values.  How many of these should there be?
    # It's hard to say -- the documentation says there are fourteen of
    # them, and then lists only thirteen; and sample games that I've
    # looked at (e.g _Adventureland_) only seem to have twelve.  I'll
    # go with the _Adventureland_ format.  (Reading the ScottCurses.c
    # source appears to confirm this.)
    print ((76<<8)+84, "\n");	# unknown -- I'm using it as MT magic
    print $nitems, "\n";	# number of items
    print $nactions, "\n";	# number of actions
    print $nvocab-1, "\n";	# number of nouns and verbs (same length!)
    print $nrooms, "\n";	# number of rooms
    print $maxload, "\n";	# maximum a player can carry
    print $start, "\n";		# starting room
    print $ntreasures, "\n";	# total treasures (*)
    print $wordlen, "\n";	# word length
    print $lighttime, "\n";	# time light source lasts
    print $nmessages, "\n";	# number of messages
    print $treasury, "\n";	# treasure room (leave things here to score)

    # Actions.
    print "\n";
    foreach my $compiled_action (@compiled_actions) {
	print $compiled_action, "\n";
    }

    # Vocab.  Verbs and nouns interleaved (one list padded if necessary.)
    print "\n";
    for (my $i = 0; $i < $nvocab; $i++) {
	my($verb, $noun) = ($this->{verbs}->[$i], $this->{nouns}->[$i]);
	$verb = '' if !defined $verb;
	$noun = '' if !defined $noun;
	print qq["$verb"	"$noun"\n];
    }

    # Rooms.  These are represented as a sequence of six integers (the
    # numbers of the rooms reached by moving North, South, East, West,
    # Up and Down respectively) followed by a description string in
    # double quotes.
    print "\n";
    foreach my $room (@{ $this->{rooms} }) {
	foreach my $dir (qw(n s e w u d)) {
	    my $dest = $room->exit($dir);
	    my $dnum;

	    if (defined $dest) {
		$dnum = $this->resolve_room($dest, 'exit');
	    } else {
		$dnum = 0;
	    }

	    print "$dnum ";
	}

	my $desc = $room->desc();
	chomp($desc);
	$desc =~ s/\"/\'/g;
	print qq["$desc"\n];
    }

    # Messages
    print "\n";
    foreach my $msg (@{ $this->{messages} }) {
	$msg =~ s/\"/\'/g;
	print qq["$msg"\n];
    }

    # Items.  Each is a quoted description and item number.
    print "\n";
    foreach my $item (@{ $this->{items} }) {    
	my $desc = $item->desc();
	chomp($desc);
	$desc =~ s/\"/\'/g;
	my $roomname = $item->where();
	my $roomnum = !defined $roomname ? 0 :
	    $this->resolve_room($roomname, 'position');
	my $getdrop = $item->getdrop();
	if (defined $getdrop) {
	    my $canonicalisedNoun = $this->resolve_noun($getdrop)
		or die "can't canonicalise gendrop '$getdrop'";
	    $getdrop = $this->{nouns}->[$canonicalisedNoun];
	    $desc .= '/' . uc($getdrop) . '/';
	}
	print qq["$desc" $roomnum\n];
    }

    # Comments.  One per compiled action
    print "\n";
    foreach my $comment (@compiled_comments) {
	print qq["$comment"\n];
    }

    # Trailer.
    print "\n";
    print $version, "\n";	# version number
    print $ident, "\n";		# ident number
    print 0, "\n";		# unknown additional magic number
}


sub resolve_room {
    my $this = shift();
    my($roomname, $caption) = @_;

    _fatal("$caption room not defined!")
	if !defined $roomname;

    my $room = $this->{roomname}->{$roomname};
    _fatal("$caption room '$roomname' doesn't exist!")
	if !defined $room;

    return $room->num();
}


sub resolve_item {
    my $this = shift();
    my($itemname, $caption) = @_;

    _fatal("$caption item not defined!")
	if !defined $itemname;

    my $item = $this->{itemname}->{$itemname};
    _fatal("$caption item '$itemname' doesn't exist!")
	if !defined $item;

    return $item->num();
}


sub resolve_message {
    my $this = shift();
    my($msg) = @_;

    if (!defined $msg) {
	warn "ignoring empty message";
	return 0;
    }

    my $val = $this->{msgmap}->{$msg};
    if (!defined $val) {
	$val = @{ $this->{messages} };
	push @{ $this->{messages} }, $msg;
	$this->{msgmap}->{$msg} = $val;
    }

    return $val;
}


sub swap_items {
    my $this = shift();
    my($slot1, $slot2) = @_;

    my $tmpitem = $this->{items}->[$slot2];
    $this->{items}->[$slot2] = $this->{items}->[$slot1];
    $this->{items}->[$slot1] = $tmpitem;

    foreach my $slot ($slot1, $slot2) {
	# Cheeky back-door patch-up of number
	$this->{items}->[$slot]->{num} = $slot;

	# Patch up object-name resolution
	my $name = $this->{items}->[$slot]->name();
	$this->{itemname}->{$name} = $this->{items}->[$slot];
    }
}


# PRIVATE to the _compile() method.
#
sub _compile_vocab {
    my $this = shift();

    my @verbs = $this->_make_wordlist('v', ([ '<auto>', 0 ],
					    [ 'GO',     1 ],
					    [ 'GET',   10 ],
					    [ 'DROP',  18 ]));
    $this->{verbs} = \@verbs;
    my @nouns = $this->_make_wordlist('n', ([ '<any>',  0 ],
					    [ 'NORTH',  1 ],
					    [ 'SOUTH',  2 ],
					    [ 'EAST',   3 ],
					    [ 'WEST',   4 ],
					    [ 'UP',     5 ],
					    [ 'DOWN',   6 ]));
    $this->{nouns} = \@nouns;

    # Find DVN (Difference between Verbs and Nouns)
    my $dvn = @{ $this->{verbs} } - @{ $this->{nouns} };
    if ($dvn > 0) {
	push @{ $this->{nouns} }, map '', 1..$dvn;
    } elsif ($dvn < 0) {
	push @{ $this->{verbs} }, map '', 1..-$dvn;
    }

    return scalar(@ { $this->{verbs} });
}


# PRIVATE to the _compile_vocab() method.
sub _make_wordlist {
    my $this = shift();
    my($type, @specials) = @_;

    my @words;
    foreach my $ref (@specials) {
	my($word, $index) = @$ref;
	my @list = $this->_extract_synonyms($type, $word);
	$this->_insert_words($type, \@words, $index, @list);
    }

    # Add non-specials.  We could do a better job than this of fitting
    # the various-sized synonym-sets into the available slots, but
    # let's not lose sleep over it.
    my $vocab = $this->{$type . 'vocab'};
    foreach my $key (sort keys %$vocab) {
	my @list = ($key, @{ $vocab->{$key} });

	# Find first area big enough to fit all the words in
	my $index = 1;
	while (1) {
	    die "no slots lower that 1000 for '$key'" if $index == 1000;
	    my $i;
	    for ($i = 0; $i < @list; $i++) {
		last if defined $words[$index+$i];
	    }
	    last if $i == @list;
	    $index++;
	}
	#warn "found slot $index for $type '$key'";
	$this->_insert_words($type, \@words, $index, @list);
    }

    return @words;
}


# PRIVATE to the _make_wordlist() method.
sub _extract_synonyms {
    my $this = shift();
    my($type, $word) = @_;

    my $vocab = $this->{$type . 'vocab'};
    my $listref = $vocab->{$word};
    if (defined $listref) {
	# Lucky guess: it was head of its list
	delete $vocab->{$word};
	return ($word, @$listref);
    }

    # Check if its in the RHS of any of the lists.  This is a slow
    # algorithm, but that's not going to be big problem.
    foreach my $key (keys %$vocab) {
	my $listref = $vocab->{$key};
	if (grep { $_ eq $word } @$listref) {
	    delete $vocab->{$key};
	    return ($key, @$listref);
	}
    }

    # Not found at all: must be an unreferenced special
    return ($word);
}


# PRIVATE to the _make_wordlist() method.
sub _insert_words {
    my $this = shift();
    my ($type, $wordsref, $index, @list) = @_;
    
    for (my $i = 0; $i < @list; $i++) {
	my $word = $list[$i];
	die "no slot for special '$word'"
	    if defined $wordsref->[$index+$i];
	$word = '*' . $word if $i > 0;
	$wordsref->[$index+$i] = $word;
	#warn "inserted $type '$word' at " . ($index+$i);
	$this->{$type . 'map'}->{$word} = $index+$i;
    }
}


# The next pair of methods get called back from
# Games::ScottAdams::Action::compile()
sub resolve_verb {
    my $this = shift();
    return $this->_resolve_word(@_, 'verb', $this->{verbs}, $this->{vmap});
}

sub resolve_noun {
    my $this = shift();
    return $this->_resolve_word(@_, 'noun', $this->{nouns}, $this->{nmap});
}

# PRIVATE to the resolve_{verb,noun}() methods
sub _resolve_word {
    my $this = shift();
    my($word, $caption, $aref, $href) = @_;

    return 0
	if !defined $word;

    $word = uc($word);
    my $val = $href->{$word};
    if (!defined $val) {
	$val = $href->{'*' . $word};
    }

    die "impossible: $caption '$word' undefined"
	if !defined $val;

    # If we specified a synonym, revert to the type word
    while ($val > 0 && $aref->[$val] =~ /^\*/) {
	$val--;
    }

    return $val;
}


# PRIVATE to Compile.pm
sub _fatal {
    return Games::ScottAdams::File::fatal(undef, @_);
}


1;
