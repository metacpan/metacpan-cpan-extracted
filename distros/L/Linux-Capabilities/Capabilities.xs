#include <xs.h>
#include <Capabilities.h>
#include <xs/export.h>
#include <panda/expected.h>

using panda::expected;
using panda::iptr;
using panda::make_iptr;
using panda::string;

using namespace xs;

namespace xs {

    template<> struct Typemap<Capabilities*> : TypemapObject<Capabilities*, Capabilities*, ObjectTypeRefcntPtr, ObjectStorageMG> {};

    template <> struct Typemap<CapFlags> : TypemapBase<CapFlags> {
        static Sv out (const CapFlags& data, const Sv& = {}) {
            auto out = Hash::create();

            out["effective"] = Simple((int)data.effective);
            out["permitted"] = Simple((int)data.permitted);
            out["inheritable"] = Simple((int)data.inheritable);

            return Ref::create(out);
        }
    };
}

MODULE = Linux::Capabilities   PACKAGE = Linux::Capabilities
PROTOTYPES: DISABLE

BOOT {
    using namespace xs::exp;
    Stash me(__PACKAGE__);
    create_constants(me, {
        {"CAP_CHOWN", (int)CAP_CHOWN},
        {"CAP_DAC_OVERRIDE", (int)CAP_DAC_OVERRIDE},
        {"CAP_DAC_READ_SEARCH", (int)CAP_DAC_READ_SEARCH},
        {"CAP_FOWNER", (int)CAP_FOWNER},
        {"CAP_FSETID", (int)CAP_FSETID},
        {"CAP_KILL", (int)CAP_KILL},

        {"CAP_SETGID", (int)CAP_SETGID},
        {"CAP_SETUID", (int)CAP_SETUID},
        {"CAP_SETPCAP", (int)CAP_SETPCAP},
        {"CAP_LINUX_IMMUTABLE", (int)CAP_LINUX_IMMUTABLE},
        {"CAP_NET_BIND_SERVICE", (int)CAP_NET_BIND_SERVICE},

        {"CAP_NET_BROADCAST", (int)CAP_NET_BROADCAST},
        {"CAP_NET_ADMIN", (int)CAP_NET_ADMIN},
        {"CAP_NET_RAW", (int)CAP_NET_RAW},
        {"CAP_IPC_LOCK", (int)CAP_IPC_LOCK},
        {"CAP_IPC_OWNER", (int)CAP_IPC_OWNER},

        {"CAP_SYS_MODULE", (int)CAP_SYS_MODULE},
        {"CAP_SYS_RAWIO", (int)CAP_SYS_RAWIO},
        {"CAP_SYS_CHROOT", (int)CAP_SYS_CHROOT},
        {"CAP_SYS_PTRACE", (int)CAP_SYS_PTRACE},
        {"CAP_SYS_PACCT", (int)CAP_SYS_PACCT},

        {"CAP_SYS_ADMIN", (int)CAP_SYS_ADMIN},
        {"CAP_SYS_BOOT", (int)CAP_SYS_BOOT},
        {"CAP_SYS_NICE", (int)CAP_SYS_NICE},
        {"CAP_SYS_RESOURCE", (int)CAP_SYS_RESOURCE},
        {"CAP_SYS_TIME", (int)CAP_SYS_TIME},

        {"CAP_SYS_TTY_CONFIG", (int)CAP_SYS_TTY_CONFIG},
        {"CAP_MKNOD", (int)CAP_MKNOD},
        {"CAP_LEASE", (int)CAP_LEASE},
        {"CAP_AUDIT_WRITE", (int)CAP_AUDIT_WRITE},
        {"CAP_AUDIT_CONTROL", (int)CAP_AUDIT_CONTROL},

        {"CAP_SETFCAP", (int)CAP_SETFCAP},
        {"CAP_MAC_OVERRIDE", (int)CAP_MAC_OVERRIDE},
        {"CAP_MAC_ADMIN", (int)CAP_MAC_ADMIN},
        {"CAP_SYSLOG", (int)CAP_SYSLOG},
        {"CAP_WAKE_ALARM", (int)CAP_WAKE_ALARM},

        {"CAP_BLOCK_SUSPEND", (int)CAP_BLOCK_SUSPEND},
        {"CAP_AUDIT_READ", (int)CAP_AUDIT_READ},

        {"CAP_EFFECTIVE", (int)CAP_EFFECTIVE},
        {"CAP_PERMITTED", (int)CAP_PERMITTED},
        {"CAP_INHERITABLE", (int)CAP_INHERITABLE},

        {"CAP_SET", (int)CAP_SET},
        {"CAP_CLEAR", (int)CAP_CLEAR}
    });
    autoexport(me);
}

