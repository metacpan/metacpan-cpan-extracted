#include "PerlTrace.h"

using panda::string;

namespace xs {

string PerlTrace::to_string() const {
    string r;
    for (const auto& frame : frames) {
        r += frame->library;
        r += "::";
        r += frame->name;
        r += "(";
        auto& args = frame->args;
        auto last = args.size() - 1;
        for (size_t i = 0; i < args.size(); ++i) {
            r += args[i];
            if (i < last) { r += ", "; }
        }
        r += ")";
        r += " at ";
        r += frame->file;
        r += ":";
        r += string::from_number(frame->line_no, 10);
        r += "\n";
    }
    return r;
}

}
