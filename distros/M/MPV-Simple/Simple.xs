#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <unistd.h>
#include <poll.h>

#include "ppport.h"

#include <mpv/client.h>

// For debugging of MPV::Simple::Pipe
//#define stdout PerlIO_stdout()

typedef mpv_handle MPV__Simple;
typedef mpv_event * MPVEvent;

static int pipes[2];
static pthread_mutex_t pipe_lock;


// callback schreibt in die Pipe ein einzelnes Byte hinein
void callback()
{
    //pthread_mutex_lock(&pipe_lock);
    if (pipes[0] != -1)
        write( pipes[1], &(char){0}, 1);
    //pthread_mutex_unlock(&pipe_lock);
    
}


MODULE = MPV::Simple		PACKAGE = MPV::Simple		

MPV__Simple *
new( const char *class )
    PREINIT:
        MPV__Simple * handle;
    CODE:
        //pthread_mutex_init(&pipe_lock, NULL);
        if ( pipe(pipes) < 0) {
            printf("Pipe creation failed\n");
            perror ("pipe");
            exit(EXIT_FAILURE);
        }
        
        // Hier geht das Programm ab und zu baden. Keine Ahnung warum??
        handle = mpv_create();
        
        //mpv_initialize(handle);
        //my_init();
        //MPV__Simple * client = mpv_create_client(handle,"perl_handle");
        
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

MODULE = MPV::Simple		PACKAGE = MPV__SimplePtr

int
set_property_string(MPV__Simple* ctx, SV* option, SV* data)
    CODE:
    {
    int ret = mpv_set_property_string( ctx, SvPV_nolen(option),SvPV_nolen(data) );
    RETVAL = ret;
    }
    OUTPUT: RETVAL
    

SV*
get_property_string(MPV__Simple* ctx, SV* property)
    CODE:
    {
    char *string = mpv_get_property_string( ctx, SvPV_nolen(property) );
    SV* value = newSVpv(string,0);
    mpv_free(string);
    RETVAL = value;
    }
    OUTPUT: RETVAL
    
int
observe_property_string(MPV__Simple* ctx, SV* property, SV* reply_userdata)
    CODE:
    {
    uint64_t userdata = SvIV(reply_userdata);
    int error = mpv_observe_property( ctx, userdata, SvPV_nolen(property), 1 );
    RETVAL = error;
    }
    OUTPUT: RETVAL

int
unobserve_property_string(MPV__Simple* ctx, SV* reply_userdata)
    CODE:
    {
    uint64_t userdata = SvIV(reply_userdata);
    int error = mpv_unobserve_property( ctx, userdata);
    RETVAL = error;
    }
    OUTPUT: RETVAL
    
int
initialize(MPV__Simple* ctx)
    CODE:
    {
        int ret;
        ret = mpv_initialize(ctx);
        RETVAL = ret;
    }
    OUTPUT: RETVAL

void
terminate_destroy(MPV__Simple* ctx)
    CODE:
    {
        close(pipes[0]);
        close(pipes[1]);
        mpv_terminate_destroy(ctx);
        
    }
    
int
command(MPV__Simple* ctx, SV* command, ...)
    CODE:
    {
    int ret;
    int args_num = items-2;
    char *command_pv = SvPV_nolen(command);
    //const char *args[] = {command_pv, *arguments, NULL};
    const char *args[items];
    int i;
    int z =1;
    args[0] = command_pv;
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
wait_event(MPV__Simple* ctx, SV* timeout)
    PREINIT:
        HV* hash;
        mpv_event * event;
    CODE:
    {
    event = mpv_wait_event( ctx, SvIV(timeout) );
    
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
wakeup(MPV__Simple* ctx)
    CODE:
    {
        mpv_wakeup(ctx);
    }

    
int
has_events(MPV__Simple* ctx)
    CODE:
    int ret;
    int pipefd = pipes[0];
    if (pipefd < 0)
        ret = -1;
    else {
        struct pollfd pfds[1] = {
            { .fd = pipefd, .events = POLLIN },
        };
        // Wait until there are possibly new mpv events
        poll(pfds,1,-1);
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
    CODE:
    void (*callback_ptr)(void*);
    callback_ptr = callback;
    mpv_set_wakeup_callback(ctx,callback_ptr,NULL);
    
