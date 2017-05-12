
GSSAPI::Context_out
new(class)
	char *	class
    CODE:
	RETVAL = 0;
    OUTPUT:
	RETVAL

void
DESTROY(context)
	GSSAPI::Context_opt	context
    PREINIT:
	OM_uint32		minor;
	OM_uint32		major;
    CODE:
	if (context != NULL) {

	    major = gss_delete_sec_context(&minor, &context, GSS_C_NO_BUFFER);
	    if ( major == GSS_S_FAILURE) {
	       warn("failed gss_delete_sec_context(), GSS_S_FAILURE, module Context.xs");
	    }
	}

GSSAPI::Status
init(context, cred, name, in_mech, in_flags, in_time, binding, in_token, out_mech, out_token, out_flags, out_time)
	GSSAPI::Context_opt	context
	GSSAPI::Cred_opt	cred
	GSSAPI::Name		name
	GSSAPI::OID_opt		in_mech
	OM_uint32		in_flags
	OM_uint32		in_time
	GSSAPI::Binding_opt	binding
	gss_buffer_desc		in_token
    PREINIT:
	GSSAPI__OID		out_mech_real;
	OM_uint32		out_flags_real;
	OM_uint32		out_time_real;
    INPUT:
	GSSAPI::OID_optout	out_mech
	gss_buffer_desc_out	out_token
	OM_uint32_optout	out_flags
	OM_uint32_optout	out_time
    CODE:
	RETVAL.major =
		gss_init_sec_context(&RETVAL.minor, cred, &context, name,
				     in_mech, in_flags, in_time, binding,
				     &in_token, out_mech, &out_token,
				     out_flags, out_time);
    OUTPUT:
	RETVAL
	context
	out_mech
	out_token
	out_flags
	out_time

GSSAPI::Status
accept(context, acc_cred, in_token, binding, out_name, out_mech, out_token, out_flags, out_time, delegated_cred)
	GSSAPI::Context_opt	context
	GSSAPI::Cred_opt	acc_cred
	gss_buffer_desc		in_token
	GSSAPI::Binding_opt	binding
    PREINIT:
	GSSAPI__Name		out_name_real;
	GSSAPI__OID		out_mech_real;
	OM_uint32		out_flags_real;
	OM_uint32		out_time_real;
	GSSAPI__Cred		delegated_cred_real;
    INPUT:
	GSSAPI::Name_optout	out_name
	GSSAPI::OID_optout	out_mech
	gss_buffer_desc_out	out_token
	OM_uint32_optout	out_flags
	OM_uint32_optout	out_time
	GSSAPI::Cred_optout	delegated_cred
    CODE:
	RETVAL.major =
		gss_accept_sec_context(&RETVAL.minor, &context, acc_cred,
				       &in_token, binding, out_name, out_mech,
				       &out_token, out_flags, out_time,
				       delegated_cred);
    OUTPUT:
	RETVAL
	context
	out_name
	out_mech
	out_token
	out_flags
	out_time
	delegated_cred

GSSAPI::Status
delete(context, out_token)
	GSSAPI::Context_opt	context
	gss_buffer_desc_out	out_token
    CODE:
	if (context != NULL) {
	    RETVAL.major = gss_delete_sec_context(&RETVAL.minor, &context,
						  &out_token);
	} else {
	    RETVAL.major = GSS_S_COMPLETE;
	    RETVAL.minor = 0;
	}
    OUTPUT:
	RETVAL
	context
	out_token

GSSAPI::Status
process_token(context, token)
	GSSAPI::Context		context
	gss_buffer_desc		token
    CODE:
	RETVAL.major =
		gss_process_context_token(&RETVAL.minor, context, &token);
    OUTPUT:
	RETVAL

GSSAPI::Status
valid_time_left(context, out_time)
	GSSAPI::Context		context
    PREINIT:
	OM_uint32		out_time_real;
    INPUT:
	OM_uint32_optout	out_time
    CODE:
	RETVAL.major = gss_context_time(&RETVAL.minor, context, out_time);
    OUTPUT:
	RETVAL
	out_time

