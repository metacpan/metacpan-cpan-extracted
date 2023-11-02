#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <math.h>

#if !defined(__cplusplus) && defined(_MSC_VER) && _MSC_VER < 1900
#  define inline __inline
#endif

/**********************************************************************************************\
* m3s API, defining all the math for this module.
\**********************************************************************************************/

struct m3s_space;
typedef struct m3s_space m3s_space_t;
typedef struct m3s_space *m3s_space_or_null;

#define SPACE_XV(s)     ((s)->mat + 0)
#define SPACE_YV(s)     ((s)->mat + 3)  
#define SPACE_ZV(s)     ((s)->mat + 6)
#define SPACE_ORIGIN(s) ((s)->mat + 9)
struct m3s_space {
	NV mat[12];
	int is_normal; // -1=UNKNOWN, 0=FALSE, 1=TRUE
	// These pointers must be refreshed by m3s_space_recache_parent
	// before they can be used after any control flow outside of XS.
	struct m3s_space *parent;
	int n_parents;
};

static const m3s_space_t m3s_identity= {
	{ 1,0,0, 0,1,0, 0,0,1, 0,0,0 },
	1,
	NULL,
	0,
};

typedef NV m3s_vector_t[3];
typedef NV *m3s_vector_p;

static const NV NV_tolerance = 1e-14;

// Initialize to identity, known to be normal
void m3s_space_init(m3s_space_t *space) {
	memcpy(space, &m3s_identity, sizeof(*space));
}

// Vector cross product, C = A cross B
static inline void m3s_vector_cross(NV *dest, NV *vec1, NV *vec2) {
	dest[0]= vec1[1]*vec2[2] - vec1[2]*vec2[1];
	dest[1]= vec1[2]*vec2[0] - vec1[0]*vec2[2];
	dest[2]= vec1[0]*vec2[1] - vec1[1]*vec2[0];
}

// Vector dot Product, N = A dot B
static inline NV m3s_vector_dotprod(NV *vec1, NV *vec2) {
	NV mag, prod;
	mag= (vec1[0]*vec1[0] + vec1[1]*vec1[1] + vec1[2]*vec1[2])
	   * (vec2[0]*vec2[0] + vec2[1]*vec2[1] + vec2[2]*vec2[2]);
	prod= vec1[0]*vec2[0] + vec1[1]*vec2[1] + vec1[2]*vec2[2];
	if (mag < NV_tolerance)
		croak("Can't calculate dot product of vector with length == 0");
	else if (fabs(mag - 1) > NV_tolerance)
		prod /= sqrt(mag);
	return prod;
}

/* Check whether a space's axis vectors are unit length and orthagonal to
 * eachother, and update the 'is_normal' flag on the space.
 * Having this flag = 1 can optimize relative rotations later.
 * The flag gets set to -1 any time an operation may have broken normality.
 * Approx Cost: 4-19 load, 3-18 mul, 4-17 add, 1-2 stor
 */
static int m3s_space_check_normal(m3s_space_t *sp) {
	sp->is_normal= 0;
	for (NV *vec= sp->mat+6, *pvec= sp->mat; vec > sp->mat; pvec= vec, vec -= 3) {
		if (fabs(vec[0]*vec[0] + vec[1]*vec[1] + vec[2]*vec[2] - 1) > NV_tolerance)
			return 0;
		if ((vec[0]*pvec[0] + vec[1]*pvec[1] + vec[2]*pvec[2]) > NV_tolerance)
			return 0;
	}
	return sp->is_normal= 1;
}

/* Project a vector from the parent coordinate space into this coordinate space.
 * The vector is modified in-place.  The origin is not subtracted from a vector,
 * as opposed to projecting a point (below)
 * Approx Cost: 12 load, 9 mul, 6 add, 3 stor
 */
static inline void m3s_space_project_vector(m3s_space_t *sp, NV *vec) {
	NV x= vec[0], y= vec[1], z= vec[2], *mat= sp->mat;
	vec[0]= x * mat[0] + y * mat[1] + z * mat[2];
	vec[1]= x * mat[3] + y * mat[4] + z * mat[5];
	vec[2]= x * mat[6] + y * mat[7] + z * mat[8];
}

/* Project a point from the parent coordinate space into this coordinate space.
 * The point is modified in-place.
 * Approx Cost: 15 load, 9 fmul, 9 fadd, 3 stor
 */
static inline void m3s_space_project_point(m3s_space_t *sp, NV *vec) {
	NV x, y, z, *mat= sp->mat;
	x= vec[0] - mat[9];
	y= vec[1] - mat[10];
	z= vec[2] - mat[11];
	vec[0]= x * mat[0] + y * mat[1] + z * mat[2];
	vec[1]= x * mat[3] + y * mat[4] + z * mat[5];
	vec[2]= x * mat[6] + y * mat[7] + z * mat[8];
}

/* Project a sibling coordinate space into this coordinate space.
 * (sibling meaning they share the same parent coordinate space)
 * The sibling will now be a child coordinate space.
 * Approx Cost: 53 load, 33 fmul, 27 fadd, 14 stor
 */
static void m3s_space_project_space(m3s_space_t *sp, m3s_space_t *peer) {
	m3s_space_project_vector(sp, SPACE_XV(peer));
	m3s_space_project_vector(sp, SPACE_YV(peer));
	m3s_space_project_vector(sp, SPACE_ZV(peer));
	m3s_space_project_point(sp, SPACE_ORIGIN(peer));
	peer->parent= sp;
	peer->n_parents= sp->n_parents + 1;
}

/* Un-project a local vector of this coordinate space out to the parent
 * coordinate space.  The vector remains a directional vector, without
 * getting the origin point added to it.
 * Approx Cost: 12 load, 9 fmul, 6 fadd, 3 stor
 */
