#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <unistd.h>
#include <poll.h>

#include "ppport.h"

/* Global Data */

#define MY_CXT_KEY "MPV::Simple::_guts" XS_VERSION

#ifdef USE_ITHREADS
#define GET_CONTEXT eval_pv("require DynaLoader;", TRUE); \
        if(!current_perl) { \
        parent_perl = PERL_GET_CONTEXT; \
        current_perl = perl_clone(parent_perl, CLONEf_KEEP_PTR_TABLE); \
        PERL_SET_CONTEXT(parent_perl); \
    }

#define ENTER_CONTEXT { \
    if(!PERL_GET_CONTEXT) { \
        PERL_SET_CONTEXT(current_perl); \
    }

#define LEAVE_CONTEXT }

#else
#define GET_CONTEXT         /* TLS context not enabled */
#define ENTER_CONTEXT       /* TLS context not enabled */
#define LEAVE_CONTEXT       /* TLS context not enabled */

#endif

typedef struct {
    /* Put Global Data in here */
    int reader;
    int writer; /* you can access this elsewhere as MY_CXT.pipes */
    SV* callback;
    SV* data;
} my_cxt_t;

START_MY_CXT

#include "const-c.inc"


#include <mpv/client.h>

// For debugging of MPV::Simple::Pipe
//#define stdout PerlIO_stdout()

typedef mpv_handle MPV__Simple;
typedef mpv_event * MPVEvent;


// We need multiple perl interpreters
PerlInterpreter *parent_perl = NULL;
extern PerlInterpreter *parent_perl;
PerlInterpreter *current_perl = NULL;


// callback schreibt in die Pipe ein einzelnes Byte hinein
void callback(void *d)
{
    //if (MY_CXT.reader != -1)
        int writer = *(int *) d;
        write( writer, &(char){0}, 1);
}

void callp (char* cmd )
{
    ENTER_CONTEXT;
    
    dTHX;
    dMY_CXT;
	dSP;

	int count;

	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	 XPUSHs(sv_2mortal(newSVsv(MY_CXT.data)));
     //XPUSHs(MY_CXT.data);
	PUTBACK;

	count = call_pv(cmd,G_SCALAR);
    //count = call_sv(MY_CXT.callback,G_SCALAR);

	SPAGAIN;

	PUTBACK;
	FREETMPS;
	LEAVE;
    
    LEAVE_CONTEXT
	
}

MODULE = MPV::Simple		PACKAGE = MPV::Simple		

INCLUDE: const-xs.inc

BOOT:
{
    MY_CXT_INIT;
    /* If any of the fields in the my_cxt_t struct need
       to be initialised, do it here.
     */
     MY_CXT.reader = -1;
     MY_CXT.writer = -1;
     
    PL_perl_destruct_level = 2;
}

MPV__Simple *
new( const char *class )
    PREINIT:
    	dMY_CXT;
        MPV__Simple * handle;
    CODE:
     	int pipes[2];
     	if ( pipe(pipes) < 0) {
            printf("Pipe creation failed\n");
            perror ("pipe");
            exit(EXIT_FAILURE);
        }   
        MY_CXT.reader = pipes[0];
        MY_CXT.writer = pipes[1];
        
        handle = mpv_create();
        
        RETVAL = handle;
    OUTPUT: RETVAL

const char *
error_string(int error)
    CODE:
    {
        const char * ret = mpv_error_string(error);
        RETVAL = ret;
    }
    OUTPUT: RETVAL

MODULE = MPV::Simple		PACKAGE = MPV__SimplePtr  PREFIX = mpv_

int
mpv_set_property_string(MPV__Simple* ctx, char* option, char* data)
    
    

char*
mpv_get_property_string(MPV__Simple* ctx, char* property)
    
    
int
mpv_observe_property_string(MPV__Simple* ctx, char* property, int reply_userdata)
    CODE:
    {
    int error = mpv_observe_property( ctx, reply_userdata, property, 1 );
    RETVAL = error;
    }
    OUTPUT: RETVAL

int
mpv_unobserve_property_string(MPV__Simple* ctx, int reply_userdata)
    CODE:
    {
    int error = mpv_unobserve_property( ctx, reply_userdata);
    RETVAL = error;
    }
    OUTPUT: RETVAL
    
int
mpv_initialize(MPV__Simple* ctx)
    

void
mpv_terminate_destroy(MPV__Simple* ctx)
    PREINIT:
    	dMY_CXT;
    CODE:
    {
        close(MY_CXT.reader);
        close(MY_CXT.writer);
        mpv_terminate_destroy(ctx);
        
    }
    
