package GCC::Node::Reference;
use strict;
use base qw(GCC::Node);

sub operand {
    my $self = shift;
    my $index = shift;
    return defined($index) ? $self->{operand}[$index] : $self->{operand};
}

sub op { shift->operand(@_) }
	    
#    'r' for codes for references to storage.
# DEFTREECODE (COMPONENT_REF, "component_ref", 'r', 2)
package GCC::Node::component_ref;
use base qw(GCC::Node::Reference);

#sub op0 { shift->{'op 0'} }
#sub op1 { shift->{'op 1'} }

# DEFTREECODE (BIT_FIELD_REF, "bit_field_ref", 'r', 3)
package GCC::Node::bit_field_ref; use base qw(GCC::Node::Reference);

# DEFTREECODE (INDIRECT_REF, "indirect_ref", 'r', 1)
package GCC::Node::indirect_ref;
use base qw(GCC::Node::Reference);

#sub op0 { shift->{'op 0'} }

# DEFTREECODE (BUFFER_REF, "buffer_ref", 'r', 1)
package GCC::Node::buffer_ref; use base qw(GCC::Node::Reference);

# DEFTREECODE (ARRAY_REF, "array_ref", 'r', 2)
package GCC::Node::array_ref;
use base qw(GCC::Node::Reference);

#sub op0 { shift->{'op 0'} }

# DEFTREECODE (ARRAY_RANGE_REF, "array_range_ref", 'r', 2)
package GCC::Node::array_range_ref; use base qw(GCC::Node::Reference);

# DEFTREECODE (VTABLE_REF, "vtable_ref", 'r', 3)
package GCC::Node::vtable_ref; use base qw(GCC::Node::Reference);

# DEFTREECODE (OFFSET_REF, "offset_ref", 'r', 2)
package GCC::Node::offset_ref; use base qw(GCC::Node::Reference);

# DEFTREECODE (SCOPE_REF, "scope_ref", 'r', 2)
package GCC::Node::scope_ref; use base qw(GCC::Node::Reference);

# DEFTREECODE (MEMBER_REF, "member_ref", 'r', 2)
package GCC::Node::member_ref; use base qw(GCC::Node::Reference);

# vim:set shiftwidth=4 softtabstop=4:
1;
