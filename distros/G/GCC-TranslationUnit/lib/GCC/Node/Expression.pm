package GCC::Node::Expression;
use strict;

sub type { shift->{type} }

sub operand {
    my $self = shift;
    my $index = shift;
    return defined($index) ? $self->{operand}[$index] : $self->{operand};
}

sub op { shift->operand(@_) }
#    'e' for codes for other kinds of expressions.  */
# DEFTREECODE (CONSTRUCTOR, "constructor", 'e', 2)
package GCC::Node::constructor;
use base qw(GCC::Node::Expression);

# TREE_OPERAND
sub elements { shift->{elts} }

# DEFTREECODE (COMPOUND_EXPR, "compound_expr", 'e', 2)
package GCC::Node::compound_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (MODIFY_EXPR, "modify_expr", 'e', 2)
package GCC::Node::modify_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (INIT_EXPR, "init_expr", 'e', 2)
package GCC::Node::init_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (TARGET_EXPR, "target_expr", 'e', 4)
package GCC::Node::target_expr;
use base qw(GCC::Node::Expression);

sub decl { shift->{decl} }

sub init { shift->{init} }

sub cleanup { shift->{clnp} }

# DEFTREECODE (COND_EXPR, "cond_expr", 'e', 3)
package GCC::Node::cond_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (BIND_EXPR, "bind_expr", 'e', 3)
package GCC::Node::bind_expr;
use base qw(GCC::Node::Expression);

sub vars { shift->{vars} }
sub body { shift->{body} }

# DEFTREECODE (CALL_EXPR, "call_expr", 'e', 2)
package GCC::Node::call_expr;
use base qw(GCC::Node::call_expr);

sub fn { shift->{fn} }
sub args { shift->{args} }

# DEFTREECODE (METHOD_CALL_EXPR, "method_call_expr", 'e', 4)
package GCC::Node::method_call_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (WITH_CLEANUP_EXPR, "with_cleanup_expr", 'e', 3)
package GCC::Node::with_cleanup_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (CLEANUP_POINT_EXPR, "cleanup_point_expr", 'e', 1)
package GCC::Node::cleanup_point_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (WITH_RECORD_EXPR, "with_record_expr", 'e', 2)
package GCC::Node::with_record_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (TRUTH_ANDIF_EXPR, "truth_andif_expr", 'e', 2)
package GCC::Node::truth_andif_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (TRUTH_ORIF_EXPR, "truth_orif_expr", 'e', 2)
package GCC::Node::truth_orif_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (TRUTH_AND_EXPR, "truth_and_expr", 'e', 2)
package GCC::Node::truth_and_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (TRUTH_OR_EXPR, "truth_or_expr", 'e', 2)
package GCC::Node::truth_or_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (TRUTH_XOR_EXPR, "truth_xor_expr", 'e', 2)
package GCC::Node::truth_xor_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (TRUTH_NOT_EXPR, "truth_not_expr", 'e', 1)
package GCC::Node::truth_not_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (SAVE_EXPR, "save_expr", 'e', 3)
package GCC::Node::save_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (UNSAVE_EXPR, "unsave_expr", 'e', 1)
package GCC::Node::unsave_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (RTL_EXPR, "rtl_expr", 'e', 2)
package GCC::Node::rtl_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (ADDR_EXPR, "addr_expr", 'e', 1)
package GCC::Node::addr_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (REFERENCE_EXPR, "reference_expr", 'e', 1)
package GCC::Node::reference_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (ENTRY_VALUE_EXPR, "entry_value_expr", 'e', 1)
package GCC::Node::entry_value_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (FDESC_EXPR, "fdesc_expr", 'e', 2)
package GCC::Node::fdesc_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (PREDECREMENT_EXPR, "predecrement_expr", 'e', 2)
package GCC::Node::predecrement_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (PREINCREMENT_EXPR, "preincrement_expr", 'e', 2)
package GCC::Node::preincrement_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (POSTDECREMENT_EXPR, "postdecrement_expr", 'e', 2)
package GCC::Node::postdecrement_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (POSTINCREMENT_EXPR, "postincrement_expr", 'e', 2)
package GCC::Node::postincrement_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (VA_ARG_EXPR, "va_arg_expr", 'e', 1)
package GCC::Node::va_arg_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (TRY_CATCH_EXPR, "try_catch_expr", 'e', 2)
package GCC::Node::try_catch_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (TRY_FINALLY_EXPR, "try_finally", 'e', 2)
package GCC::Node::try_finally; use base qw(GCC::Node::Expression);

# DEFTREECODE (GOTO_SUBROUTINE_EXPR, "goto_subroutine", 'e', 2)
package GCC::Node::goto_subroutine; use base qw(GCC::Node::Expression);

