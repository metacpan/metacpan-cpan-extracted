#include "CapErrors.h"

namespace Capability {
    unexpected<CapabilityErrors> error(const string& message) {
        return unexpected<CapabilityErrors>(CapabilityErrors(message));
    };

    unexpected<CapabilityErrors> error(const string& message, const int arg) {
        return unexpected<CapabilityErrors>(CapabilityErrors(message + string::from_number(arg)));
    };

    unexpected<CapabilityErrors> error(const string& message, const string& arg) {
        return unexpected<CapabilityErrors>(CapabilityErrors(message + arg));
    };
}