#include "CTrace.h"

using panda::string;

namespace panda { namespace backtrace {

string CTrace::to_string() const {
    string r;
    for(auto& frame: frames) {
        // mimic gdb-style
        r += "0x";
        r += string::from_number(frame->address, 16);
        if (frame->name) {
            r += " in ";
            r += frame->name;
        }
        if (frame->file) {
            r += " at ";
            r += frame->file;
            if (frame->line_no) {
                r += ":";
                r += string::from_number(frame->line_no, 10);
            }
        } else if(frame->library) {
            r += " from ";
            r += frame->library;
        }
        r += "\n";
    }
    return r;
}

}}