static inline void m3s_space_unproject_vector(m3s_space_t *sp, NV *vec) {
	NV x= vec[0], y= vec[1], z= vec[2], *mat= sp->mat;
	vec[0]= x * mat[0] + y * mat[3] + z * mat[6];
	vec[1]= x * mat[1] + y * mat[4] + z * mat[7];
	vec[2]= x * mat[2] + y * mat[5] + z * mat[8];
}

/* Un-project a local point of this coordinate space out to the parent
 * coordinate space.
 * Approx Cost: 15 load, 9 fmul, 9 fadd, 3 stor
 */
static inline void m3s_space_unproject_point(m3s_space_t *sp, NV *vec) {
	NV x= vec[0], y= vec[1], z= vec[2], *mat= sp->mat;
	vec[0]= x * mat[0] + y * mat[3] + z * mat[6] + mat[9];
	vec[1]= x * mat[1] + y * mat[4] + z * mat[7] + mat[10];
	vec[2]= x * mat[2] + y * mat[5] + z * mat[8] + mat[11];
}

/* Un-project a child coordinate space out of this coordinate space so that it
 * will become a peer of this space (sharing a parent)
 * Approx Cost: 53 load, 33 fmul, 27 fadd, 14 stor
 */
static void m3s_space_unproject_space(m3s_space_t *sp, m3s_space_t *inner) {
	m3s_space_unproject_vector(sp, SPACE_XV(inner));
	m3s_space_unproject_vector(sp, SPACE_YV(inner));
	m3s_space_unproject_vector(sp, SPACE_ZV(inner));
	m3s_space_unproject_point(sp, SPACE_ORIGIN(inner));
	inner->parent= sp->parent;
	inner->n_parents= sp->n_parents;
}

/* Assuming the ->parent pointer cache is current but the ->n_parent is not,
 * this walks down the linked list (twice) and updates it.
 */
static void m3s_space_recache_n_parents(m3s_space_t *space) {
	m3s_space_t *cur;
	int depth= -1;
	for (cur= space; cur; cur= cur->parent)
		++depth;
	for (cur= space; cur; cur= cur->parent)
		cur->n_parents= depth--;
	if (!(depth == -1)) croak("assertion failed: depth == -1");
}

/* Given two spaces (with valid ->parent caches) project/unproject the space so that
 * it represents the same global coordinates while now being described in terms of
 * a new parent coordinate space.  'parent' may be NULL, to move 'space' to become a
 * top-level space
 * MUST call m3s_space_recache_parent on each (non null) space before calling this method!
 */
static void m3s_space_reparent(m3s_space_t *space, m3s_space_t *parent) {
	m3s_space_t sp_tmp, *common_parent;
	// Short circuit for nothing to do
	if (space->parent == parent)
		return;
	// Walk back the stack of "from" until it has fewer parents than dest.
	// This way dest->parent has a chance to be "from".
	common_parent= parent;
	while (common_parent && common_parent->n_parents >= space->n_parents)
		common_parent= common_parent->parent;
	// Now unproject 'space' from each of its parents until its parent is "common_parent".
	while (space->n_parents && space->parent != common_parent) {
		// Map dest out to be a sibling of its parent
		m3s_space_unproject_space(space->parent, space);
		// back up common_parent one more time, if dest reached it
		if (common_parent && common_parent->n_parents + 1 == space->n_parents)
			common_parent= common_parent->parent;
	}
	// At this point, 'dest' is either a root 3Space, or common_parent is its parent.
	// If the common parent is the original from_space, then we're done.
	if (parent != common_parent) {
		// Calculate what from_space would be at this parent depth.
		if (!(parent != NULL)) croak("assertion failed: parent != NULL");
		memcpy(&sp_tmp, parent, sizeof(sp_tmp));
		while (sp_tmp.parent != common_parent)
			m3s_space_unproject_space(sp_tmp.parent, &sp_tmp);
		// sp_tmp is now equivalent to projecting through the chain from common_parent to parent
		m3s_space_project_space(&sp_tmp, space);
		space->parent= parent;
		space->n_parents= parent->n_parents + 1;
	}
	// Note that any space which has 'space' as a parent will now have an invalid n_parents
	// cache, which is why those caches need rebuilt before calling this function.
}

/* Rotate the space around an arbitrary vector in the parent space.
 * Angle is provided as direct sine and cosine factors.
 * The axis does not need to be a normal vector.
 * Approx Cost: 87-99 fmul, 1-2 fdiv, 56-62 fadd, 1 fabs, 1-2 sqrt
 */
static void m3s_space_rotate(m3s_space_t *space, NV angle_sin, NV angle_cos, m3s_vector_p axis) {
	NV mag_sq, scale, *vec, tmp0, tmp1;
	m3s_space_t r;

	// Construct temporary coordinate space where 'zv' is 'axis'
	mag_sq= axis[0]*axis[0] + axis[1]*axis[1] + axis[2]*axis[2];
	if (mag_sq == 0)
		croak("Can't rotate around vector with 0 magnitude");
	scale= (fabs(mag_sq - 1) > NV_tolerance)? 1/sqrt(mag_sq) : 1;
	r.mat[6]= axis[0] * scale;
	r.mat[7]= axis[1] * scale;
	r.mat[8]= axis[2] * scale;
	// set y vector to any vector not colinear with z vector
	r.mat[3]= 1;
	r.mat[4]= 0;
	r.mat[5]= 0;
	// x = normalize( y cross z )
	m3s_vector_cross(r.mat, r.mat+3, r.mat+6);
	mag_sq= r.mat[0]*r.mat[0] + r.mat[1]*r.mat[1] + r.mat[2]*r.mat[2];
	if (mag_sq < NV_tolerance) {
		// try again with a different vector
		r.mat[3]= 0;
		r.mat[4]= 1;
		m3s_vector_cross(r.mat, r.mat+3, r.mat+6);
		mag_sq= r.mat[0]*r.mat[0] + r.mat[1]*r.mat[1] + r.mat[2]*r.mat[2];
		if (mag_sq == 0)
			croak("BUG: failed to find perpendicular vector");
	}
	scale= 1 / sqrt(mag_sq);
	r.mat[0] *= scale;
	r.mat[1] *= scale;
	r.mat[2] *= scale;
	// y = z cross x (and should be normalized already because right angles)
	m3s_vector_cross(r.mat+3, r.mat+6, r.mat+0);
	// Now for each axis vector, project it into this space, rotate it (around Z), and project it back out
	for (vec=space->mat + 6; vec >= space->mat; vec-= 3) {
		m3s_space_project_vector(&r, vec);
		tmp0= angle_cos * vec[0] - angle_sin * vec[1];
		tmp1= angle_sin * vec[0] + angle_cos * vec[1];
		vec[0]= tmp0;
		vec[1]= tmp1;
		m3s_space_unproject_vector(&r, vec);
	}
}

