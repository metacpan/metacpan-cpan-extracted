#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <alsa/asoundlib.h>
#ifdef __cplusplus
}
#endif

/* Global Data */
#define MY_CXT_KEY "MIDI::EVAL::_guts" XS_VERSION
/* stuff for version 1.03 - see aconnect.c */
#define LIST_INPUT  1
#define LIST_OUTPUT 2
#define perm_ok(pinfo,bits) ((snd_seq_port_info_get_capability(pinfo) & (bits)) == (bits))
static int check_permission(snd_seq_port_info_t *pinfo, int perm) {
	if (perm) {
		if (perm & LIST_INPUT) {
			if (perm_ok(pinfo,
			 SND_SEQ_PORT_CAP_READ|SND_SEQ_PORT_CAP_SUBS_READ))
				goto __ok;
		}
		if (perm & LIST_OUTPUT) {
			if (perm_ok(pinfo,
			 SND_SEQ_PORT_CAP_WRITE|SND_SEQ_PORT_CAP_SUBS_WRITE))
				goto __ok;
		}
		return 0;
	}
 __ok:
	if (snd_seq_port_info_get_capability(pinfo) & SND_SEQ_PORT_CAP_NO_EXPORT)
		return 0;
	return 1;
}

typedef struct {
	snd_seq_t *seq_handle;
	int queue_id, ninputports, noutputports, createqueue;
	int firstoutputport, lastoutputport;
} my_cxt_t;

START_MY_CXT

MODULE = MIDI::ALSA	PACKAGE = MIDI::ALSA
PROTOTYPES: ENABLE

BOOT:
{
	MY_CXT_INIT;
	MY_CXT.queue_id = -1;
}

int
xs_client (client_name, ninputports, noutputports, createqueue) 
	const char * client_name
	int          ninputports
	int          noutputports
	int          createqueue
CODE:
{
	dMY_CXT;
	int portid, n;
	if (snd_seq_open(&MY_CXT.seq_handle,"default",SND_SEQ_OPEN_DUPLEX,0) < 0) {
		fprintf(stderr, "Error creating ALSA client.\n");
		XSRETURN(0);
	}
	snd_seq_set_client_name(MY_CXT.seq_handle, client_name );
	if ( createqueue )
		MY_CXT.queue_id = snd_seq_alloc_queue(MY_CXT.seq_handle);
	else
		MY_CXT.queue_id = SND_SEQ_QUEUE_DIRECT;

	/*  Clemens Ladisch says (comp.music.midi, 2014041):
	> If you want to allow other clients to send events to the port,
	> set the WRITE flag.
	> If you want to allow other clients to create a subscription to
	> the port, set the WRITE and SUBS_WRITE flags.
	> If you want to allow other clients to create a subscription from
	> the port, set the READ and SUBS_READ flags.
	> (Setting only the READ flag does not make sense because these flags
	> specify what *other* clients are allowed to do.)
	> The DUPLEX flag is purely informational, but you should set it if
	> the port supports both directions.
	*/
	for ( n=0; n < ninputports; n++ ) {
		if (( portid = snd_seq_create_simple_port(MY_CXT.seq_handle,
			  "Input port",
			  SND_SEQ_PORT_CAP_WRITE|SND_SEQ_PORT_CAP_SUBS_WRITE,
			  SND_SEQ_PORT_TYPE_APPLICATION)) < 0) {
			fprintf(stderr, "Error creating input port %d.\n", n );
			ST(0) = sv_2mortal(newSVnv(0));
			XSRETURN(1);
		}
		if( createqueue ) {
			/* set timestamp info of port  */
			snd_seq_port_info_t *pinfo;
			snd_seq_port_info_alloca(&pinfo);
			snd_seq_get_port_info(MY_CXT.seq_handle, portid, pinfo);
			snd_seq_port_info_set_timestamping(pinfo, 1);
			snd_seq_port_info_set_timestamp_queue(pinfo, MY_CXT.queue_id);
			snd_seq_port_info_set_timestamp_real(pinfo, 1);
			snd_seq_set_port_info(MY_CXT.seq_handle, portid, pinfo);
		}
	}
	for ( n=0; n < noutputports; n++ ) {
		/* 1.20 mark WRITE to allow UNSUBSCRIBE message from System */
		if (( portid = snd_seq_create_simple_port(MY_CXT.seq_handle,
			  "Output port",
			  SND_SEQ_PORT_CAP_READ | SND_SEQ_PORT_CAP_SUBS_READ
			  |SND_SEQ_PORT_CAP_WRITE, SND_SEQ_PORT_TYPE_APPLICATION)) < 0) {
			fprintf(stderr, "Error creating output port %d.\n", n );
			ST(0) = sv_2mortal(newSVnv(0));
			XSRETURN(1);
		}
	}
	MY_CXT.firstoutputport = ninputports;
	MY_CXT.lastoutputport  = noutputports + ninputports - 1;
	ST(0) = sv_2mortal(newSVnv(1));
	XSRETURN(1);
}

