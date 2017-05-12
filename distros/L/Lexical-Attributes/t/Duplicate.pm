package Duplicate;

use strict;
use warnings;

use Lexical::Attributes;

has $.key is ro;
has $.key;
# has $.something;

sub new {
    bless [] => shift;
}

1;

__END__
