/* Creation date: 2008-09-28T00:16:00Z
 * Authors: Don
 */

#ifndef JSONEVT_PLUS_PLUS_H
#define JSONEVT_PLUS_PLUS_H


#include <jsonevt.h>

#include <vector>
#include <string>

class JSONEvt {
  public:

    JSONEvt() { };
    ~JSONEvt() { };


    static int parse_list_of_strings(const std::string& json_str,
        std::vector<std::string>& result, std::string& err_out);

    static int parse_list_of_strings(const char *json_str, uint json_str_size,
        std::vector<std::string>& result, std::string& err_out);
};

#endif
