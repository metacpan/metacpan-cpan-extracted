#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_newRV_noinc
#define NEED_sv_2pvbyte
#define NEED_sv_2pv_flags

#include "ppport.h"

#undef warn

#include <fido.h>
#include <fido/es256.h>
#include <fido/rs256.h>
#include <fido/eddsa.h>

#ifndef MUTABLE_AV
#define MUTABLE_AV(p) ((AV *)MUTABLE_PTR(p))
#endif

/* internally generated errors */
#define ASSERT            -10000
#define USAGE             -10001
#define RESOLVE           -10002

/* internally generated classes */
#define INTERNAL          -20000

#ifdef _MSC_VER
#pragma warning (disable : 4244 4267 )
#endif

#include "constants.h"

typedef fido_assert_t *Assert;
typedef fido_cred_t *Cred;
typedef es256_pk_t *PublicKey_ES256;
typedef rs256_pk_t *PublicKey_RS256;
typedef eddsa_pk_t *PublicKey_EDDSA;

#define FIDO_NEW_OBJ(rv, class, sv)				\
	STMT_START {						\
		(rv) = sv_setref_pv(newSV(0), class, sv);	\
	} STMT_END


MODULE = FIDO::Raw			PACKAGE = FIDO::Raw

BOOT:
	fido_init (0);

INCLUDE: const-xs-constant.inc

INCLUDE: xs/Assert.xs
INCLUDE: xs/Cred.xs
INCLUDE: xs/PublicKey/ES256.xs
INCLUDE: xs/PublicKey/EDDSA.xs
INCLUDE: xs/PublicKey/RS256.xs