GSSAPI::Status
wrap_size_limit(context, flags, qop, req_output_size, max_input_size)
	GSSAPI::Context		context
	OM_uint32		flags
	OM_uint32		qop
	OM_uint32		req_output_size
    PREINIT:
	OM_uint32		max_input_size_real;
    INPUT:
	OM_uint32_optout	max_input_size
    CODE:
	RETVAL.major =
		gss_wrap_size_limit(&RETVAL.minor, context, flags, qop,
				    req_output_size, max_input_size);
    OUTPUT:
	RETVAL
	max_input_size


GSSAPI::Status
inquire(context, src_name, targ_name, lifetime, mech, flags, locally_initiated, open)
	GSSAPI::Context		context;
    PREINIT:
	GSSAPI__Name		src_name_real;
	GSSAPI__Name		targ_name_real;
	OM_uint32		lifetime_real;
	GSSAPI__OID		mech_real;
	OM_uint32		flags_real;
	int			locally_initiated_real;
	int			open_real;
    INPUT:
	GSSAPI::Name_optout	src_name
	GSSAPI::Name_optout	targ_name
	OM_uint32_optout	lifetime
	GSSAPI::OID_optout	mech
	OM_uint32_optout	flags
	int_optout		locally_initiated
	int_optout		open
    CODE:
	RETVAL.major =
		gss_inquire_context(&RETVAL.minor, context, src_name,
				    targ_name, lifetime, mech, flags,
				    locally_initiated, open);
    OUTPUT:
	RETVAL
	src_name
	targ_name
	lifetime
	mech
	flags
	locally_initiated
	open

GSSAPI::Status
export(context, token)
	GSSAPI::Context		context
	gss_buffer_desc_out	token
    CODE:
	RETVAL.major = gss_export_sec_context(&RETVAL.minor, &context, &token);
    OUTPUT:
	RETVAL
	context
	token

GSSAPI::Status
import(class, context, token)
	char *			class
	GSSAPI::Context_out	context
	gss_buffer_desc		token
    CODE:
	RETVAL.major = gss_import_sec_context(&RETVAL.minor, &token, &context);
    OUTPUT:
	RETVAL
	context

GSSAPI::Status
get_mic(context, qop, buffer, token)
	GSSAPI::Context		context
	OM_uint32		qop
	gss_buffer_desc		buffer
	gss_buffer_desc_out	token
    CODE:
	RETVAL.major =
		gss_get_mic(&RETVAL.minor, context, qop, &buffer, &token);
    OUTPUT:
	RETVAL
	token

GSSAPI::Status
verify_mic(context, buffer, token, qop)
	GSSAPI::Context		context
	gss_buffer_desc		buffer
	gss_buffer_desc		token
    PREINIT:
	OM_uint32		qop_real;
    INPUT:
	OM_uint32_optout	qop
    CODE:
	RETVAL.major =
		gss_verify_mic(&RETVAL.minor, context, &buffer, &token, qop);
    OUTPUT:
	RETVAL
	qop

GSSAPI::Status
wrap(context, conf_flag, qop, in_buffer, conf_state, out_buffer)
	GSSAPI::Context		context
	int			conf_flag
	OM_uint32		qop
	gss_buffer_desc		in_buffer
    PREINIT:
	int			conf_state_real;
    INPUT:
	int_optout		conf_state
	gss_buffer_desc_out	out_buffer
    CODE:
	RETVAL.major = gss_wrap(&RETVAL.minor, context, conf_flag, qop,
				&in_buffer, conf_state, &out_buffer);
    OUTPUT:
	RETVAL
	conf_state
	out_buffer

GSSAPI::Status
unwrap(context, in_buffer, out_buffer, conf_state, qop)
	GSSAPI::Context		context
	gss_buffer_desc		in_buffer
	gss_buffer_desc_out	out_buffer
    PREINIT:
	int			conf_state_real;
	OM_uint32		qop_real;
    INPUT:
	int_optout		conf_state
	OM_uint32_optout	qop
    CODE:
	RETVAL.major = gss_unwrap(&RETVAL.minor, context, &in_buffer,
				  &out_buffer, conf_state, qop);
    OUTPUT:
	RETVAL
	out_buffer
	conf_state
	qop
