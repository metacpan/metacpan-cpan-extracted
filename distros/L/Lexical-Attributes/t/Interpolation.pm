package Interpolation;

use strict;
use warnings;
use Lexical::Attributes;

has ($.scalar, @.array, %.hash) is rw;
has $.scalar2 is rw;
has $.a_index is rw;
has $.h_index is rw;
has $.regex is rw;

sub new {
    bless [] => shift;
}

method scalar_as_string {
    "This is '$.scalar'";
}
method scalar_single_quotes {
    'This is "$.scalar"';
}
method more_scalar_quotes {
   (qq {This is '$.scalar'}, qq'This is "$.scalar"', qq !This is '$.scalar'!,
    qq qThis is '$.scalar'q, qq@This is "$.scalar"@, qq ,This is '$.scalar',,
     q {This is '$.scalar'},  q'This is "$.scalar"',  q !This is '$.scalar'!,
     q qThis is '$.scalar'q,  q@This is "$.scalar"@,  q ,This is '$.scalar',,)
}
method double_interpolate {
    "This is '$.scalar' and that is '$.scalar2'";
}
method escaped {
   ("This is '$.scalar' and that is '\$.scalar2'",
    "This is '\\$.scalar' and that is '\\\$.scalar2'");
}
method with_normal_vars {
    "This is '$_[0]' and '$.scalar' as well"
}

method array_as_string {
    "This is [@.array]";
}
method array_single_quotes {
    'This is [@.array]';
}
method count_array {
    "There are $#.array elements in [@.array]"
}
method array_index {
    my $index = shift;
    "This is array element '$.array[$index]' on index '$index'";
}
method array_a_index {
    "This is '$.array[$.a_index]'"
}

method hash_as_string {
    "This is {%.hash}";
}
method hash_index {
    my $index = shift;
    "This is hash element '$.hash{$index}' on index '$index'";
}
method hash_h_index {
    "This is '$.hash{$.h_index}'"
}

method match {
    $_ [0] =~ /$.regex/;
}

1;

__END__
