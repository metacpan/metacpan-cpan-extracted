/**
 * This is the Cookie() constructor function.
 *
 * This constructor looks for a cookie with the specified name for the
 * current document.  If one exists, it parses its value into a set of
 * name/value pairs and stores those values as properties of the newly created
 * object.
 *
 * To store new data in the cookie, simply set properties of the Cookie
 * object.  Avoid properties named "store" and "remove" since these are 
 * reserved as method names.
 * 
 * To save cookie data in the web browser's local store, call store().
 * To remove cookie data from the browser's store, call remove().
 *
 * The static method Cookie.enabled() returns true if cookies are
 * enabled and returns false otherwise.
 */
function Cookie(name) {
    this.$name = name;  // Remember the name of this cookie

    // First, get a list of all cookies that pertain to this document
    // We do this by reading the magic Document.cookie property
    // If there are no cookies, we don't have anything to do 
    var allcookies = document.cookie;
    if (allcookies == "") return;

    // Break the string of all cookies into individual cookie strings
    // Then loop through the cookie strings, looking for our name
    var cookies = allcookies.split(';');
    var cookie = null;
    for(var i = 0; i < cookies.length; i++) {
        // Does this cookie string begin with the name we want?
        if (cookies[i].substring(0, name.length+1) == (name + "=")) {
            cookie = cookies[i];
            break;
        }
    }

    // If we didn't find a matching cookie, quit now
    if (cookie == null) return;

    // The cookie value is the part after the equals sign
    var cookieval = cookie.substring(name.length+1);

    // Now that we've extracted the value of the named cookie, we
    // must break that value down into individual state variable 
    // names and values. The name/value pairs are separated from each
    // other by ampersands, and the individual names and values are
    // separated from each other by colons. We use the split() method
    // to parse everything.
    var a = cookieval.split('&'); // Break it into an array of name/value pairs
    for(var i=0; i < a.length; i++)  // Break each pair into an array
        a[i] = a[i].split(':');

    // Now that we've parsed the cookie value, set all the names and values
    // as properties of this Cookie object. Note that we decode
    // the property value because the store() method encodes it
    for(var i = 0; i < a.length; i++) {
        this[a[i][0]] = decodeURIComponent(a[i][1]);
    }
}

/**
 * This function is the store() method of the Cookie object.
 *
 * Arguments:
 *
 *   daysToLive: the lifetime of the cookie, in days. If you set this
 *     to zero, the cookie will be deleted.  If you set it to null, or 
 *     omit this argument, the cookie will be a session cookie and will
 *     not be retained when the browser exits.  This argument is used to
 *     set the max-age attribute of the cookie.
 *   path: the value of the path attribute of the cookie
 *   domain: the value of the domain attribute of the cookie
 *   secure: if true, the secure attribute of the cookie will be set
 */
Cookie.prototype.store = function(daysToLive, path, domain, secure) {
    // First, loop through the properties of the Cookie object and
    // put together the value of the cookie. Since cookies use the
    // equals sign and semicolons as separators, we'll use colons
    // and ampersands for the individual state variables we store 
    // within a single cookie value. Note that we encode the value
    // of each property in case it contains punctuation or other
    // illegal characters.
    var cookieval = "";
    for(var prop in this) {
        // Ignore properties with names that begin with '$' and also methods
        if ((prop.charAt(0) == '$') || ((typeof this[prop]) == 'function')) 
            continue;
        if (cookieval != "") cookieval += '&';
        cookieval += prop + ':' + encodeURIComponent(this[prop]);
    }

    // Now that we have the value of the cookie, put together the 
    // complete cookie string, which includes the name and the various
    // attributes specified when the Cookie object was created
    var cookie = this.$name + '=' + cookieval;
    if (daysToLive || daysToLive == 0) { 
        cookie += "; max-age=" + (daysToLive*24*60*60);
    }

    if (path) cookie += "; path=" + path;
    if (domain) cookie += "; domain=" + domain;
    if (secure) cookie += "; secure";

    // Now store the cookie by setting the magic Document.cookie property
    document.cookie = cookie;
}

/**
 * This function is the remove() method of the Cookie object; it deletes the
 * properties of the object and removes the cookie from the browser's 
 * local store.
 * 
 * The arguments to this function are all optional, but to remove a cookie
 * you must pass the same values you passed to store().
 */
Cookie.prototype.remove = function(path, domain, secure) {
    // Delete the properties of the cookie
    for(var prop in this) {
        if (prop.charAt(0) != '$' && typeof this[prop] != 'function') 
            delete this[prop];
    }

    // Then, store the cookie with a lifetime of 0
    this.store(0, path, domain, secure);
}

/**
 * This static method attempts to determine whether cookies are enabled.
 * It returns true if they appear to be enabled and false otherwise.
 * A return value of true does not guarantee that cookies actually persist.
 * Nonpersistent session cookies may still work even if this method 
 * returns false.
 */
Cookie.enabled = function() {
    // Use navigator.cookieEnabled if this browser defines it
    if (navigator.cookieEnabled != undefined) return navigator.cookieEnabled;

    // If we've already cached a value, use that value
    if (Cookie.enabled.cache != undefined) return Cookie.enabled.cache;

    // Otherwise, create a test cookie with a lifetime
    document.cookie = "testcookie=test; max-age=10000";  // Set cookie

    // Now see if that cookie was saved
    var cookies = document.cookie;
    if (cookies.indexOf("testcookie=test") == -1) {
        // The cookie was not saved
        return Cookie.enabled.cache = false;
    }
    else {
        // Cookie was saved, so we've got to delete it before returning
        document.cookie = "testcookie=test; max-age=0";  // Delete cookie
        return Cookie.enabled.cache = true;
    }
}
