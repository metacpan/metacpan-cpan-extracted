[![Actions Status](https://github.com/kaz-utashiro/Getopt-EX-RPN/actions/workflows/test.yml/badge.svg)](https://github.com/kaz-utashiro/Getopt-EX-RPN/actions)
# NAME

Getopt::EX::RPN - RPN calculation module for Getopt::EX command option

# SYNOPSIS

    use Getopt::EX::RPN qw(rpn_calc);

# DESCRIPTION

Getopt::EX::RPN is a wrapper for [Math::RPN](https://metacpan.org/pod/Math%3A%3ARPN) package which implement
Reverse Polish Notation calculation.  **rpn\_calc** function in this
package takes additional `HEIGHT` and `WIDTH` token which describe
terminal height and width.

**rpn\_calc** recognize following tokens (case-insensitive) and numbers,
and ignore anything else.  So you can use any other character as a
delimiter.  Delimiter is not necessary if token boundary is clear.

    HEIGHT  WIDTH
    {   }
    +,ADD  ++,INCR  -,SUB  --,DECR  *,MUL  /,DIV  %,MOD  POW  SQRT
    SIN  COS  TAN
    LOG  EXP
    ABS  INT
    &,AND  |,OR  !,NOT  XOR  ~
    <,LT  <=,LE  =,==,EQ  >,GT  >=,GE  !=,NE
    IF
    DUP  EXCH  POP
    MIN  MAX
    TIME
    RAND  LRAND

Since module [Getopt::EX::Func](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3AFunc) uses comma to separate parameters,
you can't use comma as a token separator in RPN expression.  This
package accept expression like this:

    &set(width=WIDTH:2/,height=HEIGHT:DUP:2%-2/)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
