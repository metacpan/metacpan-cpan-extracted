#include <xs.h>
#include <xs/export.h>
using namespace xs;
using namespace xs::exp;

static void throw_nopackage (const Simple& name) {
    throw Simple::format("Export::XS: package '%" SVf "' doesn't exist", SVfARG(name.get()));
}

MODULE = Export::XS                PACKAGE = Export::XS
PROTOTYPES: DISABLE

void import (Simple ctx_class, ...) {
    Stash caller_stash = CopSTASH(PL_curcop);
    
    bool create = false;
    panda::string_view ctx_clname = ctx_class;
    if      (ctx_clname == "Export::XS") create = true;
    else if (ctx_clname == "Export::XS::Auto") {
        create = true;
        autoexport(caller_stash);
    }
    
    if (create) {
        if (items < 2) XSRETURN_EMPTY;
        if (Sv(ST(1)).is_hash_ref()) create_constants(caller_stash, ST(1));
        else                         create_constants(caller_stash, &ST(1), items-1);
    }
    else {
        auto ctx_stash = Stash::from_name(ctx_class);
        if (!ctx_stash) throw_nopackage(ctx_class);
        if (items > 1) {
            for (I32 i = 1; i < items; ++i) {
                panda::string_view name = Simple(ST(i));
                if (name == ":const") export_constants(ctx_stash, caller_stash);
                else                  export_sub(ctx_stash, caller_stash, name);
            }
        }
        else export_constants(ctx_stash, caller_stash);
    }
}    

Array constants_list (Simple ctx_class) {
    auto ctx_stash = Stash::from_name(ctx_class);
    if (!ctx_stash) throw_nopackage(ctx_class);
    RETVAL = constants_list(ctx_stash);
}

void export_constants (Simple ctx_class, Simple trg_class) {
    auto ctx_stash = Stash::from_name(ctx_class);
    if (!ctx_stash) throw_nopackage(ctx_class);
    auto trg_stash = Stash::from_name(trg_class);
    if (!trg_stash) throw_nopackage(trg_class);
    
    export_constants(ctx_stash, trg_stash);
}
