
GSSAPI::Status
acquire_cred(name, in_time, in_mechs, cred_usage, cred, out_mechs, out_time)
	GSSAPI::Name_opt	name
	OM_uint32		in_time
	GSSAPI::OID::Set_opt	in_mechs
	int			cred_usage
    PREINIT:
	GSSAPI__Cred		cred_real;
	GSSAPI__OID__Set	out_mechs_real;
	OM_uint32		out_time_real;
    INPUT:
	GSSAPI::Cred_optout	cred
	GSSAPI::OID::Set_optout	out_mechs
	OM_uint32_optout	out_time
    CODE:
	RETVAL.major =
	    gss_acquire_cred(&RETVAL.minor, name, in_time, in_mechs,
			     cred_usage, cred, out_mechs, out_time);
    OUTPUT:
	RETVAL
	cred
	out_mechs
	out_time


GSSAPI::Status
add_cred(in_cred, name, in_mech, cred_usage, in_init_time, in_acc_time, out_cred, out_mechs, out_init_time, out_acc_time)
	GSSAPI::Cred_opt	in_cred
	GSSAPI::Name		name
	GSSAPI::OID		in_mech
	int			cred_usage
	OM_uint32		in_init_time
	OM_uint32		in_acc_time
    PREINIT:
	GSSAPI__Cred		out_cred_real;
	GSSAPI__OID__Set	out_mechs_real;
	OM_uint32		out_init_time_real;
	OM_uint32		out_acc_time_real;
    INPUT:
	GSSAPI::Cred_optout	out_cred
	GSSAPI::OID::Set_optout	out_mechs
	OM_uint32_optout	out_init_time
	OM_uint32_optout	out_acc_time
    CODE:
	RETVAL.major =
	    gss_add_cred(&RETVAL.minor, in_cred, name, in_mech, cred_usage,
			 in_init_time, in_acc_time, out_cred,
			 out_mechs, out_init_time, out_acc_time);
    OUTPUT:
	RETVAL
	out_cred
	out_mechs
	out_init_time
	out_acc_time

GSSAPI::Status
inquire_cred(cred, name, lifetime, cred_usage, mechs)
	GSSAPI::Cred_opt	cred
    PREINIT:
	GSSAPI__Name		name_real;
	OM_uint32		lifetime_real;
	gss_cred_usage_t	cred_usage_real;
	GSSAPI__OID__Set	mechs_real;
    INPUT:
	GSSAPI::Name_optout	name
	OM_uint32_optout	lifetime
	gss_cred_usage_t_optout	cred_usage
	GSSAPI::OID::Set_optout	mechs
    CODE:
	RETVAL.major = gss_inquire_cred(&RETVAL.minor, cred, name,
					lifetime, cred_usage, mechs);
    OUTPUT:
	RETVAL
	name
	lifetime
	cred_usage
	mechs

GSSAPI::Status
inquire_cred_by_mech(cred, mech, name, init_lifetime, acc_lifetime, cred_usage)
	GSSAPI::Cred_opt	cred
	GSSAPI::OID		mech
    PREINIT:
	GSSAPI__Name		name_real;
	OM_uint32		init_lifetime_real;
	OM_uint32		acc_lifetime_real;
	gss_cred_usage_t	cred_usage_real;
    INPUT:
	GSSAPI::Name_optout	name
	OM_uint32_optout	init_lifetime
	OM_uint32_optout	acc_lifetime
	gss_cred_usage_t_optout	cred_usage
    CODE:
	RETVAL.major = gss_inquire_cred_by_mech(&RETVAL.minor, cred, mech,
						name, init_lifetime,
						acc_lifetime, cred_usage);
    OUTPUT:
	RETVAL
	name
	init_lifetime
	acc_lifetime
	cred_usage

# 2006-02-06
# addeed destructor, thanks to Merijn Broeren!
#
void
DESTROY(cred)
        GSSAPI::Cred_opt     cred
    PREINIT:
        OM_uint32               minor;
	OM_uint32		major;
    CODE:
        if (cred != NULL) {
            major = gss_release_cred(&minor, &cred);
	    if ( major != GSS_S_COMPLETE) {
	       warn("failed gss_release_cred() module Cred.xs");
	    }
        }

