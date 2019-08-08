#pragma once
#include <xs/Hash.h>
#include <xs/Stash.h>
#include <xs/Simple.h>
#include <initializer_list>

namespace xs { namespace exp {

struct Constant {
    using string_view = panda::string_view;
    string_view name;
    Sv          value;

    Constant (string_view name, const Sv& val)   : name(name), value(val) {}
    Constant (string_view name, string_view val) : name(name), value(Simple(val)) {}
    Constant (string_view name, int64_t val)     : name(name), value(Simple(val)) {}
};

void create_constant (Stash stash, const Constant& c);

inline void create_constant (Stash stash, panda::string_view name, const Sv& value)          { create_constant(stash, Constant(name, value)); }
inline void create_constant (Stash stash, panda::string_view name, panda::string_view value) { create_constant(stash, Constant(name, value)); }
inline void create_constant (Stash stash, panda::string_view name, int64_t value)            { create_constant(stash, Constant(name, value)); }

void create_constants (Stash stash, const std::initializer_list<Constant>& l);
void create_constants (Stash stash, const Hash& h);
void create_constants (Stash stash, SV*const* list, size_t items);

void register_export (const Stash& stash, panda::string_view name);

void export_sub       (const Stash& from, Stash to, panda::string_view name);
void export_constants (const Stash& from, Stash to);

Array constants_list (const Stash& stash);

void autoexport (Stash stash);

}}
