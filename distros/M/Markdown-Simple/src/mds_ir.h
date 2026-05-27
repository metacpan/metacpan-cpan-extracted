/* mds_ir.h — frozen event-stream IR.
 *
 * The parser never builds a tree. Block scanner and inline tokenizer
 * call into a SAX callbacks struct; renderer (or any other consumer)
 * implements the callbacks. Detail unions are stack-allocated by the
 * caller, never heap.
 */
#ifndef MDS_IR_H
#define MDS_IR_H

#include <stddef.h>
#include <stdint.h>

typedef enum {
    MDS_BLK_DOC = 0,
    MDS_BLK_PARAGRAPH,
    MDS_BLK_HEADING,
    MDS_BLK_CODE_INDENTED,
    MDS_BLK_CODE_FENCED,
    MDS_BLK_HTML,
    MDS_BLK_QUOTE,
    MDS_BLK_LIST,
    MDS_BLK_LIST_ITEM,
    MDS_BLK_THEMATIC_BREAK,
    MDS_BLK_TABLE,
    MDS_BLK_TABLE_HEAD,
    MDS_BLK_TABLE_BODY,
    MDS_BLK_TABLE_ROW,
    MDS_BLK_TABLE_CELL,
    MDS_BLK_FOOTNOTES_SECTION,  /* GFM §6.13 — <section class="footnotes"><ol> */
    MDS_BLK_FOOTNOTE_DEF,       /* GFM §6.13 — <li id="fn-LABEL"> */
    MDS_BLK__COUNT
} mds_block_type;

typedef enum {
    MDS_INL_TEXT = 0,
    MDS_INL_CODE,
    MDS_INL_EMPH,
    MDS_INL_STRONG,
    MDS_INL_LINK,
    MDS_INL_IMAGE,
    MDS_INL_LINEBREAK,
    MDS_INL_SOFTBREAK,
    MDS_INL_STRIKE,
    MDS_INL_HTML_INLINE,
    MDS_INL_AUTOLINK,
    MDS_INL_FOOTNOTE_REF,       /* GFM §6.13 — <sup><a href="#fn-...">N</a></sup> */
    MDS_INL__COUNT
} mds_inline_type;

typedef enum {
    MDS_ALIGN_NONE   = 0,
    MDS_ALIGN_LEFT   = 1,
    MDS_ALIGN_CENTER = 2,
    MDS_ALIGN_RIGHT  = 3
} mds_align;

/* Per-block detail, stack-allocated, valid only for the duration of one
 * enter_block callback. */
typedef struct {
    union {
        struct { int level; }                          heading;
        struct { const char* info; size_t info_len; } code_fenced;
        struct {
            int          is_ordered;
            int          is_tight;
            int          start;       /* 1 for unordered */
            char         marker;      /* '-' '+' '*' '.' ')' */
        } list;
        struct { int is_task; int checked; } list_item;
        struct { unsigned ncols; const mds_align* aligns; } table;
        struct { mds_align align; }                    table_cell;
        struct { const char* label; size_t label_len;
                 const char* body;  size_t body_len; }  footnote_def;
    } u;
} mds_block_detail;

typedef struct {
    union {
        struct { const char* href; size_t href_len;
                 const char* title; size_t title_len; } link;
        struct { const char* href; size_t href_len;
                 const char* alt;   size_t alt_len;
                 const char* title; size_t title_len; } image;
        struct { const char* uri; size_t uri_len;
                 int is_email; }                       autolink;
        struct { const char* label; size_t label_len; } footnote_ref;
    } u;
} mds_inline_detail;

/* SAX callbacks. NULL members are skipped. */
typedef struct mds_callbacks {
    void (*enter_block) (void* ud, mds_block_type, const mds_block_detail*);
    void (*leave_block) (void* ud, mds_block_type);
    void (*enter_inline)(void* ud, mds_inline_type, const mds_inline_detail*);
    void (*leave_inline)(void* ud, mds_inline_type);
    void (*text)        (void* ud, const char* s, size_t n);
    /* Raw text already escaped for HTML, used by code spans / inline HTML
     * pass-through. */
    void (*raw)         (void* ud, const char* s, size_t n);
} mds_callbacks;

#endif
