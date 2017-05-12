package GCC::Node::Exceptional;
use strict;
use base qw(GCC::Node);

sub code_class { 'e' }

#    'x' for an exceptional code (fits no category).
# DEFTREECODE (ERROR_MARK, "error_mark", 'x', 0)
package GCC::Node::error_mark; use base qw(GCC::Node::Exceptional);

# DEFTREECODE (IDENTIFIER_NODE, "identifier_node", 'x', -1)
package GCC::Node::identifier_node;
use base qw(GCC::Node::Exceptional);

# IDENTIFIER_POINTER
sub identifier { shift->{string} }

# IDENTIFIER_OPNAME_P
sub operator { shift->{operator} }

# IDENTIFIER_TYPENAME_P
sub typename { shift->{tynm} }

# anonymous_namespace_name
sub unnamed { shift->{unnamed} }

# DEFTREECODE (TREE_LIST, "tree_list", 'x', 2)
package GCC::Node::tree_list;
use base qw(GCC::Node::Exceptional);

# TREE_PURPOSE
sub purpose { shift->{purp} }

# TREE_VALU
sub value { shift->{valu} }

# TREE_CHAN
sub chain { shift->{chan} }

# DEFTREECODE (TREE_VEC, "tree_vec", 'x', 2)
package GCC::Node::tree_vec;
use base qw(GCC::Node::Exceptional);

sub vector { shift->{vector} }

package GCC::Node::binfo;
use base qw(GCC::Node::Exceptional);

# TREE_VIA_PUBLIC
sub public { shift->{pub} }

# TREE_VIA_PROTECTED
sub protected { shift->{prot} }

# TREE_VIA_PRIVATE
sub private { shift->{priv} }

sub access {
    my $self = shift;
    $self->public ? "public" :
    $self->protected ? "protected" :
    $self->private ? "private" : undef;
}

# TREE_VIA_VIRTUAL
sub virtual { shift->{virt} }

# BINFO_TYPE
sub type { shift->{type} }

# BINFO_BASETYPES
sub base { shift->{base} }

# DEFTREECODE (PLACEHOLDER_EXPR, "placeholder_expr", 'x', 0)
package GCC::Node::placeholder_expr; use base qw(GCC::Node::Exceptional);

# DEFTREECODE (TEMPLATE_PARM_INDEX, "template_parm_index", 'x', 
package GCC::Node::template_parm_index; use base qw(GCC::Node::Exceptional);

# DEFTREECODE (DEFAULT_ARG, "default_arg", 'x', 2)
package GCC::Node::default_arg; use base qw(GCC::Node::Exceptional);

# DEFTREECODE (CPLUS_BINDING, "binding", 'x', 2)
package GCC::Node::binding; use base qw(GCC::Node::Exceptional);

# DEFTREECODE (OVERLOAD, "overload", 'x', 1)
package GCC::Node::overload;
use base qw(GCC::Node::Exceptional);

# OVL_CURRENT
sub current { shift->{crnt} }

# OVL_CHAIN
sub chain { shift->{chan} }

# DEFTREECODE (WRAPPER, "wrapper", 'x', 1)
package GCC::Node::wrapper; use base qw(GCC::Node::Exceptional);

# DEFTREECODE (SRCLOC, "srcloc", 'x', 2)
package GCC::Node::srcloc; use base qw(GCC::Node::Exceptional);

# vim:set shiftwidth=4 softtabstop=4:
1;
