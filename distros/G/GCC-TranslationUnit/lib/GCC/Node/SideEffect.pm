package GCC::Node::SideEffect;
use strict;
use base qw(GCC::Node);

sub code_class { 's' }

#    's' for codes for expressions with inherent side effects.
# DEFTREECODE (LABEL_EXPR, "label_expr", 's', 1)
package GCC::Node::label_expr; use base qw(GCC::Node::SideEffect);

# DEFTREECODE (GOTO_EXPR, "goto_expr", 's', 1)
package GCC::Node::goto_expr; use base qw(GCC::Node::SideEffect);

# DEFTREECODE (RETURN_EXPR, "return_expr", 's', 1)
package GCC::Node::return_expr; use base qw(GCC::Node::SideEffect);

# DEFTREECODE (EXIT_EXPR, "exit_expr", 's', 1)
package GCC::Node::exit_expr;
use base qw(GCC::Node::SideEffect);

# TREE_OPERAND
sub cond { shift->{cond} }

# DEFTREECODE (LOOP_EXPR, "loop_expr", 's', 1)
package GCC::Node::loop_expr;
use base qw(GCC::Node::SideEffect);

# TREE_OPERAND
sub body { shift->{body} }

# vim:set shiftwidth=4 softtabstop=4:
1;
