#ifndef JSF_IR_H
#define JSF_IR_H

/* The arena IR: one jsf_node_t per subschema, aggregating every keyword that
 * applies to it. `present` is a bitmap of which keyword fields are live (so 0
 * is a legal value for e.g. `minimum`); child schemas and value blocks are
 * referenced by arena OFFSET, never a pointer (principle 9). Draft 2020-12
 * v0.01 subset - see plan_json_schema_fast/phase-02-schema-ir.md.
 *
 * Needs jsf_arena.h; the parser that fills these lives in jsf_parse.h. */

/* ---- present-keyword bits (uint64) -------------------------------------- */
#define JSF_HAS_TYPE       (1ULL<<0)
#define JSF_HAS_ENUM       (1ULL<<1)
#define JSF_HAS_CONST      (1ULL<<2)
#define JSF_HAS_MIN        (1ULL<<3)
#define JSF_HAS_MAX        (1ULL<<4)
#define JSF_HAS_EXMIN      (1ULL<<5)
#define JSF_HAS_EXMAX      (1ULL<<6)
#define JSF_HAS_MULOF      (1ULL<<7)
#define JSF_HAS_MINLEN     (1ULL<<8)
#define JSF_HAS_MAXLEN     (1ULL<<9)
#define JSF_HAS_PATTERN    (1ULL<<10)
#define JSF_HAS_FORMAT     (1ULL<<11)
#define JSF_HAS_ITEMS      (1ULL<<12)
#define JSF_HAS_PREFIX     (1ULL<<13)
#define JSF_HAS_MINITEMS   (1ULL<<14)
#define JSF_HAS_MAXITEMS   (1ULL<<15)
#define JSF_HAS_UNIQUE     (1ULL<<16)
#define JSF_HAS_CONTAINS   (1ULL<<17)
#define JSF_HAS_MINCONT    (1ULL<<18)
#define JSF_HAS_MAXCONT    (1ULL<<19)
#define JSF_HAS_PROPS      (1ULL<<20)
#define JSF_HAS_PATPROPS   (1ULL<<21)
#define JSF_HAS_ADDPROPS   (1ULL<<22)
#define JSF_HAS_REQUIRED   (1ULL<<23)
#define JSF_HAS_MINPROPS   (1ULL<<24)
#define JSF_HAS_MAXPROPS   (1ULL<<25)
#define JSF_HAS_PROPNAMES  (1ULL<<26)
#define JSF_HAS_DEPREQ     (1ULL<<27)
#define JSF_HAS_ALLOF      (1ULL<<28)
#define JSF_HAS_ANYOF      (1ULL<<29)
#define JSF_HAS_ONEOF      (1ULL<<30)
#define JSF_HAS_NOT        (1ULL<<31)
#define JSF_HAS_IF         (1ULL<<32)
#define JSF_HAS_REF        (1ULL<<33)
#define JSF_HAS_DEFAULT    (1ULL<<34)
#define JSF_HAS_DEPSCHEMAS (1ULL<<35)
#define JSF_HAS_UNEVALPROPS (1ULL<<36)
#define JSF_HAS_UNEVALITEMS (1ULL<<37)
#define JSF_HAS_DYNREF      (1ULL<<38)

/* ---- fast-path tags (principle 4) --------------------------------------- */
#define JSF_TAG_NORMAL        0
#define JSF_TAG_TRUE          1   /* true / {} : always valid */
#define JSF_TAG_FALSE         2   /* false     : always invalid */
#define JSF_TAG_TYPE_LEAF     3   /* only `type` present */
#define JSF_TAG_CONST_LEAF    4
#define JSF_TAG_ENUM_LEAF     5
#define JSF_TAG_PLAIN_OBJECT  6   /* type:object (+properties/+required) only */

#define JSF_NO_IDX 0xFFFFFFFFu

/* additionalProperties: present with addprops_off == JSF_NULL_OFF means the
 * schema was `false`; a non-zero offset is the subschema node. */

/* ---- block layouts (all arena-resident, offset-addressed) --------------- */

/* one entry of a `properties` table (sorted by name for O(log n) bsearch and
 * deterministic order); hash is PERL_HASH of the name, computed at compile. */