/* Rotate the space around one of its own axes.  axis_idx: 0 (xv), 1 (yv) or 2 (zv)
 * Angle is supplied as direct sine / cosine values.
 * If the space is_normal (unit-length vectors orthagonal to eachother) this uses a very
 * efficient optimization.  Else it falls back to the full m3s_space_rotate function.
 * Approx Cost, if normal: 18 fmul, 12 fadd
 * Approx Cost, else:      87-99 fmul, 1-2 fdiv, 56-62 fadd, 1 fabs, 1-2 sqrt
 */
static void m3s_space_self_rotate(m3s_space_t *space, NV angle_sin, NV angle_cos, int axis_idx) {
	m3s_vector_t vec1, vec2;

	if (space->is_normal == -1)
		m3s_space_check_normal(space);
	if (!space->is_normal) {
		m3s_space_rotate(space, angle_sin, angle_cos, space->mat + axis_idx*3);
	} else {
		// Axes are all unit vectors, orthagonal to eachother, and can skip setting up a
		// custom rotation matrix.  Just define the vectors inside the space post-rotation,
		// then project them out of the space.
		if (axis_idx == 0) { // around XV, Y -> Z
			vec1[0]= 0; vec1[1]=  angle_cos; vec1[2]= angle_sin;
			m3s_space_unproject_vector(space, vec1);
			vec2[0]= 0; vec2[1]= -angle_sin; vec2[2]= angle_cos;
			m3s_space_unproject_vector(space, vec2);
			memcpy(SPACE_YV(space), vec1, sizeof(vec1));
			memcpy(SPACE_ZV(space), vec2, sizeof(vec2));
		} else if (axis_idx == 1) { // around YV, Z -> X
			vec1[0]= angle_sin; vec1[1]= 0; vec1[2]= angle_cos;
			m3s_space_unproject_vector(space, vec1);
			vec2[0]= angle_cos; vec2[1]= 0; vec2[2]= -angle_sin;
			m3s_space_unproject_vector(space, vec2);
			memcpy(SPACE_ZV(space), vec1, sizeof(vec1));
			memcpy(SPACE_XV(space), vec2, sizeof(vec2));
		} else { // around ZV, X -> Y
			vec1[0]=  angle_cos; vec1[1]= angle_sin; vec1[2]= 0;
			m3s_space_unproject_vector(space, vec1);
			vec2[0]= -angle_sin; vec2[1]= angle_cos; vec2[2]= 0;
			m3s_space_unproject_vector(space, vec2);
			memcpy(SPACE_XV(space), vec1, sizeof(vec1));
			memcpy(SPACE_YV(space), vec2, sizeof(vec2));
		}
	}
}

/**********************************************************************************************\
* Typemap code that converts from Perl objects to C structs and back
* All instances of Math::3Space have a magic-attached struct m3s_space_t
* All vectors objects are a blessed scalar ref aligned to hold double[3] in the PV
\**********************************************************************************************/

// destructor for m3s_space_t magic
static int m3s_space_magic_free(pTHX_ SV* sv, MAGIC* mg) {
	if (mg->mg_ptr) {
		Safefree(mg->mg_ptr);
		mg->mg_ptr= NULL;
	}
    return 0; // ignored anyway
}
#ifdef USE_ITHREADS
// If threading system needs to clone a Space, clone the struct but don't bother
// fixing the parent cache.  That should always pass through code that calls
// m3s_space_recache_parent between when this happens and when ->parent gets used.
static int m3s_space_magic_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *param) {
    m3s_space_t *space;
	PERL_UNUSED_VAR(param);
	Newxz(space, 1, m3s_space_t);
	memcpy(space, mg->mg_ptr, sizeof(m3s_space_t));
	space->parent= NULL; // ensure no possibility of cross-thread bugs
	mg->mg_ptr= (char*) space;
    return 0;
};
#else
#define m3s_space_magic_dup NULL
#endif

// magic virtual method table for m3s_space
// Pointer to this struct is also used as an ID for type of magic
static MGVTBL m3s_space_magic_vt= {
	NULL, /* get */
	NULL, /* write */
	NULL, /* length */
	NULL, /* clear */
	m3s_space_magic_free,
	NULL, /* copy */
	m3s_space_magic_dup
#ifdef MGf_LOCAL
	,NULL
#endif
};

