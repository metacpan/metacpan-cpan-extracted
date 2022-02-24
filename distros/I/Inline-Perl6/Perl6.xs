#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <moar.h>
#include "Perl6.h"

#ifdef PERL_IMPLICIT_CONTEXT
    #define create_p6 p5_callback(my_perl)
#else
    #define create_p6 p5_callback(NULL)
#endif

SV *(*p5_callback)(PerlInterpreter *);
MVMInstance *instance;
MVMCompUnit *cu;
/* Points to the current opcode. */
MVMuint8 *cur_op = NULL;
/* The current frame's bytecode start. */
MVMuint8 *bytecode_start = NULL;
/* Points to the base of the current register set for the frame we
 * are presently in. */
MVMRegister *reg_base = NULL;
SV *perl6;
const char *filename = PERL6_INSTALL_PATH "/runtime/perl6.moarvm";

static void toplevel_initial_invoke(MVMThreadContext *tc, void *data) {
    /* Create initial frame, which sets up all of the interpreter state also. */
    MVM_frame_dispatch_zero_args(tc, ((MVMStaticFrame *)data)->body.static_code);
}

void init_inline_perl6_new_callback(SV *(*new_p5_callback)(PerlInterpreter *)) {
    p5_callback = new_p5_callback;
}

char *library_location, *helper_path;
const char *raw_clargs[2];

const char  *lib_path[3] = {
    NQP_LIBDIR,
    PERL6_INSTALL_PATH "/lib",
    PERL6_INSTALL_PATH "/runtime",
};

MODULE = Inline::Perl6		PACKAGE = Inline::Perl6		

void setup_library_location(path, helper)
        char *path
	char *helper
    CODE:
        raw_clargs[0] = helper_path = helper;
        raw_clargs[1] = library_location = path;

void
initialize()
    CODE:
        MVM_crash_on_error();

        instance   = MVM_vm_create_instance();

        /* stash the rest of the raw command line args in the instance */
        MVM_vm_set_prog_name(instance, PERL6_INSTALL_PATH "/runtime/perl6.moarvm");
        MVM_vm_set_exec_name(instance, PERL6_EXECUTABLE);
        MVM_vm_set_lib_path(instance, 3, (const char **)lib_path);
        MVM_vm_set_clargs(instance, 0, NULL);

        /* Map the compilation unit into memory and dissect it. */
        MVMThreadContext *tc = instance->main_thread;
        cu = MVM_cu_map_from_file(tc, filename, 0);

        MVMROOT(tc, cu, {
            /* The call to MVM_string_utf8_decode() may allocate, invalidating the
               location cu->body.filename */
            MVMString *const str = MVM_string_utf8_decode(tc, instance->VMString, filename, strlen(filename));
            cu->body.filename = str;

            /* Run deserialization frame, if there is one. */
            if (cu->body.deserialize_frame) {
                MVMint8 spesh_enabled_orig = tc->instance->spesh_enabled;
                tc->instance->spesh_enabled = 0;
                MVM_interp_run(tc, &toplevel_initial_invoke, cu->body.deserialize_frame, NULL);
                tc->instance->spesh_enabled = spesh_enabled_orig;
            }
        });
        MVM_vm_set_clargs(instance, 2, raw_clargs);
        instance->clargs = NULL; /* clear cache */

        MVM_interp_run(tc, &toplevel_initial_invoke, cu->body.main_frame, NULL);

        /* Stash addresses of current op, register base and SC deref base
         * in the TC; this will be used by anything that needs to switch
         * the current place we're interpreting. */
        tc->interp_cur_op         = &cur_op;
        tc->interp_bytecode_start = &bytecode_start;
        tc->interp_reg_base       = &reg_base;
        tc->interp_cu             = &cu;
        toplevel_initial_invoke(tc, cu->body.main_frame);

        mark_thread_blocked(tc);

        perl6 = create_p6;

void
p6_destroy()
    CODE:
        if (perl6 != NULL) {
            SvREFCNT_dec(perl6);
            perl6 = NULL;
	    /* Disabled due to crashes. Also moarvm itself doesn't do this by default.
            MVM_vm_destroy_instance(instance);
	    */
        }
