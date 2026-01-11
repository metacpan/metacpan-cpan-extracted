# $Id: Parse.pm,v 1.3 2006-11-03 21:00:13 mike Exp $

# Parse.pm - parsing functions for Scott Adams game files.

package Games::ScottAdams::Game;
use strict;

use Games::ScottAdams::File;


sub parse {
    my $this = shift();
    my($filename) = @_;

    #warn "parsing '$filename'";
    my $fh = new Games::ScottAdams::File($filename)
	or die "can't open '$filename': $!";

    while (defined ($_ = $fh->getline(1))) {
	s/^\s+%/%/;		# Skip any whitespace before leading %
	if (/^%room (.*)/i) {
	    $this->_parse_room($fh, $1);
	} elsif (/^%exit\s+(.*)\s+(.*)/i) {
	    $this->_parse_exit($fh, $1, $2);
	} elsif (/^%item\s+(.*)/i) {
	    $this->_parse_item($fh, $1);
	} elsif (/^%getdrop\s+(.*)/i) {
	    $this->_parse_getdrop($fh, $1);
	} elsif (/^%(at|nowhere)\s*(.*)/i) {
	    $this->_parse_at($fh, $2);
	} elsif (/^%start\s+(.*)/i) {
	    $this->_parse_start($fh, $1);
	} elsif (/^%treasury\s+(.*)/i) {
	    $this->_parse_treasury($fh, $1);
	} elsif (/^%maxload\s+(.*)/i) {
	    $this->_parse_maxload($fh, $1);
	} elsif (/^%lighttime\s+(.*)/i) {
	    $this->_parse_lighttime($fh, $1);
	} elsif (/^%ident\s+(.*)/i) {
	    $this->_parse_ident($fh, $1);
	} elsif (/^%version\s+(.*)/i) {
	    $this->_parse_version($fh, $1);
	} elsif (/^%wordlen\s+(.*)/i) {
	    $this->_parse_wordlen($fh, $1);
	} elsif (/^%lightsource\s+(.*)/i) {
	    $this->_parse_lightsource($fh, $1);
	} elsif (/^%action\s+(.*)\s+(.*)/i) {
	    $this->_parse_action($fh, $1, $2);
	} elsif (/^%action\s+(.*)/i) {
	    $this->_parse_action($fh, $1, undef);
	} elsif (/^%occur\s*(.*)/i) {
	    $this->_parse_action($fh, undef, $1);
	} elsif (/^%result/i) {
	    $this->_parse_result($fh);
	} elsif (/^%comment\s+(.*)/i) {
	    $this->_parse_comment($fh, $1);
	} elsif (/^%([nv])alias\s+(.*)\s+(.*)/i) {
	    $this->_parse_alias($fh, lc($1), $2, $3);
	} elsif (/^%include\s+(.*)/i) {
	    my $newfile = $1;
	    #warn "%include '$newfile'";
	    # Interpret filenames relative to directory of current file
	    if ($filename =~ m@/@) {
		my $prefix = $filename;
		$prefix =~ s@(.*)/.*@$1@;
		$newfile = "$prefix/$newfile";
	    }
	    $this->parse($newfile);
	} elsif (!/^%/) {
	    $fh->warn("expected directive, got '$_' (ignored)");
	} else {
	    $fh->warn("unrecognised directive (ignored): '$_'");
	}
    }

    $this->_coalesce_aliases();
    return 1;
}


# PRIVATE to the parse() method
sub _parse_room {
    my $this = shift();
    my($fh, $name) = @_;

    my $desc = '';
    while (defined (my $line = $fh->getline(1))) {
	if ($line =~ /^\s*%/) {
	    $fh->ungetline($line);
	    last;
	}

	$desc .= "$line\n";
    }

    my $num = @{ $this->{rooms} }; # 0-based index of room to be added
    my $room = new Games::ScottAdams::Room($name, $desc, $num);
    push @{ $this->{rooms} }, $room;
    if (defined $this->{roomname}->{$name}) {
	$fh->warn("discarding old room '$name'");
    }

    $this->{roomname}->{$name} = $room;
    $this->{_room} = $room;
    $this->{_roomname1} = $name
	if !defined $this->{_roomname1};
}


