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
     AF_TIPC PF_TIPC TIPC_OK */
  /* Offset 0 gives the best switch position.  */
  switch (*name++) {
  case 'A':
    if (memEQ(name, "F_TIPC", 6)) {
    /*                A            */
#ifdef AF_TIPC
      *iv_return = AF_TIPC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "F_TIPC", 6)) {
    /*                P            */
#ifdef PF_TIPC
      *iv_return = PF_TIPC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "IPC_OK", 6)) {
    /*                T            */
#ifdef TIPC_OK
      *iv_return = TIPC_OK;
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
     TIPC_ADDR_ID TIPC_CFG_SRV TIPC_ERRINFO TIPC_RETDATA TIPC_TOP_SRV */
  /* Offset 6 gives the best switch position.  */
  switch (name[6]) {
  case 'D':
    if (memEQ(name, "TIPC_ADDR_ID", 12)) {
    /*                     ^            */
#ifdef TIPC_ADDR_ID
      *iv_return = TIPC_ADDR_ID;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "TIPC_RETDATA", 12)) {
    /*                     ^            */
#ifdef TIPC_RETDATA
      *iv_return = TIPC_RETDATA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "TIPC_CFG_SRV", 12)) {
    /*                     ^            */
#ifdef TIPC_CFG_SRV
      *iv_return = TIPC_CFG_SRV;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "TIPC_TOP_SRV", 12)) {
    /*                     ^            */
#ifdef TIPC_TOP_SRV
      *iv_return = TIPC_TOP_SRV;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "TIPC_ERRINFO", 12)) {
    /*                     ^            */
#ifdef TIPC_ERRINFO
      *iv_return = TIPC_ERRINFO;
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
     TIPC_ADDR_NAME TIPC_PUBLISHED TIPC_SUB_PORTS TIPC_WITHDRAWN */
  /* Offset 10 gives the best switch position.  */
  switch (name[10]) {
  case 'N':
    if (memEQ(name, "TIPC_ADDR_NAME", 14)) {
    /*                         ^          */
#ifdef TIPC_ADDR_NAME
      *iv_return = TIPC_ADDR_NAME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "TIPC_SUB_PORTS", 14)) {
    /*                         ^          */
#ifdef TIPC_SUB_PORTS
      *iv_return = TIPC_SUB_PORTS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "TIPC_WITHDRAWN", 14)) {
    /*                         ^          */
#ifdef TIPC_WITHDRAWN
      *iv_return = TIPC_WITHDRAWN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "TIPC_PUBLISHED", 14)) {
    /*                         ^          */
#ifdef TIPC_PUBLISHED
      *iv_return = TIPC_PUBLISHED;
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
     TIPC_ADDR_MCAST TIPC_IMPORTANCE TIPC_NODE_SCOPE TIPC_ZONE_SCOPE */
  /* Offset 5 gives the best switch position.  */
  switch (name[5]) {
  case 'A':
    if (memEQ(name, "TIPC_ADDR_MCAST", 15)) {
    /*                    ^                */
#ifdef TIPC_ADDR_MCAST
      *iv_return = TIPC_ADDR_MCAST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "TIPC_IMPORTANCE", 15)) {
    /*                    ^                */
#ifdef TIPC_IMPORTANCE
      *iv_return = TIPC_IMPORTANCE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "TIPC_NODE_SCOPE", 15)) {
    /*                    ^                */
#ifdef TIPC_NODE_SCOPE
      *iv_return = TIPC_NODE_SCOPE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Z':
    if (memEQ(name, "TIPC_ZONE_SCOPE", 15)) {
    /*                    ^                */
#ifdef TIPC_ZONE_SCOPE
      *iv_return = TIPC_ZONE_SCOPE;
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
     TIPC_ERR_NO_NAME TIPC_ERR_NO_NODE TIPC_ERR_NO_PORT TIPC_SUB_SERVICE */
  /* Offset 14 gives the best switch position.  */
  switch (name[14]) {
  case 'C':
    if (memEQ(name, "TIPC_SUB_SERVICE", 16)) {
    /*                             ^        */
#ifdef TIPC_SUB_SERVICE
      *iv_return = TIPC_SUB_SERVICE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "TIPC_ERR_NO_NODE", 16)) {
    /*                             ^        */
#ifdef TIPC_ERR_NO_NODE
      *iv_return = TIPC_ERR_NO_NODE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "TIPC_ERR_NO_NAME", 16)) {
    /*                             ^        */
#ifdef TIPC_ERR_NO_NAME
      *iv_return = TIPC_ERR_NO_NAME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "TIPC_ERR_NO_PORT", 16)) {
    /*                             ^        */
#ifdef TIPC_ERR_NO_PORT
      *iv_return = TIPC_ERR_NO_PORT;
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
     TIPC_ADDR_NAMESEQ TIPC_CONN_TIMEOUT TIPC_ERR_OVERLOAD TIPC_WAIT_FOREVER */
  /* Offset 7 gives the best switch position.  */
  switch (name[7]) {
  case 'D':
    if (memEQ(name, "TIPC_ADDR_NAMESEQ", 17)) {
    /*                      ^                */
#ifdef TIPC_ADDR_NAMESEQ
      *iv_return = TIPC_ADDR_NAMESEQ;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "TIPC_WAIT_FOREVER", 17)) {
    /*                      ^                */
#ifdef TIPC_WAIT_FOREVER
      *iv_return = TIPC_WAIT_FOREVER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "TIPC_CONN_TIMEOUT", 17)) {
    /*                      ^                */
#ifdef TIPC_CONN_TIMEOUT
      *iv_return = TIPC_CONN_TIMEOUT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "TIPC_ERR_OVERLOAD", 17)) {
    /*                      ^                */
#ifdef TIPC_ERR_OVERLOAD
      *iv_return = TIPC_ERR_OVERLOAD;
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
     TIPC_CLUSTER_SCOPE TIPC_CONN_SHUTDOWN TIPC_SRC_DROPPABLE */
  /* Offset 14 gives the best switch position.  */
  switch (name[14]) {
  case 'A':
    if (memEQ(name, "TIPC_SRC_DROPPABLE", 18)) {
    /*                             ^          */
#ifdef TIPC_SRC_DROPPABLE
      *iv_return = TIPC_SRC_DROPPABLE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "TIPC_CLUSTER_SCOPE", 18)) {
    /*                             ^          */
#ifdef TIPC_CLUSTER_SCOPE
      *iv_return = TIPC_CLUSTER_SCOPE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "TIPC_CONN_SHUTDOWN", 18)) {
    /*                             ^          */
#ifdef TIPC_CONN_SHUTDOWN
      *iv_return = TIPC_CONN_SHUTDOWN;
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
     TIPC_DEST_DROPPABLE TIPC_LOW_IMPORTANCE TIPC_RESERVED_TYPES
     TIPC_SUBSCR_TIMEOUT TIPC_SUB_SINGLE_EVT */
  /* Offset 16 gives the best switch position.  */
  switch (name[16]) {
  case 'B':
    if (memEQ(name, "TIPC_DEST_DROPPABLE", 19)) {
    /*                               ^         */
#ifdef TIPC_DEST_DROPPABLE
      *iv_return = TIPC_DEST_DROPPABLE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "TIPC_SUB_SINGLE_EVT", 19)) {
    /*                               ^         */
#ifdef TIPC_SUB_SINGLE_EVT
      *iv_return = TIPC_SUB_SINGLE_EVT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "TIPC_LOW_IMPORTANCE", 19)) {
    /*                               ^         */
#ifdef TIPC_LOW_IMPORTANCE
      *iv_return = TIPC_LOW_IMPORTANCE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "TIPC_SUBSCR_TIMEOUT", 19)) {
    /*                               ^         */
#ifdef TIPC_SUBSCR_TIMEOUT
      *iv_return = TIPC_SUBSCR_TIMEOUT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "TIPC_RESERVED_TYPES", 19)) {
    /*                               ^         */
#ifdef TIPC_RESERVED_TYPES
      *iv_return = TIPC_RESERVED_TYPES;
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

#!/usr/bin/perl5.8.8 -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(AF_TIPC PF_TIPC SOL_TIPC TIPC_ADDR_ID TIPC_ADDR_MCAST
	       TIPC_ADDR_NAME TIPC_ADDR_NAMESEQ TIPC_CFG_SRV TIPC_CLUSTER_SCOPE
	       TIPC_CONN_SHUTDOWN TIPC_CONN_TIMEOUT TIPC_CRITICAL_IMPORTANCE
	       TIPC_DESTNAME TIPC_DEST_DROPPABLE TIPC_ERRINFO TIPC_ERR_NO_NAME
	       TIPC_ERR_NO_NODE TIPC_ERR_NO_PORT TIPC_ERR_OVERLOAD
	       TIPC_HIGH_IMPORTANCE TIPC_IMPORTANCE TIPC_LOW_IMPORTANCE
	       TIPC_MAX_USER_MSG_SIZE TIPC_MEDIUM_IMPORTANCE TIPC_NODE_SCOPE
	       TIPC_OK TIPC_PUBLISHED TIPC_RESERVED_TYPES TIPC_RETDATA
	       TIPC_SRC_DROPPABLE TIPC_SUBSCR_TIMEOUT TIPC_SUB_NO_BIND_EVTS
	       TIPC_SUB_NO_UNBIND_EVTS TIPC_SUB_PORTS TIPC_SUB_SERVICE
	       TIPC_SUB_SINGLE_EVT TIPC_TOP_SRV TIPC_WAIT_FOREVER
	       TIPC_WITHDRAWN TIPC_ZONE_SCOPE));