// Return the m3s_space struct attached to a Perl object via MAGIC.
// The 'obj' should be a reference to a blessed SV.
// Use AUTOCREATE to attach magic and allocate a struct if it wasn't present.
// Use OR_DIE for a built-in croak() if the return value would be NULL.
#define AUTOCREATE 1
#define OR_DIE     2
static m3s_space_t* m3s_get_magic_space(SV *obj, int flags) {
	SV *sv;
	MAGIC* magic;
	m3s_space_t *space;
	if (!sv_isobject(obj)) {
		if (flags & OR_DIE)
			croak("Not an object");
		return NULL;
	}
	sv= SvRV(obj);
	if (SvMAGICAL(sv)) {
		/* Iterate magic attached to this scalar, looking for one with our vtable */
		for (magic= SvMAGIC(sv); magic; magic = magic->mg_moremagic)
			if (magic->mg_type == PERL_MAGIC_ext && magic->mg_virtual == &m3s_space_magic_vt)
				/* If found, the mg_ptr points to the fields structure. */
				return (m3s_space_t*) magic->mg_ptr;
	}
	if (flags & AUTOCREATE) {
		Newx(space, 1, m3s_space_t);
		m3s_space_init(space);
		magic= sv_magicext(sv, NULL, PERL_MAGIC_ext, &m3s_space_magic_vt, (const char*) space, 0);
#ifdef USE_ITHREADS
		magic->mg_flags |= MGf_DUP;
#endif
		return space;
	}
	else if (flags & OR_DIE)
		croak("Object lacks 'm3s_space_t' magic");
	return NULL;
}

// Create a new Math::3Space object, to become the owner of the supplied space struct.
// Returned SV is a reference with active refcount, which is what the typemap
// wants for returning a "m3s_space_t*" to perl-land
static SV* m3s_wrap_space(m3s_space_t *space) {
	SV *obj;
	MAGIC *magic;
	// Since this is used in typemap, handle NULL gracefully
	if (!space)
		return &PL_sv_undef;
	// Create a node object
	obj= newRV_noinc((SV*)newHV());
	sv_bless(obj, gv_stashpv("Math::3Space", GV_ADD));
	magic= sv_magicext(SvRV(obj), NULL, PERL_MAGIC_ext, &m3s_space_magic_vt, (const char*) space, 0);
#ifdef USE_ITHREADS
	magic->mg_flags |= MGf_DUP;
#else
	(void)magic; // suppress warning
#endif
	return obj;
}

// This code assumes that 8-byte alignment is good enough even if the NV type is
//  long double
#define NV_ALIGNMENT_MASK 7
static void m3s_make_aligned_buffer(SV *buf, size_t size) {
	char *p;
	STRLEN len;

	if (!SvPOK(buf))
		sv_setpvs(buf, "");
	p= SvPV(buf, len);
	if (len < size) {
		SvGROW(buf, size);
		SvCUR_set(buf, size);
		p= SvPVX(buf);
	}
	// ensure double alignment
	if ((intptr_t)p & NV_ALIGNMENT_MASK) {
		SvGROW(buf, size + NV_ALIGNMENT_MASK);
		p= SvPVX(buf);
		sv_chop(buf, p + NV_ALIGNMENT_MASK+1 - ((intptr_t)p & NV_ALIGNMENT_MASK));
		SvCUR_set(buf, size);
	}
}

// Create a new Math::3Space::Vector object, which is a blessed scalar-ref containing
// the aligned bytes of three NV (usually doubles)
static SV* m3s_wrap_vector(m3s_vector_p vec_array) {
	SV *obj, *buf;
	buf= newSVpvn((char*) vec_array, sizeof(NV)*3);
	if ((intptr_t)SvPVX(buf) & NV_ALIGNMENT_MASK) {
		m3s_make_aligned_buffer(buf, sizeof(NV)*3);
		memcpy(SvPVX(buf), vec_array, sizeof(NV)*3);
	}
	obj= newRV_noinc(buf);
	sv_bless(obj, gv_stashpv("Math::3Space::Vector", GV_ADD));
	return obj;
}

// Return a pointer to the aligned NV[3] inside the scalar ref 'vector'.
// These can be written directly to modify the vector's value.
static NV * m3s_vector_get_array(SV *vector) {
	char *p= NULL;
	STRLEN len= 0;
	if (sv_isobject(vector) && SvPOK(SvRV(vector)))
		p= SvPV(SvRV(vector), len);
	if (len != sizeof(NV)*3 || ((intptr_t)p & NV_ALIGNMENT_MASK) != 0)
		croak("Invalid or corrupt Math::3Space::Vector object");
	return (NV*) p;
}

// Read the values of a vector out of perl data 'in' and store them in 'vec'
// This should be extended to handle any sensible format a user might supply vectors.
// It currently supports arrayref-of-SvNV and vector objects.
static void m3s_read_vector_from_sv(m3s_vector_p vec, SV *in) {
	SV **el;
	AV *vec_av;
	HV *attrs;
	size_t i, n;
	if (SvROK(in) && SvTYPE(SvRV(in)) == SVt_PVAV) {
		vec_av= (AV*) SvRV(in);
		n= av_len(vec_av)+1;
		if (n != 3 && n != 2)
			croak("Vector arrayref must have 2 or 3 elements");
		vec[2]= 0;
		for (i=0; i < n; i++) {
			el= av_fetch(vec_av, i, 0);
			if (!el || !*el || !looks_like_number(*el))
				croak("Vector element %d is not a number", (int)i);
			vec[i]= SvNV(*el);
		}
	} else if (SvROK(in) && SvTYPE(SvRV(in)) == SVt_PVHV) {
		attrs= (HV*) SvRV(in);
		vec[0]= ((el= hv_fetchs(attrs, "x", 0)) && *el && SvOK(*el))? SvNV(*el) : 0;
		vec[1]= ((el= hv_fetchs(attrs, "y", 0)) && *el && SvOK(*el))? SvNV(*el) : 0;
		vec[2]= ((el= hv_fetchs(attrs, "z", 0)) && *el && SvOK(*el))? SvNV(*el) : 0;
	} else if (SvROK(in) && SvPOK(SvRV(in)) && SvCUR(SvRV(in)) == sizeof(NV)*3) {
		memcpy(vec, SvPV_nolen(SvRV(in)), sizeof(NV)*3);
	} else
		croak("Can't read vector from %s", sv_reftype(in, 1));
}

