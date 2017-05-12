
MODULE = FLTK   PACKAGE = Fl_Pixmap

Fl_Pixmap *
Fl_Pixmap::new(d)
    char **d = NO_INIT;
  CODE:
    if(!SvROK(ST(1))) {
      croak("Not a reference: Fl_Pixmap::new(data): must be an array ref");
    }
    if(SvTYPE(SvRV(ST(1))) != SVt_PVAV) {
      croak("Not an array ref: Fl_Pixmap::new(data): must be an array ref");
    }
    AV *tmpav = (AV*)SvRV(ST(1));
    I32 alen = av_len(tmpav);
    d =(char **)malloc((alen+2)*sizeof(char*));
    int ti;
    SV **tmpsv;
    for(ti = 0; ti <= alen; ti++) {
      tmpsv = av_fetch(tmpav, ti, 0);
      d[ti] = (char *)SvPV(*tmpsv,PL_na);
    }
    d[ti] = 0;
    SvREFCNT_inc(ST(1));
    RETVAL = new Fl_Pixmap(d);
  OUTPUT:
    RETVAL

void
Fl_Pixmap::measure(X,Y)
  int X
  int Y
  OUTPUT:
    X
    Y

void
Fl_Pixmap::draw(x,y,w=1000,h=1000,cx=0,cy=0)
  int x
  int y
  int w
  int h
  int cx
  int cy

