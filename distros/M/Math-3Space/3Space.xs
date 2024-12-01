#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <math.h>

#if !defined(__cplusplus) && defined(_MSC_VER) && _MSC_VER < 1900
#  define inline __inline
#endif

#ifndef newAV_alloc_x
static AV *shim_newAV_alloc_x(int n) {
	AV *ret= newAV();
	av_extend(ret, n-1);
	return ret;
}
#define newAV_alloc_x shim_newAV_alloc_x
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

#define M3S_VECTYPE_VECOBJ   1
#define M3S_VECTYPE_ARRAY    2
#define M3S_VECTYPE_HASH     3
#define M3S_VECTYPE_PDL      4
#define M3S_VECTYPE_PDLMULTI 5

#define M3S_VECLOAD(vec,x_or_vec,y,z,dflt) do { \
  if (y) { \
    vec[0]= SvNV(x_or_vec); \
    vec[1]= SvNV(y); \
    vec[2]= z? SvNV(z) : dflt; \
  } else { \
    m3s_read_vector_from_sv(vec, x_or_vec, NULL, NULL); \
  } } while(0)

typedef NV m3s_vector_t[3];
typedef NV *m3s_vector_p;

struct m3s_4space_frustum_projection {
	/*   _                  _
	 *  | m00   0   m20   0  |
	 *  |  0   m11  m21   0  |
	 *  |  0    0   m22  m32 |
	 *  |_ 0    0   -1    0 _|
	 */
	double m00, m11, m20, m21, m22, m32;
	bool centered;
};
typedef union m3s_4space_projection {
	struct m3s_4space_frustum_projection frustum;
} m3s_4space_projection_t;

static const NV NV_tolerance = 1e-14;
static const double double_tolerance = 1e-14;

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
	return vec1[0]*vec2[0] + vec1[1]*vec2[1] + vec1[2]*vec2[2];
}

// Vector cosine.  Same as dotprod for unit vectors.
static inline NV m3s_vector_cosine(NV *vec1, NV *vec2) {
	NV mag, prod;
	mag= m3s_vector_dotprod(vec1,vec1) * m3s_vector_dotprod(vec2,vec2);
	prod= m3s_vector_dotprod(vec1,vec2);
	if (mag < NV_tolerance)
		croak("Can't calculate vector cosine of vector with length < 1e-14");
	else if (fabs(mag - 1) > NV_tolerance)
		prod /= sqrt(mag);
	return prod;
}

/* Check whether a space's axis vectors are unit length and orthogonal to
 * eachother, and update the 'is_normal' flag on the space.
 * Having this flag = 1 can optimize relative rotations later.
 * The flag gets set to -1 any time an operation may have broken normality.
 * Approx Cost: 4-19 load, 3-18 mul, 4-17 add, 1-2 stor
 */
