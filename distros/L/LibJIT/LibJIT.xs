#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <jit/jit.h>

#include "const-c.inc"
#include "jit_type-c.inc"
#include "av_to_pp.h"

MODULE = LibJIT		PACKAGE = LibJIT

INCLUDE: const-xs.inc

void *
_jit_get_frame_address(start, n)
	void *	start
	unsigned int	n

void *
_jit_get_next_frame_address(frame)
	void *	frame

void *
_jit_get_return_address(frame, frame0, return0)
	void *	frame
	void *	frame0
	void *	return0

void
jit_apply(signature, func, args, num_fixed_args, return_value)
	jit_type_t	signature
	void *	func
	void **	args
	unsigned int	num_fixed_args
	void *	return_value

void
jit_apply_raw(signature, func, args, return_value)
	jit_type_t	signature
	void *	func
	void *	args
	void *	return_value

int
jit_block_current_is_dead(func)
	jit_function_t	func

int
jit_block_ends_in_dead(block)
	jit_block_t	block

void
jit_block_free_meta(block, type)
	jit_block_t	block
	int	type

jit_block_t
jit_block_from_label(func, label)
	jit_function_t	func
	jit_label_t	label

jit_context_t
jit_block_get_context(block)
	jit_block_t	block

jit_function_t
jit_block_get_function(block)
	jit_block_t	block

jit_label_t
jit_block_get_label(block)
	jit_block_t	block

void *
jit_block_get_meta(block, type)
	jit_block_t	block
	int	type

jit_label_t
jit_block_get_next_label(block, label)
	jit_block_t	block
	jit_label_t	label

int
jit_block_is_reachable(block)
	jit_block_t	block

jit_block_t
jit_block_next(func, previous)
	jit_function_t	func
	jit_block_t	previous

jit_block_t
jit_block_previous(func, previous)
	jit_function_t	func
	jit_block_t	previous

int
jit_block_set_meta(block, type, data, free_data)
	jit_block_t	block
	int	type
	void *	data
	jit_meta_free_func	free_data

void *
jit_calloc(num, size)
	unsigned int	num
	unsigned int	size

void *
jit_closure_create(context, signature, func, user_data)
	jit_context_t	context
	jit_type_t	signature
	jit_closure_func	func
	void *	user_data

jit_float32
jit_closure_va_get_float32(va)
	jit_closure_va_list_t	va

jit_float64
jit_closure_va_get_float64(va)
	jit_closure_va_list_t	va

jit_long
jit_closure_va_get_long(va)
	jit_closure_va_list_t	va

jit_nfloat
jit_closure_va_get_nfloat(va)
	jit_closure_va_list_t	va

jit_nint
jit_closure_va_get_nint(va)
	jit_closure_va_list_t	va

jit_nuint
jit_closure_va_get_nuint(va)
	jit_closure_va_list_t	va

void *
jit_closure_va_get_ptr(va)
	jit_closure_va_list_t	va

void
jit_closure_va_get_struct(va, buf, type)
	jit_closure_va_list_t	va
	void *	buf
	jit_type_t	type

jit_ulong
jit_closure_va_get_ulong(va)
	jit_closure_va_list_t	va

int
jit_constant_convert(result, value, type, overflow_check)
	jit_constant_t *	result
	jit_constant_t *	value
	jit_type_t	type
	int	overflow_check

void
jit_context_build_end(context)
	jit_context_t	context

void
jit_context_build_start(context)
	jit_context_t	context

jit_context_t
jit_context_create()

void
jit_context_destroy(context)
	jit_context_t	context

void
jit_context_free_meta(context, type)
	jit_context_t	context
	int	type

void *
jit_context_get_meta(context, type)
	jit_context_t	context
	int	type

jit_nuint
jit_context_get_meta_numeric(context, type)
	jit_context_t	context
	int	type

void
jit_context_set_memory_manager(context, manager)
	jit_context_t	context
	jit_memory_manager_t	manager

int
jit_context_set_meta(context, type, data, free_data)
	jit_context_t	context
	int	type
	void *	data
	jit_meta_free_func	free_data

int
jit_context_set_meta_numeric(context, type, data)
	jit_context_t	context
	int	type
	jit_nuint	data

void
jit_context_set_on_demand_driver(context, driver)
	jit_context_t	context
	jit_on_demand_driver_func	driver

jit_debugger_breakpoint_id_t
jit_debugger_add_breakpoint(dbg, info)
	jit_debugger_t	dbg
	jit_debugger_breakpoint_info_t	info

void
jit_debugger_attach_self(dbg, stop_immediately)
	jit_debugger_t	dbg
	int	stop_immediately

void
jit_debugger_break(dbg)
	jit_debugger_t	dbg

jit_debugger_t
jit_debugger_create(context)
	jit_context_t	context

void
jit_debugger_destroy(dbg)
	jit_debugger_t	dbg

void
jit_debugger_detach_self(dbg)
	jit_debugger_t	dbg

void
jit_debugger_finish(dbg, thread)
	jit_debugger_t	dbg
	jit_debugger_thread_id_t	thread

jit_debugger_t
jit_debugger_from_context(context)
	jit_context_t	context

jit_context_t
jit_debugger_get_context(dbg)
	jit_debugger_t	dbg

int
jit_debugger_get_native_thread(dbg, thread, native_thread)
	jit_debugger_t	dbg
	jit_debugger_thread_id_t	thread
	void *	native_thread

jit_debugger_thread_id_t
jit_debugger_get_self(dbg)
	jit_debugger_t	dbg

jit_debugger_thread_id_t
jit_debugger_get_thread(dbg, native_thread)
	jit_debugger_t	dbg
	void *	native_thread

int
jit_debugger_is_alive(dbg, thread)
	jit_debugger_t	dbg
	jit_debugger_thread_id_t	thread

int
jit_debugger_is_running(dbg, thread)
	jit_debugger_t	dbg
	jit_debugger_thread_id_t	thread

void
jit_debugger_next(dbg, thread)
	jit_debugger_t	dbg
	jit_debugger_thread_id_t	thread

void
jit_debugger_quit(dbg)
	jit_debugger_t	dbg

void
jit_debugger_remove_all_breakpoints(dbg)
	jit_debugger_t	dbg

void
jit_debugger_remove_breakpoint(dbg, id)
	jit_debugger_t	dbg
	jit_debugger_breakpoint_id_t	id

void
jit_debugger_run(dbg, thread)
	jit_debugger_t	dbg
	jit_debugger_thread_id_t	thread

void
jit_debugger_set_breakable(dbg, native_thread, flag)
	jit_debugger_t	dbg
	void *	native_thread
	int	flag

jit_debugger_hook_func
jit_debugger_set_hook(context, hook)
	jit_context_t	context
	jit_debugger_hook_func	hook

void
jit_debugger_step(dbg, thread)
	jit_debugger_t	dbg
	jit_debugger_thread_id_t	thread

int
jit_debugger_wait_event(dbg, event, timeout)
	jit_debugger_t	dbg
	jit_debugger_event_t *	event
	jit_int	timeout

int
jit_debugging_possible()

jit_memory_manager_t
jit_default_memory_manager()

void
jit_exception_builtin(exception_type)
	int	exception_type

void
jit_exception_clear_last()

jit_exception_func
jit_exception_get_handler()

void *
jit_exception_get_last()

void *
jit_exception_get_last_and_clear()

jit_stack_trace_t
jit_exception_get_stack_trace()

jit_exception_func
jit_exception_set_handler(handler)
	jit_exception_func	handler

void
jit_exception_set_last(object)
	void *	object

void
jit_exception_throw(object)
	void *	object

jit_float32
jit_float32_abs(value1)
	jit_float32	value1

jit_float32
jit_float32_acos(value1)
	jit_float32	value1

jit_float32
jit_float32_add(value1, value2)
	jit_float32	value1
	jit_float32	value2

jit_float32
jit_float32_asin(value1)
	jit_float32	value1

jit_float32
jit_float32_atan(value1)
	jit_float32	value1

jit_float32
jit_float32_atan2(value1, value2)
	jit_float32	value1
	jit_float32	value2

jit_float32
jit_float32_ceil(value1)
	jit_float32	value1

jit_int
jit_float32_cmpg(value1, value2)
	jit_float32	value1
	jit_float32	value2

jit_int
jit_float32_cmpl(value1, value2)
	jit_float32	value1
	jit_float32	value2

jit_float32
jit_float32_cos(value1)
	jit_float32	value1

jit_float32
jit_float32_cosh(value1)
	jit_float32	value1

jit_float32
jit_float32_div(value1, value2)
	jit_float32	value1
	jit_float32	value2

jit_int
jit_float32_eq(value1, value2)
	jit_float32	value1
	jit_float32	value2

jit_float32
jit_float32_exp(value1)
	jit_float32	value1

jit_float32
jit_float32_floor(value1)
	jit_float32	value1

jit_int
jit_float32_ge(value1, value2)
	jit_float32	value1
	jit_float32	value2

jit_int
jit_float32_gt(value1, value2)
	jit_float32	value1
	jit_float32	value2

jit_float32
jit_float32_ieee_rem(value1, value2)
	jit_float32	value1
	jit_float32	value2

jit_int
jit_float32_is_finite(value)
	jit_float32	value

jit_int
jit_float32_is_inf(value)
	jit_float32	value

jit_int
jit_float32_is_nan(value)
	jit_float32	value

jit_int
jit_float32_le(value1, value2)
	jit_float32	value1
	jit_float32	value2

jit_float32
jit_float32_log(value1)
	jit_float32	value1

jit_float32
jit_float32_log10(value1)
	jit_float32	value1

jit_int
jit_float32_lt(value1, value2)
	jit_float32	value1
	jit_float32	value2

jit_float32
jit_float32_max(value1, value2)
	jit_float32	value1
	jit_float32	value2

