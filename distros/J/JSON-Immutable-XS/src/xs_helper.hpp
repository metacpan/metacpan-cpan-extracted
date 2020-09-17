#pragma once

#include <panda/string.h>
#include <xs/dict.h>
#include <xs/export.h>

#include <dict.hpp>  //rapidjson conflicts with perl macroses

using namespace xs;
using panda::string;

namespace json_tree {

Sv dict2sv(const Dict* dict) {
    if (dict == nullptr) return Sv::undef;
    return std::visit(overloaded{
                          [](const Dict::ObjectMap& m) -> Sv {
                              auto ret = Hash::create(m.size());
                              for (const auto& r : m) ret[r.first.c_str()] = dict2sv(&r.second);
                              return Ref::create(ret);
                          },
                          [](const Dict::ObjectArr& a) -> Sv {
                              auto ret = Array::create(a.size());
                              for (const auto& r : a) ret.push(dict2sv(&r));
                              return Ref::create(ret);
                          },
                          [](panda::string s) -> Sv {
                              return Simple(s.c_str());
                          },
                          [](Undef) -> Sv {
                              return Sv::undef;
                          },
                          [](auto v) -> Sv {
                              return Simple(v);
                          },
                      },
                      dict->value);
}

Sv dict2sv_slice(const Dict* dict, panda::string field) {
    if (dict == nullptr) return Sv::undef;

    return std::visit(overloaded{
                          [&](const Dict::ObjectMap& m) -> Sv {
                              if (m.find(field) == m.end()) return Sv::undef;
                              return dict2sv(&m.at(field));
                          },
                          [&](const Dict::ObjectArr& a) -> Sv {
                              uint64_t i;
                              auto [p, ec] = std::from_chars(field.data(), field.data() + field.size(), i);
                              if (ec != std::errc() || i >= a.size()) return nullptr;

                              return dict2sv(&a[i]);
                          },
                          [](auto) -> Sv {
                              return Sv::undef;
                          },
                      },
                      dict->value);
}

struct StringArgsRange {
    SV** args;
    size_t _size;
    size_t size() const { return _size; }
    panda::string operator[](size_t i) const { return xs::in<panda::string>(args[i]); }
};

}  // namespace json_tree
