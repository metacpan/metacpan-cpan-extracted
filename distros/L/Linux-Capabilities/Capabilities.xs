#include <xs.h>
#include <Capabilities.h>
#include <xs/export.h>
#include <panda/expected.h>

using panda::expected;
using panda::iptr;
using panda::make_iptr;
using panda::string;
using xs::exp::constant_t;
using xs::exp::create_constants;

using namespace xs;
using std::string_view;

namespace xs {

    template<> struct Typemap<Capabilities*> : TypemapObject<Capabilities*, Capabilities*, ObjectTypeRefcntPtr, ObjectStorageMG> {};

    template <> struct Typemap<CapFlags> : TypemapBase<CapFlags> {
        static Sv out (pTHX_ const CapFlags& data, const Sv& = {}) {
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
    constant_t clist[] = {
        {"CAP_CHOWN", (int)CAP_CHOWN, NULL},
        {"CAP_DAC_OVERRIDE", (int)CAP_DAC_OVERRIDE, NULL},
        {"CAP_DAC_READ_SEARCH", (int)CAP_DAC_READ_SEARCH, NULL},
        {"CAP_FOWNER", (int)CAP_FOWNER, NULL},
        {"CAP_FSETID", (int)CAP_FSETID, NULL},
        {"CAP_KILL", (int)CAP_KILL, NULL},

        {"CAP_SETGID", (int)CAP_SETGID, NULL},
        {"CAP_SETUID", (int)CAP_SETUID, NULL},
        {"CAP_SETPCAP", (int)CAP_SETPCAP, NULL},
        {"CAP_LINUX_IMMUTABLE", (int)CAP_LINUX_IMMUTABLE, NULL},
        {"CAP_NET_BIND_SERVICE", (int)CAP_NET_BIND_SERVICE, NULL},

        {"CAP_NET_BROADCAST", (int)CAP_NET_BROADCAST, NULL},
        {"CAP_NET_ADMIN", (int)CAP_NET_ADMIN, NULL},
        {"CAP_NET_RAW", (int)CAP_NET_RAW, NULL},
        {"CAP_IPC_LOCK", (int)CAP_IPC_LOCK, NULL},
        {"CAP_IPC_OWNER", (int)CAP_IPC_OWNER, NULL},

        {"CAP_SYS_MODULE", (int)CAP_SYS_MODULE, NULL},
        {"CAP_SYS_RAWIO", (int)CAP_SYS_RAWIO, NULL},
        {"CAP_SYS_CHROOT", (int)CAP_SYS_CHROOT, NULL},
        {"CAP_SYS_PTRACE", (int)CAP_SYS_PTRACE, NULL},
        {"CAP_SYS_PACCT", (int)CAP_SYS_PACCT, NULL},

        {"CAP_SYS_ADMIN", (int)CAP_SYS_ADMIN, NULL},
        {"CAP_SYS_BOOT", (int)CAP_SYS_BOOT, NULL},
        {"CAP_SYS_NICE", (int)CAP_SYS_NICE, NULL},
        {"CAP_SYS_RESOURCE", (int)CAP_SYS_RESOURCE, NULL},
        {"CAP_SYS_TIME", (int)CAP_SYS_TIME, NULL},

        {"CAP_SYS_TTY_CONFIG", (int)CAP_SYS_TTY_CONFIG, NULL},
        {"CAP_MKNOD", (int)CAP_MKNOD, NULL},
        {"CAP_LEASE", (int)CAP_LEASE, NULL},
        {"CAP_AUDIT_WRITE", (int)CAP_AUDIT_WRITE, NULL},
        {"CAP_AUDIT_CONTROL", (int)CAP_AUDIT_CONTROL, NULL},

        {"CAP_SETFCAP", (int)CAP_SETFCAP, NULL},
        {"CAP_MAC_OVERRIDE", (int)CAP_MAC_OVERRIDE, NULL},
        {"CAP_MAC_ADMIN", (int)CAP_MAC_ADMIN, NULL},
        {"CAP_SYSLOG", (int)CAP_SYSLOG, NULL},
        {"CAP_WAKE_ALARM", (int)CAP_WAKE_ALARM, NULL},

        {"CAP_BLOCK_SUSPEND", (int)CAP_BLOCK_SUSPEND, NULL},
        {"CAP_AUDIT_READ", (int)CAP_AUDIT_READ, NULL},

        {"CAP_EFFECTIVE", (int)CAP_EFFECTIVE, NULL},
        {"CAP_PERMITTED", (int)CAP_PERMITTED, NULL},
        {"CAP_INHERITABLE", (int)CAP_INHERITABLE, NULL},

        {"CAP_SET", (int)CAP_SET, NULL},
        {"CAP_CLEAR", (int)CAP_CLEAR, NULL},

        {"autoexport", 1, NULL},

        {NULL, 0, NULL}
    };
    create_constants(aTHX_ Stash(__PACKAGE__), clist);
}

iptr<Capabilities> empty(SV* CLASS) {
    PROTO = CLASS;
    RETVAL = Capabilities::init_empty().value();
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

string Capabilities::get_text() {
    RETVAL = THIS->get_text().value();
}

void Capabilities::submit() {
    THIS->submit();
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