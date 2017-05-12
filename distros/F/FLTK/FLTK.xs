
#include <FL/Enumerations.H>
#include <FL/Fl.H>
#include <FL/Fl_Color.H>
#include <FL/Fl_Boxtype.H>
#include <FL/Fl_Labeltype.H>
#include <FL/Fl_Style.H>
#include <FL/Fl_Font.H>
#include <FL/Fl_Widget.H>
#include <FL/Fl_Group.H>
#include <FL/Fl_Align_Group.H>
#include <FL/Fl_Window.H>
#include <FL/Fl_Menu_.H>
#include <FL/Fl_Menu_Button.H>
#include <FL/Fl_Double_Window.H>
#include <FL/Fl_Image.H>
#include <FL/Fl_Pixmap.H>
#include <FL/Fl_Box.H>
#include <FL/Fl_Button.H>
#include <FL/Fl_Check_Button.H>
#include <FL/Fl_Light_Button.H>
#include <FL/Fl_Round_Button.H>
#include <FL/Fl_Return_Button.H>
#include <FL/Fl_Repeat_Button.H>
#include <FL/Fl_Highlight_Button.H>
#include <FL/Fl_Radio_Button.H>
#include <FL/Fl_Radio_Light_Button.H>
#include <FL/Fl_Radio_Round_Button.H>
#include <FL/Fl_Toggle_Button.H>
#include <FL/Fl_Toggle_Light_Button.H>
#include <FL/Fl_Toggle_Round_Button.H>
#include <FL/Fl_Input.H>
#include <FL/Fl_Float_Input.H>
#include <FL/Fl_Int_Input.H>
#include <FL/Fl_Multiline_Input.H>
#include <FL/Fl_Secret_Input.H>
#include <FL/Fl_Wordwrap_Input.H>
#include <FL/Fl_Tabs.H>
#include <FL/Fl_Pack.H>
#include <FL/Fl_Scroll.H>
#include <FL/Fl_Tile.H>
#include <FL/Fl_Item.H>
#include <FL/Fl_Radio_Item.H>
#include <FL/Fl_Toggle_Item.H>
#include <FL/Fl_Menu_Bar.H>
#include <FL/Fl_Choice.H>
#include <FL/Fl_Output.H>
#include <FL/Fl_Multiline_Output.H>
#include <FL/Fl_Wordwrap_Output.H>
#include <FL/Fl_Browser.H>
#include <FL/Fl_Hold_Browser.H>
#include <FL/Fl_Multi_Browser.H>
#include <FL/Fl_Select_Browser.H>
#include <FL/Fl_Shared_Image.H>
#include <FL/Fl_Valuator.H>
#include <FL/Fl_Slider.H>
#include <FL/Fl_Fill_Slider.H>
#include <FL/Fl_Hor_Fill_Slider.H>
#include <FL/Fl_Hor_Nice_Slider.H>
#include <FL/Fl_Hor_Slider.H>
#include <FL/Fl_Hor_Value_Slider.H>
#include <FL/Fl_Nice_Slider.H>
#include <FL/Fl_Value_Slider.H>
#include <FL/Fl_Scrollbar.H>
#include <FL/Fl_Tooltip.H>
#include <FL/Fl_Color_Chooser.H>
#include <FL/fl_show_colormap.H>
#include <FL/Fl_Text_Buffer.H>
#include <FL/Fl_Text_Display.H>
#include <FL/Fl_Text_Editor.H>
#include <FL/Fl_Item_Group.H>
#include <FL/fl_ask.H>
#include <FL/fl_file_chooser.H>
#include <FL/fl_draw.H>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef list
#undef list
#endif

#define FL_IMAGE_PNG  1
#define FL_IMAGE_XPM  2
#define FL_IMAGE_GIF  3
#define FL_IMAGE_JPEG 4
#define FL_IMAGE_BMP  5

#include <stdio.h>

