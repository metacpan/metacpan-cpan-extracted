/* Quite obviously the initial author of this writing sucks at Javascript */
/* Patches welcome, bro. */

"use strict";

/* Abstract away requesting the server */
/* We do it by hand here, because this  is example */
/* I guess your favourite framework does it much better */
function do_request(post_to, data, cb, cb_err) {
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
        if (xhr.readyState != XMLHttpRequest.DONE)
            return;

        if ( xhr.status === 200 && cb ) {
            cb(xhr.responseText);
        } else if( xhr.status >= 400 && cb_err ) {
            cb_err( xhr.status );
        }
    };
    xhr.open( "post", post_to, true );
    xhr.setRequestHeader("Content-Type", "application/json");
    xhr.send(JSON.stringify(data));
};

/* Output some zebra-colored div's with span's inside */
/* Again, this is lame and can be done much better */
function colorize_nested(array, odd_class, even_class) {
    var temp = '';
    for (var i = 0; i < array.length; i++) {
        temp += '<div>'+zebra_span(array[i], odd_class, even_class)+'</div>'+"\n";
    };
    return temp;
};

function zebra_span (array, odd_class, even_class) {
    var temp = '';
    var odd = true;
    for (var i = 0; i < array.length; i++) {
        temp += '<span class='+(odd?odd_class:even_class)+'>'+array[i]+'</span>';
        odd = !odd;
    };
    return temp;
};
