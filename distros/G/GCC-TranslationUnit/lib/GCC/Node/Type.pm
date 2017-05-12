package GCC::Node::Type;
use strict;
use base qw(GCC::Node);

# TYPE_QUAL_CONST
sub const { shift->{const} }

# TYPE_QUAL_VOLATILE
sub volatile { shift->{volatile} }

# TYPE_QUAL_RESTRICT
sub restrict { shift->{restrict} }

# return qualifier string
sub quals {
    my $self = shift;
    my @quals;
    push @quals, "const" if $self->const;
    push @quals, "volatile" if $self->volatile;
    push @quals, "__restrict" if $self->restrict;
    return @quals;
}

sub qual {
    my $self = shift;
    my @quals = $self->quals;
    local($") = " ";
    return "@quals";
}

# TYPE_NAME
sub name { shift->{name} }

# TYPE_MAIN_VARIANT
sub main_variant { shift->{unql} }

# TYPE_SIZE
sub size { shift->{size} }

# TYPE_ALIGN
sub align { shift->{algn} }

#    't' for a type object code.
# DEFTREECODE (VOID_TYPE, "void_type", 't', 0)	/* The void type in C */
package GCC::Node::void_type; use base qw(GCC::Node::Type);

# DEFTREECODE (INTEGER_TYPE, "integer_type", 't', 0)
package GCC::Node::integer_type;
use base qw(GCC::Node::Type);

# TYPE_PRECISION
sub precision { shift->{prec} }

# TREE_UNSIGNED
sub unsigned { shift->{unsigned} }

# MIN_VALUE
sub min { shift->{min} }

# MAX_VALUE
sub max { shift->{max} }

# DEFTREECODE (REAL_TYPE, "real_type", 't', 0)
package GCC::Node::real_type;
use base qw(GCC::Node::Type);

sub precision { shift->{prec} }

# DEFTREECODE (COMPLEX_TYPE, "complex_type", 't', 0)
package GCC::Node::complex_type; use base qw(GCC::Node::Type);

# DEFTREECODE (VECTOR_TYPE, "vector_type", 't', 0)
package GCC::Node::vector_type; use base qw(GCC::Node::Type);

# DEFTREECODE (ENUMERAL_TYPE, "enumeral_type", 't', 0)
package GCC::Node::enumeral_type;
use base qw(GCC::Node::Type);

sub code { 'enum' }

# TYPE_PRECISION
sub precision { shift->{prec} }

# TREE_UNSIGNED
sub unsigned { shift->{unsigned} }

# MIN_VALUE
sub min { shift->{min} }

# MAX_VALUE
sub max { shift->{max} }

# TYPE_VALUES
sub values { shift->{csts} }

# DEFTREECODE (BOOLEAN_TYPE, "boolean_type", 't', 0)
package GCC::Node::boolean_type; use base qw(GCC::Node::Type);

# DEFTREECODE (CHAR_TYPE, "char_type", 't', 0)
package GCC::Node::char_type; use base qw(GCC::Node::Type);

# DEFTREECODE (POINTER_TYPE, "pointer_type", 't', 0)
package GCC::Node::pointer_type;
use base qw(GCC::Node::Type);

# To allow sharing pointer_type and reference_type
sub thingy { '*' }

sub type { shift->{ptd} }

# TYPE_PTRMEM_P
sub ptrmem { shift->{ptrmem} }

# TYPE_PTRMEM_POINTED_TO_TYPE
sub ptd { shift->{ptd} }

# TYPE_PTRMEM_CLASS_TYPE
sub class { shift->{cls} }

# DEFTREECODE (OFFSET_TYPE, "offset_type", 't', 0)
package GCC::Node::offset_type; use base qw(GCC::Node::Type);

# DEFTREECODE (REFERENCE_TYPE, "reference_type", 't', 0)
package GCC::Node::reference_type;
use base qw(GCC::Node::pointer_type);

sub thingy { '&' }

sub type { shift->{refd} }

# DEFTREECODE (METHOD_TYPE, "method_type", 't', 0)
package GCC::Node::method_type;
use base qw(GCC::Node::Type);

# TYPE_METHOD_BASETYPE
sub class { shift->{clas} }

# TREE_TYPE
sub retn { shift->{retn} }

# TREE_ARG_TYPES
sub parms { shift->{prms} }

# DEFTREECODE (FILE_TYPE, "file_type", 't', 0)
package GCC::Node::file_type; use base qw(GCC::Node::Type);

# DEFTREECODE (ARRAY_TYPE, "array_type", 't', 0)
package GCC::Node::array_type;
use base qw(GCC::Node::Type);

# TREE_TYPE
sub elements { shift->{elts} }

# TYPE_DOMAIN
sub domain { shift->{domn} }

# DEFTREECODE (SET_TYPE, "set_type", 't', 0)
package GCC::Node::set_type; use base qw(GCC::Node::Type);

# DEFTREECODE (RECORD_TYPE, "record_type", 't', 0)
package GCC::Node::record_type;
use base qw(GCC::Node::Type);

# TREE_CODE
sub code { 'struct' }

# TYPE_FIELDS
sub fields { shift->{flds} }

# TYPE_METHODS
sub methods { shift->{fncs} }

# TYPE_BINFO
sub binfo { shift->{binf} }

# TYPE_PTRMEMFUNC_P
sub ptrmemfunc { shift->{ptrmem} }

# TYPE_PTRMEM_POINTED_TO_TYPE
sub ptd { shift->{ptd} }

# TYPE_PTRMEM_CLASS_TYPE
sub class { shift->{cls} }

# TYPE_VFIELD
sub vfield { shift->{vfld} }

# CLASSTYPE_TEMPLATE_SPECIALIZATION
sub specialization { shift->{spec} }

# BINFO_BASETYPE
sub base { shift->{base} }


# DEFTREECODE (UNION_TYPE, "union_type", 't', 0)	/* C union type */
package GCC::Node::union_type;
use base qw(GCC::Node::record_type);

sub code { 'union' }

# DEFTREECODE (QUAL_UNION_TYPE, "qual_union_type", 't', 0)
package GCC::Node::qual_union_type; use base qw(GCC::Node::Type);

# DEFTREECODE (FUNCTION_TYPE, "function_type", 't', 0)
package GCC::Node::function_type;
use base qw(GCC::Node::Type);

# TREE_TYPE
sub retn { shift->{retn} }

# TYPE_ARG_TYPES
sub parms { shift->{prms} }

# DEFTREECODE (LANG_TYPE, "lang_type", 't', 0)
package GCC::Node::lang_type; use base qw(GCC::Node::Type);

# DEFTREECODE (TEMPLATE_TYPE_PARM, "template_type_parm", 't', 0)
package GCC::Node::template_type_parm; use base qw(GCC::Node::Type);
# DEFTREECODE (TEMPLATE_TEMPLATE_PARM, "template_template_parm", 't', 0)
package GCC::Node::template_template_parm; use base qw(GCC::Node::Type);
# DEFTREECODE (BOUND_TEMPLATE_TEMPLATE_PARM, "bound_template_template_parm", 't', 0)
package GCC::Node::bound_template_template_parm; use base qw(GCC::Node::Type);
# DEFTREECODE (TYPENAME_TYPE, "typename_type", 't', 0)
package GCC::Node::typename_type; use base qw(GCC::Node::Type);
# DEFTREECODE (UNBOUND_CLASS_TEMPLATE, "unbound_class_template", 't', 0)
package GCC::Node::unbound_class_template; use base qw(GCC::Node::Type);
# DEFTREECODE (TYPEOF_TYPE, "typeof_type", 't', 0)
package GCC::Node::typeof_type; use base qw(GCC::Node::Type);

# vim:set shiftwidth=4 softtabstop=4:
1;
