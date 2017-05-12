
#define __KRB5_MECHTYPE_OID &mygss_mech_krb5
#define __KRB5_OLD_MECHTYPE_OID &mygss_mech_krb5_old
#define __SPNEGO_MECHTYPE_OID &myspnego_oid_desc
#define __GSS_KRB5_NT_USER_NAME &mygss_nt_krb5_name
#define __GSS_KRB5_NT_PRINCIPAL_NAME &mygss_nt_krb5_principal
#define __gss_mech_krb5_v2 &mygss_mech_krb5_v2

/*
|  Defines explanation:
|
|  SEAM
|  different structure of headerfiles on Solaris 10 / Opensolaris
|  Trigger for setting SEAM is 'Solaris' keyword in output
|  of krb5-config --version (See Makefile.PL)
|  See <http://rt.cpan.org/Public/Bug/Display.html?id=32788>
|
|  MITKERB12
|  MIT-kerbeors of version 1.2.x does not provide alls constants
|  of the uppercase GSS_C* style. Some tweaking is required.
|  Trigger for setting MITKERB12 is the version-number in output
|  of krb5-config --version (See Makefile.PL)
|
*/

#if defined(HEIMDAL)
#include <gssapi.h>
#endif

#if !defined(HEIMDAL)

#include <gssapi/gssapi.h>
#if !defined(SEAM)
#include <gssapi/gssapi_generic.h>
#include <gssapi/gssapi_krb5.h>
#else
#include <gssapi/gssapi_ext.h>
#endif
#if defined(MITKERB12)
/* symbols not defined in MIT Kerberos 1.2.x */
#define GSS_C_NT_USER_NAME gss_nt_user_name
#define GSS_C_NT_MACHINE_UID_NAME gss_nt_machine_uid_name
#define GSS_C_NT_STRING_UID_NAME gss_nt_string_uid_name
#define GSS_C_NT_HOSTBASED_SERVICE gss_nt_service_name
#define GSS_C_NT_EXPORT_NAME gss_nt_exported_name
#endif
#endif

/*

See
http://mailman.mit.edu/pipermail/krbdev/2005-February/003193.html
"
*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_newCONSTSUB
#include "ppport.h"

static gss_OID_desc  mygss_mech_krb5  = {9, (void *) "\x2a\x86\x48\x86\xf7\x12\x01\x02\x02"};
static gss_OID_desc  mygss_mech_krb5_old  = {5, (void *) "\x2b\x05\x01\x05\x02"};

static gss_OID_desc myspnego_oid_desc = {6, (void *) "\x2b\x06\x01\x05\x05\x02"};

static gss_OID_desc mygss_nt_krb5_name =  {10, (void *) "\052\206\110\206\367\022\001\002\002\001"};

static gss_OID_desc mygss_nt_krb5_principal = {10, (void *) "\052\206\110\206\367\022\001\002\002\002"};

static gss_OID_desc mygss_mech_krb5_v2 = {9, (void *) "\052\206\110\206\367\022\001\002\003"};



static double
constant(char *name, int len, int arg)
{
    warn("GSSAPI.xs - function constant() should never be called");
    return 0;

}



/*
 * These are not part of the GSSAPI C bindings, so we can't count on
 * them being defined.  They are part of the Kerberos 1.2 GSSAPI binding
 * so we'll provide them
 */

#ifndef GSS_CALLING_ERROR_FIELD
#define GSS_CALLING_ERROR_FIELD(x) \
   (((x) >> GSS_C_CALLING_ERROR_OFFSET) & GSS_C_CALLING_ERROR_MASK)
#endif
#ifndef GSS_ROUTINE_ERROR_FIELD
#define GSS_ROUTINE_ERROR_FIELD(x) \
   (((x) >> GSS_C_ROUTINE_ERROR_OFFSET) & GSS_C_ROUTINE_ERROR_MASK)
