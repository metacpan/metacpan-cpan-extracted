#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* Copyright (C) 1997, Kenneth Albanowski.
   This code may be distributed under the same terms as Perl itself. */
   
#include <gtk/gtk.h>
#include "GdkTypes.h"
#include "MiscTypes.h"

static HV * ObjectCache = 0;

void UnregisterGtkObject(HV * hv_object, GtkObject * gtk_object)
{
	char buffer[40];
	sprintf(buffer, "%lu", (unsigned long)gtk_object);

	if (!ObjectCache)
		ObjectCache = newHV();
	
	/*sv_setiv(sv_object, 0);*/
	
	/*printf("Unregistering %d from '%s'\n", hv_object, buffer);*/
	
	/*SvREFCNT(sv_object)+=2;*/
	hv_delete(ObjectCache, buffer, strlen(buffer), G_DISCARD);
	/*SvREFCNT(sv_object)--;*/
}

void RegisterGtkObject(HV * hv_object, GtkObject * gtk_object)
{
	char buffer[40];
	sprintf(buffer, "%lu", (unsigned long)gtk_object);

	if (!ObjectCache)
		ObjectCache = newHV();
	
	/*printf("Recording %d as '%s'\n", hv_object, buffer);*/



	hv_store(ObjectCache, buffer, strlen(buffer), newRV((SV*)hv_object), 0);

	/*hv_store(ObjectCache, buffer, strlen(buffer), newSViv((int)hv_object), 0);*/
}

HV * RetrieveGtkObject(GtkObject * gtk_object)
{
	char buffer[40];
	SV ** s;
	sprintf(buffer, "%lu", (unsigned long)gtk_object);

	if (!ObjectCache)
		ObjectCache = newHV();

	s = hv_fetch(ObjectCache, buffer, strlen(buffer), 0);
	
	/*printf("Looking for PO to match GO %p\n", gtk_object);*/

	/*printf("Retrieving '%s' as %d\n", buffer, (s ? (int)*s : 0));*/

	if (s)
		return (HV*)SvRV(*s);
	else
		return 0;
}

void GCGtkObjects(void) {
  if (ObjectCache)
    {
      int count = 0;
      int dead = 0;
      HE *iter;
      hv_iterinit (ObjectCache);
      while ((iter = hv_iternext (ObjectCache)))
        {
          HV *hv_obj = (HV *)SvRV(HeVAL(iter));
          GtkObject *obj = (GtkObject *)SvIV (*hv_fetch (hv_obj, "_gtk", 4, 0));
          if ((obj->ref_count == 1) && (SvREFCNT(hv_obj) == 1)) {
            dead++;
            SvREFCNT_dec(hv_obj);
          }
          count++;
        }
      /*      fprintf(stderr, "Count: %d; Dead %d\n", count, dead); */
    }
}

extern AV * gtk_typecasts;

static void DisconnectGtkObject(GtkObject * object, gpointer data)
{
	HV * h = (HV*)data;
	/*printf("DisconnectGtkObject called on GO %p, PO %p\n", object, h);*/
	
	/*printf("Disconnecting Gtk object %d/%d\n", data, object);*/
	UnregisterGtkObject(h, object);
	/*if (GTK_OBJECT_FLOATING(object)) {
		printf("GO %p is floating, sinking.\n", object);
		gtk_object_sink(object);
	}*/
	/*printf("Destroying hv %d, with object %d\n", h, object);*/
	/*hv_delete(h, "_gtk", 4, G_DISCARD); Busted, sigh */
}


SV * newSVGtkObjectRef(GtkObject * object, char * classname)
{
	HV * previous = RetrieveGtkObject(object);
	SV * result;
	if (previous) {
		result = newRV((SV*)previous);
		/*printf("Returning previous PO %p, referencing GO %p\n", previous, object);*/
		/*printf("Returning previous ref %d as %d (%d)\n", object, previous, result);*/
		/*SvREFCNT_dec(SvRV(result));*/
	} else {
		HV * h;
		SV * s;
		if (!classname) {
			SV ** k;
			k = av_fetch(gtk_typecasts, object->klass->type, 0);
			if (!k)
				croak("unknown Gtk type");
			classname = SvPV(*k, na);
		}
		h = newHV();
		s = newSViv((int)object);
		hv_store(h, "_gtk", 4, s, 0);
		result = newRV((SV*)h);
		RegisterGtkObject(h, object);
		/*printf("Setting hv %d up for destruction on object %d\n", h, object);*/
		gtk_signal_connect(object, "destroy", (GtkSignalFunc)DisconnectGtkObject, (gpointer)h);
		/*gtk_object_weakref(object, (GtkDestroyNotify)DisconnectGtkObject, (gpointer)h);*/
		sv_bless(result, gv_stashpv(classname, FALSE));
		SvREFCNT_dec(h);
		/*gtk_object_ref(object);*/
		/*printf("Creating new PO %p referencing GO %p\n", h, object);*/
	}
	return result;
}

