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
constant_8 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     MDB_LAST MDB_NEXT MDB_PREV */
  /* Offset 4 gives the best switch position.  */
  switch (name[4]) {
  case 'L':
    if (memEQ(name, "MDB_LAST", 8)) {
    /*                   ^         */
      *iv_return = MDB_LAST;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "MDB_NEXT", 8)) {
    /*                   ^         */
      *iv_return = MDB_NEXT;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "MDB_PREV", 8)) {
    /*                   ^         */
      *iv_return = MDB_PREV;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_9 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     MDB_FIRST MDB_NOTLS MDB_PANIC */
  /* Offset 6 gives the best switch position.  */
  switch (name[6]) {
  case 'N':
    if (memEQ(name, "MDB_PANIC", 9)) {
    /*                     ^        */
#ifdef MDB_PANIC
      *iv_return = MDB_PANIC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "MDB_FIRST", 9)) {
    /*                     ^        */
      *iv_return = MDB_FIRST;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "MDB_NOTLS", 9)) {
    /*                     ^        */
#ifdef MDB_NOTLS
      *iv_return = MDB_NOTLS;
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
constant_10 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     MDB_APPEND MDB_CREATE MDB_NOLOCK MDB_NOSYNC MDB_RDONLY */
  /* Offset 6 gives the best switch position.  */
  switch (name[6]) {
  case 'E':
    if (memEQ(name, "MDB_CREATE", 10)) {
    /*                     ^          */
#ifdef MDB_CREATE
      *iv_return = MDB_CREATE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "MDB_NOLOCK", 10)) {
    /*                     ^          */
#ifdef MDB_NOLOCK
      *iv_return = MDB_NOLOCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "MDB_RDONLY", 10)) {
    /*                     ^          */
#ifdef MDB_RDONLY
      *iv_return = MDB_RDONLY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "MDB_APPEND", 10)) {
    /*                     ^          */
#ifdef MDB_APPEND
      *iv_return = MDB_APPEND;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "MDB_NOSYNC", 10)) {
    /*                     ^          */
#ifdef MDB_NOSYNC
      *iv_return = MDB_NOSYNC;
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
constant_11 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LMDB_OFLAGN MDB_BAD_DBI MDB_BAD_TXN MDB_CURRENT MDB_DUPSORT MDB_INVALID
     MDB_RESERVE MDB_SET_KEY MDB_SUCCESS */
  /* Offset 9 gives the best switch position.  */
  switch (name[9]) {
  case 'B':
    if (memEQ(name, "MDB_BAD_DBI", 11)) {
    /*                        ^        */
#ifdef MDB_BAD_DBI
      *iv_return = MDB_BAD_DBI;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "MDB_SET_KEY", 11)) {
    /*                        ^        */
      *iv_return = MDB_SET_KEY;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "LMDB_OFLAGN", 11)) {
    /*                        ^        */
#ifdef LMDB_OFLAGN
      *iv_return = LMDB_OFLAGN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "MDB_INVALID", 11)) {
    /*                        ^        */
#ifdef MDB_INVALID
      *iv_return = MDB_INVALID;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "MDB_CURRENT", 11)) {
    /*                        ^        */
#ifdef MDB_CURRENT
      *iv_return = MDB_CURRENT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "MDB_DUPSORT", 11)) {
    /*                        ^        */
#ifdef MDB_DUPSORT
      *iv_return = MDB_DUPSORT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "MDB_SUCCESS", 11)) {
    /*                        ^        */
#ifdef MDB_SUCCESS
      *iv_return = MDB_SUCCESS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "MDB_RESERVE", 11)) {
    /*                        ^        */
#ifdef MDB_RESERVE
      *iv_return = MDB_RESERVE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "MDB_BAD_TXN", 11)) {
    /*                        ^        */
#ifdef MDB_BAD_TXN
      *iv_return = MDB_BAD_TXN;
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
constant_12 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     MDB_DBS_FULL MDB_DUPFIXED MDB_FIXEDMAP MDB_GET_BOTH MDB_KEYEXIST
     MDB_LAST_DUP MDB_MAPASYNC MDB_MAP_FULL MDB_MULTIPLE MDB_NEXT_DUP
     MDB_NOSUBDIR MDB_NOTFOUND MDB_PREV_DUP MDB_TLS_FULL MDB_TXN_FULL
     MDB_WRITEMAP */
  /* Offset 4 gives the best switch position.  */
  switch (name[4]) {
  case 'D':
    if (memEQ(name, "MDB_DBS_FULL", 12)) {
    /*                   ^              */
#ifdef MDB_DBS_FULL
      *iv_return = MDB_DBS_FULL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "MDB_DUPFIXED", 12)) {
    /*                   ^              */
#ifdef MDB_DUPFIXED
      *iv_return = MDB_DUPFIXED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "MDB_FIXEDMAP", 12)) {
    /*                   ^              */
#ifdef MDB_FIXEDMAP
      *iv_return = MDB_FIXEDMAP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "MDB_GET_BOTH", 12)) {
    /*                   ^              */
      *iv_return = MDB_GET_BOTH;
      return PERL_constant_ISIV;
    }
    break;
  case 'K':
    if (memEQ(name, "MDB_KEYEXIST", 12)) {
    /*                   ^              */
#ifdef MDB_KEYEXIST
      *iv_return = MDB_KEYEXIST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "MDB_LAST_DUP", 12)) {
    /*                   ^              */
      *iv_return = MDB_LAST_DUP;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "MDB_MAPASYNC", 12)) {
    /*                   ^              */
#ifdef MDB_MAPASYNC
      *iv_return = MDB_MAPASYNC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "MDB_MAP_FULL", 12)) {
    /*                   ^              */
#ifdef MDB_MAP_FULL
      *iv_return = MDB_MAP_FULL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "MDB_MULTIPLE", 12)) {
    /*                   ^              */
#ifdef MDB_MULTIPLE
      *iv_return = MDB_MULTIPLE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "MDB_NEXT_DUP", 12)) {
    /*                   ^              */
      *iv_return = MDB_NEXT_DUP;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "MDB_NOSUBDIR", 12)) {
    /*                   ^              */
#ifdef MDB_NOSUBDIR
      *iv_return = MDB_NOSUBDIR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "MDB_NOTFOUND", 12)) {
    /*                   ^              */
#ifdef MDB_NOTFOUND
      *iv_return = MDB_NOTFOUND;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "MDB_PREV_DUP", 12)) {
    /*                   ^              */
      *iv_return = MDB_PREV_DUP;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "MDB_TLS_FULL", 12)) {
    /*                   ^              */
#ifdef MDB_TLS_FULL
      *iv_return = MDB_TLS_FULL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "MDB_TXN_FULL", 12)) {
    /*                   ^              */
#ifdef MDB_TXN_FULL
      *iv_return = MDB_TXN_FULL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'W':
    if (memEQ(name, "MDB_WRITEMAP", 12)) {
    /*                   ^              */
#ifdef MDB_WRITEMAP
      *iv_return = MDB_WRITEMAP;
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
constant_13 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     MDB_APPENDDUP MDB_BAD_RSLOT MDB_CORRUPTED MDB_FIRST_DUP MDB_NODUPDATA
     MDB_NOMEMINIT MDB_NORDAHEAD MDB_PAGE_FULL MDB_SET_RANGE */
  /* Offset 11 gives the best switch position.  */
  switch (name[11]) {
  case 'A':
    if (memEQ(name, "MDB_NORDAHEAD", 13)) {
    /*                          ^        */
#ifdef MDB_NORDAHEAD
      *iv_return = MDB_NORDAHEAD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "MDB_CORRUPTED", 13)) {
    /*                          ^        */
#ifdef MDB_CORRUPTED
      *iv_return = MDB_CORRUPTED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "MDB_SET_RANGE", 13)) {
    /*                          ^        */
      *iv_return = MDB_SET_RANGE;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "MDB_NOMEMINIT", 13)) {
    /*                          ^        */
#ifdef MDB_NOMEMINIT
      *iv_return = MDB_NOMEMINIT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "MDB_PAGE_FULL", 13)) {
    /*                          ^        */
#ifdef MDB_PAGE_FULL
      *iv_return = MDB_PAGE_FULL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "MDB_BAD_RSLOT", 13)) {
    /*                          ^        */
#ifdef MDB_BAD_RSLOT
      *iv_return = MDB_BAD_RSLOT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "MDB_NODUPDATA", 13)) {
    /*                          ^        */
#ifdef MDB_NODUPDATA
      *iv_return = MDB_NODUPDATA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "MDB_APPENDDUP", 13)) {
    /*                          ^        */
#ifdef MDB_APPENDDUP
      *iv_return = MDB_APPENDDUP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "MDB_FIRST_DUP", 13)) {
    /*                          ^        */
      *iv_return = MDB_FIRST_DUP;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_14 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     MDB_CP_COMPACT MDB_INTEGERDUP MDB_INTEGERKEY MDB_NEXT_NODUP MDB_NOMETASYNC
     MDB_PREV_NODUP MDB_REVERSEDUP MDB_REVERSEKEY */
  /* Offset 6 gives the best switch position.  */
  switch (name[6]) {
  case 'E':
    if (memEQ(name, "MDB_PREV_NODUP", 14)) {
    /*                     ^              */
      *iv_return = MDB_PREV_NODUP;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "MDB_NOMETASYNC", 14)) {
    /*                     ^              */
#ifdef MDB_NOMETASYNC
      *iv_return = MDB_NOMETASYNC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "MDB_INTEGERDUP", 14)) {
    /*                     ^              */
#ifdef MDB_INTEGERDUP
      *iv_return = MDB_INTEGERDUP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "MDB_INTEGERKEY", 14)) {
    /*                     ^              */
#ifdef MDB_INTEGERKEY
      *iv_return = MDB_INTEGERKEY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "MDB_REVERSEDUP", 14)) {
    /*                     ^              */
#ifdef MDB_REVERSEDUP
      *iv_return = MDB_REVERSEDUP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "MDB_REVERSEKEY", 14)) {
    /*                     ^              */
#ifdef MDB_REVERSEKEY
      *iv_return = MDB_REVERSEKEY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "MDB_NEXT_NODUP", 14)) {
    /*                     ^              */
      *iv_return = MDB_NEXT_NODUP;
      return PERL_constant_ISIV;
    }
    break;
  case '_':
    if (memEQ(name, "MDB_CP_COMPACT", 14)) {
    /*                     ^              */
#ifdef MDB_CP_COMPACT
      *iv_return = MDB_CP_COMPACT;
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
constant_15 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     MDB_BAD_VALSIZE MDB_CURSOR_FULL MDB_GET_CURRENT MDB_MAP_RESIZED
     MDB_NOOVERWRITE */
  /* Offset 4 gives the best switch position.  */
  switch (name[4]) {
  case 'B':
    if (memEQ(name, "MDB_BAD_VALSIZE", 15)) {
    /*                   ^                 */
#ifdef MDB_BAD_VALSIZE
      *iv_return = MDB_BAD_VALSIZE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "MDB_CURSOR_FULL", 15)) {
    /*                   ^                 */
#ifdef MDB_CURSOR_FULL
      *iv_return = MDB_CURSOR_FULL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "MDB_GET_CURRENT", 15)) {
    /*                   ^                 */
      *iv_return = MDB_GET_CURRENT;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "MDB_MAP_RESIZED", 15)) {
    /*                   ^                 */
#ifdef MDB_MAP_RESIZED
      *iv_return = MDB_MAP_RESIZED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "MDB_NOOVERWRITE", 15)) {
    /*                   ^                 */
#ifdef MDB_NOOVERWRITE
      *iv_return = MDB_NOOVERWRITE;
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
constant_16 (pTHX_ const char *name, IV *iv_return, const char **pv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     MDB_GET_MULTIPLE MDB_INCOMPATIBLE MDB_LAST_ERRCODE MDB_READERS_FULL
     MDB_VERSION_DATE MDB_VERSION_FULL */
  /* Offset 4 gives the best switch position.  */
  switch (name[4]) {
  case 'G':
    if (memEQ(name, "MDB_GET_MULTIPLE", 16)) {
    /*                   ^                  */
      *iv_return = MDB_GET_MULTIPLE;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "MDB_INCOMPATIBLE", 16)) {
    /*                   ^                  */
#ifdef MDB_INCOMPATIBLE
      *iv_return = MDB_INCOMPATIBLE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "MDB_LAST_ERRCODE", 16)) {
    /*                   ^                  */
#ifdef MDB_LAST_ERRCODE
      *iv_return = MDB_LAST_ERRCODE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "MDB_READERS_FULL", 16)) {
    /*                   ^                  */
#ifdef MDB_READERS_FULL
      *iv_return = MDB_READERS_FULL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "MDB_VERSION_DATE", 16)) {
    /*                   ^                  */
      *pv_return = MDB_VERSION_DATE;
      return PERL_constant_ISPV;
    }
    if (memEQ(name, "MDB_VERSION_FULL", 16)) {
    /*                   ^                  */
#ifdef MDB_VERSION_FULL
      *iv_return = MDB_VERSION_FULL;
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
     MDB_NEXT_MULTIPLE MDB_PAGE_NOTFOUND MDB_VERSION_MAJOR MDB_VERSION_MINOR
     MDB_VERSION_PATCH */
  /* Offset 14 gives the best switch position.  */
  switch (name[14]) {
  case 'J':
    if (memEQ(name, "MDB_VERSION_MAJOR", 17)) {
    /*                             ^         */
#ifdef MDB_VERSION_MAJOR
      *iv_return = MDB_VERSION_MAJOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "MDB_VERSION_MINOR", 17)) {
    /*                             ^         */
#ifdef MDB_VERSION_MINOR
      *iv_return = MDB_VERSION_MINOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "MDB_NEXT_MULTIPLE", 17)) {
    /*                             ^         */
      *iv_return = MDB_NEXT_MULTIPLE;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "MDB_VERSION_PATCH", 17)) {
    /*                             ^         */
#ifdef MDB_VERSION_PATCH
      *iv_return = MDB_VERSION_PATCH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "MDB_PAGE_NOTFOUND", 17)) {
    /*                             ^         */
#ifdef MDB_PAGE_NOTFOUND
      *iv_return = MDB_PAGE_NOTFOUND;
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
constant (pTHX_ const char *name, STRLEN len, IV *iv_return, const char **pv_return) {
  /* Initially switch on the length of the name.  */
  /* When generated this function returned values for the list of names given
     in this section of perl code.  Rather than manually editing these functions
     to add or remove constants, which would result in this comment and section
     of code becoming inaccurate, we recommend that you edit this section of
     code, and use it to regenerate a new set of constant functions which you
     then use to replace the originals.

     Regenerate these constant functions by feeding this entire source file to
     perl -x

#!/usr/bin/perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV PV)};
my @names = (qw(LMDB_OFLAGN MDB_APPEND MDB_APPENDDUP MDB_BAD_DBI MDB_BAD_RSLOT
	       MDB_BAD_TXN MDB_BAD_VALSIZE MDB_CORRUPTED MDB_CP_COMPACT
	       MDB_CREATE MDB_CURRENT MDB_CURSOR_FULL MDB_DBS_FULL MDB_DUPFIXED
	       MDB_DUPSORT MDB_FIXEDMAP MDB_INCOMPATIBLE MDB_INTEGERDUP
	       MDB_INTEGERKEY MDB_INVALID MDB_KEYEXIST MDB_LAST_ERRCODE
	       MDB_MAPASYNC MDB_MAP_FULL MDB_MAP_RESIZED MDB_MULTIPLE
	       MDB_NODUPDATA MDB_NOLOCK MDB_NOMEMINIT MDB_NOMETASYNC
	       MDB_NOOVERWRITE MDB_NORDAHEAD MDB_NOSUBDIR MDB_NOSYNC
	       MDB_NOTFOUND MDB_NOTLS MDB_PAGE_FULL MDB_PAGE_NOTFOUND MDB_PANIC
	       MDB_RDONLY MDB_READERS_FULL MDB_RESERVE MDB_REVERSEDUP
	       MDB_REVERSEKEY MDB_SUCCESS MDB_TLS_FULL MDB_TXN_FULL
	       MDB_VERSION_FULL MDB_VERSION_MAJOR MDB_VERSION_MINOR
	       MDB_VERSION_MISMATCH MDB_VERSION_PATCH MDB_WRITEMAP),
            {name=>"MDB_FIRST", type=>"IV", macro=>"1"},
            {name=>"MDB_FIRST_DUP", type=>"IV", macro=>"1"},
            {name=>"MDB_GET_BOTH", type=>"IV", macro=>"1"},
            {name=>"MDB_GET_BOTH_RANGE", type=>"IV", macro=>"1"},
            {name=>"MDB_GET_CURRENT", type=>"IV", macro=>"1"},
            {name=>"MDB_GET_MULTIPLE", type=>"IV", macro=>"1"},
            {name=>"MDB_LAST", type=>"IV", macro=>"1"},
            {name=>"MDB_LAST_DUP", type=>"IV", macro=>"1"},
            {name=>"MDB_NEXT", type=>"IV", macro=>"1"},
            {name=>"MDB_NEXT_DUP", type=>"IV", macro=>"1"},
            {name=>"MDB_NEXT_MULTIPLE", type=>"IV", macro=>"1"},
            {name=>"MDB_NEXT_NODUP", type=>"IV", macro=>"1"},
            {name=>"MDB_PREV", type=>"IV", macro=>"1"},
            {name=>"MDB_PREV_DUP", type=>"IV", macro=>"1"},
            {name=>"MDB_PREV_NODUP", type=>"IV", macro=>"1"},
            {name=>"MDB_SET", type=>"IV", macro=>"1"},
            {name=>"MDB_SET_KEY", type=>"IV", macro=>"1"},
            {name=>"MDB_SET_RANGE", type=>"IV", macro=>"1"},
            {name=>"MDB_VERSION_DATE", type=>"PV", macro=>"1"},
            {name=>"MDB_VERSION_STRING", type=>"PV", macro=>"1"});

print constant_types(), "\n"; # macro defs
foreach (C_constant ("LMDB_File", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("LMDB_File", $types);
__END__
   */

  switch (len) {
  case 7:
    if (memEQ(name, "MDB_SET", 7)) {
      *iv_return = MDB_SET;
      return PERL_constant_ISIV;
    }
    break;
  case 8:
    return constant_8 (aTHX_ name, iv_return);
    break;
  case 9:
    return constant_9 (aTHX_ name, iv_return);
    break;
  case 10:
    return constant_10 (aTHX_ name, iv_return);
    break;
  case 11:
    return constant_11 (aTHX_ name, iv_return);
    break;
  case 12:
    return constant_12 (aTHX_ name, iv_return);
    break;
  case 13:
    return constant_13 (aTHX_ name, iv_return);
    break;
  case 14:
    return constant_14 (aTHX_ name, iv_return);
    break;
  case 15:
    return constant_15 (aTHX_ name, iv_return);
    break;
  case 16:
    return constant_16 (aTHX_ name, iv_return, pv_return);
    break;
  case 17:
    return constant_17 (aTHX_ name, iv_return);
    break;
  case 18:
    /* Names all of length 18.  */
    /* MDB_GET_BOTH_RANGE MDB_VERSION_STRING */
    /* Offset 17 gives the best switch position.  */
    switch (name[17]) {
    case 'E':
      if (memEQ(name, "MDB_GET_BOTH_RANG", 17)) {
      /*                                E      */
        *iv_return = MDB_GET_BOTH_RANGE;
        return PERL_constant_ISIV;
      }
      break;
    case 'G':
      if (memEQ(name, "MDB_VERSION_STRIN", 17)) {
      /*                                G      */
        *pv_return = MDB_VERSION_STRING;
        return PERL_constant_ISPV;
      }
      break;
    }
    break;
  case 20:
    if (memEQ(name, "MDB_VERSION_MISMATCH", 20)) {
#ifdef MDB_VERSION_MISMATCH
      *iv_return = MDB_VERSION_MISMATCH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

