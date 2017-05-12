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
constant_7 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CDC_DVD CDC_MCN CD_MINS CD_SECS */
  /* Offset 4 gives the best switch position.  */
  switch (name[4]) {
  case 'D':
    if (memEQ(name, "CDC_DVD", 7)) {
    /*                   ^        */
#ifdef CDC_DVD
      *iv_return = CDC_DVD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "CD_SECS", 7)) {
    /*                   ^        */
#ifdef CD_SECS
      *iv_return = CD_SECS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "CD_MINS", 7)) {
    /*                   ^        */
#ifdef CD_MINS
      *iv_return = CD_MINS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "CDC_MCN", 7)) {
    /*                   ^        */
#ifdef CDC_MCN
      *iv_return = CDC_MCN;
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
constant_8 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CDC_CD_R CDC_LOCK CDO_LOCK DVD_AUTH */
  /* Offset 7 gives the best switch position.  */
  switch (name[7]) {
  case 'H':
    if (memEQ(name, "DVD_AUT", 7)) {
    /*                      H     */
#ifdef DVD_AUTH
      *iv_return = DVD_AUTH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'K':
    if (memEQ(name, "CDC_LOC", 7)) {
    /*                      K     */
#ifdef CDC_LOCK
      *iv_return = CDC_LOCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CDO_LOC", 7)) {
    /*                      K     */
#ifdef CDO_LOCK
      *iv_return = CDO_LOCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "CDC_CD_", 7)) {
    /*                      R     */
#ifdef CDC_CD_R
      *iv_return = CDC_CD_R;
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
constant_9 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CDC_CD_RW CDC_DVD_R CDC_RESET CDROMSEEK CDROMSTOP CDROM_LBA CDROM_MSF
     CDSL_NONE CDS_AUDIO CDS_MIXED CD_FRAMES */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'A':
    if (memEQ(name, "CDROM_LB", 8)) {
    /*                       A     */
#ifdef CDROM_LBA
      *iv_return = CDROM_LBA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "CDS_MIXE", 8)) {
    /*                       D     */
#ifdef CDS_MIXED
      *iv_return = CDS_MIXED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "CDSL_NON", 8)) {
    /*                       E     */
#ifdef CDSL_NONE
      *iv_return = CDSL_NONE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "CDROM_MS", 8)) {
    /*                       F     */
#ifdef CDROM_MSF
      *iv_return = CDROM_MSF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'K':
    if (memEQ(name, "CDROMSEE", 8)) {
    /*                       K     */
#ifdef CDROMSEEK
      *iv_return = CDROMSEEK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "CDS_AUDI", 8)) {
    /*                       O     */
#ifdef CDS_AUDIO
      *iv_return = CDS_AUDIO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "CDROMSTO", 8)) {
    /*                       P     */
#ifdef CDROMSTOP
      *iv_return = CDROMSTOP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "CDC_DVD_", 8)) {
    /*                       R     */
#ifdef CDC_DVD_R
      *iv_return = CDC_DVD_R;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "CD_FRAME", 8)) {
    /*                       S     */
#ifdef CD_FRAMES
      *iv_return = CD_FRAMES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "CDC_RESE", 8)) {
    /*                       T     */
#ifdef CDC_RESET
      *iv_return = CDC_RESET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'W':
    if (memEQ(name, "CDC_CD_R", 8)) {
    /*                       W     */
#ifdef CDC_CD_RW
      *iv_return = CDC_CD_RW;
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
     CDC_IOCTLS CDROMEJECT CDROMPAUSE CDROMRESET CDROMSTART CDS_DATA_1
     CDS_DATA_2 CDS_XA_2_1 CDS_XA_2_2 CD_XA_HEAD CD_XA_TAIL DVD_LAYERS
     GPCMD_SCAN GPCMD_SEEK */
  /* Offset 9 gives the best switch position.  */
  switch (name[9]) {
  case '1':
    if (memEQ(name, "CDS_DATA_", 9)) {
    /*                        1     */
#ifdef CDS_DATA_1
      *iv_return = CDS_DATA_1;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CDS_XA_2_", 9)) {
    /*                        1     */
#ifdef CDS_XA_2_1
      *iv_return = CDS_XA_2_1;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '2':
    if (memEQ(name, "CDS_DATA_", 9)) {
    /*                        2     */
#ifdef CDS_DATA_2
      *iv_return = CDS_DATA_2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CDS_XA_2_", 9)) {
    /*                        2     */
#ifdef CDS_XA_2_2
      *iv_return = CDS_XA_2_2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "CD_XA_HEA", 9)) {
    /*                        D     */
#ifdef CD_XA_HEAD
      *iv_return = CD_XA_HEAD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "CDROMPAUS", 9)) {
    /*                        E     */
#ifdef CDROMPAUSE
      *iv_return = CDROMPAUSE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'K':
    if (memEQ(name, "GPCMD_SEE", 9)) {
    /*                        K     */
#ifdef GPCMD_SEEK
      *iv_return = GPCMD_SEEK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "CD_XA_TAI", 9)) {
    /*                        L     */
#ifdef CD_XA_TAIL
      *iv_return = CD_XA_TAIL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "GPCMD_SCA", 9)) {
    /*                        N     */
#ifdef GPCMD_SCAN
      *iv_return = GPCMD_SCAN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "CDC_IOCTL", 9)) {
    /*                        S     */
#ifdef CDC_IOCTLS
      *iv_return = CDC_IOCTLS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DVD_LAYER", 9)) {
    /*                        S     */
#ifdef DVD_LAYERS
      *iv_return = DVD_LAYERS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "CDROMEJEC", 9)) {
    /*                        T     */
#ifdef CDROMEJECT
      *iv_return = CDROMEJECT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CDROMRESE", 9)) {
    /*                        T     */
#ifdef CDROMRESET
      *iv_return = CDROMRESET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CDROMSTAR", 9)) {
    /*                        T     */
#ifdef CDROMSTART
      *iv_return = CDROMSTART;
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
     CDC_DVD_RAM CDROMRESUME CDROM_DEBUG CDS_DISC_OK CDS_NO_DISC CDS_NO_INFO
     CD_ECC_SIZE CD_EDC_SIZE CD_PART_MAX GPCMD_BLANK */
  /* Offset 9 gives the best switch position.  */
  switch (name[9]) {
  case 'A':
    if (memEQ(name, "CDC_DVD_RAM", 11)) {
    /*                        ^        */
#ifdef CDC_DVD_RAM
      *iv_return = CDC_DVD_RAM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CD_PART_MAX", 11)) {
    /*                        ^        */
#ifdef CD_PART_MAX
      *iv_return = CD_PART_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "CDS_NO_INFO", 11)) {
    /*                        ^        */
#ifdef CDS_NO_INFO
      *iv_return = CDS_NO_INFO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "CDROMRESUME", 11)) {
    /*                        ^        */
#ifdef CDROMRESUME
      *iv_return = CDROMRESUME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "GPCMD_BLANK", 11)) {
    /*                        ^        */
#ifdef GPCMD_BLANK
      *iv_return = GPCMD_BLANK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "CDS_DISC_OK", 11)) {
    /*                        ^        */
#ifdef CDS_DISC_OK
      *iv_return = CDS_DISC_OK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "CDS_NO_DISC", 11)) {
    /*                        ^        */
#ifdef CDS_NO_DISC
      *iv_return = CDS_NO_DISC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "CDROM_DEBUG", 11)) {
    /*                        ^        */
#ifdef CDROM_DEBUG
      *iv_return = CDROM_DEBUG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Z':
    if (memEQ(name, "CD_ECC_SIZE", 11)) {
    /*                        ^        */
#ifdef CD_ECC_SIZE
      *iv_return = CD_ECC_SIZE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CD_EDC_SIZE", 11)) {
    /*                        ^        */
#ifdef CD_EDC_SIZE
      *iv_return = CD_EDC_SIZE;
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
     CDROMPLAYBLK CDROMPLAYMSF CDROMREADALL CDROMREADRAW CDROMSUBCHNL
     CDROMVOLCTRL CDROMVOLREAD CDSL_CURRENT CD_FRAMESIZE CD_HEAD_SIZE
     CD_PART_MASK CD_SYNC_SIZE CD_ZERO_SIZE */
  /* Offset 6 gives the best switch position.  */
  switch (name[6]) {
  case 'C':
    if (memEQ(name, "CD_SYNC_SIZE", 12)) {
    /*                     ^            */
#ifdef CD_SYNC_SIZE
      *iv_return = CD_SYNC_SIZE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "CD_HEAD_SIZE", 12)) {
    /*                     ^            */
#ifdef CD_HEAD_SIZE
      *iv_return = CD_HEAD_SIZE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "CDROMREADALL", 12)) {
    /*                     ^            */
#ifdef CDROMREADALL
      *iv_return = CDROMREADALL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CDROMREADRAW", 12)) {
    /*                     ^            */
#ifdef CDROMREADRAW
      *iv_return = CDROMREADRAW;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "CDROMPLAYBLK", 12)) {
    /*                     ^            */
#ifdef CDROMPLAYBLK
      *iv_return = CDROMPLAYBLK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CDROMPLAYMSF", 12)) {
    /*                     ^            */
#ifdef CDROMPLAYMSF
      *iv_return = CDROMPLAYMSF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "CD_FRAMESIZE", 12)) {
    /*                     ^            */
#ifdef CD_FRAMESIZE
      *iv_return = CD_FRAMESIZE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "CDROMVOLCTRL", 12)) {
    /*                     ^            */
#ifdef CDROMVOLCTRL
      *iv_return = CDROMVOLCTRL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CDROMVOLREAD", 12)) {
    /*                     ^            */
#ifdef CDROMVOLREAD
      *iv_return = CDROMVOLREAD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CD_ZERO_SIZE", 12)) {
    /*                     ^            */
#ifdef CD_ZERO_SIZE
      *iv_return = CD_ZERO_SIZE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "CD_PART_MASK", 12)) {
    /*                     ^            */
#ifdef CD_PART_MASK
      *iv_return = CD_PART_MASK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "CDROMSUBCHNL", 12)) {
    /*                     ^            */
#ifdef CDROMSUBCHNL
      *iv_return = CDROMSUBCHNL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CDSL_CURRENT", 12)) {
    /*                     ^            */
#ifdef CDSL_CURRENT
      *iv_return = CDSL_CURRENT;
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
     CDC_OPEN_TRAY CDROMEJECT_SW CDROM_GET_MCN CDROM_GET_UPC CDROM_LEADOUT
     CDS_TRAY_OPEN CD_CHUNK_SIZE CD_MSF_OFFSET CGC_DATA_NONE CGC_DATA_READ
     GPCMD_INQUIRY GPCMD_PLAY_CD GPCMD_READ_10 GPCMD_READ_12 GPCMD_READ_CD
     mechtype_tray */
  /* Offset 6 gives the best switch position.  */
  switch (name[6]) {
  case 'A':
    if (memEQ(name, "CDS_TRAY_OPEN", 13)) {
    /*                     ^             */
#ifdef CDS_TRAY_OPEN
      *iv_return = CDS_TRAY_OPEN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "CDC_OPEN_TRAY", 13)) {
    /*                     ^             */
#ifdef CDC_OPEN_TRAY
      *iv_return = CDC_OPEN_TRAY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "CDROM_GET_MCN", 13)) {
    /*                     ^             */
#ifdef CDROM_GET_MCN
      *iv_return = CDROM_GET_MCN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CDROM_GET_UPC", 13)) {
    /*                     ^             */
#ifdef CDROM_GET_UPC
      *iv_return = CDROM_GET_UPC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "GPCMD_INQUIRY", 13)) {
    /*                     ^             */
#ifdef GPCMD_INQUIRY
      *iv_return = GPCMD_INQUIRY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'J':
    if (memEQ(name, "CDROMEJECT_SW", 13)) {
    /*                     ^             */
#ifdef CDROMEJECT_SW
      *iv_return = CDROMEJECT_SW;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "CDROM_LEADOUT", 13)) {
    /*                     ^             */
#ifdef CDROM_LEADOUT
      *iv_return = CDROM_LEADOUT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "CD_CHUNK_SIZE", 13)) {
    /*                     ^             */
#ifdef CD_CHUNK_SIZE
      *iv_return = CD_CHUNK_SIZE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "GPCMD_PLAY_CD", 13)) {
    /*                     ^             */
#ifdef GPCMD_PLAY_CD
      *iv_return = GPCMD_PLAY_CD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "GPCMD_READ_10", 13)) {
    /*                     ^             */
#ifdef GPCMD_READ_10
      *iv_return = GPCMD_READ_10;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GPCMD_READ_12", 13)) {
    /*                     ^             */
#ifdef GPCMD_READ_12
      *iv_return = GPCMD_READ_12;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GPCMD_READ_CD", 13)) {
    /*                     ^             */
#ifdef GPCMD_READ_CD
      *iv_return = GPCMD_READ_CD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "CGC_DATA_NONE", 13)) {
    /*                     ^             */
#ifdef CGC_DATA_NONE
      *iv_return = CGC_DATA_NONE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CGC_DATA_READ", 13)) {
    /*                     ^             */
#ifdef CGC_DATA_READ
      *iv_return = CGC_DATA_READ;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "CD_MSF_OFFSET", 13)) {
    /*                     ^             */
#ifdef CD_MSF_OFFSET
      *iv_return = CD_MSF_OFFSET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'p':
    if (memEQ(name, "mechtype_tray", 13)) {
    /*                     ^             */
#ifdef mechtype_tray
      *iv_return = mechtype_tray;
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
constant_14 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CDC_CLOSE_TRAY CDC_PLAY_AUDIO CDO_AUTO_CLOSE CDO_AUTO_EJECT CDO_CHECK_TYPE
     CDO_USE_FFLAGS CDROMCLOSETRAY CDROMREADAUDIO CDROMREADMODE1 CDROMREADMODE2
     CDROM_LOCKDOOR CGC_DATA_WRITE DVD_STRUCT_BCA GPCMD_SEND_KEY GPCMD_SEND_OPC
     GPCMD_WRITE_10 mechtype_caddy mechtype_popup */
  /* Offset 13 gives the best switch position.  */
  switch (name[13]) {
  case '0':
    if (memEQ(name, "GPCMD_WRITE_1", 13)) {
    /*                            0      */
#ifdef GPCMD_WRITE_10
      *iv_return = GPCMD_WRITE_10;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '1':
    if (memEQ(name, "CDROMREADMODE", 13)) {
    /*                            1      */
#ifdef CDROMREADMODE1
      *iv_return = CDROMREADMODE1;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '2':
    if (memEQ(name, "CDROMREADMODE", 13)) {
    /*                            2      */
#ifdef CDROMREADMODE2
      *iv_return = CDROMREADMODE2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'A':
    if (memEQ(name, "DVD_STRUCT_BC", 13)) {
    /*                            A      */
#ifdef DVD_STRUCT_BCA
      *iv_return = DVD_STRUCT_BCA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "GPCMD_SEND_OP", 13)) {
    /*                            C      */
#ifdef GPCMD_SEND_OPC
      *iv_return = GPCMD_SEND_OPC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "CDO_AUTO_CLOS", 13)) {
    /*                            E      */
#ifdef CDO_AUTO_CLOSE
      *iv_return = CDO_AUTO_CLOSE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CDO_CHECK_TYP", 13)) {
    /*                            E      */
#ifdef CDO_CHECK_TYPE
      *iv_return = CDO_CHECK_TYPE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CGC_DATA_WRIT", 13)) {
    /*                            E      */
#ifdef CGC_DATA_WRITE
      *iv_return = CGC_DATA_WRITE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "CDC_PLAY_AUDI", 13)) {
    /*                            O      */
#ifdef CDC_PLAY_AUDIO
      *iv_return = CDC_PLAY_AUDIO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CDROMREADAUDI", 13)) {
    /*                            O      */
#ifdef CDROMREADAUDIO
      *iv_return = CDROMREADAUDIO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "CDROM_LOCKDOO", 13)) {
    /*                            R      */
#ifdef CDROM_LOCKDOOR
      *iv_return = CDROM_LOCKDOOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "CDO_USE_FFLAG", 13)) {
    /*                            S      */
#ifdef CDO_USE_FFLAGS
      *iv_return = CDO_USE_FFLAGS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "CDO_AUTO_EJEC", 13)) {
    /*                            T      */
#ifdef CDO_AUTO_EJECT
      *iv_return = CDO_AUTO_EJECT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Y':
    if (memEQ(name, "CDC_CLOSE_TRA", 13)) {
    /*                            Y      */
#ifdef CDC_CLOSE_TRAY
      *iv_return = CDC_CLOSE_TRAY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CDROMCLOSETRA", 13)) {
    /*                            Y      */
#ifdef CDROMCLOSETRAY
      *iv_return = CDROMCLOSETRAY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GPCMD_SEND_KE", 13)) {
    /*                            Y      */
#ifdef GPCMD_SEND_KEY
      *iv_return = GPCMD_SEND_KEY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'p':
    if (memEQ(name, "mechtype_popu", 13)) {
    /*                            p      */
#ifdef mechtype_popup
      *iv_return = mechtype_popup;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'y':
    if (memEQ(name, "mechtype_cadd", 13)) {
    /*                            y      */
#ifdef mechtype_caddy
      *iv_return = mechtype_caddy;
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
     CDC_SELECT_DISC CDROMPLAYTRKIND CDROMREADCOOKED CDROMREADTOCHDR
     CDROM_MAX_SLOTS CD_SUBHEAD_SIZE CD_XA_SYNC_HEAD DVD_CGMS_SINGLE
     DVD_CP_SEC_NONE DVD_LU_SEND_ASF DVD_READ_STRUCT GPCMD_SET_SPEED
     GPCMD_VERIFY_10 */
  /* Offset 11 gives the best switch position.  */
  switch (name[11]) {
  case 'C':
    if (memEQ(name, "CDROMREADTOCHDR", 15)) {
    /*                          ^          */
#ifdef CDROMREADTOCHDR
      *iv_return = CDROMREADTOCHDR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "CDC_SELECT_DISC", 15)) {
    /*                          ^          */
#ifdef CDC_SELECT_DISC
      *iv_return = CDC_SELECT_DISC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "CD_XA_SYNC_HEAD", 15)) {
    /*                          ^          */
#ifdef CD_XA_SYNC_HEAD
      *iv_return = CD_XA_SYNC_HEAD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'K':
    if (memEQ(name, "CDROMPLAYTRKIND", 15)) {
    /*                          ^          */
#ifdef CDROMPLAYTRKIND
      *iv_return = CDROMPLAYTRKIND;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "CDROM_MAX_SLOTS", 15)) {
    /*                          ^          */
#ifdef CDROM_MAX_SLOTS
      *iv_return = CDROM_MAX_SLOTS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "DVD_CGMS_SINGLE", 15)) {
    /*                          ^          */
#ifdef DVD_CGMS_SINGLE
      *iv_return = DVD_CGMS_SINGLE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DVD_CP_SEC_NONE", 15)) {
    /*                          ^          */
#ifdef DVD_CP_SEC_NONE
      *iv_return = DVD_CP_SEC_NONE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "CDROMREADCOOKED", 15)) {
    /*                          ^          */
#ifdef CDROMREADCOOKED
      *iv_return = CDROMREADCOOKED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "GPCMD_SET_SPEED", 15)) {
    /*                          ^          */
#ifdef GPCMD_SET_SPEED
      *iv_return = GPCMD_SET_SPEED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "DVD_READ_STRUCT", 15)) {
    /*                          ^          */
#ifdef DVD_READ_STRUCT
      *iv_return = DVD_READ_STRUCT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "CD_SUBHEAD_SIZE", 15)) {
    /*                          ^          */
#ifdef CD_SUBHEAD_SIZE
      *iv_return = CD_SUBHEAD_SIZE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Y':
    if (memEQ(name, "GPCMD_VERIFY_10", 15)) {
    /*                          ^          */
#ifdef GPCMD_VERIFY_10
      *iv_return = GPCMD_VERIFY_10;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "DVD_LU_SEND_ASF", 15)) {
    /*                          ^          */
#ifdef DVD_LU_SEND_ASF
      *iv_return = DVD_LU_SEND_ASF;
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
constant_16 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CDC_DRIVE_STATUS CDC_SELECT_SPEED CDROMAUDIOBUFSIZ CDROMGETSPINDOWN
     CDROMSETSPINDOWN CDROM_AUDIO_PLAY CDROM_DATA_TRACK CD_FRAMESIZE_RAW
     CD_FRAMESIZE_SUB CD_NUM_OF_CHUNKS CGC_DATA_UNKNOWN DVD_AUTH_FAILURE
     DVD_CP_SEC_EXIST DVD_LU_SEND_AGID DVD_LU_SEND_KEY1 DVD_WRITE_STRUCT
     GPCMD_REPORT_KEY GPCMD_SEND_EVENT GPMODE_ALL_PAGES */
  /* Offset 13 gives the best switch position.  */
  switch (name[13]) {
  case 'A':
    if (memEQ(name, "CDROM_DATA_TRACK", 16)) {
    /*                            ^         */
#ifdef CDROM_DATA_TRACK
      *iv_return = CDROM_DATA_TRACK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "CDC_SELECT_SPEED", 16)) {
    /*                            ^         */
#ifdef CDC_SELECT_SPEED
      *iv_return = CDC_SELECT_SPEED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DVD_LU_SEND_KEY1", 16)) {
    /*                            ^         */
#ifdef DVD_LU_SEND_KEY1
      *iv_return = DVD_LU_SEND_KEY1;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GPCMD_SEND_EVENT", 16)) {
    /*                            ^         */
#ifdef GPCMD_SEND_EVENT
      *iv_return = GPCMD_SEND_EVENT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "DVD_LU_SEND_AGID", 16)) {
    /*                            ^         */
#ifdef DVD_LU_SEND_AGID
      *iv_return = DVD_LU_SEND_AGID;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GPMODE_ALL_PAGES", 16)) {
    /*                            ^         */
#ifdef GPMODE_ALL_PAGES
      *iv_return = GPMODE_ALL_PAGES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "DVD_CP_SEC_EXIST", 16)) {
    /*                            ^         */
#ifdef DVD_CP_SEC_EXIST
      *iv_return = DVD_CP_SEC_EXIST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'K':
    if (memEQ(name, "GPCMD_REPORT_KEY", 16)) {
    /*                            ^         */
#ifdef GPCMD_REPORT_KEY
      *iv_return = GPCMD_REPORT_KEY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "CDROM_AUDIO_PLAY", 16)) {
    /*                            ^         */
#ifdef CDROM_AUDIO_PLAY
      *iv_return = CDROM_AUDIO_PLAY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "CD_NUM_OF_CHUNKS", 16)) {
    /*                            ^         */
#ifdef CD_NUM_OF_CHUNKS
      *iv_return = CD_NUM_OF_CHUNKS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "CDROMGETSPINDOWN", 16)) {
    /*                            ^         */
#ifdef CDROMGETSPINDOWN
      *iv_return = CDROMGETSPINDOWN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CDROMSETSPINDOWN", 16)) {
    /*                            ^         */
#ifdef CDROMSETSPINDOWN
      *iv_return = CDROMSETSPINDOWN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CGC_DATA_UNKNOWN", 16)) {
    /*                            ^         */
#ifdef CGC_DATA_UNKNOWN
      *iv_return = CGC_DATA_UNKNOWN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "CD_FRAMESIZE_RAW", 16)) {
    /*                            ^         */
#ifdef CD_FRAMESIZE_RAW
      *iv_return = CD_FRAMESIZE_RAW;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "CDROMAUDIOBUFSIZ", 16)) {
    /*                            ^         */
#ifdef CDROMAUDIOBUFSIZ
      *iv_return = CDROMAUDIOBUFSIZ;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CD_FRAMESIZE_SUB", 16)) {
    /*                            ^         */
#ifdef CD_FRAMESIZE_SUB
      *iv_return = CD_FRAMESIZE_SUB;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "CDC_DRIVE_STATUS", 16)) {
    /*                            ^         */
#ifdef CDC_DRIVE_STATUS
      *iv_return = CDC_DRIVE_STATUS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "DVD_AUTH_FAILURE", 16)) {
    /*                            ^         */
#ifdef DVD_AUTH_FAILURE
      *iv_return = DVD_AUTH_FAILURE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DVD_WRITE_STRUCT", 16)) {
    /*                            ^         */
#ifdef DVD_WRITE_STRUCT
      *iv_return = DVD_WRITE_STRUCT;
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
     CDC_MEDIA_CHANGED CDC_MULTI_SESSION CDROMMULTISESSION CDROMREADTOCENTRY
     CDROM_AUDIO_ERROR CDROM_DISC_STATUS CDROM_PACKET_SIZE CDROM_SELECT_DISC
     CDROM_SEND_PACKET CDROM_SET_OPTIONS CD_FRAMESIZE_RAW0 CD_FRAMESIZE_RAW1
     GPCMD_CLOSE_TRACK GPCMD_FLUSH_CACHE GPCMD_FORMAT_UNIT GPCMD_LOAD_UNLOAD
     GPCMD_READ_CD_MSF GPCMD_READ_HEADER GPMODE_CDROM_PAGE GPMODE_POWER_PAGE */
  /* Offset 15 gives the best switch position.  */
  switch (name[15]) {
  case 'A':
    if (memEQ(name, "GPCMD_LOAD_UNLOAD", 17)) {
    /*                              ^        */
#ifdef GPCMD_LOAD_UNLOAD
      *iv_return = GPCMD_LOAD_UNLOAD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "GPCMD_CLOSE_TRACK", 17)) {
    /*                              ^        */
#ifdef GPCMD_CLOSE_TRACK
      *iv_return = GPCMD_CLOSE_TRACK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "CDC_MEDIA_CHANGED", 17)) {
    /*                              ^        */
#ifdef CDC_MEDIA_CHANGED
      *iv_return = CDC_MEDIA_CHANGED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CDROM_SEND_PACKET", 17)) {
    /*                              ^        */
#ifdef CDROM_SEND_PACKET
      *iv_return = CDROM_SEND_PACKET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GPCMD_READ_HEADER", 17)) {
    /*                              ^        */
#ifdef GPCMD_READ_HEADER
      *iv_return = GPCMD_READ_HEADER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "GPMODE_CDROM_PAGE", 17)) {
    /*                              ^        */
#ifdef GPMODE_CDROM_PAGE
      *iv_return = GPMODE_CDROM_PAGE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GPMODE_POWER_PAGE", 17)) {
    /*                              ^        */
#ifdef GPMODE_POWER_PAGE
      *iv_return = GPMODE_POWER_PAGE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "GPCMD_FLUSH_CACHE", 17)) {
    /*                              ^        */
#ifdef GPCMD_FLUSH_CACHE
      *iv_return = GPCMD_FLUSH_CACHE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "GPCMD_FORMAT_UNIT", 17)) {
    /*                              ^        */
#ifdef GPCMD_FORMAT_UNIT
      *iv_return = GPCMD_FORMAT_UNIT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "CDROM_SET_OPTIONS", 17)) {
    /*                              ^        */
#ifdef CDROM_SET_OPTIONS
      *iv_return = CDROM_SET_OPTIONS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "CDC_MULTI_SESSION", 17)) {
    /*                              ^        */
#ifdef CDC_MULTI_SESSION
      *iv_return = CDC_MULTI_SESSION;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CDROMMULTISESSION", 17)) {
    /*                              ^        */
#ifdef CDROMMULTISESSION
      *iv_return = CDROMMULTISESSION;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CDROM_AUDIO_ERROR", 17)) {
    /*                              ^        */
#ifdef CDROM_AUDIO_ERROR
      *iv_return = CDROM_AUDIO_ERROR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "CDROMREADTOCENTRY", 17)) {
    /*                              ^        */
#ifdef CDROMREADTOCENTRY
      *iv_return = CDROMREADTOCENTRY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "CDROM_SELECT_DISC", 17)) {
    /*                              ^        */
#ifdef CDROM_SELECT_DISC
      *iv_return = CDROM_SELECT_DISC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GPCMD_READ_CD_MSF", 17)) {
    /*                              ^        */
#ifdef GPCMD_READ_CD_MSF
      *iv_return = GPCMD_READ_CD_MSF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "CDROM_DISC_STATUS", 17)) {
    /*                              ^        */
#ifdef CDROM_DISC_STATUS
      *iv_return = CDROM_DISC_STATUS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'W':
    if (memEQ(name, "CD_FRAMESIZE_RAW0", 17)) {
    /*                              ^        */
#ifdef CD_FRAMESIZE_RAW0
      *iv_return = CD_FRAMESIZE_RAW0;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CD_FRAMESIZE_RAW1", 17)) {
    /*                              ^        */
#ifdef CD_FRAMESIZE_RAW1
      *iv_return = CD_FRAMESIZE_RAW1;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Z':
    if (memEQ(name, "CDROM_PACKET_SIZE", 17)) {
    /*                              ^        */
#ifdef CDROM_PACKET_SIZE
      *iv_return = CDROM_PACKET_SIZE;
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
constant_18 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CDC_GENERIC_PACKET CDROM_AUDIO_PAUSED CDROM_DRIVE_STATUS
     CDROM_LAST_WRITTEN CDROM_SELECT_SPEED CD_FRAMESIZE_RAWER
     DVD_HOST_SEND_KEY2 DVD_STRUCT_DISCKEY GPCMD_PAUSE_RESUME
     GPCMD_PLAYAUDIO_TI */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'A':
    if (memEQ(name, "GPCMD_PLAYAUDIO_TI", 18)) {
    /*                       ^                */
#ifdef GPCMD_PLAYAUDIO_TI
      *iv_return = GPCMD_PLAYAUDIO_TI;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "DVD_STRUCT_DISCKEY", 18)) {
    /*                       ^                */
#ifdef DVD_STRUCT_DISCKEY
      *iv_return = DVD_STRUCT_DISCKEY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "CDROM_AUDIO_PAUSED", 18)) {
    /*                       ^                */
#ifdef CDROM_AUDIO_PAUSED
      *iv_return = CDROM_AUDIO_PAUSED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "CDROM_DRIVE_STATUS", 18)) {
    /*                       ^                */
#ifdef CDROM_DRIVE_STATUS
      *iv_return = CDROM_DRIVE_STATUS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "CDROM_SELECT_SPEED", 18)) {
    /*                       ^                */
#ifdef CDROM_SELECT_SPEED
      *iv_return = CDROM_SELECT_SPEED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "CDC_GENERIC_PACKET", 18)) {
    /*                       ^                */
#ifdef CDC_GENERIC_PACKET
      *iv_return = CDC_GENERIC_PACKET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "CDROM_LAST_WRITTEN", 18)) {
    /*                       ^                */
#ifdef CDROM_LAST_WRITTEN
      *iv_return = CDROM_LAST_WRITTEN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CD_FRAMESIZE_RAWER", 18)) {
    /*                       ^                */
#ifdef CD_FRAMESIZE_RAWER
      *iv_return = CD_FRAMESIZE_RAWER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "GPCMD_PAUSE_RESUME", 18)) {
    /*                       ^                */
#ifdef GPCMD_PAUSE_RESUME
      *iv_return = GPCMD_PAUSE_RESUME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "DVD_HOST_SEND_KEY2", 18)) {
    /*                       ^                */
#ifdef DVD_HOST_SEND_KEY2
      *iv_return = DVD_HOST_SEND_KEY2;
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
     CDROM_AUDIO_INVALID CDROM_CLEAR_OPTIONS CDROM_MEDIA_CHANGED
     CDROM_NEXT_WRITABLE CDS_DRIVE_NOT_READY DVD_CGMS_RESTRICTED
     DVD_CPM_COPYRIGHTED DVD_INVALIDATE_AGID DVD_STRUCT_MANUFACT
     DVD_STRUCT_PHYSICAL EDRIVE_CANT_DO_THIS GPCMD_MODE_SENSE_10
     GPCMD_PLAY_AUDIO_10 GPCMD_PLAY_AUDIO_TI GPCMD_REQUEST_SENSE
     GPCMD_SET_STREAMING */
  /* Offset 16 gives the best switch position.  */
  switch (name[16]) {
  case 'A':
    if (memEQ(name, "CDS_DRIVE_NOT_READY", 19)) {
    /*                               ^         */
#ifdef CDS_DRIVE_NOT_READY
      *iv_return = CDS_DRIVE_NOT_READY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DVD_STRUCT_MANUFACT", 19)) {
    /*                               ^         */
#ifdef DVD_STRUCT_MANUFACT
      *iv_return = DVD_STRUCT_MANUFACT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "CDROM_NEXT_WRITABLE", 19)) {
    /*                               ^         */
#ifdef CDROM_NEXT_WRITABLE
      *iv_return = CDROM_NEXT_WRITABLE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "DVD_STRUCT_PHYSICAL", 19)) {
    /*                               ^         */
#ifdef DVD_STRUCT_PHYSICAL
      *iv_return = DVD_STRUCT_PHYSICAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "CDROM_MEDIA_CHANGED", 19)) {
    /*                               ^         */
#ifdef CDROM_MEDIA_CHANGED
      *iv_return = CDROM_MEDIA_CHANGED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DVD_INVALIDATE_AGID", 19)) {
    /*                               ^         */
#ifdef DVD_INVALIDATE_AGID
      *iv_return = DVD_INVALIDATE_AGID;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "EDRIVE_CANT_DO_THIS", 19)) {
    /*                               ^         */
#ifdef EDRIVE_CANT_DO_THIS
      *iv_return = EDRIVE_CANT_DO_THIS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "GPCMD_SET_STREAMING", 19)) {
    /*                               ^         */
#ifdef GPCMD_SET_STREAMING
      *iv_return = GPCMD_SET_STREAMING;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "CDROM_AUDIO_INVALID", 19)) {
    /*                               ^         */
#ifdef CDROM_AUDIO_INVALID
      *iv_return = CDROM_AUDIO_INVALID;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "GPCMD_REQUEST_SENSE", 19)) {
    /*                               ^         */
#ifdef GPCMD_REQUEST_SENSE
      *iv_return = GPCMD_REQUEST_SENSE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "CDROM_CLEAR_OPTIONS", 19)) {
    /*                               ^         */
#ifdef CDROM_CLEAR_OPTIONS
      *iv_return = CDROM_CLEAR_OPTIONS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "DVD_CGMS_RESTRICTED", 19)) {
    /*                               ^         */
#ifdef DVD_CGMS_RESTRICTED
      *iv_return = DVD_CGMS_RESTRICTED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DVD_CPM_COPYRIGHTED", 19)) {
    /*                               ^         */
#ifdef DVD_CPM_COPYRIGHTED
      *iv_return = DVD_CPM_COPYRIGHTED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "GPCMD_MODE_SENSE_10", 19)) {
    /*                               ^         */
#ifdef GPCMD_MODE_SENSE_10
      *iv_return = GPCMD_MODE_SENSE_10;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GPCMD_PLAY_AUDIO_10", 19)) {
    /*                               ^         */
#ifdef GPCMD_PLAY_AUDIO_10
      *iv_return = GPCMD_PLAY_AUDIO_10;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GPCMD_PLAY_AUDIO_TI", 19)) {
    /*                               ^         */
#ifdef GPCMD_PLAY_AUDIO_TI
      *iv_return = GPCMD_PLAY_AUDIO_TI;
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
constant_20 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CDROM_CHANGER_NSLOTS CDROM_GET_CAPABILITY DVD_AUTH_ESTABLISHED
     DVD_CPM_NO_COPYRIGHT DVD_STRUCT_COPYRIGHT GPCMD_MODE_SELECT_10
     GPCMD_PLAY_AUDIO_MSF GPCMD_READ_DISC_INFO GPCMD_SET_READ_AHEAD
     GPCMD_STOP_PLAY_SCAN */
  /* Offset 17 gives the best switch position.  */
  switch (name[17]) {
  case 'C':
    if (memEQ(name, "GPCMD_STOP_PLAY_SCAN", 20)) {
    /*                                ^         */
#ifdef GPCMD_STOP_PLAY_SCAN
      *iv_return = GPCMD_STOP_PLAY_SCAN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "GPCMD_SET_READ_AHEAD", 20)) {
    /*                                ^         */
#ifdef GPCMD_SET_READ_AHEAD
      *iv_return = GPCMD_SET_READ_AHEAD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "DVD_CPM_NO_COPYRIGHT", 20)) {
    /*                                ^         */
#ifdef DVD_CPM_NO_COPYRIGHT
      *iv_return = DVD_CPM_NO_COPYRIGHT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DVD_STRUCT_COPYRIGHT", 20)) {
    /*                                ^         */
#ifdef DVD_STRUCT_COPYRIGHT
      *iv_return = DVD_STRUCT_COPYRIGHT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "DVD_AUTH_ESTABLISHED", 20)) {
    /*                                ^         */
#ifdef DVD_AUTH_ESTABLISHED
      *iv_return = DVD_AUTH_ESTABLISHED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "CDROM_GET_CAPABILITY", 20)) {
    /*                                ^         */
#ifdef CDROM_GET_CAPABILITY
      *iv_return = CDROM_GET_CAPABILITY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "GPCMD_PLAY_AUDIO_MSF", 20)) {
    /*                                ^         */
#ifdef GPCMD_PLAY_AUDIO_MSF
      *iv_return = GPCMD_PLAY_AUDIO_MSF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "GPCMD_READ_DISC_INFO", 20)) {
    /*                                ^         */
#ifdef GPCMD_READ_DISC_INFO
      *iv_return = GPCMD_READ_DISC_INFO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "CDROM_CHANGER_NSLOTS", 20)) {
    /*                                ^         */
#ifdef CDROM_CHANGER_NSLOTS
      *iv_return = CDROM_CHANGER_NSLOTS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "GPCMD_MODE_SELECT_10", 20)) {
    /*                                ^         */
#ifdef GPCMD_MODE_SELECT_10
      *iv_return = GPCMD_MODE_SELECT_10;
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
constant_21 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CDROM_AUDIO_COMPLETED CDROM_AUDIO_NO_STATUS DVD_CGMS_UNRESTRICTED
     DVD_LU_SEND_CHALLENGE DVD_LU_SEND_RPC_STATE DVD_LU_SEND_TITLE_KEY
     GPCMD_GET_PERFORMANCE GPCMD_READ_SUBCHANNEL GPCMD_START_STOP_UNIT
     GPCMD_TEST_UNIT_READY GPMODE_AUDIO_CTL_PAGE GPMODE_R_W_ERROR_PAGE */
  /* Offset 13 gives the best switch position.  */
  switch (name[13]) {
  case 'B':
    if (memEQ(name, "GPCMD_READ_SUBCHANNEL", 21)) {
    /*                            ^              */
#ifdef GPCMD_READ_SUBCHANNEL
      *iv_return = GPCMD_READ_SUBCHANNEL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "GPMODE_AUDIO_CTL_PAGE", 21)) {
    /*                            ^              */
#ifdef GPMODE_AUDIO_CTL_PAGE
      *iv_return = GPMODE_AUDIO_CTL_PAGE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "GPCMD_GET_PERFORMANCE", 21)) {
    /*                            ^              */
#ifdef GPCMD_GET_PERFORMANCE
      *iv_return = GPCMD_GET_PERFORMANCE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "DVD_LU_SEND_CHALLENGE", 21)) {
    /*                            ^              */
#ifdef DVD_LU_SEND_CHALLENGE
      *iv_return = DVD_LU_SEND_CHALLENGE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "DVD_LU_SEND_TITLE_KEY", 21)) {
    /*                            ^              */
#ifdef DVD_LU_SEND_TITLE_KEY
      *iv_return = DVD_LU_SEND_TITLE_KEY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GPCMD_TEST_UNIT_READY", 21)) {
    /*                            ^              */
#ifdef GPCMD_TEST_UNIT_READY
      *iv_return = GPCMD_TEST_UNIT_READY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "CDROM_AUDIO_COMPLETED", 21)) {
    /*                            ^              */
#ifdef CDROM_AUDIO_COMPLETED
      *iv_return = CDROM_AUDIO_COMPLETED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CDROM_AUDIO_NO_STATUS", 21)) {
    /*                            ^              */
#ifdef CDROM_AUDIO_NO_STATUS
      *iv_return = CDROM_AUDIO_NO_STATUS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "DVD_LU_SEND_RPC_STATE", 21)) {
    /*                            ^              */
#ifdef DVD_LU_SEND_RPC_STATE
      *iv_return = DVD_LU_SEND_RPC_STATE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "GPMODE_R_W_ERROR_PAGE", 21)) {
    /*                            ^              */
#ifdef GPMODE_R_W_ERROR_PAGE
      *iv_return = GPMODE_R_W_ERROR_PAGE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "DVD_CGMS_UNRESTRICTED", 21)) {
    /*                            ^              */
#ifdef DVD_CGMS_UNRESTRICTED
      *iv_return = DVD_CGMS_UNRESTRICTED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "GPCMD_START_STOP_UNIT", 21)) {
    /*                            ^              */
#ifdef GPCMD_START_STOP_UNIT
      *iv_return = GPCMD_START_STOP_UNIT;
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
constant_22 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     GPCMD_GET_MEDIA_STATUS GPCMD_MECHANISM_STATUS GPMODE_FAULT_FAIL_PAGE
     GPMODE_TO_PROTECT_PAGE */
  /* Offset 13 gives the best switch position.  */
  switch (name[13]) {
  case 'F':
    if (memEQ(name, "GPMODE_FAULT_FAIL_PAGE", 22)) {
    /*                            ^               */
#ifdef GPMODE_FAULT_FAIL_PAGE
      *iv_return = GPMODE_FAULT_FAIL_PAGE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "GPCMD_GET_MEDIA_STATUS", 22)) {
    /*                            ^               */
#ifdef GPCMD_GET_MEDIA_STATUS
      *iv_return = GPCMD_GET_MEDIA_STATUS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "GPCMD_MECHANISM_STATUS", 22)) {
    /*                            ^               */
#ifdef GPCMD_MECHANISM_STATUS
      *iv_return = GPCMD_MECHANISM_STATUS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "GPMODE_TO_PROTECT_PAGE", 22)) {
    /*                            ^               */
#ifdef GPMODE_TO_PROTECT_PAGE
      *iv_return = GPMODE_TO_PROTECT_PAGE;
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
constant_23 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     DVD_HOST_SEND_CHALLENGE DVD_HOST_SEND_RPC_STATE GPCMD_GET_CONFIGURATION
     GPCMD_READ_TOC_PMA_ATIP GPMODE_WRITE_PARMS_PAGE */
  /* Offset 14 gives the best switch position.  */
  switch (name[14]) {
  case 'A':
    if (memEQ(name, "GPMODE_WRITE_PARMS_PAGE", 23)) {
    /*                             ^               */
#ifdef GPMODE_WRITE_PARMS_PAGE
      *iv_return = GPMODE_WRITE_PARMS_PAGE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "DVD_HOST_SEND_CHALLENGE", 23)) {
    /*                             ^               */
#ifdef DVD_HOST_SEND_CHALLENGE
      *iv_return = DVD_HOST_SEND_CHALLENGE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "GPCMD_GET_CONFIGURATION", 23)) {
    /*                             ^               */
#ifdef GPCMD_GET_CONFIGURATION
      *iv_return = GPCMD_GET_CONFIGURATION;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "DVD_HOST_SEND_RPC_STATE", 23)) {
    /*                             ^               */
#ifdef DVD_HOST_SEND_RPC_STATE
      *iv_return = DVD_HOST_SEND_RPC_STATE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "GPCMD_READ_TOC_PMA_ATIP", 23)) {
    /*                             ^               */
#ifdef GPCMD_READ_TOC_PMA_ATIP
      *iv_return = GPCMD_READ_TOC_PMA_ATIP;
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
constant_24 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     GPCMD_READ_CDVD_CAPACITY GPCMD_READ_DVD_STRUCTURE GPCMD_REPAIR_RZONE_TRACK
     GPCMD_SEND_DVD_STRUCTURE GPMODE_CAPABILITIES_PAGE */
  /* Offset 18 gives the best switch position.  */
  switch (name[18]) {
  case 'P':
    if (memEQ(name, "GPCMD_READ_CDVD_CAPACITY", 24)) {
    /*                                 ^            */
#ifdef GPCMD_READ_CDVD_CAPACITY
      *iv_return = GPCMD_READ_CDVD_CAPACITY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "GPMODE_CAPABILITIES_PAGE", 24)) {
    /*                                 ^            */
#ifdef GPMODE_CAPABILITIES_PAGE
      *iv_return = GPMODE_CAPABILITIES_PAGE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "GPCMD_READ_DVD_STRUCTURE", 24)) {
    /*                                 ^            */
#ifdef GPCMD_READ_DVD_STRUCTURE
      *iv_return = GPCMD_READ_DVD_STRUCTURE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GPCMD_SEND_DVD_STRUCTURE", 24)) {
    /*                                 ^            */
#ifdef GPCMD_SEND_DVD_STRUCTURE
      *iv_return = GPCMD_SEND_DVD_STRUCTURE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "GPCMD_REPAIR_RZONE_TRACK", 24)) {
    /*                                 ^            */
#ifdef GPCMD_REPAIR_RZONE_TRACK
      *iv_return = GPCMD_REPAIR_RZONE_TRACK;
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

#!/usr/bin/perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(CDC_CD_R CDC_CD_RW CDC_CLOSE_TRAY CDC_DRIVE_STATUS CDC_DVD
	       CDC_DVD_R CDC_DVD_RAM CDC_GENERIC_PACKET CDC_IOCTLS CDC_LOCK
	       CDC_MCN CDC_MEDIA_CHANGED CDC_MULTI_SESSION CDC_OPEN_TRAY
	       CDC_PLAY_AUDIO CDC_RESET CDC_SELECT_DISC CDC_SELECT_SPEED
	       CDO_AUTO_CLOSE CDO_AUTO_EJECT CDO_CHECK_TYPE CDO_LOCK
	       CDO_USE_FFLAGS CDROMAUDIOBUFSIZ CDROMCLOSETRAY CDROMEJECT
	       CDROMEJECT_SW CDROMGETSPINDOWN CDROMMULTISESSION CDROMPAUSE
	       CDROMPLAYBLK CDROMPLAYMSF CDROMPLAYTRKIND CDROMREADALL
	       CDROMREADAUDIO CDROMREADCOOKED CDROMREADMODE1 CDROMREADMODE2
	       CDROMREADRAW CDROMREADTOCENTRY CDROMREADTOCHDR CDROMRESET
	       CDROMRESUME CDROMSEEK CDROMSETSPINDOWN CDROMSTART CDROMSTOP
	       CDROMSUBCHNL CDROMVOLCTRL CDROMVOLREAD CDROM_AUDIO_COMPLETED
	       CDROM_AUDIO_ERROR CDROM_AUDIO_INVALID CDROM_AUDIO_NO_STATUS
	       CDROM_AUDIO_PAUSED CDROM_AUDIO_PLAY CDROM_CHANGER_NSLOTS
	       CDROM_CLEAR_OPTIONS CDROM_DATA_TRACK CDROM_DEBUG
	       CDROM_DISC_STATUS CDROM_DRIVE_STATUS CDROM_GET_CAPABILITY
	       CDROM_GET_MCN CDROM_GET_UPC CDROM_LAST_WRITTEN CDROM_LBA
	       CDROM_LEADOUT CDROM_LOCKDOOR CDROM_MAX_SLOTS CDROM_MEDIA_CHANGED
	       CDROM_MSF CDROM_NEXT_WRITABLE CDROM_PACKET_SIZE
	       CDROM_SELECT_DISC CDROM_SELECT_SPEED CDROM_SEND_PACKET
	       CDROM_SET_OPTIONS CDSL_CURRENT CDSL_NONE CDS_AUDIO CDS_DATA_1
	       CDS_DATA_2 CDS_DISC_OK CDS_DRIVE_NOT_READY CDS_MIXED CDS_NO_DISC
	       CDS_NO_INFO CDS_TRAY_OPEN CDS_XA_2_1 CDS_XA_2_2 CD_CHUNK_SIZE
	       CD_ECC_SIZE CD_EDC_SIZE CD_FRAMES CD_FRAMESIZE CD_FRAMESIZE_RAW
	       CD_FRAMESIZE_RAW0 CD_FRAMESIZE_RAW1 CD_FRAMESIZE_RAWER
	       CD_FRAMESIZE_SUB CD_HEAD_SIZE CD_MINS CD_MSF_OFFSET
	       CD_NUM_OF_CHUNKS CD_PART_MASK CD_PART_MAX CD_SECS
	       CD_SUBHEAD_SIZE CD_SYNC_SIZE CD_XA_HEAD CD_XA_SYNC_HEAD
	       CD_XA_TAIL CD_ZERO_SIZE CGC_DATA_NONE CGC_DATA_READ
	       CGC_DATA_UNKNOWN CGC_DATA_WRITE DVD_AUTH DVD_AUTH_ESTABLISHED
	       DVD_AUTH_FAILURE DVD_CGMS_RESTRICTED DVD_CGMS_SINGLE
	       DVD_CGMS_UNRESTRICTED DVD_CPM_COPYRIGHTED DVD_CPM_NO_COPYRIGHT
	       DVD_CP_SEC_EXIST DVD_CP_SEC_NONE DVD_HOST_SEND_CHALLENGE
	       DVD_HOST_SEND_KEY2 DVD_HOST_SEND_RPC_STATE DVD_INVALIDATE_AGID
	       DVD_LAYERS DVD_LU_SEND_AGID DVD_LU_SEND_ASF
	       DVD_LU_SEND_CHALLENGE DVD_LU_SEND_KEY1 DVD_LU_SEND_RPC_STATE
	       DVD_LU_SEND_TITLE_KEY DVD_READ_STRUCT DVD_STRUCT_BCA
	       DVD_STRUCT_COPYRIGHT DVD_STRUCT_DISCKEY DVD_STRUCT_MANUFACT
	       DVD_STRUCT_PHYSICAL DVD_WRITE_STRUCT EDRIVE_CANT_DO_THIS
	       GPCMD_BLANK GPCMD_CLOSE_TRACK GPCMD_FLUSH_CACHE
	       GPCMD_FORMAT_UNIT GPCMD_GET_CONFIGURATION
	       GPCMD_GET_EVENT_STATUS_NOTIFICATION GPCMD_GET_MEDIA_STATUS
	       GPCMD_GET_PERFORMANCE GPCMD_INQUIRY GPCMD_LOAD_UNLOAD
	       GPCMD_MECHANISM_STATUS GPCMD_MODE_SELECT_10 GPCMD_MODE_SENSE_10
	       GPCMD_PAUSE_RESUME GPCMD_PLAYAUDIO_TI GPCMD_PLAY_AUDIO_10
	       GPCMD_PLAY_AUDIO_MSF GPCMD_PLAY_AUDIO_TI GPCMD_PLAY_CD
	       GPCMD_PREVENT_ALLOW_MEDIUM_REMOVAL GPCMD_READ_10 GPCMD_READ_12
	       GPCMD_READ_CD GPCMD_READ_CDVD_CAPACITY GPCMD_READ_CD_MSF
	       GPCMD_READ_DISC_INFO GPCMD_READ_DVD_STRUCTURE
	       GPCMD_READ_FORMAT_CAPACITIES GPCMD_READ_HEADER
	       GPCMD_READ_SUBCHANNEL GPCMD_READ_TOC_PMA_ATIP
	       GPCMD_READ_TRACK_RZONE_INFO GPCMD_REPAIR_RZONE_TRACK
	       GPCMD_REPORT_KEY GPCMD_REQUEST_SENSE GPCMD_RESERVE_RZONE_TRACK
	       GPCMD_SCAN GPCMD_SEEK GPCMD_SEND_DVD_STRUCTURE GPCMD_SEND_EVENT
	       GPCMD_SEND_KEY GPCMD_SEND_OPC GPCMD_SET_READ_AHEAD
	       GPCMD_SET_SPEED GPCMD_SET_STREAMING GPCMD_START_STOP_UNIT
	       GPCMD_STOP_PLAY_SCAN GPCMD_TEST_UNIT_READY GPCMD_VERIFY_10
	       GPCMD_WRITE_10 GPCMD_WRITE_AND_VERIFY_10 GPMODE_ALL_PAGES
	       GPMODE_AUDIO_CTL_PAGE GPMODE_CAPABILITIES_PAGE GPMODE_CDROM_PAGE
	       GPMODE_FAULT_FAIL_PAGE GPMODE_POWER_PAGE GPMODE_R_W_ERROR_PAGE
	       GPMODE_TO_PROTECT_PAGE GPMODE_WRITE_PARMS_PAGE mechtype_caddy
	       mechtype_cartridge_changer mechtype_individual_changer
	       mechtype_popup mechtype_tray));