Fl_Text_Display::Style_Table_Entry table[256];
int has_stylet = 0;
/*#include <string.h>

typedef struct pixmap_store_ {
  char **data;
} pixmap_store;

pixmap_store **pixmap_container;

int pixmap_cnt = 0;

void add_pixmap_store(void) {
  fprintf(stderr, "Entering add_pixmap_store()\n");
  if(pixmap_cnt == 0) {
    fprintf(stderr, "Allocating first pixmap element.\n");
    pixmap_container = (pixmap_store **)malloc(sizeof(pixmap_store*));
  } else {
    pixmap_cnt++;
    fprintf(stderr, "Adding %d pixmap element.\n", pixmap_cnt + 1);
    pixmap_container = (pixmap_store **)realloc((void*)pixmap_container,
                                           pixmap_cnt * sizeof(pixmap_store*));
  }
  fprintf(stderr, "Leaving add_pixmap_store()\n");
}*/
/**
 * When there's a means provided to id widgets with the type() member the
 * default callback will change to pass an object reference of the widget to
 * the perl subroutine. This means it won't happen till I enum the whole list
 * of wrapped classes and set the constructors to define this value (which is
 * to say that it'll happen the day I need this functionality...)
**/
void fltkperl_default_cb(Fl_Widget *w, void *sub) {
  int n;
  AV *cbargs = (AV *)sub;
  I32 alen = av_len(cbargs);
//  fprintf(stderr, "User data array has a length of %d.\n", alen);
  CV *thecb = (CV *)SvRV(*av_fetch(cbargs, 0, 0));

  dSP;
  ENTER;
  SAVETMPS;
  
  PUSHMARK(sp);
  for(int i = 1; i <= alen;i++) {
    XPUSHs(*av_fetch(cbargs, i, 0));
//    fprintf(stderr, "%d: %s\n", i, (char *)SvPV(*av_fetch(cbargs, i, 0),PL_na));
  }
  /* no arguments being passed currently. */
  PUTBACK;

  /* Callbacks are accomplished by passing a CV* which was assigned when 
     the callback() was set */
  n = perl_call_sv((SV*)thecb, G_DISCARD);

  SPAGAIN;
  PUTBACK;
  FREETMPS;
  LEAVE;
}

void fl_text_buffer_mcb(int pos, int nD, int nI, int nR, const char *dt, 
                        void *cb) {
  int n;
  dSP;
  ENTER;
  SAVETMPS;

  PUSHMARK(sp);

  XPUSHs(sv_2mortal(newSViv(pos)));
  XPUSHs(sv_2mortal(newSViv(nD)));
  XPUSHs(sv_2mortal(newSViv(nI)));
  XPUSHs(sv_2mortal(newSViv(nR)));
  XPUSHs(sv_2mortal(newSVpv((char *)dt,PL_na)));

  PUTBACK;

  n = perl_call_sv((SV*)cb, G_DISCARD);

  SPAGAIN;
  PUTBACK;
  FREETMPS;
  LEAVE;
}

void fl_unfinished_style_plcb() {
  printf("Unfinished style callbacks are currently disabled.\n");
}

int fl_text_editor_kbcb(int key, Fl_Text_Editor *ed, void *cb) {
  int n;
  int ret;
  dSP;
  ENTER;
  SAVETMPS;

  SV *w = sv_newmortal();
  sv_setref_pv(w, "Fl_Text_Editor", (void*)ed);

  PUSHMARK(sp);

  XPUSHs(sv_2mortal(newSViv(key)));
  XPUSHs((SV*)w);

  PUTBACK;

  n = perl_call_sv((SV*)cb, G_SCALAR);

  SPAGAIN;
  if(n == 1) {
    ret = POPi;
  }
  PUTBACK;
  FREETMPS;
  LEAVE;

  return ret;
}

Fl_Boxtype lookup_box(int t) {
  switch(t) {
    case 1:
      return FL_UP_BOX;
      break;
    case 2:
      return FL_NORMAL_BOX;
      break;
    case 3:
      return FL_DOWN_BOX;
      break;
    case 4:
      return FL_THIN_UP_BOX;
      break;
    case 5:
      return FL_THIN_BOX;
      break;
    case 6:
      return FL_THIN_DOWN_BOX;
      break;
    case 7:
      return FL_ENGRAVED_BOX;
      break;
    case 8:
      return FL_EMBOSSED_BOX;
      break;
    case 9:
      return FL_BORDER_BOX;
      break;
    case 10:
      return FL_FLAT_BOX;
      break;
    case 11:
      return FL_HIGHLIGHT_UP_BOX;
      break;
    case 12:
      return FL_FLAT_UP_BOX;
      break;
    case 13:
      return FL_HIGHLIGHT_BOX;
      break;
    case 14:
      return FL_HIGHLIGHT_DOWN_BOX;
      break;
    case 15:
      return FL_FLAT_DOWN_BOX;
      break;
    case 16:
      return FL_ROUND_UP_BOX;
      break;
    case 17:
      return FL_ROUND_BOX;
      break;
    case 18:
      return FL_DIAMOND_UP_BOX;
      break;
    case 19:
      return FL_DIAMOND_UP_BOX;
      break;
    case 20:
      return FL_DIAMOND_BOX;
      break;
    case 21:
      return FL_DIAMOND_DOWN_BOX;
      break;
    case 22:
      return FL_NO_BOX;
      break;
    case 23:
      return FL_SHADOW_BOX;
      break;
    case 24:
      return FL_ROUNDED_BOX;
      break;
    case 25:
      return FL_RSHADOW_BOX;
      break;
    case 26:
      return FL_RFLAT_BOX;
      break;
    case 27:
      return FL_OVAL_BOX;
      break;
    case 28:
      return FL_OSHADOW_BOX;
      break;
    case 29:
      return FL_OFLAT_BOX;
      break;
    case 30:
      return FL_BORDER_FRAME;
      break;
    default:
      return FL_NORMAL_BOX; 
      break;
  }
}



