#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <libgccjit.h>

#include "const-c.inc"
#include "av_to_pp.h"

MODULE = GCCJIT		PACKAGE = GCCJIT		

INCLUDE: const-xs.inc

void
gcc_jit_block_add_assignment(block, loc, lvalue, rvalue)
	gcc_jit_block *	block
	gcc_jit_location *	loc
	gcc_jit_lvalue *	lvalue
	gcc_jit_rvalue *	rvalue

void
gcc_jit_block_add_assignment_op(block, loc, lvalue, op, rvalue)
	gcc_jit_block *	block
	gcc_jit_location *	loc
	gcc_jit_lvalue *	lvalue
	enum gcc_jit_binary_op	op
	gcc_jit_rvalue *	rvalue

void
gcc_jit_block_add_comment(block, loc, text)
	gcc_jit_block *	block
	gcc_jit_location *	loc
	const char *	text

void
gcc_jit_block_add_eval(block, loc, rvalue)
	gcc_jit_block *	block
	gcc_jit_location *	loc
	gcc_jit_rvalue *	rvalue

gcc_jit_object *
gcc_jit_block_as_object(block)
	gcc_jit_block *	block

void
gcc_jit_block_end_with_conditional(block, loc, boolval, on_true, on_false)
	gcc_jit_block *	block
	gcc_jit_location *	loc
	gcc_jit_rvalue *	boolval
	gcc_jit_block *	on_true
	gcc_jit_block *	on_false

void
gcc_jit_block_end_with_jump(block, loc, target)
	gcc_jit_block *	block
	gcc_jit_location *	loc
	gcc_jit_block *	target

void
gcc_jit_block_end_with_return(block, loc, rvalue)
	gcc_jit_block *	block
	gcc_jit_location *	loc
	gcc_jit_rvalue *	rvalue

#ifdef LIBGCCJIT_HAVE_SWITCH_STATEMENTS
void
gcc_jit_block_end_with_switch(block, loc, expr, default_block, cases)
	gcc_jit_block *	block
	gcc_jit_location *	loc
	gcc_jit_rvalue *	expr
	gcc_jit_block *	default_block
	AV *	cases
PREINIT:
	AVPP_PREINIT(cases, gcc_jit_case *);
CODE:
	AVPP_CODE(cases, "gcc_jit_block_end_with_switch", gcc_jit_case *, "gcc_jit_casePtr");
	gcc_jit_block_end_with_switch(block, loc, expr, default_block, num_cases, ptr_cases);
CLEANUP:
	AVPP_CLEANUP(cases);

#endif

void
gcc_jit_block_end_with_void_return(block, loc)
	gcc_jit_block *	block
	gcc_jit_location *	loc

gcc_jit_function *
gcc_jit_block_get_function(block)
	gcc_jit_block *	block

#ifdef LIBGCCJIT_HAVE_SWITCH_STATEMENTS
gcc_jit_object *
gcc_jit_case_as_object(case_)
	gcc_jit_case *	case_

#endif

gcc_jit_context *
gcc_jit_context_acquire()

#ifdef LIBGCCJIT_HAVE_gcc_jit_context_add_command_line_option
void
gcc_jit_context_add_command_line_option(ctxt, optname)
	gcc_jit_context *	ctxt
	const char *	optname

#endif

gcc_jit_result *
gcc_jit_context_compile(ctxt)
	gcc_jit_context *	ctxt

void
gcc_jit_context_compile_to_file(ctxt, output_kind, output_path)
	gcc_jit_context *	ctxt
	enum gcc_jit_output_kind	output_kind
	const char *	output_path

void
gcc_jit_context_dump_reproducer_to_file(ctxt, path)
	gcc_jit_context *	ctxt
	const char *	path

void
gcc_jit_context_dump_to_file(ctxt, path, update_locations)
	gcc_jit_context *	ctxt
	const char *	path
	int	update_locations


=for Disable