# DEFTREECODE (LABELED_BLOCK_EXPR, "labeled_block_expr", 'e', 2)
package GCC::Node::labeled_block_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (EXIT_BLOCK_EXPR, "exit_block_expr", 'e', 2)
package GCC::Node::exit_block_expr;
use base qw(GCC::Node::Expression);

sub cond { shift->{cond} }

# DEFTREECODE (EXPR_WITH_FILE_LOCATION, "expr_with_file_location", 'e', 3)
package GCC::Node::expr_with_file_location; use base qw(GCC::Node::Expression);

# DEFTREECODE (SWITCH_EXPR, "switch_expr", 'e', 2)
package GCC::Node::switch_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (EXC_PTR_EXPR, "exc_ptr_expr", 'e', 0)
package GCC::Node::exc_ptr_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (NEW_EXPR, "nw_expr", 'e', 3)
package GCC::Node::nw_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (VEC_NEW_EXPR, "vec_nw_expr", 'e', 3)
package GCC::Node::vec_nw_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (DELETE_EXPR, "dl_expr", 'e', 2)
package GCC::Node::dl_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (VEC_DELETE_EXPR, "vec_dl_expr", 'e', 2)
package GCC::Node::vec_dl_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (TYPE_EXPR, "type_expr", 'e', 1)
package GCC::Node::type_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (AGGR_INIT_EXPR, "aggr_init_expr", 'e', 3)
package GCC::Node::aggr_init_expr;
use base qw(GCC::Node::Expression);

sub ctor { shift->{ctor} }
sub fn { shift->{fn} }
sub args { shift->{args} }
sub decl { shift->{decl} }

# DEFTREECODE (THROW_EXPR, "throw_expr", 'e', 1)
package GCC::Node::throw_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (EMPTY_CLASS_EXPR, "empty_class_expr", 'e', 0)
package GCC::Node::empty_class_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (USING_STMT, "using_directive", 'e', 1)
package GCC::Node::using_directive;
use base qw(GCC::Node::Expression);

sub line { shift->{line} }

sub namespace { shift->{nmsp} }

sub chain { shift->{'next'} }

# DEFTREECODE (TEMPLATE_ID_EXPR, "template_id_expr", 'e', 2)
package GCC::Node::template_id_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (LOOKUP_EXPR, "lookup_expr", 'e', 1)
package GCC::Node::lookup_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (MODOP_EXPR, "modop_expr", 'e', 3)
package GCC::Node::modop_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (DOTSTAR_EXPR, "dotstar_expr", 'e', 2)
package GCC::Node::dotstar_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (TYPEID_EXPR, "typeid_expr", 'e', 1)
package GCC::Node::typeid_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (PSEUDO_DTOR_EXPR, "pseudo_dtor_expr", 'e', 3)
package GCC::Node::pseudo_dtor_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (SUBOBJECT, "subobject", 'e', 1)
package GCC::Node::subobject;
use base qw(GCC::Node::Expression);

sub line { shift->{line} }

sub cleanup { shift->{clnp} }

sub chain { shift->{'next'} }

# DEFTREECODE (CTOR_STMT, "ctor_stmt", 'e', 0)
package GCC::Node::ctor_stmt;
use base qw(GCC::Node::Expression);

sub line { shift->{line} }

sub begin { shift->{begn} }

sub end { shift->{end} }

sub chain { shift->{'next'} }

# DEFTREECODE (CTOR_INITIALIZER, "ctor_initializer", 'e', 2)
package GCC::Node::ctor_initializer; use base qw(GCC::Node::Expression);

# DEFTREECODE (RETURN_INIT, "return_init", 'e', 2)
package GCC::Node::return_init; use base qw(GCC::Node::Expression);

# DEFTREECODE (TRY_BLOCK, "try_block", 'e', 2)
package GCC::Node::try_block;
use base qw(GCC::Node::Expression);

# STMT_LINENO
sub line { shift->{line} }

# CLEANUP_P
sub cleanup { shift->{cleanup} }

# TRY_STMTS
sub body { shift->{body} }

# TRY_HANDLERS
sub handlers { shift->{hdlr} }

# TREE_CHAIN
sub chain { shift->{'next'} }

# DEFTREECODE (EH_SPEC_BLOCK, "eh_spec_block", 'e', 2)
package GCC::Node::eh_spec_block;
use base qw(GCC::Node::Expression);

# STMT_LINENO
sub line { shift->{line} }

# EH_SPEC_STMTS
sub body { shift->{body} }

# EH_SPEC_RAISES
# This violates the GCC -fdump syntax!
sub raises { shift->{raises} }

# TREE_CHAIN
sub chain { shift->{'next'} }

