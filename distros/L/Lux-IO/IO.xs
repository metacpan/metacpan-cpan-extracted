#include <luxio/btree.h>

#define PERL_NO_GET_CONTEXT

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#ifdef __cplusplus
}
#endif

#define XS_STATE(type, x) \
    INT2PTR(type, SvROK(x) ? SvIV(SvRV(x)) : SvIV(x))

#define XS_STRUCT2OBJ(sv, class, obj) \
    if (obj == NULL) { \
        sv_setsv(sv, &PL_sv_undef); \
    } else { \
        sv_setref_pv(sv, class, (void *) obj); \
    }

typedef Lux::IO::db_flags_t    Lux_IO_db_flags_t;
typedef Lux::IO::db_index_t    Lux_IO_db_index_t;
typedef Lux::IO::insert_mode_t Lux_IO_insert_mode_t;
typedef Lux::IO::Btree         Lux_IO_Btree;

MODULE=Lux::IO    PACKAGE=Lux::IO    PREFIX=xs_lux_io_

BOOT:
    HV *stash;
    stash = gv_stashpv("Lux::IO", 1);
    newCONSTSUB(stash, "DB_RDONLY"  , newSViv(Lux::IO::DB_RDONLY));
    newCONSTSUB(stash, "DB_RDWR"    , newSViv(Lux::IO::DB_RDWR));
    newCONSTSUB(stash, "DB_CREAT"   , newSViv(Lux::IO::DB_CREAT));
    newCONSTSUB(stash, "DB_TRUNC"   , newSViv(Lux::IO::DB_TRUNC));
    newCONSTSUB(stash, "NONCLUSTER" , newSViv(Lux::IO::NONCLUSTER));
    newCONSTSUB(stash, "CLUSTER"    , newSViv(Lux::IO::CLUSTER));
    newCONSTSUB(stash, "OVERWRITE"  , newSViv(Lux::IO::OVERWRITE));
    newCONSTSUB(stash, "NOOVERWRITE", newSViv(Lux::IO::NOOVERWRITE));
    newCONSTSUB(stash, "APPEND"     , newSViv(Lux::IO::APPEND));

MODULE=Lux::IO    PACKAGE=Lux::IO::Btree    PREFIX=xs_lux_io_

Lux_IO_Btree*
xs_lux_io_btree_new(int index_type)
CODE:
    RETVAL = new Lux::IO::Btree((Lux::IO::db_index_t) index_type);
OUTPUT:
    RETVAL

void
xs_lux_io_btree_free(Lux_IO_Btree* bt)
CODE:
    bt->close();
    delete bt;

bool
xs_lux_io_btree_open(Lux_IO_Btree* bt, const char* db_name, int oflags)
CODE:
    RETVAL = bt->open(db_name, (Lux::IO::db_flags_t) oflags);
OUTPUT:
    RETVAL

bool
xs_lux_io_btree_close(Lux_IO_Btree* bt)
CODE:
    RETVAL = bt->close();
OUTPUT:
    RETVAL

SV*
xs_lux_io_btree_get(Lux_IO_Btree* bt, const char* key)
CODE:
    Lux::IO::data_t  k = { key, strlen(key) };
    Lux::IO::data_t* v = bt->get(&k);
    if (v) {
        RETVAL = newSVpv((char *)v->data, v->size);
        bt->clean_data(v);
    } else {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

bool
xs_lux_io_btree_put(Lux_IO_Btree* bt, const char* key, const char* value, int length, int insert_mode)
CODE:
    Lux::IO::data_t k = { key,   strlen(key)   };
    Lux::IO::data_t v = { value, length };
    RETVAL = bt->put(&k, &v, (Lux::IO::insert_mode_t) insert_mode);
OUTPUT:
    RETVAL

bool
xs_lux_io_btree_del(Lux_IO_Btree* bt, const char *key)
CODE:
    Lux::IO::data_t k = { key, strlen(key) };
    RETVAL = bt->del(&k);
OUTPUT:
    RETVAL
