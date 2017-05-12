/*
version 1.024

requires:
localeTextDomainOO
localeUtilsPlaceholderBabelFish
*/

function localeTextDomainOOExpandBabelFishLoc (ltdoo) {
    // translate methods

    localeTextDomainOO.prototype.loc_b = function(msgid, argMap) {
        var pluralCallback = ltdoo.localeUtilsPlaceholderBabelFish.pluralCallback;
        var translation = ltdoo.localeUtilsPlaceholderBabelFish.expandBabelFish(
            this.translate(undefined, msgid, undefined, undefined, false, pluralCallback),
            argMap
        );
        if ( this.filter ) {
            return this.filter(translation);
        }

        return translation;
    };

    localeTextDomainOO.prototype.loc_bp = function(msgctxt, msgid, argMap) {
        var pluralCallback = ltdoo.localeUtilsPlaceholderBabelFish.pluralCallback;
        var translation = ltdoo.localeUtilsPlaceholderBabelFish.expandBabelFish(
            this.translate(msgctxt, msgid, undefined, undefined, false, pluralCallback),
            argMap
        );
        if ( this.filter ) {
            return this.filter(translation);
        }

        return translation;
    };

    // extract only methods

    localeTextDomainOO.prototype.Nloc_b = function(msgid, argMap) {
        return [ msgid, argMap ];
    };

    localeTextDomainOO.prototype.Nloc_bp = function(msgctxt, msgid, argMap) {
        return [ msgctxt, msgid, argMap ];
    };

    return;
}
