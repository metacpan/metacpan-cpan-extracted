use strict;
use warnings;

package Bad::Model::Person;

use Moose 2;
use Meerkat::Types qw/:all/;

with 'Meerkat::Role::Document';

has name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has birthday => (
    is       => 'ro',
    isa      => MeerkatDateTime,
    coerce   => 1,
    required => 1,
);

has likes => (
    is      => 'ro',
    isa     => 'Num',
    default => 0,
);

has tags => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has parents => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

has payload => ( is => 'ro' ); # no type constaint so we can experiment

sub _indexes {
    return ( [ { unique => 1 }, { name => 1 } ] );
}

1;