# PRIVATE to the parse() method
sub _parse_exit {
    my $this = shift();
    my($fh, $dir, $dest) = @_;

    my $room = $this->{_room};
    if (!defined $room) {
	$fh->warn("ignoring %exit '$dir'->'$dest' before first room");
	return;
    }

    my $roomname = $room->name();
    $dir = lc(substr($dir, 0, 1));
    if ($dir !~ /^[nsewud]$/) {
	$fh->warn("ignoring %exit '$dir'->'$dest' at '$roomname'");
	return;
    }

    my $old = $room->exit($dir);
    if (defined $old) {
	$fh->warn("discarding old exit '$dir'->'$old' at '$roomname'");
    }

    $room->exit($dir, $dest);
}


# PRIVATE to the parse() method
sub _parse_item {
    my $this = shift();
    my($fh, $name) = @_;

    my $where = undef;		# item is initially nowhere
    my $room = $this->{_room};
    if (defined $room) {
	$where = $room->name();
    }

    my $desc = $fh->getline(1);
    while (defined (my $line = $fh->getline(1))) {
	if ($line =~ /^\s*%/) {
	    $fh->ungetline($line);
	    last;
	}

	$desc .= "\n$line";
    }

    my $num = @{ $this->{items} }; # 0-based index of item to be added
    if (0) {
	### No need to do this, is there?
	if ($num == 9) {
	    # Leave slot 9 free for the light-source
	    my $nothing = new Games::ScottAdams::Item('', '', $num++);
	    push @{ $this->{items} }, $nothing;
	}
    }

    my $item = new Games::ScottAdams::Item($name, $desc, $num, $where);
    push @{ $this->{items} }, $item;
    if (defined $this->{itemname}->{$name}) {
	$fh->warn("discarding old item '$name'");
    }

    $this->{itemname}->{$name} = $item;
    $this->{_item} = $item;
    if ($desc =~ /^\*/) {
	$this->{ntreasures}++;
    }
}


# PRIVATE to the parse() method
sub _parse_getdrop {
    my $this = shift();
    my($fh, $name) = @_;

    my $item = $this->{_item};
    if (!defined $item) {
	$fh->warn("ignoring %getdrop '$name' before first item");
	return;
    }

    my $itemname = $item->name();
    my $old = $item->getdrop();
    if (defined $old) {
	$fh->warn("discarding old getdrop '$old' for '$itemname'");
    }

    $item->getdrop($name);
    $this->_parse_alias($fh, 'n', $name);
}


# PRIVATE to the parse() method
sub _parse_at {
    my $this = shift();
    my($fh, $where) = @_;

    my $item = $this->{_item};
    if (!defined $item) {
	$fh->warn("ignoring %at '$where' before first item");
	return;
    }

    my $itemname = $item->name();
    my $old = $item->where();
    if (defined $old && $where ne '') {
	#$fh->warn("replacing location '$old' with '$where' for '$itemname'");
    }

    $item->where($where);
}


# All the following wrappers are PRIVATE to the parse() method
sub _parse_start {
    return _parse_param(@_, 'start', 'start room'); }
sub _parse_treasury {
    return _parse_param(@_, 'treasury', 'treasury room'); }
sub _parse_maxload {
    return _parse_param(@_, 'maxload', 'maximum load'); }
sub _parse_lighttime {
    return _parse_param(@_, 'lighttime', 'light duration'); }
sub _parse_ident {
    return _parse_param(@_, 'ident', 'adventure identifier'); }
sub _parse_version {
    return _parse_param(@_, 'version', 'version number'); }
sub _parse_wordlen {
    return _parse_param(@_, 'wordlen', 'word length'); }
sub _parse_lightsource {
    return _parse_param(@_, 'lightsource', 'light source'); }


