GSSAPI::Name_out
new(class)
	char *	class
    CODE:
	RETVAL = NULL;
    OUTPUT:
	RETVAL

void
DESTROY(name)
	GSSAPI::Name_opt	name
    PREINIT:
	OM_uint32		minor;
    CODE:
	if (name != NULL) {
	    (void)gss_release_name(&minor, &name);
	}


GSSAPI::Status
import(class, dest, name, ...)
	char *			class
	GSSAPI::Name_out	dest
	gss_buffer_str		name
    PREINIT:
	GSSAPI__OID	nametype = GSS_C_NO_OID;
    PROTOTYPE: $$$;$
    CODE:
	if (items > 3) {
	    if (! SvOK(ST(3))) {
		/* do nothing */
	    } else if (sv_isa(ST(3), "GSSAPI::OID")) {
		SV *tmp = SvRV(ST(3));
		nametype = (GSSAPI__OID) SvIV(tmp);
	    } else {
		croak("nametype is not of type GSSAPI::OID");
	    }
	}
	RETVAL.major =
		gss_import_name(&RETVAL.minor, &name, nametype, &dest);
    OUTPUT:
	RETVAL
	dest


GSSAPI::Status
duplicate(src, dest)
	GSSAPI::Name_opt	src
	GSSAPI::Name_out	dest
    CODE:
	RETVAL.major = gss_duplicate_name(&RETVAL.minor, src, &dest);
    OUTPUT:
	RETVAL
	dest


GSSAPI::Status
display(src, output, ...)
	GSSAPI::Name_opt	src
	gss_buffer_str_out	output
    PROTOTYPE: $$;$
    CODE:
	if (items > 2) {
	    GSSAPI__OID	outputtype = GSS_C_NO_OID;
	    RETVAL.major =
		gss_display_name(&RETVAL.minor, src, &output, &outputtype);
	    sv_setref_pvn(ST(2), "GSSAPI::OID", (void*)&outputtype,
						0 );
	} else {
	    RETVAL.major = gss_display_name(&RETVAL.minor, src, &output, NULL);
	}
    OUTPUT:
	RETVAL
	output


GSSAPI::Status
compare(arg1, arg2, ret)
	GSSAPI::Name_opt	arg1
	GSSAPI::Name_opt	arg2
	int_out			ret
    CODE:
	RETVAL.major = gss_compare_name(&RETVAL.minor, arg1, arg2, &ret);
    OUTPUT:
	RETVAL
	ret


#	This is not actually implemented in the gssapi_krb5 library
#GSSAPI::Status
#inquire_mechs(name, oidset)
#	GSSAPI::Name		name
#	GSSAPI::OID::Set	oidset
#    CODE:
#	RETVAL.major =
#		gss_inquire_mechs_for_name(&RETVAL.minor, name, &oidset);
#    OUTPUT:
#	RETVAL
#	oidset


GSSAPI::Status
canonicalize(src, type, dest)
	GSSAPI::Name_opt	src
	GSSAPI::OID		type
	GSSAPI::Name_out	dest
    CODE:
	RETVAL.major = gss_canonicalize_name(&RETVAL.minor, src, type, &dest);
    OUTPUT:
	RETVAL
	dest


GSSAPI::Status
export(name, output)
	GSSAPI::Name_opt	name
	gss_buffer_str_out	output
    CODE:
	RETVAL.major = gss_export_name(&RETVAL.minor, name, &output);
    OUTPUT:
	RETVAL
	output

