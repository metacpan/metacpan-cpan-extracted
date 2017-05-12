
MODULE = FLTK   PACKAGE = Fl_Item

Fl_Item *
Fl_Item::new(l=0)
  const char *l
  CODE:
    RETVAL = new Fl_Item();
    RETVAL->copy_label(l);
  OUTPUT:
    RETVAL

void
Fl_Item::draw()

void
Fl_Item::layout()

MODULE = FLTK   PACKAGE = Fl_Radio_Item

Fl_Radio_Item *
Fl_Radio_Item::new(l=0)
  const char *l

MODULE = FLTK   PACKAGE = Fl_Toggle_Item

Fl_Toggle_Item *
Fl_Toggle_Item::new(l=0)
  const char *l
