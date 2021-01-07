#include "recentfiles-perl.h"

#define PREP		\
	dSP;		\
	ENTER;		\
	SAVETMPS;	\
	PUSHMARK (SP);	\
	PUSHs (sv_2mortal (newSVGObject (G_OBJECT (view))));

#define CALL		\
	PUTBACK;	\
	call_sv ((SV *)GvCV (slot), G_VOID|G_DISCARD);

#define FINISH		\
	FREETMPS;	\
	LEAVE;

#define GET_METHOD(view, method)				 	  \
	HV * stash = gperl_object_stash_from_type (G_OBJECT_TYPE (view)); \
	GV * slot = gv_fetchmethod (stash, method);

static void
gtk2recentperl_recent_view_do_set_model (EggRecentView *view,
					 EggRecentModel *model)
{
	GET_METHOD (view, "DO_SET_MODEL");
	
	if (slot && GvCV (slot)) {
		dSP;

		ENTER;
		SAVETMPS;
		PUSHMARK (SP);

		EXTEND (SP, 2);
		PUSHs (newSVEggRecentView (view));
		PUSHs (newSVEggRecentModel_ornull (model));

		PUTBACK;
		call_sv ((SV *) GvCV (slot), G_VOID | G_DISCARD);
		SPAGAIN;

		PUTBACK;
		FREETMPS;
		LEAVE;
	}
}

static EggRecentModel *
gtk2recentperl_recent_view_do_get_model (EggRecentView *view)
{
	EggRecentModel *model = NULL;
	
	GET_METHOD (view, "DO_GET_MODEL");

	if (slot && GvCV (slot)) {
		SV *sv;
		dSP;

		ENTER;
		SAVETMPS;
		PUSHMARK (SP);

		EXTEND (SP, 1);
		PUSHs (newSVEggRecentView (view));

		PUTBACK;
		call_sv ((SV *) GvCV (slot), G_SCALAR);
		SPAGAIN;
		
		sv = POPs;
		if (SvOK (sv)) {
			model = SvEggRecentModel (sv);
			
			if (G_OBJECT (model)->ref_count == 1 &&
			    SvREFCNT (SvRV (sv)) == 1) {
				SvREFCNT_inc (SvRV (sv));
			}
		}
		else {
			model = NULL;
		}

		PUTBACK;
		FREETMPS;
		LEAVE;
	}

	return model;
}

static void
gtk2recentperl_recent_view_class_init (EggRecentViewClass *klass)
{
	klass->do_set_model = gtk2recentperl_recent_view_do_set_model;
	klass->do_get_model = gtk2recentperl_recent_view_do_get_model;
}


MODULE = Gtk2::Recent::View	PACKAGE = Gtk2::Recent::View	PREFIX = egg_recent_view_

=for apidoc __hide__
=cut
void
_ADD_INTERFACE (class, const char *target_class)
    CODE:
    {
	static const GInterfaceInfo iface_info = {
		(GInterfaceInitFunc) gtk2recentperl_recent_view_class_init,
		(GInterfaceFinalizeFunc) NULL,
		(gpointer) NULL
    	};
	GType gtype = gperl_object_type_from_package (target_class);
	g_type_add_interface_static (gtype, EGG_TYPE_RECENT_VIEW, &iface_info);
    }

##
##void
##egg_recent_view_clear (view)
##	EggRecentView * view

void
egg_recent_view_set_model (view, model)
	EggRecentView * view
	EggRecentModel * model

EggRecentModel_ornull *
egg_recent_view_get_model (view)
	EggRecentView * view
