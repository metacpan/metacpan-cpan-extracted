/************************************************************************
                                                  __
                   __                            /\ \
                  /\_\      ____    ___    _ __  \ \ \____
                  \/\ \    /',__\  / __`\ /\`'__\ \ \ '__`\
                   \ \ \  /\__, `\/\ \L\ \\ \ \/   \ \ \L\ \
                   _\ \ \ \/\____/\ \____/ \ \_\    \ \_,__/
                  /\ \_\ \ \/___/  \/___/   \/_/     \/___/
                  \ \____/
                   \/___/

 ************************************************************************/

var JSORB = function () {};

JSORB.VERSION   = '0.04';
JSORB.AUTHORITY = 'cpan:STEVAN';

/***************************** JSORB.Client *****************************/

JSORB.Client = function (options) {
    if (typeof options == 'string') {
        options = { 'base_url' : options };
    }
    this.base_url = options['base_url'];
    // NOTE:
    // Supported options can be found
    // here:
    //     http://docs.jquery.com/Ajax/jQuery.ajax
    // we force a few options for sanity
    // such as dataType == json and
    // we provide an error and success
    // handler, otherwise it is all up
    // to you.
    // - SL
    this.ajax_options          = options['ajax_options']          || {};
    this.base_namespace        = options['base_namespace']        || null;
    this.default_error_handler = options['default_error_handler'] || function (e) { alert(e.message) };
    this.message_count         = 0;
    this.__current_xhr         = null;

}

JSORB.Client.prototype.new_request = function (p) {
    return new JSORB.Client.Request(p);
}

JSORB.Client.prototype.notify = function (request, error_handler) {
    request = this.__coerce_request(request);
    if (request.id != null) {
        throw new Error ("Notifications must have an id of null, you have " + request.id);
    }
    // notifications do not require
    // a callback, so we just pass in
    // an empty one here - SL
    this.__call(request, function () {}, error_handler);
}

JSORB.Client.prototype.call = function (request, callback, error_handler) {
    request = this.__coerce_request(request);
    if (request.id == null) {
        this.message_count++;
        request.id = this.message_count;
    }
    this.__call(request, callback, error_handler);
}

JSORB.Client.prototype.abort_current_call = function () {
    if (this.__current_xhr) {
        this.__current_xhr.abort();
        this.__current_xhr = null;
    }
}

JSORB.Client.prototype.__coerce_request = function (request) {
    if (typeof request == 'object' && request.constructor != JSORB.Client.Request) {
        request = this.new_request(request);
    }
    return request;
}

// NOTE:
// call should take a HASH and that
// hash should be merged into ajax_options
// - SL
JSORB.Client.prototype.__call = function (request, callback, error_handler) {
    var self = this;

    if (error_handler == undefined) {
        error_handler = this.default_error_handler;
    }

    if (this.base_namespace) {
        request.method = this.base_namespace + request.method;
    }

    // clone our global options
    var options      = JSORB.Util.clone_object(this.ajax_options);
    options.url      = request.as_url(this.base_url);
    options.dataType = 'text'; // jQuery keeps not liking my JSON, odd - SL

    options.error    = function (request, status, error) {
        var resp;
        if (error) {
            // this is for exceptions that happen
            // during processing of the AJAX request
            // so we can turn this into an actual
            // JSORB response with an error for
            // the sake of consistency
            resp = new JSORB.Client.Response({
                'error' : new JSORB.Client.Error({
                    'error'   : error,
                    'message' : error.description
                })
            });
        }
        else {
            resp = new JSORB.Client.Response(request.responseText);
        }
        error_handler(resp.error);
        // clear the current xhr
        self.__current_xhr = null;
    };

    options.success  = function (data, status) {
        var resp = new JSORB.Client.Response(data);
        if (request.id != resp.id) {
            throw new Error ("Message id mismatch got " + resp.id + " expected " + request.id);
        }
        if (resp.has_error()) {
            error_handler(resp.error);
        }
        else {
            callback(resp.result);
        }
        // clear the current xhr
        self.__current_xhr = null;
    };

    this.__current_xhr = JSORB.Util.do_ajax_call(options);
}

/*************************** JSORB.Client.Request ****************************/

// Request

JSORB.Client.Request = function (p) {
    if (typeof p == 'string') {
        p = JSON.parse(p);
    }
    // FIXME:
    // This should probably check
    // for bad input here, and
    // throw an exception - SL
    this.id     = p['id'] || null;
    this.method = p['method'];
    this.params = p['params'] && typeof p['params'] == 'string'
                    ? JSON.parse(p['params'])
                    : p['params'];
}

