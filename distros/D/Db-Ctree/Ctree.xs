#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* 
   CTREE includes
*/

#include "ctstdr.h"
#include "ctoptn.h"
#include "ctaerr.h"
#include "ctdecl.h"
#include "cterrc.h"

typedef COUNT CtreeINIT;

MODULE = Db::Ctree		PACKAGE = Db::Ctree		

 #
 # NOTE: OUTPUT specifiers are not giving for VOID * types because
 #       their values can contain nulls and this will screw up length
 #       calculations.  The CTREE practice of ensuring proper buffer space
 #       holds true!!
 #

 #
 # Functions for CTREE global variables
 #

COUNT
isam_err()
     CODE:
         RETVAL = isam_err;
     OUTPUT:
         RETVAL

COUNT
isam_fil()
     CODE:
         RETVAL = isam_fil;
     OUTPUT:
         RETVAL

COUNT
sysiocod()
     CODE:
         RETVAL = sysiocod;
     OUTPUT:
         RETVAL

COUNT
uerr_cod()
     CODE:
         RETVAL = uerr_cod;
     OUTPUT:
         RETVAL

 #
 # custom GetDODA returns values as list type
 #
void
MyGetDODA(datano)
       COUNT datano
       PPCODE:
           DATOBJ doda[100];
           int    i=0;
           i=GetDODA(datano,sizeof(DATOBJ)*100,doda,SCHEMA_DODA);
           if (i)
             for(i=0; i<100 ; i++)
             {
                if (doda[i].fwhat == -1 ) break;
                EXTEND(sp, 4);
                if (doda[i].fsymb == 0 )
                   PUSHs(sv_2mortal(newSViv(i)));/*deal with null field name*/
                else
                   PUSHs(sv_2mortal(newSVpv(doda[i].fsymb,0)));
                   PUSHs(sv_2mortal(newSViv((IV)doda[i].fadr)));
                   PUSHs(sv_2mortal(newSViv(doda[i].ftype)));
                   PUSHs(sv_2mortal(newSViv(doda[i].flen )));
             } 
           else
               XSRETURN_EMPTY;
                
 #
 # custom InitISAM returns a ptr of special type to detect when the program exits.   
 # On DESTROY of the return value StopUser() is executed to ensure
 #  shared memory is cleaned up!

CtreeINIT *
MyInitISAM(bufs,fils,sect)
     COUNT  bufs
     COUNT  fils
     COUNT  sect
     CODE:
        RETVAL = malloc(sizeof(CtreeINIT));
        *RETVAL = InitISAM(bufs,fils,sect);
     OUTPUT:
        RETVAL


 # This code is executed automatically upon exit to clean up
 # shared memory.
MODULE = Db::Ctree		PACKAGE = CtreeINITPtr
void
DESTROY(init)
      CtreeINIT *init
      CODE:
           StopUser();
           free(init); 	

 #
 # Most Ctree functions converted automatically
 #
MODULE = Db::Ctree		PACKAGE = Db::Ctree		

COUNT
Abort()

COUNT
AbortXtd(lokmod)
    COUNT lokmod

COUNT
AddCtResource(datno,resptr,varlen)
    COUNT datno
    VOID * resptr
    UCOUNT varlen

COUNT
AddKey(keyno,target,recbyt,typadd)
    COUNT keyno
    VOID * target
    LONG recbyt
    COUNT typadd

COUNT
AddRecord(datno,recptr)
    COUNT datno
    VOID * recptr

COUNT
AddVRecord(datno,recptr,varlen)
    COUNT datno
    VOID * recptr
    UCOUNT varlen

COUNT
AllocateBatch(numbat)
    COUNT numbat

COUNT
AllocateSet(numset)
    COUNT numset

COUNT
AvailableFileNbr(numfils)
    COUNT numfils

LONG
Begin(mode)
    COUNT mode

COUNT
BuildKey(keyno,recptr,txt,pntr,datlen)
    COUNT keyno
    VOID * recptr
    TEXT * txt
    LONG pntr
    UCOUNT datlen

COUNT
ChangeBatch(batnum)
    COUNT batnum

COUNT
ChangeISAMContext(contextid)
    COUNT contextid