jit_float32
jit_float32_min(value1, value2)
	jit_float32	value1
	jit_float32	value2

jit_float32
jit_float32_mul(value1, value2)
	jit_float32	value1
	jit_float32	value2

jit_int
jit_float32_ne(value1, value2)
	jit_float32	value1
	jit_float32	value2

jit_float32
jit_float32_neg(value1)
	jit_float32	value1

jit_float32
jit_float32_pow(value1, value2)
	jit_float32	value1
	jit_float32	value2

jit_float32
jit_float32_rem(value1, value2)
	jit_float32	value1
	jit_float32	value2

jit_float32
jit_float32_rint(value1)
	jit_float32	value1

jit_float32
jit_float32_round(value1)
	jit_float32	value1

jit_int
jit_float32_sign(value1)
	jit_float32	value1

jit_float32
jit_float32_sin(value1)
	jit_float32	value1

jit_float32
jit_float32_sinh(value1)
	jit_float32	value1

jit_float32
jit_float32_sqrt(value1)
	jit_float32	value1

jit_float32
jit_float32_sub(value1, value2)
	jit_float32	value1
	jit_float32	value2

jit_float32
jit_float32_tan(value1)
	jit_float32	value1

jit_float32
jit_float32_tanh(value1)
	jit_float32	value1

jit_float64
jit_float32_to_float64(value)
	jit_float32	value

jit_int
jit_float32_to_int(value)
	jit_float32	value

jit_int
jit_float32_to_int_ovf(result, value)
	jit_int *	result
	jit_float32	value

jit_long
jit_float32_to_long(value)
	jit_float32	value

jit_int
jit_float32_to_long_ovf(result, value)
	jit_long *	result
	jit_float32	value

jit_nfloat
jit_float32_to_nfloat(value)
	jit_float32	value

jit_uint
jit_float32_to_uint(value)
	jit_float32	value

jit_int
jit_float32_to_uint_ovf(result, value)
	jit_uint *	result
	jit_float32	value

jit_ulong
jit_float32_to_ulong(value)
	jit_float32	value

jit_int
jit_float32_to_ulong_ovf(result, value)
	jit_ulong *	result
	jit_float32	value

jit_float32
jit_float32_trunc(value1)
	jit_float32	value1

jit_float64
jit_float64_abs(value1)
	jit_float64	value1

jit_float64
jit_float64_acos(value1)
	jit_float64	value1

jit_float64
jit_float64_add(value1, value2)
	jit_float64	value1
	jit_float64	value2

jit_float64
jit_float64_asin(value1)
	jit_float64	value1

jit_float64
jit_float64_atan(value1)
	jit_float64	value1

jit_float64
jit_float64_atan2(value1, value2)
	jit_float64	value1
	jit_float64	value2

jit_float64
jit_float64_ceil(value1)
	jit_float64	value1

jit_int
jit_float64_cmpg(value1, value2)
	jit_float64	value1
	jit_float64	value2

jit_int
jit_float64_cmpl(value1, value2)
	jit_float64	value1
	jit_float64	value2

jit_float64
jit_float64_cos(value1)
	jit_float64	value1

jit_float64
jit_float64_cosh(value1)
	jit_float64	value1

jit_float64
jit_float64_div(value1, value2)
	jit_float64	value1
	jit_float64	value2

jit_int
jit_float64_eq(value1, value2)
	jit_float64	value1
	jit_float64	value2

jit_float64
jit_float64_exp(value1)
	jit_float64	value1

jit_float64
jit_float64_floor(value1)
	jit_float64	value1

jit_int
jit_float64_ge(value1, value2)
	jit_float64	value1
	jit_float64	value2

jit_int
jit_float64_gt(value1, value2)
	jit_float64	value1
	jit_float64	value2

jit_float64
jit_float64_ieee_rem(value1, value2)
	jit_float64	value1
	jit_float64	value2

jit_int
jit_float64_is_finite(value)
	jit_float64	value

jit_int
jit_float64_is_inf(value)
	jit_float64	value

jit_int
jit_float64_is_nan(value)
	jit_float64	value

jit_int
jit_float64_le(value1, value2)
	jit_float64	value1
	jit_float64	value2

jit_float64
jit_float64_log(value1)
	jit_float64	value1

jit_float64
jit_float64_log10(value1)
	jit_float64	value1

jit_int
jit_float64_lt(value1, value2)
	jit_float64	value1
	jit_float64	value2

jit_float64
jit_float64_max(value1, value2)
	jit_float64	value1
	jit_float64	value2

jit_float64
jit_float64_min(value1, value2)
	jit_float64	value1
	jit_float64	value2

jit_float64
jit_float64_mul(value1, value2)
	jit_float64	value1
	jit_float64	value2

jit_int
jit_float64_ne(value1, value2)
	jit_float64	value1
	jit_float64	value2

jit_float64
jit_float64_neg(value1)
	jit_float64	value1

jit_float64
jit_float64_pow(value1, value2)
	jit_float64	value1
	jit_float64	value2

jit_float64
jit_float64_rem(value1, value2)
	jit_float64	value1
	jit_float64	value2

jit_float64
jit_float64_rint(value1)
	jit_float64	value1

jit_float64
jit_float64_round(value1)
	jit_float64	value1

jit_int
jit_float64_sign(value1)
	jit_float64	value1

jit_float64
jit_float64_sin(value1)
	jit_float64	value1

jit_float64
jit_float64_sinh(value1)
	jit_float64	value1

jit_float64
jit_float64_sqrt(value1)
	jit_float64	value1

jit_float64
jit_float64_sub(value1, value2)
	jit_float64	value1
	jit_float64	value2

jit_float64
jit_float64_tan(value1)
	jit_float64	value1

jit_float64
jit_float64_tanh(value1)
	jit_float64	value1

jit_float32
jit_float64_to_float32(value)
	jit_float64	value

jit_int
jit_float64_to_int(value)
	jit_float64	value

jit_int
jit_float64_to_int_ovf(result, value)
	jit_int *	result
	jit_float64	value

jit_long
jit_float64_to_long(value)
	jit_float64	value

jit_int
jit_float64_to_long_ovf(result, value)
	jit_long *	result
	jit_float64	value

jit_nfloat
jit_float64_to_nfloat(value)
	jit_float64	value

jit_uint
jit_float64_to_uint(value)
	jit_float64	value

jit_int
jit_float64_to_uint_ovf(result, value)
	jit_uint *	result
	jit_float64	value

jit_ulong
jit_float64_to_ulong(value)
	jit_float64	value

jit_int
jit_float64_to_ulong_ovf(result, value)
	jit_ulong *	result
	jit_float64	value

jit_float64
jit_float64_trunc(value1)
	jit_float64	value1

int
jit_frame_contains_crawl_mark(frame, mark)
	void *	frame
	jit_crawl_mark_t *	mark

void
jit_free(ptr)
	void *	ptr

void
jit_function_abandon(func)
	jit_function_t	func

int
jit_function_apply(func, args, return_area)
	jit_function_t	func
	AV*	args
	SV*	return_area
PREINIT:
	jit_type_t rettype;
	jit_type_t signature;
	size_t retsize;
	char *buffer;
	AVSTR_PREINIT(args);
CODE:
	signature = jit_function_get_signature(func);
	rettype = jit_type_get_return(signature);
	Perl_assert(rettype != NULL);

	retsize = jit_type_get_size(rettype);

	sv_setpvn(return_area, "", 0);
	buffer = SvGROW(return_area, retsize + 1);

	AVSTR_CODE(args, "jit_function_apply");

	RETVAL = jit_function_apply(func, (void*) ptr_args, buffer);
	buffer[retsize] = 0;
	SvCUR_set(return_area, retsize);
	SvPOK_only(return_area);
	SvSETMAGIC(return_area);
OUTPUT:
	RETVAL

int
jit_function_apply_vararg(func, signature, args, return_area)
	jit_function_t	func
	jit_type_t	signature
	void **	args
	void *	return_area

void
jit_function_clear_recompilable(func)
	jit_function_t	func

int
jit_function_compile(func)
	jit_function_t	func

int
jit_function_compile_entry(func, entry_point)
	jit_function_t	func
	void **	entry_point

jit_function_t
jit_function_create(context, signature)
	jit_context_t	context
	jit_type_t	signature

jit_function_t
jit_function_create_nested(context, signature, parent)
	jit_context_t	context
	jit_type_t	signature
	jit_function_t	parent

void
jit_function_free_meta(func, type)
	jit_function_t	func
	int	type

jit_function_t
jit_function_from_closure(context, closure)
	jit_context_t	context
	void *	closure

jit_function_t
jit_function_from_pc(context, pc, handler)
	jit_context_t	context
	void *	pc
	void **	handler

jit_function_t
jit_function_from_vtable_pointer(context, vtable_pointer)
	jit_context_t	context
	void *	vtable_pointer

jit_context_t
jit_function_get_context(func)
	jit_function_t	func

jit_block_t
jit_function_get_current(func)
	jit_function_t	func

jit_block_t
jit_function_get_entry(func)
	jit_function_t	func

unsigned int
jit_function_get_max_optimization_level()

void *
jit_function_get_meta(func, type)
	jit_function_t	func
	int	type

jit_function_t
jit_function_get_nested_parent(func)
	jit_function_t	func

jit_on_demand_func
jit_function_get_on_demand_compiler(func)
	jit_function_t	func

unsigned int
jit_function_get_optimization_level(func)
	jit_function_t	func

jit_type_t
jit_function_get_signature(func)
	jit_function_t	func

int
jit_function_is_compiled(func)
	jit_function_t	func

int
jit_function_is_recompilable(func)
	jit_function_t	func

int
jit_function_labels_equal(func, label, label2)
	jit_function_t	func
	jit_label_t	label
	jit_label_t	label2