#endif
#ifndef GSS_SUPPLEMENTARY_INFO_FIELD
#define GSS_SUPPLEMENTARY_INFO_FIELD(x) \
   (((x) >> GSS_C_SUPPLEMENTARY_OFFSET) & GSS_C_SUPPLEMENTARY_MASK)
#endif


typedef struct {
    OM_uint32	major, minor;
} gss_status_desc;
typedef gss_status_desc			GSSAPI__Status;

typedef gss_name_t			GSSAPI__Name;
typedef gss_OID				GSSAPI__OID;
typedef gss_OID_set			GSSAPI__OID__Set;
typedef gss_cred_id_t			GSSAPI__Cred;
typedef gss_ctx_id_t			GSSAPI__Context;
typedef gss_channel_bindings_t		GSSAPI__Binding;

typedef const gss_OID_desc	*	GSSAPI__OID_const;
typedef const gss_OID_set_desc	*	GSSAPI__OID__Set_const;

typedef gss_ctx_id_t			GSSAPI__Context_Iopt;

typedef gss_name_t			GSSAPI__Name_out;
typedef gss_OID				GSSAPI__OID_out;
typedef gss_OID_set			GSSAPI__OID__Set_out;
typedef gss_cred_id_t			GSSAPI__Cred_out;
typedef gss_ctx_id_t			GSSAPI__Context_out;
typedef gss_channel_bindings_t		GSSAPI__Binding_out;
typedef I32				I32_out;
typedef int				int_out;
typedef gss_cred_usage_t		gss_cred_usage_t_out;
typedef U32				U32_out;
typedef OM_uint32			OM_uint32_out;

typedef gss_name_t		*	GSSAPI__Name_optout;
typedef gss_OID			*	GSSAPI__OID_optout;
typedef gss_OID_set		*	GSSAPI__OID__Set_optout;
typedef gss_cred_id_t		*	GSSAPI__Cred_optout;
typedef I32			*	I32_optout;
typedef int			*	int_optout;
typedef gss_cred_usage_t	*	gss_cred_usage_t_optout;
typedef U32			*	U32_optout;
typedef OM_uint32		*	OM_uint32_optout;

typedef gss_name_t			GSSAPI__Name_opt;
typedef gss_OID				GSSAPI__OID_opt;
typedef gss_OID_set			GSSAPI__OID__Set_opt;
typedef gss_channel_bindings_t		GSSAPI__Binding_opt;
typedef gss_cred_id_t			GSSAPI__Cred_opt;
typedef gss_ctx_id_t			GSSAPI__Context_opt;

typedef gss_buffer_desc			gss_buffer_desc_out;
typedef gss_buffer_desc			gss_buffer_desc_copy;
typedef gss_buffer_desc			gss_buffer_str;
typedef gss_buffer_desc			gss_buffer_str_out;

typedef void *				GSSAPI_obj;

typedef gss_buffer_desc         gss_oidstr_out;

int
oid_set_is_dynamic(GSSAPI__OID__Set oidset)
{
    return 1; /* 2006-02-13 all static sets are deleted */
}


MODULE = GSSAPI		PACKAGE = GSSAPI


