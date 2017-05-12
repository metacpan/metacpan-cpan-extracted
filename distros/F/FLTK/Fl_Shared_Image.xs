
MODULE = FLTK   PACKAGE = Fl_Shared_Image

Fl_Shared_Image *
Fl_Shared_Image::new(t,f)
  int t
  const char *f
  CODE:
    switch(t) {
      case FL_IMAGE_PNG:
        //RETVAL = Fl_PNG_Image::get(f);
        croak("Fl_Shared_Image::new(): JPEG support is not implemented yet.");
        break;
      case FL_IMAGE_XPM:
        RETVAL = Fl_XPM_Image::get(f);
        break;
      case FL_IMAGE_GIF:
        RETVAL = Fl_GIF_Image::get(f);
        break;
      case FL_IMAGE_JPEG:
        //RETVAL = Fl_JPEG_Image::get(f);
        croak("Fl_Shared_Image::new(): JPEG support is not implemented yet.");
        break;
      case FL_IMAGE_BMP:
        RETVAL = Fl_BMP_Image::get(f);
        break;
      default:
        croak("Unspecified image type in call to Fl_Shared_Image::new");
        break;
    }
  OUTPUT:
    RETVAL

