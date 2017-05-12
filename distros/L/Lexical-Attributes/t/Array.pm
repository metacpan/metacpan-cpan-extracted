package Array;

use strict;
use warnings;
use Lexical::Attributes;

has @.a_default;
has @.a_ro   ro;
has @.a_pr   pr;
has @.a_priv priv;
has @.a_rw   rw;

has @.index     is rw;
has @.index2    is rw;
has @.reference is rw;

has @.array rw;

has ($.unused);

sub new {bless \do {my $obj} => shift}

sub give_status { # Class method.
   (scalar keys %unused,       #  0
    scalar keys %a_default,    #  1
    scalar keys %a_ro,         #  2
    scalar keys %a_pr,         #  3
    scalar keys %a_priv,       #  4
    scalar keys %a_rw,         #  5
    scalar keys %array,        #  6
    scalar keys %index,        #  7
    scalar keys %index2,       #  8
    scalar keys %reference,    #  9
   );
}

#
# Setter function that are not generated.
#
method my_set_a_ro      {@.a_ro      = @_;}
method my_set_a_pr      {@.a_pr      = @_;}
method my_set_a_priv    {@.a_priv    = @_;}
method my_set_a_default {@.a_default = @_;}

#
# Getter functions that are not generated.
#
method my_get_a_pr      {@_ ? @.a_pr      [$_ [0]] : @.a_pr;}
method my_get_a_priv    {@_ ? @.a_priv    [$_ [0]] : @.a_priv;}
method my_get_a_default {@_ ? @.a_default [$_ [0]] : @.a_default;}


#
#  Test array operations.
#
method array_by_index {
    my $index = shift;
    $.a_default [$index] = shift if @_;
    $.a_default [$index]
}

method push_array    {push    @.array => @_;}
method pop_array     {pop     @.array;}
method unshift_array {unshift @.array => @_;}
method shift_array   {shift   @.array;}
method splice_array  {
    my ($from, $len) = splice @_, 0, 2;
    splice @.array => $from, $len => @_;
}
method slice_array   {@.array [@_];}
method count_array   {$#.array;}


1;

__END__