jit_function_t
jit_function_next(context, prev)
	jit_context_t	context
	jit_function_t	prev

jit_function_t
jit_function_previous(context, prev)
	jit_context_t	context
	jit_function_t	prev

jit_label_t
jit_function_reserve_label(func)
	jit_function_t	func

int
jit_function_set_meta(func, type, data, free_data, build_only)
	jit_function_t	func
	int	type
	void *	data
	jit_meta_free_func	free_data
	int	build_only

void
jit_function_set_on_demand_compiler(func, on_demand)
	jit_function_t	func
	jit_on_demand_func	on_demand

void
jit_function_set_optimization_level(func, level)
	jit_function_t	func
	unsigned int	level

void
jit_function_set_recompilable(func)
	jit_function_t	func

void
jit_function_setup_entry(func, entry_point)
	jit_function_t	func
	void *	entry_point

void *
jit_function_to_closure(func)
	jit_function_t	func

void *
jit_function_to_vtable_pointer(func)
	jit_function_t	func

unsigned int
jit_get_closure_alignment()

unsigned int
jit_get_closure_size()

unsigned int
jit_get_trampoline_alignment()

unsigned int
jit_get_trampoline_size()

void
jit_init()

jit_value_t
jit_insn_abs(func, value1)
	jit_function_t	func
	jit_value_t	value1

jit_value_t
jit_insn_acos(func, value1)
	jit_function_t	func
	jit_value_t	value1

jit_value_t
jit_insn_add(func, value1, value2)
	jit_function_t	func
	jit_value_t	value1
	jit_value_t	value2

jit_value_t
jit_insn_add_ovf(func, value1, value2)
	jit_function_t	func
	jit_value_t	value1
	jit_value_t	value2

jit_value_t
jit_insn_add_relative(func, value, offset)
	jit_function_t	func
	jit_value_t	value
	jit_nint	offset

jit_value_t
jit_insn_address_of(func, value1)
	jit_function_t	func
	jit_value_t	value1

jit_value_t
jit_insn_address_of_label(func, label)
	jit_function_t	func
	jit_label_t *	label

jit_value_t
jit_insn_alloca(func, size)
	jit_function_t	func
	jit_value_t	size

jit_value_t
jit_insn_and(func, value1, value2)
	jit_function_t	func
	jit_value_t	value1
	jit_value_t	value2

jit_value_t
jit_insn_asin(func, value1)
	jit_function_t	func
	jit_value_t	value1

jit_value_t
jit_insn_atan(func, value1)
	jit_function_t	func
	jit_value_t	value1

jit_value_t
jit_insn_atan2(func, value1, value2)
	jit_function_t	func
	jit_value_t	value1
	jit_value_t	value2

int
jit_insn_branch(func, label)
	jit_function_t	func
	jit_label_t &	label
OUTPUT:
	label

int
jit_insn_branch_if(func, value, label)
	jit_function_t	func
	jit_value_t	value
	jit_label_t &	label
OUTPUT:
	label

int
jit_insn_branch_if_not(func, value, label)
	jit_function_t	func
	jit_value_t	value
	jit_label_t &	label
OUTPUT:
	label

int
jit_insn_branch_if_pc_not_in_range(func, start_label, end_label, label)
	jit_function_t	func
	jit_label_t	start_label
	jit_label_t	end_label
	jit_label_t &	label
OUTPUT:
	label

jit_value_t
jit_insn_call(func, name, jit_func, signature, args, flags)
	jit_function_t	func
	char *	name
	jit_function_t	jit_func
	jit_type_t	signature
	AV*	args
	int	flags
PREINIT:
	AVPP_PREINIT(args, jit_value_t);
CODE:
	AVPP_CODE(args, "jit_insn_call", jit_value_t);
	RETVAL = jit_insn_call(func, name, jit_func, signature, ptr_args, num_args, flags);
OUTPUT:
	RETVAL
CLEANUP:
	AVPP_CLEANUP(args);

jit_value_t
jit_insn_call_filter(func, label, value, type)
	jit_function_t	func
	jit_label_t *	label
	jit_value_t	value
	jit_type_t	type

int
jit_insn_call_finally(func, finally_label)
	jit_function_t	func
	jit_label_t *	finally_label

jit_value_t
jit_insn_call_indirect(func, value, signature, args, flags)
	jit_function_t	func
	jit_value_t	value
	jit_type_t	signature
	AV*	args
	int	flags
PREINIT:
	AVPP_PREINIT(args, jit_value_t);
CODE:
	AVPP_CODE(args, "jit_insn_call_indirect", jit_value_t);
	RETVAL = jit_insn_call_indirect(func, value, signature, ptr_args, num_args, flags);
OUTPUT:
	RETVAL
CLEANUP:
	AVPP_CLEANUP(args);

jit_value_t
jit_insn_call_indirect_vtable(func, value, signature, args, flags)
	jit_function_t	func
	jit_value_t	value
	jit_type_t	signature
	AV*	args
	int	flags
PREINIT:
	AVPP_PREINIT(args, jit_value_t);
CODE:
	AVPP_CODE(args, "jit_insn_call_indirect_vtable", jit_value_t);
	RETVAL = jit_insn_call_indirect_vtable(func, value, signature, ptr_args, num_args, flags);
OUTPUT:
	RETVAL
CLEANUP:
	AVPP_CLEANUP(args);

jit_value_t
jit_insn_call_intrinsic(func, name, intrinsic_func, descriptor, arg1, arg2)
	jit_function_t	func
	char *	name
	void *	intrinsic_func
	jit_intrinsic_descr_t *	descriptor
	jit_value_t	arg1
	jit_value_t	arg2

jit_value_t
jit_insn_call_native(func, name, native_func, signature, args, flags)
	jit_function_t	func
	char *	name
	void *	native_func
	jit_type_t	signature
	AV*	args
	int	flags
PREINIT:
	AVPP_PREINIT(args, jit_value_t);
CODE:
	AVPP_CODE(args, "jit_insn_call_native", jit_value_t);
	RETVAL = jit_insn_call_native(func, name, native_func, signature, ptr_args, num_args, flags);
OUTPUT:
	RETVAL
CLEANUP:
	AVPP_CLEANUP(args);

jit_value_t
jit_insn_ceil(func, value1)
	jit_function_t	func
	jit_value_t	value1

int
jit_insn_check_null(func, value)
	jit_function_t	func
	jit_value_t	value

jit_value_t
jit_insn_cmpg(func, value1, value2)
	jit_function_t	func
	jit_value_t	value1
	jit_value_t	value2

jit_value_t
jit_insn_cmpl(func, value1, value2)
	jit_function_t	func
	jit_value_t	value1
	jit_value_t	value2

jit_value_t
jit_insn_convert(func, value, type, overflow_check)
	jit_function_t	func
	jit_value_t	value
	jit_type_t	type
	int	overflow_check

jit_value_t
jit_insn_cos(func, value1)
	jit_function_t	func
	jit_value_t	value1

jit_value_t
jit_insn_cosh(func, value1)
	jit_function_t	func
	jit_value_t	value1

int
jit_insn_default_return(func)
	jit_function_t	func

int
jit_insn_defer_pop_stack(func, num_items)
	jit_function_t	func
	jit_nint	num_items

int
jit_insn_dest_is_value(insn)
	jit_insn_t	insn

jit_value_t
jit_insn_div(func, value1, value2)
	jit_function_t	func
	jit_value_t	value1
	jit_value_t	value2

jit_value_t
jit_insn_dup(func, value)
	jit_function_t	func
	jit_value_t	value

jit_value_t
jit_insn_eq(func, value1, value2)
	jit_function_t	func
	jit_value_t	value1
	jit_value_t	value2

jit_value_t
jit_insn_exp(func, value1)
	jit_function_t	func
	jit_value_t	value1

jit_value_t
jit_insn_floor(func, value1)
	jit_function_t	func
	jit_value_t	value1

int
jit_insn_flush_defer_pop(func, num_items)
	jit_function_t	func
	jit_nint	num_items

int
jit_insn_flush_struct(func, value)
	jit_function_t	func
	jit_value_t	value

jit_value_t
jit_insn_ge(func, value1, value2)
	jit_function_t	func
	jit_value_t	value1
	jit_value_t	value2

jit_value_t
jit_insn_get_call_stack(func)
	jit_function_t	func

jit_value_t
jit_insn_get_dest(insn)
	jit_insn_t	insn

jit_function_t
jit_insn_get_function(insn)
	jit_insn_t	insn

jit_label_t
jit_insn_get_label(insn)
	jit_insn_t	insn

char *
jit_insn_get_name(insn)
	jit_insn_t	insn

void *
jit_insn_get_native(insn)
	jit_insn_t	insn

int
jit_insn_get_opcode(insn)
	jit_insn_t	insn

jit_type_t
jit_insn_get_signature(insn)
	jit_insn_t	insn

jit_value_t
jit_insn_get_value1(insn)
	jit_insn_t	insn

jit_value_t
jit_insn_get_value2(insn)
	jit_insn_t	insn

jit_value_t
jit_insn_gt(func, value1, value2)
	jit_function_t	func
	jit_value_t	value1
	jit_value_t	value2

jit_value_t
jit_insn_import(func, value)
	jit_function_t	func
	jit_value_t	value

int
jit_insn_incoming_frame_posn(func, value, frame_offset)
	jit_function_t	func
	jit_value_t	value
	jit_nint	frame_offset

int
jit_insn_incoming_reg(func, value, reg)
	jit_function_t	func
	jit_value_t	value
	int	reg

jit_value_t
jit_insn_is_finite(func, value1)
	jit_function_t	func
	jit_value_t	value1

jit_value_t
jit_insn_is_inf(func, value1)
	jit_function_t	func
	jit_value_t	value1

jit_value_t
jit_insn_is_nan(func, value1)
	jit_function_t	func
	jit_value_t	value1