MODULE = FLTK		PACKAGE = FLTK		
PROTOTYPES: ENABLE

char *
widget_type(w)
  Fl_Widget *w = NO_INIT
  CODE:
    RETVAL = HvNAME(SvSTASH((SV*)SvRV(ST(0))));
  OUTPUT:
    RETVAL

void
fl_message(c)
  const char *c

void
fl_alert(c)
  const char *c

int
fl_ask(c)
  const char *c

int
fl_choice(q,b0,b1,b2)
  const char *q
  const char *b0
  const char *b1
  const char *b2

const char *
fl_input(l,d=0)
  const char *l
  const char *d

const char *
fl_password(l,d=0)
  const char *l
  const char *d

Fl_Widget *
fl_message_icon()

void
fl_color_chooser(...)
  CASE: items == 4
    INIT:
      const char *name = (const char *)SvPV(ST(0),PL_na);
      int RETVAL;
    CODE:
      if(SvTYPE(ST(1)) == SVt_NV) {
        double r = (double)SvNV(ST(1));
        double g = (double)SvNV(ST(2));
        double b = (double)SvNV(ST(3));
        RETVAL = fl_color_chooser(name, r, g, b);
        sv_setnv(ST(1),(double)r);
        SvSETMAGIC(ST(1));
        sv_setnv(ST(2),(double)g);
        SvSETMAGIC(ST(2));
        sv_setnv(ST(3),(double)b);
        SvSETMAGIC(ST(3));

        ST(0) = sv_newmortal();
        sv_setiv(ST(0),(IV)RETVAL);
        XSRETURN(1);
      } else {
        uchar R = (uchar)SvUV(ST(1));
        uchar G = (uchar)SvUV(ST(2));
        uchar B = (uchar)SvUV(ST(3));
        RETVAL = fl_color_chooser(name, R, G, B);
        sv_setuv(ST(1), (UV)R);
        SvSETMAGIC(ST(1));
        sv_setuv(ST(2), (UV)G);
        SvSETMAGIC(ST(2));
        sv_setuv(ST(3), (UV)B);
        SvSETMAGIC(ST(3));

        ST(0) = sv_newmortal();
        sv_setiv(ST(0), (IV)RETVAL);
        XSRETURN(1);
      }
  CASE: items == 2
    INIT:
      const char *n = (const char *)SvPV(ST(0),PL_na);
      Fl_Color c = (Fl_Color)SvUV(ST(1));
      int r;
    CODE:
      r = fl_color_chooser(n,c);
      sv_setuv(ST(1),(UV)r);
      SvSETMAGIC(ST(1));

      ST(0) = sv_newmortal();
      sv_setiv(ST(0), (IV)r);
      XSRETURN(1);

Fl_Color
fl_show_colormap(col)
  Fl_Color col

Fl_Color
fl_gray_ramp(i)
  int i

Fl_Color
fl_color_cube(r,g,b)
  int r
  int g
  int b

Fl_Color
fl_rgb(r,g=0,b=0)
  CASE: items == 3
    INPUT:
      unsigned char r
      unsigned char g
      unsigned char b
    CODE:
      RETVAL = fl_rgb(r,g,b);
    OUTPUT:
      RETVAL
  CASE: items == 1
    INPUT:
      const char *r
    CODE:
      RETVAL = fl_rgb(r);
    OUTPUT:
      RETVAL

