#include "ppport.h"
GSSAPI::Status
new(class, major, minor)
	char	*class
	U32	major
	U32	minor
    CODE:
	RETVAL.major = major;
	RETVAL.minor = minor;
    OUTPUT:
	RETVAL

U32
major(status)
	GSSAPI::Status	status
    CODE:
	RETVAL = status.major;
    OUTPUT:
	RETVAL

U32
minor(status)
	GSSAPI::Status	status
    CODE:
	RETVAL = status.minor;
    OUTPUT:
	RETVAL

U32
GSS_CALLING_ERROR(code)
	U32	code

U32
GSS_ROUTINE_ERROR(code)
	U32	code

U32
GSS_SUPPLEMENTARY_INFO(code)
	U32	code

bool
GSS_ERROR(code)
	U32	code
    CODE:
	RETVAL = GSS_ERROR(code) != 0;
    OUTPUT:
	RETVAL

U32
GSS_CALLING_ERROR_FIELD(code)
	U32	code

U32
GSS_ROUTINE_ERROR_FIELD(code)
	U32	code

U32
GSS_SUPPLEMENTARY_INFO_FIELD(code)
	U32	code

void
display_status(code, type)
	U32		code
	int		type
    PREINIT:
	OM_uint32	major_status, minor_status;
	unsigned int	msg_ctx;
	gss_buffer_desc	msg;
    PPCODE:
	msg_ctx = 0;
	do {
	    major_status =
		gss_display_status(&minor_status, code, type,
				   GSS_C_NO_OID, &msg_ctx, &msg);
	    if (GSS_ERROR(major_status)) {
		gss_release_buffer(&minor_status, &msg);
		break;
	    }
	    XPUSHs(sv_2mortal(newSVpvn(msg.value, msg.length)));
	    gss_release_buffer(&minor_status, &msg);
	} while (msg_ctx);

