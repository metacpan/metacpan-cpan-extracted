#include "Capabilities.h"

excepted<void, CapabilityErrors> Capabilities::set_flag(cap_values values, cap_flag_t flag, cap_flag_value_t flag_value) {
    for (auto value : values) {
        if (!is_supported(value)) {
            return error("not supported value: ", value);
        }
    }
    if (!CapFlags::supported(flag)) {
        return error("not supported flag: ", flag);
    }
    if (flag_value != CAP_SET && flag_value != CAP_CLEAR) {
        return error("bad flag_value: ", flag_value);
    }

    if (cap_set_flag(caps, flag, values.size(), &values.front(), flag_value) < 0) {
        return error("cap_set_flag failed");
    }

    return {};
}

excepted<void, CapabilityErrors> Capabilities::set(cap_values values, cap_flags flags, cap_flag_value_t flag_value) {
    Capabilities caps_old = *this;

    for ( const auto flag : flags ) {
        auto res = set_flag(values, (cap_flag_t)flag, flag_value);

        if (!res.has_value()) {
            *this = std::move(caps_old);
            return res;
        }
    }

    return {};
}

excepted<Capabilities*, CapabilityErrors> Capabilities::init_empty() {
    cap_t caps = cap_init();
    if (!caps) {
        return error("cap_clear failed");
    }

    return new Capabilities(caps);
}

excepted<Capabilities*, CapabilityErrors> Capabilities::init() {
    cap_t caps = cap_get_proc();
    if (!caps) {
        return error("cap_get_proc failed");
    }

    return new Capabilities(caps);
}

excepted<Capabilities*, CapabilityErrors> Capabilities::init(string str) {
    cap_t caps = cap_from_text(str.c_str());
    if (!caps) {
        return error("cap_from_text failed, input: ", str);
    }

    return new Capabilities(caps);
}

excepted<Capabilities*, CapabilityErrors> Capabilities::init(pid_t pid) {
    if ((pid <= 0) || (kill(pid, 0) < 0)) {
        return error("can\'t access proccess, pid: ", pid);
    }

    cap_t caps = cap_get_pid(pid);
    if (!caps) {
        return error("cap_get_pid failed, pid: ", pid);
    }

    return new Capabilities(caps);
}

Capabilities::Capabilities(const Capabilities & Cap) {
    if (this != &Cap) {
        if (!(caps = cap_dup(Cap.caps))) {
            throw CapabilityErrors("cap_dup failed");
        }
    }
}

Capabilities::Capabilities(Capabilities && Cap) : caps(Cap.caps) {
    Cap.caps = nullptr;
}

Capabilities& Capabilities::operator = (const Capabilities & Cap) {
    if (this != &Cap) {
        if (caps && cap_free(caps) < 0) {
            throw CapabilityErrors("cap_free failed");
        }
        if (!(caps = cap_dup(Cap.caps))) {
            throw CapabilityErrors("cap_dup failed");
        }
    }

    return *this;
}

Capabilities& Capabilities::operator = (Capabilities && Cap) {
    if (this != &Cap) {
        if(cap_free(caps) < 0) {
            throw CapabilityErrors("cap_free failed");
        }
        caps = Cap.caps;
        Cap.caps = nullptr;
    }

    return *this;
}

Capabilities::~Capabilities() {
    if (caps) {
        cap_free(caps);
    }
}

excepted<string, CapabilityErrors> Capabilities::get_text() {
    char* cstr;
    if (!(cstr = cap_to_text(caps, NULL))) {
        return error("cap_to_text failed");
    }

    return char_to_string(cstr);
}

