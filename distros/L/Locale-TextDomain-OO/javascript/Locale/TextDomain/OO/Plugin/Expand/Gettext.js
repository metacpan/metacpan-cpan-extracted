/*
version 1.014

requires:
localeTextDomainOO
*/

function localeTextDomainOOExpandGettext (ltdoo) {
    // translate methods

    localeTextDomainOO.prototype.__ = function(msgid) {
        var translation = this.translate(undefined, msgid, undefined, undefined, false);
        if ( this.filter ) {
            return this.filter(translation);
        }

        return translation;
    };

    localeTextDomainOO.prototype.__x = function(msgid, argMap) {
        var translation = ltdoo.localeUtilsPlaceholderNamed.expandNamed(
            this.translate(undefined, msgid, undefined, undefined, false),
            argMap
        );
        if ( this.filter ) {
            return this.filter(translation);
        }

        return translation;
    };

    localeTextDomainOO.prototype.__n = function(msgid, msgid_plural, count) {
        var translation = this.translate(undefined, msgid, msgid_plural, count, true);
        if ( this.filter ) {
            return this.filter(translation);
        }

        return translation;
    };

    localeTextDomainOO.prototype.__nx = function(msgid, msgid_plural, count, argMap) {
        var translation = ltdoo.localeUtilsPlaceholderNamed.expandNamed(
            this.translate(undefined, msgid, msgid_plural, count, true),
            argMap
        );
        if ( this.filter ) {
            return this.filter(translation);
        }

        return translation;
    };

    localeTextDomainOO.prototype.__p = function(msgctxt, msgid) {
        var translation = this.translate(msgctxt, msgid, undefined, undefined, false);
        if ( this.filter ) {
            return this.filter(translation);
        }

        return translation;
    };

    localeTextDomainOO.prototype.__px = function(msgctxt, msgid, argMap) {
        var translation = ltdoo.localeUtilsPlaceholderNamed.expandNamed(
            this.translate(msgctxt, msgid, undefined, undefined, false),
            argMap
        );
        if ( this.filter ) {
            return this.filter(translation);
        }

        return translation;
    };

    localeTextDomainOO.prototype.__np = function(msgctxt, msgid, msgid_plural, count) {
        var translation = this.translate(msgctxt, msgid, msgid_plural, count, true);
        if ( this.filter ) {
            return this.filter(translation);
        }

        return translation;
    };

    localeTextDomainOO.prototype.__npx = function(msgctxt, msgid, msgid_plural, count, argMap) {
        var translation = ltdoo.localeUtilsPlaceholderNamed.expandNamed(
            this.translate(msgctxt, msgid, msgid_plural, count, true),
            argMap
        );
        if ( this.filter ) {
            return this.filter(translation);
        }

        return translation;
    };

    // extract only methods

    localeTextDomainOO.prototype.N__ = function(msgid) {
        return [ msgid ];
    };

    localeTextDomainOO.prototype.N__x = function(msgid, argMap) {
        return [ msgid, argMap ];
    };

    localeTextDomainOO.prototype.N__n = function(msgid, msgid_plural, count) {
        return [ msgid, msgid_plural, count ];
    };

    localeTextDomainOO.prototype.N__nx = function(msgid, msgid_plural, count, argMap) {
        return [ msgid, msgid_plural, count, argMap ];
    };

    localeTextDomainOO.prototype.N__p = function(msgctxt, msgid) {
        return [ msgctxt, msgid ];
    };

    localeTextDomainOO.prototype.N__px = function(msgctxt, msgid, argMap) {
        return [ msgctxt, msgid, argMap ];
    };

    localeTextDomainOO.prototype.N__np = function(msgctxt, msgid, msgid_plural, count) {
        return [ msgctxt, msgid, msgid_plural, count ];
    };

    localeTextDomainOO.prototype.N__npx = function(msgctxt, msgid, msgid_plural, count, argMap) {
        return [ msgctxt, msgid, msgid_plural, count, argMap ];
    };

    return;
}
