#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <math.h>

/* Simple vector type */
typedef struct {
	double x;
	double y;
	double z;
} vec3_t;

static vec3_t vec3_add(vec3_t a, vec3_t b) {
	vec3_t r;
	r.x = a.x + b.x;
	r.y = a.y + b.y;
	r.z = a.z + b.z;
	return r;
}

static double vec3_dot(vec3_t a, vec3_t b) {
	return a.x * b.x + a.y * b.y + a.z * b.z;
}

static vec3_t vec3_cross(vec3_t a, vec3_t b) {
	vec3_t r;
	r.x = a.y * b.z - a.z * b.y;
	r.y = a.z * b.x - a.x * b.z;
	r.z = a.x * b.y - a.y * b.x;
	return r;
}

static double vec3_length(vec3_t v) {
	return sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
}

static vec3_t vec3_normalize(vec3_t v) {
	double len = vec3_length(v);
	vec3_t r;
	if (len > 0.0) {
		r.x = v.x / len;
		r.y = v.y / len;
		r.z = v.z / len;
	} else {
		r.x = r.y = r.z = 0.0;
	}
	return r;
}

MODULE = Sample::Vec3  PACKAGE = Sample::Vec3

PROTOTYPES: DISABLE

BOOT:
	/* Register constants at load time */
	HV *stash = gv_stashpv("Sample::Vec3", GV_ADD);
	newCONSTSUB(stash, "PI", newSVnv(3.14159265358979));

SV *
new(class, x, y, z)
	const char *class
	double x
	double y
	double z
	PREINIT:
		vec3_t *vec;
	CODE:
		Newx(vec, 1, vec3_t);
		vec->x = x;
		vec->y = y;
		vec->z = z;
		RETVAL = sv_newmortal();
		sv_setref_pv(RETVAL, class, (void *)vec);
		SvREFCNT_inc(RETVAL);
	OUTPUT:
		RETVAL

double
length(self)
	SV *self
	PREINIT:
		vec3_t *vec;
	CODE:
		if (!sv_isobject(self))
			croak("Not an object");
		vec = INT2PTR(vec3_t *, SvIV(SvRV(self)));
		RETVAL = vec3_length(*vec);
	OUTPUT:
		RETVAL

SV *
add(self, other)
	SV *self
	SV *other
	PREINIT:
		vec3_t *a;
		vec3_t *b;
		vec3_t *result;
		vec3_t sum;
	CODE:
		a = INT2PTR(vec3_t *, SvIV(SvRV(self)));
		b = INT2PTR(vec3_t *, SvIV(SvRV(other)));
		sum = vec3_add(*a, *b);
		Newx(result, 1, vec3_t);
		*result = sum;
		RETVAL = sv_newmortal();
		sv_setref_pv(RETVAL, "Sample::Vec3", (void *)result);
		SvREFCNT_inc(RETVAL);
	OUTPUT:
		RETVAL

double
dot(self, other)
	SV *self
	SV *other
	PREINIT:
		vec3_t *a;
		vec3_t *b;
	CODE:
		a = INT2PTR(vec3_t *, SvIV(SvRV(self)));
		b = INT2PTR(vec3_t *, SvIV(SvRV(other)));
		RETVAL = vec3_dot(*a, *b);
	OUTPUT:
		RETVAL

SV *
normalize(self)
	SV *self
	PREINIT:
		vec3_t *vec;
		vec3_t *result;
		vec3_t norm;
	CODE:
		vec = INT2PTR(vec3_t *, SvIV(SvRV(self)));
		norm = vec3_normalize(*vec);
		Newx(result, 1, vec3_t);
		*result = norm;
		RETVAL = sv_newmortal();
		sv_setref_pv(RETVAL, "Sample::Vec3", (void *)result);
		SvREFCNT_inc(RETVAL);
	OUTPUT:
		RETVAL

void
DESTROY(self)
	SV *self
	PREINIT:
		vec3_t *vec;
	CODE:
		vec = INT2PTR(vec3_t *, SvIV(SvRV(self)));
		Safefree(vec);

double
x(self)
	SV *self
	ALIAS:
		y = 1
		z = 2
	PREINIT:
		vec3_t *vec;
	CODE:
		vec = INT2PTR(vec3_t *, SvIV(SvRV(self)));
		switch (ix) {
			case 0: RETVAL = vec->x; break;
			case 1: RETVAL = vec->y; break;
			case 2: RETVAL = vec->z; break;
			default: RETVAL = 0.0;
		}
	OUTPUT:
		RETVAL
