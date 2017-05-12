package LA_Base;

use strict;
use warnings;
use Super;
use Lexical::Attributes;

our @ISA = qw /Super/;

has ($.name, $.colour);
has ($.age, $.key1, $.key2) is rw;

method base_name {
    $.name;
}
method set_base_name {
    $.name = shift;
}

method base_colour {
    $.colour;
}
method set_base_colour {
    $.colour = shift;
}

method address {
    reverse $self -> SUPER::address;
}

method my_set_key2 {
    $.key2 = shift;
}

1;

__END__
