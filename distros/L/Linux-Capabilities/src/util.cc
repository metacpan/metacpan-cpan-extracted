#include "util.h"

string char_to_string(char* chr) {
    string str = panda::string(chr);
    cap_free(chr);
    return str;
}