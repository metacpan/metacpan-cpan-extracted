#include "ppport.h"
GSSAPI::OID_out
new(class)
	char *		class
    CODE:
	RETVAL = NULL;
    OUTPUT:
	RETVAL

void
DESTROY(oid)
	GSSAPI::OID	oid
    PREINIT:
	OM_uint32	minor;
    PPCODE:
#if !defined(HEIMDAL)
	if (oid != NULL &&
	    oid != __KRB5_MECHTYPE_OID &&
	    oid != __KRB5_OLD_MECHTYPE_OID &&
	    oid != __GSS_KRB5_NT_USER_NAME &&
	    oid != __GSS_KRB5_NT_PRINCIPAL_NAME &&
	    oid != __SPNEGO_MECHTYPE_OID &&
	    oid != __gss_mech_krb5_v2  ) {
	    (void)gss_release_oid(&minor, &oid);
	}
#endif
#if defined(HEIMDAL)
#    warn("gss_release_oid is unsupported and not Part of the API!");
#endif

GSSAPI::Status
from_str(class, oid, str)
	char *		class
	GSSAPI::OID_out	oid
	gss_buffer_str	str
    CODE:
#if !defined(HEIMDAL)
	RETVAL.major = gss_str_to_oid(&RETVAL.minor, &str, &oid);
#endif
#if defined(HEIMDAL)
	croak("gss_str_to_oid() is not defined in Heimdal API!");
#endif
    OUTPUT:
	RETVAL
	oid

GSSAPI::Status
to_str(oid, str)
	GSSAPI::OID		oid
	gss_oidstr_out	str
    CODE:
	if (oid == NULL) {
	    sv_setsv_mg(ST(1), &PL_sv_undef);
	    XSRETURN_UNDEF;
	}
#if !defined(HEIMDAL)
	RETVAL.major = gss_oid_to_str(&RETVAL.minor, oid, &str);
#endif
#if defined(HEIMDAL)
	croak("gss_oid_to_str() is not defined in Heimdal API!");
#endif
    OUTPUT:
	RETVAL
	str

GSSAPI::Status
inquire_names(oid, oidset)
	GSSAPI::OID		oid
	GSSAPI::OID::Set_out	oidset
    CODE:
	RETVAL.major =
		gss_inquire_names_for_mech(&RETVAL.minor, oid, &oidset);
    OUTPUT:
	RETVAL
	oidset


#
#	generic OIDs
#

GSSAPI::OID_const
gss_nt_user_name()
    CODE:
	RETVAL = GSS_C_NT_USER_NAME;
    OUTPUT:
	RETVAL

GSSAPI::OID_const
gss_nt_machine_uid_name()
    CODE:
	RETVAL = GSS_C_NT_MACHINE_UID_NAME;
    OUTPUT:
	RETVAL

GSSAPI::OID_const
gss_nt_string_uid_name()
    CODE:
	RETVAL =  GSS_C_NT_STRING_UID_NAME;
    OUTPUT:
	RETVAL

GSSAPI::OID_const
gss_nt_service_name()
    CODE:
	RETVAL = GSS_C_NT_HOSTBASED_SERVICE;
    OUTPUT:
	RETVAL

GSSAPI::OID_const
gss_nt_exported_name()
    CODE:
	RETVAL = GSS_C_NT_EXPORT_NAME;
    OUTPUT:
	RETVAL

GSSAPI::OID_const
gss_nt_service_name_v2()
    CODE:
	RETVAL = GSS_C_NT_HOSTBASED_SERVICE;
    OUTPUT:
	RETVAL


#
#	Kerberos OIDs
#

GSSAPI::OID_const
gss_nt_krb5_name()
    CODE:
	RETVAL = __GSS_KRB5_NT_USER_NAME;
    OUTPUT:
	RETVAL

GSSAPI::OID_const
gss_nt_krb5_principal()
    CODE:
	RETVAL = __GSS_KRB5_NT_PRINCIPAL_NAME;
    OUTPUT:
	RETVAL

GSSAPI::OID_const
gss_mech_krb5()
    CODE:
	RETVAL = __KRB5_MECHTYPE_OID;
    OUTPUT:
	RETVAL

GSSAPI::OID_const
gss_mech_spnego()
    CODE:
	RETVAL = __SPNEGO_MECHTYPE_OID;
    OUTPUT:
	RETVAL

GSSAPI::OID_const
gss_mech_krb5_old()
    CODE:
	RETVAL = __KRB5_OLD_MECHTYPE_OID;
    OUTPUT:
	RETVAL

GSSAPI::OID_const
gss_mech_krb5_v2()
    CODE:
	RETVAL = __gss_mech_krb5_v2;
    OUTPUT:
	RETVAL

GSSAPI::OID_const
gss_nt_hostbased_service()
     CODE:
        RETVAL = GSS_C_NT_HOSTBASED_SERVICE;
     OUTPUT:
        RETVAL
