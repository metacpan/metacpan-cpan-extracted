
int _erl_type(x)
    ETERM *x
CODE:
    RETVAL=ERL_TYPE(x);
OUTPUT:
    RETVAL

int _erl_is_integer(x)
	ETERM *x
CODE:
    RETVAL=ERL_IS_INTEGER(x);
OUTPUT:
    RETVAL

int _erl_is_unsigned_integer(x)
	ETERM *x
CODE:
    RETVAL=ERL_IS_UNSIGNED_INTEGER(x);
OUTPUT:
    RETVAL

int _erl_is_longlong(x)
	ETERM *x
CODE:
    RETVAL=ERL_IS_LONGLONG(x);
OUTPUT:
    RETVAL

int _erl_is_unsigned_longlong(x)
	ETERM *x
CODE:
    RETVAL=ERL_IS_UNSIGNED_LONGLONG(x);
OUTPUT:
    RETVAL

int _erl_is_float(x)
	ETERM *x
CODE:
    RETVAL=ERL_IS_FLOAT(x);
OUTPUT:
    RETVAL

int _erl_is_atom(x)
	ETERM *x
CODE:
    RETVAL=ERL_IS_ATOM(x);
OUTPUT:
    RETVAL

int _erl_is_pid(x)
	ETERM *x
CODE:
    RETVAL=ERL_IS_PID(x);
OUTPUT:
    RETVAL

int _erl_is_port(x)
	ETERM *x
CODE:
    RETVAL=ERL_IS_PORT(x);
OUTPUT:
    RETVAL

int _erl_is_ref(x)
	ETERM *x
CODE:
    RETVAL=ERL_IS_REF(x);
OUTPUT:
    RETVAL

int _erl_is_tuple(x)
	ETERM *x
CODE:
    RETVAL=ERL_IS_TUPLE(x);
OUTPUT:
    RETVAL

int _erl_is_binary(x)
	ETERM *x
CODE:
    RETVAL=ERL_IS_BINARY(x);
OUTPUT:
    RETVAL

int _erl_is_nil(x)
	ETERM *x
CODE:
    RETVAL=ERL_IS_NIL(x);
OUTPUT:
    RETVAL

int _erl_is_empty_list(x)
	ETERM *x
CODE:
    RETVAL=ERL_IS_EMPTY_LIST(x);
OUTPUT:
    RETVAL

int _erl_is_cons(x)
	ETERM *x
CODE:
    RETVAL=ERL_IS_CONS(x);
OUTPUT:
    RETVAL

int _erl_is_list(x)
	ETERM *x
CODE:
    RETVAL=ERL_IS_LIST(x);
OUTPUT:
    RETVAL

int _erl_int_value(x)
	ETERM *x
CODE:
    RETVAL=ERL_INT_VALUE(x);
OUTPUT:
    RETVAL

unsigned int _erl_int_uvalue(x)
	ETERM *x
CODE:
    RETVAL=ERL_INT_UVALUE(x);
OUTPUT:
    RETVAL

# long long
long _erl_ll_value(x)
	ETERM *x
CODE:
    RETVAL=ERL_LL_VALUE(x);
OUTPUT:
    RETVAL

# long long
long _erl_ll_uvalue(x)
	ETERM *x
CODE:
    RETVAL=ERL_LL_UVALUE(x);
OUTPUT:
    RETVAL