excepted<CapFlags, CapabilityErrors> Capabilities::get_value(cap_value_t val) {
    if (!is_supported(val)) {
        return error("bad value: ", val);
    }

    CapFlags cflags;
    if (cap_get_flag(caps, val, CAP_EFFECTIVE, &cflags.effective) < 0) {
        return error("cap_get_flag effective failed");
    }
    if (cap_get_flag(caps, val, CAP_PERMITTED, &cflags.permitted) < 0) {
        return error("cap_get_flag permitted failed");
    }
    if (cap_get_flag(caps, val, CAP_INHERITABLE, &cflags.inheritable) < 0) {
        return error("cap_get_flag inheritable failed");
    }

    return cflags;
}

excepted<cap_flag_value_t, CapabilityErrors> Capabilities::get_value_flag(cap_value_t val, cap_flag_t flag) {
    if (!is_supported(val)) {
        return error("not supported value: ", val);
    }
    if (!CapFlags::supported(flag)) {
        return error("not supported flag: ", flag);
    }

    cap_flag_value_t cap_flag;
    if (cap_get_flag(caps, val, flag, &cap_flag) < 0) {
        return error("cap_get_flag failed");
    }

    return cap_flag;
}

excepted<void, CapabilityErrors> Capabilities::submit() {
    if (cap_set_proc(caps) < 0) {
        return error("cap_set_proc failed");
    }

    return {};
}

excepted<void, CapabilityErrors> Capabilities::drop(cap_values values, cap_flags flags) {
    return set(values, flags, CAP_CLEAR);
}

excepted<void, CapabilityErrors> Capabilities::raise(cap_values values, cap_flags flags) {
    return set(values, flags, CAP_SET);
}

excepted<CapabilitiesMap, CapabilityErrors> Capabilities::get_all() {
    CapabilitiesMap cmap;

    for (auto& value: cap_list) {
        CapFlags cflags;

        if (cap_get_flag(caps, value, CAP_EFFECTIVE, &cflags.effective) < 0) {
            return error("cap_get_flag effective failed");
        }
        if (cap_get_flag(caps, value, CAP_PERMITTED, &cflags.permitted) < 0) {
            return error("cap_get_flag permitted failed");
        }
        if (cap_get_flag(caps, value, CAP_INHERITABLE, &cflags.inheritable) < 0) {
            return error("cap_get_flag inheritable failed");
        }
        if (cflags.any()) {
            cmap.insert(std::pair<string,CapFlags>(char_to_string(cap_to_name(value)), cflags));
        }
    }
    return cmap;
}

cap_flags Capabilities::flag_list = {
    CAP_EFFECTIVE,
    CAP_PERMITTED,
    CAP_INHERITABLE
};

cap_values Capabilities::cap_list = {
    CAP_CHOWN,
    CAP_DAC_OVERRIDE,
    CAP_DAC_READ_SEARCH,
    CAP_FOWNER,
    CAP_FSETID,
    CAP_KILL,
    CAP_SETGID,
    CAP_SETUID,
    CAP_SETPCAP,
    CAP_LINUX_IMMUTABLE,
    CAP_NET_BIND_SERVICE,
    CAP_NET_BROADCAST,
    CAP_NET_ADMIN,
    CAP_NET_RAW,
    CAP_IPC_LOCK,
    CAP_IPC_OWNER,
    CAP_SYS_MODULE,
    CAP_SYS_RAWIO,
    CAP_SYS_CHROOT,
    CAP_SYS_PTRACE,
    CAP_SYS_PACCT,
    CAP_SYS_ADMIN,
    CAP_SYS_BOOT,
    CAP_SYS_NICE,
    CAP_SYS_RESOURCE,
    CAP_SYS_TIME,
    CAP_SYS_TTY_CONFIG,
    CAP_MKNOD,
    CAP_LEASE,
    CAP_AUDIT_WRITE,
    CAP_AUDIT_CONTROL,
    CAP_SETFCAP,
    CAP_MAC_OVERRIDE,
    CAP_MAC_ADMIN,
    CAP_SYSLOG,
    CAP_WAKE_ALARM,
    CAP_BLOCK_SUSPEND,
    CAP_AUDIT_READ
};