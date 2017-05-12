
MODULE = FLTK   PACKAGE = Fl_Labeltype_

Fl_Labeltype_ *
Fl_Labeltype_::new(n)
  const char *n

Fl_Labeltype_ *
Fl_Labeltype_::find(name)
  const char *name
  CODE:
    RETVAL = (Fl_Labeltype_ *)THIS->find(name);
  OUTPUT:
    RETVAL


