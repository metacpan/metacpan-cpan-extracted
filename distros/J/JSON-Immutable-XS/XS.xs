#include <dict.hpp>
#include <xs_helper.hpp>
#include <xs/export.h>
#include <xs/dict.h>
#include <panda/string.h>

using namespace json_tree;
using namespace xs;
using panda::string;

MODULE = JSON::Immutable::XS      PACKAGE = JSON::Immutable::XS
PROTOTYPES: DISABLE

Dict * new(SV* CLASS, panda::string filename){
    PROTO = CLASS;
    RETVAL = new Dict(filename);
}

void Dict::load_dict( panda::string filename )

void Dict::dump() : const

Sv Dict::keys() : const {
    Array ret = Array::create();
    std::vector<panda::string> keys = THIS->keys();
    for ( auto k = keys.begin(); k != keys.end(); ++k ){
        ret.push(xs::out<panda::string>(*k));
    }
    RETVAL = Ref::create(ret);
}

const Dict* Dict::get( ... ) : const {
    RETVAL = THIS->get(StringArgsRange{&ST(1), items-1}, 0 );
}

Sv Dict::get_value( ... ) : const {
    RETVAL = dict2sv(THIS->get( StringArgsRange{&ST(1), items-1}, 0 ));
}

Sv Dict::slice( ... ) : const {
    if ( items < 2) XSRETURN_UNDEF;
    StringArgsRange args = StringArgsRange{&ST(1), items-2};
    panda::string field = xs::in<panda::string>(ST(items-1));
    RETVAL = std::visit(overloaded{
                            [&](const Dict::ObjectMap& m) -> Sv {
                                auto ret = Hash::create(m.size());
                                for (const auto& r : m){
                                    ret[r.first.c_str()] = dict2sv_slice(r.second.get(args,0), field);
                                }
                                return Ref::create(ret);
                            },
                            [&](const Dict::ObjectArr& a) -> Sv {
                                auto ret = Array::create(a.size());
                                for ( const auto& r : a ){
                                    ret.push( dict2sv_slice( r.get(args,0), field ) );
                                }
                                return Ref::create(ret);
                            },
                            [](auto) -> Sv {
                                return Sv::undef;
                            }
                        },
                        THIS->value);
}

Sv Dict::size( ... ) : const {
    const Dict* d = THIS->get(StringArgsRange{&ST(1), items-1},0);
    if (d == nullptr) XSRETURN_UNDEF;
    RETVAL = std::visit(overloaded{
                            [&](const Dict::ObjectMap& m) -> Sv {
                                return Simple(m.size());
                            },
                            [&](const Dict::ObjectArr& a) -> Sv {
                                return Simple(a.size());
                            },
                            [](auto) -> Sv {
                                return Sv::undef;
                            }
                        },
                        d->value);
}

uint Dict::exists( ... ) : const {
    RETVAL=(THIS->get(StringArgsRange{&ST(1), items-1},0) == nullptr) ? 0 : 1;
}

Sv Dict::export() : const {
    RETVAL = dict2sv( THIS );
}
