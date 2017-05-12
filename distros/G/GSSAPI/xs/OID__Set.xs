GSSAPI::OID::Set_out
new(class)
	char *	class
    PREINIT:
	OM_uint32	minor_status;
    CODE:
	if (GSS_ERROR(gss_create_empty_oid_set(&minor_status, &RETVAL))) {
	    XSRETURN_UNDEF;
	}
    OUTPUT:
	RETVAL

void
DESTROY(oidset)
	GSSAPI::OID::Set	oidset
    PREINIT:
	OM_uint32	minor;
    CODE:
	if (oidset != 0 && oid_set_is_dynamic(oidset)) {
	    (void)gss_release_oid_set(&minor, &oidset);
	}

GSSAPI::Status
insert(oidset, oid)
	GSSAPI::OID::Set	oidset
	GSSAPI::OID		oid
    CODE:
	if (! oid_set_is_dynamic(oidset)) {
	    croak("oidset is not alterable");
	}
	RETVAL.major = gss_add_oid_set_member(&RETVAL.minor, oid, &oidset);
    OUTPUT:
	RETVAL

GSSAPI::Status
contains(oidset, oid, isthere)
	GSSAPI::OID::Set	oidset
	GSSAPI::OID		oid
	int			isthere
    CODE:
	RETVAL.major = gss_test_oid_set_member(&RETVAL.minor,
						oid, oidset, &isthere);
    OUTPUT:
	RETVAL
	isthere


#
#	Kerberos OID_sets
#

#GSSAPI::OID::Set_const
#gss_mech_set_krb5()
#    CODE:
#	RETVAL = gss_mech_set_krb5;
#    OUTPUT:
#	RETVAL

#GSSAPI::OID::Set_const
#gss_mech_set_krb5_old()
#    CODE:
#	RETVAL = gss_mech_set_krb5_old;
#    OUTPUT:
#	RETVAL

#GSSAPI::OID::Set_const
#gss_mech_set_krb5_both()
#    CODE:
#	RETVAL = gss_mech_set_krb5_both;
#    OUTPUT:
#	RETVAL

# Achim Grolms, 2006-02-04
# deleted this function, it makes the compile
# fail, I don't know if this function is useful
#

#GSSAPI::OID::Set_const
#gss_mech_set_krb5_v2()
#    CODE:
#	RETVAL = gss_mech_set_krb5_v2;
#    OUTPUT:
#	RETVAL

# Achim Grolms, 2006-02-04
# deleted this function, it makes the compile
# fail, I don't know if this function is useful
#
#GSSAPI::OID::Set_const
#gss_mech_set_krb5_v1v2()
#    CODE:
#	RETVAL = gss_mech_set_krb5_v1v2;
#    OUTPUT:
#	RETVAL

