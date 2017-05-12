package GCC::Node::Comparison;
use strict;
use base qw(GCC::Node);

sub operand {
    my $self = shift;
    my $index = shift;

    return defined($index) ? $self->{operand}[$index] : $self->{operand};
}

sub op { shift->operand(@_) }

sub type { shift->{type} }

#    '<' for codes for comparison expressions.
#
# DEFTREECODE (LT_EXPR, "lt_expr", '<', 2)
package GCC::Node::lt_expr; use base qw(GCC::Node::Comparison);

# DEFTREECODE (LE_EXPR, "le_expr", '<', 2)
package GCC::Node::le_expr; use base qw(GCC::Node::Comparison);

# DEFTREECODE (GT_EXPR, "gt_expr", '<', 2)
package GCC::Node::gt_expr; use base qw(GCC::Node::Comparison);

# DEFTREECODE (GE_EXPR, "ge_expr", '<', 2)
package GCC::Node::ge_expr; use base qw(GCC::Node::Comparison);

# DEFTREECODE (EQ_EXPR, "eq_expr", '<', 2)
package GCC::Node::eq_expr; use base qw(GCC::Node::Comparison);

# DEFTREECODE (NE_EXPR, "ne_expr", '<', 2)
package GCC::Node::ne_expr; use base qw(GCC::Node::Comparison);

# DEFTREECODE (UNORDERED_EXPR, "unordered_expr", '<', 2)
package GCC::Node::unordered_expr; use base qw(GCC::Node::Comparison);

# DEFTREECODE (ORDERED_EXPR, "ordered_expr", '<', 2)
package GCC::Node::ordered_expr; use base qw(GCC::Node::Comparison);

# DEFTREECODE (UNLT_EXPR, "unlt_expr", '<', 2)
package GCC::Node::unlt_expr; use base qw(GCC::Node::Comparison);

# DEFTREECODE (UNLE_EXPR, "unle_expr", '<', 2)
package GCC::Node::unle_expr; use base qw(GCC::Node::Comparison);

# DEFTREECODE (UNGT_EXPR, "ungt_expr", '<', 2)
package GCC::Node::ungt_expr; use base qw(GCC::Node::Comparison);

# DEFTREECODE (UNGE_EXPR, "unge_expr", '<', 2)
package GCC::Node::unge_expr; use base qw(GCC::Node::Comparison);

# DEFTREECODE (UNEQ_EXPR, "uneq_expr", '<', 2)
package GCC::Node::uneq_expr; use base qw(GCC::Node::Comparison);

# DEFTREECODE (SET_LE_EXPR, "set_le_expr", '<', 2)
package GCC::Node::set_le_expr; use base qw(GCC::Node::Comparison);

# vim:set shiftwidth=4 softtabstop=4:
1;