COUNT
ChangeSet(setnum)
    COUNT setnum

COUNT
ClearTranError()

COUNT
CloseCtFile(filno,filmod)
    COUNT filno
    COUNT filmod

COUNT
CloseIFile(ifilptr)
    IFIL * ifilptr

COUNT
CloseISAM()

COUNT
CloseISAMContext(contextid)
    COUNT contextid

COUNT
CloseRFile(datno)
    COUNT datno

COUNT
Commit(mode)
    COUNT mode

COUNT
CompactIFile(ifilptr)
    IFIL * ifilptr

COUNT
CompactIFileXtd(ifilptr,dataextn,indxextn,permmask,groupid,fileword)
    IFIL * ifilptr
    TEXT * dataextn
    VOID * indxextn
    LONG permmask
    TEXT * groupid
    TEXT * fileword

COUNT
CreateDataFile(datno,filnam,datlen,xtdsiz,filmod)
    COUNT datno
    TEXT * filnam
    UCOUNT datlen
    UCOUNT xtdsiz
    COUNT filmod

COUNT
CreateDataFileXtd(datno,filnam,datlen,xtdsiz,filmod,permmask,groupid,fileword)
    COUNT datno
    TEXT * filnam
    UCOUNT datlen
    UCOUNT xtdsiz
    COUNT filmod
    LONG permmask
    TEXT * groupid
    TEXT * fileword

COUNT
CreateIFile(ifilptr)
    IFIL * ifilptr

COUNT
CreateIFileXtd(ifilptr,dataextn,indxextn,permmask,groupid,fileword)
    IFIL * ifilptr
    TEXT * dataextn
    VOID * indxextn
    LONG permmask
    TEXT * groupid
    TEXT * fileword

COUNT
CreateIndexFile(keyno,filnam,keylen,keytyp,keydup,nomemb,xtdsiz,filmod)
    COUNT keyno
    TEXT * filnam
    COUNT keylen
    COUNT keytyp
    COUNT keydup
    COUNT nomemb
    UCOUNT xtdsiz
    COUNT filmod

COUNT
CreateIndexFileXtd(keyno,filnam,keylen,keytyp,keydup,nomemb,xtdsiz,filmod,permmask,groupid,fileword)
    COUNT keyno
    TEXT * filnam
    COUNT keylen
    COUNT keytyp
    COUNT keydup
    COUNT nomemb
    UCOUNT xtdsiz
    COUNT filmod
    LONG permmask
    TEXT * groupid
    TEXT * fileword

COUNT
CreateIndexMember(keyno,keylen,keytyp,keydup,membno)
    COUNT keyno
    COUNT keylen
    COUNT keytyp
    COUNT keydup
    COUNT membno

COUNT
CreateISAM(filnam)
    TEXT * filnam

COUNT
CreateISAMXtd(filnam,userprof,userid,userword,servname,permmask,groupid,fileword)
    TEXT * filnam
    COUNT userprof
    TEXT * userid
    TEXT * userword
    TEXT * servname
    LONG permmask
    TEXT * groupid
    TEXT * fileword

COUNT
CtreeFlushFile(filno)
    COUNT filno

LONG
CurrentFileOffset(datno)
    COUNT datno

TEXT *
CurrentISAMKey(keyno,idxval,plen)
    COUNT keyno
    VOID * idxval
    VRLEN * plen

TEXT *
CurrentLowLevelKey(keyno,idxval)
    COUNT keyno
    VOID * idxval

COUNT
DeleteCtFile(filno)
    COUNT filno

COUNT
DeleteCtResource(datno,resptr)
    COUNT datno
    VOID * resptr

COUNT
DeleteIFile(ifilptr)
    IFIL * ifilptr

COUNT
DeleteKey(keyno,target,recbyt)
    COUNT keyno
    VOID * target
    LONG recbyt

LONG
DeleteKeyBlind(keyno,target)
    COUNT keyno
    VOID * target

COUNT
DeleteRecord(datno)
    COUNT datno

COUNT
DeleteRFile(datno)
    COUNT datno

COUNT
DeleteVRecord(datno)
    COUNT datno

COUNT
DoBatch(filno,request,bufptr,bufsiz,mode)
    COUNT filno
    VOID * request
    VOID * bufptr
    VRLEN bufsiz
    COUNT mode

