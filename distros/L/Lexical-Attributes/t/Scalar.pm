package Scalar;

use strict;
use warnings;
use Lexical::Attributes;

has $.s_default;
has $.s_ro   is ro;
has $.s_pr   is pr;
has $.s_priv is priv;
has $.s_rw   is rw;

has ($.key_pr1, $.key_pr2, $.key_pr3);
has ($.key_ro1, $.key_ro2, $.key_ro3) ro;
has ($.key_rw1, $.key_rw2, $.key_rw3) is rw;
has ($.key_rw4) rw;

has ($.unused);

sub new {
    bless [] => shift;
}

sub give_status { # Class method.
   (scalar keys %unused,       #  0
    scalar keys %s_default,    #  1
    scalar keys %s_ro,         #  2
    scalar keys %s_pr,         #  3
    scalar keys %s_priv,       #  4
    scalar keys %key_pr1,      #  5
    scalar keys %key_pr2,      #  6
    scalar keys %key_pr3,      #  7
    scalar keys %key_ro1,      #  8
    scalar keys %key_ro2,      #  9
    scalar keys %key_ro3,      # 10
    scalar keys %key_rw1,      # 11
    scalar keys %key_rw2,      # 12
    scalar keys %key_rw3,      # 13
    scalar keys %key_rw4,      # 14
   );
}

#
# Setter function that arent generated.
#
method my_set_s_ro      {$.s_ro      = shift}
method my_set_s_pr      {$.s_pr      = shift}
method my_set_s_priv    {$.s_priv    = shift}
method my_set_s_default {$.s_default = shift}

#
# Getter functions that aren't generated.
#
method my_get_s_pr      {$.s_pr;}
method my_get_s_priv    {$.s_priv;}
method my_get_s_default {$.s_default;}

method loader {
    $.key_ro1 = shift if @_;
    $.key_ro2 = shift if @_;
    $.key_ro3 = shift if @_;
    $.key_pr1 = shift if @_;
    $.key_pr2 = shift if @_;
    $.key_pr3 = shift if @_;
}

method my_get_key_pr1 {$.key_pr1}
method my_get_key_pr2 {$.key_pr2}
method my_get_key_pr3 {$.key_pr3}

1;

__END__
