#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "Optimized_64bit/SHA3api_ref.h"
#include "Optimized_64bit/skein.h"

typedef Skein_256_Ctxt_t  * Digest__Skein__256;
typedef Skein_512_Ctxt_t  * Digest__Skein__512;
typedef Skein1024_Ctxt_t  * Digest__Skein__1024;

MODULE = Digest::Skein          PACKAGE = Digest::Skein         

PROTOTYPES: ENABLE

char *
Skein(hashbitlen, data)
		int   hashbitlen
		const BitSequence *     data
	PPCODE:
		if (hashbitlen < 0)
			croak("hashbitlen < 0");
	{
		BitSequence     hashval[128];
		char ret[256 + 1];
		int i;
		if ( Hash( hashbitlen, data, (DataLength) SvCUR(ST(1)) * 8, hashval ) != SUCCESS )
			croak("Hash() failed");
		for (i=0; i<hashbitlen/8; i++)
			sprintf(&ret[2*i], "%02X", hashval[i]);
		ST(0) = sv_2mortal(newSVpv(ret, hashbitlen/4));
		XSRETURN(1);
	}

char *
skein_256(data)
		const BitSequence *     data
	PPCODE:
	{
		BitSequence hashval[256/8];
		if ( Hash( 256, data, (DataLength) SvCUR(ST(0)) * 8, hashval ) != SUCCESS )
			croak("Hash(256) failed");
		ST(0) = sv_2mortal(newSVpv(hashval, 256/8));
		XSRETURN(1);
	}

char *
skein_512(data)
		const BitSequence *     data
	PPCODE:
	{
		char hashval[512/8];
		if ( Hash( 512, data, (DataLength) SvCUR(ST(0)) * 8, hashval ) != SUCCESS )
			croak("Hash(512) failed");
		ST(0) = sv_2mortal(newSVpv(hashval, 512/8));
		XSRETURN(1);
	}

char *
skein_1024(data)
		const BitSequence *     data
	PPCODE:
	{
		char hashval[1024/8];
		if ( Hash( 1024, data, (DataLength) SvCUR(ST(0)) * 8, hashval ) != SUCCESS )
			croak("Hash(1024) failed");
		ST(0) = sv_2mortal(newSVpv(hashval, 1024/8));
		XSRETURN(1);
	}


MODULE = Digest::Skein          PACKAGE = Digest::Skein::256

Digest::Skein::256
clone(ctx)
		Digest::Skein::256  ctx
    PREINIT:
		Skein_256_Ctxt_t *dest;
	CODE:
		Newx(dest, 1, Skein_256_Ctxt_t);
		memcpy(dest, ctx, sizeof(*dest));
		RETVAL = dest;
	OUTPUT:
		RETVAL

Digest::Skein::256
new(package, hashbitlen=256)
		SV* package
		int hashbitlen
	PPCODE:
		if (hashbitlen > 256)
			croak("hashbitlen > 256");
		if (SvROK(package)) {	/* called as $digest->new or $digest->reset */
			IV tmp;
			Digest__Skein__256	ctx;
			if (! sv_derived_from(package, "Digest::Skein::256"))
				croak("meh.");
			tmp = SvIV((SV*)SvRV(package));
			ctx = INT2PTR(Digest__Skein__256, tmp);
			if ( Skein_256_Init( ctx, items==2 ? hashbitlen : ctx->h.hashBitLen ) != SUCCESS )
				croak("Init() failed");
			RETVAL = ctx;
		}
		else {
			Skein_256_Ctxt_t *ctx;
			Newx(ctx, 1, Skein_256_Ctxt_t);
			if ( Skein_256_Init(ctx, hashbitlen) != SUCCESS )
				croak("Init() failed");
			ST(0) = sv_newmortal();
			sv_setref_pv(ST(0), "Digest::Skein::256", (void*)ctx);
		}
		XSRETURN(1);

int
hashbitlen(ctx)
		Digest::Skein::256  ctx
	CODE:
		RETVAL = ctx->h.hashBitLen;
	OUTPUT:
		RETVAL

void
DESTROY(ctx)
		Digest::Skein::256  ctx
	CODE:
		Safefree(ctx);

Digest::Skein::256
add(ctx, data, ...)
		Digest::Skein::256  ctx
		const u08b_t *	data = NO_INIT
	CODE:
	{
		int i;
		for (i=1; i<items; i++)
			if ( Skein_256_Update(ctx, (const u08b_t *)SvPV_nolen(ST(i)), SvCUR(ST(i))) != SUCCESS )
				croak("Update() failed");
		RETVAL = ctx;
	}

char *
digest(ctx)
		Digest::Skein::256  ctx
	PPCODE:
	{
		char hashval[256/8];
		int len = (ctx->h.hashBitLen + 7) >> 3;
		if ( Skein_256_Final(ctx, hashval) != SUCCESS )
			croak("final() failed");
		if ( Skein_256_Init(ctx, ctx->h.hashBitLen) != SUCCESS ) /* reset */
			croak("Init() failed");
		ST(0) = sv_2mortal(newSVpv(hashval, len));
		XSRETURN(1);
	}





MODULE = Digest::Skein          PACKAGE = Digest::Skein::512

Digest::Skein::512
clone(ctx)
		Digest::Skein::512  ctx
    PREINIT:
		Skein_512_Ctxt_t *dest;
	CODE:
		Newx(dest, 1, Skein_512_Ctxt_t);
		memcpy(dest, ctx, sizeof(*dest));
		RETVAL = dest;
	OUTPUT:
		RETVAL