# PRIVATE to the _parse_{start...wordlen}() methods
sub _parse_param {
    my $this = shift();
    my($fh, $value, $param, $caption) = @_;

    if (defined $this->{$param}) {
	$fh->warn("discarding old $caption '", $this->{$param}, "'");
    }

    $this->{$param} = $value;
}


# PRIVATE to the parse() method
sub _parse_action {
    my $this = shift();
    my($fh, $verb, $noun) = @_;

    my $num = @{ $this->{actions} }; # 0-based index of action to be added
    my $action = new Games::ScottAdams::Action($verb, $noun, $num);
    push @{ $this->{actions} }, $action;
    $this->{_action} = $action;

    # Register noun and verb
    $this->_parse_alias($fh, 'v', $verb) if $verb;
    $this->_parse_alias($fh, 'n', $noun) if $noun;

    while (defined (my $line = $fh->getline(1))) {
	if ($line =~ /^\s*%/) {
	    $fh->ungetline($line);
	    last;
	}
	$action->add_cond($line);
    }

    return;
}


# PRIVATE to the parse() method
sub _parse_result {
    my $this = shift();
    my($fh) = @_;

    my $action = $this->{_action};
    if (!defined $action) {
	$fh->warn("ignoring %result before first action");
	return;
    }

    while (defined (my $line = $fh->getline(1))) {
	if ($line =~ /^\s*%/) {
	    $fh->ungetline($line);
	    last;
	}
	$action->add_result($line);
    }
}


# PRIVATE to the parse() method
sub _parse_comment {
    my $this = shift();
    my($fh, $comment) = @_;

    my $action = $this->{_action};
    if (!defined $action) {
	$fh->warn("ignoring %comment before first %action");
	return;
    }

    my $old = $action->comment();
    if (defined $old) {
	$fh->warn("discarding old comment '$old'");
    }

    $action->comment($comment);
}


# PRIVATE to the parse() method
sub _parse_alias {
    my $this = shift();
    my $fh = shift();
    my $type = lc(shift());
    my @words = map { uc() } @_;

    my $href = $this->{$type . 'vocab'};
    for my $word (@words) {
	$fh->fatal("empty word") if !$word;
	push @{ $href->{$word} }, grep { $_ ne $word } @words;
    }
}


# PRIVATE to the parse() method
#
# At this point, we have a bunch of equivalence classes for each
# vocabulary set, we we need to coalesce them.  For example, if we
# have the following in the source --
#	%valias enter go
#	%valias run go
#	%valias walk go
# We'll have a {vvocab} hash that looks like this --
#	RUN -> GO
#	GO -> ENTER,RUN,WALK
#	ENTER -> GO
#	WALK -> GO
# But we want a single list of all four words

sub _coalesce_aliases {
    my $this = shift();

    $this->{vvocab} = _extend_lists($this->{vvocab});
    $this->{nvocab} = _extend_lists($this->{nvocab});
}

# PRIVATE to the _coalesce_aliases() method
sub _extend_lists {
    my($vocab) = @_;

    my @keys = keys %$vocab;	# we're going to change this
    foreach my $key (@keys) {
	#warn "considering aliases for '$key'";
	next if !exists $vocab->{$key};
	#warn "thinking about '$key'";
	my @list = _equivalents($vocab, $key, { $key => 1});
	#warn "\t" . join(' ', @list);
	foreach my $used (@list) {
	    delete $vocab->{$used};
	    #warn "deleted '$used'";
	}
	$vocab->{$key} = [ @list ];
    }

    return $vocab;
}

# PRIVATE to the _extend_lists method()
sub _equivalents {
    my($vocab, $word, $seen) = @_;

    my @equivalents;
    my $cref = $vocab->{$word};
    foreach my $candidate (@$cref) {
	next if exists $seen->{$candidate};
	$seen->{$candidate} = 1;
	my @sub = _equivalents($vocab, $candidate, $seen);
	push @equivalents, $candidate, @sub;
    }

    return @equivalents;
}


1;
