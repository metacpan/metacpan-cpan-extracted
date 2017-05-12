%# $Id: search.mc,v 1.3 2008-01-29 14:49:03 mike Exp $
<%perl>
    if (defined utf8param($r, "_submit") || defined utf8param($r, "_query")) {
	$m->comp("submitted.mc", %ARGS);
    } else {
	$m->comp("form.mc", %ARGS);
    }
</%perl>
