#
# ctport.ph
#
# This script was converted from ctport.ph by h2ph.
# Lines with references to &L had to be removed.  I doubt we needed them
# anyway.
#
# Robert Eden
# CommTech Corporation
# rmeden@yahoo.com
#
package Db::Ctree;  

if (!defined &ctPORTH) {
    eval 'sub ctPORTH {1;}';
    eval 'sub PERFORM_OFF {0;}';
    eval 'sub PERFORM_ON {1;}';
    eval 'sub PERFORM_DUMP {2;}';
    if (!defined &FAST) {
	eval 'sub FAST { &register;}';
    }
    if (!defined &PFAST) {
	eval 'sub PFAST { &register;}';
    }
    eval 'sub EXTERN { &extern;}';
    eval 'sub GLOBAL {1;}';
    eval 'sub LOCAL { &static;}';
    eval 'sub VOID { &void;}';
    if (!defined &ctEXPORT) {
	eval 'sub ctEXPORT {1;}';
    }
    if (!defined &SYS_NINT) {
    }
    if (!defined &SYS_UINT) {
    }
    if (!defined &SYS_LONG) {
	if (!defined &LONG) {
	}
    }
    if (!defined &SYS_ULONG) {
	if (!defined &ULONG) {
	}
    }
    if (!defined &__PROGRAM_COUNTER_TYPE__) {
	eval 'sub __PROGRAM_COUNTER_TYPE__ { &UINT;}';
    }
    if (!defined &__ERROR_CHECK_ONLY__) {
	if (!defined &ctProcPtr) {
	    eval 'sub ctProcPtr {1;}';
	    if (!defined &THINK_C) {
		if (!defined &__MWERKS__) {
		}
	    }
	}
    }
    else {
    }
    if (!defined &ctDllDecl) {
	eval 'sub ctDllDecl {1;}';
    }
    if (!defined &__ERROR_CHECK_ONLY__) {
    }
    else {
    }
    if (defined &ctSP) {
    }
    else {
    }
    if (!defined &__ERROR_CHECK_ONLY__) {
    }
    else {
    }
    if (defined &CT_ANSI) {
    }
    else {
	if (!defined &ctRNDFILE) {
	}
    }
    eval 'sub ctRECPT { &LONG;}';
    eval 'sub pctRECPT { &pLONG;}';
    if (defined &YES) {
    }
    if (defined &NO) {
    }
    if (defined &HYS) {
    }
    eval 'sub HYS {2;}';
    eval 'sub YES {1;}';
    eval 'sub NO {0;}';
    eval 'sub FOREVER { &for (;;);}';
    if (!defined &ctUPF) {
	eval 'sub ctUPF {1;}';
	eval 'sub USERPRF_NTKEY {0x0001;}';
	eval 'sub USERPRF_SAVENV {0x0002;}';
	eval 'sub USERPRF_SQL {0x0004;}';
	eval 'sub USERPRF_SERIAL {0x0008;}';
	eval 'sub USERPRF_MEMABS {0x0010;}';
	eval 'sub USERPRF_NDATA {0x0020;}';
	eval 'sub USERPRF_LOCLIB {0x0040;}';
	eval 'sub USERPRF_PTHTMP {0x0080;}';
	eval 'sub USERPRF_CODCNV {0x0100;}';
	eval 'sub USERPRF_CLRCHK {0x0200;}';
	eval 'sub USERPRF_CUSTOM {0x0400;}';
    }
    eval 'sub SYSMON_MAIN {0;}';
    eval 'sub SYSMON_OFF {99;}';
    eval 'sub SHADOW {0x0010;}';
    eval 'sub LOGFIL {0x0020;}';
    eval 'sub TWOFASE {0x0040;}';
    eval 'sub PENDERR {0x0080;}';
    eval 'sub OVRFASE {0x0001;}';
    eval 'sub CIPFASE {0x0002;}';
    eval 'sub SAVENV {0x0100;}';
    eval 'sub AUTOTRN {0x0200;}';
    eval 'sub LKSTATE {0x0400;}';
    eval 'sub DELUPDT {0x0800;}';
    eval 'sub DEFERCP {0x1000;}';
    eval 'sub AUTOSAVE {0x2000;}';
    eval 'sub COMMIT_SWAP {0x4000;}';
    eval 'sub SAVECTREE {1;}';
    eval 'sub RESTORECTREE {2;}';
    eval 'sub RES_TYPNUM {2;}';
    eval 'sub RES_TYPE {4;}';
    eval 'sub RES_FIRST {8;}';
    eval 'sub RES_NAME {16;}';
    eval 'sub RES_POS {32;}';
    eval 'sub RES_LENGTH {64;}';
    eval 'sub RES_LOCK {1;}';
    eval 'sub RES_NEXT {128;}';
    eval 'sub RES_UNAVL {256;}';
    eval 'sub BAT_CAN {0x0001;}';
    eval 'sub BAT_NXT {0x0002;}';
    eval 'sub BAT_GET {0x0003;}';
    eval 'sub BAT_DEL {0x0004;}';
    eval 'sub BAT_UPD {0x0005;}';
    eval 'sub BAT_INS {0x0006;}';
    eval 'sub BAT_OPC_RESV {0x0007;}';
    eval 'sub BAT_PKEY {0x0000;}';
    eval 'sub BAT_RESV1 {0x0008;}';
    eval 'sub BAT_VERIFY {0x0010;}';
    eval 'sub BAT_RET_REC {0x0020;}';
    eval 'sub BAT_RET_POS {0x0040;}';
    eval 'sub BAT_RET_KEY {0x0080;}';
    eval 'sub BAT_GKEY {0x0100;}';
    eval 'sub BAT_RPOS {0x0200;}';
    eval 'sub BAT_KEYS {0x0400;}';
    eval 'sub BAT_LOK_RED {0x0800;}';
    eval 'sub BAT_LOK_WRT {0x1000;}';
    eval 'sub BAT_COMPLETE {0x2000;}';
    eval 'sub BAT_FLTR {0x4000;}';
    eval 'sub BAT_LOK_KEEP {0x8000;}';
    eval 'sub EXCLUSIVE {0x0000;}';
    eval 'sub SHARED {0x0001;}';
    eval 'sub VIRTUAL {0x0000;}';
    eval 'sub PERMANENT {0x0002;}';
    eval 'sub ctFIXED {0x0000;}';
    eval 'sub VLENGTH {0x0004;}';
    eval 'sub READFIL {0x0008;}';
    eval 'sub PREIMG { &SHADOW;}';
    eval 'sub TRNLOG {( &LOGFIL |  &SHADOW);}';
    eval 'sub WRITETHRU {0x0040;}';
    eval 'sub CHECKLOCK {0x0080;}';
    eval 'sub DUPCHANEL {0x0100;}';
    eval 'sub SUPERFILE {0x0200;}';
    eval 'sub CHECKREAD {0x0400;}';
    eval 'sub DISABLERES {0x0800;}';
    eval 'sub MIRROR_SKP {0x2000;}';
    eval 'sub OPENCRPT {0x4000;}';
    eval 'sub LOGIDX {0x8000;}';
    eval 'sub OPF_ALL {( &OPF_READ |  &OPF_WRITE |  &OPF_DEF |  &OPF_DELETE);}';
    eval 'sub GPF_ALL {( &GPF_READ |  &GPF_WRITE |  &GPF_DEF |  &GPF_DELETE);}';
    eval 'sub WPF_ALL {( &WPF_READ |  &WPF_WRITE |  &WPF_DEF |  &WPF_DELETE);}';
    eval 'sub NONEXCLUSIVE {( &READFIL |  &SHARED);}';
    eval 'sub COMPLETE { &EXCLUSIVE;}';
    eval 'sub PARTIAL { &SHARED;}';
    eval 'sub NOTREUSE {0x0010;}';
    eval 'sub REGADD {0;}';
    eval 'sub INCADD {1;}';
    eval 'sub DECADD {2;}';
    eval 'sub FRSADD {0;}';
    eval 'sub NXTADD {1;}';
    eval 'sub BLDADD {2;}';
    if (!defined &ctLKIMDS) {
	eval 'sub ctLKIMDS {1;}';
	eval 'sub FREE {0;}';
	eval 'sub RESET {1;}';
	eval 'sub ENABLE {2;}';
	eval 'sub ENABLE_BLK {3;}';
	eval 'sub READREC {4;}';
	eval 'sub SUSPEND {5;}';
	eval 'sub RESTORE {6;}';
	eval 'sub RESTRED {7;}';
	eval 'sub RESTORE_BLK {8;}';
	eval 'sub ctKEEP {9;}';
	eval 'sub FREE_TRAN {10;}';
	eval 'sub READREC_BLK {11;}';
	eval 'sub ctLK_RSV {12;}';
	eval 'sub ctLK_RSV_BLK {13;}';
	eval 'sub RESTRED_BLK {14;}';
	eval 'sub RESTRSV {15;}';
	eval 'sub RESTRSV_BLK {16;}';
	eval 'sub SS_LOCK {17;}';
	eval 'sub FREE_FILE {18;}';
	eval 'sub ctLKMD_RSV {8;}';
	eval 'sub LK_BLOCK {1;}';
	eval 'sub TRNBEGLK {( &ENABLE |  &READREC |  &ctLKMD_RSV |  &LK_BLOCK);}';
    }
    eval 'sub ctKEEP_OUT {41;}';
    eval 'sub ctNEWRECFLG {2;}';
    eval 'sub ctTRANLOCK {4;}';
    eval 'sub RECLEN {0;}';
    eval 'sub KEYLEN {1;}';
    eval 'sub FILTYP {2;}';
    eval 'sub FILMOD {3;}';
    eval 'sub REVMAP {4;}';
    eval 'sub KEYTYP {5;}';
    eval 'sub KEYDUP {6;}';
    eval 'sub LOGSIZ {10;}';
    eval 'sub PHYSIZ {11;}';
    eval 'sub NODSIZ {12;}';
    eval 'sub KEYMEM {13;}';
    eval 'sub KEYPAD {14;}';
    eval 'sub FLDELM {15;}';
    eval 'sub RECPAD {16;}';
    eval 'sub MIRRST {17;}';
    eval 'sub RELKEY {18;}';
    eval 'sub PERMSK {19;}';
    eval 'sub FILDEF {20;}';
    eval 'sub ALIGNM {21;}';
    eval 'sub FILNAM {0;}';
    eval 'sub FRSFLD {1;}';
    eval 'sub LSTFLD {2;}';
    eval 'sub IDXNAM {3;}';
    eval 'sub MIRNAM {4;}';
    eval 'sub OWNNAM {5;}';
    eval 'sub GRPNAM {6;}';
    eval 'sub ctSERNUMhdr {1;}';
    eval 'sub ctTSTAMPhdr {2;}';
    eval 'sub ctNUMENThdr {3;}';
    eval 'sub ctTIMEIDhdr {4;}';
    eval 'sub ctALIGNhdr {17;}';
    eval 'sub ctFLAVORhdr {18;}';
    eval 'sub ctUSERhdr {32;}';
    eval 'sub ctISAMKBUFhdr {33;}';
    eval 'sub CHKNUL {ord(\'\\1\');}';
    eval 'sub NONE {0;}';
    eval 'sub RCVMOD {0;}';
    eval 'sub BAKMOD {1;}';
    eval 'sub FWDMOD {2;}';
    eval 'sub MBRMOD {3;}';
    eval 'sub TRNNUM {0;}';
    eval 'sub TRNTIM {1;}';
    eval 'sub SAVCURI {0;}';
    eval 'sub RSTCURI {1;}';
    eval 'sub SWTCURI {2;}';
    eval 'sub REGSEG {0;}';
    eval 'sub INTSEG {1;}';
    eval 'sub UREGSEG {2;}';
    eval 'sub SRLSEG {3;}';
    eval 'sub VARSEG {4;}';
    eval 'sub UVARSEG {5;}';
    eval 'sub YOURSEG1 {6;}';
    eval 'sub YOURSEG2 {7;}';
    eval 'sub SGNSEG {8;}';
    eval 'sub FLTSEG {9;}';
    eval 'sub DECSEG {10;}';
    eval 'sub BCDSEG {11;}';
    eval 'sub SCHSEG {12;}';
    eval 'sub USCHSEG {13;}';
    eval 'sub VSCHSEG {14;}';
    eval 'sub UVSCHSEG {15;}';
    eval 'sub XTDSEG {256;}';
    eval 'sub SEGMSK {0x010f;}';
    eval 'sub DSCSEG {0x0010;}';
    eval 'sub ALTSEG {0x0020;}';
    eval 'sub ENDSEG {0x0040;}';
    eval 'sub RSVSEG {0x0080;}';
    eval 'sub OPS_ONCE_LOK {0x0004;}';
    eval 'sub OPS_ONCE_BLK {0x0020;}';
    eval 'sub OPS_RSVD_2B2 {0x0040;}';
    eval 'sub OPS_RSVD_2B3 {0x0080;}';
    eval 'sub OPS_RSVD_2B4 {0x0100;}';
    eval 'sub OPS_STATE_OFF {0x00000000;}';
    eval 'sub OPS_STATE_SET {0x00000001;}';
    eval 'sub OPS_STATE_ON {0x00000002;}';
    eval 'sub OPS_STATE_RET {0x00000003;}';
    eval 'sub OPS_STATE_VRET {0x00000004;}';
    eval 'sub OPS_UNLOCK_ADD {0x00000001;}';
    eval 'sub OPS_UNLOCK_RWT {0x00000002;}';
    eval 'sub OPS_UNLOCK_UPD {( &OPS_UNLOCK_ADD |  &OPS_UNLOCK_RWT);}';
    eval 'sub OPS_LOCKON_GET {(( &LONG)  &OPS_ONCE_LOK);}';
    eval 'sub OPS_VARLEN_CMB {0x00000008;}';
    eval 'sub OPS_SERVER_SHT {0x00000010;}';
    eval 'sub OPS_LOCKON_BLK {(( &LONG)  &OPS_ONCE_BLK);}';
    eval 'sub OPS_ADMOPN {0x00000200;}';
    eval 'sub OPS_OMITCP {0x00000400;}';
    eval 'sub OPS_SKPDAT {0x00000800;}';
    eval 'sub OPS_MIRROR_NOSWITCH {0x00001000;}';
    eval 'sub OPS_CLIENT_TRM {0x00002000;}';
    eval 'sub OPS_MIRROR_TRM {0x00004000;}';
    eval 'sub OPS_FUNCTION_MON {0x00008000;}';
    eval 'sub OPS_LOCK_MON {0x00010000;}';
    eval 'sub OPS_TRACK_MON {0x00020000;}';
    eval 'sub OPS_AUTOISAM_TRN {0x00040000;}';
    eval 'sub OPS_SERIAL_UPD {0x00080000;}';
    eval 'sub OPS_MEMORY_SWP {0x00100000;}';
    eval 'sub OPS_COMMIT_SWP {0x00200000;}';
    eval 'sub OPS_once {( &OPS_ONCE_LOK |  &OPS_ONCE_BLK);}';
    eval 'sub OPS_lockon {( &OPS_LOCKON_GET |  &OPS_LOCKON_BLK);}';
    eval 'sub OPS_monitors {( &OPS_FUNCTION_MON |  &OPS_LOCK_MON |  &OPS_TRACK_MON);}';
    eval 'sub OPS_internal {( &OPS_SERVER_SHT |  &OPS_ADMOPN |  &OPS_OMITCP |  &OPS_SKPDAT |  &OPS_CLIENT_TRM);}';
    eval 'sub OPS_server {( &OPS_COMMIT_SWP |  &OPS_SERVER_SHT |  &OPS_CLIENT_TRM |  &OPS_MIRROR_TRM |  &OPS_MEMORY_SWP);}';
    eval 'sub OPS_permanent {( &OPS_SERVER_SHT |  &OPS_CLIENT_TRM |  &OPS_MIRROR_TRM |  &OPS_MEMORY_SWP);}';
    eval 'sub DEF_IFIL {0;}';
    eval 'sub DEF_MAP {1;}';
    eval 'sub DEF_NAMES {2;}';
    eval 'sub DEF_SQL1 {3;}';
    eval 'sub DEF_SQL2 {4;}';
    eval 'sub DEF_SQL3 {5;}';
    eval 'sub DEF_DTREE1 {6;}';
    eval 'sub DEF_DTREE2 {7;}';
    eval 'sub DEF_DTREE3 {8;}';
    eval 'sub DEF_NATLNG1 {9;}';
    eval 'sub DEF_NATLNG2 {10;}';
    eval 'sub DEF_NATLNG3 {11;}';
    eval 'sub DEF_RESRVD1 {12;}';
    eval 'sub DEF_RESRVD20 {31;}';
    eval 'sub DEF_NUMBER {32;}';
    eval 'sub FCRES_DATA {1;}';
    eval 'sub FCRES_SCRT {2;}';
    eval 'sub FCRES_IDX {3;}';
    eval 'sub FCRES_SQL {4;}';
    eval 'sub FCRES_CIDX {5;}';
    eval 'sub FCRNAM_LEN {8;}';
    eval 'sub tfrmkey { &TFRMKEY;}';
    eval 'sub alcset { &ALCSET;}';
    eval 'sub chgset { &CHGSET;}';
    eval 'sub FNSYSABS {1;}';
    eval 'sub FNSRVDIR {2;}';
    eval 'sub FNLOCSRV {3;}';
    eval 'sub PKEYLEN {(3 *  &SIZEOF( &LONG) +  &SIZEOF( &COUNT));}';
    eval 'sub USRLSTSIZ {256;}';
    eval 'sub ALTSEQSIZ {256;}';
    eval 'sub ALTSEQBYT {( &ALTSEQSIZ *  &SIZEOF( &COUNT));}';
    eval 'sub ctDODA {1;}';
    if (!defined &CTBOUND) {
    }
    eval 'sub SCHEMA_MAP {1;}';
    eval 'sub SCHEMA_NAMES {2;}';
    eval 'sub SCHEMA_MAPandNAMES {3;}';
    eval 'sub SCHEMA_DODA {4;}';
    eval 'sub SegOff {
        local($struc, $member) = @_;
        eval "(( &NINT)&((($struc *)0)->$member))";
    }';
    eval 'sub ArraySegOff {
        local($struc, $member) = @_;
        eval "(( &NINT) ((($struc *)0)->$member))";
    }';
    if (!defined &ctDTYPES) {
	eval 'sub ctDTYPES {1;}';
	eval 'sub CT_BOOL {(1 << 3);}';
	eval 'sub CT_CHAR {(2 << 3);}';
	eval 'sub CT_CHARU {(3 << 3);}';
	eval 'sub CT_INT2 {((4 << 3) + 1);}';
	eval 'sub CT_INT2U {((5 << 3) + 1);}';
	eval 'sub CT_INT4 {((6 << 3) + 3);}';
	eval 'sub CT_INT4U {((7 << 3) + 3);}';
	eval 'sub CT_MONEY {((8 << 3) + 3);}';
	eval 'sub CT_DATE {((9 << 3) + 3);}';
	eval 'sub CT_TIME {((10 << 3) + 3);}';
	eval 'sub CT_SFLOAT {((11 << 3) + 3);}';
	eval 'sub CT_DFLOAT {((12 << 3) + 7);}';
	eval 'sub CT_SQLBCDold {((13 << 3) + 3);}';
	eval 'sub CT_SQLBCD {((13 << 3) + 4);}';
	eval 'sub CT_EFLOAT {((14 << 3) + 7);}';
	eval 'sub CT_TIMESold {((15 << 3) + 3);}';
	eval 'sub CT_TIMES {((15 << 3) + 4);}';
	eval 'sub CT_ARRAY {(16 << 3);}';
	eval 'sub CT_RESRVD {(17 << 3);}';
	eval 'sub CT_FSTRING {(18 << 3);}';
	eval 'sub CT_FPSTRING {(19 << 3);}';
	eval 'sub CT_F2STRING {(20 << 3);}';
	eval 'sub CT_F4STRING {(21 << 3);}';
	eval 'sub CT_STRING {( &CT_FSTRING + 2);}';
	eval 'sub CT_PSTRING {( &CT_FPSTRING + 2);}';
	eval 'sub CT_2STRING {( &CT_F2STRING + 2);}';
	eval 'sub CT_4STRING {( &CT_F4STRING + 2);}';
	eval 'sub CT_LAST { &CT_4STRING;}';
    }
    eval 'sub CT_STRFLT {( &CT_LAST + 1);}';
    eval 'sub CT_STRLNG {( &CT_LAST + 2);}';
    eval 'sub CT_NUMSTR {( &CT_LAST + 3);}';
    eval 'sub CT_DBLSTR {( &CT_LAST + 4);}';
    eval 'sub CT_SUBSTR {( &CT_LAST + 5);}';
    eval 'sub CT_WLDCRD {( &CT_LAST + 6);}';
    eval 'sub SEC_FILEWORD {1;}';
    eval 'sub SEC_FILEGRUP {2;}';
    eval 'sub SEC_FILEMASK {3;}';
    eval 'sub SEC_FILEOWNR {4;}';
    eval 'sub ctSEGLEN {1;}';
    eval 'sub ctSEGMOD {2;}';
    eval 'sub ctSEGPOS {3;}';
    eval 'sub DataBufferRequests {0;}';
    eval 'sub DataBufferHits {1;}';
    eval 'sub IndexBufferRequests {2;}';
    eval 'sub IndexBufferHits {3;}';
    eval 'sub NbrReadOperations {4;}';
    eval 'sub NbrBytesRead {5;}';
    eval 'sub NbrWriteOperations {6;}';
    eval 'sub NbrBytesWritten {7;}';
    eval 'sub updateIFIL {-99;}';
    eval 'sub cfgFILES {0;}';
    eval 'sub cfgUSERS {1;}';
    eval 'sub cfgIDX_MEMORY {2;}';
    eval 'sub cfgDAT_MEMORY {3;}';
    eval 'sub cfgTOT_MEMORY {4;}';
    eval 'sub cfgUSR_MEMORY {5;}';
    eval 'sub cfgPREIMAGE_FILE {6;}';
    eval 'sub cfgPAGE_SIZE {7;}';
    eval 'sub cfgCOMMIT {8;}';
    eval 'sub cfgLOG_SPACE {9;}';
    eval 'sub cfgLOG_EVEN {10;}';
    eval 'sub cfgLOG_ODD {11;}';
    eval 'sub cfgSTART_EVEN {12;}';
    eval 'sub cfgSTART_ODD {13;}';
    eval 'sub cfgSERVER_DIRECTORY {14;}';
    eval 'sub cfgLOCAL_DIRECTORY {15;}';
    eval 'sub cfgSERVER_NAME {16;}';
    eval 'sub cfgDUMP {17;}';
    eval 'sub cfgSQL_TABLES {18;}';
    eval 'sub cfgKEEP_LOGS {19;}';
    eval 'sub cfgCOMM_PROTOCOL {20;}';
    eval 'sub cfgSQL_SUPERFILES {21;}';
    eval 'sub cfgLIST_MEMORY {22;}';
    eval 'sub cfgSORT_MEMORY {23;}';
    eval 'sub cfgBUFR_MEMORY {24;}';
    eval 'sub cfgPREIMAGE_HASH {25;}';
    eval 'sub cfgLOCK_HASH {26;}';
    eval 'sub cfgUSR_MEM_RULE {27;}';
    eval 'sub cfgGUEST_MEMORY {28;}';
    eval 'sub cfgQUERY_MEMORY {29;}';
    eval 'sub cfgTRAN_TIMEOUT {30;}';
    eval 'sub cfgMAX_DAT_KEY {31;}';
    eval 'sub cfgSQL_DEBUG {32;}';
    eval 'sub cfgSEMAPHORE_BLK {33;}';
    eval 'sub cfgSESSION_TIMEOUT {34;}';
    eval 'sub cfgTASKER_SLEEP {35;}';
    eval 'sub cfgFILE_HANDLES {36;}';
    eval 'sub cfgMEMORY_MONITOR {37;}';
    eval 'sub cfgTASKER_PC {38;}';
    eval 'sub cfgTASKER_SP {39;}';
    eval 'sub cfgTASKER_NP {40;}';
    eval 'sub cfgNODE_DELAY {41;}';
    eval 'sub cfgDEADLOCK_MONITOR {42;}';
    eval 'sub cfgNODEQ_MONITOR {43;}';
    eval 'sub cfgCOMMIT_DELAY {44;}';
    eval 'sub cfgCHECKPOINT_MONITOR {45;}';
    eval 'sub cfgNODEQ_SEARCH {46;}';
    eval 'sub cfgMAX_KEY_SEG {47;}';
    eval 'sub cfgFUNCTION_MONITOR {48;}';
    eval 'sub cfgTASKER_LOOP {49;}';
    eval 'sub cfgREQUEST_DELAY {50;}';
    eval 'sub cfgREQUEST_DELTA {51;}';
    eval 'sub cfg9074_MONITOR {52;}';
    eval 'sub cfg9477_MONITOR {53;}';
    eval 'sub cfgSKIP_MISSING_FILES {54;}';
    eval 'sub cfgTMPNAME_PATH {55;}';
    eval 'sub cfgLOG_EVEN_MIRROR {56;}';
    eval 'sub cfgLOG_ODD_MIRROR {57;}';
    eval 'sub cfgSTART_EVEN_MIRROR {58;}';
    eval 'sub cfgSTART_ODD_MIRROR {59;}';
    eval 'sub cfgADMIN_MIRROR {60;}';
    eval 'sub cfgSKIP_MISSING_MIRRORS {61;}';
    eval 'sub cfgCOMMENTS {62;}';
    eval 'sub cfgMIRRORS {63;}';
    eval 'sub cfg749X_MONITOR {64;}';
    eval 'sub cfgCOMPATIBILITY {65;}';
    eval 'sub cfgDIAGNOSTICS {66;}';
    eval 'sub cfgCONTEXT_HASH {67;}';
    eval 'sub cfgGUEST_LOGON {68;}';
    eval 'sub cfgTRANSACTION_FLUSH {69;}';
    eval 'sub cfgCHECKPOINT_FLUSH {70;}';
    eval 'sub cfgLOCK_MONITOR {71;}';
    eval 'sub cfgMEMORY_TRACK {72;}';
    eval 'sub cfgSUPPRESS_LOG_FLUSH {73;}';
    eval 'sub cfgPREIMAGE_DUMP {74;}';
    eval 'sub cfgRECOVER_MEMLOG {75;}';
    eval 'sub cfgRECOVER_DETAILS {76;}';
    eval 'sub cfgCHECKPOINT_INTERVAL {77;}';
    eval 'sub cfgRECOVER_SKIPCLEAN {78;}';
    eval 'sub cfgSIGNAL_READY {79;}';
    eval 'sub cfgSIGNAL_MIRROR_EVENT {80;}';
    eval 'sub cfgCHECKPOINT_IDLE {81;}';
    eval 'sub cfgSIGNAL_DOWN {82;}';
    eval 'sub cfgFORCE_LOGIDX {83;}';
    eval 'sub cfgCHECKPOINT_PREVIOUS {84;}';
    eval 'sub cfgTRAN_HIGH_MARK {85;}';
    eval 'sub cfgCTSTATUS_MASK {86;}';
    eval 'sub cfgCTSTATUS_SIZE {87;}';
    eval 'sub cfgMONITOR_MASK {88;}';
    eval 'sub cfgRECOVER_FILES {89;}';
    eval 'sub cfgLAST {90;}';
    eval 'sub cfgDISKIO_MODEL {128;}';
    eval 'sub cfgTRANPROC {129;}';
    eval 'sub cfgRESOURCE {130;}';
    eval 'sub cfgCTBATCH {131;}';
    eval 'sub cfgCTSUPER {132;}';
    eval 'sub cfgFUTURE1 {133;}';
    eval 'sub cfgVARLDATA {134;}';
    eval 'sub cfgVARLKEYS {135;}';
    eval 'sub cfgPARMFILE {136;}';
    eval 'sub cfgRTREE {137;}';
    eval 'sub cfgCTS_ISAM {138;}';
    eval 'sub cfgBOUND {139;}';
    eval 'sub cfgNOGLOBALS {140;}';
    eval 'sub cfgPROTOTYPE {141;}';
    eval 'sub cfgPASCALst {142;}';
    eval 'sub cfgPASCAL24 {143;}';
    eval 'sub cfgWORD_ORDER {144;}';
    eval 'sub cfgPARMFILE_FORMAT {145;}';
    eval 'sub cfgUNIFRMAT {146;}';
    eval 'sub cfgLOCLIB {147;}';
    eval 'sub cfgANSI {148;}';
    eval 'sub cfgFILE_SPECS {149;}';
    eval 'sub cfgPATH_SEPARATOR {150;}';
    eval 'sub cfgLOGIDX {151;}';
    eval 'sub cfgMEMORY_USAGE {192;}';
    eval 'sub cfgMEMORY_HIGH {193;}';
    eval 'sub cfgNET_ALLOCS {194;}';
    eval 'sub cfgDNODE_QLENGTH {195;}';
    eval 'sub cfgCHKPNT_QLENGTH {196;}';
    eval 'sub cfgSYSMON_QLENGTH {197;}';
    eval 'sub cfgMONAL1_QLENGTH {198;}';
    eval 'sub cfgMONAL2_QLENGTH {199;}';
    eval 'sub cfgLOGONS {200;}';
    eval 'sub cfgNET_LOCKS {201;}';
    eval 'sub cfgPHYSICAL_FILES {202;}';
    eval 'sub cfgOPEN_FILES {203;}';
    eval 'sub cfgOPEN_FCBS {204;}';
    eval 'sub cfgUSER_FILES {205;}';
    eval 'sub cfgUSER_MEMORY {206;}';
    eval 'sub cfgCONDIDX {207;}';
    eval 'sub ctCFGLMT {256;}';
    eval 'sub ctHISTlog {0x0001;}';
    eval 'sub ctHISTfirst {0x0002;}';
    eval 'sub ctHISTnext {0x0004;}';
    eval 'sub ctHISTfrwd {0x0008;}';
    eval 'sub ctHISTuser {0x0010;}';
    eval 'sub ctHISTnode {0x0020;}';
    eval 'sub ctHISTpos {0x0040;}';
    eval 'sub ctHISTkey {0x0080;}';
    eval 'sub ctHISTdata {0x1000;}';
    eval 'sub ctHISTindx {0x2000;}';
    eval 'sub ctHISTnet {0x4000;}';
    eval 'sub ctHISTinfo {0x8000;}';
    eval 'sub ctHISTmapmask {0x00ff;}';
    eval 'sub ctHISTkdel {0x0100;}';
    eval 'sub ctlogALL {1;}';
    eval 'sub ctlogLOG {2;}';
    eval 'sub ctlogSTART {3;}';
    eval 'sub ctlogLOG_EVEN {4;}';
    eval 'sub ctlogLOG_ODD {5;}';
    eval 'sub ctlogSTART_EVEN {6;}';
    eval 'sub ctlogSTART_ODD {7;}';
    eval 'sub ctlogALL_MIRROR {17;}';
    eval 'sub ctlogLOG_MIRROR {18;}';
    eval 'sub ctlogSTART_MIRROR {19;}';
    eval 'sub ctlogLOG_EVEN_MIRROR {20;}';
    eval 'sub ctlogLOG_ODD_MIRROR {21;}';
    eval 'sub ctlogSTART_EVEN_MIRROR {22;}';
    eval 'sub ctlogSTART_ODD_MIRROR {23;}';
}
1;