COUNT
EnableCtResource(datno)
    COUNT datno

LONG
EstimateKeySpan(keyno,keyval1,keyval2)
    COUNT keyno
    VOID * keyval1
    VOID * keyval2

COUNT
FirstInSet(keyno,target,recptr,siglen)
    COUNT keyno
    VOID * target
    VOID * recptr
    COUNT siglen

LONG
FirstKey(keyno,idxval)
    COUNT keyno
    VOID * idxval

COUNT
FirstRecord(filno,recptr)
    COUNT filno
    VOID * recptr

COUNT
FreeBatch()

COUNT
FreeSet()

COUNT
GetAltSequence(keyno,altseq)
    COUNT keyno
    COUNT * altseq

LONG
GetCtFileInfo(filno,mode)
    COUNT filno
    COUNT mode

LONG
GetCtResource(datno,resptr,bufptr,bufsiz,resmode)
    COUNT datno
    VOID * resptr
    VOID * bufptr
    VRLEN bufsiz
    COUNT resmode

VOID *
GetCtreePointer(regid)
    TEXT * regid

COUNT
GetCtTempFileName(bufptr,bufsiz)
    VOID * bufptr
    VRLEN bufsiz

LONG
GetGTEKey(keyno,target,idxval)
    COUNT keyno
    VOID * target
    VOID * idxval

COUNT
GetGTERecord(keyno,target,recptr)
    COUNT keyno
    VOID * target
    VOID * recptr

LONG
GetGTKey(keyno,target,idxval)
    COUNT keyno
    VOID * target
    VOID * idxval

COUNT
GetGTRecord(keyno,target,recptr)
    COUNT keyno
    VOID * target
    VOID * recptr

  # COUNT
  # GetGTVRecord(keyno,target,recptr,plen)
      # COUNT keyno
      # VOID * target
      # VOID * recptr
      # VRLEN * plen

VRLEN
GetIFile(datno,buflen,bufptr)
    COUNT datno
    LONG buflen
    VOID * bufptr

LONG
GetKey(keyno,target)
    COUNT keyno
    VOID * target

LONG
GetLTEKey(keyno,target,idxval)
    COUNT keyno
    VOID * target
    VOID * idxval

COUNT
GetLTERecord(keyno,target,recptr)
    COUNT keyno
    VOID * target
    VOID * recptr

 # COUNT
 # GetLTEVRecord(keyno,target,recptr,plen)
     # COUNT keyno
     # VOID * target
     # VOID * recptr
     # VRLEN * plen

LONG
GetLTKey(keyno,target,idxval)
    COUNT keyno
    VOID * target
    VOID * idxval

COUNT
GetLTRecord(keyno,target,recptr)
    COUNT keyno
    VOID * target
    VOID * recptr

 # COUNT
 # GetLTVRecord(keyno,target,recptr,plen)
     # COUNT keyno
     # VOID * target
     # VOID * recptr
     # VRLEN * plen

LONG
GetORDKey(keyno,target,offset,idxval)
    COUNT keyno
    VOID * target
    VRLEN offset
    VOID * idxval

COUNT
GetRecord(keyno,target,recptr)
    COUNT keyno
    VOID * target
    VOID * recptr

LONG
GetSerialNbr(datno)
    COUNT datno

COUNT
GetSuperFileNames(superFileNo,nambuf,buflen,memberFileNo)
    COUNT superFileNo
    TEXT * nambuf
    LONG buflen
    COUNT memberFileNo

COUNT
GetSymbolicNames(filno,nambuf,buflen,mode)
    COUNT filno
    TEXT * nambuf
    LONG buflen
    COUNT mode

COUNT
InitCTree(bufs,fils,sect)
    COUNT bufs
    COUNT fils
    COUNT sect

COUNT
InitCTreeXtd(bufs,fils,sect,dbufs,userprof,userid,userword,servname)
    COUNT bufs
    COUNT fils
    COUNT sect
    COUNT dbufs
    COUNT userprof
    TEXT * userid
    TEXT * userword
    TEXT * servname


