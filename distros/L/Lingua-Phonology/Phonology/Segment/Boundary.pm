#!/usr/bin/perl

package Lingua::Phonology::Segment::Boundary;

# This class defines BOUNDARY segments, used by Linuga::Phonology::Rules. A
# Boundary segment should always return true from BOUNDARY() or
# value('BOUNDARY'), but false from everything else. Only a few tweaks are
# needed to make sure that this happens.

use strict;
use warnings;
use base 'Lingua::Phonology::Segment';

our $VERSION = 0.2;

sub new {
    bless {}, shift;
}

# Be a boundary (duh) - Segment::AUTOLOAD won't do this since there's no
# BOUNDARY feature
sub BOUNDARY {
	return 1;
}

# Don't ever be anything else
sub value_ref {
    my $self = shift;
    if ($_[0] eq 'BOUNDARY') {
        return 1 if $self->{WANT} eq 'number';
        return '+' if $self->{WANT} eq 'text';
        return \1;
    }
    return;
}

# Ignore calls to spell, but return a defined value
sub spell {
    return '';
}

# Return the truth from all_values
sub all_values {
	return (BOUNDARY => 1);
}

1;
