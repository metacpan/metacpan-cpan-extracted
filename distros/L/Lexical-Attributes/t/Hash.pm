package Hash;

use strict;
use warnings;
use Lexical::Attributes;

has %.h_default;
has %.h_ro      is ro;
has %.h_pr      is pr;
has %.h_priv    is priv;
has %.h_rw      is rw;

has %.reference is rw;
has %.index     rw;
has %.index2    rw;

has (%.unused);
has %.hash   is rw;

sub new {bless \do {my $v} => shift}

sub give_status { # Class method.
   (scalar keys %unused,       #  0
    scalar keys %h_default,    #  1
    scalar keys %h_ro,         #  2
    scalar keys %h_pr,         #  3
    scalar keys %h_priv,       #  4
    scalar keys %h_rw,         #  5
    scalar keys %hash,         #  6
    scalar keys %index,        #  7
    scalar keys %index2,       #  8
    scalar keys %reference,    #  9
   );
}

#
# Setter function that are not generated.
#
method my_set_h_ro      {%.h_ro      = @_;}
method my_set_h_pr      {%.h_pr      = @_;}
method my_set_h_priv    {%.h_priv    = @_;}
method my_set_h_default {%.h_default = @_;}

#
# Getter functions that are not generated.
#
method my_get_h_pr      {@_ ? @.h_pr      {$_ [0]} : %.h_pr;}
method my_get_h_priv    {@_ ? @.h_priv    {$_ [0]} : %.h_priv;}
method my_get_h_default {@_ ? @.h_default {$_ [0]} : %.h_default;}

#
# Hash functionality
#
method hash_by_key {
    my $key = shift;
    $.hash {$key} = shift if @_;
    $.hash {$key};
}
method hash_keys   {keys   %.hash;}
method hash_values {values %.hash;}
method slice_hash  {@.hash {@_};}


1;

__END__