Fl_Color
fl_color_average(c1,c2,w)
  Fl_Color c1
  Fl_Color c2
  double w

Fl_Color
fl_inactive(c,f=0)
  CASE: items == 2
    INPUT:
      Fl_Color c
      Fl_Flags f
    CODE:
      RETVAL = fl_inactive(c,f);
    OUTPUT:
      RETVAL
  CASE: items == 1
    INPUT:
      Fl_Color c
    CODE:
      RETVAL = fl_inactive(c);
    OUTPUT:
      RETVAL

Fl_Color
fl_contrast(fg,bg)
  Fl_Color fg
  Fl_Color bg

void
fl_color(...)
  CASE: items == 3
    INIT:
      uchar r = (uchar)SvUV(ST(0));
      uchar g = (uchar)SvUV(ST(1));
      uchar b = (uchar)SvUV(ST(2));
    CODE:
      fl_color(r,g,b);
  CASE: items == 1
    INIT:
      Fl_Color c = (Fl_Color)SvUV(ST(0));
    CODE:
      fl_color(c);
  CASE: items == 0
    INIT:
      Fl_Color RETVAL;
    CODE:
      RETVAL = fl_color();
      ST(0) = sv_newmortal();
      sv_setuv(ST(0),(UV)RETVAL);
      XSRETURN(1);

void
fl_clip(x,y,w,h)
  int x
  int y
  int w
  int h

void
fl_clip_out(x,y,w,h)
  int x
  int y
  int w
  int h

void
fl_push_no_clip()

void
fl_pop_clip()

int
fl_not_clipped(x,y,w,h)
  int x
  int y
  int w
  int h

int
fl_clip_box(a,b,c,d,x,y,w,h)
  int a
  int b
  int c
  int d
  int x
  int y
  int w
  int h
  OUTPUT:
    x
    y
    w
    h
    RETVAL

void
fl_line_style(s,w=0,d=0)
  int s
  int w
  char *d

void
fl_point(x,y)
  int x
  int y

void
fl_rect(x,y,w,h)
  int x
  int y
  int w
  int h

void
fl_rectf(x,y,w,h)
  int x
  int y
  int w
  int h

void
fl_line(x1,y1,x2,y2,x3=0,y3=0)
  CASE: items == 4
    INPUT:
      int x1
      int y1
      int x2
      int y2
    CODE:
      fl_line(x1,y1,x2,y2);
  CASE: items == 6
    INPUT:
      int x1
      int y1
      int x2
      int y2
      int x3
      int y3
    CODE:
      fl_line(x1,y1,x2,y2,x3,y3);

void
fl_loop(x1,y1,x2,y2,x3,y3,x4=0,y4=0)
  CASE: items == 6
    INPUT:
      int x1
      int y1
      int x2
      int y2
      int x3
      int y3
    CODE:
      fl_loop(x1,y1,x2,y2,x3,y3);
  CASE: items == 8
    INPUT:
      int x1
      int y1
      int x2
      int y2
      int x3
      int y3
      int x4
      int y4
    CODE:
      fl_loop(x1,y1,x2,y2,x3,y3,x4,y4);

void
fl_polygon(x1,y1,x2,y2,x3,y3,x4=0,y4=0)
  CASE: items == 6
    INPUT:
      int x1
      int y1
      int x2
      int y2
      int x3
      int y3
    CODE:
      fl_polygon(x1,y1,x2,y2,x3,y3);
  CASE: items == 8
    INPUT:
      int x1
      int y1
      int x2
      int y2
      int x3
      int y3
      int x4
      int y4
    CODE:
      fl_polygon(x1,y1,x2,y2,x3,y3,x4,y4);

void
fl_xyline(x,y,y1,x2=0,y3=0)
  CASE: items == 5
    INPUT:
      int x
      int y
      int y1
      int x2
      int y3
    CODE:
      fl_xyline(x,y,y1,x2,y3);
  CASE: items == 4
    INPUT:
      int x
      int y
      int y1
      int x2
    CODE:
      fl_xyline(x,y,y1,x2);
  CASE: items == 3
    INPUT:
      int x
      int y
      int y1
    CODE:
      fl_xyline(x,y,y1);

void
fl_yxline(x,y,y1,x2=0,y3=0)
  CASE: items == 5
    INPUT:
      int x
      int y
      int y1
      int x2
      int y3
    CODE:
      fl_yxline(x,y,y1,x2,y3);
  CASE: items == 4
    INPUT:
      int x
      int y
      int y1
      int x2
    CODE:
      fl_yxline(x,y,y1,x2);
  CASE: items == 3
    INPUT:
      int x
      int y
      int y1
    CODE:
      fl_yxline(x,y,y1);

