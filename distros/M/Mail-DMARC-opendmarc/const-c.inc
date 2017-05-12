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
constant_17 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     DMARC_POLICY_NONE DMARC_POLICY_PASS DMARC_RECORD_FO_0 DMARC_RECORD_FO_1
     DMARC_RECORD_FO_D DMARC_RECORD_FO_S */
  /* Offset 16 gives the best switch position.  */
  switch (name[16]) {
  case '0':
    if (memEQ(name, "DMARC_RECORD_FO_", 16)) {
    /*                               0      */
#ifdef DMARC_RECORD_FO_0
      *iv_return = DMARC_RECORD_FO_0;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '1':
    if (memEQ(name, "DMARC_RECORD_FO_", 16)) {
    /*                               1      */
#ifdef DMARC_RECORD_FO_1
      *iv_return = DMARC_RECORD_FO_1;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "DMARC_RECORD_FO_", 16)) {
    /*                               D      */
#ifdef DMARC_RECORD_FO_D
      *iv_return = DMARC_RECORD_FO_D;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "DMARC_POLICY_NON", 16)) {
    /*                               E      */
#ifdef DMARC_POLICY_NONE
      *iv_return = DMARC_POLICY_NONE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "DMARC_POLICY_PAS", 16)) {
    /*                               S      */
#ifdef DMARC_POLICY_PASS
      *iv_return = DMARC_POLICY_PASS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DMARC_RECORD_FO_", 16)) {
    /*                               S      */
#ifdef DMARC_RECORD_FO_S
      *iv_return = DMARC_RECORD_FO_S;
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
     DMARC_POLICY_ABSENT DMARC_POLICY_REJECT DMARC_RECORD_P_NONE */
  /* Offset 15 gives the best switch position.  */
  switch (name[15]) {
  case 'J':
    if (memEQ(name, "DMARC_POLICY_REJECT", 19)) {
    /*                              ^          */
#ifdef DMARC_POLICY_REJECT
      *iv_return = DMARC_POLICY_REJECT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "DMARC_RECORD_P_NONE", 19)) {
    /*                              ^          */
#ifdef DMARC_RECORD_P_NONE
      *iv_return = DMARC_RECORD_P_NONE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "DMARC_POLICY_ABSENT", 19)) {
    /*                              ^          */
#ifdef DMARC_POLICY_ABSENT
      *iv_return = DMARC_POLICY_ABSENT;
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
     DMARC_RECORD_A_STRICT DMARC_RECORD_P_REJECT DMARC_RECORD_RF_IODEF
     OPENDMARC_LIB_VERSION */
  /* Offset 17 gives the best switch position.  */
  switch (name[17]) {
  case 'J':
    if (memEQ(name, "DMARC_RECORD_P_REJECT", 21)) {
    /*                                ^          */
#ifdef DMARC_RECORD_P_REJECT
      *iv_return = DMARC_RECORD_P_REJECT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "DMARC_RECORD_RF_IODEF", 21)) {
    /*                                ^          */
#ifdef DMARC_RECORD_RF_IODEF
      *iv_return = DMARC_RECORD_RF_IODEF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "DMARC_RECORD_A_STRICT", 21)) {
    /*                                ^          */
#ifdef DMARC_RECORD_A_STRICT
      *iv_return = DMARC_RECORD_A_STRICT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "OPENDMARC_LIB_VERSION", 21)) {
    /*                                ^          */
#ifdef OPENDMARC_LIB_VERSION
      *iv_return = OPENDMARC_LIB_VERSION;
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
     DMARC_PARSE_ERROR_EMPTY DMARC_POLICY_QUARANTINE DMARC_TLD_ERROR_UNKNOWN
     OPENDMARC_TLD_TYPE_NONE */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'C':
    if (memEQ(name, "OPENDMARC_TLD_TYPE_NONE", 23)) {
    /*                       ^                     */
#ifdef OPENDMARC_TLD_TYPE_NONE
      *iv_return = OPENDMARC_TLD_TYPE_NONE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "DMARC_TLD_ERROR_UNKNOWN", 23)) {
    /*                       ^                     */
#ifdef DMARC_TLD_ERROR_UNKNOWN
      *iv_return = DMARC_TLD_ERROR_UNKNOWN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "DMARC_POLICY_QUARANTINE", 23)) {
    /*                       ^                     */
#ifdef DMARC_POLICY_QUARANTINE
      *iv_return = DMARC_POLICY_QUARANTINE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "DMARC_PARSE_ERROR_EMPTY", 23)) {
    /*                       ^                     */
#ifdef DMARC_PARSE_ERROR_EMPTY
      *iv_return = DMARC_PARSE_ERROR_EMPTY;
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
     DMARC_DNS_ERROR_NXDOMAIN DMARC_FROM_DOMAIN_ABSENT OPENDMARC_MAX_NSADDRLIST
     */
  /* Offset 6 gives the best switch position.  */
  switch (name[6]) {
  case 'A':
    if (memEQ(name, "OPENDMARC_MAX_NSADDRLIST", 24)) {
    /*                     ^                        */
#ifdef OPENDMARC_MAX_NSADDRLIST
      *iv_return = OPENDMARC_MAX_NSADDRLIST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "DMARC_DNS_ERROR_NXDOMAIN", 24)) {
    /*                     ^                        */
#ifdef DMARC_DNS_ERROR_NXDOMAIN
      *iv_return = DMARC_DNS_ERROR_NXDOMAIN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "DMARC_FROM_DOMAIN_ABSENT", 24)) {
    /*                     ^                        */
#ifdef DMARC_FROM_DOMAIN_ABSENT
      *iv_return = DMARC_FROM_DOMAIN_ABSENT;
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
constant_25 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     DMARC_DNS_ERROR_NO_RECORD DMARC_POLICY_IP_TYPE_IPV4
     DMARC_POLICY_IP_TYPE_IPV6 DMARC_RECORD_P_QUARANTINE */
  /* Offset 24 gives the best switch position.  */
  switch (name[24]) {
  case '4':
    if (memEQ(name, "DMARC_POLICY_IP_TYPE_IPV", 24)) {
    /*                                       4      */
#ifdef DMARC_POLICY_IP_TYPE_IPV4
      *iv_return = DMARC_POLICY_IP_TYPE_IPV4;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '6':
    if (memEQ(name, "DMARC_POLICY_IP_TYPE_IPV", 24)) {
    /*                                       6      */
#ifdef DMARC_POLICY_IP_TYPE_IPV6
      *iv_return = DMARC_POLICY_IP_TYPE_IPV6;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "DMARC_DNS_ERROR_NO_RECOR", 24)) {
    /*                                       D      */
#ifdef DMARC_DNS_ERROR_NO_RECORD
      *iv_return = DMARC_DNS_ERROR_NO_RECORD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "DMARC_RECORD_P_QUARANTIN", 24)) {
    /*                                       E      */
#ifdef DMARC_RECORD_P_QUARANTINE
      *iv_return = DMARC_RECORD_P_QUARANTINE;
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
constant_26 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     DMARC_PARSE_ERROR_NO_ALLOC DMARC_PARSE_ERROR_NULL_CTX
     DMARC_RECORD_A_UNSPECIFIED DMARC_RECORD_P_UNSPECIFIED
     OPENDMARC_TLD_TYPE_MOZILLA */
  /* Offset 24 gives the best switch position.  */
  switch (name[24]) {
  case 'E':
    if (memEQ(name, "DMARC_RECORD_A_UNSPECIFIED", 26)) {
    /*                                       ^        */
#ifdef DMARC_RECORD_A_UNSPECIFIED
      *iv_return = DMARC_RECORD_A_UNSPECIFIED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DMARC_RECORD_P_UNSPECIFIED", 26)) {
    /*                                       ^        */
#ifdef DMARC_RECORD_P_UNSPECIFIED
      *iv_return = DMARC_RECORD_P_UNSPECIFIED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "OPENDMARC_TLD_TYPE_MOZILLA", 26)) {
    /*                                       ^        */
#ifdef OPENDMARC_TLD_TYPE_MOZILLA
      *iv_return = OPENDMARC_TLD_TYPE_MOZILLA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "DMARC_PARSE_ERROR_NO_ALLOC", 26)) {
    /*                                       ^        */
#ifdef DMARC_PARSE_ERROR_NO_ALLOC
      *iv_return = DMARC_PARSE_ERROR_NO_ALLOC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "DMARC_PARSE_ERROR_NULL_CTX", 26)) {
    /*                                       ^        */
#ifdef DMARC_PARSE_ERROR_NULL_CTX
      *iv_return = DMARC_PARSE_ERROR_NULL_CTX;
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
constant_27 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     DMARC_PARSE_ERROR_BAD_VALUE DMARC_PARSE_ERROR_NO_DOMAIN
     DMARC_RECORD_FO_UNSPECIFIED DMARC_RECORD_RF_UNSPECIFIED */
  /* Offset 26 gives the best switch position.  */
  switch (name[26]) {
  case 'D':
    if (memEQ(name, "DMARC_RECORD_FO_UNSPECIFIE", 26)) {
    /*                                         D      */
#ifdef DMARC_RECORD_FO_UNSPECIFIED
      *iv_return = DMARC_RECORD_FO_UNSPECIFIED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DMARC_RECORD_RF_UNSPECIFIE", 26)) {
    /*                                         D      */
#ifdef DMARC_RECORD_RF_UNSPECIFIED
      *iv_return = DMARC_RECORD_RF_UNSPECIFIED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "DMARC_PARSE_ERROR_BAD_VALU", 26)) {
    /*                                         E      */
#ifdef DMARC_PARSE_ERROR_BAD_VALUE
      *iv_return = DMARC_PARSE_ERROR_BAD_VALUE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "DMARC_PARSE_ERROR_NO_DOMAI", 26)) {
    /*                                         N      */
#ifdef DMARC_PARSE_ERROR_NO_DOMAIN
      *iv_return = DMARC_PARSE_ERROR_NO_DOMAIN;
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
constant_29 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     DMARC_PARSE_ERROR_BAD_VERSION DMARC_POLICY_SPF_OUTCOME_FAIL
     DMARC_POLICY_SPF_OUTCOME_NONE DMARC_POLICY_SPF_OUTCOME_PASS */
  /* Offset 27 gives the best switch position.  */
  switch (name[27]) {
  case 'I':
    if (memEQ(name, "DMARC_POLICY_SPF_OUTCOME_FAIL", 29)) {
    /*                                          ^        */
#ifdef DMARC_POLICY_SPF_OUTCOME_FAIL
      *iv_return = DMARC_POLICY_SPF_OUTCOME_FAIL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "DMARC_POLICY_SPF_OUTCOME_NONE", 29)) {
    /*                                          ^        */
#ifdef DMARC_POLICY_SPF_OUTCOME_NONE
      *iv_return = DMARC_POLICY_SPF_OUTCOME_NONE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "DMARC_PARSE_ERROR_BAD_VERSION", 29)) {
    /*                                          ^        */
#ifdef DMARC_PARSE_ERROR_BAD_VERSION
      *iv_return = DMARC_PARSE_ERROR_BAD_VERSION;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "DMARC_POLICY_SPF_OUTCOME_PASS", 29)) {
    /*                                          ^        */
#ifdef DMARC_POLICY_SPF_OUTCOME_PASS
      *iv_return = DMARC_POLICY_SPF_OUTCOME_PASS;
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
constant_30 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     DMARC_POLICY_DKIM_OUTCOME_FAIL DMARC_POLICY_DKIM_OUTCOME_NONE
     DMARC_POLICY_DKIM_OUTCOME_PASS */
  /* Offset 26 gives the best switch position.  */
  switch (name[26]) {
  case 'F':
    if (memEQ(name, "DMARC_POLICY_DKIM_OUTCOME_FAIL", 30)) {
    /*                                         ^          */
#ifdef DMARC_POLICY_DKIM_OUTCOME_FAIL
      *iv_return = DMARC_POLICY_DKIM_OUTCOME_FAIL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "DMARC_POLICY_DKIM_OUTCOME_NONE", 30)) {
    /*                                         ^          */
#ifdef DMARC_POLICY_DKIM_OUTCOME_NONE
      *iv_return = DMARC_POLICY_DKIM_OUTCOME_NONE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "DMARC_POLICY_DKIM_OUTCOME_PASS", 30)) {
    /*                                         ^          */
#ifdef DMARC_POLICY_DKIM_OUTCOME_PASS
      *iv_return = DMARC_POLICY_DKIM_OUTCOME_PASS;
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
constant_31 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     DMARC_PARSE_ERROR_BAD_SPF_MACRO DMARC_PARSE_ERROR_NO_REQUIRED_P
     DMARC_POLICY_SPF_ALIGNMENT_FAIL DMARC_POLICY_SPF_ALIGNMENT_PASS */
  /* Offset 30 gives the best switch position.  */
  switch (name[30]) {
  case 'L':
    if (memEQ(name, "DMARC_POLICY_SPF_ALIGNMENT_FAI", 30)) {
    /*                                             L      */
#ifdef DMARC_POLICY_SPF_ALIGNMENT_FAIL
      *iv_return = DMARC_POLICY_SPF_ALIGNMENT_FAIL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "DMARC_PARSE_ERROR_BAD_SPF_MACR", 30)) {
    /*                                             O      */
#ifdef DMARC_PARSE_ERROR_BAD_SPF_MACRO
      *iv_return = DMARC_PARSE_ERROR_BAD_SPF_MACRO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "DMARC_PARSE_ERROR_NO_REQUIRED_", 30)) {
    /*                                             P      */
#ifdef DMARC_PARSE_ERROR_NO_REQUIRED_P
      *iv_return = DMARC_PARSE_ERROR_NO_REQUIRED_P;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "DMARC_POLICY_SPF_ALIGNMENT_PAS", 30)) {
    /*                                             S      */
#ifdef DMARC_POLICY_SPF_ALIGNMENT_PASS
      *iv_return = DMARC_POLICY_SPF_ALIGNMENT_PASS;
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
constant_32 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     DMARC_PARSE_ERROR_BAD_DKIM_MACRO DMARC_POLICY_DKIM_ALIGNMENT_FAIL
     DMARC_POLICY_DKIM_ALIGNMENT_PASS DMARC_POLICY_SPF_ORIGIN_MAILFROM
     DMARC_POLICY_SPF_OUTCOME_TMPFAIL */
  /* Offset 20 gives the best switch position.  */
  switch (name[20]) {
  case 'C':
    if (memEQ(name, "DMARC_POLICY_SPF_OUTCOME_TMPFAIL", 32)) {
    /*                                   ^                  */
#ifdef DMARC_POLICY_SPF_OUTCOME_TMPFAIL
      *iv_return = DMARC_POLICY_SPF_OUTCOME_TMPFAIL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "DMARC_PARSE_ERROR_BAD_DKIM_MACRO", 32)) {
    /*                                   ^                  */
#ifdef DMARC_PARSE_ERROR_BAD_DKIM_MACRO
      *iv_return = DMARC_PARSE_ERROR_BAD_DKIM_MACRO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "DMARC_POLICY_SPF_ORIGIN_MAILFROM", 32)) {
    /*                                   ^                  */
#ifdef DMARC_POLICY_SPF_ORIGIN_MAILFROM
      *iv_return = DMARC_POLICY_SPF_ORIGIN_MAILFROM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "DMARC_POLICY_DKIM_ALIGNMENT_FAIL", 32)) {
    /*                                   ^                  */
#ifdef DMARC_POLICY_DKIM_ALIGNMENT_FAIL
      *iv_return = DMARC_POLICY_DKIM_ALIGNMENT_FAIL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DMARC_POLICY_DKIM_ALIGNMENT_PASS", 32)) {
    /*                                   ^                  */
#ifdef DMARC_POLICY_DKIM_ALIGNMENT_PASS
      *iv_return = DMARC_POLICY_DKIM_ALIGNMENT_PASS;
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
my @names = (qw(DMARC_DNS_ERROR_NO_RECORD DMARC_DNS_ERROR_NXDOMAIN
	       DMARC_DNS_ERROR_TMPERR DMARC_FROM_DOMAIN_ABSENT
	       DMARC_MAXHOSTNAMELEN DMARC_PARSE_ERROR_BAD_DKIM_MACRO
	       DMARC_PARSE_ERROR_BAD_SPF_MACRO DMARC_PARSE_ERROR_BAD_VALUE
	       DMARC_PARSE_ERROR_BAD_VERSION DMARC_PARSE_ERROR_EMPTY
	       DMARC_PARSE_ERROR_NO_ALLOC DMARC_PARSE_ERROR_NO_DOMAIN
	       DMARC_PARSE_ERROR_NO_REQUIRED_P DMARC_PARSE_ERROR_NULL_CTX
	       DMARC_PARSE_OKAY DMARC_POLICY_ABSENT
	       DMARC_POLICY_DKIM_ALIGNMENT_FAIL
	       DMARC_POLICY_DKIM_ALIGNMENT_PASS DMARC_POLICY_DKIM_OUTCOME_FAIL
	       DMARC_POLICY_DKIM_OUTCOME_NONE DMARC_POLICY_DKIM_OUTCOME_PASS
	       DMARC_POLICY_DKIM_OUTCOME_TMPFAIL DMARC_POLICY_IP_TYPE_IPV4
	       DMARC_POLICY_IP_TYPE_IPV6 DMARC_POLICY_NONE DMARC_POLICY_PASS
	       DMARC_POLICY_QUARANTINE DMARC_POLICY_REJECT
	       DMARC_POLICY_SPF_ALIGNMENT_FAIL DMARC_POLICY_SPF_ALIGNMENT_PASS
	       DMARC_POLICY_SPF_ORIGIN_HELO DMARC_POLICY_SPF_ORIGIN_MAILFROM
	       DMARC_POLICY_SPF_OUTCOME_FAIL DMARC_POLICY_SPF_OUTCOME_NONE
	       DMARC_POLICY_SPF_OUTCOME_PASS DMARC_POLICY_SPF_OUTCOME_TMPFAIL
	       DMARC_RECORD_A_RELAXED DMARC_RECORD_A_STRICT
	       DMARC_RECORD_A_UNSPECIFIED DMARC_RECORD_FO_0 DMARC_RECORD_FO_1
	       DMARC_RECORD_FO_D DMARC_RECORD_FO_S DMARC_RECORD_FO_UNSPECIFIED
	       DMARC_RECORD_P_NONE DMARC_RECORD_P_QUARANTINE
	       DMARC_RECORD_P_REJECT DMARC_RECORD_P_UNSPECIFIED
	       DMARC_RECORD_RF_AFRF DMARC_RECORD_RF_IODEF
	       DMARC_RECORD_RF_UNSPECIFIED DMARC_TLD_ERROR_UNKNOWN MAXNS
	       MAXPATHLEN OPENDMARC_LIB_VERSION OPENDMARC_MAX_NSADDRLIST
	       OPENDMARC_TLD_TYPE_MOZILLA OPENDMARC_TLD_TYPE_NONE));

print constant_types(), "\n"; # macro defs
foreach (C_constant ("Mail::DMARC::opendmarc", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("Mail::DMARC::opendmarc", $types);
__END__
   */

  switch (len) {
  case 5:
    if (memEQ(name, "MAXNS", 5)) {
#ifdef MAXNS
      *iv_return = MAXNS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 10:
    if (memEQ(name, "MAXPATHLEN", 10)) {
#ifdef MAXPATHLEN
      *iv_return = MAXPATHLEN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 16:
    if (memEQ(name, "DMARC_PARSE_OKAY", 16)) {
#ifdef DMARC_PARSE_OKAY
      *iv_return = DMARC_PARSE_OKAY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 17:
    return constant_17 (aTHX_ name, iv_return);
    break;
  case 19:
    return constant_19 (aTHX_ name, iv_return);
    break;
  case 20:
    /* Names all of length 20.  */
    /* DMARC_MAXHOSTNAMELEN DMARC_RECORD_RF_AFRF */
    /* Offset 10 gives the best switch position.  */
    switch (name[10]) {
    case 'O':
      if (memEQ(name, "DMARC_MAXHOSTNAMELEN", 20)) {
      /*                         ^                */
#ifdef DMARC_MAXHOSTNAMELEN
        *iv_return = DMARC_MAXHOSTNAMELEN;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'R':
      if (memEQ(name, "DMARC_RECORD_RF_AFRF", 20)) {
      /*                         ^                */
#ifdef DMARC_RECORD_RF_AFRF
        *iv_return = DMARC_RECORD_RF_AFRF;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 21:
    return constant_21 (aTHX_ name, iv_return);
    break;
  case 22:
    /* Names all of length 22.  */
    /* DMARC_DNS_ERROR_TMPERR DMARC_RECORD_A_RELAXED */
    /* Offset 17 gives the best switch position.  */
    switch (name[17]) {
    case 'L':
      if (memEQ(name, "DMARC_RECORD_A_RELAXED", 22)) {
      /*                                ^           */
#ifdef DMARC_RECORD_A_RELAXED
        *iv_return = DMARC_RECORD_A_RELAXED;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'M':
      if (memEQ(name, "DMARC_DNS_ERROR_TMPERR", 22)) {
      /*                                ^           */
#ifdef DMARC_DNS_ERROR_TMPERR
        *iv_return = DMARC_DNS_ERROR_TMPERR;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
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
    if (memEQ(name, "DMARC_POLICY_SPF_ORIGIN_HELO", 28)) {
#ifdef DMARC_POLICY_SPF_ORIGIN_HELO
      *iv_return = DMARC_POLICY_SPF_ORIGIN_HELO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
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
    if (memEQ(name, "DMARC_POLICY_DKIM_OUTCOME_TMPFAIL", 33)) {
#ifdef DMARC_POLICY_DKIM_OUTCOME_TMPFAIL
      *iv_return = DMARC_POLICY_DKIM_OUTCOME_TMPFAIL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

