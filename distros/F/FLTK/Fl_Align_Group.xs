
MODULE = FLTK   PACKAGE = Fl_Align_Group

Fl_Align_Group *
Fl_Align_Group::new(x,y,w,h,l)
  int x
  int y
  int w
  int h
  const char *l

void
Fl_Align_Group::layout()

void
Fl_Align_Group::vertical(...)
  CASE: items == 2
    INIT:
      bool v = (bool)SvIV(ST(1));
    CODE:
      THIS->vertical(v);
  CASE: items == 1
    INIT:
      bool r;
    CODE:
      r = THIS->vertical();
      ST(0) = sv_newmortal();
      sv_setiv(ST(0),(IV)r);
      XSRETURN(1);

void
Fl_Align_Group::n_to_break(n=0)
  CASE: items == 2
    INPUT:
      uchar n
    CODE:
      THIS->n_to_break(n);
  CASE: items == 1
    INIT:
      uchar r;
    CODE:
      r = THIS->n_to_break();
      ST(0) = sv_newmortal();
      sv_setuv(ST(0),(UV)r);
      XSRETURN(1);

void
Fl_Align_Group::dw(n=0)
  CASE: items == 2
    INPUT:
      uchar n
    CODE:
      THIS->dw(n);
  CASE: items == 1
    INIT:
      uchar r;
    CODE:
      r = THIS->dw();
      ST(0) = sv_newmortal();
      sv_setuv(ST(0),(UV)r);
      XSRETURN(1);

void
Fl_Align_Group::dh(n=0)
  CASE: items == 2
    INPUT:
      uchar n
    CODE:
      THIS->dh(n);
  CASE: items == 1
    INIT:
      uchar r;
    CODE:
      r = THIS->dh();
      ST(0) = sv_newmortal();
      sv_setuv(ST(0),(UV)r);
      XSRETURN(1);

void
Fl_Align_Group::align(a=0)
  CASE: items == 2
    INPUT:
      Fl_Align a
    CODE:
      THIS->align(a);
  CASE: items == 1
    INIT:
      int r;
    CODE:
      r = THIS->align();
      ST(0) = sv_newmortal();
      sv_setiv(ST(0),(IV)r);
      XSRETURN(1);

