#include <panda/string.h>
#include <panda/excepted.h>

using panda::string;
using panda::unexpected;

class CapabilityErrors : public std::exception {
public:
    explicit CapabilityErrors(const char* message) : _msg(message) {}
    explicit CapabilityErrors(const string& message) : _msg(message) {}
    virtual ~CapabilityErrors() throw () {}
    virtual const char* what() const throw () { return _msg.c_str(); }

protected:
    string _msg;
};

namespace Capability {
    unexpected<CapabilityErrors> error(const string&);
    unexpected<CapabilityErrors> error(const string&, const int);
    unexpected<CapabilityErrors> error(const string&, const string&);
}