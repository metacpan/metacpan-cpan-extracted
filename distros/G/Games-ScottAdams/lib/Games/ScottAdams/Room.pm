# $Id: Room.pm,v 1.1 2006/10/31 20:31:21 mike Exp $

# Room.pm - a room in a Scott Adams game.

package Games::ScottAdams::Room;
use strict;


sub new {
    my $class = shift();
    my($name, $desc, $num) = @_;

    return bless {
	name => $name,
	desc => $desc,
	num => $num,		# 0-based index into Game's list of rooms
	exits => {},		# room names indexed by direction
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


sub exit {
    my $this = shift();
    my($dir, $dest) = @_;

    my $res = $this->{exits}->{$dir};
    if (defined $dest) {
	$this->{exits}->{$dir} = $dest;
    }

    return $res;
}


### Only for temporary sanity-checking output in Game::compile()
#sub describe {
#    my $this = shift();
#    my($game) = @_;
#
#    print $this->{desc};
#    foreach my $dir (sort keys %{ $this->{exits} }) {
#	print "\t$dir -> ", $this->{exits}->{$dir}, "\n";
#    }
#
#    ### Sneaky looking inside the Games::ScottAdams::Item object.
#    foreach my $item (@{ $game->{items} }) {
#	if (defined $item->{where} && $item->{where} eq $this->{name}) {
#	    print "[", $item->{name}, "] ", $item->{desc};
#	    print " (", $item->{alias}, ")"
#		if defined $item->{alias};
#	    print "\n";
#	}
#    }
#}


1;
