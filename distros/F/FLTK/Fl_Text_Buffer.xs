
MODULE = FLTK	PACKAGE = Fl_Text_Buffer

Fl_Text_Buffer *
Fl_Text_Buffer::new(rs=0)
  int rs

int
Fl_Text_Buffer::length()

void
Fl_Text_Buffer::text(t=0)
  CASE: items == 2
    INPUT:
      const char *t
    CODE:
      THIS->text(t);
  CASE: items == 1
    INIT:
      const char *r;
    CODE:
      r = THIS->text();
      ST(0) = sv_newmortal();
      sv_setpv(ST(0), (char *)r);
      XSRETURN(1);

const char *
Fl_Text_Buffer::text_range(s,e)
  int s
  int e

char
Fl_Text_Buffer::character(i)
  int i

const char *
Fl_Text_Buffer::text_in_rectangle(s,e,rs,re)
  int s
  int e
  int rs
  int re

void
Fl_Text_Buffer::insert(p,t)
  int p
  const char *t

void
Fl_Text_Buffer::append(t)
  const char *t

void
Fl_Text_Buffer::remove(s,e)
  int s
  int e

void 
Fl_Text_Buffer::replace(s,e,t)
  int s
  int e
  const char *t

void
Fl_Text_Buffer::copy(fb,fs,fe,tp)
  Fl_Text_Buffer *fb
  int fs
  int fe
  int tp

void
Fl_Text_Buffer::insert_column(c,sp,t,ci,cd)
  int c
  int sp
  const char *t
  int ci
  int cd
  CODE:
    THIS->insert_column(c,sp,t, &ci, &cd);
  OUTPUT:
    ci
    cd

void
Fl_Text_Buffer::replace_rectangular(s,e,rs,re,t)
  int s
  int e
  int rs
  int re
  const char *t

void
Fl_Text_Buffer::overlay_rectangular(s,rs,re,t,ci,cd)
  int s
  int rs
  int re
  const char *t
  int ci
  int cd
  CODE:
    THIS->overlay_rectangular(s,rs,re,t,&ci,&cd);
  OUTPUT:
    ci
    cd

void
Fl_Text_Buffer::remove_rectangular(s,e,rs,re)
  int s
  int e
  int rs
  int re

void
Fl_Text_Buffer::clear_rectangular(s,e,rs,re)
  int s
  int e
  int rs
  int re

void
Fl_Text_Buffer::tab_distance(t=0)
  CASE: items == 2
    INPUT:
      int t
    CODE:
      THIS->tab_distance(t);
  CASE: items == 1
    INIT:
      int r;
    CODE:
      r = THIS->tab_distance();
      ST(0) = sv_newmortal();
      sv_setiv(ST(0),(IV)r);
      XSRETURN(1);

void
Fl_Text_Buffer::select(s,e)
  int s
  int e

void
Fl_Text_Buffer::unselect()

void
Fl_Text_Buffer::select_rectangular(s,e,rs,re)
  int s
  int e
  int rs
  int re

int
Fl_Text_Buffer::selection_position(s,e,r=0,rs=0,re=0)
  CASE: items == 6
    INPUT:
      int s
      int e
      int r
      int rs
      int re
    CODE:
      RETVAL = THIS->selection_position(&s,&e,&r,&rs,&re);
    OUTPUT:
      s
      e
      r
      rs
      re
      RETVAL
  CASE: items == 3
    INPUT:
      int s
      int e
    CODE:
      RETVAL = THIS->selection_position(&s,&e);
    OUTPUT:
      s
      e
      RETVAL

const char *
Fl_Text_Buffer::selection_text()

void
Fl_Text_Buffer::remove_selection()

void
Fl_Text_Buffer::replace_selection(t)
  const char *t

void
Fl_Text_Buffer::secondary_select(s,e)
  int s
  int e

void
Fl_Text_Buffer::secondary_unselect()

void
Fl_Text_Buffer::secondary_select_rectangular(s,e,rs,re)
  int s
  int e
  int rs
  int re

int
Fl_Text_Buffer::secondary_selection_position(s,e,r,rs,re)
  int s
  int e
  int r
  int rs
  int re
  CODE:
    RETVAL = THIS->secondary_selection_position(&s,&e,&r,&rs,&re);
  OUTPUT:
    s
    e
    r
    rs
    re
    RETVAL

const char *
Fl_Text_Buffer::secondary_selection_text()

void
Fl_Text_Buffer::remove_secondary_selection()

void
Fl_Text_Buffer::replace_secondary_selection(t)
  const char *t

void
Fl_Text_Buffer::highlight(s,e)
  int s
  int e

void
Fl_Text_Buffer::unhighlight()

void
Fl_Text_Buffer::highlight_rectangular(s,e,rs,re)
  int s
  int e
  int rs
  int re

int
Fl_Text_Buffer::highlight_position(s,e,r,rs,re)
  int s
  int e
  int r
  int rs
  int re
  CODE:
    RETVAL = THIS->highlight_position(&s,&e,&r,&rs,&re);
  OUTPUT:
    s
    e
    r
    rs
    re
    RETVAL

const char *
Fl_Text_Buffer::highlight_text()