void
jit_insn_iter_init(iter, block)
	jit_insn_iter_t *	iter
	jit_block_t	block

void
jit_insn_iter_init_last(iter, block)
	jit_insn_iter_t *	iter
	jit_block_t	block

jit_insn_t
jit_insn_iter_next(iter)
	jit_insn_iter_t *	iter

jit_insn_t
jit_insn_iter_previous(iter)
	jit_insn_iter_t *	iter

int
jit_insn_jump_table(func, value, labels, num_labels)
	jit_function_t	func
	jit_value_t	value
	jit_label_t *	labels
	unsigned int	num_labels

int
jit_insn_label(func, label)
	jit_function_t	func
	jit_label_t &	label
OUTPUT:
	label

jit_value_t
jit_insn_le(func, value1, value2)
	jit_function_t	func
	jit_value_t	value1
	jit_value_t	value2

jit_value_t
jit_insn_load(func, value)
	jit_function_t	func
	jit_value_t	value

jit_value_t
jit_insn_load_elem(func, base_addr, index, elem_type)
	jit_function_t	func
	jit_value_t	base_addr
	jit_value_t	index
	jit_type_t	elem_type

jit_value_t
jit_insn_load_elem_address(func, base_addr, index, elem_type)
	jit_function_t	func
	jit_value_t	base_addr
	jit_value_t	index
	jit_type_t	elem_type

jit_value_t
jit_insn_load_relative(func, value, offset, type)
	jit_function_t	func
	jit_value_t	value
	jit_nint	offset
	jit_type_t	type

jit_value_t
jit_insn_load_small(func, value)
	jit_function_t	func
	jit_value_t	value

jit_value_t
jit_insn_log(func, value1)
	jit_function_t	func
	jit_value_t	value1

jit_value_t
jit_insn_log10(func, value1)
	jit_function_t	func
	jit_value_t	value1

jit_value_t
jit_insn_lt(func, value1, value2)
	jit_function_t	func
	jit_value_t	value1
	jit_value_t	value2

int
jit_insn_mark_breakpoint(func, data1, data2)
	jit_function_t	func
	jit_nint	data1
	jit_nint	data2

int
jit_insn_mark_breakpoint_variable(func, data1, data2)
	jit_function_t	func
	jit_value_t	data1
	jit_value_t	data2

int
jit_insn_mark_offset(func, offset)
	jit_function_t	func
	jit_int	offset

jit_value_t
jit_insn_max(func, value1, value2)
	jit_function_t	func
	jit_value_t	value1
	jit_value_t	value2

int
jit_insn_memcpy(func, dest, src, size)
	jit_function_t	func
	jit_value_t	dest
	jit_value_t	src
	jit_value_t	size

int
jit_insn_memmove(func, dest, src, size)
	jit_function_t	func
	jit_value_t	dest
	jit_value_t	src
	jit_value_t	size

int
jit_insn_memset(func, dest, value, size)
	jit_function_t	func
	jit_value_t	dest
	jit_value_t	value
	jit_value_t	size

jit_value_t
jit_insn_min(func, value1, value2)
	jit_function_t	func
	jit_value_t	value1
	jit_value_t	value2

int
jit_insn_move_blocks_to_end(func, from_label, to_label)
	jit_function_t	func
	jit_label_t	from_label
	jit_label_t	to_label

int
jit_insn_move_blocks_to_start(func, from_label, to_label)
	jit_function_t	func
	jit_label_t	from_label
	jit_label_t	to_label

jit_value_t
jit_insn_mul(func, value1, value2)
	jit_function_t	func
	jit_value_t	value1
	jit_value_t	value2

jit_value_t
jit_insn_mul_ovf(func, value1, value2)
	jit_function_t	func
	jit_value_t	value1
	jit_value_t	value2

jit_value_t
jit_insn_ne(func, value1, value2)
	jit_function_t	func
	jit_value_t	value1
	jit_value_t	value2

jit_value_t
jit_insn_neg(func, value1)
	jit_function_t	func
	jit_value_t	value1

int
jit_insn_new_block(func)
	jit_function_t	func

jit_value_t
jit_insn_not(func, value1)
	jit_function_t	func
	jit_value_t	value1

jit_value_t
jit_insn_or(func, value1, value2)
	jit_function_t	func
	jit_value_t	value1
	jit_value_t	value2

int
jit_insn_outgoing_frame_posn(func, value, frame_offset)
	jit_function_t	func
	jit_value_t	value
	jit_nint	frame_offset

int
jit_insn_outgoing_reg(func, value, reg)
	jit_function_t	func
	jit_value_t	value
	int	reg

int
jit_insn_pop_stack(func, num_items)
	jit_function_t	func
	jit_nint	num_items

jit_value_t
jit_insn_pow(func, value1, value2)
	jit_function_t	func
	jit_value_t	value1
	jit_value_t	value2

int
jit_insn_push(func, value)
	jit_function_t	func
	jit_value_t	value

int
jit_insn_push_ptr(func, value, type)
	jit_function_t	func
	jit_value_t	value
	jit_type_t	type

int
jit_insn_push_return_area_ptr(func)
	jit_function_t	func

jit_value_t
jit_insn_rem(func, value1, value2)
	jit_function_t	func
	jit_value_t	value1
	jit_value_t	value2

jit_value_t
jit_insn_rem_ieee(func, value1, value2)
	jit_function_t	func
	jit_value_t	value1
	jit_value_t	value2

int
jit_insn_rethrow_unhandled(func)
	jit_function_t	func

int
jit_insn_return(func, value)
	jit_function_t	func
	jit_value_t	value

int
jit_insn_return_from_filter(func, value)
	jit_function_t	func
	jit_value_t	value

int
jit_insn_return_from_finally(func)
	jit_function_t	func

int
jit_insn_return_ptr(func, value, type)
	jit_function_t	func
	jit_value_t	value
	jit_type_t	type

int
jit_insn_return_reg(func, value, reg)
	jit_function_t	func
	jit_value_t	value
	int	reg

jit_value_t
jit_insn_rint(func, value1)
	jit_function_t	func
	jit_value_t	value1

jit_value_t
jit_insn_round(func, value1)
	jit_function_t	func
	jit_value_t	value1

int
jit_insn_set_param(func, value, offset)
	jit_function_t	func
	jit_value_t	value
	jit_nint	offset

int
jit_insn_set_param_ptr(func, value, type, offset)
	jit_function_t	func
	jit_value_t	value
	jit_type_t	type
	jit_nint	offset

int
jit_insn_setup_for_nested(func, nested_level, reg)
	jit_function_t	func
	int	nested_level
	int	reg

jit_value_t
jit_insn_shl(func, value1, value2)
	jit_function_t	func
	jit_value_t	value1
	jit_value_t	value2

jit_value_t
jit_insn_shr(func, value1, value2)
	jit_function_t	func
	jit_value_t	value1
	jit_value_t	value2

jit_value_t
jit_insn_sign(func, value1)
	jit_function_t	func
	jit_value_t	value1

jit_value_t
jit_insn_sin(func, value1)
	jit_function_t	func
	jit_value_t	value1

jit_value_t
jit_insn_sinh(func, value1)
	jit_function_t	func
	jit_value_t	value1

jit_value_t
jit_insn_sqrt(func, value1)
	jit_function_t	func
	jit_value_t	value1

jit_value_t
jit_insn_sshr(func, value1, value2)
	jit_function_t	func
	jit_value_t	value1
	jit_value_t	value2

jit_value_t
jit_insn_start_catcher(func)
	jit_function_t	func

jit_value_t
jit_insn_start_filter(func, label, type)
	jit_function_t	func
	jit_label_t *	label
	jit_type_t	type

int
jit_insn_start_finally(func, finally_label)
	jit_function_t	func
	jit_label_t *	finally_label

int
jit_insn_store(func, dest, value)
	jit_function_t	func
	jit_value_t	dest
	jit_value_t	value

int
jit_insn_store_elem(func, base_addr, index, value)
	jit_function_t	func
	jit_value_t	base_addr
	jit_value_t	index
	jit_value_t	value

int
jit_insn_store_relative(func, dest, offset, value)
	jit_function_t	func
	jit_value_t	dest
	jit_nint	offset
	jit_value_t	value

jit_value_t
jit_insn_sub(func, value1, value2)
	jit_function_t	func
	jit_value_t	value1
	jit_value_t	value2

jit_value_t
jit_insn_sub_ovf(func, value1, value2)
	jit_function_t	func
	jit_value_t	value1
	jit_value_t	value2

jit_value_t
jit_insn_tan(func, value1)
	jit_function_t	func
	jit_value_t	value1

jit_value_t
jit_insn_tanh(func, value1)
	jit_function_t	func
	jit_value_t	value1

int
jit_insn_throw(func, value)
	jit_function_t	func
	jit_value_t	value

jit_value_t
jit_insn_thrown_exception(func)
	jit_function_t	func

jit_value_t
jit_insn_to_bool(func, value1)
	jit_function_t	func
	jit_value_t	value1

jit_value_t
jit_insn_to_not_bool(func, value1)
	jit_function_t	func
	jit_value_t	value1

jit_value_t
jit_insn_trunc(func, value1)
	jit_function_t	func
	jit_value_t	value1

int
jit_insn_uses_catcher(func)
	jit_function_t	func

jit_value_t
jit_insn_ushr(func, value1, value2)
	jit_function_t	func
	jit_value_t	value1
	jit_value_t	value2

jit_value_t
jit_insn_xor(func, value1, value2)
	jit_function_t	func
	jit_value_t	value1
	jit_value_t	value2

jit_int
jit_int_abs(value1)
	jit_int	value1

jit_int
jit_int_add(value1, value2)
	jit_int	value1
	jit_int	value2

jit_int
jit_int_add_ovf(result, value1, value2)
	jit_int *	result
	jit_int	value1
	jit_int	value2

