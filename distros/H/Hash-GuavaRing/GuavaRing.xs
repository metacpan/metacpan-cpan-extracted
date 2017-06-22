#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/////////////////////////// guava-hash code ///////////////////////////////
int guava(long state, unsigned int buckets);

static const long
	K   = 2862933555777941757L;

static const double
	D   = 0x1.0p31;

int guava(long state, unsigned int buckets) {
	int candidate = 0;
	int next;
	while (1) {
		state = K * state + 1;
		next = (int) ( (double) (candidate + 1) / ( (double)( (int)( (long unsigned) state >> 33 ) + 1 ) / D ) );
		if ( ( next >= 0 ) && ( next < buckets )) {
			candidate = next;
		} else {
			return candidate;
		}
	}
}


/////////////////////// END guava-hash code ///////////////////////////////

#ifndef likely
#define likely(x)       __builtin_expect(!!(x), 1)
#define unlikely(x)     __builtin_expect(!!(x), 0)
#endif

typedef struct {
	SV * self;
	HV * stash;
	AV * nodes;
} GuavaRing;

#define svstrcmp(a,b) strcmp(SvPV_nolen(a),b)

MODULE = Hash::GuavaRing		PACKAGE = Hash::GuavaRing

void new(...)
	PPCODE:
		if (items < 1) croak("Usage: %s->new(...)",SvPV_nolen(ST(0)));
		GuavaRing * self = (GuavaRing *) safemalloc( sizeof(GuavaRing) );
		if (unlikely(!self)) croak("Failed to allocate memory");
		memset(self,0,sizeof(GuavaRing));
		self->stash = gv_stashpv(SvPV_nolen(ST(0)), TRUE);
		{
			SV *iv = newSViv(PTR2IV( self ));
			self->self = sv_bless(newRV_noinc (iv), self->stash);
			ST(0) = sv_2mortal(self->self);
		}
		int i;
		SV **key;
		AV *nodes = 0;
		for ( i=1; i < items; i=i+2) {
			if ( !svstrcmp(ST(i),"nodes") ) {
				if (SvROK(ST(i+1)) && SvTYPE(SvRV(ST(i+1))) == SVt_PVAV) {
					nodes = (AV *) SvRV( ST(i+1) );
				} else {
					croak("nodes must be arrayref, but got %s", SvPV_nolen(ST(i+1)));
				}
			}
			else {
				croak("Uknown option '%s'", SvPV_nolen(ST(i)));
			}
		}
		self->nodes = newAV();
		for ( i = 0; i <= av_len(nodes); i++ ) {
			key = av_fetch( nodes, i, 0 );
			av_store(self->nodes, i, SvREFCNT_inc(*key));
		}

		XSRETURN(1);

void DESTROY(SV *)
	PPCODE:
		register GuavaRing *self = ( GuavaRing * ) SvUV( SvRV( ST(0) ) );
		if (self->nodes) SvREFCNT_dec(self->nodes);
		if (self->self && SvOK(self->self) && SvOK( SvRV(self->self) )) {
			SvREFCNT_inc(SvRV(self->self));
			SvREFCNT_dec(self->self);
		}
		safefree(self);
		XSRETURN_UNDEF;

void get (SV *, SV * key)
	PPCODE:
		register GuavaRing *self = ( GuavaRing * ) SvUV( SvRV( ST(0) ) );
		// fprintf(stderr,"\nav_len(self->nodes) = %i\n",av_len(self->nodes));
		int idx = guava( SvIV(key), av_len(self->nodes)+1 );

		SV **node = av_fetch(self->nodes, idx, 0);

		ST(0) = *node;
		XSRETURN(1);