Disabled, because out_ptr is hard to handle in XS: it is only written to when
gcc_jit_context_compile() is called, which means there is nothing to do here,
and whatever happens in gcc_jit_context_compile() wrapper must know somehow
about the out_ptr we got here. Integrated wrapper that calls both
gcc_jit_context_enable_dump() and gcc_jit_context_compile() together would be a
solution, but meh.

void
gcc_jit_context_enable_dump(ctxt, dumpname, out_ptr)
	gcc_jit_context *	ctxt
	const char *	dumpname
	char **	out_ptr

=cut

gcc_jit_function *
gcc_jit_context_get_builtin_function(ctxt, name)
	gcc_jit_context *	ctxt
	const char *	name

const char *
gcc_jit_context_get_first_error(ctxt)
	gcc_jit_context *	ctxt

gcc_jit_type *
gcc_jit_context_get_int_type(ctxt, num_bytes, is_signed)
	gcc_jit_context *	ctxt
	int	num_bytes
	int	is_signed

const char *
gcc_jit_context_get_last_error(ctxt)
	gcc_jit_context *	ctxt

gcc_jit_type *
gcc_jit_context_get_type(ctxt, type_)
	gcc_jit_context *	ctxt
	enum gcc_jit_types	type_

gcc_jit_lvalue *
gcc_jit_context_new_array_access(ctxt, loc, ptr, index)
	gcc_jit_context *	ctxt
	gcc_jit_location *	loc
	gcc_jit_rvalue *	ptr
	gcc_jit_rvalue *	index

gcc_jit_type *
gcc_jit_context_new_array_type(ctxt, loc, element_type, num_elements)
	gcc_jit_context *	ctxt
	gcc_jit_location *	loc
	gcc_jit_type *	element_type
	int	num_elements

gcc_jit_rvalue *
gcc_jit_context_new_binary_op(ctxt, loc, op, result_type, a, b)
	gcc_jit_context *	ctxt
	gcc_jit_location *	loc
	enum gcc_jit_binary_op	op
	gcc_jit_type *	result_type
	gcc_jit_rvalue *	a
	gcc_jit_rvalue *	b

gcc_jit_rvalue *
gcc_jit_context_new_call(ctxt, loc, func, args)
	gcc_jit_context *	ctxt
	gcc_jit_location *	loc
	gcc_jit_function *	func
	AV *	args
PREINIT:
	AVPP_PREINIT(args, gcc_jit_rvalue *);
CODE:
	AVPP_CODE(args, "gcc_jit_context_new_call", gcc_jit_rvalue *, "gcc_jit_rvaluePtr");
	RETVAL = gcc_jit_context_new_call(ctxt, loc, func, num_args, ptr_args);
OUTPUT:
	RETVAL
CLEANUP:
	AVPP_CLEANUP(args);

gcc_jit_rvalue *
gcc_jit_context_new_call_through_ptr(ctxt, loc, fn_ptr, args)
	gcc_jit_context *	ctxt
	gcc_jit_location *	loc
	gcc_jit_rvalue *	fn_ptr
	AV *	args
PREINIT:
	AVPP_PREINIT(args, gcc_jit_rvalue *);
CODE:
	AVPP_CODE(args, "gcc_jit_context_new_call_through_ptr", gcc_jit_rvalue *, "gcc_jit_rvaluePtr");
	RETVAL = gcc_jit_context_new_call_through_ptr(ctxt, loc, fn_ptr, num_args, ptr_args);
OUTPUT:
	RETVAL
CLEANUP:
	AVPP_CLEANUP(args);

#ifdef LIBGCCJIT_HAVE_SWITCH_STATEMENTS
gcc_jit_case *
gcc_jit_context_new_case(ctxt, min_value, max_value, dest_block)
	gcc_jit_context *	ctxt
	gcc_jit_rvalue *	min_value
	gcc_jit_rvalue *	max_value
	gcc_jit_block *	dest_block

#endif

