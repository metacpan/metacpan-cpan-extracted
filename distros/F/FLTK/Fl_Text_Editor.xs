
MODULE = FLTK     PACKAGE = Fl_Text_Editor

Fl_Text_Editor *
Fl_Text_Editor::new(x,y,w,h,l=0)
  int x
  int y
  int w
  int h
  const char *l

int
Fl_Text_Editor::handle(i)
  int i

void
Fl_Text_Editor::insert_mode(b=0)
  CASE: items == 2
    INPUT:
      int b
    CODE:
      THIS->insert_mode(b);
  CASE: items == 1
    INIT: 
      int r;
    CODE:
      r = THIS->insert_mode();
      ST(0) = sv_newmortal();
      sv_setiv(ST(0),(IV)r);
      XSRETURN(1);

void
Fl_Text_Editor::add_key_binding(...)
  CODE:
    int k = (int)SvIV(ST(1));
    int s = (int)SvIV(ST(2));
    if(SvTYPE(SvRV((SV*)ST(3))) != SVt_PVCV) {
      croak("Fl_Text_Editor::add_key_binding() requires a function reference.");
    }
    THIS->add_key_binding(k, s, fl_text_editor_kbcb, (void*)SvRV((SV*)ST(3)));

void
Fl_Text_Editor::remove_key_binding(k,s)
  int k
  int s

void
Fl_Text_Editor::remove_all_key_bindings()

int
Fl_Text_Editor::kf_default(c,e)
  int c
  Fl_Text_Editor *e

int
Fl_Text_Editor::kf_ignore(c,e)
  int c
  Fl_Text_Editor *e

int
Fl_Text_Editor::kf_backspace(c,e)
  int c
  Fl_Text_Editor *e

int
Fl_Text_Editor::kf_enter(c,e)
  int c
  Fl_Text_Editor *e

int
Fl_Text_Editor::kf_move(c,e)
  int c
  Fl_Text_Editor *e

int
Fl_Text_Editor::kf_shift_move(c,e)
  int c
  Fl_Text_Editor *e

int
Fl_Text_Editor::kf_ctrl_move(c,e)
  int c
  Fl_Text_Editor *e

int
Fl_Text_Editor::kf_c_s_move(c,e)
  int c
  Fl_Text_Editor *e

int
Fl_Text_Editor::kf_home(c,e)
  int c
  Fl_Text_Editor *e

int
Fl_Text_Editor::kf_end(c,e)
  int c
  Fl_Text_Editor *e

int
Fl_Text_Editor::kf_left(c,e)
  int c
  Fl_Text_Editor *e

int
Fl_Text_Editor::kf_up(c,e)
  int c
  Fl_Text_Editor *e

int
Fl_Text_Editor::kf_right(c,e)
  int c
  Fl_Text_Editor *e

int
Fl_Text_Editor::kf_down(c,e)
  int c
  Fl_Text_Editor *e

int
Fl_Text_Editor::kf_page_up(c,e)
  int c
  Fl_Text_Editor *e

int
Fl_Text_Editor::kf_page_down(c,e)
  int c
  Fl_Text_Editor *e

int
Fl_Text_Editor::kf_insert(c,e)
  int c
  Fl_Text_Editor *e

int
Fl_Text_Editor::kf_delete(c,e)
  int c
  Fl_Text_Editor *e

int
Fl_Text_Editor::kf_copy(c,e)
  int c
  Fl_Text_Editor *e

int
Fl_Text_Editor::kf_cut(c,e)
  int c
  Fl_Text_Editor *e

int
Fl_Text_Editor::kf_paste(c,e)
  int c
  Fl_Text_Editor *e

int
Fl_Text_Editor::kf_select_all(c,e)
  int c
  Fl_Text_Editor *e