// Walk the perl-side chain of $space->parent->parent->... and update the C-side
// parent pointers and n_parents counters.  This needs called any time we come back
// from perl-land because scripts might update these references at any time, and
// it would require too much magic to update the C pointers as that happened.
// So, just let them get out of sync, then re-cache them here.
static void m3s_space_recache_parent(SV *space_sv) {
	m3s_space_t *space= NULL, *prev= NULL;
	SV **field, *cur= space_sv;
	HV *seen= NULL;
	int depth= 0;
	while (cur && SvOK(cur)) {
		prev= space;
		if (!(
			SvROK(cur) && SvTYPE(SvRV(cur)) == SVt_PVHV
			&& (space= m3s_get_magic_space(cur, 0))
		))
			croak("'parent' is not a Math::3Space : %s", SvPV_nolen(cur));
		space->parent= NULL;
		if (prev) {
			prev->parent= space;
			if (++depth > 964) { // Check for cycles in the graph
				if (!seen) seen= (HV*) sv_2mortal((SV*)newHV()); // hash will auto-garbage-collect
				field= hv_fetch(seen, (char*)&space, sizeof(space), 1); // use pointer value as key
				if (!field || !*field) croak("BUG");
				if (SvOK(*field))
					croak("Cycle detected in space->parent graph");
				sv_setsv(*field, &PL_sv_yes); // signal that we've been here with any pointer value
			}
		}
		field= hv_fetch((HV*) SvRV(cur), "parent", 6, 0);
		cur= field? *field : NULL;
	}
	for (space= m3s_get_magic_space(space_sv, OR_DIE); space; space= space->parent)
		space->n_parents= depth--;
}

/**********************************************************************************************\
* Math::3Space Public API
\**********************************************************************************************/
MODULE = Math::3Space              PACKAGE = Math::3Space

void
_init(obj, source=NULL)
	SV *obj
	SV *source
	INIT:
		m3s_space_t *space= m3s_get_magic_space(obj, AUTOCREATE);
		m3s_space_t *src_space;
		HV *attrs;
		SV **field;
	CODE:
		if (source) {
			if (sv_isobject(source)) {
				src_space= m3s_get_magic_space(source, OR_DIE);
				memcpy(space, src_space, sizeof(*space));
			} else if (SvROK(source) && SvTYPE(source) == SVt_PVHV) {
				attrs= (HV*) SvRV(source);
				if ((field= hv_fetch(attrs, "xv", 2, 0)) && *field && SvOK(*field))
					m3s_read_vector_from_sv(SPACE_XV(space), *field);
				else
					SPACE_XV(space)[0]= 1;
				if ((field= hv_fetch(attrs, "yv", 2, 0)) && *field && SvOK(*field))
					m3s_read_vector_from_sv(SPACE_YV(space), *field);
				else
					SPACE_YV(space)[1]= 1;
				if ((field= hv_fetch(attrs, "zv", 2, 0)) && *field && SvOK(*field))
					m3s_read_vector_from_sv(SPACE_ZV(space), *field);
				else
					SPACE_ZV(space)[2]= 1;
				if ((field= hv_fetch(attrs, "origin", 6, 0)) && *field && SvOK(*field))
					m3s_read_vector_from_sv(SPACE_ORIGIN(space), *field);
				space->is_normal= -1;
			} else
				croak("Invalid source for _init");
		}

SV*
clone(obj)
	SV *obj
	INIT:
		m3s_space_t *space= m3s_get_magic_space(obj, OR_DIE), *space2;
		HV *clone_hv;
	CODE:
		if (SvTYPE(SvRV(obj)) != SVt_PVHV)
			croak("Invalid source object"); // just to be really sure before next line
		clone_hv= newHVhv((HV*)SvRV(obj));
		RETVAL= newRV_noinc((SV*)clone_hv);
		sv_bless(RETVAL, gv_stashpv(sv_reftype(SvRV(obj), 1), GV_ADD));
		space2= m3s_get_magic_space(RETVAL, AUTOCREATE);
		memcpy(space2, space, sizeof(*space2));
	OUTPUT:
		RETVAL

SV*
space(parent=NULL)
	SV *parent
	INIT:
		m3s_space_t *space;
	CODE:
		if (parent && SvOK(parent) && !m3s_get_magic_space(parent, 0))
			croak("Invalid parent, must be instance of Math::3Space");
		Newx(space, 1, m3s_space_t);
		m3s_space_init(space);
		RETVAL= m3s_wrap_space(space);
		if (parent && SvOK(parent))
			hv_store((HV*)SvRV(RETVAL), "parent", 6, newSVsv(parent), 0);
	OUTPUT:
		RETVAL

void
xv(space, x_or_vec=NULL, y=NULL, z=NULL)
	m3s_space_t *space
	SV *x_or_vec
	SV *y
	SV *z
	ALIAS:
		Math::3Space::yv = 1
		Math::3Space::zv = 2
		Math::3Space::origin = 3
	INIT:
		NV *vec= space->mat + ix * 3;
	PPCODE:
		if (x_or_vec) {
			if (y) {
				vec[0]= SvNV(x_or_vec);
				vec[1]= SvNV(y);
				vec[2]= z? SvNV(z) : 0;
			} else {
				m3s_read_vector_from_sv(vec, x_or_vec);
			}
			space->is_normal= -1;
			// leave $self on stack as return value
		} else {
			ST(0)= sv_2mortal(m3s_wrap_vector(vec));
		}
		XSRETURN(1);

bool
is_normal(space)
	m3s_space_t *space
	CODE:
		if (space->is_normal == -1)
			m3s_space_check_normal(space);
		RETVAL= space->is_normal;
	OUTPUT:
		RETVAL

int
parent_count(space)
	SV *space
	CODE:
		m3s_space_recache_parent(space);
		RETVAL= m3s_get_magic_space(space, OR_DIE)->n_parents;
	OUTPUT:
		RETVAL