Digest::Skein::512
new(package, hashbitlen=512)
		SV* package
		int hashbitlen
	PPCODE:
		if (hashbitlen > 512)
			croak("hashbitlen > 512");
		if (SvROK(package)) {	/* called as $digest->new or $digest->reset */
			IV tmp;
			Digest__Skein__512	ctx;
			if (! sv_derived_from(package, "Digest::Skein::512"))
				croak("meh.");
			tmp = SvIV((SV*)SvRV(package));
			ctx = INT2PTR(Digest__Skein__512, tmp);
			if ( Skein_512_Init( ctx, items==2 ? hashbitlen : ctx->h.hashBitLen ) != SUCCESS )
				croak("Init() failed");
			RETVAL = ctx;
		}
		else {
			Skein_512_Ctxt_t *ctx;
			Newx(ctx, 1, Skein_512_Ctxt_t);
			if ( Skein_512_Init(ctx, hashbitlen) != SUCCESS )
				croak("Init() failed");
			ST(0) = sv_newmortal();
			sv_setref_pv(ST(0), "Digest::Skein::512", (void*)ctx);
		}
		XSRETURN(1);

int
hashbitlen(ctx)
		Digest::Skein::512  ctx
	CODE:
		RETVAL = ctx->h.hashBitLen;
	OUTPUT:
		RETVAL

void
DESTROY(ctx)
		Digest::Skein::512  ctx
	CODE:
		Safefree(ctx);

Digest::Skein::512
add(ctx, data, ...)
		Digest::Skein::512  ctx
		const u08b_t *	data = NO_INIT
	CODE:
	{
		int i;
		for (i=1; i<items; i++)
			if ( Skein_512_Update(ctx, (const u08b_t *)SvPV_nolen(ST(i)), SvCUR(ST(i))) != SUCCESS )
				croak("Update() failed");
		RETVAL = ctx;
	}

char *
digest(ctx)
		Digest::Skein::512  ctx
	PPCODE:
	{
		char hashval[512/8];
		int len = (ctx->h.hashBitLen + 7) >> 3;
		if ( Skein_512_Final(ctx, hashval) != SUCCESS )
			croak("final() failed");
		if ( Skein_512_Init(ctx, ctx->h.hashBitLen) != SUCCESS ) /* reset */
			croak("Init() failed");
		ST(0) = sv_2mortal(newSVpv(hashval, len));
		XSRETURN(1);
	}



MODULE = Digest::Skein          PACKAGE = Digest::Skein::1024

Digest::Skein::1024
clone(ctx)
		Digest::Skein::1024  ctx
    PREINIT:
		Skein1024_Ctxt_t *dest;
	CODE:
		Newx(dest, 1, Skein1024_Ctxt_t);
		memcpy(dest, ctx, sizeof(*dest));
		RETVAL = dest;
	OUTPUT:
		RETVAL

Digest::Skein::1024
new(package, hashbitlen=1024)
		SV* package
		int hashbitlen
	PPCODE:
		if (hashbitlen > 1024)
			croak("hashbitlen > 1024");
		if (SvROK(package)) {	/* called as $digest->new or $digest->reset */
			IV tmp;
			Digest__Skein__1024	ctx;
			if (! sv_derived_from(package, "Digest::Skein::1024"))
				croak("meh.");
			tmp = SvIV((SV*)SvRV(package));
			ctx = INT2PTR(Digest__Skein__1024, tmp);
			if ( Skein1024_Init( ctx, items==2 ? hashbitlen : ctx->h.hashBitLen ) != SUCCESS )
				croak("Init() failed");
			RETVAL = ctx;
		}
		else {
			Skein1024_Ctxt_t *ctx;
			Newx(ctx, 1, Skein1024_Ctxt_t);
			if ( Skein1024_Init(ctx, hashbitlen) != SUCCESS )
				croak("Init() failed");
			ST(0) = sv_newmortal();
			sv_setref_pv(ST(0), "Digest::Skein::1024", (void*)ctx);
		}
		XSRETURN(1);

int
hashbitlen(ctx)
		Digest::Skein::1024  ctx
	CODE:
		RETVAL = ctx->h.hashBitLen;
	OUTPUT:
		RETVAL

void
DESTROY(ctx)
		Digest::Skein::1024  ctx
	CODE:
		Safefree(ctx);

Digest::Skein::1024
add(ctx, data, ...)
		Digest::Skein::1024  ctx
		const u08b_t *	data = NO_INIT
	CODE:
	{
		int i;
		for (i=1; i<items; i++)
			if ( Skein1024_Update(ctx, (const u08b_t *)SvPV_nolen(ST(i)), SvCUR(ST(i))) != SUCCESS )
				croak("Update() failed");
		RETVAL = ctx;
	}

char *
digest(ctx)
		Digest::Skein::1024  ctx
	PPCODE:
	{
		char hashval[1024/8];
		int len = (ctx->h.hashBitLen + 7) >> 3;
		if ( Skein1024_Final(ctx, hashval) != SUCCESS )
			croak("final() failed");
		if ( Skein1024_Init(ctx, ctx->h.hashBitLen) != SUCCESS ) /* reset */
			croak("Init() failed");
		ST(0) = sv_2mortal(newSVpv(hashval, len));
		XSRETURN(1);
	}



# vim: ts=4 sw=4 noet si