int
xs_parse_address(port_name)
	const char * port_name
CODE:
{	/* 1.11 */
	dMY_CXT;
	snd_seq_addr_t *addr;
	addr = alloca(sizeof(snd_seq_addr_t));
	int rc = snd_seq_parse_address(MY_CXT.seq_handle, addr, port_name);
	if (rc < 0) {
		/* fprintf(stderr, "Invalid port %s - %s\n", port_name, snd_strerror(rc)); */
		XSRETURN(0);
	}
	ST(0) = sv_2mortal(newSVnv(addr->client));
	ST(1) = sv_2mortal(newSVnv(addr->port));
	XSRETURN(2);
}

int
xs_connectfrom (myport, src_client, src_port)
	int myport
	int src_client
	int src_port
CODE:
{
	dMY_CXT;
	if (MY_CXT.seq_handle == NULL) { XSRETURN(0); }  /* avoid segfaults */
    /* Modify dest port if out of bounds 1.01 */
    if (myport >= MY_CXT.firstoutputport) myport = MY_CXT.firstoutputport-1;
	int rc = snd_seq_connect_from(MY_CXT.seq_handle,myport,src_client,src_port);
	/* returns 0 on success, or a negative error code */
	/* http://alsa-project.org/alsa-doc/alsa-lib/seq.html */
	ST(0) = sv_2mortal(newSVnv(rc==0));
	XSRETURN(1);
}

int
xs_connectto (myport, dest_client, dest_port)
	int myport
	int dest_client
	int dest_port
CODE:
{
	dMY_CXT;
	if (MY_CXT.seq_handle == NULL) { XSRETURN(0); }  /* avoid segfaults */
    /* Modify source port if out of bounds 1.01 */
    if ( myport < MY_CXT.firstoutputport ) myport= MY_CXT.firstoutputport;
    else if ( myport > MY_CXT.lastoutputport ) myport = MY_CXT.lastoutputport;
	int rc = snd_seq_connect_to(MY_CXT.seq_handle,myport,dest_client,dest_port);
	/* returns 0 on success, or a negative error code */
	/* http://alsa-project.org/alsa-doc/alsa-lib/seq.html */
	ST(0) = sv_2mortal(newSVnv(rc==0));
	XSRETURN(1);
}

int
xs_disconnectfrom (myport, src_client, src_port)
	int myport
	int src_client
	int src_port
CODE:
{
	dMY_CXT;
	if (MY_CXT.seq_handle == NULL) { XSRETURN(0); }  /* avoid segfaults */
    /* Modify dest port if out of bounds 1.01 */
    if (myport >= MY_CXT.firstoutputport) myport = MY_CXT.firstoutputport-1;
	int rc = snd_seq_disconnect_from(MY_CXT.seq_handle,myport,src_client,src_port);
	/* returns 0 on success, or a negative error code */
	/* http://alsa-project.org/alsa-doc/alsa-lib/seq.html */
	ST(0) = sv_2mortal(newSVnv(rc==0));
	XSRETURN(1);
}

