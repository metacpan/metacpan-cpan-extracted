package DummyClass;

use strict;
use warnings;

sub new {
    my $pkg = shift;
    my $self = bless {}, $pkg;
    return $self;
}

1;