typedef struct jsf_propent {
    uint32_t name_off;    /* interned jsf_str_t */
    uint32_t child_off;   /* schema node */
    U32      hash;        /* PERL_HASH(name) */
    uint32_t name_len;
} jsf_propent;

typedef struct jsf_proptab { uint32_t n; /* jsf_propent[n] follows */ } jsf_proptab;

/* one `required` name, with its index into the (sorted) proptab or JSF_NO_IDX */
typedef struct jsf_reqent { uint32_t name_off; uint32_t prop_idx; } jsf_reqent;
typedef struct jsf_reqset { uint32_t n; /* jsf_reqent[n] follows */ } jsf_reqset;

/* one `patternProperties` entry: interned pattern string + subschema */
typedef struct jsf_patent { uint32_t pat_off; uint32_t child_off; } jsf_patent;
typedef struct jsf_pattab { uint32_t n; /* jsf_patent[n] follows */ } jsf_pattab;

/* a list of subschema node offsets (prefixItems, allOf, anyOf, oneOf) */
typedef struct jsf_offlist { uint32_t n; /* uint32_t off[n] follows */ } jsf_offlist;

/* one `dependentRequired` entry: a property name -> a list of required names */
typedef struct jsf_depent { uint32_t name_off; uint32_t names_off; } jsf_depent;
typedef struct jsf_deptab { uint32_t n; /* jsf_depent[n] follows */ } jsf_deptab;

/* one `dependentSchemas` entry: a property name -> a subschema applied to the
 * whole object when that property is present */
typedef struct jsf_dsent { uint32_t name_off; uint32_t sch_off; } jsf_dsent;
typedef struct jsf_dstab { uint32_t n; /* jsf_dsent[n] follows */ } jsf_dstab;

/* ---- the schema node ---------------------------------------------------- */
typedef struct jsf_node {
    U64      present;      /* JSF_HAS_* bitmap */
    uint32_t type_mask;    /* JSF_T_* from `type` */
    uint8_t  tag;          /* JSF_TAG_* */
    uint8_t  unique;       /* uniqueItems bool */
    uint8_t  _pad[2];

    /* type/enum/const: enum/const values live in the compiled keepalive AV */
    uint32_t enum_keep;    /* first keep index */
    uint32_t enum_n;       /* count */
    uint32_t const_keep;   /* keep index */
    uint32_t default_keep; /* keep index of `default` value (apply_defaults) */

    /* numbers */
    NV       minimum, maximum, exmin, exmax, mulof;

    /* strings */
    UV       min_length, max_length;
    uint32_t pattern_off;  /* interned */
    uint32_t format_off;   /* interned */

    /* arrays */
    uint32_t items_off;    /* node */
    uint32_t prefix_off;   /* jsf_offlist */
    UV       min_items, max_items;
    uint32_t contains_off; /* node */
    UV       min_contains, max_contains;

    /* objects */
    uint32_t props_off;    /* jsf_proptab */
    uint32_t patprops_off; /* jsf_pattab */
    uint32_t addprops_off; /* node, or JSF_NULL_OFF meaning `false` */
    uint32_t required_off; /* jsf_reqset */
    UV       min_props, max_props;
    uint32_t propnames_off;/* node */
    uint32_t depreq_off;   /* jsf_deptab */
    uint32_t depsch_off;   /* jsf_dstab */
    uint32_t unevalprops_off; /* node (unevaluatedProperties) */
    uint32_t unevalitems_off; /* node (unevaluatedItems) */

    /* applicators */
    uint32_t allof_off, anyof_off, oneof_off;  /* jsf_offlist */
    uint32_t not_off;                          /* node */
    uint32_t if_off, then_off, else_off;       /* node */

    /* core */
    uint32_t ref_off;         /* resolved target node ($ref, or $dynamicRef fallback) */
    uint32_t schema_path_off; /* interned JSON Pointer to this subschema (no '#') */
    uint32_t base_off;        /* interned base URI of this node's resource */
    uint32_t dynref_name_off; /* interned $dynamicRef fragment name (dynamic search) */
} jsf_node_t;

#endif /* JSF_IR_H */
