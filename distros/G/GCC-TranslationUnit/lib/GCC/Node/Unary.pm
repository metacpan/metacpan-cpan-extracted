package GCC::Node::Unary;
use strict;
use base qw(GCC::Node);

sub operand {
    my $self = shift;
    my $index = shift;
    return defined($index) ? $self->{operand}[$index] : $self->{operand};
}

sub op { shift->operand(@_) }
	    
sub type { shift->{type} }

#    '1' for codes for unary arithmetic expressions.
# DEFTREECODE (FIX_TRUNC_EXPR, "fix_trunc_expr", '1', 1)
package GCC::Node::fix_trunc_expr; use base qw(GCC::Node::Unary);

# DEFTREECODE (FIX_CEIL_EXPR, "fix_ceil_expr", '1', 1)
package GCC::Node::fix_ceil_expr; use base qw(GCC::Node::Unary);

# DEFTREECODE (FIX_FLOOR_EXPR, "fix_floor_expr", '1', 1)
package GCC::Node::fix_floor_expr; use base qw(GCC::Node::Unary);

# DEFTREECODE (FIX_ROUND_EXPR, "fix_round_expr", '1', 1)
package GCC::Node::fix_round_expr; use base qw(GCC::Node::Unary);

# DEFTREECODE (FLOAT_EXPR, "float_expr", '1', 1)
package GCC::Node::float_expr; use base qw(GCC::Node::Unary);

# DEFTREECODE (NEGATE_EXPR, "negate_expr", '1', 1)
package GCC::Node::negate_expr; use base qw(GCC::Node::Unary);

# DEFTREECODE (ABS_EXPR, "abs_expr", '1', 1)
package GCC::Node::abs_expr; use base qw(GCC::Node::Unary);

# DEFTREECODE (FFS_EXPR, "ffs_expr", '1', 1)
package GCC::Node::ffs_expr; use base qw(GCC::Node::Unary);

# DEFTREECODE (BIT_NOT_EXPR, "bit_not_expr", '1', 1)
package GCC::Node::bit_not_expr; use base qw(GCC::Node::Unary);

# DEFTREECODE (CARD_EXPR, "card_expr", '1', 1)
package GCC::Node::card_expr; use base qw(GCC::Node::Unary);

# DEFTREECODE (CONVERT_EXPR, "convert_expr", '1', 1)
package GCC::Node::convert_expr; use base qw(GCC::Node::Unary);

# DEFTREECODE (NOP_EXPR, "nop_expr", '1', 1)
package GCC::Node::nop_expr; use base qw(GCC::Node::Unary);

# DEFTREECODE (NON_LVALUE_EXPR, "non_lvalue_expr", '1', 1)
package GCC::Node::non_lvalue_expr; use base qw(GCC::Node::Unary);

# DEFTREECODE (VIEW_CONVERT_EXPR, "view_convert_expr", '1', 1)
package GCC::Node::view_convert_expr; use base qw(GCC::Node::Unary);

# DEFTREECODE (CONJ_EXPR, "conj_expr", '1', 1)
package GCC::Node::conj_expr; use base qw(GCC::Node::Unary);

# DEFTREECODE (REALPART_EXPR, "realpart_expr", '1', 1)
package GCC::Node::realpart_expr; use base qw(GCC::Node::Unary);

# DEFTREECODE (IMAGPART_EXPR, "imagpart_expr", '1', 1)
package GCC::Node::imagpart_expr; use base qw(GCC::Node::Unary);

# DEFTREECODE (CAST_EXPR, "cast_expr", '1', 1)
package GCC::Node::cast_expr; use base qw(GCC::Node::Unary);

# DEFTREECODE (REINTERPRET_CAST_EXPR, "reinterpret_cast_expr", '1', 1)
package GCC::Node::reinterpret_cast_expr; use base qw(GCC::Node::Unary);

# DEFTREECODE (CONST_CAST_EXPR, "const_cast_expr", '1', 1)
package GCC::Node::const_cast_expr; use base qw(GCC::Node::Unary);

# DEFTREECODE (STATIC_CAST_EXPR, "static_cast_expr", '1', 1)
package GCC::Node::static_cast_expr; use base qw(GCC::Node::Unary);

# DEFTREECODE (DYNAMIC_CAST_EXPR, "dynamic_cast_expr", '1', 1)
package GCC::Node::dynamic_cast_expr; use base qw(GCC::Node::Unary);

# DEFTREECODE (SIZEOF_EXPR, "sizeof_expr", '1', 1)
package GCC::Node::sizeof_expr; use base qw(GCC::Node::Unary);

# DEFTREECODE (ALIGNOF_EXPR, "alignof_expr", '1', 1)
package GCC::Node::alignof_expr; use base qw(GCC::Node::Unary);

# vim:set shiftwidth=4 softtabstop=4:
1;
