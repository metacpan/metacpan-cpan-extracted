package GCC::Node::Declaration;
use strict;
use base qw(GCC::Node);
#    'd' for codes for declarations (also serving as variable refs).

# DECL_NAME
sub name { shift->{name} }

# DECL_ASSEMBLER_NAME
sub assembler_name { shift->{mngl} || '' }

# TREE_TYPE
sub type { shift->{type} }

# DECL_CONTEXT
sub context { shift->{scpe} }

# DECL_SOURCE_FILE
sub source { shift->{source} }

# DECL_ARTIFICIAL
sub artificial { shift->{artificial} }

# TREE_CHAIN
sub chain { shift->{chan} }

# DECL_LANGUAGE != lang_cplusplus
sub C { shift->{C} }

sub access { shift->{access} }
sub private { shift->{private} }
sub protected { shift->{protected} }
sub public { $_[0]->{public} || !$_[0]->{access} }

# DEFTREECODE (FUNCTION_DECL, "function_decl", 'd', 0)
package GCC::Node::function_decl;
use base qw(GCC::Node::Declaration);

# DECL_ARGUMENTS
sub args { shift->{args} }

# DECL_EXTERNAL
sub external { shift->{undefined} }

# !TREE_PUBLIC
sub static { shift->{static} }

# DECL_SAVED_TREE
sub body { shift->{body} }

# DECL_OVERLOADED_OPERATOR_P
sub operator {
    my $self = shift;
    return undef unless $self->{operator};
    if($self->conversion) {
	# return the type or something
#	my $type = $self->type->retn->var_type;
#	$type =~ s/\@//;
#	return $type;
	return "CONVERSION";
    } else {
	return $GCC::TranslationUnit::Parser::ops{ $self->{operator} };
    }
}

# DECL_FUNCTION_MEMBER_P
sub member { shift->{member} }

# DECL_PURE_VIRTUAL_P
sub pure { shift->{pure} }

# DECL_VIRTUAL_P
sub virtual { shift->{virtual} }

# DECL_CONSTRUCTOR_P
sub constructor { shift->{constructor} }

# DECL_DESTRUCTOR_P
sub destructor { shift->{destructor} }

# DECL_CONV_FN_P
sub conversion { shift->{conversion} }

# DECL_GLOBAL_CTOR_P
sub global_init { shift->{'global init'} }

# DECL_GLOBAL_DTOR_P
sub global_fini { shift->{'global fini'} }

# GLOBAL_INIT_PRIORITY
sub init_priority { shift->{prio} }

# DECL_FRIEND_PSEUDO_TEMPLATE_INSTANTIATION
sub pseudo_tmpl { shift->{'pseudo tmpl'} }

# DECL_THUNK_P
sub thunk { shift->{thunk} }

# THUNK_DELTA
sub delta { shift->{dlta} }

# THUNK_VCALL_OFFSET
sub vcall_offset { shift->{vcll} }

# DECL_INITIAL
sub fn { shift->{fn} }

# DEFTREECODE (LABEL_DECL, "label_decl", 'd', 0)
package GCC::Node::label_decl; use base qw(GCC::Node::Declaration);

# DEFTREECODE (CONST_DECL, "const_decl", 'd', 0)
package GCC::Node::const_decl;
use base qw(GCC::Node::Declaration);

# DECL_INITIAL
sub initial { shift->{cnst} }

# DEFTREECODE (TYPE_DECL, "type_decl", 'd', 0)
package GCC::Node::type_decl; use base qw(GCC::Node::Declaration);

# DEFTREECODE (VAR_DECL, "var_decl", 'd', 0)
package GCC::Node::var_decl;
use base qw(GCC::Node::Declaration);

# DECL_INITIAL
sub initial { shift->{init} }

# DECL_SIZE
sub size { shift->{size} }

# DECL_ALIGN
sub align { shift->{align} }

# TREE_USED
sub used { shift->{used} }

# DECL_REGISTER
sub register { shift->{register} }

sub access { shift->{access} || 'public' }

# TREE_STATIC && !TREE_PUBLIC
sub static { shift->{static} }

# DEFTREECODE (PARM_DECL, "parm_decl", 'd', 0)
package GCC::Node::parm_decl;
use base qw(GCC::Node::Declaration);

# DECL_ARG_TYPE
sub arg_type { shift->{argt} }

# DECL_SIZE
sub size { shift->{size} }

# DECL_ALIGN
sub align { shift->{algn} }

# TREE_USED
sub used { shift->{used} }

# DECL_REGISTER
sub register { shift->{register} }

# DEFTREECODE (RESULT_DECL, "result_decl", 'd', 0)
package GCC::Node::result_decl;
use base qw(GCC::Node::Declaration);

# DECL_INITIAL
sub initial { shift->{init} }

# DECL_SIZE
sub size { shift->{size} }

# DECL_ALIGN
sub align { shift->{algn} }

# DEFTREECODE (FIELD_DECL, "field_decl", 'd', 0)
package GCC::Node::field_decl;
use base qw(GCC::Node::Declaration);

# DECL_INITIAL
sub initial { shift->{init} }

# DECL_SIZE
sub size { shift->{size} }

# DECL_ALIGN
sub align { shift->{algn} }

# DECL_C_BIT_FIELD
sub bitfield { shift->{bitfield} }

# bit_position
sub bit_position { shift->{bpos} }

sub access { shift->{access} || 'public' }

# DECL_MUTABLE_P
sub mutable { shift->{mutable} }


# DEFTREECODE (NAMESPACE_DECL, "namespace_decl", 'd', 0)
package GCC::Node::namespace_decl;
use base qw(GCC::Node::Declaration);

# DECL_NAMESPACE_ALIAS
sub alias { shift->{alis} }

# cp_namespace_decls
sub decls { shift->{dcls} }

# DEFTREECODE (TEMPLATE_DECL, "template_decl", 'd', 0)
package GCC::Node::template_decl;
use base qw(GCC::Node::Declaration);

# DECL_TEMPLATE_RESULT
sub result { shift->{rslt} }

# DECL_TEMPLATE_INSTATIATIONS
sub instantiations { shift->{inst} }

# DECL_TEMPLATE_SPECIALIZATIONS
sub specializations { shift->{spcs} }

# DECL_TEMPLATE_PARMS
sub parms { shift->{prms} }

# DEFTREECODE (USING_DECL, "using_decl", 'd', 0)
package GCC::Node::using_decl; use base qw(GCC::Node::Declaration);

# vim:set shiftwidth=4 softtabstop=4:
1;
