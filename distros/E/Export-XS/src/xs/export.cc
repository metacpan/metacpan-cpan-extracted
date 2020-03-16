#include "export.h"
#include <xs/Ref.h>
#include <xs/Array.h>
#include <panda/optional.h>

namespace xs { namespace exp {

using panda::string;
using panda::string_view;

static PERL_THREAD_LOCAL struct {
    Hash  clists;
    Stash self_stash = Stash("Export::XS", GV_ADD);
} tls;

static bool _init () {
    xs::at_perl_destroy([]{
        tls.clists     = nullptr;
        tls.self_stash = nullptr;
    });
    return true;
}
static bool __init = _init();

static void throw_noname (Stash s) { throw std::logic_error(string("Export::XS: can't define a constant with an empty name in '") + s.name() + "'"); }

Array constants_list (const Stash& stash) {
    if (!tls.clists) tls.clists = Hash::create();
    auto clist = tls.clists[stash.name()];
    if (!clist.defined()) clist = Ref::create(Array::create());
    return Array(clist);
}

static void register_export_impl (const Stash& stash, string_view name, Array clist) {
    if (!name.length()) throw_noname(stash);
    if (!clist) clist = constants_list(stash);
    clist.push(Simple(name));
}

void register_export (const Stash& stash, string_view name) {
    register_export_impl(stash, name, {});
}

static void create_constant_impl (Stash& stash, const Constant& c, Array clist) {
    if (!c.name.length()) throw_noname(stash);

    // check that we won't redefine any subroutine
    if (stash.sub(c.name)) throw std::logic_error(string("Export::XS: can't create constant '") + stash.name() + "::" + c.name + "' - symbol already exists");

    stash.add_const_sub(c.name, c.value);
    register_export_impl(stash, c.name, clist);
}

void create_constant (Stash stash, const Constant& c) {
    create_constant_impl(stash, c, {});
}

void create_constants (Stash stash, const std::initializer_list<Constant>& list) {
    auto clist = constants_list(stash);
    for (auto& c : list) create_constant_impl(stash, c, clist);
}

void create_constants (Stash stash, const Hash& hash) {
    auto clist = constants_list(stash);
    for (const auto& row : hash) create_constant_impl(stash, Constant(row.key(), row.value()), clist);
}

void create_constants (Stash stash, SV*const* list, size_t items) {
    if (!list || !items) return;
    auto clist = constants_list(stash);
    for (size_t i = 0; i < items - 1; i += 2) {
        Simple name  = *list++;
        Sv     value = *list++;
        create_constant_impl(stash, Constant(name, value), clist);
    }
}

void export_sub (const Stash& from, Stash to, string_view name) {
    auto gv = from.fetch(name);
    if (!gv.sub()) throw std::logic_error(string("Export::XS: can't export unexisting symbol '") + from.name() + "::" + name + "'");
    to[name] = gv; // "to[name] = sub" leads to "used once once" warning. setting the whole glob supresses the warning
}

void export_constants (const Stash& from, Stash to) {
    auto clist = constants_list(from);
    for (const auto& elem : clist) export_sub(from, to, Simple(elem));
}

void autoexport (Stash stash) {
    auto gv = tls.self_stash["import"];
    auto dsub = stash.sub("import");
    if (dsub && dsub != gv.sub() && (!dsub.stash() || dsub.stash().name() != "UNIVERSAL")) {
        throw std::logic_error(string("Export::XS: can't make autoexport for stash '") + stash.name() + "' - you already have import() sub");
    }
    stash["import"] = gv;
}

}}