void
fl_arc(x,y,w,h,a1,a2)
  int x
  int y
  int w
  int h
  double a1
  double a2

void
fl_pie(x,y,w,h,a1,a2)
  int x
  int y
  int w
  int h
  double a1
  double a2

void
fl_push_matrix()

void
fl_pop_matrix()

void
fl_scale(x,y=0)
  CASE: items == 2
    INPUT:
      double x
      double y
    CODE:
      fl_scale(x,y);
  CASE: items == 1
    INPUT:
      double x
    CODE:
      fl_scale(x);

void
fl_translate(x,y)
  double x
  double y

void
fl_rotate(d)
  double d

void
fl_mult_matrix(a,b,c,d,x,y)
  double a
  double b
  double c
  double d
  double x
  double y

void
fl_begin_points()

void
fl_begin_line()

void
fl_begin_loop()

void
fl_begin_polygon()

void
fl_vertex(x,y)
  double x
  double y

void
fl_curve(a,b,c,d,x,y,w,h)
  double a
  double b
  double c
  double d
  double x
  double y
  double w
  double h

void
fl_circle(x,y,r)
  double x
  double y
  double r

void
fl_end_points()

void
fl_end_line()

void
fl_end_loop()

void
fl_end_polygon()

void
fl_begin_complex_polygon()

void
fl_gap()

void
fl_end_complex_polygon()

double
fl_transform_x(x,y)
  double x
  double y

double
fl_transform_y(x,y)
  double x
  double y

double
fl_transform_dx(x,y)
  double x
  double y

double
fl_transform_dy(x,y)
  double x
  double y

void
fl_transformed_vertex(x,y)
  double x
  double y

void
fl_font(...)
  CASE: items == 3
    INIT:
      Fl_Font f = (Fl_Font)SvIV((SV*)SvRV(ST(0)));
      unsigned s = (unsigned)SvUV(ST(1));
      const char *e = (const char *)SvPV(ST(2),PL_na);
    CODE:
      fl_font(f,s,e);
  CASE: items == 2
    INIT:
      Fl_Font f = (Fl_Font)SvIV((SV*)SvRV(ST(0)));
      unsigned s = (unsigned)SvUV(ST(1));
    CODE:
      fl_font(f,s);
  CASE: items == 1
    INIT:
      const Fl_Font_ *ret;
      const char *fnt = (const char *)SvPV(ST(0),PL_na);
    CODE:
      ret = fl_font(fnt);
      ST(0) = sv_newmortal();
      sv_setref_pv(ST(0),"Fl_Font_",(void*)ret);
      XSRETURN(1);
  CASE: items == 0
    INIT:
      const Fl_Font_ *r;
    CODE:
      r = fl_font();
      ST(0) = sv_newmortal();
      sv_setref_pv(ST(0),"Fl_Font_",(void*)r);
      XSRETURN(1);

unsigned
fl_size()

int
fl_height()

int
fl_descent()

int
fl_width(c,n=0)
  CASE: items == 2
    INPUT:
      const char *c
      int n
    CODE:
      RETVAL = fl_width(c,n);
    OUTPUT:
      RETVAL
  CASE: items == 1
    INPUT:
      const char *c
    CODE:
      RETVAL = fl_width(c);
    OUTPUT:
      RETVAL

void
fl_get_color(c,r=0,g=0,b=0)
  CASE: items == 4
    INPUT:
      Fl_Color c
      uchar r
      uchar g
      uchar b
    CODE:
      fl_get_color(c,r,g,b);
  CASE: items == 1
    INPUT:
      Fl_Color c
    INIT:
      Fl_Color r;
    CODE:
      r = fl_get_color(c);
      ST(0) = sv_newmortal();
      sv_setuv(ST(0),(UV)r);
      XSRETURN(1);

void
fl_set_color(c,c2)
  Fl_Color c
  Fl_Color c2

void
fl_free_color(c)
  Fl_Color c

void
fl_background(c)
  Fl_Color c

Fl_Color
fl_nearest_color(c)
  Fl_Color c

char *
fl_file_chooser(msg,pat,name)
  const char *msg
  const char *pat
  const char *name

