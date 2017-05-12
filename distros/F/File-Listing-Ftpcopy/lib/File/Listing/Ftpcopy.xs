#include "ftpparse.h"
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include <stdint.h>
#define MATH_INT64_NATIVE_IF_AVAILABLE
#include "perl_math_int64.h"

MODULE = File::Listing::Ftpcopy		PACKAGE = File::Listing::Ftpcopy

BOOT:
    PERL_MATH_INT64_LOAD_OR_CROAK;

SV *
ftpparse(line)
        char *line;
    INIT:
        HV * result;
        struct ftpparse fp;
        int val;
    CODE:
        val = ftpparse(&fp, line, strlen(line), 0);
        if(val)
        {
          result = newHV();
          hv_store(result, "name",            4, newSVpv(fp.name,fp.namelen), 0);
          hv_store(result, "flagtrycwd",     10, newSViv(fp.flagtrycwd), 0);
          hv_store(result, "flagtryretr",    11, newSViv(fp.flagtryretr), 0);
          hv_store(result, "sizetype",        8, newSViv(fp.sizetype), 0);
          /*
           * If UV is 64 bit then store size as a UV,
           * otherwise use sprintf and store it as a string.
           * use PRIu64 which is c99, otherwise try %llu
           * and cross fingers that it is supported.
           */
          hv_store(result, "size",            4, newSVu64(fp.size), 0);
          hv_store(result, "mtimetype",       9, newSViv(fp.mtimetype), 0);
          /*
           * okay this is slightly silly, the TAI implementation
           * with ftpparse is converting from UNIX time to TAI but
           * it isn't consulting any leap second tables or anything
           * like that so it is sort of pointless.  Since most Perl
           * programmers are likely to be dealing with the UNIX time
           * scale we will just quietly convert it back to UNIX time
           * (at least in so far as it was converted to TAI in the
           * first place).
           */
          hv_store(result, "mtime",           5, newSVu64(fp.mtime.x-4611686018427387914ULL), 0);
          hv_store(result, "idtype",          6, newSViv(fp.idtype), 0);
          hv_store(result, "id",              2, newSVpv(fp.id, fp.idlen), 0);
          hv_store(result, "format",          6, newSViv(fp.format), 0);
          hv_store(result, "flagbrokenmlsx", 14, newSViv(fp.flagbrokenmlsx), 0);
          if(fp.symlink != NULL)
          {
            hv_store(result, "symlink", 7, newSVpv(fp.symlink, fp.symlinklen), 0);
          }
          RETVAL = newRV_noinc((SV*)result);
        }
        else
        {
          XSRETURN_EMPTY;
        }
    OUTPUT:
        RETVAL
       

SV *
_parse_dir(line)
        char * line
    INIT:
        struct ftpparse fp;
        int val;
        AV * result;
        char *type;
        SV * size;
        SV * mtime;
    CODE:
        val = ftpparse(&fp, line, strlen(line), 0);
        if(val && !(fp.namelen == 1 && fp.name[0] == '.') && !(fp.namelen == 2 && fp.name[0] == '.' && fp.name[1] == '.'))
        {
          result = newAV();
          av_push(result, newSVpv(fp.name,fp.namelen));
          if(fp.symlink != NULL)
            type = "l";
          else if(fp.flagtrycwd && !fp.flagtryretr)
            type = "d";
          else if(!fp.flagtrycwd && fp.flagtryretr)
            type = "f";
          else
            type = "?";
          av_push(result, newSVpv(type, 1));
          if(fp.sizetype == FTPPARSE_SIZE_UNKNOWN)
          {
            size = newSV(0);
          }
          else
          {
            size = newSVu64(fp.size);
          }
          av_push(result, size);
          if(fp.mtimetype == FTPPARSE_MTIME_UNKNOWN)
          {
            mtime = newSV(0);
          }
          else
          {
            mtime = newSVu64(fp.mtime.x-4611686018427387914ULL);
          }
          av_push(result, mtime);
          av_push(result, newSV(0));
          av_push(result, newSViv(fp.mtimetype));
          RETVAL = newRV_noinc((SV*)result);
        }
        else
        {
          XSRETURN_EMPTY;
        }
    OUTPUT:
        RETVAL
        

int
_return42()
    CODE:
        RETVAL = (10*4+2);
    OUTPUT:
        RETVAL

int
_size_of_UV()
    CODE:
        RETVAL = sizeof(UV);
    OUTPUT:
        RETVAL

int
_constant(name)
        char *name
    CODE:
        if(!strcmp(name, "FORMAT_EPLF"))
          RETVAL = FTPPARSE_FORMAT_EPLF;
        else if(!strcmp(name, "FORMAT_LS"))
          RETVAL = FTPPARSE_FORMAT_LS;
        else if(!strcmp(name, "FORMAT_MLSX"))
          RETVAL = FTPPARSE_FORMAT_MLSX;
        else if(!strcmp(name, "FORMAT_UNKNOWN"))
          RETVAL = FTPPARSE_FORMAT_UNKNOWN;
        else if(!strcmp(name, "ID_FULL"))
          RETVAL = FTPPARSE_ID_FULL;
        else if(!strcmp(name, "ID_UNKNOWN"))
          RETVAL = FTPPARSE_ID_UNKNOWN;
        else if(!strcmp(name, "MTIME_LOCAL"))
          RETVAL = FTPPARSE_MTIME_LOCAL;
        else if(!strcmp(name, "MTIME_REMOTEDAY"))
          RETVAL = FTPPARSE_MTIME_REMOTEDAY;
        else if(!strcmp(name, "MTIME_REMOTEMINUTE"))
          RETVAL = FTPPARSE_MTIME_REMOTEMINUTE;
        else if(!strcmp(name, "MTIME_REMOTESECOND"))
          RETVAL = FTPPARSE_MTIME_REMOTESECOND;
        else if(!strcmp(name, "MTIME_UNKNOWN"))
          RETVAL = FTPPARSE_MTIME_UNKNOWN;
        else if(!strcmp(name, "SIZE_ASCII"))
          RETVAL = FTPPARSE_SIZE_ASCII;
        else if(!strcmp(name, "SIZE_BINARY"))
          RETVAL = FTPPARSE_SIZE_BINARY;
        else if(!strcmp(name, "SIZE_UNKNOWN"))
          RETVAL = FTPPARSE_SIZE_UNKNOWN;
        else
          RETVAL = -1;
    OUTPUT:
        RETVAL


SV *
_tai_now()
    INIT:
        SV *result;
        struct tai to;
        char b[21];
    CODE:
        tai_now(&to);
#ifdef PRIu64
        sprintf(b, "%"PRIu64,to.x);
#else
        sprintf(b, "%llu",to.x);
#endif
        result = newSVpv(b,0);
        RETVAL = newRV_noinc(result);
    OUTPUT:
        RETVAL

