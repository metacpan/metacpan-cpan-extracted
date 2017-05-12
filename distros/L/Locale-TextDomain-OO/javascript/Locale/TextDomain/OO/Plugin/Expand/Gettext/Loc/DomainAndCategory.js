/*
version 1.014

requires:
localeTextDomainOO
*/
function localeTextDomainOOExpandGettextLocDomainAndCategory(ltdoo) {
    var shadowDomains    = [];
    var shadowCategories = [];

    localeTextDomainOO.prototype.loc_begin_d = function(domain) {
        if ( domain === undefined ) {
            throw 'Domain is not defined';
        }
        shadowDomains.push(this.domain);
        this.domain = domain;

        return;
    };
    localeTextDomainOO.prototype.loc_begin_c = function(category) {
        if ( category === undefined ) {
            throw 'Category is not defined';
        }
        shadowCategories.push(this.category);
        this.category = category;

        return;
    };
    localeTextDomainOO.prototype.loc_begin_dc = function(domain, category) {
        this.loc_begin_d(domain);
        this.loc_begin_c(category);

        return;
    };

    localeTextDomainOO.prototype.loc_end_d = function() {
        if ( ! shadowDomains.length ) {
            throw 'Tried to get the domain from stack but no domain is not stored';
        }
        this.domain = shadowDomains.pop();

        return;
    };
    localeTextDomainOO.prototype.loc_end_c = function() {
        if ( ! shadowCategories.length ) {
            throw 'Tried to get the category from stack but no category is stored';
        }
        this.category = shadowCategories.pop();

        return;
    };
    localeTextDomainOO.prototype.loc_end_dc = function() {
        this.loc_end_d();
        this.loc_end_c();

        return;
    };

    localeTextDomainOO.prototype.loc_dx = function(domain, msgid, argMap) {
        this.loc_begin_d(domain);
        var translation = this.loc_x(msgid, argMap);
        this.loc_end_d();

        return translation;
    };
    localeTextDomainOO.prototype.loc_cx = function(msgid, category, argMap) {
        this.loc_begin_c(category);
        var translation = this.loc_x(msgid, argMap);
        this.loc_end_c();

        return translation;
    };
    localeTextDomainOO.prototype.loc_dcx = function(domain, msgid, category, argMap) {
        this.loc_begin_d(domain);
        var translation = this.loc_cx(msgid, category, argMap);
        this.loc_end_d();

        return translation;
    };

    localeTextDomainOO.prototype.loc_dnx = function(domain, msgid, msgid_plural, count, argMap) {
        this.loc_begin_d(domain);
        var translation = this.loc_nx(msgid, msgid_plural, count, argMap);
        this.loc_end_d();

        return translation;
    };
    localeTextDomainOO.prototype.loc_cnx = function(msgid, msgid_plural, count, category, argMap) {
        this.loc_begin_c(category);
        var translation = this.loc_nx(msgid, msgid_plural, count, argMap);
        this.loc_end_c();

        return translation;
    };
    localeTextDomainOO.prototype.loc_dcnx = function(domain, msgid, msgid_plural, count, category, argMap) {
        this.loc_begin_d(domain);
        var translation = this.loc_cnx(msgid, msgid_plural, count, category, argMap);
        this.loc_end_d();

        return translation;
    };

    localeTextDomainOO.prototype.loc_dpx = function(domain, msgctxt, msgid, argMap) {
        this.loc_begin_d(domain);
        var translation = this.loc_px(msgctxt, msgid, argMap);
        this.loc_end_d();

        return translation;
    };
    localeTextDomainOO.prototype.loc_cpx = function(msgctxt, msgid, category, argMap) {
        this.loc_begin_c(category);
        var translation = this.loc_px(msgctxt, msgid, argMap);
        this.loc_end_c();

        return translation;
    };
    localeTextDomainOO.prototype.loc_dcpx = function(domain, msgctxt, msgid, category, argMap) {
        this.loc_begin_d(domain);
        var translation = this.loc_cpx(msgctxt, msgid, category, argMap);
        this.loc_end_d();

        return translation;
    };

    localeTextDomainOO.prototype.loc_dnpx = function(domain, msgctxt, msgid, msgid_plural, count, argMap) {
        this.loc_begin_d(domain);
        var translation = this.loc_npx(msgctxt, msgid, msgid_plural, count, argMap);
        this.loc_end_d();

        return translation;
    };
    localeTextDomainOO.prototype.loc_cnpx = function(msgctxt, msgid, msgid_plural, count, category, argMap) {
        this.loc_begin_c(category);
        var translation = this.loc_npx(msgctxt, msgid, msgid_plural, count, argMap);
        this.loc_end_c();

        return translation;
    };
    localeTextDomainOO.prototype.loc_dcnpx = function(domain, msgctxt, msgid, msgid_plural, count, category, argMap) {
        this.loc_begin_d(domain);
        var translation = this.loc_cnpx(msgctxt, msgid, msgid_plural, count, category, argMap);
        this.loc_end_d();

        return translation;
    };

    localeTextDomainOO.prototype.loc_d   = localeTextDomainOO.prototype.loc_dx;
    localeTextDomainOO.prototype.loc_dn  = localeTextDomainOO.prototype.loc_dnx;
    localeTextDomainOO.prototype.loc_dp  = localeTextDomainOO.prototype.loc_dpx;
    localeTextDomainOO.prototype.loc_dnp = localeTextDomainOO.prototype.loc_dnpx;

    localeTextDomainOO.prototype.loc_c   = localeTextDomainOO.prototype.loc_cx;
    localeTextDomainOO.prototype.loc_cn  = localeTextDomainOO.prototype.loc_cnx;
    localeTextDomainOO.prototype.loc_cp  = localeTextDomainOO.prototype.loc_cpx;
    localeTextDomainOO.prototype.loc_cnp = localeTextDomainOO.prototype.loc_cnpx;

    localeTextDomainOO.prototype.loc_dc   = localeTextDomainOO.prototype.loc_dcx;
    localeTextDomainOO.prototype.loc_dcn  = localeTextDomainOO.prototype.loc_dcnx;
    localeTextDomainOO.prototype.loc_dcp  = localeTextDomainOO.prototype.loc_dcpx;
    localeTextDomainOO.prototype.loc_dcnp = localeTextDomainOO.prototype.loc_dcnpx;

    localeTextDomainOO.prototype.Nloc_d   = function (domain, msgid) {
        return [domain, msgid];
    };
    localeTextDomainOO.prototype.Nloc_dn  = function (domain, msgid, msgid_plural, count) {
        return [domain, msgid, msgid_plural, count];
    };
    localeTextDomainOO.prototype.Nloc_dp  = function (domain, msgctxt, msgid) {
        return [domain, msgctxt, msgid];
    };
    localeTextDomainOO.prototype.Nloc_dnp = function (domain, msgctxt, msgid, msgid_plural, count) {
        return [domain, msgctxt, msgid, msgid_plural, count];
    };

    localeTextDomainOO.prototype.Nloc_dx   = function (domain, msgid, argMap) {
        return [domain, msgid, argMap];
    };
    localeTextDomainOO.prototype.Nloc_dnx  = function (domain, msgid, msgid_plural, count, argMap) {
        return [domain, msgid, msgid_plural, count, argMap];
    };
    localeTextDomainOO.prototype.Nloc_dpx  = function (domain, msgctxt, msgid, argMap) {
        return [domain, msgctxt, msgid, argMap];
    };
    localeTextDomainOO.prototype.Nloc_dnpx = function (domain, msgctxt, msgid, msgid_plural, count, argMap) {
        return [domain, msgctxt, msgid, msgid_plural, count, argMap];
    };

    localeTextDomainOO.prototype.Nloc_c   = function (msgid, category) {
        return [msgid, category];
    };
    localeTextDomainOO.prototype.Nloc_cn  = function (msgid, msgid_plural, count, category) {
        return [msgid, msgid_plural, count, category];
    };
    localeTextDomainOO.prototype.Nloc_cp  = function (msgctxt, msgid, category) {
        return [msgctxt, msgid, category];
    };
    localeTextDomainOO.prototype.Nloc_cnp = function (msgctxt, msgid, msgid_plural, count, category) {
        return [msgctxt, msgid, msgid_plural, count, category];
    };

    localeTextDomainOO.prototype.Nloc_cx   = function (msgid, category, argMap) {
        return [msgid, category, argMap];
    };
    localeTextDomainOO.prototype.Nloc_cnx  = function (msgid, msgid_plural, count, category, argMap) {
        return [msgid, msgid_plural, count, category, argMap];
    };
    localeTextDomainOO.prototype.Nloc_cpx  = function (msgctxt, msgid, category, argMap) {
        return [msgctxt, msgid, category, argMap];
    };
    localeTextDomainOO.prototype.Nloc_cnpx = function (msgctxt, msgid, msgid_plural, count, category, argMap) {
        return [msgctxt, msgid, msgid_plural, count, category, argMap];
    };

    localeTextDomainOO.prototype.Nloc_dc   = function (domain, msgid, category) {
        return [domain, msgid, category];
    };
    localeTextDomainOO.prototype.Nloc_dcn  = function (domain, msgid, msgid_plural, count, category) {
        return [domain, msgid, msgid_plural, count, category];
    };
    localeTextDomainOO.prototype.Nloc_dcp  = function (domain, msgctxt, msgid, category) {
        return [domain, msgctxt, msgid, category];
    };
    localeTextDomainOO.prototype.Nloc_dcnp = function (domain, msgctxt, msgid, msgid_plural, count, category) {
        return [domain, msgctxt, msgid, msgid_plural, count, category];
    };

    localeTextDomainOO.prototype.Nloc_dcx   = function (domain, msgid, category, argMap) {
        return [domain, msgid, category, argMap];
    };
    localeTextDomainOO.prototype.Nloc_dcnx  = function (domain, msgid, msgid_plural, count, category, argMap) {
        return [domain, msgid, msgid_plural, count, category, argMap];
    };
    localeTextDomainOO.prototype.Nloc_dcpx  = function (domain, msgctxt, msgid, category, argMap) {
        return [domain, msgctxt, msgid, category, argMap];
    };
    localeTextDomainOO.prototype.Nloc_dcnpx = function (domain, msgctxt, msgid, msgid_plural, count, category, argMap) {
        return [domain, msgctxt, msgid, msgid_plural, count, category, argMap];
    };

    return;
}
