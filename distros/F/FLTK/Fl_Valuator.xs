
MODULE = FLTK   PACKAGE = Fl_Valuator

void
Fl_Valuator::value(v=0)
  CASE: items == 2
    INPUT:
      double v
    INIT:
      int r;
    CODE:
      r = THIS->value(v);
      ST(0) = sv_newmortal();
      sv_setiv(ST(0),(IV)r);
      XSRETURN(1);
  CASE: items == 1
    INIT:
      double ret;
    CODE:
      ret = THIS->value();
      ST(0) = sv_newmortal();
      sv_setnv(ST(0), (double)ret);
      XSRETURN(1);

void
Fl_Valuator::step(v=0)
  CASE: items == 2
    INPUT:
      double v
    CODE:
      THIS->step(v);
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      double ret;
    CODE:
      ret = THIS->step();
      ST(0) = sv_newmortal();
      sv_setnv(ST(0), (double)ret);
      XSRETURN(1);

void
Fl_Valuator::minimum(v=0)
  CASE: items == 2
    INPUT:
      double v
    CODE:
      THIS->minimum(v);
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      double ret;
    CODE: 
      ret = THIS->minimum();
      ST(0) = sv_newmortal();
      sv_setnv(ST(0), (double)ret);
      XSRETURN(1);

void
Fl_Valuator::maximum(v=0)
  CASE: items == 2
    INPUT:
      double v
    CODE:
      THIS->maximum(v);
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      double ret;
    CODE: 
      ret = THIS->maximum();
      ST(0) = sv_newmortal();
      sv_setnv(ST(0), (double)ret);
      XSRETURN(1);

void
Fl_Valuator::range(a,b)
  double a
  double b

void
Fl_Valuator::linesize(i=0)
  CASE: items == 2
    INPUT:
      int i
    CODE:
      THIS->linesize(i);
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      int r;
    CODE:
      r = THIS->linesize();
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), (IV)r);
      XSRETURN(1);

void
Fl_Valuator::pagesize(i=0)
  CASE: items == 2
    INPUT:
      int i
    CODE:
      THIS->pagesize(i);
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      int r;
    CODE:
      r = THIS->pagesize();
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), (IV)r);
      XSRETURN(1);

int
Fl_Valuator::format(c)
  char *c

int
Fl_Valuator::handle(i)
  int i

double
Fl_Valuator::increment(v,s)
  double v
  int s

double
Fl_Valuator::clamp(d)
  double d

double
Fl_Valuator::round(d)
  double d

double
Fl_Valuator::softclamp(d)
  double d