JSORB.Client.Request.prototype.is_notification = function () { return this.id == null }

JSORB.Client.Request.prototype.as_url = function (base_url) {
    var params = [ 'jsonrpc=2.0' ];
    if (this.id != null) {
        params.push('id=' + escape(this.id));
    }
    params.push('method=' + escape(this.method));
    if (this.params) {
        params.push('params='  + escape(JSON.stringify(this.params)));
    }
    return (base_url == undefined ? '' : base_url) + '?' + params.join('&');
}

JSORB.Client.Request.prototype.collapse_for_json = function () {
    return {
        'jsonrpc' : '2.0',
        'id'      : this.id,
        'method'  : this.method,
        'params'  : this.params
    };
}

JSORB.Client.Request.prototype.as_json = function () {
    return JSON.stringify(this.collapse_for_json());
}

/*************************** JSORB.Client.Response ***************************/

// Response

JSORB.Client.Response = function (p) {
    if (typeof p == 'string') {
        p = JSON.parse(p);
    }
    // FIXME:
    // This should probably check
    // for bad input here, and
    // throw an exception - SL
    this.id     = p['id'];
    this.result = p['result'];
    this.error  = p['error'] ? new JSORB.Client.Error(p['error']) : null;
}

JSORB.Client.Response.prototype.has_error = function () { return this.error != null }

JSORB.Client.Response.prototype.collapse_for_json = function () {
    return {
        'id'     : this.id,
        'result' : this.result,
        'error'  : (this.has_error() ? this.error.collapse_for_json() : null)
    };
}

JSORB.Client.Response.prototype.as_json = function () {
    return JSON.stringify(this.collapse_for_json());
}

/************************** JSORB.Client.Error **************************/

// Simple error object

JSORB.Client.Error = function (options) {
    if (options == undefined) {
        options = {};
    }
    this.code    = options['code']    || 1;
    this.message = options['message'] || "An error has occured";
    this.data    = options['data']    || {};
}

JSORB.Client.Error.prototype.collapse_for_json = function () {
    return {
        'code'    : this.code,
        'message' : this.message,
        'data'    : this.data
    };
}

JSORB.Client.Error.prototype.as_json = function () {
    return JSON.stringify(this.collapse_for_json());
}

/***************************** JSORB.Util ******************************/

JSORB.Util = function () {}

JSORB.Util.clone_object = function (object) {
    return jQuery.extend({}, object);
}

JSORB.Util.do_ajax_call = function (options) {
    // NOTE:
    // This must return the raw
    // XMLHTTPRequest object.
    // - SL
    return jQuery.ajax(options);
}

/***********************************************************************/

/*

DEPENDENCIES

This requires the standard JSON
library, which can be found here:

http://www.json.org/json2.js

And a copy of the JQuery library
which can be found here:

http://jqueryjs.googlecode.com/files/jquery-1.2.6.js

BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

AUTHOR

Stevan Little <stevan.little@iinteractive.com>

COPYRIGHT AND LICENSE

Copyright 2008-2010 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

*/

