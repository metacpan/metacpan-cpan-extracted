
MODULE = FLTK   PACKAGE = Fl_Style

Fl_Style *
Fl_Style::new()

void
Fl_Style::revert()

int
Fl_Style::dynamic()

void
Fl_Style::start(n)
  const char *n

MODULE = FLTK   PACKAGE = Fl_Font_

Fl_Font_ *
Fl_Font_::new()

const char *
Fl_Font_::system_name()

const char *
Fl_Font_::name(i=0)
  int i
  CODE:
    RETVAL = THIS->name(&i);
  OUTPUT:
    i
    RETVAL

Fl_Font_ *
Fl_Font_::bold()

Fl_Font_ *
Fl_Font_::italic()

