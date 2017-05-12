/*---------------------------------------------------------------------------------------------------*/
#include <unistd.h>
#include "list.h"

/*---------------------------------------------------------------------------------------------------*/

/** ARRAY store macros **/

#define AVS_H(arr, h)				av_push(arr, newRV((SV *)h))
#define AVS_A(arr, a)				av_push(arr, newRV((SV *)a))
#define AVS_I(arr, i)				av_push(arr, newSViv(i))
#define AVS_S(arr, s)				av_push(arr, newSVpv(s, 0))


/** HASH store macros **/

/* Use 'name' as structure field name AND HASH key name */
#define HVS(h, name, sv)		hv_store(h, #name, sizeof(#name)-1, sv, 0)
#define HVS_S(h, sp, name)		if (sp->name)      hv_store(h, #name, sizeof(#name)-1, newSVpv(sp->name, 0), 0)
#define HVS_I(h, sp, name)		if (sp->name >= 0) hv_store(h, #name, sizeof(#name)-1, newSViv(sp->name), 0)
#define HVS_BIT(h, var, name)	hv_store(h, #name, sizeof(#name)-1, newSViv(var & name ? 1 : 0), 0)

/* Specify the structure field name and HASH key name separately */
#define HVSN_S(h, sp, name, key)		if (sp->name)      hv_store(h, #key, sizeof(#key)-1, newSVpv(sp->name, 0), 0)
#define HVSN_I(h, sp, name, key)		if (sp->name >= 0) hv_store(h, #key, sizeof(#key)-1, newSViv(sp->name), 0)

/* Convert string before storing in hash */
#define HVS_STRING(h, sp, name)			hv_store(h, #name, sizeof(#name)-1, newSVpv(_to_string(sp->name), 0), 0)
#define HVS_STRING_STRIP(h, sp, name)	hv_store(h, #name, sizeof(#name)-1, newSVpv(_to_string_strip(sp->name), 0), 0)

/* non-struct member versions */
#define HVS_INT(h, name, i)		hv_store(h, #name, sizeof(#name)-1, newSViv(i), 0)
#define HVS_STR(h, name, s)		hv_store(h, #name, sizeof(#name)-1, newSVpv(s, 0), 0)


/** HASH read macros **/
#define HVF_I(hv,var)                                 \
  if ( (val = hv_fetch (hv, #var, sizeof (#var) - 1, 0)) ) { \
  	if ( val != NULL ) { \
      var = SvIV (*val); \
  	  if (DVBT_DEBUG) fprintf(stderr, " set %s = %d\n", #var, var); \
  	} \
  }

#define HVF_SV(hv,var)                                 \
  if ( (val = hv_fetch (hv, #var, sizeof (#var) - 1, 0)) ) { \
  	if ( val != NULL ) { \
      var = SvSV (*val); \
  	} \
  }

#define HVF_IV(hv,var,ival)                                 \
  if ( (val = hv_fetch (hv, #var, sizeof (#var) - 1, 0)) ) { \
  	if ( val != NULL ) { \
      ival = SvIV (*val); \
  	} \
  }

#define HVF_SVV(hv,var,sval)                                 \
  if ( (val = hv_fetch (hv, #var, sizeof (#var) - 1, 0)) ) { \
  	if ( val != NULL ) { \
      sval = (*val); \
  	} \
  }

#define HVF(hv, var)	hv_fetch (hv, #var, sizeof (#var) - 1, 0)


/* get the HASH ref using the specified key. If not currently set, then create a new HASH and add it to the parent */
#define GET_HREF(hv, key, var)                                \
  if ( (val = hv_fetch (hv, #key, sizeof (#key) - 1, 0)) ) { \
  	if ( val != NULL ) { \
      var = (HV *)sv_2mortal(*val); \
  	} \
  	else { \
  	  var = (HV *)sv_2mortal((SV *)newHV()); \
  	  hv_store(hv, #key, sizeof(#key)-1, newRV((SV *)var), 0) ; \
  	} \
  }


/*---------------------------------------------------------------------------------------------------*/
// Copies string into a static area so it can be used for creating Perl hash entries
#define TO_STRING_MAX		8191
static char ret_str[TO_STRING_MAX+1] ;
static char *_to_string(char *str)
{
int i, j, len = strlen(str);

   for (i=0, j=0; (i < len) && (i < TO_STRING_MAX); i++)
   {
	   ret_str[j++] = str[i] ;

	   /* terminate */
	   ret_str[j] = 0 ;
   }
   return ret_str ;
}

/*---------------------------------------------------------------------------------------------------*/
// Copies string into a static area so it can be used for creating Perl hash entries. Also strips out
// any invalid chars
static unsigned valid_char[0xff] ;
static unsigned valid_char_init = 0 ;
static char *_to_string_strip(char *str)
{
int i, j, len = strlen(str);

	// set up lookup table once
	if (!valid_char_init)
	{
		for (i=0; (i < 0xff); i++)
		{
			valid_char[i] = 0 ;
			if (
				((i >= ' ') && (i <= '~'))
				|| (i == '\n')
				|| (i == '\r')
				|| (i == 0)
			)
			{
				valid_char[i] = 1 ;
			}
		}
		valid_char_init = 1 ;
	}

	// copy valid chars to destination
	for (i=0, j=0; (i < len) && (i < TO_STRING_MAX); i++)
	{
		if (valid_char[(unsigned char)(str[i]) & 0xff])
		{
			ret_str[j++] = str[i] ;
		}

		/* terminate */
		ret_str[j] = 0 ;
	}
	return ret_str ;
}

