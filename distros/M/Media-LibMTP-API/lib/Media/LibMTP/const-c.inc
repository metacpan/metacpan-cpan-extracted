#define PERL_constant_NOTFOUND	1
#define PERL_constant_NOTDEF	2
#define PERL_constant_ISIV	3
#define PERL_constant_ISNO	4
#define PERL_constant_ISNV	5
#define PERL_constant_ISPV	6
#define PERL_constant_ISPVN	7
#define PERL_constant_ISSV	8
#define PERL_constant_ISUNDEF	9
#define PERL_constant_ISUV	10
#define PERL_constant_ISYES	11

#ifndef NVTYPE
typedef double NV; /* 5.6 and later define NVTYPE, and typedef NV to it.  */
#endif
#ifndef aTHX_
#define aTHX_ /* 5.6 or later define this for threading support.  */
#endif
#ifndef pTHX_
#define pTHX_ /* 5.6 or later define this for threading support.  */
#endif

static int
constant_16 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LIBMTP_DEBUG_ALL LIBMTP_DEBUG_PTP LIBMTP_DEBUG_USB */
  /* Offset 14 gives the best switch position.  */
  switch (name[14]) {
  case 'L':
    if (memEQ(name, "LIBMTP_DEBUG_ALL", 16)) {
    /*                             ^        */
#ifdef LIBMTP_DEBUG_ALL
      *iv_return = LIBMTP_DEBUG_ALL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "LIBMTP_DEBUG_USB", 16)) {
    /*                             ^        */
#ifdef LIBMTP_DEBUG_USB
      *iv_return = LIBMTP_DEBUG_USB;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "LIBMTP_DEBUG_PTP", 16)) {
    /*                             ^        */
#ifdef LIBMTP_DEBUG_PTP
      *iv_return = LIBMTP_DEBUG_PTP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_17 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LIBMTP_DEBUG_DATA LIBMTP_DEBUG_NONE LIBMTP_DEBUG_PLST LIBMTP_ERROR_NONE */
  /* Offset 15 gives the best switch position.  */
  switch (name[15]) {
  case 'N':
    if (memEQ(name, "LIBMTP_DEBUG_NONE", 17)) {
    /*                              ^        */
#ifdef LIBMTP_DEBUG_NONE
      *iv_return = LIBMTP_DEBUG_NONE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "LIBMTP_ERROR_NONE", 17)) {
    /*                              ^        */
      *iv_return = LIBMTP_ERROR_NONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "LIBMTP_DEBUG_PLST", 17)) {
    /*                              ^        */
#ifdef LIBMTP_DEBUG_PLST
      *iv_return = LIBMTP_DEBUG_PLST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "LIBMTP_DEBUG_DATA", 17)) {
    /*                              ^        */
#ifdef LIBMTP_DEBUG_DATA
      *iv_return = LIBMTP_DEBUG_DATA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_19 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LIBMTP_FILETYPE_AAC LIBMTP_FILETYPE_ASF LIBMTP_FILETYPE_AVI
     LIBMTP_FILETYPE_BMP LIBMTP_FILETYPE_DOC LIBMTP_FILETYPE_GIF
     LIBMTP_FILETYPE_JP2 LIBMTP_FILETYPE_JPX LIBMTP_FILETYPE_M4A
     LIBMTP_FILETYPE_MHT LIBMTP_FILETYPE_MP2 LIBMTP_FILETYPE_MP3
     LIBMTP_FILETYPE_MP4 LIBMTP_FILETYPE_OGG LIBMTP_FILETYPE_PNG
     LIBMTP_FILETYPE_PPT LIBMTP_FILETYPE_WAV LIBMTP_FILETYPE_WMA
     LIBMTP_FILETYPE_WMV LIBMTP_FILETYPE_XLS LIBMTP_FILETYPE_XML */
  /* Offset 18 gives the best switch position.  */
  switch (name[18]) {
  case '2':
    if (memEQ(name, "LIBMTP_FILETYPE_JP", 18)) {
    /*                                 2      */
      *iv_return = LIBMTP_FILETYPE_JP2;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LIBMTP_FILETYPE_MP", 18)) {
    /*                                 2      */
      *iv_return = LIBMTP_FILETYPE_MP2;
      return PERL_constant_ISIV;
    }
    break;
  case '3':
    if (memEQ(name, "LIBMTP_FILETYPE_MP", 18)) {
    /*                                 3      */
      *iv_return = LIBMTP_FILETYPE_MP3;
      return PERL_constant_ISIV;
    }
    break;
  case '4':
    if (memEQ(name, "LIBMTP_FILETYPE_MP", 18)) {
    /*                                 4      */
      *iv_return = LIBMTP_FILETYPE_MP4;
      return PERL_constant_ISIV;
    }
    break;
  case 'A':
    if (memEQ(name, "LIBMTP_FILETYPE_M4", 18)) {
    /*                                 A      */
      *iv_return = LIBMTP_FILETYPE_M4A;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LIBMTP_FILETYPE_WM", 18)) {
    /*                                 A      */
      *iv_return = LIBMTP_FILETYPE_WMA;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "LIBMTP_FILETYPE_AA", 18)) {
    /*                                 C      */
      *iv_return = LIBMTP_FILETYPE_AAC;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LIBMTP_FILETYPE_DO", 18)) {
    /*                                 C      */
      *iv_return = LIBMTP_FILETYPE_DOC;
      return PERL_constant_ISIV;
    }
    break;
  case 'F':
    if (memEQ(name, "LIBMTP_FILETYPE_AS", 18)) {
    /*                                 F      */
      *iv_return = LIBMTP_FILETYPE_ASF;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LIBMTP_FILETYPE_GI", 18)) {
    /*                                 F      */
      *iv_return = LIBMTP_FILETYPE_GIF;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "LIBMTP_FILETYPE_OG", 18)) {
    /*                                 G      */
      *iv_return = LIBMTP_FILETYPE_OGG;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LIBMTP_FILETYPE_PN", 18)) {
    /*                                 G      */
      *iv_return = LIBMTP_FILETYPE_PNG;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "LIBMTP_FILETYPE_AV", 18)) {
    /*                                 I      */
      *iv_return = LIBMTP_FILETYPE_AVI;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "LIBMTP_FILETYPE_XM", 18)) {
    /*                                 L      */
      *iv_return = LIBMTP_FILETYPE_XML;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "LIBMTP_FILETYPE_BM", 18)) {
    /*                                 P      */
      *iv_return = LIBMTP_FILETYPE_BMP;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "LIBMTP_FILETYPE_XL", 18)) {
    /*                                 S      */
      *iv_return = LIBMTP_FILETYPE_XLS;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "LIBMTP_FILETYPE_MH", 18)) {
    /*                                 T      */
      *iv_return = LIBMTP_FILETYPE_MHT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LIBMTP_FILETYPE_PP", 18)) {
    /*                                 T      */
      *iv_return = LIBMTP_FILETYPE_PPT;
      return PERL_constant_ISIV;
    }
    break;
  case 'V':
    if (memEQ(name, "LIBMTP_FILETYPE_WA", 18)) {
    /*                                 V      */
      *iv_return = LIBMTP_FILETYPE_WAV;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LIBMTP_FILETYPE_WM", 18)) {
    /*                                 V      */
      *iv_return = LIBMTP_FILETYPE_WMV;
      return PERL_constant_ISIV;
    }
    break;
  case 'X':
    if (memEQ(name, "LIBMTP_FILETYPE_JP", 18)) {
    /*                                 X      */
      *iv_return = LIBMTP_FILETYPE_JPX;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_20 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LIBMTP_DATATYPE_INT8 LIBMTP_ERROR_GENERAL LIBMTP_FILETYPE_FLAC
     LIBMTP_FILETYPE_HTML LIBMTP_FILETYPE_JFIF LIBMTP_FILETYPE_JPEG
     LIBMTP_FILETYPE_MPEG LIBMTP_FILETYPE_PICT LIBMTP_FILETYPE_TEXT
     LIBMTP_FILETYPE_TIFF LIBMTP_PROPERTY_Mood LIBMTP_PROPERTY_Name
     LIBMTP_PROPERTY_Role */
  /* Offset 18 gives the best switch position.  */
  switch (name[18]) {
  case 'A':
    if (memEQ(name, "LIBMTP_ERROR_GENERAL", 20)) {
    /*                                 ^        */
      *iv_return = LIBMTP_ERROR_GENERAL;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LIBMTP_FILETYPE_FLAC", 20)) {
    /*                                 ^        */
      *iv_return = LIBMTP_FILETYPE_FLAC;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "LIBMTP_FILETYPE_PICT", 20)) {
    /*                                 ^        */
      *iv_return = LIBMTP_FILETYPE_PICT;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "LIBMTP_FILETYPE_JPEG", 20)) {
    /*                                 ^        */
      *iv_return = LIBMTP_FILETYPE_JPEG;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LIBMTP_FILETYPE_MPEG", 20)) {
    /*                                 ^        */
      *iv_return = LIBMTP_FILETYPE_MPEG;
      return PERL_constant_ISIV;
    }
    break;
  case 'F':
    if (memEQ(name, "LIBMTP_FILETYPE_TIFF", 20)) {
    /*                                 ^        */
      *iv_return = LIBMTP_FILETYPE_TIFF;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "LIBMTP_FILETYPE_JFIF", 20)) {
    /*                                 ^        */
      *iv_return = LIBMTP_FILETYPE_JFIF;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "LIBMTP_FILETYPE_HTML", 20)) {
    /*                                 ^        */
      *iv_return = LIBMTP_FILETYPE_HTML;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "LIBMTP_DATATYPE_INT8", 20)) {
    /*                                 ^        */
      *iv_return = LIBMTP_DATATYPE_INT8;
      return PERL_constant_ISIV;
    }
    break;
  case 'X':
    if (memEQ(name, "LIBMTP_FILETYPE_TEXT", 20)) {
    /*                                 ^        */
      *iv_return = LIBMTP_FILETYPE_TEXT;
      return PERL_constant_ISIV;
    }
    break;
  case 'l':
    if (memEQ(name, "LIBMTP_PROPERTY_Role", 20)) {
    /*                                 ^        */
      *iv_return = LIBMTP_PROPERTY_Role;
      return PERL_constant_ISIV;
    }
    break;
  case 'm':
    if (memEQ(name, "LIBMTP_PROPERTY_Name", 20)) {
    /*                                 ^        */
      *iv_return = LIBMTP_PROPERTY_Name;
      return PERL_constant_ISIV;
    }
    break;
  case 'o':
    if (memEQ(name, "LIBMTP_PROPERTY_Mood", 20)) {
    /*                                 ^        */
      *iv_return = LIBMTP_PROPERTY_Mood;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_21 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LIBMTP_DATATYPE_INT16 LIBMTP_DATATYPE_INT32 LIBMTP_DATATYPE_INT64
     LIBMTP_DATATYPE_UINT8 LIBMTP_FILETYPE_ALBUM LIBMTP_PROPERTY_Genre
     LIBMTP_PROPERTY_Owner LIBMTP_PROPERTY_Track LIBMTP_PROPERTY_Width */
  /* Offset 20 gives the best switch position.  */
  switch (name[20]) {
  case '2':
    if (memEQ(name, "LIBMTP_DATATYPE_INT3", 20)) {
    /*                                   2      */
      *iv_return = LIBMTP_DATATYPE_INT32;
      return PERL_constant_ISIV;
    }
    break;
  case '4':
    if (memEQ(name, "LIBMTP_DATATYPE_INT6", 20)) {
    /*                                   4      */
      *iv_return = LIBMTP_DATATYPE_INT64;
      return PERL_constant_ISIV;
    }
    break;
  case '6':
    if (memEQ(name, "LIBMTP_DATATYPE_INT1", 20)) {
    /*                                   6      */
      *iv_return = LIBMTP_DATATYPE_INT16;
      return PERL_constant_ISIV;
    }
    break;
  case '8':
    if (memEQ(name, "LIBMTP_DATATYPE_UINT", 20)) {
    /*                                   8      */
      *iv_return = LIBMTP_DATATYPE_UINT8;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "LIBMTP_FILETYPE_ALBU", 20)) {
    /*                                   M      */
      *iv_return = LIBMTP_FILETYPE_ALBUM;
      return PERL_constant_ISIV;
    }
    break;
  case 'e':
    if (memEQ(name, "LIBMTP_PROPERTY_Genr", 20)) {
    /*                                   e      */
      *iv_return = LIBMTP_PROPERTY_Genre;
      return PERL_constant_ISIV;
    }
    break;
  case 'h':
    if (memEQ(name, "LIBMTP_PROPERTY_Widt", 20)) {
    /*                                   h      */
      *iv_return = LIBMTP_PROPERTY_Width;
      return PERL_constant_ISIV;
    }
    break;
  case 'k':
    if (memEQ(name, "LIBMTP_PROPERTY_Trac", 20)) {
    /*                                   k      */
      *iv_return = LIBMTP_PROPERTY_Track;
      return PERL_constant_ISIV;
    }
    break;
  case 'r':
    if (memEQ(name, "LIBMTP_PROPERTY_Owne", 20)) {
    /*                                   r      */
      *iv_return = LIBMTP_PROPERTY_Owner;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_22 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LIBMTP_DATATYPE_UINT16 LIBMTP_DATATYPE_UINT32 LIBMTP_DATATYPE_UINT64
     LIBMTP_ERROR_CANCELLED LIBMTP_ERROR_PTP_LAYER LIBMTP_ERROR_USB_LAYER
     LIBMTP_FILETYPE_FOLDER LIBMTP_FILETYPE_VCARD2 LIBMTP_FILETYPE_VCARD3
     LIBMTP_PROPERTY_Artist LIBMTP_PROPERTY_Editor LIBMTP_PROPERTY_Height
     LIBMTP_PROPERTY_Hidden LIBMTP_PROPERTY_Lyrics LIBMTP_PROPERTY_Prefix
     LIBMTP_PROPERTY_Rating LIBMTP_PROPERTY_Source LIBMTP_PROPERTY_Suffix
     LIBMTP_PROPERTY_SyncID */
  /* Offset 17 gives the best switch position.  */
  switch (name[17]) {
  case 'C':
    if (memEQ(name, "LIBMTP_FILETYPE_VCARD2", 22)) {
    /*                                ^           */
      *iv_return = LIBMTP_FILETYPE_VCARD2;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LIBMTP_FILETYPE_VCARD3", 22)) {
    /*                                ^           */
      *iv_return = LIBMTP_FILETYPE_VCARD3;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "LIBMTP_ERROR_CANCELLED", 22)) {
    /*                                ^           */
      *iv_return = LIBMTP_ERROR_CANCELLED;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "LIBMTP_DATATYPE_UINT16", 22)) {
    /*                                ^           */
      *iv_return = LIBMTP_DATATYPE_UINT16;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LIBMTP_DATATYPE_UINT32", 22)) {
    /*                                ^           */
      *iv_return = LIBMTP_DATATYPE_UINT32;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LIBMTP_DATATYPE_UINT64", 22)) {
    /*                                ^           */
      *iv_return = LIBMTP_DATATYPE_UINT64;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "LIBMTP_ERROR_PTP_LAYER", 22)) {
    /*                                ^           */
      *iv_return = LIBMTP_ERROR_PTP_LAYER;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LIBMTP_ERROR_USB_LAYER", 22)) {
    /*                                ^           */
      *iv_return = LIBMTP_ERROR_USB_LAYER;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "LIBMTP_FILETYPE_FOLDER", 22)) {
    /*                                ^           */
      *iv_return = LIBMTP_FILETYPE_FOLDER;
      return PERL_constant_ISIV;
    }
    break;
  case 'a':
    if (memEQ(name, "LIBMTP_PROPERTY_Rating", 22)) {
    /*                                ^           */
      *iv_return = LIBMTP_PROPERTY_Rating;
      return PERL_constant_ISIV;
    }
    break;
  case 'd':
    if (memEQ(name, "LIBMTP_PROPERTY_Editor", 22)) {
    /*                                ^           */
      *iv_return = LIBMTP_PROPERTY_Editor;
      return PERL_constant_ISIV;
    }
    break;
  case 'e':
    if (memEQ(name, "LIBMTP_PROPERTY_Height", 22)) {
    /*                                ^           */
      *iv_return = LIBMTP_PROPERTY_Height;
      return PERL_constant_ISIV;
    }
    break;
  case 'i':
    if (memEQ(name, "LIBMTP_PROPERTY_Hidden", 22)) {
    /*                                ^           */
      *iv_return = LIBMTP_PROPERTY_Hidden;
      return PERL_constant_ISIV;
    }
    break;
  case 'o':
    if (memEQ(name, "LIBMTP_PROPERTY_Source", 22)) {
    /*                                ^           */
      *iv_return = LIBMTP_PROPERTY_Source;
      return PERL_constant_ISIV;
    }
    break;
  case 'r':
    if (memEQ(name, "LIBMTP_PROPERTY_Artist", 22)) {
    /*                                ^           */
      *iv_return = LIBMTP_PROPERTY_Artist;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LIBMTP_PROPERTY_Prefix", 22)) {
    /*                                ^           */
      *iv_return = LIBMTP_PROPERTY_Prefix;
      return PERL_constant_ISIV;
    }
    break;
  case 'u':
    if (memEQ(name, "LIBMTP_PROPERTY_Suffix", 22)) {
    /*                                ^           */
      *iv_return = LIBMTP_PROPERTY_Suffix;
      return PERL_constant_ISIV;
    }
    break;
  case 'y':
    if (memEQ(name, "LIBMTP_PROPERTY_Lyrics", 22)) {
    /*                                ^           */
      *iv_return = LIBMTP_PROPERTY_Lyrics;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LIBMTP_PROPERTY_SyncID", 22)) {
    /*                                ^           */
      *iv_return = LIBMTP_PROPERTY_SyncID;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_23 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LIBMTP_ERROR_CONNECTING LIBMTP_FILETYPE_AUDIBLE LIBMTP_FILETYPE_UNKNOWN
     LIBMTP_FILETYPE_WINEXEC LIBMTP_PROPERTY_BuyFlag LIBMTP_PROPERTY_Credits
     LIBMTP_PROPERTY_Fnumber LIBMTP_PROPERTY_Subject LIBMTP_PROPERTY_UNKNOWN */
  /* Offset 16 gives the best switch position.  */
  switch (name[16]) {
  case 'A':
    if (memEQ(name, "LIBMTP_FILETYPE_AUDIBLE", 23)) {
    /*                               ^             */
      *iv_return = LIBMTP_FILETYPE_AUDIBLE;
      return PERL_constant_ISIV;
    }
    break;
  case 'B':
    if (memEQ(name, "LIBMTP_PROPERTY_BuyFlag", 23)) {
    /*                               ^             */
      *iv_return = LIBMTP_PROPERTY_BuyFlag;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "LIBMTP_PROPERTY_Credits", 23)) {
    /*                               ^             */
      *iv_return = LIBMTP_PROPERTY_Credits;
      return PERL_constant_ISIV;
    }
    break;
  case 'F':
    if (memEQ(name, "LIBMTP_PROPERTY_Fnumber", 23)) {
    /*                               ^             */
      *iv_return = LIBMTP_PROPERTY_Fnumber;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "LIBMTP_ERROR_CONNECTING", 23)) {
    /*                               ^             */
      *iv_return = LIBMTP_ERROR_CONNECTING;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "LIBMTP_PROPERTY_Subject", 23)) {
    /*                               ^             */
      *iv_return = LIBMTP_PROPERTY_Subject;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "LIBMTP_FILETYPE_UNKNOWN", 23)) {
    /*                               ^             */
      *iv_return = LIBMTP_FILETYPE_UNKNOWN;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LIBMTP_PROPERTY_UNKNOWN", 23)) {
    /*                               ^             */
      *iv_return = LIBMTP_PROPERTY_UNKNOWN;
      return PERL_constant_ISIV;
    }
    break;
  case 'W':
    if (memEQ(name, "LIBMTP_FILETYPE_WINEXEC", 23)) {
    /*                               ^             */
      *iv_return = LIBMTP_FILETYPE_WINEXEC;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_24 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LIBMTP_FILETYPE_FIRMWARE LIBMTP_FILETYPE_PLAYLIST LIBMTP_HANDLER_RETURN_OK
     LIBMTP_PROPERTY_BodyText LIBMTP_PROPERTY_Composer LIBMTP_PROPERTY_Duration
     LIBMTP_PROPERTY_Keywords LIBMTP_PROPERTY_Priority LIBMTP_PROPERTY_Subtitle
     LIBMTP_PROPERTY_UseCount */
  /* Offset 22 gives the best switch position.  */
  switch (name[22]) {
  case 'O':
    if (memEQ(name, "LIBMTP_HANDLER_RETURN_OK", 24)) {
    /*                                     ^        */
      *iv_return = LIBMTP_HANDLER_RETURN_OK;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "LIBMTP_FILETYPE_FIRMWARE", 24)) {
    /*                                     ^        */
      *iv_return = LIBMTP_FILETYPE_FIRMWARE;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "LIBMTP_FILETYPE_PLAYLIST", 24)) {
    /*                                     ^        */
      *iv_return = LIBMTP_FILETYPE_PLAYLIST;
      return PERL_constant_ISIV;
    }
    break;
  case 'd':
    if (memEQ(name, "LIBMTP_PROPERTY_Keywords", 24)) {
    /*                                     ^        */
      *iv_return = LIBMTP_PROPERTY_Keywords;
      return PERL_constant_ISIV;
    }
    break;
  case 'e':
    if (memEQ(name, "LIBMTP_PROPERTY_Composer", 24)) {
    /*                                     ^        */
      *iv_return = LIBMTP_PROPERTY_Composer;
      return PERL_constant_ISIV;
    }
    break;
  case 'l':
    if (memEQ(name, "LIBMTP_PROPERTY_Subtitle", 24)) {
    /*                                     ^        */
      *iv_return = LIBMTP_PROPERTY_Subtitle;
      return PERL_constant_ISIV;
    }
    break;
  case 'n':
    if (memEQ(name, "LIBMTP_PROPERTY_UseCount", 24)) {
    /*                                     ^        */
      *iv_return = LIBMTP_PROPERTY_UseCount;
      return PERL_constant_ISIV;
    }
    break;
  case 'o':
    if (memEQ(name, "LIBMTP_PROPERTY_Duration", 24)) {
    /*                                     ^        */
      *iv_return = LIBMTP_PROPERTY_Duration;
      return PERL_constant_ISIV;
    }
    break;
  case 't':
    if (memEQ(name, "LIBMTP_PROPERTY_Priority", 24)) {
    /*                                     ^        */
      *iv_return = LIBMTP_PROPERTY_Priority;
      return PERL_constant_ISIV;
    }
    break;
  case 'x':
    if (memEQ(name, "LIBMTP_PROPERTY_BodyText", 24)) {
    /*                                     ^        */
      *iv_return = LIBMTP_PROPERTY_BodyText;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_25 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LIBMTP_ERROR_STORAGE_FULL LIBMTP_FILETYPE_MEDIACARD
     LIBMTP_PROPERTY_AlbumName LIBMTP_PROPERTY_Birthdate
     LIBMTP_PROPERTY_CreatedBy LIBMTP_PROPERTY_DRMStatus
     LIBMTP_PROPERTY_DateAdded LIBMTP_PROPERTY_GivenName
     LIBMTP_PROPERTY_IsCropped LIBMTP_PROPERTY_MediaGUID
     LIBMTP_PROPERTY_MessageCC LIBMTP_PROPERTY_MessageTo
     LIBMTP_PROPERTY_MetaGenre LIBMTP_PROPERTY_ScanDepth
     LIBMTP_PROPERTY_SkipCount LIBMTP_PROPERTY_StorageID
     LIBMTP_PROPERTY_URLSource LIBMTP_PROPERTY_Webmaster */
  /* Offset 18 gives the best switch position.  */
  switch (name[18]) {
  case 'C':
    if (memEQ(name, "LIBMTP_PROPERTY_IsCropped", 25)) {
    /*                                 ^             */
      *iv_return = LIBMTP_PROPERTY_IsCropped;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "LIBMTP_FILETYPE_MEDIACARD", 25)) {
    /*                                 ^             */
      *iv_return = LIBMTP_FILETYPE_MEDIACARD;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "LIBMTP_ERROR_STORAGE_FULL", 25)) {
    /*                                 ^             */
      *iv_return = LIBMTP_ERROR_STORAGE_FULL;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "LIBMTP_PROPERTY_URLSource", 25)) {
    /*                                 ^             */
      *iv_return = LIBMTP_PROPERTY_URLSource;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "LIBMTP_PROPERTY_DRMStatus", 25)) {
    /*                                 ^             */
      *iv_return = LIBMTP_PROPERTY_DRMStatus;
      return PERL_constant_ISIV;
    }
    break;
  case 'a':
    if (memEQ(name, "LIBMTP_PROPERTY_ScanDepth", 25)) {
    /*                                 ^             */
      *iv_return = LIBMTP_PROPERTY_ScanDepth;
      return PERL_constant_ISIV;
    }
    break;
  case 'b':
    if (memEQ(name, "LIBMTP_PROPERTY_AlbumName", 25)) {
    /*                                 ^             */
      *iv_return = LIBMTP_PROPERTY_AlbumName;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LIBMTP_PROPERTY_Webmaster", 25)) {
    /*                                 ^             */
      *iv_return = LIBMTP_PROPERTY_Webmaster;
      return PERL_constant_ISIV;
    }
    break;
  case 'd':
    if (memEQ(name, "LIBMTP_PROPERTY_MediaGUID", 25)) {
    /*                                 ^             */
      *iv_return = LIBMTP_PROPERTY_MediaGUID;
      return PERL_constant_ISIV;
    }
    break;
  case 'e':
    if (memEQ(name, "LIBMTP_PROPERTY_CreatedBy", 25)) {
    /*                                 ^             */
      *iv_return = LIBMTP_PROPERTY_CreatedBy;
      return PERL_constant_ISIV;
    }
    break;
  case 'i':
    if (memEQ(name, "LIBMTP_PROPERTY_SkipCount", 25)) {
    /*                                 ^             */
      *iv_return = LIBMTP_PROPERTY_SkipCount;
      return PERL_constant_ISIV;
    }
    break;
  case 'o':
    if (memEQ(name, "LIBMTP_PROPERTY_StorageID", 25)) {
    /*                                 ^             */
      *iv_return = LIBMTP_PROPERTY_StorageID;
      return PERL_constant_ISIV;
    }
    break;
  case 'r':
    if (memEQ(name, "LIBMTP_PROPERTY_Birthdate", 25)) {
    /*                                 ^             */
      *iv_return = LIBMTP_PROPERTY_Birthdate;
      return PERL_constant_ISIV;
    }
    break;
  case 's':
    if (memEQ(name, "LIBMTP_PROPERTY_MessageCC", 25)) {
    /*                                 ^             */
      *iv_return = LIBMTP_PROPERTY_MessageCC;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LIBMTP_PROPERTY_MessageTo", 25)) {
    /*                                 ^             */
      *iv_return = LIBMTP_PROPERTY_MessageTo;
      return PERL_constant_ISIV;
    }
    break;
  case 't':
    if (memEQ(name, "LIBMTP_PROPERTY_DateAdded", 25)) {
    /*                                 ^             */
      *iv_return = LIBMTP_PROPERTY_DateAdded;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LIBMTP_PROPERTY_MetaGenre", 25)) {
    /*                                 ^             */
      *iv_return = LIBMTP_PROPERTY_MetaGenre;
      return PERL_constant_ISIV;
    }
    break;
  case 'v':
    if (memEQ(name, "LIBMTP_PROPERTY_GivenName", 25)) {
    /*                                 ^             */
      *iv_return = LIBMTP_PROPERTY_GivenName;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_26 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LIBMTP_FILETYPE_VCALENDAR1 LIBMTP_FILETYPE_VCALENDAR2
     LIBMTP_PROPERTY_BufferSize LIBMTP_PROPERTY_FamilyName
     LIBMTP_PROPERTY_MessageBCC LIBMTP_PROPERTY_ObjectSize
     LIBMTP_PROPERTY_ProducedBy LIBMTP_PROPERTY_SampleRate
     LIBMTP_PROPERTY_TimetoLive */
  /* Offset 16 gives the best switch position.  */
  switch (name[16]) {
  case 'B':
    if (memEQ(name, "LIBMTP_PROPERTY_BufferSize", 26)) {
    /*                               ^                */
      *iv_return = LIBMTP_PROPERTY_BufferSize;
      return PERL_constant_ISIV;
    }
    break;
  case 'F':
    if (memEQ(name, "LIBMTP_PROPERTY_FamilyName", 26)) {
    /*                               ^                */
      *iv_return = LIBMTP_PROPERTY_FamilyName;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "LIBMTP_PROPERTY_MessageBCC", 26)) {
    /*                               ^                */
      *iv_return = LIBMTP_PROPERTY_MessageBCC;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "LIBMTP_PROPERTY_ObjectSize", 26)) {
    /*                               ^                */
      *iv_return = LIBMTP_PROPERTY_ObjectSize;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "LIBMTP_PROPERTY_ProducedBy", 26)) {
    /*                               ^                */
      *iv_return = LIBMTP_PROPERTY_ProducedBy;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "LIBMTP_PROPERTY_SampleRate", 26)) {
    /*                               ^                */
      *iv_return = LIBMTP_PROPERTY_SampleRate;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "LIBMTP_PROPERTY_TimetoLive", 26)) {
    /*                               ^                */
      *iv_return = LIBMTP_PROPERTY_TimetoLive;
      return PERL_constant_ISIV;
    }
    break;
  case 'V':
    if (memEQ(name, "LIBMTP_FILETYPE_VCALENDAR1", 26)) {
    /*                               ^                */
      *iv_return = LIBMTP_FILETYPE_VCALENDAR1;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LIBMTP_FILETYPE_VCALENDAR2", 26)) {
    /*                               ^                */
      *iv_return = LIBMTP_FILETYPE_VCALENDAR2;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_27 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LIBMTP_FILETYPE_UNDEF_AUDIO LIBMTP_FILETYPE_UNDEF_VIDEO
     LIBMTP_HANDLER_RETURN_ERROR LIBMTP_PROPERTY_AlbumArtist
     LIBMTP_PROPERTY_BitRateType LIBMTP_PROPERTY_DateCreated
     LIBMTP_PROPERTY_Description LIBMTP_PROPERTY_DisplayName
     LIBMTP_PROPERTY_EmailOthers LIBMTP_PROPERTY_MessageRead
     LIBMTP_PROPERTY_MiddleNames LIBMTP_PROPERTY_PagerNumber
     LIBMTP_PROPERTY_PropertyBag */
  /* Offset 23 gives the best switch position.  */
  switch (name[23]) {
  case 'I':
    if (memEQ(name, "LIBMTP_FILETYPE_UNDEF_VIDEO", 27)) {
    /*                                      ^          */
      *iv_return = LIBMTP_FILETYPE_UNDEF_VIDEO;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "LIBMTP_PROPERTY_DisplayName", 27)) {
    /*                                      ^          */
      *iv_return = LIBMTP_PROPERTY_DisplayName;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "LIBMTP_HANDLER_RETURN_ERROR", 27)) {
    /*                                      ^          */
      *iv_return = LIBMTP_HANDLER_RETURN_ERROR;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LIBMTP_PROPERTY_MessageRead", 27)) {
    /*                                      ^          */
      *iv_return = LIBMTP_PROPERTY_MessageRead;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "LIBMTP_PROPERTY_BitRateType", 27)) {
    /*                                      ^          */
      *iv_return = LIBMTP_PROPERTY_BitRateType;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "LIBMTP_FILETYPE_UNDEF_AUDIO", 27)) {
    /*                                      ^          */
      *iv_return = LIBMTP_FILETYPE_UNDEF_AUDIO;
      return PERL_constant_ISIV;
    }
    break;
  case 'a':
    if (memEQ(name, "LIBMTP_PROPERTY_DateCreated", 27)) {
    /*                                      ^          */
      *iv_return = LIBMTP_PROPERTY_DateCreated;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LIBMTP_PROPERTY_MiddleNames", 27)) {
    /*                                      ^          */
      *iv_return = LIBMTP_PROPERTY_MiddleNames;
      return PERL_constant_ISIV;
    }
    break;
  case 'h':
    if (memEQ(name, "LIBMTP_PROPERTY_EmailOthers", 27)) {
    /*                                      ^          */
      *iv_return = LIBMTP_PROPERTY_EmailOthers;
      return PERL_constant_ISIV;
    }
    break;
  case 'm':
    if (memEQ(name, "LIBMTP_PROPERTY_PagerNumber", 27)) {
    /*                                      ^          */
      *iv_return = LIBMTP_PROPERTY_PagerNumber;
      return PERL_constant_ISIV;
    }
    break;
  case 't':
    if (memEQ(name, "LIBMTP_PROPERTY_AlbumArtist", 27)) {
    /*                                      ^          */
      *iv_return = LIBMTP_PROPERTY_AlbumArtist;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LIBMTP_PROPERTY_Description", 27)) {
    /*                                      ^          */
      *iv_return = LIBMTP_PROPERTY_Description;
      return PERL_constant_ISIV;
    }
    break;
  case 'y':
    if (memEQ(name, "LIBMTP_PROPERTY_PropertyBag", 27)) {
    /*                                      ^          */
      *iv_return = LIBMTP_PROPERTY_PropertyBag;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_28 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LIBMTP_HANDLER_RETURN_CANCEL LIBMTP_PROPERTY_AudioBitRate
     LIBMTP_PROPERTY_ByteBookmark LIBMTP_PROPERTY_DateAuthored
     LIBMTP_PROPERTY_DateModified LIBMTP_PROPERTY_EmailPrimary
     LIBMTP_PROPERTY_ExposureTime LIBMTP_PROPERTY_LastAccessed
     LIBMTP_PROPERTY_ObjectFormat LIBMTP_PROPERTY_ParentObject
     LIBMTP_PROPERTY_SystemObject LIBMTP_PROPERTY_TimeBookmark
     LIBMTP_PROPERTY_TotalBitRate LIBMTP_PROPERTY_URLReference
     LIBMTP_PROPERTY_VideoBitRate */
  /* Offset 16 gives the best switch position.  */
  switch (name[16]) {
  case 'A':
    if (memEQ(name, "LIBMTP_PROPERTY_AudioBitRate", 28)) {
    /*                               ^                  */
      *iv_return = LIBMTP_PROPERTY_AudioBitRate;
      return PERL_constant_ISIV;
    }
    break;
  case 'B':
    if (memEQ(name, "LIBMTP_PROPERTY_ByteBookmark", 28)) {
    /*                               ^                  */
      *iv_return = LIBMTP_PROPERTY_ByteBookmark;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "LIBMTP_PROPERTY_DateAuthored", 28)) {
    /*                               ^                  */
      *iv_return = LIBMTP_PROPERTY_DateAuthored;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LIBMTP_PROPERTY_DateModified", 28)) {
    /*                               ^                  */
      *iv_return = LIBMTP_PROPERTY_DateModified;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "LIBMTP_HANDLER_RETURN_CANCEL", 28)) {
    /*                               ^                  */
      *iv_return = LIBMTP_HANDLER_RETURN_CANCEL;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LIBMTP_PROPERTY_EmailPrimary", 28)) {
    /*                               ^                  */
      *iv_return = LIBMTP_PROPERTY_EmailPrimary;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LIBMTP_PROPERTY_ExposureTime", 28)) {
    /*                               ^                  */
      *iv_return = LIBMTP_PROPERTY_ExposureTime;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "LIBMTP_PROPERTY_LastAccessed", 28)) {
    /*                               ^                  */
      *iv_return = LIBMTP_PROPERTY_LastAccessed;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "LIBMTP_PROPERTY_ObjectFormat", 28)) {
    /*                               ^                  */
      *iv_return = LIBMTP_PROPERTY_ObjectFormat;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "LIBMTP_PROPERTY_ParentObject", 28)) {
    /*                               ^                  */
      *iv_return = LIBMTP_PROPERTY_ParentObject;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "LIBMTP_PROPERTY_SystemObject", 28)) {
    /*                               ^                  */
      *iv_return = LIBMTP_PROPERTY_SystemObject;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "LIBMTP_PROPERTY_TimeBookmark", 28)) {
    /*                               ^                  */
      *iv_return = LIBMTP_PROPERTY_TimeBookmark;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LIBMTP_PROPERTY_TotalBitRate", 28)) {
    /*                               ^                  */
      *iv_return = LIBMTP_PROPERTY_TotalBitRate;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "LIBMTP_PROPERTY_URLReference", 28)) {
    /*                               ^                  */
      *iv_return = LIBMTP_PROPERTY_URLReference;
      return PERL_constant_ISIV;
    }
    break;
  case 'V':
    if (memEQ(name, "LIBMTP_PROPERTY_VideoBitRate", 28)) {
    /*                               ^                  */
      *iv_return = LIBMTP_PROPERTY_VideoBitRate;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_29 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LIBMTP_PROPERTY_AudioBitDepth LIBMTP_PROPERTY_ExposureIndex
     LIBMTP_PROPERTY_ImageBitDepth LIBMTP_PROPERTY_LastBuildDate
     LIBMTP_PROPERTY_MessageSender LIBMTP_PROPERTY_NonConsumable */
  /* Offset 16 gives the best switch position.  */
  switch (name[16]) {
  case 'A':
    if (memEQ(name, "LIBMTP_PROPERTY_AudioBitDepth", 29)) {
    /*                               ^                   */
      *iv_return = LIBMTP_PROPERTY_AudioBitDepth;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "LIBMTP_PROPERTY_ExposureIndex", 29)) {
    /*                               ^                   */
      *iv_return = LIBMTP_PROPERTY_ExposureIndex;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "LIBMTP_PROPERTY_ImageBitDepth", 29)) {
    /*                               ^                   */
      *iv_return = LIBMTP_PROPERTY_ImageBitDepth;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "LIBMTP_PROPERTY_LastBuildDate", 29)) {
    /*                               ^                   */
      *iv_return = LIBMTP_PROPERTY_LastBuildDate;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "LIBMTP_PROPERTY_MessageSender", 29)) {
    /*                               ^                   */
      *iv_return = LIBMTP_PROPERTY_MessageSender;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "LIBMTP_PROPERTY_NonConsumable", 29)) {
    /*                               ^                   */
      *iv_return = LIBMTP_PROPERTY_NonConsumable;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_30 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LIBMTP_ERROR_MEMORY_ALLOCATION LIBMTP_PROPERTY_AudioWAVECodec
     LIBMTP_PROPERTY_EmailBusiness1 LIBMTP_PROPERTY_EmailBusiness2
     LIBMTP_PROPERTY_EmailPersonal1 LIBMTP_PROPERTY_EmailPersonal2
     LIBMTP_PROPERTY_LanguageLocale LIBMTP_PROPERTY_ObjectBookmark
     LIBMTP_PROPERTY_ObjectFileName LIBMTP_PROPERTY_OriginLocation
     LIBMTP_PROPERTY_ParentalRating LIBMTP_PROPERTY_SubDescription
     LIBMTP_PROPERTY_URLDestination LIBMTP_STORAGE_SORTBY_MAXSPACE */
  /* Offset 22 gives the best switch position.  */
  switch (name[22]) {
  case 'A':
    if (memEQ(name, "LIBMTP_PROPERTY_AudioWAVECodec", 30)) {
    /*                                     ^              */
      *iv_return = LIBMTP_PROPERTY_AudioWAVECodec;
      return PERL_constant_ISIV;
    }
    break;
  case 'B':
    if (memEQ(name, "LIBMTP_PROPERTY_ObjectBookmark", 30)) {
    /*                                     ^              */
      *iv_return = LIBMTP_PROPERTY_ObjectBookmark;
      return PERL_constant_ISIV;
    }
    break;
  case 'F':
    if (memEQ(name, "LIBMTP_PROPERTY_ObjectFileName", 30)) {
    /*                                     ^              */
      *iv_return = LIBMTP_PROPERTY_ObjectFileName;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "LIBMTP_ERROR_MEMORY_ALLOCATION", 30)) {
    /*                                     ^              */
      *iv_return = LIBMTP_ERROR_MEMORY_ALLOCATION;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LIBMTP_PROPERTY_OriginLocation", 30)) {
    /*                                     ^              */
      *iv_return = LIBMTP_PROPERTY_OriginLocation;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "LIBMTP_STORAGE_SORTBY_MAXSPACE", 30)) {
    /*                                     ^              */
#ifdef LIBMTP_STORAGE_SORTBY_MAXSPACE
      *iv_return = LIBMTP_STORAGE_SORTBY_MAXSPACE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'a':
    if (memEQ(name, "LIBMTP_PROPERTY_ParentalRating", 30)) {
    /*                                     ^              */
      *iv_return = LIBMTP_PROPERTY_ParentalRating;
      return PERL_constant_ISIV;
    }
    break;
  case 'c':
    if (memEQ(name, "LIBMTP_PROPERTY_SubDescription", 30)) {
    /*                                     ^              */
      *iv_return = LIBMTP_PROPERTY_SubDescription;
      return PERL_constant_ISIV;
    }
    break;
  case 'e':
    if (memEQ(name, "LIBMTP_PROPERTY_EmailPersonal1", 30)) {
    /*                                     ^              */
      *iv_return = LIBMTP_PROPERTY_EmailPersonal1;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LIBMTP_PROPERTY_EmailPersonal2", 30)) {
    /*                                     ^              */
      *iv_return = LIBMTP_PROPERTY_EmailPersonal2;
      return PERL_constant_ISIV;
    }
    break;
  case 'g':
    if (memEQ(name, "LIBMTP_PROPERTY_LanguageLocale", 30)) {
    /*                                     ^              */
      *iv_return = LIBMTP_PROPERTY_LanguageLocale;
      return PERL_constant_ISIV;
    }
    break;
  case 't':
    if (memEQ(name, "LIBMTP_PROPERTY_URLDestination", 30)) {
    /*                                     ^              */
      *iv_return = LIBMTP_PROPERTY_URLDestination;
      return PERL_constant_ISIV;
    }
    break;
  case 'u':
    if (memEQ(name, "LIBMTP_PROPERTY_EmailBusiness1", 30)) {
    /*                                     ^              */
      *iv_return = LIBMTP_PROPERTY_EmailBusiness1;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LIBMTP_PROPERTY_EmailBusiness2", 30)) {
    /*                                     ^              */
      *iv_return = LIBMTP_PROPERTY_EmailBusiness2;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_31 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LIBMTP_ERROR_NO_DEVICE_ATTACHED LIBMTP_PROPERTY_ActivityEndTime
     LIBMTP_PROPERTY_AssociationDesc LIBMTP_PROPERTY_AssociationType
     LIBMTP_PROPERTY_EffectiveRating LIBMTP_PROPERTY_EncodingProfile
     LIBMTP_PROPERTY_EncodingQuality LIBMTP_STORAGE_SORTBY_FREESPACE
     LIBMTP_STORAGE_SORTBY_NOTSORTED */
  /* Offset 25 gives the best switch position.  */
  switch (name[25]) {
  case 'E':
    if (memEQ(name, "LIBMTP_STORAGE_SORTBY_FREESPACE", 31)) {
    /*                                        ^            */
#ifdef LIBMTP_STORAGE_SORTBY_FREESPACE
      *iv_return = LIBMTP_STORAGE_SORTBY_FREESPACE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "LIBMTP_PROPERTY_EffectiveRating", 31)) {
    /*                                        ^            */
      *iv_return = LIBMTP_PROPERTY_EffectiveRating;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "LIBMTP_STORAGE_SORTBY_NOTSORTED", 31)) {
    /*                                        ^            */
#ifdef LIBMTP_STORAGE_SORTBY_NOTSORTED
      *iv_return = LIBMTP_STORAGE_SORTBY_NOTSORTED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "LIBMTP_ERROR_NO_DEVICE_ATTACHED", 31)) {
    /*                                        ^            */
      *iv_return = LIBMTP_ERROR_NO_DEVICE_ATTACHED;
      return PERL_constant_ISIV;
    }
    break;
  case 'n':
    if (memEQ(name, "LIBMTP_PROPERTY_ActivityEndTime", 31)) {
    /*                                        ^            */
      *iv_return = LIBMTP_PROPERTY_ActivityEndTime;
      return PERL_constant_ISIV;
    }
    break;
  case 'o':
    if (memEQ(name, "LIBMTP_PROPERTY_AssociationDesc", 31)) {
    /*                                        ^            */
      *iv_return = LIBMTP_PROPERTY_AssociationDesc;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LIBMTP_PROPERTY_AssociationType", 31)) {
    /*                                        ^            */
      *iv_return = LIBMTP_PROPERTY_AssociationType;
      return PERL_constant_ISIV;
    }
    break;
  case 'r':
    if (memEQ(name, "LIBMTP_PROPERTY_EncodingProfile", 31)) {
    /*                                        ^            */
      *iv_return = LIBMTP_PROPERTY_EncodingProfile;
      return PERL_constant_ISIV;
    }
    break;
  case 'u':
    if (memEQ(name, "LIBMTP_PROPERTY_EncodingQuality", 31)) {
    /*                                        ^            */
      *iv_return = LIBMTP_PROPERTY_EncodingQuality;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_32 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LIBMTP_PROPERTY_ActivityAccepted LIBMTP_PROPERTY_ActivityLocation
     LIBMTP_PROPERTY_FaxNumberPrimary LIBMTP_PROPERTY_IsColorCorrected
     LIBMTP_PROPERTY_KeyFrameDistance LIBMTP_PROPERTY_NumberOfChannels
     LIBMTP_PROPERTY_OrganizationName LIBMTP_PROPERTY_ProtectionStatus
     LIBMTP_PROPERTY_VideoFourCCCodec */
  /* Offset 16 gives the best switch position.  */
  switch (name[16]) {
  case 'A':
    if (memEQ(name, "LIBMTP_PROPERTY_ActivityAccepted", 32)) {
    /*                               ^                      */
      *iv_return = LIBMTP_PROPERTY_ActivityAccepted;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LIBMTP_PROPERTY_ActivityLocation", 32)) {
    /*                               ^                      */
      *iv_return = LIBMTP_PROPERTY_ActivityLocation;
      return PERL_constant_ISIV;
    }
    break;
  case 'F':
    if (memEQ(name, "LIBMTP_PROPERTY_FaxNumberPrimary", 32)) {
    /*                               ^                      */
      *iv_return = LIBMTP_PROPERTY_FaxNumberPrimary;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "LIBMTP_PROPERTY_IsColorCorrected", 32)) {
    /*                               ^                      */
      *iv_return = LIBMTP_PROPERTY_IsColorCorrected;
      return PERL_constant_ISIV;
    }
    break;
  case 'K':
    if (memEQ(name, "LIBMTP_PROPERTY_KeyFrameDistance", 32)) {
    /*                               ^                      */
      *iv_return = LIBMTP_PROPERTY_KeyFrameDistance;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "LIBMTP_PROPERTY_NumberOfChannels", 32)) {
    /*                               ^                      */
      *iv_return = LIBMTP_PROPERTY_NumberOfChannels;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "LIBMTP_PROPERTY_OrganizationName", 32)) {
    /*                               ^                      */
      *iv_return = LIBMTP_PROPERTY_OrganizationName;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "LIBMTP_PROPERTY_ProtectionStatus", 32)) {
    /*                               ^                      */
      *iv_return = LIBMTP_PROPERTY_ProtectionStatus;
      return PERL_constant_ISIV;
    }
    break;
  case 'V':
    if (memEQ(name, "LIBMTP_PROPERTY_VideoFourCCCodec", 32)) {
    /*                               ^                      */
      *iv_return = LIBMTP_PROPERTY_VideoFourCCCodec;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_33 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LIBMTP_PROPERTY_ActivityBeginTime LIBMTP_PROPERTY_ActivityResources
     LIBMTP_PROPERTY_FaxNumberBusiness LIBMTP_PROPERTY_FaxNumberPersonal
     LIBMTP_PROPERTY_PhoneNumberMobile LIBMTP_PROPERTY_PhoneNumberOthers
     LIBMTP_PROPERTY_PhoneticGivenName LIBMTP_PROPERTY_PrimaryWebAddress */
  /* Offset 27 gives the best switch position.  */
  switch (name[27]) {
  case 'M':
    if (memEQ(name, "LIBMTP_PROPERTY_PhoneNumberMobile", 33)) {
    /*                                          ^            */
      *iv_return = LIBMTP_PROPERTY_PhoneNumberMobile;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "LIBMTP_PROPERTY_PhoneNumberOthers", 33)) {
    /*                                          ^            */
      *iv_return = LIBMTP_PROPERTY_PhoneNumberOthers;
      return PERL_constant_ISIV;
    }
    break;
  case 'd':
    if (memEQ(name, "LIBMTP_PROPERTY_PrimaryWebAddress", 33)) {
    /*                                          ^            */
      *iv_return = LIBMTP_PROPERTY_PrimaryWebAddress;
      return PERL_constant_ISIV;
    }
    break;
  case 'e':
    if (memEQ(name, "LIBMTP_PROPERTY_PhoneticGivenName", 33)) {
    /*                                          ^            */
      *iv_return = LIBMTP_PROPERTY_PhoneticGivenName;
      return PERL_constant_ISIV;
    }
    break;
  case 'i':
    if (memEQ(name, "LIBMTP_PROPERTY_ActivityBeginTime", 33)) {
    /*                                          ^            */
      *iv_return = LIBMTP_PROPERTY_ActivityBeginTime;
      return PERL_constant_ISIV;
    }
    break;
  case 'o':
    if (memEQ(name, "LIBMTP_PROPERTY_ActivityResources", 33)) {
    /*                                          ^            */
      *iv_return = LIBMTP_PROPERTY_ActivityResources;
      return PERL_constant_ISIV;
    }
    break;
  case 'r':
    if (memEQ(name, "LIBMTP_PROPERTY_FaxNumberPersonal", 33)) {
    /*                                          ^            */
      *iv_return = LIBMTP_PROPERTY_FaxNumberPersonal;
      return PERL_constant_ISIV;
    }
    break;
  case 's':
    if (memEQ(name, "LIBMTP_PROPERTY_FaxNumberBusiness", 33)) {
    /*                                          ^            */
      *iv_return = LIBMTP_PROPERTY_FaxNumberBusiness;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_34 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LIBMTP_FILETYPE_WINDOWSIMAGEFORMAT LIBMTP_PROPERTY_BusinessWebAddress
     LIBMTP_PROPERTY_PersonalWebAddress LIBMTP_PROPERTY_PhoneNumberMobile2
     LIBMTP_PROPERTY_PhoneNumberPrimary LIBMTP_PROPERTY_PhoneticFamilyName */
  /* Offset 22 gives the best switch position.  */
  switch (name[22]) {
  case 'S':
    if (memEQ(name, "LIBMTP_FILETYPE_WINDOWSIMAGEFORMAT", 34)) {
    /*                                     ^                  */
      *iv_return = LIBMTP_FILETYPE_WINDOWSIMAGEFORMAT;
      return PERL_constant_ISIV;
    }
    break;
  case 'a':
    if (memEQ(name, "LIBMTP_PROPERTY_PersonalWebAddress", 34)) {
    /*                                     ^                  */
      *iv_return = LIBMTP_PROPERTY_PersonalWebAddress;
      return PERL_constant_ISIV;
    }
    break;
  case 'i':
    if (memEQ(name, "LIBMTP_PROPERTY_PhoneticFamilyName", 34)) {
    /*                                     ^                  */
      *iv_return = LIBMTP_PROPERTY_PhoneticFamilyName;
      return PERL_constant_ISIV;
    }
    break;
  case 's':
    if (memEQ(name, "LIBMTP_PROPERTY_BusinessWebAddress", 34)) {
    /*                                     ^                  */
      *iv_return = LIBMTP_PROPERTY_BusinessWebAddress;
      return PERL_constant_ISIV;
    }
    break;
  case 'u':
    if (memEQ(name, "LIBMTP_PROPERTY_PhoneNumberMobile2", 34)) {
    /*                                     ^                  */
      *iv_return = LIBMTP_PROPERTY_PhoneNumberMobile2;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LIBMTP_PROPERTY_PhoneNumberPrimary", 34)) {
    /*                                     ^                  */
      *iv_return = LIBMTP_PROPERTY_PhoneNumberPrimary;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_35 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LIBMTP_PROPERTY_CorruptOrUnplayable LIBMTP_PROPERTY_MessageReceivedTime
     LIBMTP_PROPERTY_OriginalReleaseDate LIBMTP_PROPERTY_PhoneNumberBusiness
     LIBMTP_PROPERTY_PhoneNumberPersonal */
  /* Offset 32 gives the best switch position.  */
  switch (name[32]) {
  case 'a':
    if (memEQ(name, "LIBMTP_PROPERTY_OriginalReleaseDate", 35)) {
    /*                                               ^         */
      *iv_return = LIBMTP_PROPERTY_OriginalReleaseDate;
      return PERL_constant_ISIV;
    }
    break;
  case 'b':
    if (memEQ(name, "LIBMTP_PROPERTY_CorruptOrUnplayable", 35)) {
    /*                                               ^         */
      *iv_return = LIBMTP_PROPERTY_CorruptOrUnplayable;
      return PERL_constant_ISIV;
    }
    break;
  case 'e':
    if (memEQ(name, "LIBMTP_PROPERTY_PhoneNumberBusiness", 35)) {
    /*                                               ^         */
      *iv_return = LIBMTP_PROPERTY_PhoneNumberBusiness;
      return PERL_constant_ISIV;
    }
    break;
  case 'i':
    if (memEQ(name, "LIBMTP_PROPERTY_MessageReceivedTime", 35)) {
    /*                                               ^         */
      *iv_return = LIBMTP_PROPERTY_MessageReceivedTime;
      return PERL_constant_ISIV;
    }
    break;
  case 'n':
    if (memEQ(name, "LIBMTP_PROPERTY_PhoneNumberPersonal", 35)) {
    /*                                               ^         */
      *iv_return = LIBMTP_PROPERTY_PhoneNumberPersonal;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_36 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LIBMTP_PROPERTY_CopyrightInformation LIBMTP_PROPERTY_PhoneNumberBusiness2
     LIBMTP_PROPERTY_PhoneNumberPersonal2 LIBMTP_PROPERTY_ProducerSerialNumber
     */
  /* Offset 34 gives the best switch position.  */
  switch (name[34]) {
  case 'e':
    if (memEQ(name, "LIBMTP_PROPERTY_ProducerSerialNumber", 36)) {
    /*                                                 ^        */
      *iv_return = LIBMTP_PROPERTY_ProducerSerialNumber;
      return PERL_constant_ISIV;
    }
    break;
  case 'l':
    if (memEQ(name, "LIBMTP_PROPERTY_PhoneNumberPersonal2", 36)) {
    /*                                                 ^        */
      *iv_return = LIBMTP_PROPERTY_PhoneNumberPersonal2;
      return PERL_constant_ISIV;
    }
    break;
  case 'o':
    if (memEQ(name, "LIBMTP_PROPERTY_CopyrightInformation", 36)) {
    /*                                                 ^        */
      *iv_return = LIBMTP_PROPERTY_CopyrightInformation;
      return PERL_constant_ISIV;
    }
    break;
  case 's':
    if (memEQ(name, "LIBMTP_PROPERTY_PhoneNumberBusiness2", 36)) {
    /*                                                 ^        */
      *iv_return = LIBMTP_PROPERTY_PhoneNumberBusiness2;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_39 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LIBMTP_PROPERTY_InstantMessengerAddress
     LIBMTP_PROPERTY_PostalAddressOtherLine1
     LIBMTP_PROPERTY_PostalAddressOtherLine2 */
  /* Offset 38 gives the best switch position.  */
  switch (name[38]) {
  case '1':
    if (memEQ(name, "LIBMTP_PROPERTY_PostalAddressOtherLine", 38)) {
    /*                                                     1      */
      *iv_return = LIBMTP_PROPERTY_PostalAddressOtherLine1;
      return PERL_constant_ISIV;
    }
    break;
  case '2':
    if (memEQ(name, "LIBMTP_PROPERTY_PostalAddressOtherLine", 38)) {
    /*                                                     2      */
      *iv_return = LIBMTP_PROPERTY_PostalAddressOtherLine2;
      return PERL_constant_ISIV;
    }
    break;
  case 's':
    if (memEQ(name, "LIBMTP_PROPERTY_InstantMessengerAddres", 38)) {
    /*                                                     s      */
      *iv_return = LIBMTP_PROPERTY_InstantMessengerAddress;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_40 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LIBMTP_PROPERTY_FramesPerThousandSeconds
     LIBMTP_PROPERTY_InstantMessengerAddress2
     LIBMTP_PROPERTY_InstantMessengerAddress3
     LIBMTP_PROPERTY_PhoneticOrganizationName
     LIBMTP_PROPERTY_PostalAddressOtherRegion
     LIBMTP_PROPERTY_RepresentativeSampleData
     LIBMTP_PROPERTY_RepresentativeSampleSize */
  /* Offset 38 gives the best switch position.  */
  switch (name[38]) {
  case 'd':
    if (memEQ(name, "LIBMTP_PROPERTY_FramesPerThousandSeconds", 40)) {
    /*                                                     ^        */
      *iv_return = LIBMTP_PROPERTY_FramesPerThousandSeconds;
      return PERL_constant_ISIV;
    }
    break;
  case 'm':
    if (memEQ(name, "LIBMTP_PROPERTY_PhoneticOrganizationName", 40)) {
    /*                                                     ^        */
      *iv_return = LIBMTP_PROPERTY_PhoneticOrganizationName;
      return PERL_constant_ISIV;
    }
    break;
  case 'o':
    if (memEQ(name, "LIBMTP_PROPERTY_PostalAddressOtherRegion", 40)) {
    /*                                                     ^        */
      *iv_return = LIBMTP_PROPERTY_PostalAddressOtherRegion;
      return PERL_constant_ISIV;
    }
    break;
  case 's':
    if (memEQ(name, "LIBMTP_PROPERTY_InstantMessengerAddress2", 40)) {
    /*                                                     ^        */
      *iv_return = LIBMTP_PROPERTY_InstantMessengerAddress2;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LIBMTP_PROPERTY_InstantMessengerAddress3", 40)) {
    /*                                                     ^        */
      *iv_return = LIBMTP_PROPERTY_InstantMessengerAddress3;
      return PERL_constant_ISIV;
    }
    break;
  case 't':
    if (memEQ(name, "LIBMTP_PROPERTY_RepresentativeSampleData", 40)) {
    /*                                                     ^        */
      *iv_return = LIBMTP_PROPERTY_RepresentativeSampleData;
      return PERL_constant_ISIV;
    }
    break;
  case 'z':
    if (memEQ(name, "LIBMTP_PROPERTY_RepresentativeSampleSize", 40)) {
    /*                                                     ^        */
      *iv_return = LIBMTP_PROPERTY_RepresentativeSampleSize;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_41 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LIBMTP_PROPERTY_ActivityOptionalAttendees
     LIBMTP_PROPERTY_ActivityRequiredAttendees
     LIBMTP_PROPERTY_PostalAddressBusinessCity
     LIBMTP_PROPERTY_PostalAddressBusinessFull
     LIBMTP_PROPERTY_PostalAddressOtherCountry
     LIBMTP_PROPERTY_PostalAddressPersonalFull
     LIBMTP_PROPERTY_RepresentativeSampleWidth */
  /* Offset 31 gives the best switch position.  */
  switch (name[31]) {
  case 'a':
    if (memEQ(name, "LIBMTP_PROPERTY_RepresentativeSampleWidth", 41)) {
    /*                                              ^                */
      *iv_return = LIBMTP_PROPERTY_RepresentativeSampleWidth;
      return PERL_constant_ISIV;
    }
    break;
  case 'd':
    if (memEQ(name, "LIBMTP_PROPERTY_ActivityRequiredAttendees", 41)) {
    /*                                              ^                */
      *iv_return = LIBMTP_PROPERTY_ActivityRequiredAttendees;
      return PERL_constant_ISIV;
    }
    break;
  case 'h':
    if (memEQ(name, "LIBMTP_PROPERTY_PostalAddressOtherCountry", 41)) {
    /*                                              ^                */
      *iv_return = LIBMTP_PROPERTY_PostalAddressOtherCountry;
      return PERL_constant_ISIV;
    }
    break;
  case 'l':
    if (memEQ(name, "LIBMTP_PROPERTY_ActivityOptionalAttendees", 41)) {
    /*                                              ^                */
      *iv_return = LIBMTP_PROPERTY_ActivityOptionalAttendees;
      return PERL_constant_ISIV;
    }
    break;
  case 'r':
    if (memEQ(name, "LIBMTP_PROPERTY_PostalAddressPersonalFull", 41)) {
    /*                                              ^                */
      *iv_return = LIBMTP_PROPERTY_PostalAddressPersonalFull;
      return PERL_constant_ISIV;
    }
    break;
  case 's':
    if (memEQ(name, "LIBMTP_PROPERTY_PostalAddressBusinessCity", 41)) {
    /*                                              ^                */
      *iv_return = LIBMTP_PROPERTY_PostalAddressBusinessCity;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LIBMTP_PROPERTY_PostalAddressBusinessFull", 41)) {
    /*                                              ^                */
      *iv_return = LIBMTP_PROPERTY_PostalAddressBusinessFull;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_42 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LIBMTP_PROPERTY_PostalAddressBusinessLine1
     LIBMTP_PROPERTY_PostalAddressBusinessLine2
     LIBMTP_PROPERTY_RepresentativeSampleFormat
     LIBMTP_PROPERTY_RepresentativeSampleHeight */
  /* Offset 39 gives the best switch position.  */
  switch (name[39]) {
  case 'g':
    if (memEQ(name, "LIBMTP_PROPERTY_RepresentativeSampleHeight", 42)) {
    /*                                                      ^         */
      *iv_return = LIBMTP_PROPERTY_RepresentativeSampleHeight;
      return PERL_constant_ISIV;
    }
    break;
  case 'm':
    if (memEQ(name, "LIBMTP_PROPERTY_RepresentativeSampleFormat", 42)) {
    /*                                                      ^         */
      *iv_return = LIBMTP_PROPERTY_RepresentativeSampleFormat;
      return PERL_constant_ISIV;
    }
    break;
  case 'n':
    if (memEQ(name, "LIBMTP_PROPERTY_PostalAddressBusinessLine1", 42)) {
    /*                                                      ^         */
      *iv_return = LIBMTP_PROPERTY_PostalAddressBusinessLine1;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LIBMTP_PROPERTY_PostalAddressBusinessLine2", 42)) {
    /*                                                      ^         */
      *iv_return = LIBMTP_PROPERTY_PostalAddressBusinessLine2;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_44 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LIBMTP_PROPERTY_PostalAddressBusinessCountry
     LIBMTP_PROPERTY_PostalAddressOtherPostalCode
     LIBMTP_PROPERTY_RepresentativeSampleDuration */
  /* Offset 33 gives the best switch position.  */
  switch (name[33]) {
  case 'n':
    if (memEQ(name, "LIBMTP_PROPERTY_PostalAddressBusinessCountry", 44)) {
    /*                                                ^                 */
      *iv_return = LIBMTP_PROPERTY_PostalAddressBusinessCountry;
      return PERL_constant_ISIV;
    }
    break;
  case 'p':
    if (memEQ(name, "LIBMTP_PROPERTY_RepresentativeSampleDuration", 44)) {
    /*                                                ^                 */
      *iv_return = LIBMTP_PROPERTY_RepresentativeSampleDuration;
      return PERL_constant_ISIV;
    }
    break;
  case 'r':
    if (memEQ(name, "LIBMTP_PROPERTY_PostalAddressOtherPostalCode", 44)) {
    /*                                                ^                 */
      *iv_return = LIBMTP_PROPERTY_PostalAddressOtherPostalCode;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant (pTHX_ const char *name, STRLEN len, IV *iv_return) {
  /* Initially switch on the length of the name.  */
  /* When generated this function returned values for the list of names given
     in this section of perl code.  Rather than manually editing these functions
     to add or remove constants, which would result in this comment and section
     of code becoming inaccurate, we recommend that you edit this section of
     code, and use it to regenerate a new set of constant functions which you
     then use to replace the originals.

     Regenerate these constant functions by feeding this entire source file to
     perl -x

#!/usr/bin/perl5.14.2 -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(LIBMTP_DEBUG_ALL LIBMTP_DEBUG_DATA LIBMTP_DEBUG_NONE
	       LIBMTP_DEBUG_PLST LIBMTP_DEBUG_PTP LIBMTP_DEBUG_USB
	       LIBMTP_STORAGE_SORTBY_FREESPACE LIBMTP_STORAGE_SORTBY_MAXSPACE
	       LIBMTP_STORAGE_SORTBY_NOTSORTED),
            {name=>"LIBMTP_DATATYPE_INT16", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_DATATYPE_INT32", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_DATATYPE_INT64", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_DATATYPE_INT8", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_DATATYPE_UINT16", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_DATATYPE_UINT32", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_DATATYPE_UINT64", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_DATATYPE_UINT8", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_ERROR_CANCELLED", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_ERROR_CONNECTING", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_ERROR_GENERAL", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_ERROR_MEMORY_ALLOCATION", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_ERROR_NONE", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_ERROR_NO_DEVICE_ATTACHED", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_ERROR_PTP_LAYER", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_ERROR_STORAGE_FULL", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_ERROR_USB_LAYER", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_AAC", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_ALBUM", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_ASF", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_AUDIBLE", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_AVI", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_BMP", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_DOC", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_FIRMWARE", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_FLAC", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_FOLDER", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_GIF", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_HTML", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_JFIF", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_JP2", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_JPEG", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_JPX", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_M4A", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_MEDIACARD", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_MHT", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_MP2", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_MP3", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_MP4", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_MPEG", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_OGG", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_PICT", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_PLAYLIST", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_PNG", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_PPT", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_QT", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_TEXT", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_TIFF", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_UNDEF_AUDIO", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_UNDEF_VIDEO", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_UNKNOWN", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_VCALENDAR1", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_VCALENDAR2", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_VCARD2", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_VCARD3", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_WAV", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_WINDOWSIMAGEFORMAT", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_WINEXEC", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_WMA", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_WMV", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_XLS", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_FILETYPE_XML", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_HANDLER_RETURN_CANCEL", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_HANDLER_RETURN_ERROR", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_HANDLER_RETURN_OK", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_ActivityAccepted", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_ActivityBeginTime", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_ActivityEndTime", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_ActivityLocation", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_ActivityOptionalAttendees", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_ActivityRequiredAttendees", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_ActivityResources", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_AlbumArtist", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_AlbumName", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_AllowedFolderContents", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_Artist", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_AssociationDesc", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_AssociationType", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_AudioBitDepth", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_AudioBitRate", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_AudioWAVECodec", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_Birthdate", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_BitRateType", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_BodyText", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_BufferSize", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_BusinessWebAddress", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_BuyFlag", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_ByteBookmark", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_Composer", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_CopyrightInformation", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_CorruptOrUnplayable", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_CreatedBy", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_Credits", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_DRMStatus", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_DateAdded", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_DateAuthored", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_DateCreated", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_DateModified", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_Description", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_DisplayName", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_Duration", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_Editor", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_EffectiveRating", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_EmailBusiness1", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_EmailBusiness2", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_EmailOthers", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_EmailPersonal1", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_EmailPersonal2", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_EmailPrimary", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_EncodingProfile", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_EncodingQuality", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_ExposureIndex", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_ExposureTime", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_FamilyName", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_FaxNumberBusiness", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_FaxNumberPersonal", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_FaxNumberPrimary", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_Fnumber", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_FramesPerThousandSeconds", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_Genre", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_GivenName", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_Height", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_Hidden", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_ImageBitDepth", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_InstantMessengerAddress", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_InstantMessengerAddress2", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_InstantMessengerAddress3", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_IsColorCorrected", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_IsCropped", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_KeyFrameDistance", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_Keywords", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_LanguageLocale", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_LastAccessed", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_LastBuildDate", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_Lyrics", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_MediaGUID", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_MessageBCC", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_MessageCC", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_MessageRead", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_MessageReceivedTime", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_MessageSender", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_MessageTo", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_MetaGenre", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_MiddleNames", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_Mood", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_Name", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_NonConsumable", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_NumberOfChannels", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_ObjectBookmark", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_ObjectFileName", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_ObjectFormat", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_ObjectSize", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_OrganizationName", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_OriginLocation", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_OriginalReleaseDate", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_Owner", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_PagerNumber", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_ParentObject", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_ParentalRating", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_PersistantUniqueObjectIdentifier", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_PersonalWebAddress", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_PhoneNumberBusiness", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_PhoneNumberBusiness2", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_PhoneNumberMobile", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_PhoneNumberMobile2", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_PhoneNumberOthers", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_PhoneNumberPersonal", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_PhoneNumberPersonal2", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_PhoneNumberPrimary", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_PhoneticFamilyName", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_PhoneticGivenName", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_PhoneticOrganizationName", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_PostalAddressBusinessCity", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_PostalAddressBusinessCountry", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_PostalAddressBusinessFull", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_PostalAddressBusinessLine1", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_PostalAddressBusinessLine2", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_PostalAddressBusinessPostalCode", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_PostalAddressBusinessRegion", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_PostalAddressOtherCity", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_PostalAddressOtherCountry", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_PostalAddressOtherFull", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_PostalAddressOtherLine1", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_PostalAddressOtherLine2", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_PostalAddressOtherPostalCode", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_PostalAddressOtherRegion", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_PostalAddressPersonalFull", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_PostalAddressPersonalFullCity", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_PostalAddressPersonalFullCountry", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_PostalAddressPersonalFullLine1", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_PostalAddressPersonalFullLine2", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_PostalAddressPersonalFullPostalCode", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_PostalAddressPersonalFullRegion", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_Prefix", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_PrimaryWebAddress", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_Priority", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_ProducedBy", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_ProducerSerialNumber", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_PropertyBag", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_ProtectionStatus", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_Rating", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_RepresentativeSampleData", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_RepresentativeSampleDuration", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_RepresentativeSampleFormat", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_RepresentativeSampleHeight", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_RepresentativeSampleSize", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_RepresentativeSampleWidth", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_Role", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_SampleRate", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_ScanDepth", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_SkipCount", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_Source", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_StorageID", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_SubDescription", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_Subject", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_SubscriptionContentID", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_Subtitle", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_Suffix", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_SyncID", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_SystemObject", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_TimeBookmark", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_TimetoLive", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_TotalBitRate", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_Track", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_UNKNOWN", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_URLDestination", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_URLReference", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_URLSource", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_UseCount", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_VideoBitRate", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_VideoFourCCCodec", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_Webmaster", type=>"IV", macro=>"1"},
            {name=>"LIBMTP_PROPERTY_Width", type=>"IV", macro=>"1"});

print constant_types(), "\n"; # macro defs
foreach (C_constant ("Media::LibMTP::API", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("Media::LibMTP::API", $types);
__END__
   */

  switch (len) {
  case 16:
    return constant_16 (aTHX_ name, iv_return);
    break;
  case 17:
    return constant_17 (aTHX_ name, iv_return);
    break;
  case 18:
    if (memEQ(name, "LIBMTP_FILETYPE_QT", 18)) {
      *iv_return = LIBMTP_FILETYPE_QT;
      return PERL_constant_ISIV;
    }
    break;
  case 19:
    return constant_19 (aTHX_ name, iv_return);
    break;
  case 20:
    return constant_20 (aTHX_ name, iv_return);
    break;
  case 21:
    return constant_21 (aTHX_ name, iv_return);
    break;
  case 22:
    return constant_22 (aTHX_ name, iv_return);
    break;
  case 23:
    return constant_23 (aTHX_ name, iv_return);
    break;
  case 24:
    return constant_24 (aTHX_ name, iv_return);
    break;
  case 25:
    return constant_25 (aTHX_ name, iv_return);
    break;
  case 26:
    return constant_26 (aTHX_ name, iv_return);
    break;
  case 27:
    return constant_27 (aTHX_ name, iv_return);
    break;
  case 28:
    return constant_28 (aTHX_ name, iv_return);
    break;
  case 29:
    return constant_29 (aTHX_ name, iv_return);
    break;
  case 30:
    return constant_30 (aTHX_ name, iv_return);
    break;
  case 31:
    return constant_31 (aTHX_ name, iv_return);
    break;
  case 32:
    return constant_32 (aTHX_ name, iv_return);
    break;
  case 33:
    return constant_33 (aTHX_ name, iv_return);
    break;
  case 34:
    return constant_34 (aTHX_ name, iv_return);
    break;
  case 35:
    return constant_35 (aTHX_ name, iv_return);
    break;
  case 36:
    return constant_36 (aTHX_ name, iv_return);
    break;
  case 37:
    /* Names all of length 37.  */
    /* LIBMTP_PROPERTY_AllowedFolderContents
       LIBMTP_PROPERTY_SubscriptionContentID */
    /* Offset 30 gives the best switch position.  */
    switch (name[30]) {
    case 'n':
      if (memEQ(name, "LIBMTP_PROPERTY_SubscriptionContentID", 37)) {
      /*                                             ^             */
        *iv_return = LIBMTP_PROPERTY_SubscriptionContentID;
        return PERL_constant_ISIV;
      }
      break;
    case 'o':
      if (memEQ(name, "LIBMTP_PROPERTY_AllowedFolderContents", 37)) {
      /*                                             ^             */
        *iv_return = LIBMTP_PROPERTY_AllowedFolderContents;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 38:
    /* Names all of length 38.  */
    /* LIBMTP_PROPERTY_PostalAddressOtherCity
       LIBMTP_PROPERTY_PostalAddressOtherFull */
    /* Offset 34 gives the best switch position.  */
    switch (name[34]) {
    case 'C':
      if (memEQ(name, "LIBMTP_PROPERTY_PostalAddressOtherCity", 38)) {
      /*                                                 ^          */
        *iv_return = LIBMTP_PROPERTY_PostalAddressOtherCity;
        return PERL_constant_ISIV;
      }
      break;
    case 'F':
      if (memEQ(name, "LIBMTP_PROPERTY_PostalAddressOtherFull", 38)) {
      /*                                                 ^          */
        *iv_return = LIBMTP_PROPERTY_PostalAddressOtherFull;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 39:
    return constant_39 (aTHX_ name, iv_return);
    break;
  case 40:
    return constant_40 (aTHX_ name, iv_return);
    break;
  case 41:
    return constant_41 (aTHX_ name, iv_return);
    break;
  case 42:
    return constant_42 (aTHX_ name, iv_return);
    break;
  case 43:
    if (memEQ(name, "LIBMTP_PROPERTY_PostalAddressBusinessRegion", 43)) {
      *iv_return = LIBMTP_PROPERTY_PostalAddressBusinessRegion;
      return PERL_constant_ISIV;
    }
    break;
  case 44:
    return constant_44 (aTHX_ name, iv_return);
    break;
  case 45:
    if (memEQ(name, "LIBMTP_PROPERTY_PostalAddressPersonalFullCity", 45)) {
      *iv_return = LIBMTP_PROPERTY_PostalAddressPersonalFullCity;
      return PERL_constant_ISIV;
    }
    break;
  case 46:
    /* Names all of length 46.  */
    /* LIBMTP_PROPERTY_PostalAddressPersonalFullLine1
       LIBMTP_PROPERTY_PostalAddressPersonalFullLine2 */
    /* Offset 45 gives the best switch position.  */
    switch (name[45]) {
    case '1':
      if (memEQ(name, "LIBMTP_PROPERTY_PostalAddressPersonalFullLine", 45)) {
      /*                                                            1      */
        *iv_return = LIBMTP_PROPERTY_PostalAddressPersonalFullLine1;
        return PERL_constant_ISIV;
      }
      break;
    case '2':
      if (memEQ(name, "LIBMTP_PROPERTY_PostalAddressPersonalFullLine", 45)) {
      /*                                                            2      */
        *iv_return = LIBMTP_PROPERTY_PostalAddressPersonalFullLine2;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 47:
    /* Names all of length 47.  */
    /* LIBMTP_PROPERTY_PostalAddressBusinessPostalCode
       LIBMTP_PROPERTY_PostalAddressPersonalFullRegion */
    /* Offset 31 gives the best switch position.  */
    switch (name[31]) {
    case 'r':
      if (memEQ(name, "LIBMTP_PROPERTY_PostalAddressPersonalFullRegion", 47)) {
      /*                                              ^                      */
        *iv_return = LIBMTP_PROPERTY_PostalAddressPersonalFullRegion;
        return PERL_constant_ISIV;
      }
      break;
    case 's':
      if (memEQ(name, "LIBMTP_PROPERTY_PostalAddressBusinessPostalCode", 47)) {
      /*                                              ^                      */
        *iv_return = LIBMTP_PROPERTY_PostalAddressBusinessPostalCode;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 48:
    /* Names all of length 48.  */
    /* LIBMTP_PROPERTY_PersistantUniqueObjectIdentifier
       LIBMTP_PROPERTY_PostalAddressPersonalFullCountry */
    /* Offset 18 gives the best switch position.  */
    switch (name[18]) {
    case 'r':
      if (memEQ(name, "LIBMTP_PROPERTY_PersistantUniqueObjectIdentifier", 48)) {
      /*                                 ^                                    */
        *iv_return = LIBMTP_PROPERTY_PersistantUniqueObjectIdentifier;
        return PERL_constant_ISIV;
      }
      break;
    case 's':
      if (memEQ(name, "LIBMTP_PROPERTY_PostalAddressPersonalFullCountry", 48)) {
      /*                                 ^                                    */
        *iv_return = LIBMTP_PROPERTY_PostalAddressPersonalFullCountry;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 51:
    if (memEQ(name, "LIBMTP_PROPERTY_PostalAddressPersonalFullPostalCode", 51)) {
      *iv_return = LIBMTP_PROPERTY_PostalAddressPersonalFullPostalCode;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

