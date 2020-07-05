#if !defined(__APPLE__) && !defined(_WIN32)

#include <link.h>
#include <limits.h>     // PATH_MAX
#include <unistd.h>
#include <sys/stat.h>
#include "dl.h"


namespace panda { namespace backtrace {

int dl_iterate(struct dl_phdr_info *info, size_t, void* data){
    //printf("so: %s at %lx\n", info->dlpi_name, info->dlpi_addr);
    if (info->dlpi_name) {
        string name = string(info->dlpi_name);
        /* special case - read self */
        if (name.length() == 0) {
            name.reserve(PATH_MAX);
            auto len = readlink("/proc/self/exe", name.buf(), PATH_MAX);
            if (len > 0) {
                name.length(static_cast<size_t>(len));
            }
        }
        if (!name) { return 0; }

        auto container = reinterpret_cast<SharedObjectMap*>(data);
        auto end = info->dlpi_addr;
        for (int j = 0; j < info->dlpi_phnum; j++) {
            auto& header = info->dlpi_phdr[j];
            auto s = info->dlpi_addr + header.p_vaddr;
            auto e =  s + header.p_memsz;
            if (e > end) { end = e; }
            //printf("\t\t header %2d: address=%10p .. %10p [%s at %10p]\n", j, (void *) start, (void*) end, info->dlpi_name, info->dlpi_addr);
        }
        auto begin = static_cast<std::uint64_t>(info->dlpi_addr);
        container->emplace_back(SharedObjectInfo{begin, static_cast<std::uint64_t>(end), false, name});
    }

    return 0;
}


void gather_info(SharedObjectMap& map) {
    dl_iterate_phdr(dl_iterate, &map);
}

}}

#endif
