/*
version 1.014

requires:
localeTextDomainOO
*/

function localeTextDomainOOExpandGettextLoc (ltdoo) {
    // translate methods

    localeTextDomainOO.prototype.loc_ = function(msgid) {
        var translation = this.translate(undefined, msgid, undefined, undefined, false);
        if ( this.filter ) {
            return this.filter(translation);
        }

        return translation;
    };

    localeTextDomainOO.prototype.loc_x = function(msgid, argMap) {
        var translation = ltdoo.localeUtilsPlaceholderNamed.expandNamed(
            this.translate(undefined, msgid, undefined, undefined, false),
            argMap
        );
        if ( this.filter ) {
            return this.filter(translation);
        }

        return translation;
    };

    localeTextDomainOO.prototype.loc_n = function(msgid, msgid_plural, count) {
        var translation = this.translate(undefined, msgid, msgid_plural, count, true);
        if ( this.filter ) {
            return this.filter(translation);
        }

        return translation;
    };

    localeTextDomainOO.prototype.loc_nx = function(msgid, msgid_plural, count, argMap) {
        var translation = ltdoo.localeUtilsPlaceholderNamed.expandNamed(
            this.translate(undefined, msgid, msgid_plural, count, true),
            argMap
        );
        if ( this.filter ) {
            return this.filter(translation);
        }

        return translation;
    };

    localeTextDomainOO.prototype.loc_p = function(msgctxt, msgid) {
        var translation = this.translate(msgctxt, msgid, undefined, undefined, false);
        if ( this.filter ) {
            return this.filter(translation);
        }

        return translation;
    };

    localeTextDomainOO.prototype.loc_px = function(msgctxt, msgid, argMap) {
        var translation = ltdoo.localeUtilsPlaceholderNamed.expandNamed(
            this.translate(msgctxt, msgid, undefined, undefined, false),
            argMap
        );
        if ( this.filter ) {
            return this.filter(translation);
        }

        return translation;
    };

    localeTextDomainOO.prototype.loc_np = function(msgctxt, msgid, msgid_plural, count) {
        var translation = this.translate(msgctxt, msgid, msgid_plural, count, true);
        if ( this.filter ) {
            return this.filter(translation);
        }

        return translation;
    };

    localeTextDomainOO.prototype.loc_npx = function(msgctxt, msgid, msgid_plural, count, argMap) {
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

    localeTextDomainOO.prototype.Nloc_ = function(msgid) {
        return [ msgid ];
    };

    localeTextDomainOO.prototype.Nloc_x = function(msgid, argMap) {
        return [ msgid, argMap ];
    };

    localeTextDomainOO.prototype.Nloc_n = function(msgid, msgid_plural, count) {
        return [ msgid, msgid_plural, count ];
    };

    localeTextDomainOO.prototype.Nloc_nx = function(msgid, msgid_plural, count, argMap) {
        return [ msgid, msgid_plural, count, argMap ];
    };

    localeTextDomainOO.prototype.Nloc_p = function(msgctxt, msgid) {
        return [ msgctxt, msgid ];
    };

    localeTextDomainOO.prototype.Nloc_px = function(msgctxt, msgid, argMap) {
        return [ msgctxt, msgid, argMap ];
    };

    localeTextDomainOO.prototype.Nloc_np = function(msgctxt, msgid, msgid_plural, count) {
        return [ msgctxt, msgid, msgid_plural, count ];
    };

    localeTextDomainOO.prototype.Nloc_npx = function(msgctxt, msgid, msgid_plural, count, argMap) {
        return [ msgctxt, msgid, msgid_plural, count, argMap ];
    };

    return;
}
