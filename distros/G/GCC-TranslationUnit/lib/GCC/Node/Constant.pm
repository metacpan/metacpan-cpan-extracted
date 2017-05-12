package GCC::Node::Constant;
#    'c' for codes for constants.
use strict;
use base qw(GCC::Node);

# All constants can apparently have types
sub type { shift->{type} }

# DEFTREECODE (INTEGER_CST, "integer_cst", 'c', 2)
package GCC::Node::integer_cst;
use base qw(GCC::Node::Constant);

# TREE_INT_CST_LOW
sub low { shift->{low} }

# TREE_INT_CST_HIGH
sub high { shift->{high} || 0 }

# DEFTREECODE (REAL_CST, "real_cst", 'c', 3)
package GCC::Node::real_cst; use base qw(GCC::Node::Constant);

# DEFTREECODE (COMPLEX_CST, "complex_cst", 'c', 3)
package GCC::Node::complex_cst; use base qw(GCC::Node::Constant);

# DEFTREECODE (VECTOR_CST, "vector_cst", 'c', 3)     
package GCC::Node::vector_cst; use base qw(GCC::Node::Constant);

# DEFTREECODE (STRING_CST, "string_cst", 'c', 3)
package GCC::Node::string_cst; use base qw(GCC::Node::Constant);

sub string { shift->{string} }

# DEFTREECODE (PTRMEM_CST, "ptrmem_cst", 'c', 2)
package GCC::Node::ptrmem_cst; use base qw(GCC::Node::Constant);

# PTRMEM_CST_CLASS
sub class { shift->{clas} }

# PTRMEM_CST_MEMBER
sub member { shift->{mbr} }

# vim:set shiftwidth=4 softtabstop=4:
1;