print constant_types(); # macro defs
foreach (C_constant ("IO::Socket::TIPC", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("IO::Socket::TIPC", $types);
__END__
   */

  switch (len) {
  case 7:
    return constant_7 (aTHX_ name, iv_return);
    break;
  case 8:
    if (memEQ(name, "SOL_TIPC", 8)) {
#ifdef SOL_TIPC
      *iv_return = SOL_TIPC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 12:
    return constant_12 (aTHX_ name, iv_return);
    break;
  case 13:
    if (memEQ(name, "TIPC_DESTNAME", 13)) {
#ifdef TIPC_DESTNAME
      *iv_return = TIPC_DESTNAME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
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
    if (memEQ(name, "TIPC_HIGH_IMPORTANCE", 20)) {
#ifdef TIPC_HIGH_IMPORTANCE
      *iv_return = TIPC_HIGH_IMPORTANCE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 21:
    if (memEQ(name, "TIPC_SUB_NO_BIND_EVTS", 21)) {
#ifdef TIPC_SUB_NO_BIND_EVTS
      *iv_return = TIPC_SUB_NO_BIND_EVTS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 22:
    /* Names all of length 22.  */
    /* TIPC_MAX_USER_MSG_SIZE TIPC_MEDIUM_IMPORTANCE */
    /* Offset 14 gives the best switch position.  */
    switch (name[14]) {
    case 'M':
      if (memEQ(name, "TIPC_MAX_USER_MSG_SIZE", 22)) {
      /*                             ^              */
#ifdef TIPC_MAX_USER_MSG_SIZE
        *iv_return = TIPC_MAX_USER_MSG_SIZE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'P':
      if (memEQ(name, "TIPC_MEDIUM_IMPORTANCE", 22)) {
      /*                             ^              */
#ifdef TIPC_MEDIUM_IMPORTANCE
        *iv_return = TIPC_MEDIUM_IMPORTANCE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 23:
    if (memEQ(name, "TIPC_SUB_NO_UNBIND_EVTS", 23)) {
#ifdef TIPC_SUB_NO_UNBIND_EVTS
      *iv_return = TIPC_SUB_NO_UNBIND_EVTS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 24:
    if (memEQ(name, "TIPC_CRITICAL_IMPORTANCE", 24)) {
#ifdef TIPC_CRITICAL_IMPORTANCE
      *iv_return = TIPC_CRITICAL_IMPORTANCE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

