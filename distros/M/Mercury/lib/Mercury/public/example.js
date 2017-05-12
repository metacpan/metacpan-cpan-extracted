
var sockets = {};

function open_ws( path ) {
    var root = 'ws://' + $( '#url-root' ).val();
    return new WebSocket( root + path );
}

function send_message( id ) {
    var message = $( '#' + id + '-message' ).val();
    if ( !message ) {
        return;
    }
    sockets[id].socket.send( message );
    $( '#' + id + '-log' ).prepend( '<p>' + message + '</p>' );
    $( '#' + id + '-message' ).val('');
}

function connect_send( event, id, root_url ) {
    event.preventDefault();

    if ( !sockets[id] ) {
        sockets[id] = {};
    }

    var new_topic = $( '#' + id + '-topic' ).val();
    if ( sockets[id].topic != new_topic ) {

        if ( sockets[id].socket ) {
            // Close the old socket
            $( '#' + id + '-log' ).prepend( '<p>### Disconnected</p>' );
            $( '#' + id + '-topic-field' ).removeClass( 'has-success' );
            sockets[id].socket.onclose = undefined;
            sockets[id].socket.close();
        }

        var url = root_url + new_topic;
        $( '#' + id + '-log' ).prepend( '<p>### Sending on ' + url + '</p>' );
        sockets[id].socket = open_ws( url );
        sockets[id].socket.onopen = function () {
            send_message( id );
            sockets[id].topic = new_topic;
            $( '#' + id + '-topic-field' ).addClass( 'has-success' );
        };
        sockets[id].socket.onclose = function ( ) {
            sockets[id].topic = undefined;
            sockets[id].socket = undefined;
            $( '#' + id + '-log' ).prepend( '<p>### Disconnected</p>' );
            $( '#' + id + '-topic-field' ).removeClass( 'has-success' );
        };
    }
    else {
        send_message( id );
    }
}

function connect_recv( event, id, root_url ) {
    event.preventDefault();

    if ( !sockets[id] ) {
        sockets[id] = {};
    }

    var new_topic = $( '#' + id + '-topic' ).val();
    if ( sockets[id].topic != new_topic ) {

        if ( sockets[id].socket ) {
            // Close the old socket
            $( '#' + id + '-log' ).prepend( '<p>### Disconnected</p>' );
            $( '#' + id + '-topic-field' ).removeClass( 'has-success' );
            sockets[id].socket.onclose = undefined;
            sockets[id].socket.close();
        }

        var url = root_url + new_topic;
        $( '#' + id + '-log' ).prepend( '<p>### Receiving on ' + url + '</p>' );
        sockets[id].socket = open_ws( url );
        sockets[id].socket.onopen = function () {
            send_message( id );
            sockets[id].topic = new_topic;
            $( '#' + id + '-topic-field' ).addClass( 'has-success' );
        };
        sockets[id].socket.onclose = function ( ) {
            sockets[id].topic = undefined;
            sockets[id].socket = undefined;
            $( '#' + id + '-log' ).prepend( '<p>### Disconnected</p>' );
            $( '#' + id + '-topic-field' ).removeClass( 'has-success' );
        };
        sockets[id].socket.onmessage = function ( event ) {
            $( '#' + id + '-log' ).prepend( '<p>' + event.data + '</p>' );
        };
    }
    else {
        send_message( id );
    }
}

