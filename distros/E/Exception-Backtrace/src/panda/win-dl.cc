#ifdef _WIN32

#include "panda/exception/win_debug.h"

#include <windows.h>
#include <dbgeng.h>
#include <climits>
#include <iostream>
#include <ios>
#include "SharedObjectInfo.h"

namespace panda { namespace backtrace {


class ModuleDebuggingSymbols: public debugging_symbols {

    using debugging_symbols::debugging_symbols;

public:
    void gather(SharedObjectMap& container) noexcept {
        ULONG modules_count = 0, modules_unloaded_count;
        bool ok;

        ok = S_OK == idebug_->GetNumberModules(&modules_count, &modules_unloaded_count);
        if (!ok) return;

        //std::cout << "Loaded modules : " << modules_count << "\n";

        for(ULONG i = 0; i < modules_count; ++i) {

            DEBUG_MODULE_PARAMETERS params;
            ok = S_OK == idebug_->GetModuleParameters(1, nullptr, i, &params);
            if (!ok) return;

            //std::cout << "base: " << std::hex << params.Base << ", size: " << params.Size << "\n";

            string image_name;
            image_name.reserve(params.ImageNameSize);
            ULONG ImageNameSize;
            ok = S_OK == idebug_->GetModuleNames(i, 0,
                                                 image_name.buf(), params.ImageNameSize, &ImageNameSize,
                                                 nullptr, 0, nullptr,
                                                 nullptr, 0, nullptr);
            if (!ok) return;
            image_name.length(ImageNameSize - 1); /* skip null-byte */
            //std::cout << "module " << i << ": " << image_name << "\n";
            auto info = SharedObjectInfo{params.Base,params.Base + params.Size, true, image_name};
            container.push_back(info);
        }
    }
};

void gather_info(SharedObjectMap& map) {
    ModuleDebuggingSymbols idebug;
    if (!idebug.is_inited()) { return; }
    idebug.gather(map);
}

}}

#endif
