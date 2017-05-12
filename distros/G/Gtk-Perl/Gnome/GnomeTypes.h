
#ifndef _Gnome_Types_h_
#define _Gnome_Types_h_

typedef GnomeDesktopEntry * Gnome__DesktopEntry;
typedef GnomeCanvasItem * Gnome__CanvasItem_Up;
typedef GnomeCanvasItem * Gnome__CanvasItem_Sink_Up;
typedef GnomeCanvasItem * Gnome__CanvasItem_OrNULL_Up;

/* if must already be allocated */
void SvGnomeUIInfo (SV *data, GnomeUIInfo *info);

#endif /*_Gnome_Types_h_*/
