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
SV *perl6;
const char *filename = PERL6_INSTALL_PATH "/share/perl6/runtime/perl6.moarvm";

static void toplevel_initial_invoke(MVMThreadContext *tc, void *data) {
    /* Create initial frame, which sets up all of the interpreter state also. */
    MVM_frame_invoke(tc, (MVMStaticFrame *)data, MVM_callsite_get_common(tc, MVM_CALLSITE_ID_NULL_ARGS), NULL, NULL, NULL, -1);
}

void init_inline_perl6_new_callback(SV *(*new_p5_callback)(PerlInterpreter *)) {
    p5_callback = new_p5_callback;
}

char *library_location, *helper_path;

MODULE = Inline::Perl6		PACKAGE = Inline::Perl6		

void setup_library_location(path, helper)
        char *path
	char *helper
    CODE:
        library_location = path;
	helper_path = helper;

void
initialize()
    CODE:
        const char  *lib_path[8];
        const char *raw_clargs[2];

        int argi         = 1;
        int lib_path_i   = 0;

        MVM_crash_on_error();

        instance   = MVM_vm_create_instance();
        lib_path[lib_path_i++] = PERL6_INSTALL_PATH "/share/nqp/lib";
        lib_path[lib_path_i++] = PERL6_INSTALL_PATH "/share/perl6/lib";
        lib_path[lib_path_i++] = PERL6_INSTALL_PATH "/share/perl6/runtime";
        lib_path[lib_path_i++] = NULL;

        for( argi = 0; argi < lib_path_i; argi++)
            instance->lib_path[argi] = lib_path[argi];

        /* stash the rest of the raw command line args in the instance */
        instance->prog_name  = PERL6_INSTALL_PATH "/share/perl6/runtime/perl6.moarvm";
        instance->exec_name  = "perl6";
        instance->raw_clargs = NULL;

        /* Map the compilation unit into memory and dissect it. */
        MVMThreadContext *tc = instance->main_thread;
        cu = MVM_cu_map_from_file(tc, filename);

        MVMROOT(tc, cu, {
            /* The call to MVM_string_utf8_decode() may allocate, invalidating the
               location cu->body.filename */
            MVMString *const str = MVM_string_utf8_decode(tc, instance->VMString, filename, strlen(filename));
            cu->body.filename = str;

            /* Run deserialization frame, if there is one. */
            if (cu->body.deserialize_frame) {
                MVM_interp_run(tc, &toplevel_initial_invoke, cu->body.deserialize_frame);
            }
        });
        instance->num_clargs = 2;
        raw_clargs[0] = helper_path;
        raw_clargs[1] = library_location;
        instance->raw_clargs = (char **)raw_clargs;
        instance->clargs = NULL; /* clear cache */

        MVMStaticFrame *start_frame;

        MVM_interp_run(tc, &toplevel_initial_invoke, cu->body.main_frame);

        /* Points to the current opcode. */
        MVMuint8 *cur_op = NULL;

        /* The current frame's bytecode start. */
        MVMuint8 *bytecode_start = NULL;

        /* Points to the base of the current register set for the frame we
         * are presently in. */
        MVMRegister *reg_base = NULL;

        /* Stash addresses of current op, register base and SC deref base
         * in the TC; this will be used by anything that needs to switch
         * the current place we're interpreting. */
        tc->interp_cur_op         = &cur_op;
        tc->interp_bytecode_start = &bytecode_start;
        tc->interp_reg_base       = &reg_base;
        tc->interp_cu             = &cu;
        toplevel_initial_invoke(tc, cu->body.main_frame);

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
