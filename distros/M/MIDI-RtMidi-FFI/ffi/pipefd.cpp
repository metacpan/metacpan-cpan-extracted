#include <ffi_platypus_bundle.h>
#include <unistd.h>
#include <stdio.h>
#include <rtmidi_c.h>
#include <fcntl.h>

#ifdef __MINGW32__
#include <winsock2.h>
#define write( fd, message, size ) send( fd, message, size, 0 )
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    int fd;
} _cb_descriptor;

void _callback( double deltatime, const char *message, size_t size, _cb_descriptor *data ) {
    if( size < 1 ) {
        return;
    }

    int total = 0;
    int remains = size;
    while ( total < size ) {
        int sent = write( data->fd, message + total, remains );
        if ( sent < 0 ) {
            perror("Callback write error.");
            return;
        }
        remains -= sent;
        total += sent;
    }

}

RTMIDIAPI
int callback_fd( RtMidiInPtr device, int fd ) {

    _cb_descriptor *data = (_cb_descriptor*)malloc( sizeof( _cb_descriptor ) );
    int pipefd[2] = { 0, 0 };

#ifdef __MINGW32__

    if ( fd <= 0 ) {
        fprintf(stderr, "Parameter 'fd' required on Win32\n");
        return -1;
    }

    fd = _get_osfhandle( fd );
    if ( fd <= 0 ) {
        perror("Unable to retrieve Win32 SOCKET for passed fd.");
        return -1;
    }

    data->fd = fd;

#else

    if ( pipe(pipefd) < 0 ) {
        perror("Cannot create pipe!");
        return -1;
    }
    fcntl( pipefd[0], F_SETFL, O_NONBLOCK );
    data->fd = pipefd[1];

#endif

    rtmidi_in_set_callback( device, (RtMidiCCallback)&_callback, data );

    return pipefd[0];
}

RTMIDIAPI
void _free_userdata( RtMidiInPtr device ) {
    if ( device->data ) {
        free( device->data );
    }
}

#ifdef __cplusplus
}
#endif