iptr<Capabilities> empty(SV* CLASS) {
    PROTO = CLASS;
    RETVAL = Capabilities::init_empty().value();
}

iptr<Capabilities> from_file(SV* CLASS, string file_path) {
    PROTO = CLASS;
    RETVAL = Capabilities::init_from_file(file_path).value();
}

iptr<Capabilities> new(SV* CLASS, SV* arg = NULL) {
    if (items == 1) {
        RETVAL = Capabilities::init().value();
    } else {
        if (looks_like_number(arg)) {
            RETVAL = Capabilities::init(xs::in<pid_t>(arg)).value();
        } else {
            RETVAL = Capabilities::init(xs::in<string>(arg)).value();
        }
    }
}

int is_supported(SV* arg1, cap_value_t arg2 = 0) {
    cap_value_t value = items == 1 ? xs::in<cap_value_t>(arg1) : arg2;
    RETVAL = Capabilities::is_supported(value);
}

string get_name(SV* arg1, cap_value_t arg2 = 0) {
    cap_value_t value = items == 1 ? xs::in<cap_value_t>(arg1) : arg2;
    RETVAL = Capabilities::get_name(value).value();
}

string Capabilities::get_text() {
    RETVAL = THIS->get_text().value();
}

void Capabilities::submit() {
    THIS->submit();
}

void Capabilities::submit_to_file(string fpath) {
    THIS->submit_to_file(fpath);
}

int Capabilities::get_value_flag(cap_value_t value, int flag) {
    RETVAL = THIS->get_value_flag(value, (cap_flag_t)flag).value();
}

CapFlags Capabilities::get_value(cap_value_t value) {
    RETVAL = THIS->get_value(value).value();
}

CapabilitiesMap Capabilities::get_all() {
    RETVAL = THIS->get_all().value();
}

void Capabilities::raise(...) {
    if (items < 1) {
        throw std::invalid_argument("not a class method");
    }
    if (items == 1) {
        THIS->raise();
        XSRETURN_EMPTY;
    } 

    auto first = Scalar(ST(1));
    cap_values vals;

    if (first.is_array_ref()) {
        vals = xs::in<cap_values>(first);
    } else {
        vals = { xs::in<cap_value_t>(first) };
    }

    if (items == 2) {
        THIS->raise(vals);
        XSRETURN_EMPTY;
    }

    auto second = Scalar(ST(2));
    cap_flags flags;

    if (second.is_array_ref()) {
        flags = xs::in<cap_flags>(second);
    } else {
        flags = { xs::in<int>(second) };
    }

    THIS->raise(vals, flags);
}

void Capabilities::drop(...) {
    if (items < 1) {
        throw std::invalid_argument("not a class method");
    }
    if (items == 1) {
        THIS->drop();
        XSRETURN_EMPTY;
    } 

    auto first = Scalar(ST(1));
    cap_values vals;

    if (first.is_array_ref()) {
        vals = xs::in<cap_values>(first);
    } else {
        vals = { xs::in<cap_value_t>(first) };
    }

    if (items == 2) {
        THIS->drop(vals);
        XSRETURN_EMPTY;
    }

    auto second = Scalar(ST(2));
    cap_flags flags;

    if (second.is_array_ref()) {
        flags = xs::in<cap_flags>(second);
    } else {
        flags = { xs::in<int>(second) };
    }

    THIS->drop(vals, flags);
}