void
Fl_Text_Buffer::add_modify_callback(sb)
  CV *sb = NO_INIT
  CODE:
    if(SvTYPE(SvRV((SV*)ST(1))) != SVt_PVCV) {
      croak("Fl_Text_Buffer::add_modify_callback() requires a function reference.");
    }
    THIS->add_modify_callback(fl_text_buffer_mcb,(void*)SvRV((SV*)ST(1)));

void
Fl_Text_Buffer::remove_modify_callback(sb)
  CV *sb = NO_INIT
  CODE:
    if(SvTYPE(SvRV((SV*)ST(1))) != SVt_PVCV) {
      croak("Fl_Text_Buffer::remove_modify_callback() requires a function reference.");
    }
    THIS->remove_modify_callback(fl_text_buffer_mcb,(void*)SvRV((SV*)ST(1)));

void
Fl_Text_Buffer::call_modify_callbacks()

const char *
Fl_Text_Buffer::line_text(p)
  int p

int
Fl_Text_Buffer::line_start(p)
  int p

int
Fl_Text_Buffer::line_end(p)
  int p

int
Fl_Text_Buffer::word_start(p)
  int p

int
Fl_Text_Buffer::word_end(p)
  int p

int
Fl_Text_Buffer::expand_character(c,i,o,t,n)
  char c
  int i
  char *o
  int t
  char n

int
Fl_Text_Buffer::character_width(c,i,t,n)
  char c
  int i
  int t
  char n

int
Fl_Text_Buffer::count_displayed_characters(l,t)
  int l
  int t

int
Fl_Text_Buffer::skip_displayed_characters(l,n)
  int l
  int n

int
Fl_Text_Buffer::count_lines(s,e)
  int s
  int e

int
Fl_Text_Buffer::skip_lines(s,n)
  int s
  int n

int
Fl_Text_Buffer::rewind_lines(s,n)
  int s
  int n

int
Fl_Text_Buffer::findchar_forward(s,c,f)
  int s
  char c
  int f
  CODE:
    RETVAL = THIS->findchar_forward(s,c,&f);
  OUTPUT:
    f
    RETVAL

int
Fl_Text_Buffer::findchar_backward(s,c,f)
  int s
  char c
  int f
  CODE:
    RETVAL = THIS->findchar_backward(s,c,&f);
  OUTPUT:
    f
    RETVAL

int
Fl_Text_Buffer::findchars_forward(s,c,f)
  int s
  const char *c
  int f
  CODE:
    RETVAL = THIS->findchars_forward(s,c,&f);
  OUTPUT:
    f
    RETVAL

int
Fl_Text_Buffer::findchars_backward(s,c,f)
  int s
  const char *c
  int f
  CODE:
    RETVAL = THIS->findchars_backward(s,c,&f);
  OUTPUT:
    f
    RETVAL

int
Fl_Text_Buffer::search_forward(s,st,f,m=0)
  int s
  const char *st
  int f
  int m
  CODE:
    RETVAL = THIS->search_forward(s,st,&f,m);
  OUTPUT:
    f
    RETVAL

int
Fl_Text_Buffer::search_backward(s,st,f,m=0)
  int s
  const char *st
  int f
  int m
  CODE:
    RETVAL = THIS->search_backward(s,st,&f,m);
  OUTPUT:
    f
    RETVAL

int
Fl_Text_Buffer::substitute_null_characters(s,l)
  char *s
  int l

void
Fl_Text_Buffer::unsubstitute_null_characters(s)
  char *s

Fl_Text_Selection *
Fl_Text_Buffer::primary_selection()

Fl_Text_Selection *
Fl_Text_Buffer::secondary_selection()

Fl_Text_Selection *
Fl_Text_Buffer::highlight_selection()

MODULE = FLTK   PACKAGE = Fl_Text_Selection

Fl_Text_Selection *
Fl_Text_Selection::new()

void
Fl_Text_Selection::set(s,e)
  int s
  int e

void
Fl_Text_Selection::set_rectangular(s,e,rs,re)
  int s
  int e
  int rs
  int re

void
Fl_Text_Selection::update(p,nd,ni)
  int p
  int nd
  int ni

char
Fl_Text_Selection::rectangular()

int
Fl_Text_Selection::start()

int
Fl_Text_Selection::end()

int
Fl_Text_Selection::rect_start()

int
Fl_Text_Selection::rect_end()

void
Fl_Text_Selection::selected(b=0)
  CASE: items == 2
    INPUT:
      char b
    CODE:
      THIS->selected(b);
  CASE: items == 1
    INIT:
      char r;
    CODE:
      r = THIS->selected();
      ST(0) = sv_newmortal();
      sv_setpvn(ST(0), (char *)&r,1);
      XSRETURN(1);

int
Fl_Text_Selection::includes(p,l,d)
  int p
  int l
  int d

int
Fl_Text_Selection::position(s,e,r=0,rs=0,re=0)
  CASE: items == 6
    INPUT:
      int s
      int e
      int r
      int rs
      int re
    CODE:
      RETVAL = THIS->position(&s, &e, &r, &rs, &re);
    OUTPUT:
      s
      e
      r
      rs
      re
      RETVAL
  CASE: items == 3
    INPUT:
      int s
      int e
    CODE:
      RETVAL = THIS->position(&s, &e);
    OUTPUT:
      s
      e
      RETVAL