const Fl_Font_ *
FL_HELVETICA()
  CODE:
    RETVAL = FL_HELVETICA;
  OUTPUT:
    RETVAL

const Fl_Font_ *
FL_HELVETICA_BOLD()
  CODE:
    RETVAL = FL_HELVETICA_BOLD;
  OUTPUT:
    RETVAL

const Fl_Font_ *
FL_HELVETICA_ITALIC()
  CODE:
    RETVAL = FL_HELVETICA_ITALIC;
  OUTPUT:
    RETVAL

const Fl_Font_ *
FL_HELVETICA_BOLD_ITALIC()
  CODE:
    RETVAL = FL_HELVETICA_BOLD_ITALIC;
  OUTPUT:
    RETVAL

const Fl_Font_ *
FL_COURIER()
  CODE:
    RETVAL = FL_COURIER;
  OUTPUT:
    RETVAL

const Fl_Font_ *
FL_COURIER_BOLD()
  CODE:
    RETVAL = FL_COURIER_BOLD;
  OUTPUT:
    RETVAL

const Fl_Font_ *
FL_COURIER_ITALIC()
  CODE:
    RETVAL = FL_COURIER_ITALIC;
  OUTPUT:
    RETVAL

const Fl_Font_ *
FL_COURIER_BOLD_ITALIC()
  CODE:
    RETVAL = FL_COURIER_BOLD_ITALIC;
  OUTPUT:
    RETVAL

const Fl_Font_ *
FL_TIMES()
  CODE:
    RETVAL = FL_TIMES;
  OUTPUT:
    RETVAL

const Fl_Font_ *
FL_TIMES_BOLD()
  CODE:
    RETVAL = FL_TIMES_BOLD;
  OUTPUT:
    RETVAL

const Fl_Font_ *
FL_TIMES_ITALIC()
  CODE:
    RETVAL = FL_TIMES_ITALIC;
  OUTPUT:
    RETVAL

const Fl_Font_ *
FL_TIMES_BOLD_ITALIC()
  CODE:
    RETVAL = FL_TIMES_BOLD_ITALIC;
  OUTPUT:
    RETVAL

const Fl_Font_ *
FL_SYMBOL()
  CODE:
    RETVAL = FL_SYMBOL;
  OUTPUT:
    RETVAL

const Fl_Font_ *
FL_SCREEN()
  CODE:
    RETVAL = FL_SCREEN;
  OUTPUT:
    RETVAL

const Fl_Font_ *
FL_SCREEN_BOLD()
  CODE:
    RETVAL = FL_SCREEN_BOLD;
  OUTPUT:
    RETVAL

const Fl_Font_ *
FL_ZAPF_DINGBATS()
  CODE:
    RETVAL = FL_ZAPF_DINGBATS;
  OUTPUT:
    RETVAL

void
run()
  CODE:
    Fl::run();

INCLUDE: Fl_Macros.xs
INCLUDE: Fl.xs
INCLUDE: Fl_Boxtype.xs
INCLUDE: Fl_Labeltype.xs
INCLUDE: Fl_Style.xs
INCLUDE: Fl_Widget.xs
INCLUDE: Fl_Group.xs
INCLUDE: Fl_List.xs
INCLUDE: Fl_Window.xs
INCLUDE: Fl_Image.xs
INCLUDE: Fl_Pixmap.xs
INCLUDE: Fl_Box.xs
INCLUDE: Fl_Button.xs
INCLUDE: Fl_Check_Button.xs
INCLUDE: Fl_Input.xs
INCLUDE: Fl_Input_Children.xs
INCLUDE: Fl_Tabs.xs
INCLUDE: Fl_Tile.xs
INCLUDE: Fl_Pack.xs
INCLUDE: Fl_Scroll.xs
INCLUDE: Fl_Menu_.xs
INCLUDE: Fl_Menus.xs
INCLUDE: Fl_Item.xs
INCLUDE: Fl_Browser.xs
INCLUDE: Fl_Browsers.xs
INCLUDE: Fl_Align_Group.xs
INCLUDE: Fl_Shared_Image.xs
INCLUDE: Fl_Valuator.xs
INCLUDE: Fl_Slider.xs
INCLUDE: Fl_Sliders.xs
INCLUDE: Fl_Tooltip.xs
INCLUDE: Fl_Double_Window.xs
INCLUDE: Fl_Text_Buffer.xs
INCLUDE: Fl_Text_Display.xs
INCLUDE: Fl_Text_Editor.xs
