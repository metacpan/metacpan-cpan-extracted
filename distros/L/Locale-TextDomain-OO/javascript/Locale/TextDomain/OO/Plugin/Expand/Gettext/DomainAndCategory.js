/*
version 1.014

requires:
localeTextDomainOO
*/

function localeTextDomainOOExpandGettextDomainAndCategory(ltdoo) {
    var shadowDomains    = [];
    var shadowCategories = [];

    localeTextDomainOO.prototype.__begin_d = function(domain) {
        if ( domain === undefined ) {
            throw 'Domain is not defined';
        }
        shadowDomains.push(this.domain);
        this.domain = domain;

        return;
    };
    localeTextDomainOO.prototype.__begin_c = function(category) {
        if ( category === undefined ) {
            throw 'Category is not defined';
        }
        shadowCategories.push(this.category);
        this.category = category;

        return;
    };
    localeTextDomainOO.prototype.__begin_dc = function(domain, category) {
        this.__begin_d(domain);
        this.__begin_c(category);

        return;
    };

    localeTextDomainOO.prototype.__end_d = function() {
        if ( ! shadowDomains.length ) {
            throw 'Tried to get the domain from stack but no domain is not stored';
        }
        this.domain = shadowDomains.pop();

        return;
    };
    localeTextDomainOO.prototype.__end_c = function() {
        if ( ! shadowCategories.length ) {
            throw 'Tried to get the category from stack but no category is stored';
        }
        this.category = shadowCategories.pop();

        return;
    };
    localeTextDomainOO.prototype.__end_dc = function() {
        this.__end_d();
        this.__end_c();

        return;
    };

    localeTextDomainOO.prototype.__dx = function(domain, msgid, argMap) {
        this.__begin_d(domain);
        var translation = this.__x(msgid, argMap);
        this.__end_d();

        return translation;
    };
    localeTextDomainOO.prototype.__cx = function(msgid, category, argMap) {
        this.__begin_c(category);
        var translation = this.__x(msgid, argMap);
        this.__end_c();

        return translation;
    };
    localeTextDomainOO.prototype.__dcx = function(domain, msgid, category, argMap) {
        this.__begin_d(domain);
        var translation = this.__cx(msgid, category, argMap);
        this.__end_d();

        return translation;
    };

    localeTextDomainOO.prototype.__dnx = function(domain, msgid, msgid_plural, count, argMap) {
        this.__begin_d(domain);
        var translation = this.__nx(msgid, msgid_plural, count, argMap);
        this.__end_d();

        return translation;
    };
    localeTextDomainOO.prototype.__cnx = function(msgid, msgid_plural, count, category, argMap) {
        this.__begin_c(category);
        var translation = this.__nx(msgid, msgid_plural, count, argMap);
        this.__end_c();

        return translation;
    };
    localeTextDomainOO.prototype.__dcnx = function(domain, msgid, msgid_plural, count, category, argMap) {
        this.__begin_d(domain);
        var translation = this.__cnx(msgid, msgid_plural, count, category, argMap);
        this.__end_d();

        return translation;
    };

    localeTextDomainOO.prototype.__dpx = function(domain, msgctxt, msgid, argMap) {
        this.__begin_d(domain);
        var translation = this.__px(msgctxt, msgid, argMap);
        this.__end_d();

        return translation;
    };
    localeTextDomainOO.prototype.__cpx = function(msgctxt, msgid, category, argMap) {
        this.__begin_c(category);
        var translation = this.__px(msgctxt, msgid, argMap);
        this.__end_c();

        return translation;
    };
    localeTextDomainOO.prototype.__dcpx = function(domain, msgctxt, msgid, category, argMap) {
        this.__begin_d(domain);
        var translation = this.__cpx(msgctxt, msgid, category, argMap);
        this.__end_d();

        return translation;
    };

    localeTextDomainOO.prototype.__dnpx = function(domain, msgctxt, msgid, msgid_plural, count, argMap) {
        this.__begin_d(domain);
        var translation = this.__npx(msgctxt, msgid, msgid_plural, count, argMap);
        this.__end_d();

        return translation;
    };
    localeTextDomainOO.prototype.__cnpx = function(msgctxt, msgid, msgid_plural, count, category, argMap) {
        this.__begin_c(category);
        var translation = this.__npx(msgctxt, msgid, msgid_plural, count, argMap);
        this.__end_c();

        return translation;
    };
    localeTextDomainOO.prototype.__dcnpx = function(domain, msgctxt, msgid, msgid_plural, count, category, argMap) {
        this.__begin_d(domain);
        var translation = this.__cnpx(msgctxt, msgid, msgid_plural, count, category, argMap);
        this.__end_d();

        return translation;
    };

    localeTextDomainOO.prototype.__d   = localeTextDomainOO.prototype.__dx;
    localeTextDomainOO.prototype.__dn  = localeTextDomainOO.prototype.__dnx;
    localeTextDomainOO.prototype.__dp  = localeTextDomainOO.prototype.__dpx;
    localeTextDomainOO.prototype.__dnp = localeTextDomainOO.prototype.__dnpx;

    localeTextDomainOO.prototype.__c   = localeTextDomainOO.prototype.__cx;
    localeTextDomainOO.prototype.__cn  = localeTextDomainOO.prototype.__cnx;
    localeTextDomainOO.prototype.__cp  = localeTextDomainOO.prototype.__cpx;
    localeTextDomainOO.prototype.__cnp = localeTextDomainOO.prototype.__cnpx;

    localeTextDomainOO.prototype.__dc   = localeTextDomainOO.prototype.__dcx;
    localeTextDomainOO.prototype.__dcn  = localeTextDomainOO.prototype.__dcnx;
    localeTextDomainOO.prototype.__dcp  = localeTextDomainOO.prototype.__dcpx;
    localeTextDomainOO.prototype.__dcnp = localeTextDomainOO.prototype.__dcnpx;

    localeTextDomainOO.prototype.N__d   = function (domain, msgid) {
        return [domain, msgid];
    };
    localeTextDomainOO.prototype.N__dn  = function (domain, msgid, msgid_plural, count) {
        return [domain, msgid, msgid_plural, count];
    };
    localeTextDomainOO.prototype.N__dp  = function (domain, msgctxt, msgid) {
        return [domain, msgctxt, msgid];
    };
    localeTextDomainOO.prototype.N__dnp = function (domain, msgctxt, msgid, msgid_plural, count) {
        return [domain, msgctxt, msgid, msgid_plural, count];
    };

    localeTextDomainOO.prototype.N__dx   = function (domain, msgid, argMap) {
        return [domain, msgid, argMap];
    };
    localeTextDomainOO.prototype.N__dnx  = function (domain, msgid, msgid_plural, count, argMap) {
        return [domain, msgid, msgid_plural, count, argMap];
    };
    localeTextDomainOO.prototype.N__dpx  = function (domain, msgctxt, msgid, argMap) {
        return [domain, msgctxt, msgid, argMap];
    };
    localeTextDomainOO.prototype.N__dnpx = function (domain, msgctxt, msgid, msgid_plural, count, argMap) {
        return [domain, msgctxt, msgid, msgid_plural, count, argMap];
    };

    localeTextDomainOO.prototype.N__c   = function (msgid, category) {
        return [msgid, category];
    };
    localeTextDomainOO.prototype.N__cn  = function (msgid, msgid_plural, count, category) {
        return [msgid, msgid_plural, count, category];
    };
    localeTextDomainOO.prototype.N__cp  = function (msgctxt, msgid, category) {
        return [msgctxt, msgid, category];
    };
    localeTextDomainOO.prototype.N__cnp = function (msgctxt, msgid, msgid_plural, count, category) {
        return [msgctxt, msgid, msgid_plural, count, category];
    };

    localeTextDomainOO.prototype.N__cx   = function (msgid, category, argMap) {
        return [msgid, category, argMap];
    };
    localeTextDomainOO.prototype.N__cnx  = function (msgid, msgid_plural, count, category, argMap) {
        return [msgid, msgid_plural, count, category, argMap];
    };
    localeTextDomainOO.prototype.N__cpx  = function (msgctxt, msgid, category, argMap) {
        return [msgctxt, msgid, category, argMap];
    };
    localeTextDomainOO.prototype.N__cnpx = function (msgctxt, msgid, msgid_plural, count, category, argMap) {
        return [msgctxt, msgid, msgid_plural, count, category, argMap];
    };

    localeTextDomainOO.prototype.N__dc   = function (domain, msgid, category) {
        return [domain, msgid, category];
    };
    localeTextDomainOO.prototype.N__dcn  = function (domain, msgid, msgid_plural, count, category) {
        return [domain, msgid, msgid_plural, count, category];
    };
    localeTextDomainOO.prototype.N__dcp  = function (domain, msgctxt, msgid, category) {
        return [domain, msgctxt, msgid, category];
    };
    localeTextDomainOO.prototype.N__dcnp = function (domain, msgctxt, msgid, msgid_plural, count, category) {
        return [domain, msgctxt, msgid, msgid_plural, count, category];
    };

    localeTextDomainOO.prototype.N__dcx   = function (domain, msgid, category, argMap) {
        return [domain, msgid, category, argMap];
    };
    localeTextDomainOO.prototype.N__dcnx  = function (domain, msgid, msgid_plural, count, category, argMap) {
        return [domain, msgid, msgid_plural, count, category, argMap];
    };
    localeTextDomainOO.prototype.N__dcpx  = function (domain, msgctxt, msgid, category, argMap) {
        return [domain, msgctxt, msgid, category, argMap];
    };
    localeTextDomainOO.prototype.N__dcnpx = function (domain, msgctxt, msgid, msgid_plural, count, category, argMap) {
        return [domain, msgctxt, msgid, msgid_plural, count, category, argMap];
    };

    return;
}
