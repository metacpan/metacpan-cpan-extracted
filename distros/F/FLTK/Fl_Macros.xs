
MODULE = FLTK   PACKAGE = FLTK

Fl_Labeltype
FL_NORMAL_LABEL()
  CODE:
    RETVAL = (Fl_Labeltype)safemalloc(sizeof(Fl_Labeltype));
    RETVAL = FL_NORMAL_LABEL;
  OUTPUT:
    RETVAL

Fl_Labeltype
FL_NO_LABEL()
  CODE:
    RETVAL = (Fl_Labeltype)safemalloc(sizeof(Fl_Labeltype));
    RETVAL = FL_NO_LABEL;
  OUTPUT:
    RETVAL

Fl_Labeltype
FL_SYMBOL_LABEL()
  CODE:
    RETVAL = (Fl_Labeltype)safemalloc(sizeof(Fl_Labeltype));
    RETVAL = FL_SYMBOL_LABEL;
  OUTPUT:
    RETVAL

Fl_Labeltype
FL_SHADOW_LABEL()
  CODE:
    RETVAL = (Fl_Labeltype)safemalloc(sizeof(Fl_Labeltype));
    RETVAL = FL_SHADOW_LABEL;
  OUTPUT:
    RETVAL

Fl_Labeltype
FL_ENGRAVED_LABEL()
  CODE:
    RETVAL = (Fl_Labeltype)safemalloc(sizeof(Fl_Labeltype));
    RETVAL = FL_ENGRAVED_LABEL;
  OUTPUT:
    RETVAL

Fl_Labeltype
FL_EMBOSSED_LABEL()
  CODE:
    RETVAL = (Fl_Labeltype)safemalloc(sizeof(Fl_Labeltype));
    RETVAL = FL_EMBOSSED_LABEL;
  OUTPUT:
    RETVAL