void
reparent(space, parent)
	SV *space
	SV *parent
	INIT:
		m3s_space_t *sp3= m3s_get_magic_space(space, OR_DIE), *psp3, *cur;
	PPCODE:
		m3s_space_recache_parent(space);
		if (SvOK(parent)) {
			psp3= m3s_get_magic_space(parent, OR_DIE);
			m3s_space_recache_parent(parent);
			// Make sure this doesn't create a cycle
			for (cur= psp3; cur; cur= cur->parent)
				if (cur == sp3)
					croak("Attempt to create a cycle: new 'parent' is a child of this space");
			m3s_space_reparent(sp3, psp3);
		} else {
			m3s_space_reparent(sp3, NULL);
		}
		hv_store((HV*) SvRV(space), "parent", 6, newSVsv(parent), 0);
		XSRETURN(1);

void
translate(space, x_or_vec, y=NULL, z=NULL)
	m3s_space_t *space
	SV *x_or_vec
	SV *y
	SV *z
	ALIAS:
		Math::3Space::tr = 0
		Math::3Space::travel = 1
		Math::3Space::go = 1
	INIT:
		NV vec[3], *matp;
	PPCODE:
		if (y) {
			vec[0]= SvNV(x_or_vec);
			vec[1]= SvNV(y);
			vec[2]= z? SvNV(z) : 0;
		} else {
			m3s_read_vector_from_sv(vec, x_or_vec);
		}
		if (ix) {
			matp= space->mat;
			matp[9] += vec[0] * matp[0] + vec[1] * matp[3] + vec[2] * matp[6];
			++matp;
			matp[9] += vec[0] * matp[0] + vec[1] * matp[3] + vec[2] * matp[6];
			++matp;
			matp[9] += vec[0] * matp[0] + vec[1] * matp[3] + vec[2] * matp[6];
		} else {
			matp= SPACE_ORIGIN(space);
			*matp++ += vec[0];
			*matp++ += vec[1];
			*matp++ += vec[2];
		}
		XSRETURN(1);

void
scale(space, xscale_or_vec, yscale=NULL, zscale=NULL)
	m3s_space_t *space
	SV *xscale_or_vec
	SV *yscale
	SV *zscale
	ALIAS:
		Math::3Space::set_scale = 1
	INIT:
		NV vec[3], s, m, *matp= SPACE_XV(space);
		size_t i;
	PPCODE:
		if (SvROK(xscale_or_vec) && yscale == NULL) {
			m3s_read_vector_from_sv(vec, xscale_or_vec);
		} else {
			vec[0]= SvNV(xscale_or_vec);
			vec[1]= yscale? SvNV(yscale) : vec[0];
			vec[2]= zscale? SvNV(zscale) : vec[0];
		}
		for (i= 0; i < 3; i++) {
			s= vec[i];
			if (ix == 1) {
				m= sqrt(matp[0]*matp[0] + matp[1]*matp[1] + matp[2]*matp[2]);
				if (m > 0)
					s /= m;
				else
					warn("can't scale magnitude=0 vector");
			}
			*matp++ *= s;
			*matp++ *= s;
			*matp++ *= s;
		}
		space->is_normal= -1;
		XSRETURN(1);

void
rotate(space, angle, x_or_vec, y=NULL, z=NULL)
	m3s_space_t *space
	NV angle
	SV *x_or_vec
	SV *y
	SV *z
	INIT:
		m3s_vector_t vec;
	ALIAS:
		Math::3Space::rot = 0
	PPCODE:
		if (y) {
			if (!z) croak("Missing z coordinate in space->rotate(angle, x, y, z)");
			vec[0]= SvNV(x_or_vec);
			vec[1]= SvNV(y);
			vec[2]= SvNV(z);
		} else {
			m3s_read_vector_from_sv(vec, x_or_vec);
		}
		m3s_space_rotate(space, sin(angle * 2 * M_PI), cos(angle * 2 * M_PI), vec);
		// return $self
		XSRETURN(1);

void
rot_x(space, angle)
	m3s_space_t *space
	NV angle
	ALIAS:
		Math::3Space::rot_y = 1
		Math::3Space::rot_z = 2
		Math::3Space::rot_xv = 3
		Math::3Space::rot_yv = 4
		Math::3Space::rot_zv = 5
	INIT:
		NV *matp, tmp1, tmp2;
		size_t ofs1, ofs2;
		NV s= sin(angle * 2 * M_PI), c= cos(angle * 2 * M_PI);
	PPCODE:
		if (ix < 3) { // Rotate around axis of parent
			matp= SPACE_XV(space);
			ofs1= (ix+1) % 3;
			ofs2= (ix+2) % 3;
			tmp1= c * matp[ofs1] - s * matp[ofs2];
			tmp2= s * matp[ofs1] + c * matp[ofs2];
			matp[ofs1]= tmp1;
			matp[ofs2]= tmp2;
			matp += 3;
			tmp1= c * matp[ofs1] - s * matp[ofs2];
			tmp2= s * matp[ofs1] + c * matp[ofs2];
			matp[ofs1]= tmp1;
			matp[ofs2]= tmp2;
			matp += 3;
			tmp1= c * matp[ofs1] - s * matp[ofs2];
			tmp2= s * matp[ofs1] + c * matp[ofs2];
			matp[ofs1]= tmp1;
			matp[ofs2]= tmp2;
		} else {
			m3s_space_self_rotate(space, s, c, ix - 3);
		}
		XSRETURN(1);