gcc_jit_rvalue *
gcc_jit_context_new_cast(ctxt, loc, rvalue, type)
	gcc_jit_context *	ctxt
	gcc_jit_location *	loc
	gcc_jit_rvalue *	rvalue
	gcc_jit_type *	type

gcc_jit_context *
gcc_jit_context_new_child_context(parent_ctxt)
	gcc_jit_context *	parent_ctxt

gcc_jit_rvalue *
gcc_jit_context_new_comparison(ctxt, loc, op, a, b)
	gcc_jit_context *	ctxt
	gcc_jit_location *	loc
	enum gcc_jit_comparison	op
	gcc_jit_rvalue *	a
	gcc_jit_rvalue *	b

gcc_jit_field *
gcc_jit_context_new_field(ctxt, loc, type, name)
	gcc_jit_context *	ctxt
	gcc_jit_location *	loc
	gcc_jit_type *	type
	const char *	name

gcc_jit_function *
gcc_jit_context_new_function(ctxt, loc, kind, return_type, name, params, is_variadic)
	gcc_jit_context *	ctxt
	gcc_jit_location *	loc
	enum gcc_jit_function_kind	kind
	gcc_jit_type *	return_type
	const char *	name
	AV *	params
	int	is_variadic
PREINIT:
	AVPP_PREINIT(params, gcc_jit_param *);
CODE:
	AVPP_CODE(params, "gcc_jit_context_new_function", gcc_jit_param *, "gcc_jit_paramPtr");
	RETVAL = gcc_jit_context_new_function(ctxt, loc, kind, return_type, name, num_params, ptr_params, is_variadic);
OUTPUT:
	RETVAL
CLEANUP:
	AVPP_CLEANUP(params);

gcc_jit_type *
gcc_jit_context_new_function_ptr_type(ctxt, loc, return_type, param_types, is_variadic)
	gcc_jit_context *	ctxt
	gcc_jit_location *	loc
	gcc_jit_type *	return_type
	AV *	param_types
	int	is_variadic
PREINIT:
	AVPP_PREINIT(param_types, gcc_jit_type *);
CODE:
	AVPP_CODE(param_types, "gcc_jit_context_new_function_ptr_type", gcc_jit_type *, "gcc_jit_typePtr");
	RETVAL = gcc_jit_context_new_function_ptr_type(ctxt, loc, return_type, num_param_types, ptr_param_types, is_variadic);
OUTPUT:
	RETVAL
CLEANUP:
	AVPP_CLEANUP(param_types);

gcc_jit_lvalue *
gcc_jit_context_new_global(ctxt, loc, kind, type, name)
	gcc_jit_context *	ctxt
	gcc_jit_location *	loc
	enum gcc_jit_global_kind	kind
	gcc_jit_type *	type
	const char *	name

gcc_jit_location *
gcc_jit_context_new_location(ctxt, filename, line, column)
	gcc_jit_context *	ctxt
	const char *	filename
	int	line
	int	column

gcc_jit_struct *
gcc_jit_context_new_opaque_struct(ctxt, loc, name)
	gcc_jit_context *	ctxt
	gcc_jit_location *	loc
	const char *	name

gcc_jit_param *
gcc_jit_context_new_param(ctxt, loc, type, name)
	gcc_jit_context *	ctxt
	gcc_jit_location *	loc
	gcc_jit_type *	type
	const char *	name

gcc_jit_rvalue *
gcc_jit_context_new_rvalue_from_double(ctxt, numeric_type, value)
	gcc_jit_context *	ctxt
	gcc_jit_type *	numeric_type
	double	value

gcc_jit_rvalue *
gcc_jit_context_new_rvalue_from_int(ctxt, numeric_type, value)
	gcc_jit_context *	ctxt
	gcc_jit_type *	numeric_type
	int	value

gcc_jit_rvalue *
gcc_jit_context_new_rvalue_from_long(ctxt, numeric_type, value)
	gcc_jit_context *	ctxt
	gcc_jit_type *	numeric_type
	long	value

