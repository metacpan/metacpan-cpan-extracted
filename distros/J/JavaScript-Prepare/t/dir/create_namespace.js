namespace.create = function () {
    var args = arguments;
    var alen = args.length;
    var dest, ns;
    
    for ( var i = 0; i < alen ; i++ ) {
        dest = (""+args[i]).split(".");
        dlen = dest.length;
        ns   = namespace;
        
        for ( var j = (dest[0] == "namespace") ? 1 : 0 ; j < dlen ; j++ ) {
            ns[ dest[j] ] = ns[ dest[j] ] || {};
            ns = ns[ dest[j] ];
        }
    }
    
    return ns;
};