BOOT:
{
   HV *stash = gv_stashpvn ("GSSAPI", 6, TRUE );
#if defined( GSS_C_ACCEPT )
   newCONSTSUB( stash, "GSS_C_ACCEPT", newSVuv( GSS_C_ACCEPT ) );
#endif
#if defined( GSS_C_AF_APPLETALK )
   newCONSTSUB( stash, "GSS_C_AF_APPLETALK", newSVuv( GSS_C_AF_APPLETALK ) );
#endif
#if defined( GSS_C_AF_BSC )
   newCONSTSUB( stash, "GSS_C_AF_BSC", newSVuv( GSS_C_AF_BSC ) );
#endif
#if defined( GSS_C_AF_CCITT )
   newCONSTSUB( stash, "GSS_C_AF_CCITT", newSVuv( GSS_C_AF_CCITT ) );
#endif
#if defined( GSS_C_AF_CHAOS )
   newCONSTSUB( stash, "GSS_C_AF_CHAOS", newSVuv( GSS_C_AF_CHAOS ) );
#endif
#if defined( GSS_C_AF_DATAKIT )
   newCONSTSUB( stash, "GSS_C_AF_DATAKIT", newSVuv( GSS_C_AF_DATAKIT ) );
#endif
#if defined( GSS_C_AF_DECnet )
   newCONSTSUB( stash, "GSS_C_AF_DECnet", newSVuv( GSS_C_AF_DECnet ) );
#endif
#if defined( GSS_C_AF_DLI )
   newCONSTSUB( stash, "GSS_C_AF_DLI", newSVuv( GSS_C_AF_DLI ) );
#endif
#if defined( GSS_C_AF_DSS )
   newCONSTSUB( stash, "GSS_C_AF_DSS", newSVuv( GSS_C_AF_DSS ) );
#endif
#if defined( GSS_C_AF_ECMA )
   newCONSTSUB( stash, "GSS_C_AF_ECMA", newSVuv( GSS_C_AF_ECMA ) );
#endif
#if defined( GSS_C_AF_HYLINK )
   newCONSTSUB( stash, "GSS_C_AF_HYLINK", newSVuv( GSS_C_AF_HYLINK ) );
#endif
#if defined( GSS_C_AF_IMPLINK )
   newCONSTSUB( stash, "GSS_C_AF_IMPLINK", newSVuv( GSS_C_AF_IMPLINK ) );
#endif
#if defined( GSS_C_AF_INET )
   newCONSTSUB( stash, "GSS_C_AF_INET", newSVuv( GSS_C_AF_INET ) );
#endif
#if defined( GSS_C_AF_LAT )
   newCONSTSUB( stash, "GSS_C_AF_LAT", newSVuv( GSS_C_AF_LAT ) );
#endif
#if defined( GSS_C_AF_LOCAL )
   newCONSTSUB( stash, "GSS_C_AF_LOCAL", newSVuv( GSS_C_AF_LOCAL ) );
#endif
#if defined( GSS_C_AF_NBS )
   newCONSTSUB( stash, "GSS_C_AF_NBS", newSVuv( GSS_C_AF_NBS ) );
#endif
#if defined( GSS_C_AF_NS )
   newCONSTSUB( stash, "GSS_C_AF_NS", newSVuv( GSS_C_AF_NS ) );
#endif
#if defined( GSS_C_AF_NULLADDR )
   newCONSTSUB( stash, "GSS_C_AF_NULLADDR", newSVuv( GSS_C_AF_NULLADDR ) );
#endif
#if defined( GSS_C_AF_OSI )
   newCONSTSUB( stash, "GSS_C_AF_OSI", newSVuv( GSS_C_AF_OSI ) );
#endif
#if defined( GSS_C_AF_PUP )
   newCONSTSUB( stash, "GSS_C_AF_PUP", newSVuv( GSS_C_AF_PUP ) );
#endif
#if defined( GSS_C_AF_SNA )
   newCONSTSUB( stash, "GSS_C_AF_SNA", newSVuv( GSS_C_AF_SNA ) );
#endif
#if defined( GSS_C_AF_UNSPEC )
   newCONSTSUB( stash, "GSS_C_AF_UNSPEC", newSVuv( GSS_C_AF_UNSPEC ) );
#endif
#if defined( GSS_C_AF_X25 )
   newCONSTSUB( stash, "GSS_C_AF_X25", newSVuv( GSS_C_AF_X25 ) );
#endif
#if defined( GSS_C_ANON_FLAG )
   newCONSTSUB( stash, "GSS_C_ANON_FLAG", newSVuv( GSS_C_ANON_FLAG ) );
#endif
#if defined( GSS_C_BOTH )
   newCONSTSUB( stash, "GSS_C_BOTH", newSVuv( GSS_C_BOTH ) );
#endif
#if defined( GSS_C_CALLING_ERROR_MASK )
   newCONSTSUB( stash, "GSS_C_CALLING_ERROR_MASK", newSVuv( GSS_C_CALLING_ERROR_MASK ) );
#endif
#if defined( GSS_C_CALLING_ERROR_OFFSET )
   newCONSTSUB( stash, "GSS_C_CALLING_ERROR_OFFSET", newSVuv( GSS_C_CALLING_ERROR_OFFSET ) );
#endif
#if defined( GSS_C_CONF_FLAG )
   newCONSTSUB( stash, "GSS_C_CONF_FLAG", newSVuv( GSS_C_CONF_FLAG ) );
#endif
#if defined( GSS_C_DELEG_FLAG )
   newCONSTSUB( stash, "GSS_C_DELEG_FLAG", newSVuv( GSS_C_DELEG_FLAG ) );
#endif
#if defined( GSS_C_GSS_CODE )
   newCONSTSUB( stash, "GSS_C_GSS_CODE", newSVuv( GSS_C_GSS_CODE ) );
#endif
#if defined( GSS_C_INDEFINITE )
   newCONSTSUB( stash, "GSS_C_INDEFINITE", newSVuv( GSS_C_INDEFINITE ) );
#endif
#if defined( GSS_C_INITIATE )
   newCONSTSUB( stash, "GSS_C_INITIATE", newSVuv( GSS_C_INITIATE ) );
#endif
#if defined( GSS_C_INTEG_FLAG )
   newCONSTSUB( stash, "GSS_C_INTEG_FLAG", newSVuv( GSS_C_INTEG_FLAG ) );
#endif
#if defined( GSS_C_MECH_CODE )
   newCONSTSUB( stash, "GSS_C_MECH_CODE", newSVuv( GSS_C_MECH_CODE ) );
#endif
#if defined( GSS_C_MUTUAL_FLAG )
   newCONSTSUB( stash, "GSS_C_MUTUAL_FLAG", newSVuv( GSS_C_MUTUAL_FLAG ) );
#endif
#if defined( GSS_C_PROT_READY_FLAG )
   newCONSTSUB( stash, "GSS_C_PROT_READY_FLAG", newSVuv( GSS_C_PROT_READY_FLAG ) );
#endif
#if defined( GSS_C_QOP_DEFAULT )
   newCONSTSUB( stash, "GSS_C_QOP_DEFAULT", newSVuv( GSS_C_QOP_DEFAULT ) );
#endif
#if defined( GSS_C_REPLAY_FLAG )
   newCONSTSUB( stash, "GSS_C_REPLAY_FLAG", newSVuv( GSS_C_REPLAY_FLAG ) );
#endif
#if defined( GSS_C_ROUTINE_ERROR_MASK )
   newCONSTSUB( stash, "GSS_C_ROUTINE_ERROR_MASK", newSVuv( GSS_C_ROUTINE_ERROR_MASK ) );
#endif
#if defined( GSS_C_ROUTINE_ERROR_OFFSET )
   newCONSTSUB( stash, "GSS_C_ROUTINE_ERROR_OFFSET", newSVuv( GSS_C_ROUTINE_ERROR_OFFSET ) );
#endif
#if defined( GSS_C_SEQUENCE_FLAG )
   newCONSTSUB( stash, "GSS_C_SEQUENCE_FLAG", newSVuv( GSS_C_SEQUENCE_FLAG ) );
#endif
#if defined( GSS_C_SUPPLEMENTARY_MASK )
   newCONSTSUB( stash, "GSS_C_SUPPLEMENTARY_MASK", newSVuv( GSS_C_SUPPLEMENTARY_MASK ) );
#endif
#if defined( GSS_C_SUPPLEMENTARY_OFFSET )
   newCONSTSUB( stash, "GSS_C_SUPPLEMENTARY_OFFSET", newSVuv( GSS_C_SUPPLEMENTARY_OFFSET ) );
#endif
#if defined( GSS_C_TRANS_FLAG )
   newCONSTSUB( stash, "GSS_C_TRANS_FLAG", newSVuv( GSS_C_TRANS_FLAG ) );
#endif
#if defined( GSS_S_BAD_BINDINGS )
   newCONSTSUB( stash, "GSS_S_BAD_BINDINGS", newSVuv( GSS_S_BAD_BINDINGS ) );
#endif
#if defined( GSS_S_BAD_MECH )
   newCONSTSUB( stash, "GSS_S_BAD_MECH", newSVuv( GSS_S_BAD_MECH ) );
#endif
#if defined( GSS_S_BAD_NAME )
   newCONSTSUB( stash, "GSS_S_BAD_NAME", newSVuv( GSS_S_BAD_NAME ) );
#endif
#if defined( GSS_S_BAD_NAMETYPE )
   newCONSTSUB( stash, "GSS_S_BAD_NAMETYPE", newSVuv( GSS_S_BAD_NAMETYPE ) );
#endif
#if defined( GSS_S_BAD_QOP )
   newCONSTSUB( stash, "GSS_S_BAD_QOP", newSVuv( GSS_S_BAD_QOP ) );
#endif
#if defined( GSS_S_BAD_SIG )
   newCONSTSUB( stash, "GSS_S_BAD_SIG", newSVuv( GSS_S_BAD_SIG ) );
#endif
#if defined( GSS_S_BAD_STATUS )
   newCONSTSUB( stash, "GSS_S_BAD_STATUS", newSVuv( GSS_S_BAD_STATUS ) );
#endif
#if defined( GSS_S_CALL_BAD_STRUCTURE )
   newCONSTSUB( stash, "GSS_S_CALL_BAD_STRUCTURE", newSVuv( GSS_S_CALL_BAD_STRUCTURE ) );
#endif
#if defined( GSS_S_CALL_INACCESSIBLE_READ )
   newCONSTSUB( stash, "GSS_S_CALL_INACCESSIBLE_READ", newSVuv( GSS_S_CALL_INACCESSIBLE_READ ) );
#endif
#if defined( GSS_S_CALL_INACCESSIBLE_WRITE )
   newCONSTSUB( stash, "GSS_S_CALL_INACCESSIBLE_WRITE", newSVuv( GSS_S_CALL_INACCESSIBLE_WRITE ) );
#endif
#if defined( GSS_S_COMPLETE )
   newCONSTSUB( stash, "GSS_S_COMPLETE", newSVuv( GSS_S_COMPLETE ) );
#endif
#if defined( GSS_S_CONTEXT_EXPIRED )
   newCONSTSUB( stash, "GSS_S_CONTEXT_EXPIRED", newSVuv( GSS_S_CONTEXT_EXPIRED ) );
#endif
#if defined( GSS_S_CONTINUE_NEEDED )
   newCONSTSUB( stash, "GSS_S_CONTINUE_NEEDED", newSVuv( GSS_S_CONTINUE_NEEDED ) );
#endif
#if defined( GSS_S_CREDENTIALS_EXPIRED )
   newCONSTSUB( stash, "GSS_S_CREDENTIALS_EXPIRED", newSVuv( GSS_S_CREDENTIALS_EXPIRED ) );
#endif
#if defined( GSS_S_CRED_UNAVAIL )
   newCONSTSUB( stash, "GSS_S_CRED_UNAVAIL", newSVuv( GSS_S_CRED_UNAVAIL ) );
#endif
#if defined( GSS_S_DEFECTIVE_CREDENTIAL )
   newCONSTSUB( stash, "GSS_S_DEFECTIVE_CREDENTIAL", newSVuv( GSS_S_DEFECTIVE_CREDENTIAL ) );
#endif
#if defined( GSS_S_DEFECTIVE_TOKEN )
   newCONSTSUB( stash, "GSS_S_DEFECTIVE_TOKEN", newSVuv( GSS_S_DEFECTIVE_TOKEN ) );
#endif
#if defined( GSS_S_DUPLICATE_ELEMENT )
   newCONSTSUB( stash, "GSS_S_DUPLICATE_ELEMENT", newSVuv( GSS_S_DUPLICATE_ELEMENT ) );
#endif
#if defined( GSS_S_DUPLICATE_TOKEN )
   newCONSTSUB( stash, "GSS_S_DUPLICATE_TOKEN", newSVuv( GSS_S_DUPLICATE_TOKEN ) );
#endif
#if defined( GSS_S_FAILURE )
   newCONSTSUB( stash, "GSS_S_FAILURE", newSVuv( GSS_S_FAILURE ) );
#endif
#if defined( GSS_S_GAP_TOKEN )
   newCONSTSUB( stash, "GSS_S_GAP_TOKEN", newSVuv( GSS_S_GAP_TOKEN ) );
#endif
#if defined( GSS_S_NAME_NOT_MN )
   newCONSTSUB( stash, "GSS_S_NAME_NOT_MN", newSVuv( GSS_S_NAME_NOT_MN ) );
#endif
#if defined( GSS_S_NO_CONTEXT )
   newCONSTSUB( stash, "GSS_S_NO_CONTEXT", newSVuv( GSS_S_NO_CONTEXT ) );
#endif
#if defined( GSS_S_NO_CRED )
   newCONSTSUB( stash, "GSS_S_NO_CRED", newSVuv( GSS_S_NO_CRED ) );
#endif
#if defined( GSS_S_OLD_TOKEN )
   newCONSTSUB( stash, "GSS_S_OLD_TOKEN", newSVuv( GSS_S_OLD_TOKEN ) );
#endif
#if defined( GSS_S_UNAUTHORIZED )
   newCONSTSUB( stash, "GSS_S_UNAUTHORIZED", newSVuv( GSS_S_UNAUTHORIZED ) );
#endif
#if defined( GSS_S_UNAVAILABLE )
   newCONSTSUB( stash, "GSS_S_UNAVAILABLE", newSVuv( GSS_S_UNAVAILABLE ) );
#endif
#if defined( GSS_S_UNSEQ_TOKEN )
   newCONSTSUB( stash, "GSS_S_UNSEQ_TOKEN", newSVuv( GSS_S_UNSEQ_TOKEN ) );
#endif
}