gcc_jit_rvalue *
gcc_jit_context_new_rvalue_from_ptr(ctxt, pointer_type, value)
	gcc_jit_context *	ctxt
	gcc_jit_type *	pointer_type
	void *	value

gcc_jit_rvalue *
gcc_jit_context_new_string_literal(ctxt, value)
	gcc_jit_context *	ctxt
	const char *	value

gcc_jit_struct *
gcc_jit_context_new_struct_type(ctxt, loc, name, fields)
	gcc_jit_context *	ctxt
	gcc_jit_location *	loc
	const char *	name
	AV *	fields
PREINIT:
	AVPP_PREINIT(fields, gcc_jit_field *);
CODE:
	AVPP_CODE(fields, "gcc_jit_context_new_struct_type", gcc_jit_field *, "gcc_jit_fieldPtr");
	RETVAL = gcc_jit_context_new_struct_type(ctxt, loc, name, num_fields, ptr_fields);
OUTPUT:
	RETVAL
CLEANUP:
	AVPP_CLEANUP(fields);

gcc_jit_rvalue *
gcc_jit_context_new_unary_op(ctxt, loc, op, result_type, rvalue)
	gcc_jit_context *	ctxt
	gcc_jit_location *	loc
	enum gcc_jit_unary_op	op
	gcc_jit_type *	result_type
	gcc_jit_rvalue *	rvalue

gcc_jit_type *
gcc_jit_context_new_union_type(ctxt, loc, name, fields)
	gcc_jit_context *	ctxt
	gcc_jit_location *	loc
	const char *	name
	AV *	fields
PREINIT:
	AVPP_PREINIT(fields, gcc_jit_field *);
CODE:
	AVPP_CODE(fields, "gcc_jit_context_new_union_type", gcc_jit_field *, "gcc_jit_fieldPtr");
	RETVAL = gcc_jit_context_new_union_type(ctxt, loc, name, num_fields, ptr_fields);
OUTPUT:
	RETVAL
CLEANUP:
	AVPP_CLEANUP(fields);

gcc_jit_rvalue *
gcc_jit_context_null(ctxt, pointer_type)
	gcc_jit_context *	ctxt
	gcc_jit_type *	pointer_type

gcc_jit_rvalue *
gcc_jit_context_one(ctxt, numeric_type)
	gcc_jit_context *	ctxt
	gcc_jit_type *	numeric_type

void
gcc_jit_context_release(ctxt)
	gcc_jit_context *	ctxt

#ifdef LIBGCCJIT_HAVE_gcc_jit_context_set_bool_allow_unreachable_blocks
void
gcc_jit_context_set_bool_allow_unreachable_blocks(ctxt, bool_value)
	gcc_jit_context *	ctxt
	int	bool_value

#endif

void
gcc_jit_context_set_bool_option(ctxt, opt, value)
	gcc_jit_context *	ctxt
	enum gcc_jit_bool_option	opt
	int	value

void
gcc_jit_context_set_int_option(ctxt, opt, value)
	gcc_jit_context *	ctxt
	enum gcc_jit_int_option	opt
	int	value

void
gcc_jit_context_set_logfile(ctxt, logfile, flags, verbosity)
	gcc_jit_context *	ctxt
	FILE *	logfile
	int	flags
	int	verbosity

void
gcc_jit_context_set_str_option(ctxt, opt, value)
	gcc_jit_context *	ctxt
	enum gcc_jit_str_option	opt
	const char *	value

gcc_jit_rvalue *
gcc_jit_context_zero(ctxt, numeric_type)
	gcc_jit_context *	ctxt
	gcc_jit_type *	numeric_type

gcc_jit_object *
gcc_jit_field_as_object(field)
	gcc_jit_field *	field

gcc_jit_object *
gcc_jit_function_as_object(func)
	gcc_jit_function *	func

void
gcc_jit_function_dump_to_dot(func, path)
	gcc_jit_function *	func
	const char *	path

