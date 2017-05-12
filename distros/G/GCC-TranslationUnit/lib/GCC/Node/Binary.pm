package GCC::Node::Binary;
use strict;
use base qw(GCC::Node);

sub operand {
    my $self = shift;
    my $index = shift;
    return defined($index) ? $self->{operand}[$index] : $self->{operand};
}

sub op { shift->operand(@_) }

sub type { shift->{type} }

#    '2' for codes for binary arithmetic expressions.

# DEFTREECODE (PLUS_EXPR, "plus_expr", '2', 2)
package GCC::Node::plus_expr; use base qw(GCC::Node::Binary);

# DEFTREECODE (MINUS_EXPR, "minus_expr", '2', 2)
package GCC::Node::minus_expr; use base qw(GCC::Node::Binary);

# DEFTREECODE (MULT_EXPR, "mult_expr", '2', 2)
package GCC::Node::mult_expr; use base qw(GCC::Node::Binary);

# DEFTREECODE (TRUNC_DIV_EXPR, "trunc_div_expr", '2', 2)
package GCC::Node::trunc_div_expr; use base qw(GCC::Node::Binary);

# DEFTREECODE (CEIL_DIV_EXPR, "ceil_div_expr", '2', 2)
package GCC::Node::ceil_div_expr; use base qw(GCC::Node::Binary);

# DEFTREECODE (FLOOR_DIV_EXPR, "floor_div_expr", '2', 2)
package GCC::Node::floor_div_expr; use base qw(GCC::Node::Binary);

# DEFTREECODE (ROUND_DIV_EXPR, "round_div_expr", '2', 2)
package GCC::Node::round_div_expr; use base qw(GCC::Node::Binary);

# DEFTREECODE (TRUNC_MOD_EXPR, "trunc_mod_expr", '2', 2)
package GCC::Node::trunc_mod_expr; use base qw(GCC::Node::Binary);

# DEFTREECODE (CEIL_MOD_EXPR, "ceil_mod_expr", '2', 2)
package GCC::Node::ceil_mod_expr; use base qw(GCC::Node::Binary);

# DEFTREECODE (FLOOR_MOD_EXPR, "floor_mod_expr", '2', 2)
package GCC::Node::floor_mod_expr; use base qw(GCC::Node::Binary);

# DEFTREECODE (ROUND_MOD_EXPR, "round_mod_expr", '2', 2)
package GCC::Node::round_mod_expr; use base qw(GCC::Node::Binary);

# DEFTREECODE (RDIV_EXPR, "rdiv_expr", '2', 2)
package GCC::Node::rdiv_expr; use base qw(GCC::Node::Binary);

# DEFTREECODE (EXACT_DIV_EXPR, "exact_div_expr", '2', 2)
package GCC::Node::exact_div_expr; use base qw(GCC::Node::Binary);

# DEFTREECODE (MIN_EXPR, "min_expr", '2', 2)
package GCC::Node::min_expr; use base qw(GCC::Node::Binary);

# DEFTREECODE (MAX_EXPR, "max_expr", '2', 2)
package GCC::Node::max_expr; use base qw(GCC::Node::Binary);

# DEFTREECODE (LSHIFT_EXPR, "lshift_expr", '2', 2)
package GCC::Node::lshift_expr; use base qw(GCC::Node::Binary);

# DEFTREECODE (RSHIFT_EXPR, "rshift_expr", '2', 2)
package GCC::Node::rshift_expr; use base qw(GCC::Node::Binary);

# DEFTREECODE (LROTATE_EXPR, "lrotate_expr", '2', 2)
package GCC::Node::lrotate_expr; use base qw(GCC::Node::Binary);

# DEFTREECODE (RROTATE_EXPR, "rrotate_expr", '2', 2)
package GCC::Node::rrotate_expr; use base qw(GCC::Node::Binary);

# DEFTREECODE (BIT_IOR_EXPR, "bit_ior_expr", '2', 2)
package GCC::Node::bit_ior_expr; use base qw(GCC::Node::Binary);

# DEFTREECODE (BIT_XOR_EXPR, "bit_xor_expr", '2', 2)
package GCC::Node::bit_xor_expr; use base qw(GCC::Node::Binary);

# DEFTREECODE (BIT_AND_EXPR, "bit_and_expr", '2', 2)
package GCC::Node::bit_and_expr; use base qw(GCC::Node::Binary);

# DEFTREECODE (BIT_ANDTC_EXPR, "bit_andtc_expr", '2', 2)
package GCC::Node::bit_andtc_expr; use base qw(GCC::Node::Binary);

# DEFTREECODE (IN_EXPR, "in_expr", '2', 2)
package GCC::Node::in_expr; use base qw(GCC::Node::Binary);

# DEFTREECODE (RANGE_EXPR, "range_expr", '2', 2)
package GCC::Node::range_expr; use base qw(GCC::Node::Binary);

# DEFTREECODE (COMPLEX_EXPR, "complex_expr", '2', 2)
package GCC::Node::complex_expr; use base qw(GCC::Node::Binary);

# vim:set shiftwidth=4 softtabstop=4:
1;