int
xs_disconnectto (myport, dest_client, dest_port)
	int myport
	int dest_client
	int dest_port
CODE:
{
	dMY_CXT;
	if (MY_CXT.seq_handle == NULL) { XSRETURN(0); }  /* avoid segfaults */
    /* Modify source port if out of bounds 1.01 */
    if ( myport < MY_CXT.firstoutputport ) myport= MY_CXT.firstoutputport;
    else if ( myport > MY_CXT.lastoutputport ) myport = MY_CXT.lastoutputport;
	int rc = snd_seq_disconnect_to(MY_CXT.seq_handle,myport,dest_client,dest_port);
	/* returns 0 on success, or a negative error code */
	/* http://alsa-project.org/alsa-doc/alsa-lib/seq.html */
	ST(0) = sv_2mortal(newSVnv(rc==0));
	XSRETURN(1);
}

int
xs_fd ()
CODE:
{
	dMY_CXT;
	if (MY_CXT.seq_handle == NULL) { XSRETURN(0); }  /* avoid segfaults */
	int npfd;
	struct pollfd *pfd;
	npfd = snd_seq_poll_descriptors_count(MY_CXT.seq_handle, POLLIN);
	pfd = (struct pollfd *)alloca(npfd * sizeof(struct pollfd));
	snd_seq_poll_descriptors(MY_CXT.seq_handle, pfd, npfd, POLLIN);
	ST(0) = sv_2mortal(newSVnv(pfd->fd));
	XSRETURN(1);
}

int
xs_input ()
CODE:
{
	dMY_CXT;
	if (MY_CXT.seq_handle == NULL) { XSRETURN(0); }  /* avoid segfaults */
	snd_seq_event_t *ev;
	int err;
	err = snd_seq_event_input( MY_CXT.seq_handle, &ev );
	if (err < 0) { XSRETURN(0); }  /* 1.04 survive SIGINT */
	/* returns: (type, flags, tag, queue, time, src_client, src_port,
	   dest_client, dest_port, data...)
	   We flatten out the list here so as not to have to use userdata
	   and we use one Time in secs, rather than separate secs and nsecs
	*/
	ST(0) = sv_2mortal(newSViv( ev->type));
	ST(1) = sv_2mortal(newSViv( ev->flags));
	ST(2) = sv_2mortal(newSViv( ev->tag));
	ST(3) = sv_2mortal(newSViv( ev->queue));
	ST(4) = sv_2mortal(newSVnv( ev->time.time.tv_sec+1.0e-9*ev->time.time.tv_nsec));
	ST(5) = sv_2mortal(newSViv( ev->source.client));
	ST(6) = sv_2mortal(newSViv( ev->source.port));
	ST(7) = sv_2mortal(newSViv( ev->dest.client));
	ST(8) = sv_2mortal(newSViv( ev->dest.port));

	switch( ev->type ) {
		case SND_SEQ_EVENT_NOTE:
		case SND_SEQ_EVENT_NOTEON:
		case SND_SEQ_EVENT_NOTEOFF:
		case SND_SEQ_EVENT_KEYPRESS:
			ST(9)  = sv_2mortal(newSViv( ev->data.note.channel));
			ST(10) = sv_2mortal(newSViv( ev->data.note.note));
			ST(11) = sv_2mortal(newSViv( ev->data.note.velocity));
			ST(12) = sv_2mortal(newSViv( ev->data.note.off_velocity));
			ST(13) = sv_2mortal(newSViv( ev->data.note.duration));
			XSRETURN(14);
			break;

		case SND_SEQ_EVENT_CONTROLLER:
		case SND_SEQ_EVENT_PGMCHANGE:
		case SND_SEQ_EVENT_CHANPRESS:
		case SND_SEQ_EVENT_PITCHBEND:
			ST(9)  = sv_2mortal(newSViv( ev->data.control.channel));
			ST(10) = sv_2mortal(newSViv( ev->data.control.unused[0]));
			ST(11) = sv_2mortal(newSViv( ev->data.control.unused[1]));
			ST(12) = sv_2mortal(newSViv( ev->data.control.unused[2]));
			ST(13) = sv_2mortal(newSViv( ev->data.control.param));
			ST(14) = sv_2mortal(newSViv( ev->data.control.value));
			XSRETURN(15);
			break;

		case SND_SEQ_EVENT_SYSEX:
			/* extract the *char+strlen and return it as a perl string */
			ST(9) = sv_2mortal(newSVpv( ev->data.ext.ptr, ev->data.ext.len));
			XSRETURN(10);
			break;

		default:
			XSRETURN(9);
	}
}