gcc_jit_param *
gcc_jit_function_get_param(func, index)
	gcc_jit_function *	func
	int	index

gcc_jit_block *
gcc_jit_function_new_block(func, name)
	gcc_jit_function *	func
	const char *	name

gcc_jit_lvalue *
gcc_jit_function_new_local(func, loc, type, name)
	gcc_jit_function *	func
	gcc_jit_location *	loc
	gcc_jit_type *	type
	const char *	name

gcc_jit_object *
gcc_jit_location_as_object(loc)
	gcc_jit_location *	loc

gcc_jit_lvalue *
gcc_jit_lvalue_access_field(struct_or_union, loc, field)
	gcc_jit_lvalue *	struct_or_union
	gcc_jit_location *	loc
	gcc_jit_field *	field

gcc_jit_object *
gcc_jit_lvalue_as_object(lvalue)
	gcc_jit_lvalue *	lvalue

gcc_jit_rvalue *
gcc_jit_lvalue_as_rvalue(lvalue)
	gcc_jit_lvalue *	lvalue

gcc_jit_rvalue *
gcc_jit_lvalue_get_address(lvalue, loc)
	gcc_jit_lvalue *	lvalue
	gcc_jit_location *	loc

gcc_jit_context *
gcc_jit_object_get_context(obj)
	gcc_jit_object *	obj

const char *
gcc_jit_object_get_debug_string(obj)
	gcc_jit_object *	obj

gcc_jit_lvalue *
gcc_jit_param_as_lvalue(param)
	gcc_jit_param *	param

gcc_jit_object *
gcc_jit_param_as_object(param)
	gcc_jit_param *	param

gcc_jit_rvalue *
gcc_jit_param_as_rvalue(param)
	gcc_jit_param *	param

void *
gcc_jit_result_get_code(result, funcname)
	gcc_jit_result *	result
	const char *	funcname

void *
gcc_jit_result_get_global(result, name)
	gcc_jit_result *	result
	const char *	name

void
gcc_jit_result_release(result)
	gcc_jit_result *	result

gcc_jit_rvalue *
gcc_jit_rvalue_access_field(struct_or_union, loc, field)
	gcc_jit_rvalue *	struct_or_union
	gcc_jit_location *	loc
	gcc_jit_field *	field

gcc_jit_object *
gcc_jit_rvalue_as_object(rvalue)
	gcc_jit_rvalue *	rvalue

gcc_jit_lvalue *
gcc_jit_rvalue_dereference(rvalue, loc)
	gcc_jit_rvalue *	rvalue
	gcc_jit_location *	loc

gcc_jit_lvalue *
gcc_jit_rvalue_dereference_field(ptr, loc, field)
	gcc_jit_rvalue *	ptr
	gcc_jit_location *	loc
	gcc_jit_field *	field

gcc_jit_type *
gcc_jit_rvalue_get_type(rvalue)
	gcc_jit_rvalue *	rvalue

gcc_jit_type *
gcc_jit_struct_as_type(struct_type)
	gcc_jit_struct *	struct_type

void
gcc_jit_struct_set_fields(struct_type, loc, fields)
	gcc_jit_struct *	struct_type
	gcc_jit_location *	loc
	AV *	fields
PREINIT:
	AVPP_PREINIT(fields, gcc_jit_field *);
CODE:
	AVPP_CODE(fields, "gcc_jit_struct_set_fields", gcc_jit_field *, "gcc_jit_fieldPtr");
	gcc_jit_struct_set_fields(struct_type, loc, num_fields, ptr_fields);
CLEANUP:
	AVPP_CLEANUP(fields);

gcc_jit_object *
gcc_jit_type_as_object(type)
	gcc_jit_type *	type

gcc_jit_type *
gcc_jit_type_get_const(type)
	gcc_jit_type *	type

gcc_jit_type *
gcc_jit_type_get_pointer(type)
	gcc_jit_type *	type

gcc_jit_type *
gcc_jit_type_get_volatile(type)
	gcc_jit_type *	type
