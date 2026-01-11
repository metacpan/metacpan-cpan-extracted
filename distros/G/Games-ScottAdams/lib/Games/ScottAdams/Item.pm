# $Id: Item.pm,v 1.1 2006-10-31 20:31:21 mike Exp $

# Item.pm - an item in a Scott Adams game.

package Games::ScottAdams::Item;
use strict;


sub new {
    my $class = shift();
    my($name, $desc, $num, $where) = @_;

    return bless {
	name => $name,
	desc => $desc,
	num => $num,		# 0-based index into Game's list of rooms
	where => $where,	# name of containing room (undef=nowhere)
	getdrop => undef,	# name for automatic get/drop (if provided)
    }, $class;
}


sub name {
    my $this = shift();
    return $this->{name};
}

sub desc {
    my $this = shift();
    return $this->{desc};
}

sub num {
    my $this = shift();
    return $this->{num};
}


sub where {
    my $this = shift();
    my($where) = @_;

    my $old = $this->{where};
    if (defined $where) {
	undef $where if $where eq '';
	$this->{where} = $where;
    }
    return $old;
}


# Allow special argument of empty string meaning nowhere
sub getdrop {
    my $this = shift();
    my($name) = @_;

    my $old = $this->{getdrop};
    if (defined $name) {
	$this->{getdrop} = $name;
    }
    return $old;
}


1;