jit_int
jit_int_and(value1, value2)
	jit_int	value1
	jit_int	value2

jit_int
jit_int_cmp(value1, value2)
	jit_int	value1
	jit_int	value2

jit_int
jit_int_div(result, value1, value2)
	jit_int *	result
	jit_int	value1
	jit_int	value2

jit_int
jit_int_eq(value1, value2)
	jit_int	value1
	jit_int	value2

jit_int
jit_int_ge(value1, value2)
	jit_int	value1
	jit_int	value2

jit_int
jit_int_gt(value1, value2)
	jit_int	value1
	jit_int	value2

jit_int
jit_int_le(value1, value2)
	jit_int	value1
	jit_int	value2

jit_int
jit_int_lt(value1, value2)
	jit_int	value1
	jit_int	value2

jit_int
jit_int_max(value1, value2)
	jit_int	value1
	jit_int	value2

jit_int
jit_int_min(value1, value2)
	jit_int	value1
	jit_int	value2

jit_int
jit_int_mul(value1, value2)
	jit_int	value1
	jit_int	value2

jit_int
jit_int_mul_ovf(result, value1, value2)
	jit_int *	result
	jit_int	value1
	jit_int	value2

jit_int
jit_int_ne(value1, value2)
	jit_int	value1
	jit_int	value2

jit_int
jit_int_neg(value1)
	jit_int	value1

jit_int
jit_int_not(value1)
	jit_int	value1

jit_int
jit_int_or(value1, value2)
	jit_int	value1
	jit_int	value2

jit_int
jit_int_rem(result, value1, value2)
	jit_int *	result
	jit_int	value1
	jit_int	value2

jit_int
jit_int_shl(value1, value2)
	jit_int	value1
	jit_uint	value2

jit_int
jit_int_shr(value1, value2)
	jit_int	value1
	jit_uint	value2

jit_int
jit_int_sign(value1)
	jit_int	value1

jit_int
jit_int_sub(value1, value2)
	jit_int	value1
	jit_int	value2

jit_int
jit_int_sub_ovf(result, value1, value2)
	jit_int *	result
	jit_int	value1
	jit_int	value2

jit_float32
jit_int_to_float32(value)
	jit_int	value

jit_float64
jit_int_to_float64(value)
	jit_int	value

jit_int
jit_int_to_int(value)
	jit_int	value

jit_int
jit_int_to_int_ovf(result, value)
	jit_int *	result
	jit_int	value

jit_long
jit_int_to_long(value)
	jit_int	value

jit_int
jit_int_to_long_ovf(result, value)
	jit_long *	result
	jit_int	value

jit_nfloat
jit_int_to_nfloat(value)
	jit_int	value

jit_int
jit_int_to_sbyte(value)
	jit_int	value

jit_int
jit_int_to_sbyte_ovf(result, value)
	jit_int *	result
	jit_int	value

jit_int
jit_int_to_short(value)
	jit_int	value

jit_int
jit_int_to_short_ovf(result, value)
	jit_int *	result
	jit_int	value

jit_int
jit_int_to_ubyte(value)
	jit_int	value

jit_int
jit_int_to_ubyte_ovf(result, value)
	jit_int *	result
	jit_int	value

jit_uint
jit_int_to_uint(value)
	jit_int	value

jit_int
jit_int_to_uint_ovf(result, value)
	jit_uint *	result
	jit_int	value

jit_ulong
jit_int_to_ulong(value)
	jit_int	value

jit_int
jit_int_to_ulong_ovf(result, value)
	jit_ulong *	result
	jit_int	value

jit_int
jit_int_to_ushort(value)
	jit_int	value

jit_int
jit_int_to_ushort_ovf(result, value)
	jit_int *	result
	jit_int	value

jit_int
jit_int_xor(value1, value2)
	jit_int	value1
	jit_int	value2

jit_long
jit_long_abs(value1)
	jit_long	value1

jit_long
jit_long_add(value1, value2)
	jit_long	value1
	jit_long	value2

jit_int
jit_long_add_ovf(result, value1, value2)
	jit_long *	result
	jit_long	value1
	jit_long	value2

jit_long
jit_long_and(value1, value2)
	jit_long	value1
	jit_long	value2

jit_int
jit_long_cmp(value1, value2)
	jit_long	value1
	jit_long	value2

jit_int
jit_long_div(result, value1, value2)
	jit_long *	result
	jit_long	value1
	jit_long	value2

jit_int
jit_long_eq(value1, value2)
	jit_long	value1
	jit_long	value2

jit_int
jit_long_ge(value1, value2)
	jit_long	value1
	jit_long	value2

jit_int
jit_long_gt(value1, value2)
	jit_long	value1
	jit_long	value2

jit_int
jit_long_le(value1, value2)
	jit_long	value1
	jit_long	value2

jit_int
jit_long_lt(value1, value2)
	jit_long	value1
	jit_long	value2

jit_long
jit_long_max(value1, value2)
	jit_long	value1
	jit_long	value2

jit_long
jit_long_min(value1, value2)
	jit_long	value1
	jit_long	value2

jit_long
jit_long_mul(value1, value2)
	jit_long	value1
	jit_long	value2

jit_int
jit_long_mul_ovf(result, value1, value2)
	jit_long *	result
	jit_long	value1
	jit_long	value2

jit_int
jit_long_ne(value1, value2)
	jit_long	value1
	jit_long	value2

jit_long
jit_long_neg(value1)
	jit_long	value1

jit_long
jit_long_not(value1)
	jit_long	value1

jit_long
jit_long_or(value1, value2)
	jit_long	value1
	jit_long	value2

jit_int
jit_long_rem(result, value1, value2)
	jit_long *	result
	jit_long	value1
	jit_long	value2

jit_long
jit_long_shl(value1, value2)
	jit_long	value1
	jit_uint	value2

jit_long
jit_long_shr(value1, value2)
	jit_long	value1
	jit_uint	value2

jit_int
jit_long_sign(value1)
	jit_long	value1

jit_long
jit_long_sub(value1, value2)
	jit_long	value1
	jit_long	value2

jit_int
jit_long_sub_ovf(result, value1, value2)
	jit_long *	result
	jit_long	value1
	jit_long	value2

jit_float32
jit_long_to_float32(value)
	jit_long	value

jit_float64
jit_long_to_float64(value)
	jit_long	value

jit_int
jit_long_to_int(value)
	jit_long	value

jit_int
jit_long_to_int_ovf(result, value)
	jit_int *	result
	jit_long	value

jit_long
jit_long_to_long(value)
	jit_long	value

jit_int
jit_long_to_long_ovf(result, value)
	jit_long *	result
	jit_long	value

jit_nfloat
jit_long_to_nfloat(value)
	jit_long	value

jit_uint
jit_long_to_uint(value)
	jit_long	value

jit_int
jit_long_to_uint_ovf(result, value)
	jit_uint *	result
	jit_long	value

jit_ulong
jit_long_to_ulong(value)
	jit_long	value

jit_int
jit_long_to_ulong_ovf(result, value)
	jit_ulong *	result
	jit_long	value

jit_long
jit_long_xor(value1, value2)
	jit_long	value1
	jit_long	value2

void *
jit_malloc(size)
	unsigned int	size

void *
jit_memchr(str, ch, len)
	void *	str
	int	ch
	unsigned int	len

int
jit_memcmp(s1, s2, len)
	void *	s1
	void *	s2
	unsigned int	len

void *
jit_memcpy(dest, src, len)
	void *	dest
	void *	src
	unsigned int	len

void *
jit_memmove(dest, src, len)
	void *	dest
	void *	src
	unsigned int	len

void *
jit_memset(dest, ch, len)
	void *	dest
	int	ch
	unsigned int	len

void
jit_meta_destroy(list)
	jit_meta_t *	list

void
jit_meta_free(list, type)
	jit_meta_t *	list
	int	type

void *
jit_meta_get(list, type)
	jit_meta_t	list
	int	type

int
jit_meta_set(list, type, data, free_data, pool_owner)
	jit_meta_t *	list
	int	type
	void *	data
	jit_meta_free_func	free_data
	jit_function_t	pool_owner

jit_nfloat
jit_nfloat_abs(value1)
	jit_nfloat	value1

jit_nfloat
jit_nfloat_acos(value1)
	jit_nfloat	value1

jit_nfloat
jit_nfloat_add(value1, value2)
	jit_nfloat	value1
	jit_nfloat	value2

jit_nfloat
jit_nfloat_asin(value1)
	jit_nfloat	value1

jit_nfloat
jit_nfloat_atan(value1)
	jit_nfloat	value1

jit_nfloat
jit_nfloat_atan2(value1, value2)
	jit_nfloat	value1
	jit_nfloat	value2

jit_nfloat
jit_nfloat_ceil(value1)
	jit_nfloat	value1

jit_int
jit_nfloat_cmpg(value1, value2)
	jit_nfloat	value1
	jit_nfloat	value2

jit_int
jit_nfloat_cmpl(value1, value2)
	jit_nfloat	value1
	jit_nfloat	value2

jit_nfloat
jit_nfloat_cos(value1)
	jit_nfloat	value1

jit_nfloat
jit_nfloat_cosh(value1)
	jit_nfloat	value1

jit_nfloat
jit_nfloat_div(value1, value2)
	jit_nfloat	value1
	jit_nfloat	value2

jit_int
jit_nfloat_eq(value1, value2)
	jit_nfloat	value1
	jit_nfloat	value2

jit_nfloat
jit_nfloat_exp(value1)
	jit_nfloat	value1

jit_nfloat
jit_nfloat_floor(value1)
	jit_nfloat	value1

jit_int
jit_nfloat_ge(value1, value2)
	jit_nfloat	value1
	jit_nfloat	value2

jit_int
jit_nfloat_gt(value1, value2)
	jit_nfloat	value1
	jit_nfloat	value2

