# tag: test subclass for JOAP Server Class

# Copyright (c) 2003, Evan Prodromou <evan@prodromou.san-francisco.ca.us>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA

package MyPerson;
use base qw(JOAP::Server::Class);
use Error;

MyPerson->Description(<<'END_OF_DESCRIPTION');
Some basic information about a person. Tries to exercise the features
of JOAP, such as class attributes and class methods, as well as read-only
attributes.
END_OF_DESCRIPTION

MyPerson->Attributes (
    {
	given_name => {
	    type => 'string',
	    required => 1,
	    desc => 'Given name of the person.'
	},

	family_name => {
	    type => 'string',
	    required => 1,
	    desc => 'Family name of the person.'
	},

	birthdate => {
	    type => 'dateTime.iso8601',
	    required => 1,
	    desc => 'birthdate of person in GMT'
	},

	age => {
	    type => 'i4',
	    writable => 0,
	    desc => 'Age in years (rounded down) of person at current time',
	},

	sign => {
	    type => 'string',
	    writable => 0,
	    desc => 'Astrological sign of person'
	},

	species => {
	    type => 'string',
	    writable => 0,
	    allocation => 'class',
	    desc => 'species of people'
	},

	population => {
	    type => 'i4',
	    writable => 1,
	    allocation => 'class',
	    desc => 'total population of people'
	}
    });

MyPerson->Methods (
    {
	walk => {
	    returnType => 'boolean',
	    params => [
		{
		    name => 'steps',
		      type => 'i4',
		      desc => 'how many steps forward to walk, fault if less than zero'
		}
	    ],
	    desc => 'Walk forward \'steps\' steps'},

	get_family => {
	    allocation => 'class',
	    returnType => 'array',
	    params => [
		{
		    name => 'family_name',
		      type => 'string',
		      desc => 'family name to look for'
		}
	    ],
	    desc => 'Returns people in a given family (yes, <search> is better). Fault if param length less than 1.'}
    });

MyPerson->Id(['family_name', 'given_name']);

our $species = 'homo sapiens';

sub age {

    my $self = shift;
    my $bd = $self->birthdate;
    my @now = gmtime;

    my @then = JOAP->datetime_to_array($bd);

    my ($y, $m, $d) = ($then[5], $then[4], $then[3]);

    my $age = $now[5] - $y;

    if (($now[4] > $m) ||
	($now[4] == $m && $now[3] >= $d))
    {
	$age++;
    }

    return $age;
}

sub sign {
    my $self = shift;
    my $bd = $self->birthdate;

    my @time = JOAP->datetime_to_array($bd);

    my $m = $time[4] + 1;
    my $d = $time[3];

    if (($m == 12 && $d >= 21) ||
	($m == 1 && $d < 21))
    {
	return "capricorn";
    } elsif (($m == 1 && $d >= 21) ||
	($m == 2 && $d < 21))
    {
	return "aquarius";
    } elsif (($m == 2 && $d >= 21) ||
	($m == 3 && $d < 21))
    {
	return "pisces";
    } elsif (($m == 3 && $d >= 21) ||
	($m == 4 && $d < 21))
    {
	return "iforget";
    } elsif (($m == 4 && $d >= 21) ||
	($m == 5 && $d < 21))
    {
	return "gemini";
    } elsif (($m == 5 && $d >= 21) ||
	($m == 6 && $d < 21))
    {
	return "taurus";
    } elsif (($m == 6 && $d >= 21) ||
	($m == 7 && $d < 21))
    {
	return "cancer";
    } elsif (($m == 7 && $d >= 21) ||
	($m == 8 && $d < 21))
    {
	return "leo";
    } elsif (($m == 8 && $d >= 21) ||
	($m == 9 && $d < 21))
    {
	return "scorpio";
    } elsif (($m == 9 && $d >= 21) ||
	($m == 10 && $d < 21))
    {
	return "libra";
    } elsif (($m == 10 && $d >= 21) ||
	($m == 11 && $d < 21))
    {
	return "virgo";
    } elsif (($m == 11 && $d >= 21) ||
	($m == 12 && $d < 21))
    {
	return "sagittarius";
    }

    return "unknown";
}

sub walk {

    my $self = shift;
    my $steps = shift;

    if ($steps < 0) {
        throw Error::Simple("Never go back.", 5440);
    }

    for (my $i = 0; $i < $steps; $i++) {
	$self->step();
    }

    return 1;
}

sub step {
    my $self = shift;

    return 0;
}

sub get_family {
    my $self = shift;
    my $family = shift;
    my $matches = [];

    if (length($family) == 0) {
        throw Error::Simple("Family name empty", 23);
    }

    $self->_iterate(
	sub {
	    push @$matches, $_->given_name
	      if $_->family_name eq $family;
	});

    return $matches;
}

1;

