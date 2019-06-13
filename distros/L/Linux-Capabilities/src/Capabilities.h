#include <sys/capability.h>
#include <sys/types.h>
#include <signal.h>

#include <map>
#include <set>
#include <vector>

#include <panda/refcnt.h>
#include <panda/string.h>
#include <panda/excepted.h>

#include "CapFlags.h"
#include "CapErrors.h"
#include "util.h"

using panda::string;
using panda::excepted;
using Capability::error;
using CapabilitiesMap = std::map<string, CapFlags>;
using cap_values = std::vector<cap_value_t>;
using cap_flags = std::vector<int>;

class Capabilities : public virtual panda::Refcnt {
private:
    cap_t caps = nullptr;

    static cap_values   cap_list;
    static cap_flags    flag_list;

    static string get_name(cap_value_t);

    excepted<void, CapabilityErrors> set_flag(cap_values, cap_flag_t, cap_flag_value_t);
    excepted<void, CapabilityErrors> set(cap_values, cap_flags, cap_flag_value_t);

    Capabilities(cap_t c) { caps = c; }
public:
    static excepted<Capabilities*, CapabilityErrors> init_empty();
    static excepted<Capabilities*, CapabilityErrors> init();
    static excepted<Capabilities*, CapabilityErrors> init(string);
    static excepted<Capabilities*, CapabilityErrors> init(pid_t);

    Capabilities(const Capabilities&);
    Capabilities(Capabilities&&);

    Capabilities& operator=(const Capabilities&);
    Capabilities& operator=(Capabilities&&);

    ~Capabilities();
    static int is_supported(cap_value_t cap) { return CAP_IS_SUPPORTED(cap); }

    excepted <string, CapabilityErrors> get_text();

    excepted <void, CapabilityErrors> submit();

    excepted <CapFlags, CapabilityErrors> get_value(cap_value_t);
    excepted <cap_flag_value_t, CapabilityErrors> get_value_flag(cap_value_t, cap_flag_t);

    excepted <void, CapabilityErrors> drop(cap_values values = cap_list, cap_flags flags = flag_list);
    excepted <void, CapabilityErrors> raise(cap_values values = cap_list, cap_flags flags = flag_list);

    excepted<CapabilitiesMap, CapabilityErrors> get_all();
};