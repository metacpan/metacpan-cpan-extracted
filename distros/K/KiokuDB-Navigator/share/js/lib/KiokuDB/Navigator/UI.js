
if (KiokuDB           == undefined) var KiokuDB           = function () {};
if (KiokuDB.Navigator == undefined)     KiokuDB.Navigator = function () {};

KiokuDB.Navigator.UI = function (options) {
    this.id        = options['id'] || 'root';
    this.container = options['container'];
    this.navigator = options['navigator'];
}

KiokuDB.Navigator.UI.prototype.load_object = function (callback) {
    var self = this;
    this.navigator.lookup(
        this.id,
        function (obj) {
            self.obj = obj;

            // create a holder for the object ...
            var object_container = self.create_object_container();

            // if we don't have a container to
            // put ourselves in, we need to create
            // and initialize one
            if (self.container == undefined) {
                self.container = jQuery( self.create_entity_container( object_container ) );
            }
            else {
                self.container.html( object_container );
            }

            // create and insert the
            // object represetation
            jQuery('.data ul', self.container).html(
                self.create_entity_repr( self.obj['data'] )
            );

            self.init_event_handlers();

            if (callback != undefined) { callback( self ) }
        }
    );
}

KiokuDB.Navigator.UI.prototype.init_event_handlers = function () {

    var self = this;

    jQuery('.navigator_handle', this.container).toggle(
        function () { jQuery('.data', jQuery(this).parent().parent()).hide() },
        function () { jQuery('.data', jQuery(this).parent().parent()).show() }
    );

    jQuery('.loader', this.container).click(function () {
        var id = jQuery(this).attr('id');

        (new KiokuDB.Navigator.UI ({
            'id'        : id,
            'container' : jQuery(this).siblings('.sub_object'),
            'navigator' : self.navigator
        })).load_object();

        jQuery(this).siblings('.sub_object').removeClass('hidden');
        jQuery(this).unbind('click');
        jQuery(this).click(function () {
            jQuery(this).siblings('.sub_object').toggle()
        });
    });
}

KiokuDB.Navigator.UI.prototype.create_entity_container = function ( container ) {
    return '<div class="window">'
         +     '<div class="handle">'
         +         '<a class="navigator_handle" href="#">[ _ ]</a>'
         +         '&nbsp;'
         +         '<a href="#" onclick="$(this).parent().parent().remove()">[ x ]</a>'
         +     '</div>'
         +     '<div class="body">'
         +        container
         +     '</div>'
         + '</div>'
}

KiokuDB.Navigator.UI.prototype.create_object_container = function () {
    return '<div class="object">'
         +     '<div class="header">'
         + (this.obj['__CLASS__'] == undefined
             ? ('')
             : ('<div class="__CLASS__">' + this.obj['__CLASS__'] + '</div>'))
         +        '<div class="id">'  + this.id +  '</div>'
         +     '</div>'
         +     '<div class="data">'
         +        '<ul id="' + this.id + '"></ul>'
         +     '</div>'
         + '</div>';
}

KiokuDB.Navigator.UI.prototype.create_entity_repr = function (obj) {
    var out = '';
    if (obj.constructor == Array) {
        // this will handle KiokuDB::Set objects
        for (var i = 0; i < obj.length; i++) {
            out += '<li>' + this.create_repr( obj[i] ) + '</li>';
        }
    }
    else if (typeof obj === "object") {
        // other objects
        for (var prop in obj) {
            out += '<li><div class="label">' + prop + '</div><div class="value">';
            out += this.create_repr( obj[prop] );
            out += "</div></li>"
        }
    }
    else {
        // collapsed objects
        out += '<li><div class="label">data</div><div class="value">';
        out += this.create_repr( obj );
        out += "</div></li>"
    }

    return out;
}

KiokuDB.Navigator.UI.prototype.create_repr = function (x) {
    var out = '';
    if (x === null) {
        return "<span class='undef'>undef</span>";
    }
    switch (x.constructor) {
        case Object:
            out += this.create_object_repr(x);
            break;
        case Array:
            out += this.create_array_repr(x);
            break;
        case String:
            // if we find a string which
            // looks a lot like a ref then
            // we make an assumption and
            // just make it a link
            if (this.is_ref_id(x)) {
                out += this.create_object_link( x );
            }
            else {
                out += x;
            }
            break;
        default:
            out += x;
    }
    return out;
}

KiokuDB.Navigator.UI.prototype.create_object_repr = function (obj) {
    if (obj['$ref']) {
        // we are assuming here that
        // an object with a $ref key
        // will be a jspon object and
        // so be nothing more then a ref
        return this.create_object_link( obj['$ref'] )
    }
    else {
        var out = '<table class="hash">';
        for (var prop in obj) {
            out += "<tr>"
                 + "<td valign='top' class='hash_key'>" + prop + "</td>"
                 + "<td valign='top' class='fat_comma'>=></td>"
                 + "<td valign='top' class='hash_value'>" + this.create_repr( obj[prop] ) + "</td>"
                 + "</tr>";
        }
        out += '</table>';
        return out;
    }
}

KiokuDB.Navigator.UI.prototype.create_array_repr = function (arr) {
    // IMPROVE ME:
    // This could be made nicer,
    // perhaps with scrolling if
    // it is too long.
    // - SL
    var out = '<ul>';
    for (var i = 0; i < arr.length; i++) {
        out += '<li>' + this.create_repr( arr[i] ) + '</li>';
    }
    out += '</ul>';
    return out;
}

KiokuDB.Navigator.UI.prototype.create_object_link = function (ref_id) {
    if (ref_id.indexOf('.data') != -1) {
        ref_id = ref_id.substring(0, ref_id.indexOf('.data'));
    }
    return '<a id="' + ref_id + '" class="loader" href="javascript:void(0)">'
         + ref_id
         + '</a><div class="sub_object hidden"></div>';
}


KiokuDB.Navigator.UI.prototype.is_ref_id = function (id) {
    if (id.indexOf('-') == 8 && id.lastIndexOf('-') == 23) {
        return true;
    }
    return false;
}
