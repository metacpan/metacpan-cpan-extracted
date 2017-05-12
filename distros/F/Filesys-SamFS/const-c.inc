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
constant_6 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     DEV_ON DEV_RO DT_DAT DT_LMF SS_ACL SS_AIO */
  /* Offset 4 gives the best switch position.  */
  switch (name[4]) {
  case 'A':
    if (memEQ(name, "DT_DAT", 6)) {
    /*                   ^       */
#ifdef DT_DAT
      *iv_return = DT_DAT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "SS_ACL", 6)) {
    /*                   ^       */
#ifdef SS_ACL
      *iv_return = SS_ACL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "SS_AIO", 6)) {
    /*                   ^       */
#ifdef SS_AIO
      *iv_return = SS_AIO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "DT_LMF", 6)) {
    /*                   ^       */
#ifdef DT_LMF
      *iv_return = DT_LMF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "DEV_ON", 6)) {
    /*                   ^       */
#ifdef DEV_ON
      *iv_return = DEV_ON;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "DEV_RO", 6)) {
    /*                   ^       */
#ifdef DEV_RO
      *iv_return = DEV_RO;
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
constant_7 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     DEV_OFF DT_3570 DT_3590 DT_3592 DT_9490 DT_9840 DT_9940 DT_DATA DT_DISK
     DT_META DT_RAID DT_TAPE SS_WORM S_IRGRP S_IROTH S_IRUSR S_IRWXG S_IRWXO
     S_IRWXU S_IWGRP S_IWOTH S_IWUSR S_IXGRP S_IXOTH S_IXUSR */
  /* Offset 6 gives the best switch position.  */
  switch (name[6]) {
  case '0':
    if (memEQ(name, "DT_357", 6)) {
    /*                     0     */
#ifdef DT_3570
      *iv_return = DT_3570;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DT_359", 6)) {
    /*                     0     */
#ifdef DT_3590
      *iv_return = DT_3590;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DT_949", 6)) {
    /*                     0     */
#ifdef DT_9490
      *iv_return = DT_9490;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DT_984", 6)) {
    /*                     0     */
#ifdef DT_9840
      *iv_return = DT_9840;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DT_994", 6)) {
    /*                     0     */
#ifdef DT_9940
      *iv_return = DT_9940;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '2':
    if (memEQ(name, "DT_359", 6)) {
    /*                     2     */
#ifdef DT_3592
      *iv_return = DT_3592;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'A':
    if (memEQ(name, "DT_DAT", 6)) {
    /*                     A     */
#ifdef DT_DATA
      *iv_return = DT_DATA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DT_MET", 6)) {
    /*                     A     */
#ifdef DT_META
      *iv_return = DT_META;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "DT_RAI", 6)) {
    /*                     D     */
#ifdef DT_RAID
      *iv_return = DT_RAID;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "DT_TAP", 6)) {
    /*                     E     */
#ifdef DT_TAPE
      *iv_return = DT_TAPE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "DEV_OF", 6)) {
    /*                     F     */
#ifdef DEV_OFF
      *iv_return = DEV_OFF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "S_IRWX", 6)) {
    /*                     G     */
#ifdef S_IRWXG
      *iv_return = S_IRWXG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "S_IROT", 6)) {
    /*                     H     */
#ifdef S_IROTH
      *iv_return = S_IROTH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_IWOT", 6)) {
    /*                     H     */
#ifdef S_IWOTH
      *iv_return = S_IWOTH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_IXOT", 6)) {
    /*                     H     */
#ifdef S_IXOTH
      *iv_return = S_IXOTH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'K':
    if (memEQ(name, "DT_DIS", 6)) {
    /*                     K     */
#ifdef DT_DISK
      *iv_return = DT_DISK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "SS_WOR", 6)) {
    /*                     M     */
#ifdef SS_WORM
      *iv_return = SS_WORM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "S_IRWX", 6)) {
    /*                     O     */
#ifdef S_IRWXO
      *iv_return = S_IRWXO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "S_IRGR", 6)) {
    /*                     P     */
#ifdef S_IRGRP
      *iv_return = S_IRGRP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_IWGR", 6)) {
    /*                     P     */
#ifdef S_IWGRP
      *iv_return = S_IWGRP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_IXGR", 6)) {
    /*                     P     */
#ifdef S_IXGRP
      *iv_return = S_IXGRP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "S_IRUS", 6)) {
    /*                     R     */
#ifdef S_IRUSR
      *iv_return = S_IRUSR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_IWUS", 6)) {
    /*                     R     */
#ifdef S_IWUSR
      *iv_return = S_IWUSR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_IXUS", 6)) {
    /*                     R     */
#ifdef S_IXUSR
      *iv_return = S_IXUSR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "S_IRWX", 6)) {
    /*                     U     */
#ifdef S_IRWXU
      *iv_return = S_IRWXU;
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
     CF_STALE DEV_DOWN DEV_IDLE DT_3570C DT_ROBOT DT_TITAN RI_bufio RI_nopos
     SS_CSGEN SS_CSUSE SS_CSVAL SS_DFACL SS_SAMFS */
  /* Offset 5 gives the best switch position.  */
  switch (name[5]) {
  case '7':
    if (memEQ(name, "DT_3570C", 8)) {
    /*                    ^        */
#ifdef DT_3570C
      *iv_return = DT_3570C;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'A':
    if (memEQ(name, "CF_STALE", 8)) {
    /*                    ^        */
#ifdef CF_STALE
      *iv_return = CF_STALE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SS_DFACL", 8)) {
    /*                    ^        */
#ifdef SS_DFACL
      *iv_return = SS_DFACL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "DT_ROBOT", 8)) {
    /*                    ^        */
#ifdef DT_ROBOT
      *iv_return = DT_ROBOT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "DEV_IDLE", 8)) {
    /*                    ^        */
#ifdef DEV_IDLE
      *iv_return = DEV_IDLE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "SS_CSGEN", 8)) {
    /*                    ^        */
#ifdef SS_CSGEN
      *iv_return = SS_CSGEN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "SS_SAMFS", 8)) {
    /*                    ^        */
#ifdef SS_SAMFS
      *iv_return = SS_SAMFS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "DEV_DOWN", 8)) {
    /*                    ^        */
#ifdef DEV_DOWN
      *iv_return = DEV_DOWN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "DT_TITAN", 8)) {
    /*                    ^        */
#ifdef DT_TITAN
      *iv_return = DT_TITAN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "SS_CSUSE", 8)) {
    /*                    ^        */
#ifdef SS_CSUSE
      *iv_return = SS_CSUSE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "SS_CSVAL", 8)) {
    /*                    ^        */
#ifdef SS_CSVAL
      *iv_return = SS_CSVAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'f':
    if (memEQ(name, "RI_bufio", 8)) {
    /*                    ^        */
#ifdef RI_bufio
      *iv_return = RI_bufio;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'p':
    if (memEQ(name, "RI_nopos", 8)) {
    /*                    ^        */
#ifdef RI_nopos
      *iv_return = RI_nopos;
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
     CF_ARCH_I CF_REARCH DT_ACL452 DT_CYGNET DT_EXB210 DT_EXBX80 DT_HPLIBS
     DT_IBMATL DT_METD28 DT_PSEUDO DT_SCSI_R DT_STKAPI DT_STKLXX DT_TAPE_R
     SS_DATA_V */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case '0':
    if (memEQ(name, "DT_EXB21", 8)) {
    /*                       0     */
#ifdef DT_EXB210
      *iv_return = DT_EXB210;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DT_EXBX8", 8)) {
    /*                       0     */
#ifdef DT_EXBX80
      *iv_return = DT_EXBX80;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '2':
    if (memEQ(name, "DT_ACL45", 8)) {
    /*                       2     */
#ifdef DT_ACL452
      *iv_return = DT_ACL452;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '8':
    if (memEQ(name, "DT_METD2", 8)) {
    /*                       8     */
#ifdef DT_METD28
      *iv_return = DT_METD28;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "CF_REARC", 8)) {
    /*                       H     */
#ifdef CF_REARCH
      *iv_return = CF_REARCH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "CF_ARCH_", 8)) {
    /*                       I     */
#ifdef CF_ARCH_I
      *iv_return = CF_ARCH_I;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DT_STKAP", 8)) {
    /*                       I     */
#ifdef DT_STKAPI
      *iv_return = DT_STKAPI;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "DT_IBMAT", 8)) {
    /*                       L     */
#ifdef DT_IBMATL
      *iv_return = DT_IBMATL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "DT_PSEUD", 8)) {
    /*                       O     */
#ifdef DT_PSEUDO
      *iv_return = DT_PSEUDO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "DT_SCSI_", 8)) {
    /*                       R     */
#ifdef DT_SCSI_R
      *iv_return = DT_SCSI_R;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DT_TAPE_", 8)) {
    /*                       R     */
#ifdef DT_TAPE_R
      *iv_return = DT_TAPE_R;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "DT_HPLIB", 8)) {
    /*                       S     */
#ifdef DT_HPLIBS
      *iv_return = DT_HPLIBS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "DT_CYGNE", 8)) {
    /*                       T     */
#ifdef DT_CYGNET
      *iv_return = DT_CYGNET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "SS_DATA_", 8)) {
    /*                       V     */
#ifdef SS_DATA_V
      *iv_return = SS_DATA_V;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "DT_STKLX", 8)) {
    /*                       X     */
#ifdef DT_STKLXX
      *iv_return = DT_STKLXX;
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
     CF_DAMAGED DT_ACL2640 DT_ACL_LIB DT_ADIC100 DT_ADIC448 DT_ATL1500
     DT_DLT2700 DT_DOCSTOR DT_GRAUACI DT_IBM3580 DT_IBM3584 DT_LMS4500
     DT_METD360 DT_ODI_NEO DT_OPTICAL DT_SONYAIT DT_SONYCSM DT_SONYDMS
     DT_SONYDTF DT_SONYPSC DT_SPECLOG DT_STK5800 DT_STK97XX DT_TAPE_SR
     DT_UNKNOWN DT_UNUSED1 DT_UNUSED2 DT_UNUSED3 DVST_AUDIT DVST_MAINT
     DVST_READY RI_blockio RI_foreign SS_DAMAGED SS_OFFLINE SS_PARTIAL
     SS_REMEDIA SS_SETFA_G SS_SETFA_S SS_STAGE_A SS_STAGE_N SS_STAGING */
  /* Offset 9 gives the best switch position.  */
  switch (name[9]) {
  case '0':
    if (memEQ(name, "DT_ACL264", 9)) {
    /*                        0     */
#ifdef DT_ACL2640
      *iv_return = DT_ACL2640;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DT_ADIC10", 9)) {
    /*                        0     */
#ifdef DT_ADIC100
      *iv_return = DT_ADIC100;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DT_ATL150", 9)) {
    /*                        0     */
#ifdef DT_ATL1500
      *iv_return = DT_ATL1500;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DT_DLT270", 9)) {
    /*                        0     */
#ifdef DT_DLT2700
      *iv_return = DT_DLT2700;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DT_IBM358", 9)) {
    /*                        0     */
#ifdef DT_IBM3580
      *iv_return = DT_IBM3580;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DT_LMS450", 9)) {
    /*                        0     */
#ifdef DT_LMS4500
      *iv_return = DT_LMS4500;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DT_METD36", 9)) {
    /*                        0     */
#ifdef DT_METD360
      *iv_return = DT_METD360;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DT_STK580", 9)) {
    /*                        0     */
#ifdef DT_STK5800
      *iv_return = DT_STK5800;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '1':
    if (memEQ(name, "DT_UNUSED", 9)) {
    /*                        1     */
#ifdef DT_UNUSED1
      *iv_return = DT_UNUSED1;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '2':
    if (memEQ(name, "DT_UNUSED", 9)) {
    /*                        2     */
#ifdef DT_UNUSED2
      *iv_return = DT_UNUSED2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '3':
    if (memEQ(name, "DT_UNUSED", 9)) {
    /*                        3     */
#ifdef DT_UNUSED3
      *iv_return = DT_UNUSED3;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '4':
    if (memEQ(name, "DT_IBM358", 9)) {
    /*                        4     */
#ifdef DT_IBM3584
      *iv_return = DT_IBM3584;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '8':
    if (memEQ(name, "DT_ADIC44", 9)) {
    /*                        8     */
#ifdef DT_ADIC448
      *iv_return = DT_ADIC448;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'A':
    if (memEQ(name, "SS_REMEDI", 9)) {
    /*                        A     */
#ifdef SS_REMEDIA
      *iv_return = SS_REMEDIA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SS_STAGE_", 9)) {
    /*                        A     */
#ifdef SS_STAGE_A
      *iv_return = SS_STAGE_A;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "DT_ACL_LI", 9)) {
    /*                        B     */
#ifdef DT_ACL_LIB
      *iv_return = DT_ACL_LIB;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "DT_SONYPS", 9)) {
    /*                        C     */
#ifdef DT_SONYPSC
      *iv_return = DT_SONYPSC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "CF_DAMAGE", 9)) {
    /*                        D     */
#ifdef CF_DAMAGED
      *iv_return = CF_DAMAGED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SS_DAMAGE", 9)) {
    /*                        D     */
#ifdef SS_DAMAGED
      *iv_return = SS_DAMAGED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "SS_OFFLIN", 9)) {
    /*                        E     */
#ifdef SS_OFFLINE
      *iv_return = SS_OFFLINE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "DT_SONYDT", 9)) {
    /*                        F     */
#ifdef DT_SONYDTF
      *iv_return = DT_SONYDTF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "DT_SPECLO", 9)) {
    /*                        G     */
#ifdef DT_SPECLOG
      *iv_return = DT_SPECLOG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SS_SETFA_", 9)) {
    /*                        G     */
#ifdef SS_SETFA_G
      *iv_return = SS_SETFA_G;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SS_STAGIN", 9)) {
    /*                        G     */
#ifdef SS_STAGING
      *iv_return = SS_STAGING;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "DT_GRAUAC", 9)) {
    /*                        I     */
#ifdef DT_GRAUACI
      *iv_return = DT_GRAUACI;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "DT_OPTICA", 9)) {
    /*                        L     */
#ifdef DT_OPTICAL
      *iv_return = DT_OPTICAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SS_PARTIA", 9)) {
    /*                        L     */
#ifdef SS_PARTIAL
      *iv_return = SS_PARTIAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "DT_SONYCS", 9)) {
    /*                        M     */
#ifdef DT_SONYCSM
      *iv_return = DT_SONYCSM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "DT_UNKNOW", 9)) {
    /*                        N     */
#ifdef DT_UNKNOWN
      *iv_return = DT_UNKNOWN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SS_STAGE_", 9)) {
    /*                        N     */
#ifdef SS_STAGE_N
      *iv_return = SS_STAGE_N;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "DT_ODI_NE", 9)) {
    /*                        O     */
#ifdef DT_ODI_NEO
      *iv_return = DT_ODI_NEO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "DT_DOCSTO", 9)) {
    /*                        R     */
#ifdef DT_DOCSTOR
      *iv_return = DT_DOCSTOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DT_TAPE_S", 9)) {
    /*                        R     */
#ifdef DT_TAPE_SR
      *iv_return = DT_TAPE_SR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "DT_SONYDM", 9)) {
    /*                        S     */
#ifdef DT_SONYDMS
      *iv_return = DT_SONYDMS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SS_SETFA_", 9)) {
    /*                        S     */
#ifdef SS_SETFA_S
      *iv_return = SS_SETFA_S;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "DT_SONYAI", 9)) {
    /*                        T     */
#ifdef DT_SONYAIT
      *iv_return = DT_SONYAIT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DVST_AUDI", 9)) {
    /*                        T     */
#ifdef DVST_AUDIT
      *iv_return = DVST_AUDIT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DVST_MAIN", 9)) {
    /*                        T     */
#ifdef DVST_MAINT
      *iv_return = DVST_MAINT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "DT_STK97X", 9)) {
    /*                        X     */
#ifdef DT_STK97XX
      *iv_return = DT_STK97XX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Y':
    if (memEQ(name, "DVST_READ", 9)) {
    /*                        Y     */
#ifdef DVST_READY
      *iv_return = DVST_READY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'n':
    if (memEQ(name, "RI_foreig", 9)) {
    /*                        n     */
#ifdef RI_foreign
      *iv_return = RI_foreign;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'o':
    if (memEQ(name, "RI_blocki", 9)) {
    /*                        o     */
#ifdef RI_blockio
      *iv_return = RI_blockio;
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
     CF_ARCHIVED CF_VERIFIED DEV_NOALLOC DEV_UNAVAIL DT_ADIC1000 DT_ATLP3000
     DT_DISK_SET DT_ERASABLE DT_HP_C7200 DT_META_SET DT_QUAL82xx DT_SONYSAIT
     DVST_OPENED DVST_UNLOAD MAX_ARCHIVE MAX_VOLUMES SS_ARCHDONE SS_ARCHIVED
     SS_DIRECTIO SS_READONLY */
  /* Offset 7 gives the best switch position.  */
  switch (name[7]) {
  case '1':
    if (memEQ(name, "DT_ADIC1000", 11)) {
    /*                      ^          */
#ifdef DT_ADIC1000
      *iv_return = DT_ADIC1000;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '3':
    if (memEQ(name, "DT_ATLP3000", 11)) {
    /*                      ^          */
#ifdef DT_ATLP3000
      *iv_return = DT_ATLP3000;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '7':
    if (memEQ(name, "DT_HP_C7200", 11)) {
    /*                      ^          */
#ifdef DT_HP_C7200
      *iv_return = DT_HP_C7200;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '8':
    if (memEQ(name, "DT_QUAL82xx", 11)) {
    /*                      ^          */
#ifdef DT_QUAL82xx
      *iv_return = DT_QUAL82xx;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'A':
    if (memEQ(name, "DT_ERASABLE", 11)) {
    /*                      ^          */
#ifdef DT_ERASABLE
      *iv_return = DT_ERASABLE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "SS_DIRECTIO", 11)) {
    /*                      ^          */
#ifdef SS_DIRECTIO
      *iv_return = SS_DIRECTIO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "SS_ARCHDONE", 11)) {
    /*                      ^          */
#ifdef SS_ARCHDONE
      *iv_return = SS_ARCHDONE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "DVST_OPENED", 11)) {
    /*                      ^          */
#ifdef DVST_OPENED
      *iv_return = DVST_OPENED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "CF_VERIFIED", 11)) {
    /*                      ^          */
#ifdef CF_VERIFIED
      *iv_return = CF_VERIFIED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "MAX_ARCHIVE", 11)) {
    /*                      ^          */
#ifdef MAX_ARCHIVE
      *iv_return = MAX_ARCHIVE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "CF_ARCHIVED", 11)) {
    /*                      ^          */
#ifdef CF_ARCHIVED
      *iv_return = CF_ARCHIVED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SS_ARCHIVED", 11)) {
    /*                      ^          */
#ifdef SS_ARCHIVED
      *iv_return = SS_ARCHIVED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "DEV_NOALLOC", 11)) {
    /*                      ^          */
#ifdef DEV_NOALLOC
      *iv_return = DEV_NOALLOC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DVST_UNLOAD", 11)) {
    /*                      ^          */
#ifdef DVST_UNLOAD
      *iv_return = DVST_UNLOAD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "SS_READONLY", 11)) {
    /*                      ^          */
#ifdef SS_READONLY
      *iv_return = SS_READONLY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "DT_SONYSAIT", 11)) {
    /*                      ^          */
#ifdef DT_SONYSAIT
      *iv_return = DT_SONYSAIT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "MAX_VOLUMES", 11)) {
    /*                      ^          */
#ifdef MAX_VOLUMES
      *iv_return = MAX_VOLUMES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "DEV_UNAVAIL", 11)) {
    /*                      ^          */
#ifdef DEV_UNAVAIL
      *iv_return = DEV_UNAVAIL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "DT_DISK_SET", 11)) {
    /*                      ^          */
#ifdef DT_DISK_SET
      *iv_return = DT_DISK_SET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DT_META_SET", 11)) {
    /*                      ^          */
#ifdef DT_META_SET
      *iv_return = DT_META_SET;
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
     DT_HISTORIAN DT_PLASMON_D DT_PLASMON_G DT_PSEUDO_RD DT_PSEUDO_SC
     DT_PSEUDO_SS DT_QUANTUMC4 DVST_FORWARD DVST_LABELED DVST_MOUNTED
     DVST_PRESENT DVST_SCANNED DVST_WR_LOCK SS_ARCHIVE_A SS_ARCHIVE_C
     SS_ARCHIVE_I SS_ARCHIVE_N SS_ARCHIVE_R SS_RELEASE_A SS_RELEASE_N
     SS_RELEASE_P SS_SEGMENT_A SS_SEGMENT_F SS_SEGMENT_S SS_STAGEFAIL */
  /* Offset 11 gives the best switch position.  */
  switch (name[11]) {
  case '4':
    if (memEQ(name, "DT_QUANTUMC", 11)) {
    /*                          4      */
#ifdef DT_QUANTUMC4
      *iv_return = DT_QUANTUMC4;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'A':
    if (memEQ(name, "SS_ARCHIVE_", 11)) {
    /*                          A      */
#ifdef SS_ARCHIVE_A
      *iv_return = SS_ARCHIVE_A;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SS_RELEASE_", 11)) {
    /*                          A      */
#ifdef SS_RELEASE_A
      *iv_return = SS_RELEASE_A;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SS_SEGMENT_", 11)) {
    /*                          A      */
#ifdef SS_SEGMENT_A
      *iv_return = SS_SEGMENT_A;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "DT_PSEUDO_S", 11)) {
    /*                          C      */
#ifdef DT_PSEUDO_SC
      *iv_return = DT_PSEUDO_SC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SS_ARCHIVE_", 11)) {
    /*                          C      */
#ifdef SS_ARCHIVE_C
      *iv_return = SS_ARCHIVE_C;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "DT_PLASMON_", 11)) {
    /*                          D      */
#ifdef DT_PLASMON_D
      *iv_return = DT_PLASMON_D;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DT_PSEUDO_R", 11)) {
    /*                          D      */
#ifdef DT_PSEUDO_RD
      *iv_return = DT_PSEUDO_RD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DVST_FORWAR", 11)) {
    /*                          D      */
#ifdef DVST_FORWARD
      *iv_return = DVST_FORWARD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DVST_LABELE", 11)) {
    /*                          D      */
#ifdef DVST_LABELED
      *iv_return = DVST_LABELED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DVST_MOUNTE", 11)) {
    /*                          D      */
#ifdef DVST_MOUNTED
      *iv_return = DVST_MOUNTED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DVST_SCANNE", 11)) {
    /*                          D      */
#ifdef DVST_SCANNED
      *iv_return = DVST_SCANNED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "SS_SEGMENT_", 11)) {
    /*                          F      */
#ifdef SS_SEGMENT_F
      *iv_return = SS_SEGMENT_F;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "DT_PLASMON_", 11)) {
    /*                          G      */
#ifdef DT_PLASMON_G
      *iv_return = DT_PLASMON_G;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "SS_ARCHIVE_", 11)) {
    /*                          I      */
#ifdef SS_ARCHIVE_I
      *iv_return = SS_ARCHIVE_I;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'K':
    if (memEQ(name, "DVST_WR_LOC", 11)) {
    /*                          K      */
#ifdef DVST_WR_LOCK
      *iv_return = DVST_WR_LOCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "SS_STAGEFAI", 11)) {
    /*                          L      */
#ifdef SS_STAGEFAIL
      *iv_return = SS_STAGEFAIL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "DT_HISTORIA", 11)) {
    /*                          N      */
#ifdef DT_HISTORIAN
      *iv_return = DT_HISTORIAN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SS_ARCHIVE_", 11)) {
    /*                          N      */
#ifdef SS_ARCHIVE_N
      *iv_return = SS_ARCHIVE_N;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SS_RELEASE_", 11)) {
    /*                          N      */
#ifdef SS_RELEASE_N
      *iv_return = SS_RELEASE_N;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "SS_RELEASE_", 11)) {
    /*                          P      */
#ifdef SS_RELEASE_P
      *iv_return = SS_RELEASE_P;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "SS_ARCHIVE_", 11)) {
    /*                          R      */
#ifdef SS_ARCHIVE_R
      *iv_return = SS_ARCHIVE_R;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "DT_PSEUDO_S", 11)) {
    /*                          S      */
#ifdef DT_PSEUDO_SS
      *iv_return = DT_PSEUDO_SS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SS_SEGMENT_", 11)) {
    /*                          S      */
#ifdef SS_SEGMENT_S
      *iv_return = SS_SEGMENT_S;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "DVST_PRESEN", 11)) {
    /*                          T      */
#ifdef DVST_PRESENT
      *iv_return = DVST_PRESENT;
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
     CF_UNARCHIVED DT_CLASS_MASK DT_FAMILY_SET DT_MEDIA_MASK DT_METRUM_LIB
     DT_PSEUDO_SSI DT_ROBOT_MASK DT_THIRD_MASK DT_VIDEO_TAPE DVST_CLEANING
     DVST_I_E_PORT DVST_POSITION DVST_SCANNING DVST_SCAN_ERR */
  /* Offset 5 gives the best switch position.  */
  switch (name[5]) {
  case 'A':
    if (memEQ(name, "CF_UNARCHIVED", 13)) {
    /*                    ^              */
#ifdef CF_UNARCHIVED
      *iv_return = CF_UNARCHIVED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DT_CLASS_MASK", 13)) {
    /*                    ^              */
#ifdef DT_CLASS_MASK
      *iv_return = DT_CLASS_MASK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "DT_ROBOT_MASK", 13)) {
    /*                    ^              */
#ifdef DT_ROBOT_MASK
      *iv_return = DT_ROBOT_MASK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "DVST_CLEANING", 13)) {
    /*                    ^              */
#ifdef DVST_CLEANING
      *iv_return = DVST_CLEANING;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "DT_MEDIA_MASK", 13)) {
    /*                    ^              */
#ifdef DT_MEDIA_MASK
      *iv_return = DT_MEDIA_MASK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DT_VIDEO_TAPE", 13)) {
    /*                    ^              */
#ifdef DT_VIDEO_TAPE
      *iv_return = DT_VIDEO_TAPE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "DT_PSEUDO_SSI", 13)) {
    /*                    ^              */
#ifdef DT_PSEUDO_SSI
      *iv_return = DT_PSEUDO_SSI;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "DT_THIRD_MASK", 13)) {
    /*                    ^              */
#ifdef DT_THIRD_MASK
      *iv_return = DT_THIRD_MASK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DVST_I_E_PORT", 13)) {
    /*                    ^              */
#ifdef DVST_I_E_PORT
      *iv_return = DVST_I_E_PORT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "DT_FAMILY_SET", 13)) {
    /*                    ^              */
#ifdef DT_FAMILY_SET
      *iv_return = DT_FAMILY_SET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "DVST_POSITION", 13)) {
    /*                    ^              */
#ifdef DVST_POSITION
      *iv_return = DVST_POSITION;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "DVST_SCANNING", 13)) {
    /*                    ^              */
#ifdef DVST_SCANNING
      *iv_return = DVST_SCANNING;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DVST_SCAN_ERR", 13)) {
    /*                    ^              */
#ifdef DVST_SCAN_ERR
      *iv_return = DVST_SCAN_ERR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "DT_METRUM_LIB", 13)) {
    /*                    ^              */
#ifdef DT_METRUM_LIB
      *iv_return = DT_METRUM_LIB;
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
     DT_CLASS_SHIFT DT_FUJITSU_128 DT_LINEAR_TAPE DT_PLASMON_UDO DT_SQUARE_TAPE
     DT_THIRD_PARTY DVST_ATTENTION DVST_BAD_MEDIA DVST_FS_ACTIVE DVST_READ_ONLY
     DVST_REQUESTED DVST_STOR_FULL DVST_WAIT_IDLE */
  /* Offset 7 gives the best switch position.  */
  switch (name[7]) {
  case 'A':
    if (memEQ(name, "DT_LINEAR_TAPE", 14)) {
    /*                      ^             */
#ifdef DT_LINEAR_TAPE
      *iv_return = DT_LINEAR_TAPE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DVST_READ_ONLY", 14)) {
    /*                      ^             */
#ifdef DVST_READ_ONLY
      *iv_return = DVST_READ_ONLY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "DT_THIRD_PARTY", 14)) {
    /*                      ^             */
#ifdef DT_THIRD_PARTY
      *iv_return = DT_THIRD_PARTY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DVST_BAD_MEDIA", 14)) {
    /*                      ^             */
#ifdef DVST_BAD_MEDIA
      *iv_return = DVST_BAD_MEDIA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "DVST_WAIT_IDLE", 14)) {
    /*                      ^             */
#ifdef DVST_WAIT_IDLE
      *iv_return = DVST_WAIT_IDLE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "DT_PLASMON_UDO", 14)) {
    /*                      ^             */
#ifdef DT_PLASMON_UDO
      *iv_return = DT_PLASMON_UDO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "DVST_STOR_FULL", 14)) {
    /*                      ^             */
#ifdef DVST_STOR_FULL
      *iv_return = DVST_STOR_FULL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Q':
    if (memEQ(name, "DVST_REQUESTED", 14)) {
    /*                      ^             */
#ifdef DVST_REQUESTED
      *iv_return = DVST_REQUESTED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "DT_SQUARE_TAPE", 14)) {
    /*                      ^             */
#ifdef DT_SQUARE_TAPE
      *iv_return = DT_SQUARE_TAPE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "DT_CLASS_SHIFT", 14)) {
    /*                      ^             */
#ifdef DT_CLASS_SHIFT
      *iv_return = DT_CLASS_SHIFT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "DT_FUJITSU_128", 14)) {
    /*                      ^             */
#ifdef DT_FUJITSU_128
      *iv_return = DT_FUJITSU_128;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DVST_ATTENTION", 14)) {
    /*                      ^             */
#ifdef DVST_ATTENTION
      *iv_return = DVST_ATTENTION;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "DVST_FS_ACTIVE", 14)) {
    /*                      ^             */
#ifdef DVST_FS_ACTIVE
      *iv_return = DVST_FS_ACTIVE;
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
     CF_INCONSISTENT DT_EXABYTE_TAPE DT_STRIPE_GROUP DT_WORM_OPTICAL */
  /* Offset 4 gives the best switch position.  */
  switch (name[4]) {
  case 'N':
    if (memEQ(name, "CF_INCONSISTENT", 15)) {
    /*                   ^                 */
#ifdef CF_INCONSISTENT
      *iv_return = CF_INCONSISTENT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "DT_WORM_OPTICAL", 15)) {
    /*                   ^                 */
#ifdef DT_WORM_OPTICAL
      *iv_return = DT_WORM_OPTICAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "DT_STRIPE_GROUP", 15)) {
    /*                   ^                 */
#ifdef DT_STRIPE_GROUP
      *iv_return = DT_STRIPE_GROUP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "DT_EXABYTE_TAPE", 15)) {
    /*                   ^                 */
#ifdef DT_EXABYTE_TAPE
      *iv_return = DT_EXABYTE_TAPE;
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
     DT_EXABYTE_M2_TAPE DT_SCSI_ROBOT_MASK DT_WORM_OPTICAL_12 */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'O':
    if (memEQ(name, "DT_WORM_OPTICAL_12", 18)) {
    /*                       ^                */
#ifdef DT_WORM_OPTICAL_12
      *iv_return = DT_WORM_OPTICAL_12;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "DT_SCSI_ROBOT_MASK", 18)) {
    /*                       ^                */
#ifdef DT_SCSI_ROBOT_MASK
      *iv_return = DT_SCSI_ROBOT_MASK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "DT_EXABYTE_M2_TAPE", 18)) {
    /*                       ^                */
#ifdef DT_EXABYTE_M2_TAPE
      *iv_return = DT_EXABYTE_M2_TAPE;
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
my @names = (qw(CF_ARCHIVED CF_ARCH_I CF_DAMAGED CF_INCONSISTENT CF_REARCH
	       CF_STALE CF_UNARCHIVED CF_VERIFIED DEV_DOWN DEV_IDLE DEV_NOALLOC
	       DEV_OFF DEV_ON DEV_RO DEV_UNAVAIL DT_3570 DT_3570C DT_3590
	       DT_3592 DT_9490 DT_9840 DT_9940 DT_ACL2640 DT_ACL452 DT_ACL_LIB
	       DT_ADIC100 DT_ADIC1000 DT_ADIC448 DT_ATL1500 DT_ATLP3000
	       DT_CLASS_MASK DT_CLASS_SHIFT DT_CYGNET DT_D3 DT_DAT DT_DATA
	       DT_DISK DT_DISK_SET DT_DLT2700 DT_DOCSTOR DT_ERASABLE
	       DT_EXABYTE_M2_TAPE DT_EXABYTE_TAPE DT_EXB210 DT_EXBX80
	       DT_FAMILY_SET DT_FUJITSU_128 DT_GRAUACI DT_HISTORIAN DT_HPLIBS
	       DT_HP_C7200 DT_IBM3580 DT_IBM3584 DT_IBMATL DT_LINEAR_TAPE
	       DT_LMF DT_LMS4500 DT_MEDIA_MASK DT_META DT_META_SET DT_METD28
	       DT_METD360 DT_METRUM_LIB DT_MULTIFUNCTION DT_ODI_NEO DT_OPTICAL
	       DT_PLASMON_D DT_PLASMON_G DT_PLASMON_UDO DT_PSEUDO DT_PSEUDO_RD
	       DT_PSEUDO_SC DT_PSEUDO_SS DT_PSEUDO_SSI DT_QUAL82xx DT_QUANTUMC4
	       DT_RAID DT_ROBOT DT_ROBOT_MASK DT_SCSI_R DT_SCSI_ROBOT_MASK
	       DT_SONYAIT DT_SONYCSM DT_SONYDMS DT_SONYDTF DT_SONYPSC
	       DT_SONYSAIT DT_SPECLOG DT_SQUARE_TAPE DT_STK5800 DT_STK97XX
	       DT_STKAPI DT_STKLXX DT_STRIPE_GROUP DT_STRIPE_GROUP_MASK DT_TAPE
	       DT_TAPE_R DT_TAPE_SR DT_THIRD_MASK DT_THIRD_PARTY DT_TITAN
	       DT_UNKNOWN DT_UNUSED1 DT_UNUSED2 DT_UNUSED3 DT_VIDEO_TAPE
	       DT_WORM_OPTICAL DT_WORM_OPTICAL_12 DT_xx DVST_ATTENTION
	       DVST_AUDIT DVST_BAD_MEDIA DVST_CLEANING DVST_FORWARD
	       DVST_FS_ACTIVE DVST_I_E_PORT DVST_LABELED DVST_MAINT
	       DVST_MOUNTED DVST_OPENED DVST_POSITION DVST_PRESENT DVST_READY
	       DVST_READ_ONLY DVST_REQUESTED DVST_SCANNED DVST_SCANNING
	       DVST_SCAN_ERR DVST_STOR_FULL DVST_UNLOAD DVST_WAIT_IDLE
	       DVST_WR_LOCK MAX_ARCHIVE MAX_VOLUMES RI_blockio RI_bufio
	       RI_foreign RI_nopos SAM_MIN_SEGMENT_SIZE SS_ACL SS_AIO
	       SS_ARCHDONE SS_ARCHIVED SS_ARCHIVE_A SS_ARCHIVE_C SS_ARCHIVE_I
	       SS_ARCHIVE_N SS_ARCHIVE_R SS_CSGEN SS_CSUSE SS_CSVAL SS_DAMAGED
	       SS_DATA_V SS_DFACL SS_DIRECTIO SS_OFFLINE SS_PARTIAL SS_READONLY
	       SS_RELEASE_A SS_RELEASE_N SS_RELEASE_P SS_REMEDIA SS_SAMFS
	       SS_SEGMENT_A SS_SEGMENT_F SS_SEGMENT_S SS_SETFA_G SS_SETFA_S
	       SS_STAGEFAIL SS_STAGE_A SS_STAGE_N SS_STAGING SS_WORM S_IRGRP
	       S_IROTH S_IRUSR S_IRWXG S_IRWXO S_IRWXU S_IWGRP S_IWOTH S_IWUSR
	       S_IXGRP S_IXOTH S_IXUSR));

print constant_types(); # macro defs
foreach (C_constant ("Filesys::SamFS", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("Filesys::SamFS", $types);
__END__
   */

  switch (len) {
  case 5:
    /* Names all of length 5.  */
    /* DT_D3 DT_xx */
    /* Offset 3 gives the best switch position.  */
    switch (name[3]) {
    case 'D':
      if (memEQ(name, "DT_D3", 5)) {
      /*                  ^       */
#ifdef DT_D3
        *iv_return = DT_D3;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'x':
      if (memEQ(name, "DT_xx", 5)) {
      /*                  ^       */
#ifdef DT_xx
        *iv_return = DT_xx;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 6:
    return constant_6 (aTHX_ name, iv_return);
    break;
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
    if (memEQ(name, "DT_MULTIFUNCTION", 16)) {
#ifdef DT_MULTIFUNCTION
      *iv_return = DT_MULTIFUNCTION;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 18:
    return constant_18 (aTHX_ name, iv_return);
    break;
  case 20:
    /* Names all of length 20.  */
    /* DT_STRIPE_GROUP_MASK SAM_MIN_SEGMENT_SIZE */
    /* Offset 14 gives the best switch position.  */
    switch (name[14]) {
    case 'P':
      if (memEQ(name, "DT_STRIPE_GROUP_MASK", 20)) {
      /*                             ^            */
#ifdef DT_STRIPE_GROUP_MASK
        *iv_return = DT_STRIPE_GROUP_MASK;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'T':
      if (memEQ(name, "SAM_MIN_SEGMENT_SIZE", 20)) {
      /*                             ^            */
#ifdef SAM_MIN_SEGMENT_SIZE
        *iv_return = SAM_MIN_SEGMENT_SIZE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