void
project_vector(space, ...)
	m3s_space_t *space
	INIT:
		m3s_vector_t vec;
		int i;
		AV *vec_av;
	ALIAS:
		Math::3Space::project = 1
		Math::3Space::unproject_vector = 2
		Math::3Space::unproject = 3
	PPCODE:
		for (i= 1; i < items; i++) {
			m3s_read_vector_from_sv(vec, ST(i));
			switch (ix) {
			case 0: m3s_space_project_vector(space, vec); break;
			case 1: m3s_space_project_point(space, vec); break;
			case 2: m3s_space_unproject_vector(space, vec); break;
			default: m3s_space_unproject_point(space, vec);
			}
			if (SvTYPE(SvRV(ST(i))) == SVt_PVAV) {
				vec_av= newAV();
				av_extend(vec_av, 2);
				av_push(vec_av, newSVnv(vec[0]));
				av_push(vec_av, newSVnv(vec[1]));
				av_push(vec_av, newSVnv(vec[2]));
				ST(i-1)= sv_2mortal(newRV_noinc((SV*)vec_av));
			} else {
				ST(i-1)= sv_2mortal(m3s_wrap_vector(vec));
			}
		}
		XSRETURN(items-1);

void
project_vector_inplace(space, ...)
	m3s_space_t *space
	INIT:
		m3s_vector_t vec;
		m3s_vector_p vecp;
		size_t i, n;
		AV *vec_av;
		SV **item, *x, *y, *z;
	ALIAS:
		Math::3Space::project_inplace = 1
		Math::3Space::unproject_vector_inplace = 2
		Math::3Space::unproject_inplace = 3
	PPCODE:
		for (i= 1; i < items; i++) {
			if (!SvROK(ST(i)))
				croak("Expected vector at $_[%d]", (int)(i-1));
			else if (SvPOK(SvRV(ST(i)))) {
				vecp= m3s_vector_get_array(ST(i));
				switch (ix) {
				case 0: m3s_space_project_vector(space, vecp); break;
				case 1: m3s_space_project_point(space, vecp); break;
				case 2: m3s_space_unproject_vector(space, vecp); break;
				default: m3s_space_unproject_point(space, vecp);
				}
			}
			else if (SvTYPE(SvRV(ST(i))) == SVt_PVAV) {
				vec_av= (AV*) SvRV(ST(i));
				n= av_len(vec_av)+1;
				if (n != 3 && n != 2) croak("Expected 2 or 3 elements in vector");
				item= av_fetch(vec_av, 0, 0);
				if (!(item && *item && SvOK(*item))) croak("Expected x value at $vec->[0]");
				x= *item;
				item= av_fetch(vec_av, 1, 0);
				if (!(item && *item && SvOK(*item))) croak("Expected y value at $vec->[1]");
				y= *item;
				item= n == 3? av_fetch(vec_av, 2, 0) : NULL;
				if (item && !(*item && SvOK(*item))) croak("Invalid z value at $vec->[2]");
				z= item? *item : NULL;
				vec[0]= SvNV(x);
				vec[1]= SvNV(y);
				vec[2]= z? SvNV(z) : 0;
				
				switch (ix) {
				case 0: m3s_space_project_vector(space, vec); break;
				case 1: m3s_space_project_point(space, vec); break;
				case 2: m3s_space_unproject_vector(space, vec); break;
				default: m3s_space_unproject_point(space, vec);
				}
				
				sv_setnv(x, vec[0]);
				sv_setnv(y, vec[1]);
				if (z) sv_setnv(z, vec[2]);
			}
		}
		// return $self
		XSRETURN(1);

void
get_gl_matrix(space, buffer=NULL)
	m3s_space_t *space
	SV *buffer
	INIT:
		NV *src;
		double *dst;
	PPCODE:
		if (buffer) {
			m3s_make_aligned_buffer(buffer, sizeof(double)*16);
			dst= (double*) SvPVX(buffer);
			src= space->mat;
			dst[ 0] = src[ 0]; dst[ 1] = src[ 1]; dst[ 2] = src[ 2]; dst[ 3] = 0;
			dst[ 4] = src[ 3]; dst[ 5] = src[ 4]; dst[ 6] = src[ 5]; dst[ 7] = 0;
			dst[ 8] = src[ 6]; dst[ 9] = src[ 7]; dst[10] = src[ 8]; dst[11] = 0;
			dst[12] = src[ 9]; dst[13] = src[10]; dst[14] = src[11]; dst[15] = 1;
			XSRETURN(0);
		} else {
			EXTEND(SP, 16);
			mPUSHn(SPACE_XV(space)[0]); mPUSHn(SPACE_XV(space)[1]); mPUSHn(SPACE_XV(space)[2]); mPUSHn(0);
			mPUSHn(SPACE_YV(space)[0]); mPUSHn(SPACE_YV(space)[1]); mPUSHn(SPACE_YV(space)[2]); mPUSHn(0);
			mPUSHn(SPACE_ZV(space)[0]); mPUSHn(SPACE_ZV(space)[1]); mPUSHn(SPACE_ZV(space)[2]); mPUSHn(0);
			mPUSHn(SPACE_ORIGIN(space)[0]); mPUSHn(SPACE_ORIGIN(space)[1]); mPUSHn(SPACE_ORIGIN(space)[2]); mPUSHn(1);
			XSRETURN(16);
		}

#**********************************************************************************************
# Math::3Space::Vector
#**********************************************************************************************
MODULE = Math::3Space              PACKAGE = Math::3Space::Vector

m3s_vector_p
vec3(vec_or_x, y=NULL, z=NULL)
	SV* vec_or_x
	SV* y
	SV* z
	INIT:
		m3s_vector_t vec;
	CODE:
		if (y) {
			vec[0]= SvNV(vec_or_x);
			vec[1]= SvNV(y);
			vec[2]= z? SvNV(z) : 0;
		} else {
			m3s_read_vector_from_sv(vec, vec_or_x);
		}
		RETVAL = vec;
	OUTPUT:
		RETVAL