jit_nfloat
jit_nfloat_ieee_rem(value1, value2)
	jit_nfloat	value1
	jit_nfloat	value2

jit_int
jit_nfloat_is_finite(value)
	jit_nfloat	value

jit_int
jit_nfloat_is_inf(value)
	jit_nfloat	value

jit_int
jit_nfloat_is_nan(value)
	jit_nfloat	value

jit_int
jit_nfloat_le(value1, value2)
	jit_nfloat	value1
	jit_nfloat	value2

jit_nfloat
jit_nfloat_log(value1)
	jit_nfloat	value1

jit_nfloat
jit_nfloat_log10(value1)
	jit_nfloat	value1

jit_int
jit_nfloat_lt(value1, value2)
	jit_nfloat	value1
	jit_nfloat	value2

jit_nfloat
jit_nfloat_max(value1, value2)
	jit_nfloat	value1
	jit_nfloat	value2

jit_nfloat
jit_nfloat_min(value1, value2)
	jit_nfloat	value1
	jit_nfloat	value2

jit_nfloat
jit_nfloat_mul(value1, value2)
	jit_nfloat	value1
	jit_nfloat	value2

jit_int
jit_nfloat_ne(value1, value2)
	jit_nfloat	value1
	jit_nfloat	value2

jit_nfloat
jit_nfloat_neg(value1)
	jit_nfloat	value1

jit_nfloat
jit_nfloat_pow(value1, value2)
	jit_nfloat	value1
	jit_nfloat	value2

jit_nfloat
jit_nfloat_rem(value1, value2)
	jit_nfloat	value1
	jit_nfloat	value2

jit_nfloat
jit_nfloat_rint(value1)
	jit_nfloat	value1

jit_nfloat
jit_nfloat_round(value1)
	jit_nfloat	value1

jit_int
jit_nfloat_sign(value1)
	jit_nfloat	value1

jit_nfloat
jit_nfloat_sin(value1)
	jit_nfloat	value1

jit_nfloat
jit_nfloat_sinh(value1)
	jit_nfloat	value1

jit_nfloat
jit_nfloat_sqrt(value1)
	jit_nfloat	value1

jit_nfloat
jit_nfloat_sub(value1, value2)
	jit_nfloat	value1
	jit_nfloat	value2

jit_nfloat
jit_nfloat_tan(value1)
	jit_nfloat	value1

jit_nfloat
jit_nfloat_tanh(value1)
	jit_nfloat	value1

jit_float32
jit_nfloat_to_float32(value)
	jit_nfloat	value

jit_float64
jit_nfloat_to_float64(value)
	jit_nfloat	value

jit_int
jit_nfloat_to_int(value)
	jit_nfloat	value

jit_int
jit_nfloat_to_int_ovf(result, value)
	jit_int *	result
	jit_nfloat	value

jit_long
jit_nfloat_to_long(value)
	jit_nfloat	value

jit_int
jit_nfloat_to_long_ovf(result, value)
	jit_long *	result
	jit_nfloat	value

jit_uint
jit_nfloat_to_uint(value)
	jit_nfloat	value

jit_int
jit_nfloat_to_uint_ovf(result, value)
	jit_uint *	result
	jit_nfloat	value

jit_ulong
jit_nfloat_to_ulong(value)
	jit_nfloat	value

jit_int
jit_nfloat_to_ulong_ovf(result, value)
	jit_ulong *	result
	jit_nfloat	value

jit_nfloat
jit_nfloat_trunc(value1)
	jit_nfloat	value1

int
jit_raw_supported(signature)
	jit_type_t	signature

void
jit_readelf_add_to_context(readelf, context)
	jit_readelf_t	readelf
	jit_context_t	context

void
jit_readelf_close(readelf)
	jit_readelf_t	readelf

char *
jit_readelf_get_name(readelf)
	jit_readelf_t	readelf

char *
jit_readelf_get_needed(readelf, index)
	jit_readelf_t	readelf
	unsigned int	index

void *
jit_readelf_get_section(readelf, name, size)
	jit_readelf_t	readelf
	char *	name
	jit_nuint *	size

void *
jit_readelf_get_section_by_type(readelf, type, size)
	jit_readelf_t	readelf
	jit_int	type
	jit_nuint *	size

void *
jit_readelf_get_symbol(readelf, name)
	jit_readelf_t	readelf
	char *	name

void *
jit_readelf_map_vaddr(readelf, vaddr)
	jit_readelf_t	readelf
	jit_nuint	vaddr

unsigned int
jit_readelf_num_needed(readelf)
	jit_readelf_t	readelf

int
jit_readelf_open(readelf, filename, flags)
	jit_readelf_t *	readelf
	char *	filename
	int	flags

int
jit_readelf_register_symbol(context, name, value, after)
	jit_context_t	context
	char *	name
	void *	value
	int	after

int
jit_readelf_resolve_all(context, print_failures)
	jit_context_t	context
	int	print_failures

void *
jit_realloc(ptr, size)
	void *	ptr
	unsigned int	size

=for Disable

h2xs failed to parse these functions properly, Perl has own sprintf.

int
jit_snprintf(str, len, arg2, ...)
	char *	str
	unsigned int	len
	char * format	arg2

int
jit_sprintf(str, arg1, ...)
	char *	str
	char * format	arg1

=cut

void
jit_stack_trace_free(trace)
	jit_stack_trace_t	trace

jit_function_t
jit_stack_trace_get_function(context, trace, posn)
	jit_context_t	context
	jit_stack_trace_t	trace
	unsigned int	posn

unsigned int
jit_stack_trace_get_offset(context, trace, posn)
	jit_context_t	context
	jit_stack_trace_t	trace
	unsigned int	posn

void *
jit_stack_trace_get_pc(trace, posn)
	jit_stack_trace_t	trace
	unsigned int	posn

unsigned int
jit_stack_trace_get_size(trace)
	jit_stack_trace_t	trace

char *
jit_strcat(dest, src)
	char *	dest
	char *	src

char *
jit_strchr(str, ch)
	char *	str
	int	ch

int
jit_strcmp(str1, str2)
	char *	str1
	char *	str2

char *
jit_strcpy(dest, src)
	char *	dest
	char *	src

char *
jit_strdup(str)
	char *	str

int
jit_stricmp(str1, str2)
	char *	str1
	char *	str2

unsigned int
jit_strlen(str)
	char *	str

int
jit_strncmp(str1, str2, len)
	char *	str1
	char *	str2
	unsigned int	len

char *
jit_strncpy(dest, src, len)
	char *	dest
	char *	src
	unsigned int	len

char *
jit_strndup(str, len)
	char *	str
	unsigned int	len

int
jit_strnicmp(str1, str2, len)
	char *	str1
	char *	str2
	unsigned int	len

char *
jit_strrchr(str, ch)
	char *	str
	int	ch

int
jit_supports_closures()

int
jit_supports_threads()

int
jit_supports_virtual_memory()

jit_nuint
jit_type_best_alignment()

jit_type_t
jit_type_copy(type)
	jit_type_t	type

jit_type_t
jit_type_create_pointer(type, incref)
	jit_type_t	type
	int	incref

jit_type_t
jit_type_create_signature(abi, return_type, params, incref)
	jit_abi_t	abi
	jit_type_t	return_type
	AV*	params
	int	incref
PREINIT:
	AVPP_PREINIT(params, jit_type_t);
CODE:
	AVPP_CODE(params, "jit_type_create_signature", jit_type_t);
	RETVAL = jit_type_create_signature(abi, return_type, ptr_params, num_params, incref);
OUTPUT:
	RETVAL
CLEANUP:
	AVPP_CLEANUP(params);

jit_type_t
jit_type_create_struct(fields, incref)
	AV*	fields
	int	incref
PREINIT:
	AVPP_PREINIT(fields, jit_type_t);
CODE:
	AVPP_CODE(fields, "jit_type_create_struct", jit_type_t);
	RETVAL = jit_type_create_struct(ptr_fields, num_fields, incref);
OUTPUT:
	RETVAL
CLEANUP:
	AVPP_CLEANUP(fields);

jit_type_t
jit_type_create_tagged(type, kind, data, free_func, incref)
	jit_type_t	type
	int	kind
	void *	data
	jit_meta_free_func	free_func
	int	incref

jit_type_t
jit_type_create_union(fields, incref)
	AV*	fields
	int	incref
PREINIT:
	AVPP_PREINIT(fields, jit_type_t);
CODE:
	AVPP_CODE(fields, "jit_type_create_union", jit_type_t);
	RETVAL = jit_type_create_union(ptr_fields, num_fields, incref);
OUTPUT:
	RETVAL
CLEANUP:
	AVPP_CLEANUP(fields);


unsigned int
jit_type_find_name(type, name)
	jit_type_t	type
	char *	name

void
jit_type_free(type)
	jit_type_t	type

jit_abi_t
jit_type_get_abi(type)
	jit_type_t	type

jit_nuint
jit_type_get_alignment(type)
	jit_type_t	type

jit_type_t
jit_type_get_field(type, field_index)
	jit_type_t	type
	unsigned int	field_index

int
jit_type_get_kind(type)
	jit_type_t	type

char *
jit_type_get_name(type, index)
	jit_type_t	type
	unsigned int	index

jit_nuint
jit_type_get_offset(type, field_index)
	jit_type_t	type
	unsigned int	field_index

jit_type_t
jit_type_get_param(type, param_index)
	jit_type_t	type
	unsigned int	param_index

jit_type_t
jit_type_get_ref(type)
	jit_type_t	type

jit_type_t
jit_type_get_return(type)
	jit_type_t	type

jit_nuint
jit_type_get_size(type)
	jit_type_t	type

void *
jit_type_get_tagged_data(type)
	jit_type_t	type

int
jit_type_get_tagged_kind(type)
	jit_type_t	type