// ****************************************************************************
//  http://www.geocities.com/SouthBeach/Marina/4942/misc/misc.htm#unknown
// ****************************************************************************
//
// [3]_______________________________  \ ___/
//                   / __/              \  /             \__ \
//                  / /                  \/                 \ \
//                 / /              ___________              \ \
//                / /            __/___________\__            \ \
//              ./ /__  ___     /=================\     ___  __\ \.
//     [4]-------> ___||___|====|[[[[[|||||||]]]]]|====|___||___ <------[4]
//            /  /              |=o=o=o=o=o=o=o=o=| <-------------------[5]
//           .' /                \_______ _______/                \ `.
//           :  |___                    |*|                    ___|  :
//          .'  |   \_________________  |*|  _________________/   |  `.
//          :   |   ___________   ___ \ |*| / ___   ___________   |   :
//          :   |__/           \ /   \_\\*//_/   \ /           \__|   :
//          :   |______________:|:____:: **::****:|:********\ <---------[6]
//         .'  /:|||||||||||||'`|;..:::::::::::..;|'`|||||||*|||||:\  `.
//     [7]----------> ||||||' .:::;~|~~~___~~~|~;:::. `|||||*|| <-------[7]
//         :   |:|||||||||' .::'\ ..:::::::::::.. /`::. `|||*|||||:|   :
//         :   |:|||||||' .::' .:::''~~     ~~``:::. `::. `|\***\|:|   :
//         :   |:|||||' .::\ .::''\ |   [9]   | /``::: /::. `|||*|:|   :
//     [8]------------>::' .::'    \|_________|/    `::: `::. `|* <-----[6]
//         `.  \:||' .::' ::'\ [9] .     .     . [9] /::: `::.  *|:/  .'
//          :   \:' :::'.::'  \  .               .  /  `::.`::: *:/   :
//          :    | .::'.::'____\    [10] . [10]    /____`::.`::.*|    :
//          :    | :::~:::     |       . . .       |     :::~:::*|    :
//          :    | ::: ::  [9] | .   . ..:.. .   . | [9]  :: :::*|    :
//          :    \ ::: ::      |       . :\_____________________________[11]
//          `.    \`:: ::: ____|     .   .   .     |____ ::: ::'/    .'
//           :     \:;~`::.    / .  [10]   [10]  . \    .::'~::/     :
//           `.     \:. `::.  /    .     .     .    \  .::' .:/     .'
//            :      \:. `:::/ [9]   _________   [9] \:::' .:/      :
//            `.      \::. `:::.   /|         |\   .:::' .::/      .'
//             :       ~~\:/ `:::./ |   [9]   | \.:::' \:/~~       :
//             `:=========\::. `::::...     ...::::' .::/=========:'
//              `:         ~\::./ ```:::::::::''' \.::/~         :'
//               `.          ~~~~~~\|   ~~~   |/~~~~~~          .'
//                `.                \:::...:::/                .'
//                 `.                ~~~~~~~~~                .'
//
// ****************************************************************************
//
//                                    /\
//                                   /  \ <---------------------------[1]
//                                  /    \
//                _________________/______\_________________
//               | :      ||:      ~      ~               : |
//   [2]-------> | :      ||:                             : |
//               | :      ||:                             : |
//               | :      ||:                             : |
//               | :      ||:                             : |
//               | :      ||:                             : |
//               | :      ||:                             : |
//               | :      ||:                             : |
//               | :      ||:                             : |
//               | :      ||:                             : |
//               | :      ||:                             : |
//               | :      ||:                             : |
//               | :______||:_____________________________: |
//               |/_______||/______________________________\|
//                \       ~\       |              |         /
//                 \       |\      |              |        /
//                  \      | \     |              |       /
//                   \     |  \    |              |      /
//                    \    |___\   |______________|     /
//                     \  |     \ |~               \   /
//                      \|_______\|_________________\_/
//                      |_____________________________|
//                      /                             \
//                     /       _________________       \
//                    /      _/                 \_      \
//                   /    __/                     \__    \
//                  /    /                           \    \
//                 /__ _/                             \_ __\
//   [3]_______________________________                 \ _|
//                 / /                 \                 \ \
//                / /                  \/                 \ \
//               / /              ___________              \ \
//              | /            __/___________\__            \ |
//              | |_  ___     /=================\     ___  _| |
//   [4]---------> _||___|====|[[[[[[[|||]]]]]]]|====|___||_ <--------[4]
//              | |           |-----------------|           | |
//              | |           |o=o=o=o=o=o=o=o=o| <-------------------[5]
//              | |            \_______________/            | |
//              | |__                |: :|                __| |
//              | |  \______________ |: :| ______________/  | |
//              | | ________________\|: :|/________________ | |
//              | |/            |::::|: :|::::|            \| |
//   [6]----------------------> |::::|: :|::::| <---------------------[6]
//              | |             |::::|: :|::::|             | |
//              | |             |::==|: :|== <------------------------[9]
//              | |             |::__\: :/__::|             | |
//              | |             |::  ~: :~  ::|             | |
//   [7]----------------------------> \_/   ::|             | |
//              | |~\________/~\|::    ~    ::|/~\________/~| |
//              | |            ||::         <-------------------------[8]
//              | |_/~~~~~~~~\_/|::_ _ _ _ _::|\_/~~~~~~~~\_| |
//   [9]-------------------------->_=_=_=_=_::|             | |
//              | |             :::._______.:::             | |
//              | |            .:::|       |:::..           | |
//              | |        ..:::::'|       |`:::::..        | |
//   [6]---------------->.::::::' ||       || `::::::.<---------------[6]
//              | |    .::::::' | ||       || | `::::::.    | |
//             /| |  .::::::'   | ||       || |   `::::::.  | |
//            | | | .:::::'     | ||    <-----------------------------[10]
//            | | |.:::::'      | ||       || |      `:::::.| |
//            | | ||::::'       | |`.     .'| |       `::::|| |
//  [11]___________________________  ``~''  __________________________[11]
//            : | | \::            \       /            ::/ | |
//           |  | |  \:_________|_|\/__ __\/|_|_________:/  | |
//           /  | |   |  __________~___:___~__________  |   | |
//          ||  | |   | |          |:::::::|          | |   | |
//  [12]   /|:  | |   | |          |:::::::|          | |   | |
//|~~~~~  / |:  | |   | |          |:::::::|          | |   | |
//|----> / /|:  | |   | |          |:::::::|        <-----------------[10]
//|     / / |:  | |   | |          |:::::::|          | |   | |
//|      /  |:  | |   | |          |::::<-----------------------------[13]
//|     /  /|:  | |   | |          |:::::::|          | |   | |
//|    /  / |:  | |   | |          `:::::::'          | |   | |
//|  _/  / /:~: | |   | `:           ``~''           :' |   | |
//|  |  / / ~.. | |   |: `:                         :' :|   | |
//|->| / /   :  | |   :::  `.                     .' <----------------[11]
//|  |/ / ^   ~\|  \  ::::.  `.                 .'  .::::  /  |
//|  ~   /|\    |   \_::::::.  `.             .'  .::::::_/   |
//|_______|     |      \::::::.  `.         .'  .:::<-----------------[6]
//              |_________\:::::.. `~.....~' ..:::::/_________|
//              |          \::::::::.......::::::::/          |
//              |           ~~~~~~~~~~~~~~~~~~~~~~~           |
//              `.                                           .'
//               `.                                         .'
//                `.                                       .'
//                 `:.                                   .:'
//                  `::.                               .::'
//                    `::..                         ..::'
//                      `:::..                   ..:::'
//                        `::::::...        ..::::::'
//  [14]------------------> `:____:::::::::::____:' <-----------------[14]
//                            ```::::_____::::'''
//                                   ~~~~~
//
// ****************************************************************************
//
//                                     |
//                                     |
//                                     |
//                                     |
//  [1]------------------------------> o
//
//                                  . o o .
//                                 . o_0_o . <-----------------------[2]
//                                 . o 0 o .
//                                  . o o .
//
//                                     |
//                                    \|/
//                                     ~
//
//                               . o o. .o o .
//  [3]-----------------------> . o_0_o"o_0_o .
//                              . o 0 o~o 0 o .
//                               . o o.".o o .
//                                     |
//                                /    |    \
//                              |/_    |    _\|
//                              ~~     |     ~~
//                                     |
//                         o o         |        o o
//  [4]-----------------> o_0_o        |       o_0_o <---------------[5]
//                        o~0~o        |       o~0~o
//                         o o )       |      ( o o
//                            /        o       \
//                           /        [1]       \
//                          /                    \
//                         /                      \
//                        /                        \
//                       o [1]                  [1] o
//               . o o .            . o o .            . o o .
//              . o_0_o .          . o_0_o .          . o_0_o .
//              . o 0 o .  <-[2]-> . o 0 o . <-[2]->  . o 0 o .
//               . o o .            . o o .            . o o .
//
//                /                    |                    \
//              |/_                   \|/                   _\|
//              ~~                     ~                     ~~
//
//    . o o. .o o .              . o o. .o o .              . o o. .o o .
//   . o_0_o"o_0_o .            . o_0_o"o_0_o .            . o_0_o"o_0_o .
//   . o 0 o~o 0 o . <--[3]-->  . o 0 o~o 0 o .  <--[3]--> . o 0 o~o 0 o .
//    . o o.".o o .              . o o.".o o .              . o o.".o o .
//      .   |   .                  .   |   .                  .   |   .
//     /    |    \                /    |    \                /    |    \
//     :    |    :                :    |    :                :    |    :
//     :    |    :                :    |    :                :    |    :
//    \:/   |   \:/              \:/   |   \:/              \:/   |   \:/
//     ~    |    ~                ~    |    ~                ~    |    ~
//[4] o o   |   o o [5]      [4] o o   |   o o [5]      [4] o o   |   o o [5]
//   o_0_o  |  o_0_o            o_0_o  |  o_0_o            o_0_o  |  o_0_o
//   o~0~o  |  o~0~o            o~0~o  |  o~0~o            o~0~o  |  o~0~o
//    o o ) | ( o o              o o ) | ( o o              o o ) | ( o o
//       /  |  \                    /  |  \                    /  |  \
//      /   |   \                  /   |   \                  /   |   \
//     /    |    \                /    |    \                /    |    \
//    /     |     \              /     |     \              /     |     \
//   /      o      \            /      o      \            /      o      \
//  /      [1]      \          /      [1]      \          /      [1]      \
// o                 o        o                 o        o                 o
//[1]               [1]      [1]               [1]      [1]               [1]
//
// ****************************************************************************
