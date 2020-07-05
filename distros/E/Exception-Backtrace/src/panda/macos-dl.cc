#if defined(__APPLE__)

#include <mach-o/dyld.h>
#include <cstdint>
#include <limits>
#include "dl.h"

namespace panda { namespace backtrace {

void gather_info(SharedObjectMap& container) {
    uint32_t count = _dyld_image_count();
    for(uint32_t i = 0; i < count; ++i) {
        auto raw_name = _dyld_get_image_name(i);
        auto offset = _dyld_get_image_vmaddr_slide(i);
        auto header = _dyld_get_image_header(i);

        auto cmd_offset = (header->magic == MH_MAGIC_64) ? sizeof(mach_header_64) : sizeof(mach_header);
        auto cmd = (load_command*)((char*)header + cmd_offset);

        std::uint64_t begin = offset;
        std::uint64_t size = 0;
        for(uint32_t j = 0; j < cmd->cmdsize; ++j) {
            if (cmd->cmd == LC_SEGMENT) {
                auto seg = (segment_command*)cmd;
                size += seg->vmsize;
            }
            else if (cmd->cmd == LC_SEGMENT_64) {
                auto seg = (segment_command_64*)cmd;
                size += seg->vmsize;
            }
            cmd = (struct load_command*)((char*)cmd + cmd->cmdsize);
        }

        std::uint64_t end = begin + size;
        string name(raw_name);
        //printf("b=%10p, e = %10p, name: %s\n", begin, end, raw_name);
        container.emplace_back(SharedObjectInfo{begin, end, false, name});
    }
};

}}

#endif