int
mpv_command(MPV__Simple* ctx, char* command, ...)
    CODE:
    {
    int ret;
    int args_num = items-2;
    
    const char *args[items];
    int i;
    int z =1;
    args[0] = command;
    for (i=2; i <items; i += 1) {
        SV *key = ST(i);
        char *pv = SvPV_nolen(key);
        args[z] = pv;
        z = z+1;
    }
    args[z] = NULL;
    
    ret = mpv_command(ctx, args);
    RETVAL = ret;
    }
    OUTPUT: RETVAL
    
HV *
mpv_wait_event(MPV__Simple* ctx, int timeout)
    PREINIT:
        HV* hash;
        mpv_event * event;
    CODE:
    {
    event = mpv_wait_event( ctx, timeout );
    
    hash = (HV *) sv_2mortal( (SV*) newHV() );
    
    // Copy struct contents into hash
    hv_store(hash,"id",2,newSViv(event->event_id),0);
    
    // Data for MPV_EVENT_GET_PROPERTY_REPLY (not supported!)
    // and MPV_EVENT_PROPERTY_CHANGE
    if (event->event_id == 3 || event->event_id == 22) {
        mpv_event_property * property = event->data;
        const char * name = property->name;
        hv_store(hash,"name",4,newSVpv(name,0),0);
        // MPV_FORMAT_NONE
        if (property->format == 0) {
            hv_store(hash,"data",4,newSV(0),0);
        }
        // MPV_FORMAT_STRING and MPV_FORMAT_OSD_STRING
        else if (property->format == 1 || property->format == 2) {
            char * data = *(char**) property->data;
            hv_store(hash,"data",4,newSVpv(data,0),0);
        }
        // TODO: The following needs tests and add mor mpv_formats
        // MPV_FORMAT_FLAG
        else if (property->format == 3) {
            int data = *(int*) property->data;
            hv_store(hash,"data",4,newSViv(data),0);
        }
        // MPV_FORMAT_DOUBLE
        else if (property->format == 5) {
            double data = *(double*) property->data;
            hv_store(hash,"data",4,newSVnv(data),0);
        }
        else {
            hv_store(hash,"data",4,newSVpv("MPV_FORMAT_NODE and MPV_FORMAT_INT64 at the moment not supported. For the latter please use MPV_FORMAT_DOUBLE.",0),0);
        }
    }
    
    // Data for MPV_EVENT_END_FILE
    else if (event->event_id == 7) {
        mpv_event_end_file * data = event->data;
        int reason = data->reason;
        hv_store(hash,"data",4,newSViv(reason),0);
    }
    else {
        hv_store(hash,"data",4,newSV(0),0);
    }
    
    RETVAL = hash;
    }
    OUTPUT: RETVAL

    
void
mpv_wakeup(MPV__Simple* ctx)

    
int
has_events(MPV__Simple* ctx)
    PREINIT:
    	dMY_CXT;
    CODE:
    int ret;
    int pipefd = MY_CXT.reader;
    if (pipefd < 0)
        ret = -1;
    else {
        struct pollfd pfds[1] = {
            { .fd = pipefd, .events = POLLIN },
        };
        // Wait until there are possibly new mpv events
        poll(pfds,1,0);
        if (pfds[0].revents & POLLIN) {
            // Empty the pipe. Doing this before calling mpv_wait_event()
            // ensures that no wakeups are missed. It's not so important to
            // make sure the pipe is really empty (it will just cause some
            // additional wakeups in unlikely corner cases).
            char unused[256];
            read(pipefd, unused, sizeof(unused));
            ret = 1;
        }
        else {
            ret = 0;
        }
    }
    RETVAL = ret;
    OUTPUT: RETVAL
            
            
void
setup_event_notification(MPV__Simple* ctx)
    PREINIT:
    	dMY_CXT;
    CODE:
    void (*callback_ptr)(void*);
    callback_ptr = callback;
    void *d = (int *) &MY_CXT.writer;
    mpv_set_wakeup_callback(ctx,callback_ptr,d);
    

void
set_my_callback(ctx, fn)
    MPV__Simple* ctx
    SV *    fn
    PREINIT:
      dMY_CXT;
    CODE:
    /* Remember the Perl sub */
    if (MY_CXT.callback == (SV*)NULL)
        MY_CXT.callback = newSVsv(fn);
    else
        SvSetSV(MY_CXT.callback, fn);

void
set_my_data(ctx, fn)
    MPV__Simple* ctx
    SV *    fn
    PREINIT:
        dMY_CXT;
    CODE:
    /* Remember the Perl sub */
    if (MY_CXT.data == (SV*)NULL)
        MY_CXT.data = newSVsv(fn);
    else
        SvSetSV(MY_CXT.data, fn);
    
void
mpv_set_wakeup_callback(MPV__Simple* ctx, char* cmd)
    PREINIT:
            dMY_CXT;
    CODE:
    {
    SV* data;
    
    GET_CONTEXT;
    
    mpv_set_wakeup_callback(ctx,(void (*)(void *) )callp,cmd);
    }