# DEFTREECODE (HANDLER, "handler", 'e', 2)
package GCC::Node::handler;
use base qw(GCC::Node::Expression);

sub line { shift->{line} }

# HANDLER_PARMS
sub parms { shift->{parm} }

# HANDLER_BODY
sub body { shift->{body} }

sub chain { shift->{'next'} }

# DEFTREECODE (MUST_NOT_THROW_EXPR, "must_not_throw_expr", 'e', 1)
package GCC::Node::must_not_throw_expr;
use base qw(GCC::Node::Expression);

sub line { shift->{line} }

sub body { shift->{body} }

sub chain { shift->{'next'} }

# DEFTREECODE (TAG_DEFN, "tag_defn", 'e', 0)
package GCC::Node::tag_defn; use base qw(GCC::Node::Expression);

# DEFTREECODE (IDENTITY_CONV, "identity_conv", 'e', 1)
package GCC::Node::identity_conv; use base qw(GCC::Node::Expression);

# DEFTREECODE (LVALUE_CONV, "lvalue_conv", 'e', 1)
package GCC::Node::lvalue_conv; use base qw(GCC::Node::Expression);

# DEFTREECODE (QUAL_CONV, "qual_conv", 'e', 1)
package GCC::Node::qual_conv; use base qw(GCC::Node::Expression);

# DEFTREECODE (STD_CONV, "std_conv", 'e', 1)
package GCC::Node::std_conv; use base qw(GCC::Node::Expression);

# DEFTREECODE (PTR_CONV, "ptr_conv", 'e', 1)
package GCC::Node::ptr_conv; use base qw(GCC::Node::Expression);

# DEFTREECODE (PMEM_CONV, "pmem_conv", 'e', 1)
package GCC::Node::pmem_conv; use base qw(GCC::Node::Expression);

# DEFTREECODE (BASE_CONV, "base_conv", 'e', 1)
package GCC::Node::base_conv; use base qw(GCC::Node::Expression);

# DEFTREECODE (REF_BIND, "ref_bind", 'e', 1)
package GCC::Node::ref_bind; use base qw(GCC::Node::Expression);

# DEFTREECODE (USER_CONV, "user_conv", 'e', 2)
package GCC::Node::user_conv; use base qw(GCC::Node::Expression);

# DEFTREECODE (AMBIG_CONV, "ambig_conv", 'e', 1)
package GCC::Node::ambig_conv; use base qw(GCC::Node::Expression);

# DEFTREECODE (RVALUE_CONV, "rvalue_conv", 'e', 1)
package GCC::Node::rvalue_conv; use base qw(GCC::Node::Expression);

# DEFTREECODE (ARROW_EXPR, "arrow_expr", 'e', 1)
package GCC::Node::arrow_expr; use base qw(GCC::Node::Expression);

# DEFTREECODE (EXPR_STMT, "expr_stmt", 'e', 1)
package GCC::Node::expr_stmt;
use base qw(GCC::Node::Expression);

sub line { shift->{line} }

# EXPR_STMT_EXPR
sub expr { shift->{expr} }

sub chain { shift->{'next'} }

# DEFTREECODE (COMPOUND_STMT, "compound_stmt", 'e', 1)
package GCC::Node::compound_stmt;
use base qw(GCC::Node::Expression);

sub line { shift->{line} }

# COMPOUND_BODY
sub body { shift->{body} }

sub chain { shift->{'next'} }

# DEFTREECODE (DECL_STMT, "decl_stmt", 'e', 1)
package GCC::Node::decl_stmt;
use base qw(GCC::Node::Expression);

sub line { shift->{line} }

# DECL_STMT_DECL
sub decl { shift->{decl} }

sub chain { shift->{'next'} }

# DEFTREECODE (IF_STMT, "if_stmt", 'e', 3)
package GCC::Node::if_stmt;
use base qw(GCC::Node::Expression);

sub line { shift->{line} }

# IF_COND
sub cond { shift->{cond} }

# THEN_CLAUSE
sub then_clause { shift->{'then'} }

# ELSE_CLAUSE
sub else_clause { shift->{'else'} }

sub chain { shift->{'next'} }

# DEFTREECODE (FOR_STMT, "for_stmt", 'e', 4)
package GCC::Node::for_stmt;
use base qw(GCC::Node::Expression);

sub line { shift->{line} }

# FOR_INIT_STMT
sub init { shift->{init} }

# FOR_COND
sub cond { shift->{cond} }

# FOR_EXPR
sub expr { shift->{expr} }

# FOR_BODY
sub body { shift->{body} }

sub chain { shift->{'next'} }
# DEFTREECODE (WHILE_STMT, "while_stmt", 'e', 2)
package GCC::Node::while_stmt;
use base qw(GCC::Node::Expression);

