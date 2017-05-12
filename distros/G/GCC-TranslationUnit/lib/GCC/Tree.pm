package GCC::Tree;

# This class does nothing special except keep the internal goodies out of
# GCC::TranslationUnit
#
# For a full description of the GCC tree structure, download the GCC source;
# read gcc/doc/c-tree.texi for the detailed overview, gcc/tree.def for the
# C/Pascal tree nodes, and gcc/cp/cp-tree.def for the C++ tree nodes.
#
# I swear, it's all well commented; especially compared to MY code!
#
use GCC::Node::Exceptional;	# 'x'
use GCC::Node::Type;		# 't'
use GCC::Node::Block;		# 'b'
use GCC::Node::Constant;	# 'c'
use GCC::Node::Declaration;	# 'd'
use GCC::Node::Reference;	# 'r'
use GCC::Node::Comparison;	# '>'
use GCC::Node::Unary;		# '1'
use GCC::Node::Binary;		# '2'
use GCC::Node::SideEffect;	# 's'
use GCC::Node::Expression;	# 'e'

package GCC::Node;

sub chain {}

1;