m3s_vector_p
new(pkg, ...)
	SV *pkg
	INIT:
		m3s_vector_t vec= { 0, 0, 0 };
		const char *key;
		IV i, ofs;
	CODE:
		if (items == 2 && SvROK(ST(1))) {
			m3s_read_vector_from_sv(vec, ST(1));
		}
		else if (items & 1) {
			for (i= 1; i < items; i+= 2) {
				key= SvOK(ST(i))? SvPV_nolen(ST(i)) : "";
				if (strcmp(key, "x") == 0) ofs= 0;
				else if (strcmp(key, "y") == 0) ofs= 1;
				else if (strcmp(key, "z") == 0) ofs= 2;
				else croak("Unknown attribute '%s'", key);
				
				if (!looks_like_number(ST(i+1)))
					croak("Expected attribute '%s' value, but got '%s'", SvPV_nolen(ST(i)), SvPV_nolen(ST(i+1)));
				vec[ofs]= SvNV(ST(i+1));
			}
		}
		else
			croak("Expected hashref, arrayref, or even-length list of attribute/value pairs");
		RETVAL = vec;
	OUTPUT:
		RETVAL

void
x(vec, newval=NULL)
	m3s_vector_p vec
	SV *newval
	ALIAS:
		Math::3Space::Vector::y = 1
		Math::3Space::Vector::z = 2
	PPCODE:
		if (newval) {
			vec[ix]= SvNV(newval);
		} else {
			ST(0)= sv_2mortal(newSVnv(vec[ix]));
		}
		XSRETURN(1);

void
xyz(vec)
	m3s_vector_p vec
	PPCODE:
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(vec[0])));
		PUSHs(sv_2mortal(newSVnv(vec[1])));
		PUSHs(sv_2mortal(newSVnv(vec[2])));

void
magnitude(vec, scale=NULL)
	m3s_vector_p vec
	SV *scale
	INIT:
		NV s, m= sqrt(vec[0]*vec[0] + vec[1]*vec[1] + vec[2]*vec[2]);
	PPCODE:
		if (scale) {
			if (m > 0) {
				s= SvNV(scale) / m;
				vec[0] *= s;
				vec[1] *= s;
				vec[2] *= s;
			} else
				warn("can't scale magnitude=0 vector");
			// return $self
		} else {
			ST(0)= sv_2mortal(newSVnv(m));
		}
		XSRETURN(1);

void
set(vec1, vec2_or_x, y=NULL, z=NULL)
	m3s_vector_p vec1
	SV *vec2_or_x
	SV *y
	SV *z
	ALIAS:
		Math::3Space::Vector::add = 1
		Math::3Space::Vector::sub = 2
	INIT:
		NV vec2[3];
	PPCODE:
		if (y || looks_like_number(vec2_or_x)) {
			vec2[0]= SvNV(vec2_or_x);
			vec2[1]= y? SvNV(y) : 0;
			vec2[2]= z? SvNV(z) : 0;
		} else {
			m3s_read_vector_from_sv(vec2, vec2_or_x);
		}
		if (ix == 0) {
			vec1[0]= vec2[0];
			vec1[1]= vec2[1];
			vec1[2]= vec2[2];
		} else if (ix == 1) {
			vec1[0]+= vec2[0];
			vec1[1]+= vec2[1];
			vec1[2]+= vec2[2];
		} else {
			vec1[0]-= vec2[0];
			vec1[1]-= vec2[1];
			vec1[2]-= vec2[2];
		}
		XSRETURN(1);

void
scale(vec1, vec2_or_x, y=NULL, z=NULL)
	m3s_vector_p vec1
	SV *vec2_or_x
	SV *y
	SV *z
	INIT:
		NV vec2[3];
	PPCODE:
		// single value should be treated as ($x,$x,$x) inatead of ($x,0,0)
		if (looks_like_number(vec2_or_x)) {
			vec2[0]= SvNV(vec2_or_x);
			vec2[1]= y? SvNV(y) : vec2[0];
			vec2[2]= z? SvNV(z) : y? 1 : vec2[0];
		}
		else {
			m3s_read_vector_from_sv(vec2, vec2_or_x);
		}
		vec1[0]*= vec2[0];
		vec1[1]*= vec2[1];
		vec1[2]*= vec2[2];
		XSRETURN(1);

NV
dot(vec1, vec2_or_x, y=NULL, z=NULL)
	m3s_vector_p vec1
	SV *vec2_or_x
	SV *y
	SV *z
	INIT:
		NV vec2[3];
	CODE:
		if (y) {
			vec2[0]= SvNV(vec2_or_x);
			vec2[1]= SvNV(y);
			vec2[2]= z? SvNV(z) : 0;
		} else {
			m3s_read_vector_from_sv(vec2, vec2_or_x);
		}
		RETVAL= m3s_vector_dotprod(vec1, vec2);
	OUTPUT:
		RETVAL

void
cross(vec1, vec2_or_x, vec3_or_y=NULL, z=NULL)
	m3s_vector_p vec1
	SV *vec2_or_x
	SV *vec3_or_y
	SV *z
	INIT:
		m3s_vector_t vec2, vec3;
	PPCODE:
		if (!vec3_or_y) { // RET = vec1->cross(vec2)
			m3s_read_vector_from_sv(vec2, vec2_or_x);
			m3s_vector_cross(vec3, vec1, vec2);
			ST(0)= sv_2mortal(m3s_wrap_vector(vec3));
		} else if (z || !SvROK(vec2_or_x) || looks_like_number(vec2_or_x)) { // RET = vec1->cross(x,y,z)
			vec2[0]= SvNV(vec2_or_x);
			vec2[1]= SvNV(vec3_or_y);
			vec2[2]= z? SvNV(z) : 0;
			m3s_vector_cross(vec3, vec1, vec2);
			ST(0)= sv_2mortal(m3s_wrap_vector(vec3));
		} else {
			m3s_read_vector_from_sv(vec2, vec2_or_x);
			m3s_read_vector_from_sv(vec3, vec3_or_y);
			m3s_vector_cross(vec1, vec2, vec3);
			// leave $self on stack
		}
		XSRETURN(1);