COUNT
InitISAMXtd(bufs,fils,sect,dbufs,userprof,userid,userword,servname)
    COUNT bufs
    COUNT fils
    COUNT sect
    COUNT dbufs
    COUNT userprof
    TEXT * userid
    TEXT * userword
    TEXT * servname

COUNT
IOPERFORMANCE(bufptr)
    VOID * bufptr

COUNT
IOPERFORMANCEX(bufptr)
    VOID * bufptr

LONG
KeyAtPercentile(keyno,idxval,percent)
    COUNT keyno
    VOID * idxval
    VRLEN percent

COUNT
LastInSet(keyno,target,recptr,siglen)
    COUNT keyno
    VOID * target
    VOID * recptr
    COUNT siglen

LONG
LastKey(keyno,idxval)
    COUNT keyno
    VOID * idxval

COUNT
LastRecord(filno,recptr)
    COUNT filno
    VOID * recptr

COUNT
LoadKey(keyno,target,recbyt,typadd)
    COUNT keyno
    VOID * target
    LONG recbyt
    COUNT typadd

COUNT
LockCtData(datno,lokmod,recbyt)
    COUNT datno
    COUNT lokmod
    LONG recbyt

COUNT
LockISAM(lokmod)
    COUNT lokmod

LONG
NbrOfKeyEntries(keyno)
    COUNT keyno

LONG
NbrOfKeysInRange(keyno,keyval1,keyval2)
    COUNT keyno
    VOID * keyval1
    VOID * keyval2

LONG
NbrOfRecords(datno)
    COUNT datno

LONG
NewData(datno)
    COUNT datno

LONG
NewVData(datno,varlen)
    COUNT datno
    UCOUNT varlen

COUNT
NextInSet(keyno,recptr)
    COUNT keyno
    VOID * recptr

LONG
NextKey(keyno,idxval)
    COUNT keyno
    VOID * idxval

COUNT
NextRecord(filno,recptr)
    COUNT filno
    VOID * recptr

COUNT
OpenCtFile(filno,filnam,filmod)
    COUNT filno
    TEXT * filnam
    COUNT filmod

COUNT
OpenCtFileXtd(filno,filnam,filmod,fileword)
    COUNT filno
    TEXT * filnam
    COUNT filmod
    TEXT * fileword

COUNT
OpenFileWithResource(filno,filnam,filmod)
    COUNT filno
    TEXT * filnam
    COUNT filmod

 # COUNT
 # OpenFileWithResourceXTD(filno,filnam,filmod,fileword)
     # COUNT filno
     # TEXT * filnam
     # COUNT filmod
     # TEXT * fileword

COUNT
OpenIFile(ifilptr)
    IFIL * ifilptr

COUNT
OpenIFileXtd(ifilptr,dataextn,indxextn,fileword)
    IFIL * ifilptr
    TEXT * dataextn
    VOID * indxextn
    TEXT * fileword

COUNT
OpenISAM(filnam)
    TEXT * filnam

COUNT
OpenISAMContext(datno,keyno,contextid)
    COUNT datno
    COUNT keyno
    COUNT contextid

COUNT
OpenISAMXtd(filnam,userprof,userid,userword,servname,fileword)
    TEXT * filnam
    COUNT userprof
    TEXT * userid
    TEXT * userword
    TEXT * servname
    TEXT * fileword

 # COUNT
 # Perform(status_word)
     # LONG status_word

COUNT
PermIIndex(ifilptr)
    IFIL * ifilptr

COUNT
PositionSet(keyno,recptr,siglen)
    COUNT keyno
    VOID * recptr
    COUNT siglen

COUNT
PreviousInSet(keyno,recptr)
    COUNT keyno
    VOID * recptr

LONG
PreviousKey(keyno,idxval)
    COUNT keyno
    VOID * idxval

COUNT
PreviousRecord(filno,recptr)
    COUNT filno
    VOID * recptr

COUNT
PutDODA(datno,doda,numfld)
    COUNT datno
    DATOBJ * doda
    UCOUNT numfld

COUNT
PutIFile(ifilptr)
    IFIL * ifilptr

COUNT
PutIFileXtd(ifilptr,dataextn,indxextn,fileword)
    IFIL * ifilptr
    TEXT * dataextn
    VOID * indxextn
    TEXT * fileword

