#ifndef V8CONTEXT_H_
#define V8CONTEXT_H_

#include <v8.h>
#include "pl_config.h"
#include "pl_v8.h"

#define V8_OPT_NAME_GATHER_STATS      "gather_stats"
#define V8_OPT_NAME_SAVE_MESSAGES     "save_messages"
#define V8_OPT_NAME_MAX_MEMORY_BYTES  "max_memory_bytes"
#define V8_OPT_NAME_MAX_TIMEOUT_US    "max_timeout_us"

#define V8_OPT_FLAG_GATHER_STATS      0x01
#define V8_OPT_FLAG_SAVE_MESSAGES     0x02
#define V8_OPT_FLAG_MAX_MEMORY_BYTES  0x04
#define V8_OPT_FLAG_MAX_TIMEOUT_US    0x08

using namespace v8;

class V8Context {
    public:
        V8Context(HV* opt);
        ~V8Context();

        void reset();

        SV* get(const char* name);
        SV* exists(const char* name);
        SV* typeof(const char* name);
        SV* instanceof(const char* oname, const char* cname);

        void set(const char* name, SV* value);
        void remove(const char* name);

        SV* eval(const char* code, const char* file = 0);

        SV* global_objects();

        int run_gc();

        HV* get_stats();
        void reset_stats();

        HV* get_msgs();
        void reset_msgs();

        Isolate* isolate;
        Persistent<Context>* persistent_context;
        Persistent<ObjectTemplate>* persistent_template;

        uint64_t flags;
        HV* stats;
        HV* msgs;
        long pagesize_bytes;
        size_t max_allocated_bytes;  // unused for now
        double max_timeout_us;       // unused for now

        static uint64_t GetTypeFlags(const Local<Value>& v);
    private:
        int inited;
        Isolate::CreateParams create_params;

        static void initialize_v8();
        static void terminate_v8();
        static int instance_count;
        static std::unique_ptr<Platform> platform;

        void set_up();
        void tear_down();
};

#endif
