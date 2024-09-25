package Graph::Grammar::Rule::NoMoreVertices;

# ABSTRACT: Marker for rules where no more vertices are allowed
our $VERSION = '0.2.0'; # VERSION

use strict;
use warnings;

sub new
{
    my $class = shift;
    return bless {}, $class;
}

1;
