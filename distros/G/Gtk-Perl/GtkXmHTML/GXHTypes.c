
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

#include <gtk-xmhtml/gtk-xmhtml.h>
#include "GtkXmHTMLDefs.h"

static char *urls [] = {
        "unknown", "named (...)", "jump (#...)",
        "file_local (file.html)", "file_remote (file://foo.bar/file)",
        "ftp", "http", "gopher", "wais", "news", "telnet", "mailto",
        "exec:foo_bar", "internal"
};

	/* completely busted */
XmAnyCallbackStruct * SvGtkXmHTMLCallbackStruct(SV * data)
{
	return 0;
}

XmAnyCallbackStruct * SvSetXmAnyCallbackStruct(SV * data, XmAnyCallbackStruct * e)
{
	return 0;
}

SV * newSVXmAnyCallbackStruct(XmAnyCallbackStruct * e)
{
	HV * h;
	SV * r;
	int n;
	
	if (!e)
		return newSVsv(&PL_sv_undef);
 
        h = newHV();

	r = newRV((SV*)h);
	SvREFCNT_dec(h);

	/*sv_bless(r, gv_stashpv("Gtk::XmHTMLCallback", FALSE));*/
 	
	hv_store(h, "_ptr", 4, newSViv((int)e), 0);

	/*g_warning("html reason: %d\n", e->reason);*/
	/* workaround bug in gtkxmhtml */
	if (e->reason) {
		hv_store(h, "reason", 6, newSVXmHTMLCallbackReason(e->reason), 0);
	} else {
		hv_store(h, "reason", 6, newSVpv("activate", 0), 0);
	}
	hv_store(h, "event", 5, newSVGdkEvent(e->event), 0);
	switch (e->reason) {
	case XmCR_HTML_ANCHORTRACK:
	case XmCR_ACTIVATE:
		{
			XmHTMLAnchorCallbackStruct *cbs = (XmHTMLAnchorCallbackStruct*)e;
			hv_store(h, "urltype", 7, newSVpv(urls[cbs->url_type], 0), 0);
			hv_store(h, "line", 4, newSViv(cbs->line), 0);
			if (cbs->href)
				hv_store(h, "href", 4, newSVpv(cbs->href, 0), 0);
			if (cbs->target)
				hv_store(h, "target", 6, newSVpv(cbs->target, 0), 0);
			if (cbs->rel)
				hv_store(h, "rel", 3, newSVpv(cbs->rel, 0), 0);
			if (cbs->title)
				hv_store(h, "title", 5, newSVpv(cbs->title, 0), 0);
			hv_store(h, "doit", 4, newSViv(cbs->doit), 0);
			hv_store(h, "visited", 7, newSViv(cbs->visited), 0);
		}
		break;
	}
	
	return r;
}