jit_type_t
jit_type_get_tagged_type(type)
	jit_type_t	type

int
jit_type_has_tag(type, kind)
	jit_type_t	type
	int	kind

int
jit_type_is_pointer(type)
	jit_type_t	type

int
jit_type_is_primitive(type)
	jit_type_t	type

int
jit_type_is_signature(type)
	jit_type_t	type

int
jit_type_is_struct(type)
	jit_type_t	type

int
jit_type_is_tagged(type)
	jit_type_t	type

int
jit_type_is_union(type)
	jit_type_t	type

jit_type_t
jit_type_normalize(type)
	jit_type_t	type

unsigned int
jit_type_num_fields(type)
	jit_type_t	type

unsigned int
jit_type_num_params(type)
	jit_type_t	type

jit_type_t
jit_type_promote_int(type)
	jit_type_t	type

jit_type_t
jit_type_remove_tags(type)
	jit_type_t	type

int
jit_type_return_via_pointer(type)
	jit_type_t	type

int
jit_type_set_names(type, names)
	jit_type_t	type
	AV*	names
PREINIT:
	AVSTR_PREINIT(names);
CODE:
	AVSTR_CODE(names, "jit_type_set_names");
	RETVAL = jit_type_set_names(type, ptr_names, num_names);
OUTPUT:
	RETVAL
CLEANUP:
	AVSTR_CLEANUP(names);

void
jit_type_set_offset(type, field_index, offset)
	jit_type_t	type
	unsigned int	field_index
	jit_nuint	offset

void
jit_type_set_size_and_alignment(type, size, alignment)
	jit_type_t	type
	jit_nint	size
	jit_nint	alignment

void
jit_type_set_tagged_data(type, data, free_func)
	jit_type_t	type
	void *	data
	jit_meta_free_func	free_func

void
jit_type_set_tagged_type(type, underlying, incref)
	jit_type_t	type
	jit_type_t	underlying
	int	incref

jit_uint
jit_uint_add(value1, value2)
	jit_uint	value1
	jit_uint	value2

jit_int
jit_uint_add_ovf(result, value1, value2)
	jit_uint *	result
	jit_uint	value1
	jit_uint	value2

jit_uint
jit_uint_and(value1, value2)
	jit_uint	value1
	jit_uint	value2

jit_int
jit_uint_cmp(value1, value2)
	jit_uint	value1
	jit_uint	value2

jit_int
jit_uint_div(result, value1, value2)
	jit_uint *	result
	jit_uint	value1
	jit_uint	value2

jit_int
jit_uint_eq(value1, value2)
	jit_uint	value1
	jit_uint	value2

jit_int
jit_uint_ge(value1, value2)
	jit_uint	value1
	jit_uint	value2

jit_int
jit_uint_gt(value1, value2)
	jit_uint	value1
	jit_uint	value2

jit_int
jit_uint_le(value1, value2)
	jit_uint	value1
	jit_uint	value2

jit_int
jit_uint_lt(value1, value2)
	jit_uint	value1
	jit_uint	value2

jit_uint
jit_uint_max(value1, value2)
	jit_uint	value1
	jit_uint	value2

jit_uint
jit_uint_min(value1, value2)
	jit_uint	value1
	jit_uint	value2

jit_uint
jit_uint_mul(value1, value2)
	jit_uint	value1
	jit_uint	value2

jit_int
jit_uint_mul_ovf(result, value1, value2)
	jit_uint *	result
	jit_uint	value1
	jit_uint	value2

jit_int
jit_uint_ne(value1, value2)
	jit_uint	value1
	jit_uint	value2

jit_uint
jit_uint_neg(value1)
	jit_uint	value1

jit_uint
jit_uint_not(value1)
	jit_uint	value1

jit_uint
jit_uint_or(value1, value2)
	jit_uint	value1
	jit_uint	value2

jit_int
jit_uint_rem(result, value1, value2)
	jit_uint *	result
	jit_uint	value1
	jit_uint	value2

jit_uint
jit_uint_shl(value1, value2)
	jit_uint	value1
	jit_uint	value2

jit_uint
jit_uint_shr(value1, value2)
	jit_uint	value1
	jit_uint	value2

jit_uint
jit_uint_sub(value1, value2)
	jit_uint	value1
	jit_uint	value2

jit_int
jit_uint_sub_ovf(result, value1, value2)
	jit_uint *	result
	jit_uint	value1
	jit_uint	value2

jit_float32
jit_uint_to_float32(value)
	jit_uint	value

jit_float64
jit_uint_to_float64(value)
	jit_uint	value

jit_int
jit_uint_to_int(value)
	jit_uint	value

jit_int
jit_uint_to_int_ovf(result, value)
	jit_int *	result
	jit_uint	value

jit_long
jit_uint_to_long(value)
	jit_uint	value

jit_int
jit_uint_to_long_ovf(result, value)
	jit_long *	result
	jit_uint	value

jit_nfloat
jit_uint_to_nfloat(value)
	jit_uint	value

jit_uint
jit_uint_to_uint(value)
	jit_uint	value

jit_int
jit_uint_to_uint_ovf(result, value)
	jit_uint *	result
	jit_uint	value

jit_ulong
jit_uint_to_ulong(value)
	jit_uint	value

jit_int
jit_uint_to_ulong_ovf(result, value)
	jit_ulong *	result
	jit_uint	value

jit_uint
jit_uint_xor(value1, value2)
	jit_uint	value1
	jit_uint	value2

jit_ulong
jit_ulong_add(value1, value2)
	jit_ulong	value1
	jit_ulong	value2

jit_int
jit_ulong_add_ovf(result, value1, value2)
	jit_ulong *	result
	jit_ulong	value1
	jit_ulong	value2

jit_ulong
jit_ulong_and(value1, value2)
	jit_ulong	value1
	jit_ulong	value2

jit_int
jit_ulong_cmp(value1, value2)
	jit_ulong	value1
	jit_ulong	value2

jit_int
jit_ulong_div(result, value1, value2)
	jit_ulong *	result
	jit_ulong	value1
	jit_ulong	value2

jit_int
jit_ulong_eq(value1, value2)
	jit_ulong	value1
	jit_ulong	value2

jit_int
jit_ulong_ge(value1, value2)
	jit_ulong	value1
	jit_ulong	value2

jit_int
jit_ulong_gt(value1, value2)
	jit_ulong	value1
	jit_ulong	value2

jit_int
jit_ulong_le(value1, value2)
	jit_ulong	value1
	jit_ulong	value2

jit_int
jit_ulong_lt(value1, value2)
	jit_ulong	value1
	jit_ulong	value2

jit_ulong
jit_ulong_max(value1, value2)
	jit_ulong	value1
	jit_ulong	value2

jit_ulong
jit_ulong_min(value1, value2)
	jit_ulong	value1
	jit_ulong	value2

jit_ulong
jit_ulong_mul(value1, value2)
	jit_ulong	value1
	jit_ulong	value2

jit_int
jit_ulong_mul_ovf(result, value1, value2)
	jit_ulong *	result
	jit_ulong	value1
	jit_ulong	value2

jit_int
jit_ulong_ne(value1, value2)
	jit_ulong	value1
	jit_ulong	value2

jit_ulong
jit_ulong_neg(value1)
	jit_ulong	value1

jit_ulong
jit_ulong_not(value1)
	jit_ulong	value1

jit_ulong
jit_ulong_or(value1, value2)
	jit_ulong	value1
	jit_ulong	value2

jit_int
jit_ulong_rem(result, value1, value2)
	jit_ulong *	result
	jit_ulong	value1
	jit_ulong	value2

jit_ulong
jit_ulong_shl(value1, value2)
	jit_ulong	value1
	jit_uint	value2

jit_ulong
jit_ulong_shr(value1, value2)
	jit_ulong	value1
	jit_uint	value2

jit_ulong
jit_ulong_sub(value1, value2)
	jit_ulong	value1
	jit_ulong	value2

jit_int
jit_ulong_sub_ovf(result, value1, value2)
	jit_ulong *	result
	jit_ulong	value1
	jit_ulong	value2

jit_float32
jit_ulong_to_float32(value)
	jit_ulong	value

jit_float64
jit_ulong_to_float64(value)
	jit_ulong	value

jit_int
jit_ulong_to_int(value)
	jit_ulong	value

jit_int
jit_ulong_to_int_ovf(result, value)
	jit_int *	result
	jit_ulong	value

jit_long
jit_ulong_to_long(value)
	jit_ulong	value

jit_int
jit_ulong_to_long_ovf(result, value)
	jit_long *	result
	jit_ulong	value

jit_nfloat
jit_ulong_to_nfloat(value)
	jit_ulong	value

jit_uint
jit_ulong_to_uint(value)
	jit_ulong	value

jit_int
jit_ulong_to_uint_ovf(result, value)
	jit_uint *	result
	jit_ulong	value

jit_ulong
jit_ulong_to_ulong(value)
	jit_ulong	value

jit_int
jit_ulong_to_ulong_ovf(result, value)
	jit_ulong *	result
	jit_ulong	value

jit_ulong
jit_ulong_xor(value1, value2)
	jit_ulong	value1
	jit_ulong	value2

void
jit_unwind_free(unwind)
	jit_unwind_context_t *	unwind

jit_function_t
jit_unwind_get_function(unwind)
	jit_unwind_context_t *	unwind

unsigned int
jit_unwind_get_offset(unwind)
	jit_unwind_context_t *	unwind

void *
jit_unwind_get_pc(unwind)
	jit_unwind_context_t *	unwind

int
jit_unwind_init(unwind, context)
	jit_unwind_context_t *	unwind
	jit_context_t	context

int
jit_unwind_jump(unwind, pc)
	jit_unwind_context_t *	unwind
	void *	pc

int
jit_unwind_next(unwind)
	jit_unwind_context_t *	unwind