static int m3s_space_check_normal(m3s_space_t *sp) {
	NV *vec, *pvec;
	sp->is_normal= 0;
	for (vec= sp->mat+6, pvec= sp->mat; vec > sp->mat; pvec= vec, vec -= 3) {
		if (fabs(m3s_vector_dotprod(vec,vec) - 1) > NV_tolerance)
			return 0;
		if (m3s_vector_dotprod(vec,pvec) > NV_tolerance)
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
	// Walk back the stack of parents until it has fewer parents than 'space'.
	// This way space->parent has a chance to be 'common_parent'.
	common_parent= parent;
	while (common_parent && common_parent->n_parents >= space->n_parents)
		common_parent= common_parent->parent;
	// Now unproject 'space' from each of its parents until its parent is 'common_parent'.
	while (space->n_parents && space->parent != common_parent) {
		// Map 'space' out to be a sibling of its parent
		m3s_space_unproject_space(space->parent, space);
		// if 'space' reached the depth of common_parent+1 and the loop didn't stop,
		// then it wasn't actually the parent they have in common, yet.
		if (common_parent && common_parent->n_parents + 1 == space->n_parents)
			common_parent= common_parent->parent;
	}
	// At this point, 'space' is either a root 3Space, or 'common_parent' is its parent.
	// If the common parent is the original 'parent', then we're done.
	if (parent == common_parent)
		return;
	// Calculate an equivalent space to 'parent' at this parent depth.
	if (!(parent != NULL)) croak("assertion failed: parent != NULL");
	memcpy(&sp_tmp, parent, sizeof(sp_tmp));
	while (sp_tmp.parent != common_parent)
		m3s_space_unproject_space(sp_tmp.parent, &sp_tmp);
	// 'sp_tmp' is now equivalent to projecting through the chain from common_parent to parent,
	// so just project 'space' into this temporary and we're done.
	m3s_space_project_space(&sp_tmp, space);
	space->parent= parent;
	space->n_parents= parent->n_parents + 1;
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
	mag_sq= m3s_vector_dotprod(axis,axis);
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
	mag_sq= m3s_vector_dotprod(r.mat,r.mat);
	if (mag_sq < NV_tolerance) {
		// try again with a different vector
		r.mat[3]= 0;
		r.mat[4]= 1;
		m3s_vector_cross(r.mat, r.mat+3, r.mat+6);
		mag_sq= m3s_vector_dotprod(r.mat,r.mat);
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

/* Rotate the space around an axis of its parent.  axis_idx: 0 (xv), 1 (yv) or 2 (zv)
 * Angle is supplied as direct sine / cosine values.
 * Approx Cost: 12 fmul, 6 fadd
 */
static void m2s_space_parent_axis_rotate(m3s_space_t *space, NV angle_sin, NV angle_cos, int axis_idx) {
	int ofs1, ofs2;
	NV tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, *matp;
	switch (axis_idx) {
	case 0: ofs1= 1, ofs2= 2; break;
	case 1: ofs1= 2, ofs2= 0; break;
	case 2: ofs1= 0, ofs2= 1; break;
	default: croak("BUG: axis_idx > 2");
	}
	matp= SPACE_XV(space);
	tmp1= angle_cos * matp[ofs1  ] - angle_sin * matp[ofs2  ];
	tmp2= angle_sin * matp[ofs1  ] + angle_cos * matp[ofs2  ];
	tmp3= angle_cos * matp[ofs1+3] - angle_sin * matp[ofs2+3];
	tmp4= angle_sin * matp[ofs1+3] + angle_cos * matp[ofs2+3];
	tmp5= angle_cos * matp[ofs1+6] - angle_sin * matp[ofs2+6];
	tmp6= angle_sin * matp[ofs1+6] + angle_cos * matp[ofs2+6];
	matp[ofs1]= tmp1;
	matp[ofs2]= tmp2;
	matp[ofs1+3]= tmp3;
	matp[ofs2+3]= tmp4;
	matp[ofs1+6]= tmp5;
	matp[ofs2+6]= tmp6;
}

/* Rotate the space around one of its own axes.  axis_idx: 0 (xv), 1 (yv) or 2 (zv)
 * Angle is supplied as direct sine / cosine values.
 * If the space is_normal (unit-length vectors orthogonal to eachother) this uses a very
 * efficient optimization.  Else it falls back to the full m3s_space_rotate function.
 * Approx Cost, if normal: 18 fmul, 12 fadd
 * Approx Cost, else:      87-99 fmul, 1-2 fdiv, 56-62 fadd, 1 fabs, 1-2 sqrt
 */
static void m3s_space_self_axis_rotate(m3s_space_t *space, NV angle_sin, NV angle_cos, int axis_idx) {
	m3s_vector_t vec1, vec2;

	if (space->is_normal == -1)
		m3s_space_check_normal(space);
	if (!space->is_normal) {
		m3s_space_rotate(space, angle_sin, angle_cos, space->mat + axis_idx*3);
	} else {
		// Axes are all unit vectors, orthogonal to eachother, and can skip setting up a
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
static char* m3s_make_aligned_buffer(SV *buf, size_t size) {
	char *p;
	STRLEN len;

	if (!SvPOK(buf))
		sv_setpvs(buf, "");
	p= SvPV_force(buf, len);
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
	return p;
}

// Create a new Math::3Space::Vector object, which is a blessed scalar-ref containing
// the aligned bytes of three NV (usually doubles)
static SV* m3s_wrap_vector(m3s_vector_p vec_array) {
	SV *obj, *buf;
	buf= newSVpvn((char*) vec_array, sizeof(NV)*3);
	if ((intptr_t)SvPVX(buf) & NV_ALIGNMENT_MASK) {
		memcpy(m3s_make_aligned_buffer(buf, sizeof(NV)*3), vec_array, sizeof(NV)*3);
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
// It currently supports arrayref-of-SvNV, hashref of SvNV, scalarrefs of packed doubles
// (i.e. vector objects), and PDL ndarrays.
// The return type is one of the M3S_VECTYPE_ constants.  The output params 'vec', 'pdl_dims',
// and 'component_sv' may or may not get filled in, depending on that return type.
// The function 'croak's if the input is not valid.
static int m3s_read_vector_from_sv(m3s_vector_p vec, SV *in, size_t pdl_dims[3], SV *component_sv[3]) {
	SV **el, *rv= SvROK(in)? SvRV(in) : NULL;
	AV *vec_av;
	HV *attrs;
	size_t i, n;
	if (!rv)
		croak("Vector must be a reference type");

	// Given a scalar-ref to a buffer the size of 3 packed NV (could be double or long double)
	// which is also the structure used by blessed Math::3Space::Vector, simply copy the value
	// into 'vec'.
	if (SvPOK(rv) && SvCUR(rv) == sizeof(NV)*3) {
		memcpy(vec, SvPV_force_nolen(rv), sizeof(NV)*3);
		return M3S_VECTYPE_VECOBJ;
	}
	// Given an array, the array must be length 2 or 3, and each element must look like a number.
	// If it matches, the values are loaded into 'vec', and pointers to the SVs are stored in
	// component_sv if the caller provided that.
	else if (SvTYPE(rv) == SVt_PVAV) {
		vec_av= (AV*) rv;
		n= av_len(vec_av)+1;
		if (n != 3 && n != 2)
			croak("Vector arrayref must have 2 or 3 elements");
		vec[2]= 0;
		if (component_sv) component_sv[2]= NULL;
		for (i=0; i < n; i++) {
			el= av_fetch(vec_av, i, 0);
			if (!el || !*el || !looks_like_number(*el))
				croak("Vector element %d is not a number", (int)i);
			vec[i]= SvNV(*el);
			if (component_sv) component_sv[i]= *el;
		}
		return M3S_VECTYPE_ARRAY;
	}
	// Given a hashref, look for elements 'x', 'y', and 'z'.  They default to 0 if not found.
	// Each found element must be a number.  The SV pointers are saved into component_sv if
	// it was provided by the caller.
	else if (SvTYPE(rv) == SVt_PVHV) {
		const char *keys= "x\0y\0z";
		attrs= (HV*) rv;
		for (i=0; i < 3; i++) {
			if ((el= hv_fetch(attrs, keys+(i<<1), 1, 0)) && *el && SvOK(*el)) {
				if (!looks_like_number(*el))
					croak("Hash element %s is not a number", keys+(i<<1));
				vec[i]= SvNV(*el);
				if (component_sv) component_sv[i]= *el;
			} else {
				vec[i]= 0;
				if (component_sv) component_sv[i]= NULL;
			}
		}
		return M3S_VECTYPE_HASH;
	}
	// Given a PDL ndarray object, check its dimensions.  If the ndarray is exactly a 2x1 or 3x1
	// array, then copy those values into 'vec'.  If the ndarray has higher dimensions, let the
	// caller know about them in the 'pdl_dims' array, and don't touch 'vec'.  The caller can
	// then decide how to handle those higher dimensions, or throw an error etc.
	else if (sv_derived_from(in, "PDL")) {
		dSP;
		int count, single_dim= 0;
		SV *ret;

		ENTER;
		SAVETMPS;
		PUSHMARK(SP);
		EXTEND(SP,1);
		PUSHs(in);
		PUTBACK;
		count= call_method("dims", G_LIST);
		SPAGAIN;
		if (pdl_dims) {
			// return up to 3 dims; more than that doesn't change our behavior.
			if (count > 3) SP -= (count-3);
			pdl_dims[2]= (count > 2)? POPi : 0;
			pdl_dims[1]= (count > 1)? POPi : 0;
			pdl_dims[0]= (count > 0)? POPi : 0;
			if (pdl_dims[1] == 0)
				single_dim= pdl_dims[0];
		}
		// if caller doesn't pass pdl_dims, they expect a simple 1x3 vector.
		else if (count == 1) {
			single_dim= POPi;
		} else {
			SP -= count;
		}
		PUTBACK;
		FREETMPS;
		LEAVE;

		if (single_dim == 2 || single_dim == 3) {
			ENTER;
			SAVETMPS;
			PUSHMARK(SP);
			EXTEND(SP,1);
			PUSHs(in);
			PUTBACK;
			count= call_method("list", G_LIST);
			SPAGAIN;
			if (count > 3) SP -= (count-3); // should never happen
			vec[2]= (count > 2)? POPn : 0;
			vec[1]= (count > 1)? POPn : 0;
			vec[0]= (count > 0)? POPn : 0;
			PUTBACK;
			FREETMPS;
			LEAVE;
			return M3S_VECTYPE_PDL;
		}
		else if (!pdl_dims)
			croak("Expected PDL dimensions of 2x1 or 3x1");
		else
			return M3S_VECTYPE_PDLMULTI;
	} else
		croak("Can't read vector from %s", sv_reftype(in, 1));
}

// Create a new Math::3Space::Vector object, which is a blessed scalar-ref containing
// the aligned bytes of three NV (usually doubles)
static SV* m3s_wrap_projection(m3s_4space_projection_t *p, const char* pkg) {
	SV *obj, *buf;
	buf= newSVpvn((char*) p, sizeof(m3s_4space_projection_t));
	if ((intptr_t)SvPVX(buf) & NV_ALIGNMENT_MASK) {
		memcpy(m3s_make_aligned_buffer(buf, sizeof(m3s_4space_projection_t)), p, sizeof(m3s_4space_projection_t));
	}
	obj= newRV_noinc(buf);
	sv_bless(obj, gv_stashpv(pkg, GV_ADD));
	return obj;
}

// Return a pointer to the aligned NV[3] inside the scalar ref 'vector'.
// These can be written directly to modify the vector's value.
static m3s_4space_projection_t * m3s_projection_get(SV *vector) {
	char *p= NULL;
	STRLEN len= 0;
	if (sv_isobject(vector) && SvPOK(SvRV(vector)))
		p= SvPV(SvRV(vector), len);
	if (len != sizeof(m3s_4space_projection_t) || ((intptr_t)p & NV_ALIGNMENT_MASK) != 0)
		croak("Invalid or corrupt Math::3Space::Projection object");
	return (m3s_4space_projection_t*) p;
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

// TODO: find a way to tap into PDL without compile-time dependency...
static SV* m3s_pdl_vector(m3s_vector_p vec, int dim) {
	SV *ret;
	int count;
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	EXTEND(SP, 3);
	PUSHs(sv_2mortal(newSVnv(vec[0])));
	PUSHs(sv_2mortal(newSVnv(vec[1])));
	if (dim == 3) PUSHs(sv_2mortal(newSVnv(vec[2])));
	PUTBACK;
	count= call_pv("PDL::Core::pdl", G_SCALAR);
	if (count != 1) croak("call to PDL::Core::pdl did not return an ndarray");
	SPAGAIN;
	ret= POPs;
	SvREFCNT_inc(ret); // protect from FREETMPS
	PUTBACK;
	FREETMPS;
	LEAVE;
	return ret;
}
static SV* m3s_pdl_matrix(NV *mat, bool transpose) {
	AV *av;
	SV *ret;
	int i, count;
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	EXTEND(SP, 3);
	for (i= 0; i < 3; i++) {
		av= newAV_alloc_x(3);
		av_push(av, newSVnv(mat[transpose? i+0 : (i*3)+0]));
		av_push(av, newSVnv(mat[transpose? i+3 : (i*3)+1]));
		av_push(av, newSVnv(mat[transpose? i+6 : (i*3)+2]));
		PUSHs(sv_2mortal((SV*)newRV_noinc((SV*)av)));
	}
	PUTBACK;
	count= call_pv("PDL::Core::pdl", G_SCALAR);
	if (count != 1) croak("call to PDL::Core::pdl did not return an ndarray");
	SPAGAIN;
	ret= POPs;
	SvREFCNT_inc(ret); // protect from FREETMPS
	PUTBACK;
	FREETMPS;
	LEAVE;
	return ret;
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
					m3s_read_vector_from_sv(SPACE_XV(space), *field, NULL, NULL);
				else
					SPACE_XV(space)[0]= 1;
				if ((field= hv_fetch(attrs, "yv", 2, 0)) && *field && SvOK(*field))
					m3s_read_vector_from_sv(SPACE_YV(space), *field, NULL, NULL);
				else
					SPACE_YV(space)[1]= 1;
				if ((field= hv_fetch(attrs, "zv", 2, 0)) && *field && SvOK(*field))
					m3s_read_vector_from_sv(SPACE_ZV(space), *field, NULL, NULL);
				else
					SPACE_ZV(space)[2]= 1;
				if ((field= hv_fetch(attrs, "origin", 6, 0)) && *field && SvOK(*field))
					m3s_read_vector_from_sv(SPACE_ORIGIN(space), *field, NULL, NULL);
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
			M3S_VECLOAD(vec,x_or_vec,y,z,0);
			if (ix < 3) space->is_normal= -1;
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
		m3s_space_t *sp3= m3s_get_magic_space(space, OR_DIE), *psp3=NULL, *cur;
	PPCODE:
		m3s_space_recache_parent(space);
		if (SvOK(parent)) {
			psp3= m3s_get_magic_space(parent, OR_DIE);
			m3s_space_recache_parent(parent);
			// Make sure this doesn't create a cycle
			for (cur= psp3; cur; cur= cur->parent)
				if (cur == sp3)
					croak("Attempt to create a cycle: new 'parent' is a child of this space");
		}
		m3s_space_reparent(sp3, psp3);
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
		M3S_VECLOAD(vec,x_or_vec,y,z,0);
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
			m3s_read_vector_from_sv(vec, xscale_or_vec, NULL, NULL);
		} else {
			vec[0]= SvNV(xscale_or_vec);
			vec[1]= yscale? SvNV(yscale) : vec[0];
			vec[2]= zscale? SvNV(zscale) : vec[0];
		}
		for (i= 0; i < 3; i++) {
			s= vec[i];
			if (ix == 1) {
				m= sqrt(m3s_vector_dotprod(matp,matp));
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
			m3s_read_vector_from_sv(vec, x_or_vec, NULL, NULL);
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
		if (ix < 3) // Rotate around axis of parent
			m2s_space_parent_axis_rotate(space, s, c, ix);
		else
			m3s_space_self_axis_rotate(space, s, c, ix - 3);
		XSRETURN(1);

void
project_vector(space, ...)
	m3s_space_t *space
	INIT:
		m3s_vector_t vec;
		int i, vectype, count;
		AV *vec_av;
		HV *vec_hv;
		SV *pdl_origin= NULL, *pdl_matrix= NULL;
		size_t pdl_dims[3];
	ALIAS:
		Math::3Space::project = 1
		Math::3Space::unproject_vector = 2
		Math::3Space::unproject = 3
	PPCODE:
		for (i= 1; i < items; i++) {
			vectype= m3s_read_vector_from_sv(vec, ST(i), pdl_dims, NULL);
			if (vectype == M3S_VECTYPE_PDLMULTI) {
				dSP;
				if (!pdl_origin) {
					pdl_origin= sv_2mortal(m3s_pdl_vector(SPACE_ORIGIN(space), 3));
					pdl_matrix= sv_2mortal(m3s_pdl_matrix(SPACE_XV(space), !(ix&2) /*transpose bool*/));
				}
				ENTER;
				SAVETMPS;
				PUSHMARK(SP);
				// first, clone the input.  Then modify it in place.
				EXTEND(SP, 4);
				PUSHs(ST(i));
				PUTBACK;
				count= call_method("copy", G_SCALAR);
				SPAGAIN;
				if (count != 1) croak("PDL->copy failed?");
				// project point subtracts origin
				PUSHs(ix == 3? pdl_origin : &PL_sv_undef);
				PUSHs(pdl_matrix);
				// unproject point adds origin
				PUSHs(ix == 1? pdl_origin : &PL_sv_undef);
				PUTBACK;
				count= call_pv("Math::3Space::_pdl_project_inplace", G_DISCARD);
				
				FREETMPS;
				LEAVE;
				ST(i-1)= ST(i);
			}
			else {
				switch (ix) {
				case 0: m3s_space_project_vector(space, vec); break;
				case 1: m3s_space_project_point(space, vec); break;
				case 2: m3s_space_unproject_vector(space, vec); break;
				default: m3s_space_unproject_point(space, vec);
				}
				switch (vectype) {
				case M3S_VECTYPE_ARRAY:
					vec_av= newAV();
					av_extend(vec_av, 2);
					av_push(vec_av, newSVnv(vec[0]));
					av_push(vec_av, newSVnv(vec[1]));
					av_push(vec_av, newSVnv(vec[2]));
					ST(i-1)= sv_2mortal(newRV_noinc((SV*)vec_av));
					break;
				case M3S_VECTYPE_HASH:
					vec_hv= newHV();
					hv_stores(vec_hv, "x", newSVnv(vec[0]));
					hv_stores(vec_hv, "y", newSVnv(vec[1]));
					hv_stores(vec_hv, "z", newSVnv(vec[2]));
					ST(i-1)= sv_2mortal(newRV_noinc((SV*)vec_hv));
					break;
				case M3S_VECTYPE_PDL:
					ST(i-1)= sv_2mortal(m3s_pdl_vector(vec, pdl_dims[0]));
					break;
				default:
					ST(i-1)= sv_2mortal(m3s_wrap_vector(vec));
				}
			}
		}
		XSRETURN(items-1);

void
project_vector_inplace(space, ...)
	m3s_space_t *space
	INIT:
		m3s_vector_t vec;
		m3s_vector_p vecp;
		size_t i, j, n;
		int vectype;
		AV *vec_av;
		SV **item, *x, *y, *z, *pdl_origin= NULL, *pdl_matrix= NULL;
		size_t pdl_dims[3];
		SV *component_sv[3];
	ALIAS:
		Math::3Space::project_inplace = 1
		Math::3Space::unproject_vector_inplace = 2
		Math::3Space::unproject_inplace = 3
	PPCODE:
		for (i= 1; i < items; i++) {
			if (!SvROK(ST(i)))
				croak("Expected vector at $_[%d]", (int)(i-1));
			vectype= m3s_read_vector_from_sv(vec, ST(i), pdl_dims, component_sv);
			switch (vectype) {
			case M3S_VECTYPE_VECOBJ:
				vecp= m3s_vector_get_array(ST(i));
				switch (ix) {
				case 0: m3s_space_project_vector(space, vecp); break;
				case 1: m3s_space_project_point(space, vecp); break;
				case 2: m3s_space_unproject_vector(space, vecp); break;
				default: m3s_space_unproject_point(space, vecp);
				}
				break;
			case M3S_VECTYPE_ARRAY:
			case M3S_VECTYPE_HASH:
				switch (ix) {
				case 0: m3s_space_project_vector(space, vec); break;
				case 1: m3s_space_project_point(space, vec); break;
				case 2: m3s_space_unproject_vector(space, vec); break;
				default: m3s_space_unproject_point(space, vec);
				}
				for (j=0; j < 3; j++)
					if (component_sv[j])
						sv_setnv(component_sv[j], vec[j]);
				break;
			case M3S_VECTYPE_PDL:
			case M3S_VECTYPE_PDLMULTI:
				{
					int count;
					dSP;
					if (!pdl_origin) {
						pdl_origin= sv_2mortal(m3s_pdl_vector(SPACE_ORIGIN(space), 3));
						pdl_matrix= sv_2mortal(m3s_pdl_matrix(SPACE_XV(space), !(ix&2) /*transpose bool*/));
					}
					ENTER;
					SAVETMPS;
					PUSHMARK(SP);
					EXTEND(SP, 4);
					PUSHs(ST(i));
					// project point subtracts origin
					PUSHs(ix == 3? pdl_origin : &PL_sv_undef);
					PUSHs(pdl_matrix);
					// unproject point adds origin
					PUSHs(ix == 1? pdl_origin : &PL_sv_undef);
					PUTBACK;
					count= call_pv("Math::3Space::_pdl_project_inplace", G_DISCARD);
					
					FREETMPS;
					LEAVE;
				}
				break;
			default:
				croak("bug: unhandled vec type");
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
			dst= (double*) m3s_make_aligned_buffer(buffer, sizeof(double)*16);
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
# Math::3Space::Projection
#**********************************************************************************************
MODULE = Math::3Space              PACKAGE = Math::3Space::Projection

SV *
_frustum(left, right, bottom, top, near_z, far_z)
	double left
	double right
	double bottom
	double top
	double near_z
	double far_z
	INIT:
		m3s_4space_projection_t proj;
		double w, h, d, w_1, h_1, d_1;
	CODE:
		w= right - left;
		h= top - bottom;
		d= far_z - near_z;
		if (fabs(w) < double_tolerance || fabs(h) < double_tolerance || fabs(d) < double_tolerance)
			croak("Described frustum has a zero-sized dimension");

		w_1= 1/w;
		h_1= 1/h;
		d_1= 1/d;
		proj.frustum.m00= near_z * 2 * w_1;
		proj.frustum.m11= near_z * 2 * h_1;
		proj.frustum.m20= (right+left) * w_1;
		proj.frustum.m21= (top+bottom) * h_1;
		proj.frustum.m22= -(near_z+far_z) * d_1;
		proj.frustum.m32= -2 * near_z * far_z * d_1;
		// use optimized version if m20 and m21 are zero
		proj.frustum.centered= fabs(proj.frustum.m20) < double_tolerance && fabs(proj.frustum.m21) < double_tolerance;
		RETVAL= m3s_wrap_projection(&proj,
			"Math::3Space::Projection::Frustum"
		);
	OUTPUT:
		RETVAL

SV *
_perspective(vertical_field_of_view, aspect, near_z, far_z)
	double vertical_field_of_view
	double aspect
	double near_z
	double far_z
	INIT:
		m3s_4space_projection_t proj;
		double f= tan(M_PI_2 - vertical_field_of_view * M_PI),
		       neg_inv_range_z= -1 / (far_z - near_z);
	CODE:
		proj.frustum.m00= f / aspect;
		proj.frustum.m11= f;
		proj.frustum.m20= 0;
		proj.frustum.m21= 0;
		proj.frustum.m22= (near_z+far_z) * neg_inv_range_z;
		proj.frustum.m32= 2 * near_z * far_z * neg_inv_range_z;
		proj.frustum.centered= true;
		RETVAL= m3s_wrap_projection(&proj, "Math::3Space::Projection::Frustum");
	OUTPUT:
		RETVAL

MODULE = Math::3Space              PACKAGE = Math::3Space::Projection::Frustum

# This is an optimized matrix multiplication taking advantage of all the
# zeroes and ones in both the 3Space matrix and the projection matrix.

void
matrix_colmajor(proj, space=NULL)
	m3s_4space_projection_t *proj
	m3s_space_t *space
	ALIAS:
		get_gl_matrix      = 0
		matrix_pack_float  = 1
		matrix_pack_double = 2
	INIT:
		double dst[16];
		struct m3s_4space_frustum_projection *f= &proj->frustum;
	PPCODE:
		if (!space) { /* user just wants the matrix itself */
			dst[ 0]= f->m00; dst[ 4]= 0;      dst[ 8]= f->m20;  dst[12]= 0;
			dst[ 1]= 0;      dst[ 5]= f->m11; dst[ 9]= f->m21;  dst[13]= 0;
			dst[ 2]= 0;      dst[ 6]= 0;      dst[10]= f->m22;  dst[14]= f->m32;
			dst[ 3]= 0;      dst[ 7]= 0;      dst[11]= -1;      dst[15]= 0;
		}
		else if (proj->frustum.centered) { /* centered frustum, optimize by assuming m20 and m21 are zero */
			dst[ 0]= f->m00 * SPACE_XV(space)[0];
			dst[ 1]= f->m11 * SPACE_XV(space)[1];
			dst[ 2]= f->m22 * SPACE_XV(space)[2];
			dst[ 3]=         -SPACE_XV(space)[2];
			dst[ 4]= f->m00 * SPACE_YV(space)[0];
			dst[ 5]= f->m11 * SPACE_YV(space)[1];
			dst[ 6]= f->m22 * SPACE_YV(space)[2];
			dst[ 7]=         -SPACE_YV(space)[2];
			dst[ 8]= f->m00 * SPACE_ZV(space)[0];
			dst[ 9]= f->m11 * SPACE_ZV(space)[1];
			dst[10]= f->m22 * SPACE_ZV(space)[2];
			dst[11]=         -SPACE_ZV(space)[2];
			dst[12]= f->m00 * SPACE_ORIGIN(space)[0];
			dst[13]= f->m11 * SPACE_ORIGIN(space)[1];
			dst[14]= f->m22 * SPACE_ORIGIN(space)[2] + f->m32;
			dst[15]=         -SPACE_ORIGIN(space)[2];
		} else {
			dst[ 0]= f->m00 * SPACE_XV(space)[0] +                               f->m20 * SPACE_XV(space)[2];
			dst[ 1]=                               f->m11 * SPACE_XV(space)[1] + f->m21 * SPACE_XV(space)[2];
			dst[ 2]=                                                             f->m22 * SPACE_XV(space)[2];
			dst[ 3]=                                                                     -SPACE_XV(space)[2];
			dst[ 4]= f->m00 * SPACE_YV(space)[0] +                               f->m20 * SPACE_YV(space)[2];
			dst[ 5]=                               f->m11 * SPACE_YV(space)[1] + f->m21 * SPACE_YV(space)[2];
			dst[ 6]=                                                             f->m22 * SPACE_YV(space)[2];
			dst[ 7]=                                                                     -SPACE_YV(space)[2];
			dst[ 8]= f->m00 * SPACE_ZV(space)[0] +                               f->m20 * SPACE_ZV(space)[2];
			dst[ 9]=                               f->m11 * SPACE_ZV(space)[1] + f->m21 * SPACE_ZV(space)[2];
			dst[10]=                                                             f->m22 * SPACE_ZV(space)[2];
			dst[11]=                                                                     -SPACE_ZV(space)[2];
			dst[12]= f->m00 * SPACE_ORIGIN(space)[0]                           + f->m20 * SPACE_ORIGIN(space)[2];
			dst[13]=                           f->m11 * SPACE_ORIGIN(space)[1] + f->m21 * SPACE_ORIGIN(space)[2];
			dst[14]=                                                             f->m22 * SPACE_ORIGIN(space)[2] + f->m32;
			dst[15]=                                                                     -SPACE_ORIGIN(space)[2];
		}
		if (ix & 3) { /* packed something */
			ST(0)= sv_newmortal();
			if (ix & 1) { /* packed floats */
				float *buf;
				int i;
				buf= (float*) m3s_make_aligned_buffer(ST(0), sizeof(float)*16);
				for (i= 0; i < 16; i++) buf[i]= (float) dst[i];
			} else {
				memcpy(m3s_make_aligned_buffer(ST(0), sizeof(double)*16), dst, sizeof(double)*16);
			}
			XSRETURN(1);
		} else {
			int i;
			EXTEND(SP, 16);
			for (i= 0; i < 16; i++)
				mPUSHn(dst[i]);
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
		M3S_VECLOAD(vec,vec_or_x,y,z,0);
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
			m3s_read_vector_from_sv(vec, ST(1), NULL, NULL);
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
		NV s, m= sqrt(m3s_vector_dotprod(vec,vec));
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
		M3S_VECLOAD(vec2,vec2_or_x,y,z,0);
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
		// single value should be treated as ($x,$x,$x) instead of ($x,0,0)
		if (looks_like_number(vec2_or_x)) {
			vec2[0]= SvNV(vec2_or_x);
			vec2[1]= y? SvNV(y) : vec2[0];
			vec2[2]= z? SvNV(z) : y? 1 : vec2[0];
		}
		else {
			m3s_read_vector_from_sv(vec2, vec2_or_x, NULL, NULL);
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
		M3S_VECLOAD(vec2,vec2_or_x,y,z,0);
		RETVAL= m3s_vector_dotprod(vec1, vec2);
	OUTPUT:
		RETVAL

NV
cos(vec1, vec2_or_x, y=NULL, z=NULL)
	m3s_vector_p vec1
	SV *vec2_or_x
	SV *y
	SV *z
	INIT:
		NV vec2[3];
	CODE:
		M3S_VECLOAD(vec2,vec2_or_x,y,z,0);
		RETVAL= m3s_vector_cosine(vec1, vec2);
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
			m3s_read_vector_from_sv(vec2, vec2_or_x, NULL, NULL);
			m3s_vector_cross(vec3, vec1, vec2);
			ST(0)= sv_2mortal(m3s_wrap_vector(vec3));
		} else if (z || !SvROK(vec2_or_x) || looks_like_number(vec2_or_x)) { // RET = vec1->cross(x,y,z)
			vec2[0]= SvNV(vec2_or_x);
			vec2[1]= SvNV(vec3_or_y);
			vec2[2]= z? SvNV(z) : 0;
			m3s_vector_cross(vec3, vec1, vec2);
			ST(0)= sv_2mortal(m3s_wrap_vector(vec3));
		} else {
			m3s_read_vector_from_sv(vec2, vec2_or_x, NULL, NULL);
			m3s_read_vector_from_sv(vec3, vec3_or_y, NULL, NULL);
			m3s_vector_cross(vec1, vec2, vec3);
			// leave $self on stack
		}
		XSRETURN(1);

BOOT:
	HV *inc= get_hv("INC", GV_ADD);
	AV *isa;
	hv_stores(inc, "Math::3Space::Projection",                  newSVpvs("Math/3Space.pm"));
	hv_stores(inc, "Math::3Space::Projection::Frustum",         newSVpvs("Math/3Space.pm"));
	isa= get_av("Math::3Space::Projection::Frustum::ISA", GV_ADD);
	av_push(isa, newSVpvs("Math::3Space::Projection"));