int
xs_inputpending ()
CODE:
{
	dMY_CXT;
	if (MY_CXT.seq_handle == NULL) { XSRETURN(0); }  /* avoid segfaults */
	int rc = snd_seq_event_input_pending(MY_CXT.seq_handle, 1);
	ST(0) = sv_2mortal(newSVnv(rc));
	XSRETURN(1);
}

int
xs_id ()
CODE:
{
	dMY_CXT;
	if (MY_CXT.seq_handle == NULL) { XSRETURN(0); }
	ST(0) = sv_2mortal(newSVnv(snd_seq_client_id( MY_CXT.seq_handle )));
	XSRETURN(1);
}

int
xs_output (type, flags, tag, queue, t, src_client, src_port, dest_client, dest_port, data1, data2, data3, data4, data5, data6, sysex_data)
	int    type
	int    flags
	int    tag
	int    queue
	double t
	int    src_client
	int    src_port
	int    dest_client
	int    dest_port
	int    data1
	int    data2
	int    data3
	int    data4
	int    data5
	int    data6
	char * sysex_data
CODE:
{
	dMY_CXT;
	if (MY_CXT.seq_handle == NULL) { XSRETURN(0); }  /* avoid segfaults */
    snd_seq_event_t ev;
    ev.type          = type;
    ev.flags         = flags | SND_SEQ_TIME_STAMP_REAL;  /* 1.15 */
    ev.tag           = tag;
    ev.queue         = queue;
    ev.time.time.tv_sec  = (int) t;
    ev.time.time.tv_nsec = (int) (1.0e9 * (t - (double) ev.time.time.tv_sec));
    ev.source.client = src_client;
    ev.source.port   = src_port;
    ev.dest.client   = dest_client;
    ev.dest.port     = dest_port;
    static int * data;
    switch( ev.type ) {
        case SND_SEQ_EVENT_NOTE:
        case SND_SEQ_EVENT_NOTEON:
        case SND_SEQ_EVENT_NOTEOFF:
        case SND_SEQ_EVENT_KEYPRESS:
            ev.data.note.channel      = data1;
            ev.data.note.note         = data2;
            ev.data.note.velocity     = data3;
            ev.data.note.off_velocity = data4;
            ev.data.note.duration     = data5;
            break;

        case SND_SEQ_EVENT_CONTROLLER:
        case SND_SEQ_EVENT_PGMCHANGE:
        case SND_SEQ_EVENT_CHANPRESS:
        case SND_SEQ_EVENT_PITCHBEND:
            ev.data.control.channel   = data1;
            ev.data.control.unused[0] = data2;
            ev.data.control.unused[1] = data3;
            ev.data.control.unused[2] = data4;
            ev.data.control.param     = data5;
            ev.data.control.value     = data6;
            /* printf ( "param: %d\n", ev.data.control.param );
               printf ( "value: %d\n", ev.data.control.value );
            */
            break;

		case SND_SEQ_EVENT_SYSEX:
			/* data1 must be the length of it; it could contain \0's */
			snd_seq_ev_set_variable ( &ev, data1, sysex_data );
			break;
    }
    /* If not a direct event, use the queue */
    if ( ev.queue != SND_SEQ_QUEUE_DIRECT )
        ev.queue = MY_CXT.queue_id;
    /* Modify source port if out of bounds */
    if ( ev.source.port < MY_CXT.firstoutputport ) 
        snd_seq_ev_set_source(&ev, MY_CXT.firstoutputport );
    else if ( ev.source.port > MY_CXT.lastoutputport )
        snd_seq_ev_set_source(&ev, MY_CXT.lastoutputport );
    /* Use subscribed ports, except if ECHO event */
    /* if ( ev.type != SND_SEQ_EVENT_ECHO ) snd_seq_ev_set_subs(&ev); */
	/* Use subscribed ports, except if ECHO event, or dest_client>0 1.12 */
	if (ev.type != SND_SEQ_EVENT_ECHO && ( !dest_client
	  || dest_client == snd_seq_client_id( MY_CXT.seq_handle)))  /* 1.14 */
		snd_seq_ev_set_subs(&ev);
    int rc = snd_seq_event_output_direct( MY_CXT.seq_handle, &ev );
	ST(0) = sv_2mortal(newSVnv(rc));
	XSRETURN(1);
}

