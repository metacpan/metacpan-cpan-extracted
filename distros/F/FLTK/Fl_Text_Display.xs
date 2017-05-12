
MODULE = FLTK     PACKAGE = Fl_Text_Display

Fl_Text_Display *
Fl_Text_Display::new(x,y,w,h,l=0)
  int x
  int y
  int w
  int h
  const char *l

int
Fl_Text_Display::handle(i)
  int i

void
Fl_Text_Display::buffer(b=0)
  CASE: items == 2
    INPUT:
      Fl_Text_Buffer *b
    CODE:
      THIS->buffer(b);
  CASE: items == 1
    INIT:
      Fl_Text_Buffer *r;
    CODE:
      r = THIS->buffer();
      ST(0) = sv_newmortal();
      sv_setref_pv(ST(0), "Fl_Text_Buffer", (void*)r);
      XSRETURN(1); 

void
Fl_Text_Display::redisplay_range(s,e)
  int s
  int e

void
Fl_Text_Display::scroll(t,h)
  int t
  int h

void
Fl_Text_Display::insert(t)
  const char *t

void
Fl_Text_Display::insert_position(i=0)
  CASE: items == 2
    INPUT:
      int i
    CODE:
      THIS->insert_position(i);
  CASE: items == 1
    INIT:
      int r;
    CODE:
      r = THIS->insert_position();
      ST(0) = sv_newmortal();
      sv_setiv(ST(0),(IV)r);
      XSRETURN(1); 

int
Fl_Text_Display::in_selection(x,y)
  int x
  int y

void
Fl_Text_Display::show_insert_position()

int
Fl_Text_Display::move_right()

int
Fl_Text_Display::move_left()

int
Fl_Text_Display::move_up()

int
Fl_Text_Display::move_down()

void
Fl_Text_Display::next_word()

void
Fl_Text_Display::previous_word()

void
Fl_Text_Display::show_cursor(b=1)
  int b

void
Fl_Text_Display::hide_cursor()

void
Fl_Text_Display::cursor_style(s)
  int s

void
Fl_Text_Display::scrollbar_width(w=0)
  CASE: items == 2
    INPUT:
      int w
    CODE:
      THIS->scrollbar_width(w);
  CASE: items == 1
    INIT:
      int r;
    CODE:
      r = THIS->scrollbar_width();
      ST(0) = sv_newmortal(); 
      sv_setiv(ST(0),(IV)r);
      XSRETURN(1);

void
Fl_Text_Display::scrollbar_align(a=0)
  CASE: items == 2
    INPUT:
      Fl_Flags a
    CODE:
      THIS->scrollbar_align(a);
  CASE: items == 1
    INIT:
      int r;
    CODE:
      r = THIS->scrollbar_align();
      ST(0) = sv_newmortal(); 
      sv_setiv(ST(0),(IV)r);
      XSRETURN(1);

int
Fl_Text_Display::word_start(p)
  int p

int
Fl_Text_Display::word_end(p)
  int p

void
Fl_Text_Display::highlight_data(...)
  INIT:
    Fl_Text_Buffer *buf = (Fl_Text_Buffer*)SvIV(SvRV((SV*)ST(1)));
//    Fl_Text_Display::Style_Table_Entry *table;
    int nstyles;
    char uf = (char)*SvPV(ST(3), PL_na);
  CODE:
    if(has_stylet) {
      croak("Only one style table is currently allowed.");
    }
    if(SvTYPE(SvRV((SV*)ST(2))) != SVt_PVAV) {
      croak("Fl_Text_Display::highlight_data() needs an array reference.");
    }
    if(SvTYPE(SvRV((SV*)ST(4))) != SVt_PVCV) {
      croak("Fl_Text_Display::highlight_data() needs a function reference.");
    }
    AV *tarr = (AV*)SvRV((SV*)ST(2));
    AV *item;
    nstyles = av_len(tarr) + 1;
//    table = (Fl_Text_Display::Style_Table_Entry *)malloc(nstyles * sizeof(Fl_Text_Display::Style_Table_Entry *));
    int cnt = 0;
    if(nstyles > 256) { nstyles = 256;}
    while(cnt < nstyles) {
      if(SvTYPE(SvRV((SV*)*av_fetch(tarr, cnt, 0))) != SVt_PVAV) {
        croak("Fl_Text_Display::highlight_data() style table element %d is not an array reference.", cnt);
      }
      item = (AV*)SvRV((SV*)*av_fetch(tarr, cnt, 0));
      table[cnt].color = (Fl_Color)SvUV((SV*)*av_fetch(item, 0, 0));
      if(SvTYPE(SvRV((SV*)*av_fetch(item, 1, 0))) != SVt_PVMG) {
        croak("Fl_Text_Display::highlight_data() font entry in element %d of style table is not an Fl_Font_ object.", cnt);
      }
      table[cnt].font = (Fl_Font)SvIV(SvRV((SV*)*av_fetch(item, 1, 0)));
      table[cnt].size = (int)SvIV((SV*)*av_fetch(item, 2, 0));
      cnt++;
    }
    has_stylet++;
    THIS->highlight_data(buf, table, nstyles, uf, fl_unfinished_style_plcb,
                         (void*)SvRV((SV*)ST(4)));
    
int
Fl_Text_Display::position_style(ls,ll,li,di)
  int ls
  int ll
  int li
  int di