print constant_types(); # macro defs
foreach (C_constant ("Device::CDROM", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("Device::CDROM", $types);
__END__
   */

  switch (len) {
  case 7:
    return constant_7 (aTHX_ name, iv_return);
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
    return constant_16 (aTHX_ name, iv_return);
    break;
  case 17:
    return constant_17 (aTHX_ name, iv_return);
    break;
  case 18:
    return constant_18 (aTHX_ name, iv_return);
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
    /* Names all of length 25.  */
    /* GPCMD_RESERVE_RZONE_TRACK GPCMD_WRITE_AND_VERIFY_10 */
    /* Offset 12 gives the best switch position.  */
    switch (name[12]) {
    case 'A':
      if (memEQ(name, "GPCMD_WRITE_AND_VERIFY_10", 25)) {
      /*                           ^                   */
#ifdef GPCMD_WRITE_AND_VERIFY_10
        *iv_return = GPCMD_WRITE_AND_VERIFY_10;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'E':
      if (memEQ(name, "GPCMD_RESERVE_RZONE_TRACK", 25)) {
      /*                           ^                   */
#ifdef GPCMD_RESERVE_RZONE_TRACK
        *iv_return = GPCMD_RESERVE_RZONE_TRACK;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 26:
    if (memEQ(name, "mechtype_cartridge_changer", 26)) {
#ifdef mechtype_cartridge_changer
      *iv_return = mechtype_cartridge_changer;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 27:
    /* Names all of length 27.  */
    /* GPCMD_READ_TRACK_RZONE_INFO mechtype_individual_changer */
    /* Offset 22 gives the best switch position.  */
    switch (name[22]) {
    case '_':
      if (memEQ(name, "GPCMD_READ_TRACK_RZONE_INFO", 27)) {
      /*                                     ^           */
#ifdef GPCMD_READ_TRACK_RZONE_INFO
        *iv_return = GPCMD_READ_TRACK_RZONE_INFO;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'a':
      if (memEQ(name, "mechtype_individual_changer", 27)) {
      /*                                     ^           */
#ifdef mechtype_individual_changer
        *iv_return = mechtype_individual_changer;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 28:
    if (memEQ(name, "GPCMD_READ_FORMAT_CAPACITIES", 28)) {
#ifdef GPCMD_READ_FORMAT_CAPACITIES
      *iv_return = GPCMD_READ_FORMAT_CAPACITIES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 34:
    if (memEQ(name, "GPCMD_PREVENT_ALLOW_MEDIUM_REMOVAL", 34)) {
#ifdef GPCMD_PREVENT_ALLOW_MEDIUM_REMOVAL
      *iv_return = GPCMD_PREVENT_ALLOW_MEDIUM_REMOVAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 35:
    if (memEQ(name, "GPCMD_GET_EVENT_STATUS_NOTIFICATION", 35)) {
#ifdef GPCMD_GET_EVENT_STATUS_NOTIFICATION
      *iv_return = GPCMD_GET_EVENT_STATUS_NOTIFICATION;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

