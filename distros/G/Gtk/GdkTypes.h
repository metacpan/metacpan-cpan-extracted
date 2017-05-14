
/* Copyright (C) 1997, Kenneth Albanowski.
   This code may be distributed under the same terms as Perl itself. */
   

/*typedef GdkPixmap * Gtk__Gdk__Pixmap;
typedef GdkBitmap * Gtk__Gdk__Bitmap;
typedef GdkWindow * Gtk__Gdk__Window;*/
typedef GdkCursor * Gtk__Gdk__Cursor;
typedef GdkGC * Gtk__Gdk__GC;
typedef GdkGCValues * Gtk__Gdk__GCValues;
typedef GdkDeviceInfo * Gtk__Gdk__DeviceInfo;
typedef GdkTimeCoord * Gtk__Gdk__TimeCoord;
typedef GdkImage * Gtk__Gdk__Image;

/*typedef GdkWindow * Gtk__Gdk__Window;
typedef GdkVisual * Gtk__Gdk__Visual;
typedef GdkColormap * Gtk__Gdk__Colormap;
typedef GdkFont * Gtk__Gdk__Font;*/

typedef GdkEvent * Gtk__Gdk__Event;
typedef GdkRegion * Gtk__Gdk__Region;
typedef GdkRectangle * Gtk__Gdk__Rectangle;
typedef GdkColor * Gtk__Gdk__Color;
/*typedef GdkImageType Gtk__Gdk__ImageType;*/
/*typedef GdkWindowType Gtk__Gdk__WindowType;*/
/*typedef GdkSubwindowMode Gtk__Gdk__SubwindowMode;*/
/*typedef GdkLineStyle Gtk__Gdk__LineStyle;
typedef GdkFill Gtk__Gdk__Fill;*/
/*typedef GdkJoinStyle Gtk__Gdk__JoinStyle;*/
/*typedef GdkFunction Gtk__Gdk__Function;*/
typedef GdkAtom Gtk__Gdk__Atom;
/*typedef GdkCapStyle Gtk__Gdk__CapStyle;*/
/*typedef GdkEventMask Gtk__Gdk__EventMask;*/
/*typedef GdkInputCondition Gtk__Gdk__InputCondition;*/
/*typedef GdkModifierType Gtk__Gdk__ModifierType;*/
typedef GdkGCValuesMask Gtk__Gdk__ValuesMask;
typedef GdkGCValues Gtk__Gdk__Values;
/*typedef GdkInputSource Gtk__Gdk__InputSource;*/
/*typedef GdkInputMode Gtk__Gdk__InputMode;*/
/*typedef GdkAxisUse Gtk__Gdk__AxisUse;*/

extern int SvGdkEventType(SV * value);
extern SV * newSVGdkEventType(int value);
extern int SvGdkModifierType(SV * value);
extern SV * newSVGdkModifierType(int value);
extern int SvGdkGCValuesMask(SV * value);
extern SV * newSVGdkGCValuesMask(int value);
extern SV * newSVGdkGCValues(GdkGCValues * v);
extern GdkGCValues * SvGdkGCValues(SV * data, GdkGCValues * v, GdkGCValuesMask * m);
extern int SvGdkWindowType(SV * value);
extern SV * newSVGdkWindowType(int value);
extern int SvGdkNotifyType(SV * value);
extern SV * newSVGdkNotifyType(int value);
extern int SvGdkVisualType(SV * value);
extern SV * newSVGdkVisualType(int value);

/*extern int SvGdkInputMode(SV * value);
extern SV * newSVGdkInputMode(int value);*/
/*extern int SvGdkInputSource(SV * value);
extern SV * newSVGdkInputSource(int value);*/
/*extern int SvGdkAxisUse(SV * value);
extern SV * newSVGdkAxisUse(int value);*/

extern SV * newSVGdkDeviceInfo(GdkDeviceInfo * i);
extern SV * newSVGdkTimeCoord(GdkTimeCoord * i);

extern int SvGdkSubwindowMode(SV * value);
extern SV * newSVGdkSubwindowMode(int value);
/*extern int SvGdkLineStyle(SV * value);
extern SV * newSVGdkLineStyle(int value);*/
extern int SvGdkFunction(SV * value);
extern SV * newSVGdkFunction(int value);
extern int SvGdkJoinStyle(SV * value);
extern SV * newSVGdkJoinStyle(int value);
/*extern int SvGdkFill(SV * value);
extern SV * newSVGdkFill(int value);*/
extern int SvGdkCapStyle(SV * value);
extern SV * newSVGdkCapStyle(int value);
extern int SvGdkWindowClass(SV * value);
extern SV * newSVGdkWindowClass(int value);
extern int SvGdkWindowType(SV * value);
extern SV * newSVGdkWindowType(int value);
extern int SvGdkCursorType(SV * value);
extern SV * newSVGdkCursorType(int value);
/*extern int SvGdkEventMask(SV * value);
extern SV * newSVGdkEventMask(int value);*/
extern int SvGdkInputCondition(SV * value);
extern SV * newSVGdkInputCondition(int value);
/*extern SV * newSVGdkWindowRef(GdkWindow * w);
extern GdkWindow * SvGdkWindowRef(SV * data);
extern SV * newSVGdkPixmapRef(GdkPixmap * w);
extern GdkPixmap * SvGdkPixmapRef(SV * data);
extern SV * newSVGdkBitmapRef(GdkBitmap * w);
extern GdkBitmap * SvGdkBitmapRef(SV * data);
extern SV * newSVGdkColormapRef(GdkColormap * w);
extern GdkColormap * SvGdkColormapRef(SV * data);
extern SV * newSVGdkCursorRef(GdkCursor * w);
extern GdkCursor * SvGdkCursorRef(SV * data);
extern SV * newSVGdkVisualRef(GdkVisual * w);
extern GdkVisual * SvGdkVisualRef(SV * data);
extern SV * newSVGdkGCRef(GdkGC * g);
extern GdkGC * SvGdkGCRef(SV * data);
extern SV * newSVGdkFontRef(GdkFont * f);
extern GdkFont * SvGdkFontRef(SV * data);
extern SV * newSVGdkImageRef(GdkImage * i);
extern GdkImage * SvGdkImageRef(SV * data);*/
extern SV * newSVGdkRectangle(GdkRectangle * rect);
extern GdkRectangle * SvGdkRectangle(SV * data, GdkRectangle * rect);
extern SV * newSVGdkColor(GdkColor * color);
extern GdkColor * SvGdkColor(SV * data);
extern SV * newSVGdkAtom(GdkAtom a);
extern GdkAtom SvGdkAtom(SV * data);
extern SV * newSVGdkEvent(GdkEvent * e);
extern GdkEvent * SvGdkEvent(SV * data);
extern SV * newSVGdkRegion(GdkRegion * e);
extern GdkRegion * SvGdkRegion(SV * data);
extern GdkWindowAttr * SvGdkWindowAttr(SV * data, GdkWindowAttr * attr, gint * mask);

#define newSVGdkImage(data) newSVMiscRef((void*)data, "Gtk::Gdk::Image", 0)
#define SvGdkImage(data) (GdkImage*)SvMiscRef(data,0)