COUNT
ReadData(datno,recbyt,recptr)
    COUNT datno
    LONG recbyt
    VOID * recptr

COUNT
ReadIsamData(datno,recbyt,recptr)
    COUNT datno
    LONG recbyt
    VOID * recptr

COUNT
ReadVData(datno,recbyt,recptr,bufsiz)
    COUNT datno
    LONG recbyt
    VOID * recptr
    VRLEN bufsiz

COUNT
RebuildIFile(ifilptr)
    IFIL * ifilptr

COUNT
RebuildIFileXtd(ifilptr,dataextn,indxextn,permmask,groupid,fileword)
    IFIL * ifilptr
    TEXT * dataextn
    VOID * indxextn
    LONG permmask
    TEXT * groupid
    TEXT * fileword

COUNT
RegisterCtree(regid)
    TEXT * regid

COUNT
ReleaseData(datno,recbyt)
    COUNT datno
    LONG recbyt

COUNT
ReleaseVData(datno,recbyt)
    COUNT datno
    LONG recbyt

COUNT
ReReadRecord(datno,recptr)
    COUNT datno
    VOID * recptr

COUNT
ReReadVRecord(datno,recptr,bufsiz)
    COUNT datno
    VOID * recptr
    VRLEN bufsiz

COUNT
ResetRecord(datno,mode)
    COUNT datno
    COUNT mode

COUNT
RestoreSavePoint(savpnt)
    COUNT savpnt

COUNT
ReWriteRecord(datno,recptr)
    COUNT datno
    VOID * recptr

COUNT
ReWriteVRecord(datno,recptr,varlen)
    COUNT datno
    VOID * recptr
    UCOUNT varlen

COUNT
Security(filno,bufptr,bufsiz,mode)
    COUNT filno
    VOID * bufptr
    VRLEN bufsiz
    COUNT mode

COUNT
SetAlternateSequence(keyno,altseq)
    COUNT keyno
    COUNT * altseq

COUNT
SetNodeName(nodename)
    TEXT * nodename

LONG
SetOperationState(status_word,operation_code)
    LONG status_word
    VRLEN operation_code

COUNT
SetRecord(datno,recbyt,recptr,datlen)
    COUNT datno
    LONG recbyt
    VOID * recptr
    UCOUNT datlen

COUNT
SetSavePoint()

COUNT
SetVariableBytes(filno,pvbyte)
    COUNT filno
    UTEXT * pvbyte

COUNT
StopServer(userword,servname,delay)
    TEXT * userword
    TEXT * servname
    COUNT delay

COUNT
StopUser()

COUNT
SuperfilePrepassXtd(filnam,fileword)
    TEXT * filnam
    TEXT * fileword

COUNT
SwitchCtree(regid)
    TEXT * regid

COUNT
SystemConfiguration(bufptr)
    VOID * bufptr

COUNT
SystemMonitor(mode,timeout,buffer,buflen)
    COUNT mode
    LONG timeout
    TEXT * buffer
    LONG buflen

COUNT
TempIIndexXtd(ifilptr,permmask,groupid,fileword)
    IFIL * ifilptr
    LONG permmask
    TEXT * groupid
    TEXT * fileword

TEXT *
TransformKey(keyno,target)
    COUNT keyno
    VOID * target

COUNT
UnRegisterCtree(regid)
    TEXT * regid

COUNT
UpdateCtResource(datno,resptr,varlen)
    COUNT datno
    VOID * resptr
    UCOUNT varlen

COUNT
UpdateFileMode(filno,filmod)
    COUNT filno
    COUNT filmod

COUNT
UpdateHeader(filno,hdrval,mode)
    COUNT filno
    LONG hdrval
    COUNT mode

VRLEN
VDataLength(datno,recbyt)
    COUNT datno
    LONG recbyt

VRLEN
VRecordLength(datno)
    COUNT datno

TEXT *
WhichCtree()

COUNT
vtclose()

COUNT
WriteData(datno,recbyt,recptr)
    COUNT datno
    LONG recbyt
    VOID * recptr

COUNT
WriteVData(datno,recbyt,recptr,varlen)
    COUNT datno
    LONG recbyt
    VOID * recptr
    UCOUNT varlen