int
xs_queue_id ()
CODE:
{
	/* 1.16 */
	dMY_CXT;
	if (MY_CXT.seq_handle == NULL) { XSRETURN(0); }  /* avoid segfaults */
	ST(0) = sv_2mortal(newSVnv(MY_CXT.queue_id));
	XSRETURN(1);
}

int
xs_start ()
CODE:
{
	dMY_CXT;
	if (MY_CXT.seq_handle == NULL) { XSRETURN(0); }  /* avoid segfaults */
	if (MY_CXT.queue_id < 0) {
		ST(0) = sv_2mortal(newSVnv(0));
		XSRETURN(1);
	}
	int rc = snd_seq_start_queue(MY_CXT.seq_handle, MY_CXT.queue_id, NULL);
	snd_seq_drain_output(MY_CXT.seq_handle);
	ST(0) = sv_2mortal(newSVnv(rc));
	XSRETURN(1);
}

int
xs_status ()
CODE:
{
    dMY_CXT;
	if (MY_CXT.seq_handle == NULL) { XSRETURN(0); }  /* avoid segfaults */
	if (MY_CXT.queue_id < 0) {
		ST(0) = sv_2mortal(newSVnv(0));
		XSRETURN(1);
	}
	snd_seq_queue_status_t *queue_status;
	int running, events;
	const snd_seq_real_time_t *rt;
	snd_seq_queue_status_malloc( &queue_status );
	snd_seq_get_queue_status(MY_CXT.seq_handle, MY_CXT.queue_id, queue_status);
	rt      = snd_seq_queue_status_get_real_time( queue_status );
	running = snd_seq_queue_status_get_status( queue_status );
	events  = snd_seq_queue_status_get_events( queue_status );
	/* returns: running, time in floating-point seconds, events */
    ST(0) = sv_2mortal(newSVnv(running));
    ST(1) = sv_2mortal(newSVnv(rt->tv_sec + 1.0e-9*rt->tv_nsec));
    ST(2) = sv_2mortal(newSVnv(events));
	snd_seq_queue_status_free( queue_status );
    XSRETURN(3);
}

int
xs_stop ()
CODE:
{
	dMY_CXT;
	if (MY_CXT.seq_handle == NULL) { XSRETURN(0); }  /* avoid segfaults */
	if (MY_CXT.queue_id < 0) {
		ST(0) = sv_2mortal(newSVnv(0));
		XSRETURN(1);
	}
	int rc = snd_seq_stop_queue(MY_CXT.seq_handle, MY_CXT.queue_id, NULL);
	ST(0) = sv_2mortal(newSVnv(rc));
	XSRETURN(1);
}