sub line { shift->{line} }

# WHILE_COND
sub cond { shift->{cond} }

# WHILE_BODY
sub body { shift->{body} }

sub chain { shift->{'next'} }

# DEFTREECODE (DO_STMT, "do_stmt", 'e', 2)
package GCC::Node::do_stmt;
use base qw(GCC::Node::Expression);

sub line { shift->{line} }

# DO_BODY
sub body { shift->{body} }

# DO_COND
sub cond { shift->{cond} }

sub chain { shift->{'next'} }

# DEFTREECODE (RETURN_STMT, "return_stmt", 'e', 1)
package GCC::Node::return_stmt;
use base qw(GCC::Node::Expression);

sub line { shift->{line} }

# RETURN_EXPR
sub expr { shift->{expr} }

sub chain { shift->{'next'} }

# DEFTREECODE (BREAK_STMT, "break_stmt", 'e', 0)
package GCC::Node::break_stmt;
use base qw(GCC::Node::Expression);

sub line { shift->{line} }

sub chain { shift->{'next'} }

# DEFTREECODE (CONTINUE_STMT, "continue_stmt", 'e', 0)
package GCC::Node::continue_stmt;
use base qw(GCC::Node::Expression);

sub line { shift->{line} }

sub chain { shift->{'next'} }

# DEFTREECODE (SWITCH_STMT, "switch_stmt", 'e', 3)
package GCC::Node::switch_stmt;
use base qw(GCC::Node::Expression);

sub line { shift->{line} }

# SWITCH_COND
sub cond { shift->{cond} }

# SWITCH_BODY
sub body { shift->{body} }

sub chain { shift->{'next'} }
# DEFTREECODE (GOTO_STMT, "goto_stmt", 'e', 1)
package GCC::Node::goto_stmt;
use base qw(GCC::Node::Expression);

sub line { shift->{line} }

# GOTO_DESTINATION
sub destination { shift->{dest} }

sub chain { shift->{'next'} }

# DEFTREECODE (LABEL_STMT, "label_stmt", 'e', 1)
package GCC::Node::label_stmt;
use base qw(GCC::Node::Expression);

sub line { shift->{line} }

# LABEL_STMT_LABEL
sub label { shift->{labl} }

sub chain { shift->{'next'} }

# DEFTREECODE (ASM_STMT, "asm_stmt", 'e', 5)
package GCC::Node::asm_stmt;
use base qw(GCC::Node::Expression);

sub line { shift->{line} }

# ASM_VOLATILE_P
sub volatile { shift->{volatile} }

# ASM_STRING
sub string { shift->{strg} }

# ASM_OUTPUTS
sub outputs { shift->{outs} }

# ASM_INPUTS
sub inputs { shift->{ins} }

# ASM_CLOBBERS
sub clobbers { shift->{clbr} }

sub chain { shift->{'next'} }
# DEFTREECODE (SCOPE_STMT, "scope_stmt", 'e', 1)
package GCC::Node::scope_stmt;
use base qw(GCC::Node::Expression);

sub line { shift->{line} }

# SCOPE_BEGIN_P
sub begin { shift->{begn} }
sub end { shift->{end} }

# SCOPE_NULLIFIED_P
sub nullified { shift->{null} }

# !SCOPE_NO_CLEANUPS_P
sub cleanups { shift->{clnp} }

sub chain { shift->{'next'} }
# DEFTREECODE (FILE_STMT, "file_stmt", 'e', 1)
package GCC::Node::file_stmt; use base qw(GCC::Node::Expression);

# DEFTREECODE (CASE_LABEL, "case_label", 'e', 3)
package GCC::Node::case_label;
use base qw(GCC::Node::Expression);

# CASE_LOW
sub low { shift->{low} }

# CASE_HIGH
sub high { shift->{high} }

sub chain { shift->{'next'} }

# DEFTREECODE (STMT_EXPR, "stmt_expr", 'e', 1)
package GCC::Node::stmt_expr;
use base qw(GCC::Node::Expression);

# STMT_EXPR_STMT
sub stmt { shift->{stmt} }

# DEFTREECODE (COMPOUND_LITERAL_EXPR, "compound_literal_expr", 'e', 1)
package GCC::Node::compound_literal_expr; use base qw(GCC::Node::Expression);
# DEFTREECODE (CLEANUP_STMT, "cleanup_stmt", 'e', 2)
package GCC::Node::cleanup_stmt;
use base qw(GCC::Node::Expression);

sub line { shift->{line} }

# CLEANUP_DECL
sub decl { shift->{decl} }

# CLEANUP_EXPR
sub expr { shift->{expr} }

sub chain { shift->{'next'} }


# vim:set shiftwidth=4 softtabstop=4:
1;
