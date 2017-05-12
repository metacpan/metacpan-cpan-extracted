##############################################################################
# The Faq-O-Matic is Copyright 1997 by Jon Howell, all rights reserved.      #
#                                                                            #
# This program is free software; you can redistribute it and/or              #
# modify it under the terms of the GNU General Public License                #
# as published by the Free Software Foundation; either version 2             #
# of the License, or (at your option) any later version.                     #
#                                                                            #
# This program is distributed in the hope that it will be useful,            #
# but WITHOUT ANY WARRANTY; without even the implied warranty of             #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              #
# GNU General Public License for more details.                               #
#                                                                            #
# You should have received a copy of the GNU General Public License          #
# along with this program; if not, write to the Free Software                #
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.#
#                                                                            #
# Jon Howell can be contacted at:                                            #
# 6211 Sudikoff Lab, Dartmouth College                                       #
# Hanover, NH  03755-3510                                                    #
# jonh@cs.dartmouth.edu                                                      #
#                                                                            #
# An electronic copy of the GPL is available at:                             #
# http://www.gnu.org/copyleft/gpl.html                                       #
#                                                                            #
##############################################################################

use strict;

###
### A FAQ::OMatic::Set keeps track of a nonrepeating list of strings,
### such as authors of a part. It can keep the strings in order of insertion,
### if desired.
###

package FAQ::OMatic::Set;

use FAQ::OMatic;

sub new {
	my ($class) = shift;
	my $keepOrdered = shift() || 0;

	my $set = {};
	bless $set;
	$set->{'Hash'} = {};
	$set->{'keepOrdered'} = $keepOrdered;
	if ($keepOrdered) {
		$set->{'List'} = [];
	}

	return $set;
}

# insert members of list into this set
sub insert {
	my $self = shift;

	while (scalar(@_) > 0) {
		my $arg = shift;

		# TODO debug block, delete
		if (not defined $arg) {
			my @cl = caller();
			die "caller was: <b>".join("/", @cl)."</b>";
		}

		if (not exists $self->{'Hash'}->{$arg}) {	# arg not in set yet
			$self->{'Hash'}->{$arg} = 1;
			if ($self->{'keepOrdered'}) {
				push @{$self->{'List'}}, $arg;
			}
		}
	}
}

sub remove {
	my $self = shift;

	while (scalar(@_) > 0) {
		my $arg = shift;

		if ($self->{'Hash'}->{$arg}) {
			delete $self->{'Hash'}->{$arg};
			if ($self->{'keepOrdered'}) {
				my @newList = grep {$_ ne $arg} @{$self->{'List'}};
				$self->{'List'} = \@newList;
			}
		}
	}
}

sub getList {
	my $self = shift;

	if ($self->{'keepOrdered'}) {
		return @{$self->{'List'}};
	} else {
		return sort keys %{$self->{'Hash'}};
	}
}

# return "deep copy" of myself
sub clone {
	my $self = shift;

	my $newself = new FAQ::OMatic::Set($self->{'keepOrdered'});

	$newself->{'Hash'} = { %{$self->{'Hash'}}	};

	if ($self->{'keepOrdered'}) {
		$newself->{'List'} = [ @{$self->{'List'}}	];
	}

	return $newself;
}

sub subtract {
	my $self = shift;
	my $subtrahend = shift; 		# (set whose items we remove)

	my $difference = $self->clone;
	$difference->remove($subtrahend->getList());
	return $difference;
}

1;