PROTOTYPES: ENABLE

int
gssapi_implementation_is_heimdal()
CODE:
#if defined(HEIMDAL)
      RETVAL = 1;
#endif
#if !defined(HEIMDAL)
      RETVAL = 0;
#endif
OUTPUT:
        RETVAL


double
constant(sv,arg)
    PREINIT:
	STRLEN		len;
    INPUT:
	SV *		sv
	char *		s = SvPV(sv, len);
	int		arg
    CODE:
	RETVAL = constant(s,len,arg);
    OUTPUT:
	RETVAL


GSSAPI::Status
indicate_mechs(oidset)
	GSSAPI::OID::Set_out	oidset
    CODE:
	RETVAL.major = gss_indicate_mechs(&RETVAL.minor, &oidset);
    OUTPUT:
	RETVAL
	oidset

bool
is_valid(object)
	GSSAPI_obj	object
    CODE:
	RETVAL = (object != NULL);
    OUTPUT:
	RETVAL


MODULE = GSSAPI		PACKAGE = GSSAPI::Status

INCLUDE: xs/Status.xs


MODULE = GSSAPI		PACKAGE = GSSAPI::Name

INCLUDE: xs/Name.xs


MODULE = GSSAPI		PACKAGE = GSSAPI::OID

INCLUDE: xs/OID.xs


MODULE = GSSAPI		PACKAGE = GSSAPI::OID::Set

INCLUDE: xs/OID__Set.xs


MODULE = GSSAPI		PACKAGE = GSSAPI::Cred

INCLUDE: xs/Cred.xs


MODULE = GSSAPI		PACKAGE = GSSAPI::Binding

INCLUDE: xs/Binding.xs


MODULE = GSSAPI		PACKAGE = GSSAPI::Context

INCLUDE: xs/Context.xs