int
xs_listclients (getnumports)
	int getnumports;
CODE:
{
	/* stuff for version 1.03 - see aconnect.c
	alsa-utils.sourcearchive.com/documentation/1.0.20/aconnect_8c-source.html 
	*/
	dMY_CXT;
	if (MY_CXT.seq_handle == NULL) { XSRETURN(0); }
	snd_seq_client_info_t *cinfo;
	snd_seq_port_info_t *pinfo;
	snd_seq_client_info_alloca(&cinfo);
	snd_seq_port_info_alloca(&pinfo);
	snd_seq_client_info_set_client(cinfo, -1);
	unsigned int iST = 0;
	while (snd_seq_query_next_client(MY_CXT.seq_handle, cinfo) >= 0) {
		/* reset query info */
		snd_seq_port_info_set_client(pinfo,
		 snd_seq_client_info_get_client(cinfo));
		snd_seq_port_info_set_port(pinfo, -1);
 		ST(iST) = sv_2mortal(newSVnv(snd_seq_client_info_get_client(cinfo)));
		iST++;
		if (getnumports == 1) {
 			ST(iST) = sv_2mortal(newSVnv(
			  snd_seq_client_info_get_num_ports(cinfo)));
		} else {
	 		ST(iST) = sv_2mortal(newSVpv(snd_seq_client_info_get_name(cinfo),
			 strlen(snd_seq_client_info_get_name(cinfo))));
		}
		iST++;
	}
	XSRETURN(iST);
}

int
xs_listconnections (from)
	int from;
CODE:
{
	/* stuff for version 1.03 - see aconnect.c
	alsa-utils.sourcearchive.com/documentation/1.0.20/aconnect_8c-source.html 
	*/
	dMY_CXT;
	if (MY_CXT.seq_handle == NULL) { XSRETURN(0); }
	snd_seq_client_info_t *cinfo;
	snd_seq_port_info_t *pinfo;
    snd_seq_query_subscribe_t *subs;
	snd_seq_client_info_alloca(&cinfo);
	snd_seq_port_info_alloca(&pinfo);
    snd_seq_query_subscribe_alloca(&subs);
	snd_seq_get_client_info(MY_CXT.seq_handle, cinfo);
	unsigned int iST = 0;
    /* reset query info */
    snd_seq_query_subscribe_set_type(subs,
	  from ? SND_SEQ_QUERY_SUBS_WRITE : SND_SEQ_QUERY_SUBS_READ);
    snd_seq_port_info_set_client(pinfo,
      snd_seq_client_info_get_client(cinfo));
    snd_seq_port_info_set_port(pinfo, -1);
    while (snd_seq_query_next_port(MY_CXT.seq_handle, pinfo) >= 0) {
    	snd_seq_query_subscribe_set_root(subs,
		  snd_seq_port_info_get_addr(pinfo));
    	snd_seq_query_subscribe_set_port(subs,
		  snd_seq_port_info_get_addr(pinfo)->port);
    	snd_seq_query_subscribe_set_index(subs, 0);
		/* At least, the client id, the port id, the index number
		 and the query type must be set to perform a proper query. */
    	while (snd_seq_query_port_subscribers(MY_CXT.seq_handle, subs) >= 0) {
        	const snd_seq_addr_t *addr;
        	addr = snd_seq_query_subscribe_get_addr(subs);
			ST(iST)
			  = sv_2mortal(newSVnv(snd_seq_port_info_get_addr(pinfo)->port));
			iST++;
			ST(iST) = sv_2mortal(newSVnv(addr->client));
			iST++;
			ST(iST) = sv_2mortal(newSVnv(addr->port));
			iST++;
        	snd_seq_query_subscribe_set_index(subs,
         	  snd_seq_query_subscribe_get_index(subs) + 1);
		}
    }
	XSRETURN(iST);
}