GtkObject * SvGtkObjectRef(SV * o, char * name)
{
	HV * q;
	SV ** r;
	if (!o || !SvOK(o) || !(q=(HV*)SvRV(o)) || (SvTYPE(q) != SVt_PVHV))
		return 0;
	if (name && !sv_derived_from(o, name))
		croak("variable is not of type %s", name);
	r = hv_fetch(q, "_gtk", 4, 0);
	if (!r || !SvIV(*r))
		croak("variable is damaged %s", name);
	return (GtkObject*)SvIV(*r);
}

void disconnect_GtkObjectRef(SV * o)
{
#if 0
	HV * q;
	SV ** r;
	GtkObject * object;
	printf("DESTROY PO %p\n", o);
	/*printf("Trying to delete GtkObject %d\n", o);*/
	if (!o || !SvOK(o) || !(q=(HV*)SvRV(o)) || (SvTYPE(q) != SVt_PVHV))
		return;
	r = hv_fetch(q, "_gtk", 4, 0);
	if (!r || !SvIV(*r))
		return;
	object = (GtkObject*)SvIV(*r);
	printf("(And thus GO %p)\n", object);
#endif
#if 0
	HV * q;
	SV ** r;
	/*printf("Trying to delete GtkObject %d\n", o);*/
	if (!o || !SvOK(o) || !(q=(HV*)SvRV(o)) || (SvTYPE(q) != SVt_PVHV))
		return;
	r = hv_fetch(q, "_gtk", 4, 0);
	if (!r || !SvIV(*r))
		return;
	UnregisterGtkObject(q, (GtkObject*)SvIV(*r));
	hv_delete(q, "_gtk", 4, G_DISCARD);
#endif
}

GtkMenuEntry * SvGtkMenuEntry(SV * data, GtkMenuEntry * e)
{
	HV * h;
	SV ** s;

	if ((!data) || (!SvOK(data)) || (!SvRV(data)) || (SvTYPE(SvRV(data)) != SVt_PVHV))
		return 0;
	
	if (!e)
		e = alloc_temp(sizeof(GtkMenuEntry));

	h = (HV*)SvRV(data);
	
	if (s=hv_fetch(h, "path", 4, 0))
		e->path = SvPV(*s,na);
	else
		croak("menu entry must contain path");
	if (s=hv_fetch(h, "accelerator", 11, 0))
		e->accelerator = SvPV(*s, na);
	else
		croak("menu entry must contain accelerator");
	if (s=hv_fetch(h, "widget", 6, 0))
		e->widget = GTK_WIDGET(SvGtkObjectRef(*s, "Gtk::Widget"));
	else
		croak("menu entry must contain widget");
	if (s=hv_fetch(h, "callback", 8, 0))
		e->callback_data = newSVsv(*s);
	else
		croak("menu entry must contain callback");

	return e;
}

SV * newSVGtkMenuEntry(GtkMenuEntry * e)
{
	HV * h;
	SV * r;
	
	if (!e)
		return &sv_undef;
		
	h = newHV();
	r = newRV((SV*)h);
	SvREFCNT_dec(h);
	
	hv_store(h, "path", 4, newSVpv(e->path,0), 0);
	hv_store(h, "accelerator", 11, newSVpv(e->accelerator,0), 0);
	hv_store(h, "widget", 6, newSVGtkObjectRef(GTK_OBJECT(e->widget), 0), 0);
	hv_store(h, "callback", 11, newSVsv(e->callback_data ? e->callback_data : &sv_undef), 0);
	return r;
}

SV * newSVGtkSelectionDataRef(GdkWindow * w) { return newSVMiscRef(w, "Gtk::SelectionData",0); }
GdkWindow * SvGtkSelectionDataRef(SV * data) { return SvMiscRef(data, "Gtk::SelectionData"); }


/*SV * newSVGtkMenuPath(GtkMenuPath * e)
{
	HV * h;
	SV * r;
	
	if (!e)
		return &sv_undef;
		
	h = newHV();
	r = newRV((SV*)h);
	SvREFCNT_dec(h);
	
	hv_store(h, "path", 4, newSVpv(e->path), 0);
	hv_store(h, "widget", 6, newSVGtkObjectRef(e->widget, 0), 0);
	return r;
}
*/
