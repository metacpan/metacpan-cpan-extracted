#include <sys/capability.h>

class CapFlags {
public:
    cap_flag_value_t effective;
    cap_flag_value_t permitted;
    cap_flag_value_t inheritable;

    static int supported(cap_flag_t flag) { return flag >= 0 && flag <= 3; };
    
    int any();
};