int
xs_syncoutput()
CODE:
{
	dMY_CXT;
	if (MY_CXT.seq_handle == NULL) { XSRETURN(0); }
    int rc = snd_seq_sync_output_queue( MY_CXT.seq_handle );
	ST(0) = sv_2mortal(newSVnv(rc));
	XSRETURN(1);
}


int
xs_constname2value ()
CODE:
{
	dMY_CXT;
	struct constant {  /* Gems p. 334 */
		const char * name;
		int value;
	};
	static const struct constant constants[] = {
		{"SND_SEQ_EVENT_BOUNCE", SND_SEQ_EVENT_BOUNCE},
		{"SND_SEQ_EVENT_CHANPRESS", SND_SEQ_EVENT_CHANPRESS},
		{"SND_SEQ_EVENT_CLIENT_CHANGE", SND_SEQ_EVENT_CLIENT_CHANGE},
		{"SND_SEQ_EVENT_CLIENT_EXIT", SND_SEQ_EVENT_CLIENT_EXIT},
		{"SND_SEQ_EVENT_CLIENT_START", SND_SEQ_EVENT_CLIENT_START},
		{"SND_SEQ_EVENT_CLOCK", SND_SEQ_EVENT_CLOCK},
		{"SND_SEQ_EVENT_CONTINUE", SND_SEQ_EVENT_CONTINUE},
		{"SND_SEQ_EVENT_CONTROL14", SND_SEQ_EVENT_CONTROL14},
		{"SND_SEQ_EVENT_CONTROLLER", SND_SEQ_EVENT_CONTROLLER},
		{"SND_SEQ_EVENT_ECHO", SND_SEQ_EVENT_ECHO},
		{"SND_SEQ_EVENT_KEYPRESS", SND_SEQ_EVENT_KEYPRESS},
		{"SND_SEQ_EVENT_KEYSIGN", SND_SEQ_EVENT_KEYSIGN},
		{"SND_SEQ_EVENT_NONE", SND_SEQ_EVENT_NONE},
		{"SND_SEQ_EVENT_NONREGPARAM", SND_SEQ_EVENT_NONREGPARAM},
		{"SND_SEQ_EVENT_NOTE", SND_SEQ_EVENT_NOTE},
		{"SND_SEQ_EVENT_NOTEOFF", SND_SEQ_EVENT_NOTEOFF},
		{"SND_SEQ_EVENT_NOTEON", SND_SEQ_EVENT_NOTEON},
		{"SND_SEQ_EVENT_OSS", SND_SEQ_EVENT_OSS},
		{"SND_SEQ_EVENT_PGMCHANGE", SND_SEQ_EVENT_PGMCHANGE},
		{"SND_SEQ_EVENT_PITCHBEND", SND_SEQ_EVENT_PITCHBEND},
		{"SND_SEQ_EVENT_PORT_CHANGE", SND_SEQ_EVENT_PORT_CHANGE},
		{"SND_SEQ_EVENT_PORT_EXIT", SND_SEQ_EVENT_PORT_EXIT},
		{"SND_SEQ_EVENT_PORT_START", SND_SEQ_EVENT_PORT_START},
		{"SND_SEQ_EVENT_PORT_SUBSCRIBED", SND_SEQ_EVENT_PORT_SUBSCRIBED},
		{"SND_SEQ_EVENT_PORT_UNSUBSCRIBED", SND_SEQ_EVENT_PORT_UNSUBSCRIBED},
		{"SND_SEQ_EVENT_QFRAME", SND_SEQ_EVENT_QFRAME},
		{"SND_SEQ_EVENT_QUEUE_SKEW", SND_SEQ_EVENT_QUEUE_SKEW},
		{"SND_SEQ_EVENT_REGPARAM", SND_SEQ_EVENT_REGPARAM},
		{"SND_SEQ_EVENT_RESET", SND_SEQ_EVENT_RESET},
		{"SND_SEQ_EVENT_RESULT", SND_SEQ_EVENT_RESULT},
		{"SND_SEQ_EVENT_SENSING", SND_SEQ_EVENT_SENSING},
		{"SND_SEQ_EVENT_SETPOS_TICK", SND_SEQ_EVENT_SETPOS_TICK},
		{"SND_SEQ_EVENT_SETPOS_TIME", SND_SEQ_EVENT_SETPOS_TIME},
		{"SND_SEQ_EVENT_SONGPOS", SND_SEQ_EVENT_SONGPOS},
		{"SND_SEQ_EVENT_SONGSEL", SND_SEQ_EVENT_SONGSEL},
		{"SND_SEQ_EVENT_START", SND_SEQ_EVENT_START},
		{"SND_SEQ_EVENT_STOP", SND_SEQ_EVENT_STOP},
		{"SND_SEQ_EVENT_SYNC_POS", SND_SEQ_EVENT_SYNC_POS},
		{"SND_SEQ_EVENT_SYSEX", SND_SEQ_EVENT_SYSEX},
		{"SND_SEQ_EVENT_SYSTEM", SND_SEQ_EVENT_SYSTEM},
		{"SND_SEQ_EVENT_TEMPO", SND_SEQ_EVENT_TEMPO},
		{"SND_SEQ_EVENT_TICK", SND_SEQ_EVENT_TICK},
		{"SND_SEQ_EVENT_TIMESIGN", SND_SEQ_EVENT_TIMESIGN},
		{"SND_SEQ_EVENT_TUNE_REQUEST", SND_SEQ_EVENT_TUNE_REQUEST},
		{"SND_SEQ_EVENT_USR0", SND_SEQ_EVENT_USR0},
		{"SND_SEQ_EVENT_USR1", SND_SEQ_EVENT_USR1},
		{"SND_SEQ_EVENT_USR2", SND_SEQ_EVENT_USR2},
		{"SND_SEQ_EVENT_USR3", SND_SEQ_EVENT_USR3},
		{"SND_SEQ_EVENT_USR4", SND_SEQ_EVENT_USR4},
		{"SND_SEQ_EVENT_USR5", SND_SEQ_EVENT_USR5},
		{"SND_SEQ_EVENT_USR6", SND_SEQ_EVENT_USR6},
		{"SND_SEQ_EVENT_USR7", SND_SEQ_EVENT_USR7},
		{"SND_SEQ_EVENT_USR8", SND_SEQ_EVENT_USR8},
		{"SND_SEQ_EVENT_USR9", SND_SEQ_EVENT_USR9},
		{"SND_SEQ_EVENT_USR_VAR0", SND_SEQ_EVENT_USR_VAR0},
		{"SND_SEQ_EVENT_USR_VAR1", SND_SEQ_EVENT_USR_VAR1},
		{"SND_SEQ_EVENT_USR_VAR2", SND_SEQ_EVENT_USR_VAR2},
		{"SND_SEQ_EVENT_USR_VAR3", SND_SEQ_EVENT_USR_VAR3},
		{"SND_SEQ_EVENT_USR_VAR4", SND_SEQ_EVENT_USR_VAR4},
		{"SND_SEQ_QUEUE_DIRECT", SND_SEQ_QUEUE_DIRECT},
		{"SND_SEQ_TIME_STAMP_REAL", SND_SEQ_TIME_STAMP_REAL},
		{NULL, 0}
	};
	int index;  /* define constants in module namespace */
	int i = 0;  /* index into name,value array */
	for (index = 0; constants[index].name != NULL; ++index) {
		ST(i) = sv_2mortal(newSVpv(constants[index].name, 0));
		i++;
		ST(i) = sv_2mortal(newSViv(constants[index].value));
		i++;
	}
	XSRETURN(i);
}
