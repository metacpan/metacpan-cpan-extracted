
/* based on perl 5.18 pointer table */

struct smptr_tbl_ent {
    struct smptr_tbl_ent*       next;
    const void*                 oldval;
    void*                       newval;
};

struct smptr_tbl {
    struct smptr_tbl_ent**      tbl_ary;
    UV                          tbl_max;
    UV                          tbl_items;
    struct smptr_tbl_arena      *tbl_arena;
    struct smptr_tbl_ent        *tbl_arena_next;
    struct smptr_tbl_ent        *tbl_arena_end;
    bool                        tbl_split_disabled;
    bool                        tbl_split_needed;
};

typedef struct smptr_tbl_ent SMPTR_TBL_ENT_t;
typedef struct smptr_tbl     SMPTR_TBL_t;