int
jit_unwind_next_pc(unwind)
	jit_unwind_context_t *	unwind

int
jit_uses_interpreter()

jit_value_t
jit_value_create(func, type)
	jit_function_t	func
	jit_type_t	type

jit_value_t
jit_value_create_constant(func, const_value)
	jit_function_t	func
	jit_constant_t *	const_value

jit_value_t
jit_value_create_float32_constant(func, type, const_value)
	jit_function_t	func
	jit_type_t	type
	jit_float32	const_value

jit_value_t
jit_value_create_float64_constant(func, type, const_value)
	jit_function_t	func
	jit_type_t	type
	jit_float64	const_value

jit_value_t
jit_value_create_long_constant(func, type, const_value)
	jit_function_t	func
	jit_type_t	type
	jit_long	const_value

jit_value_t
jit_value_create_nfloat_constant(func, type, const_value)
	jit_function_t	func
	jit_type_t	type
	jit_nfloat	const_value

jit_value_t
jit_value_create_nint_constant(func, type, const_value)
	jit_function_t	func
	jit_type_t	type
	jit_nint	const_value

jit_block_t
jit_value_get_block(value)
	jit_value_t	value

jit_constant_t
jit_value_get_constant(value)
	jit_value_t	value

jit_context_t
jit_value_get_context(value)
	jit_value_t	value

jit_float32
jit_value_get_float32_constant(value)
	jit_value_t	value

jit_float64
jit_value_get_float64_constant(value)
	jit_value_t	value

jit_function_t
jit_value_get_function(value)
	jit_value_t	value

jit_long
jit_value_get_long_constant(value)
	jit_value_t	value

jit_nfloat
jit_value_get_nfloat_constant(value)
	jit_value_t	value

jit_nint
jit_value_get_nint_constant(value)
	jit_value_t	value

jit_value_t
jit_value_get_param(func, param)
	jit_function_t	func
	unsigned int	param

jit_value_t
jit_value_get_struct_pointer(func)
	jit_function_t	func

jit_type_t
jit_value_get_type(value)
	jit_value_t	value

int
jit_value_is_addressable(value)
	jit_value_t	value

int
jit_value_is_constant(value)
	jit_value_t	value

int
jit_value_is_local(value)
	jit_value_t	value

int
jit_value_is_parameter(value)
	jit_value_t	value

int
jit_value_is_temporary(value)
	jit_value_t	value

int
jit_value_is_true(value)
	jit_value_t	value

int
jit_value_is_volatile(value)
	jit_value_t	value

void
jit_value_ref(func, value)
	jit_function_t	func
	jit_value_t	value

void
jit_value_set_addressable(value)
	jit_value_t	value

void
jit_value_set_volatile(value)
	jit_value_t	value

int
jit_vmem_commit(addr, size, prot)
	void *	addr
	jit_uint	size
	jit_prot_t	prot

int
jit_vmem_decommit(addr, size)
	void *	addr
	jit_uint	size

void
jit_vmem_init()

jit_uint
jit_vmem_page_size()

int
jit_vmem_protect(addr, size, prot)
	void *	addr
	jit_uint	size
	jit_prot_t	prot

int
jit_vmem_release(addr, size)
	void *	addr
	jit_uint	size

void *
jit_vmem_reserve(size)
	jit_uint	size

void *
jit_vmem_reserve_committed(size, prot)
	jit_uint	size
	jit_prot_t	prot

jit_nuint
jit_vmem_round_down(value)
	jit_nuint	value

jit_nuint
jit_vmem_round_up(value)
	jit_nuint	value

int
jit_writeelf_add_function(writeelf, func, name)
	jit_writeelf_t	writeelf
	jit_function_t	func
	char *	name

int
jit_writeelf_add_needed(writeelf, library_name)
	jit_writeelf_t	writeelf
	char *	library_name

jit_writeelf_t
jit_writeelf_create(library_name)
	char *	library_name

void
jit_writeelf_destroy(writeelf)
	jit_writeelf_t	writeelf

int
jit_writeelf_write(writeelf, filename)
	jit_writeelf_t	writeelf
	char *	filename

int
jit_writeelf_write_section(writeelf, name, type, buf, len, discardable)
	jit_writeelf_t	writeelf
	char *	name
	jit_int	type
	void *	buf
	unsigned int	len
	int	discardable

int
jitom_class_add_ref(model, klass, obj_value)
	jit_objmodel_t	model
	jitom_class_t	klass
	jit_value_t	obj_value

int
jitom_class_delete(model, klass, obj_value)
	jit_objmodel_t	model
	jitom_class_t	klass
	jit_value_t	obj_value

jitom_class_t *
jitom_class_get_all_supers(model, klass, num)
	jit_objmodel_t	model
	jitom_class_t	klass
	unsigned int *	num

jitom_field_t *
jitom_class_get_fields(model, klass, num)
	jit_objmodel_t	model
	jitom_class_t	klass
	unsigned int *	num

jitom_class_t *
jitom_class_get_interfaces(model, klass, num)
	jit_objmodel_t	model
	jitom_class_t	klass
	unsigned int *	num

jitom_method_t *
jitom_class_get_methods(model, klass, num)
	jit_objmodel_t	model
	jitom_class_t	klass
	unsigned int *	num

int
jitom_class_get_modifiers(model, klass)
	jit_objmodel_t	model
	jitom_class_t	klass

char *
jitom_class_get_name(model, klass)
	jit_objmodel_t	model
	jitom_class_t	klass

jitom_class_t
jitom_class_get_primary_super(model, klass)
	jit_objmodel_t	model
	jitom_class_t	klass

jit_type_t
jitom_class_get_type(model, klass)
	jit_objmodel_t	model
	jitom_class_t	klass

jit_type_t
jitom_class_get_value_type(model, klass)
	jit_objmodel_t	model
	jitom_class_t	klass

jit_value_t
jitom_class_new(model, klass, ctor, func, args, num_args, flags)
	jit_objmodel_t	model
	jitom_class_t	klass
	jitom_method_t	ctor
	jit_function_t	func
	jit_value_t *	args
	unsigned int	num_args
	int	flags

jit_value_t
jitom_class_new_value(model, klass, ctor, func, args, num_args, flags)
	jit_objmodel_t	model
	jitom_class_t	klass
	jitom_method_t	ctor
	jit_function_t	func
	jit_value_t *	args
	unsigned int	num_args
	int	flags

void
jitom_destroy_model(model)
	jit_objmodel_t	model

int
jitom_field_get_modifiers(model, klass, field)
	jit_objmodel_t	model
	jitom_class_t	klass
	jitom_field_t	field

char *
jitom_field_get_name(model, klass, field)
	jit_objmodel_t	model
	jitom_class_t	klass
	jitom_field_t	field

jit_type_t
jitom_field_get_type(model, klass, field)
	jit_objmodel_t	model
	jitom_class_t	klass
	jitom_field_t	field

jit_value_t
jitom_field_load(model, klass, field, func, obj_value)
	jit_objmodel_t	model
	jitom_class_t	klass
	jitom_field_t	field
	jit_function_t	func
	jit_value_t	obj_value

jit_value_t
jitom_field_load_address(model, klass, field, func, obj_value)
	jit_objmodel_t	model
	jitom_class_t	klass
	jitom_field_t	field
	jit_function_t	func
	jit_value_t	obj_value

int
jitom_field_store(model, klass, field, func, obj_value, value)
	jit_objmodel_t	model
	jitom_class_t	klass
	jitom_field_t	field
	jit_function_t	func
	jit_value_t	obj_value
	jit_value_t	value

jitom_class_t
jitom_get_class_by_name(model, name)
	jit_objmodel_t	model
	char *	name

int
jitom_method_get_modifiers(model, klass, method)
	jit_objmodel_t	model
	jitom_class_t	klass
	jitom_method_t	method

char *
jitom_method_get_name(model, klass, method)
	jit_objmodel_t	model
	jitom_class_t	klass
	jitom_method_t	method

jit_type_t
jitom_method_get_type(model, klass, method)
	jit_objmodel_t	model
	jitom_class_t	klass
	jitom_method_t	method

jit_value_t
jitom_method_invoke(model, klass, method, func, args, num_args, flags)
	jit_objmodel_t	model
	jitom_class_t	klass
	jitom_method_t	method
	jit_function_t	func
	jit_value_t *	args
	unsigned int	num_args
	int	flags

jit_value_t
jitom_method_invoke_virtual(model, klass, method, func, args, num_args, flags)
	jit_objmodel_t	model
	jitom_class_t	klass
	jitom_method_t	method
	jit_function_t	func
	jit_value_t *	args
	unsigned int	num_args
	int	flags

jitom_class_t
jitom_type_get_class(type)
	jit_type_t	type

jit_objmodel_t
jitom_type_get_model(type)
	jit_type_t	type

int
jitom_type_is_class(type)
	jit_type_t	type

int
jitom_type_is_value(type)
	jit_type_t	type

jit_type_t
jitom_type_tag_as_class(type, model, klass, incref)
	jit_type_t	type
	jit_objmodel_t	model
	jitom_class_t	klass
	int	incref

jit_type_t
jitom_type_tag_as_value(type, model, klass, incref)
	jit_type_t	type
	jit_objmodel_t	model
	jitom_class_t	klass
	int	incref

void
jit_dump_type(stream, type)
	FILE*	stream
	jit_type_t	type

void
jit_dump_value(stream, func, value, prefix)
	FILE*	stream
	jit_function_t	func
	jit_value_t	value
	char*	prefix

void
jit_dump_insn(stream, func, insn)
	FILE*	stream
	jit_function_t	func
	jit_insn_t	insn

void
jit_dump_function(stream, func, name)
	FILE*	stream
	jit_function_t	func
	char*	name

INCLUDE: jit_type-xs.inc
