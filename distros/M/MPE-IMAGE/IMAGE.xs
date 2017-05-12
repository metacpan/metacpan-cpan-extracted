#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


  #define make_int(var,index) (var[index] << 16) | (var[index+1] & 0xffff)

  void setstatus(short *status) {
    int  cnt;
    AV  *status_array;
    SV **sv_ptr;

    status_array = get_av("MPE::IMAGE::DbStatus",TRUE);
    /* Make sure we have enough entries */
    if (av_len(status_array) < 9) {
      av_unshift(status_array,10 - (av_len(status_array)+1));
    }
    for (cnt = 0; cnt < 10; cnt++) {
      if ((sv_ptr = av_fetch(status_array,cnt,FALSE)) == NULL) {
        av_store(status_array,cnt,newSViv(status[cnt]));
      } else {
        sv_setiv(*sv_ptr,status[cnt]);
      } 
    }
  } /* setstatus */

  SV *DbControl(SV *basehandle, short mode, SV *func, SV *set, short flags) {
    SV   **handle;
    short  status[10];
    short  qualifier[16];

    handle = hv_fetch((HV *)SvRV(basehandle),"handle",6,FALSE);
    if (handle == NULL) {
      croak("DbControl called without valid handle.");
    } 
    if ( mode < 1  || mode > 16 || mode == 11 || mode == 12 ) {
      warn("DbControl can only handle modes 1-10 and 13-16");
      warn("Ignoring DbControl call with mode %d",mode);
      return(&PL_sv_undef);
    }
    if (mode == 13) {
      qualifier[0] = SvIV(func);
      if (qualifier[0] != 0) {
        qualifier[1] = SvIV(set);
        qualifier[4] = flags;
      }
    } else if (mode == 14) {
      qualifier[0] = SvIV(func);
      qualifier[1] = SvPV_nolen(set)[0];
    } else if (mode == 15) {
      if (SvOK(func)) {
        qualifier[0] = SvPV_nolen(set)[0] << 8;
      }
    }
    dbcontrol(SvPV_nolen(*handle),&qualifier,&mode,status);
    setstatus(status);
    if (mode == 13 || mode == 14) {
      return(newSViv(make_int(qualifier,2)));
    } else {
      return(&PL_sv_undef);
    }
  }
    
  void setDbError(SV *ErrPtr) {
    int    cnt;
    short  dbstatus[10];
    char   error[73];
    short  error_len;
    AV    *status_array;
    SV    *DbError;
    SV   **sv_ptr;

    DbError = SvRV(ErrPtr);
    status_array = get_av("MPE::IMAGE::DbStatus",FALSE);
    if (status_array == NULL ||
        av_len(status_array) < 9 ||
        SvIV(*av_fetch(status_array,0,FALSE)) == 0) {
      sv_setiv(DbError,0);
      sv_setpvn(DbError,"",0);
      SvIOK_on(DbError);
    } else {
      for (cnt = 0; cnt < 10; cnt++) {
        sv_ptr = av_fetch(status_array,cnt,FALSE);
        dbstatus[cnt] = SvIV(*sv_ptr);
      }
      dberror(dbstatus,error,&error_len);
      sv_setiv(DbError,dbstatus[0]);
      sv_setpvn(DbError,error,error_len);
      SvIOK_on(DbError);
    }
  } /* setDbError */

  void DbExplain() {
    int    cnt;
    short  dbstatus[10];
    AV    *status_array;
    SV   **sv_ptr;

    status_array = get_av("MPE::IMAGE::DbStatus",FALSE);
    if (status_array != NULL && av_len(status_array) >= 9) {
      for (cnt = 0; cnt < 10; cnt++) {
        sv_ptr = av_fetch(status_array,cnt,FALSE);
        dbstatus[cnt] = SvIV(*sv_ptr);
      }
      dbexplain(dbstatus);
    }
  } /* DbExplain */

  void _dbclose(SV *basehandle, SV *dataset, short mode) {
    short    status[10];
    SV     **entry;
    STRLEN   len;
    char    *dset_buf;
    short    dset_num;

    entry = hv_fetch((HV *)SvRV(basehandle),"handle",6,FALSE);
    if (entry == NULL) {
      croak("DbClose called without valid handle.");
    } else {
      if (*entry == NULL) {
        croak("*entry is NULL");
      }
      if (SvIOK(dataset) || looks_like_number(dataset)) {
        (short *)dset_buf = &dset_num;
        dset_num = SvIV(dataset);
      } else {
        dset_buf = SvPV_nolen(dataset);
      }
      dbclose(SvPV_nolen(*entry),dset_buf,&mode,status);
      setstatus(status);
      if (status[0] == 0 && mode == 1) {
        hv_store((HV *)SvRV(basehandle),"closed",6,&PL_sv_undef,0);
      }
    }
  } /* _dbclose */

  void _dbdelete(SV *basehandle, SV *dset) {
    short   status[10];
    short   mode = 1;
    char   *dset_buf;
    short   dset_num;
    SV    **entry;

    entry = hv_fetch((HV *)SvRV(basehandle),"handle",6,FALSE);
    if (entry == NULL) {
      croak("DbDelete called without valid handle.");
    } 
    if (SvIOK(dset) || looks_like_number(dset)) {
      (short *)dset_buf = &dset_num;
      dset_num = SvIV(dset);
    } else {
      dset_buf = SvPV_nolen(dset);
    }

    dbdelete(SvPV_nolen(*entry),dset_buf,&mode,status);
    setstatus(status);

  } /* _dbdelete */

  void _dbfind(SV *basehandle, SV *dataset, short mode, SV *item,
               SV *argument) {
    short   status[10];
    SV    **entry;
    char   *dset_buf;
    short   dset_num;
    char   *item_buf;
    short   item_num;

    entry = hv_fetch((HV *)SvRV(basehandle),"handle",6,FALSE);
    if (entry == NULL) {
      croak("DbFind called without valid handle.");
    } 

    if (SvIOK(dataset) || looks_like_number(dataset)) {
      (short *)dset_buf = &dset_num;
      dset_num = SvIV(dataset);
    } else {
      dset_buf = SvPV_nolen(dataset);
    }

    if (SvIOK(item) || looks_like_number(item)) {
      (short *)item_buf = &item_num;
      item_num = SvIV(item);
    } else {
      item_buf = SvPV_nolen(item);
    }

    dbfind(SvPV_nolen(*entry),dset_buf,&mode,status,item_buf,
           SvPV_nolen(argument));
    setstatus(status);
  } /* _dbfind */
    
  SV *_dbget(SV *basehandle, SV *dataset, short mode, SV *list, 
             SV *argument, int size) {
    int     cnt;
    short   status[10];
    char   *buffer;
    SV    **entry;
    short  *list_buffer;
    AV     *list_array;
    char   *dset_buf;
    short   dset_num;
    SV     *ret_sv;

    entry = hv_fetch((HV *)SvRV(basehandle),"handle",6,FALSE);
    if (entry == NULL) {
      croak("DbGet called without valid handle.");
    } 
    if (size > 0) {
      buffer = malloc(size);
    } else {
      buffer = malloc(1);
    }
    if (buffer == NULL) {
      croak("Unable to malloc %d bytes in DbGet",size);
    }
    if (SvROK(list)) { /* Got a list of item numbers */
      list_array = (AV *)SvRV(list);
      list_buffer = calloc(av_len(list_array)+2,2);
      list_buffer[0] = av_len(list_array)+1;
      for (cnt = 1; cnt <= list_buffer[0]; cnt++) {
        list_buffer[cnt] = SvIV(*av_fetch(list_array,cnt-1,FALSE));
      }
    } else {
      (char *)list_buffer = SvPV_nolen(list);
    }
    if (SvIOK(dataset) || looks_like_number(dataset)) {
      (short *)dset_buf = &dset_num;
      dset_num = SvIV(dataset);
    } else {
      dset_buf = SvPV_nolen(dataset);
    }

    dbget(SvPV_nolen(*entry),dset_buf,&mode,status,list_buffer,buffer,
          SvPV_nolen(argument));
    setstatus(status);
    
    if (SvROK(list)) {
      free(list_buffer);
    }
    if (buffer != NULL) {
      ret_sv = newSVpvn(buffer,size);
      free(buffer);
      return(ret_sv);
    } else {
      return(&PL_sv_undef);
    }
  } /* _dbget */

  SV *_dbinfo(SV *basehandle, SV *qualifier, short mode) {
    int     cnt;
    short   status[10];
    short   qual_short;
    short  *buffer;
    int    *intbuf;
    AV     *new_array;
    HV     *new_hash;
    char   *char_ptr;
    SV     *temp_sv;
    SV     *return_sv;
    
    if ( mode < 101  || (mode > 104 &&
         mode < 113) || (mode > 113 &&
         mode < 201) || (mode > 209 &&
         mode < 301) || (mode > 302 &&
         mode < 401) || (mode > 404 &&
         mode < 406) || (mode > 406 &&
         mode < 501) || (mode > 502 &&
         mode < 901) ||  mode > 901 ) {
      warn("DbInfo can only handle the following modes:\n");
      warn("  101-104, 113, 201-209, 301-302, 401-404, 406, 501-502, 901\n");
      warn("Ignoring DbInfo call with mode %d",mode);
      return(&PL_sv_undef);
    }

    /* 
       Maxima:
        240 datasets per database
       1200 items per database
        255 items per dataset
         99 chunks per jumbo dataset
         64 paths per master dataset
         16 paths per detail dataset
     */
       
    if (mode == 101 || 
        mode == 201 || mode == 206 ||
        mode == 501 || 
        mode == 901) {
      buffer = calloc(1,2);
    } else if (mode == 302 || mode == 502) {
      buffer = calloc(2,2);
    } else if (mode == 401 || mode == 402) {
      buffer = calloc(16,2);
    } else if (mode == 102 || mode == 113 ||
               mode == 202 || mode == 205 ||
               mode == 403 || mode == 404 ||
               mode == 406) {
      buffer = calloc(32,2);
    } else if (mode == 208 || mode == 209) {
      /* put it into intbuf for access and buffer to be freed */
      (int *)buffer = intbuf = calloc(32,4);
    } else if (mode == 207 || mode == 301) {
      buffer = calloc(200,2);
    } else if (mode == 103 || mode == 104 || 
               mode == 203 || mode == 204) {
      buffer = calloc(1201,2);
    }
    if (SvIOK(qualifier) || looks_like_number(qualifier)) {
      qual_short = SvIV(qualifier);
      dbinfo(SvPV_nolen(basehandle),&qual_short,&mode,status,buffer);
    } else {
      dbinfo(SvPV_nolen(basehandle),SvPV_nolen(qualifier),&mode,status,buffer);
    }
    setstatus(status);
    if (status[0] != 0) {
      /* Something went wrong, don't parse return values */
      free(buffer);
      return(&PL_sv_undef);
    }
    if (mode == 101 || 
        mode == 201 || mode == 206 ||
        mode == 501 || 
        mode == 901) {
      return_sv = newSViv(*buffer);
    } else if (mode == 209) {
      new_array = newAV();

      av_push(new_array,newSViv(intbuf[0]));
      av_push(new_array,newSViv(intbuf[1]));
      
      return_sv = newRV_noinc((SV *)new_array);
    } else if (mode == 302 || mode == 502) {
      new_array = newAV();

      av_push(new_array,newSViv(buffer[0]));
      av_push(new_array,newSViv(buffer[1]));
      
      return_sv = newRV_noinc((SV *)new_array);
    } else if (mode == 102 || 
               mode == 202 || mode == 205) {
      new_hash = newHV();

      char_ptr = (char *)buffer + 16;
      while (char_ptr >= (char *)buffer && *(--char_ptr) == ' ') {}
      temp_sv = newSVpvn((char *)buffer,char_ptr - (char *)buffer + 1);
      hv_store(new_hash,"name",4,temp_sv,0);

      temp_sv = newSVpvn((char *)&buffer[8],1);
      hv_store(new_hash,"type",4,temp_sv,0);

      hv_store(new_hash,"length",6,newSViv(buffer[9]),0);

      if (mode == 102) {
        hv_store(new_hash,"count",      5,newSViv(buffer[10]),         0);
      } else {
        hv_store(new_hash,"block fact",10,newSViv(buffer[10]),         0);
        hv_store(new_hash,"entries",    7,newSViv(make_int(buffer,13)),0);
        hv_store(new_hash,"capacity",   8,newSViv(make_int(buffer,15)),0);
      
        if (mode == 205) {
          hv_store(new_hash,"hwm",         3,newSViv(make_int(buffer,17)),0);
          hv_store(new_hash,"max cap",     7,newSViv(make_int(buffer,19)),0);
          hv_store(new_hash,"init cap",    8,newSViv(make_int(buffer,21)),0);
          hv_store(new_hash,"increment",   9,newSViv(make_int(buffer,23)),0);
          hv_store(new_hash,"inc percent",11,newSViv(buffer[25]),         0);
          hv_store(new_hash,"dynamic cap",11,newSViv(buffer[26]),         0);
        }
      } 

      return_sv = newRV_noinc((SV *)new_hash);
    } else if (mode == 401 || mode == 403) {
      new_hash = newHV();

      char_ptr = (char *)buffer + 8;
      while (char_ptr >= (char *)buffer && *(--char_ptr) == ' ') {}
      temp_sv = newSVpvn((char *)buffer,char_ptr - (char *)buffer + 1);
      hv_store(new_hash,"logid",5,temp_sv,0);

      hv_store(new_hash,"base log flag",13,newSViv(buffer[4]),0);
      hv_store(new_hash,"user log flag",13,newSViv(buffer[5]),0);
      hv_store(new_hash,"trans flag",10,newSViv(buffer[6]),0);
      hv_store(new_hash,"user trans num",14,newSViv(make_int(buffer,7)),0);
   
      if (mode == 403) {
        hv_store(new_hash,"log set size",12,newSViv(make_int(buffer,9)),0);
        hv_store(new_hash,"log set type",12,newSVpvn((char *)&buffer[11],2),0);
        hv_store(new_hash,"base attached",13,newSViv(buffer[12]),0);
        hv_store(new_hash,"dynamic trans",13,newSViv(buffer[13]),0);

        char_ptr = (char *)buffer + 52;
        while (char_ptr >= (char *)buffer && *(--char_ptr) == ' ') {}
        temp_sv = newSVpvn((char *)buffer,char_ptr - (char *)buffer + 1);
        hv_store(new_hash,"log set name",12,temp_sv,0);

      }

      return_sv = newRV_noinc((SV *)new_hash);
    } else if (mode == 402) {
      new_hash = newHV();

      hv_store(new_hash,"ILR log flag",12,newSViv(buffer[0]),0);
      hv_store(new_hash,"ILR date",8,newSViv(buffer[1]),0);
      hv_store(new_hash,"ILR time",8,newSViv(make_int(buffer,2)),0);

      return_sv = newRV_noinc((SV *)new_hash);
    } else if (mode == 404) {
      new_hash = newHV();

      hv_store(new_hash,"base log flag",13,newSViv(buffer[0]),0);
      hv_store(new_hash,"user log flag",13,newSViv(buffer[1]),0);
      hv_store(new_hash,"rollback flag",13,newSViv(buffer[2]),0);
      hv_store(new_hash,"ILR log flag",12,newSViv(buffer[3]),0);
      hv_store(new_hash,"mustrecover",11,newSViv(buffer[4]),0);
      hv_store(new_hash,"base remote",11,newSViv(buffer[5]),0);
      hv_store(new_hash,"trans flag",10,newSViv(buffer[6]),0);

      char_ptr = (char *)buffer + 22;
      while (char_ptr >= (char *)buffer && *(--char_ptr) == ' ') {}
      temp_sv = newSVpvn((char *)buffer,char_ptr - (char *)buffer + 1);
      hv_store(new_hash,"logid",5,temp_sv,0);

      hv_store(new_hash,"log index",9,newSViv(make_int(buffer,11)),0);
      hv_store(new_hash,"trans id",8,newSViv(make_int(buffer,13)),0);
      hv_store(new_hash,"trans bases",11,newSViv(buffer[15]),0);
   
      new_array = newAV();

      for (cnt = 1; cnt <= buffer[15]; cnt++) {
        av_push(new_array,newSViv(buffer[cnt+15]));
      }

      hv_store(new_hash,"base ids",8,newRV_noinc((SV *)new_array),0);

      return_sv = newRV_noinc((SV *)new_hash);
    } else if (mode == 406) {
      new_hash = newHV();

      char_ptr = (char *)buffer + 28;
      while (char_ptr >= (char *)buffer && *(--char_ptr) == ' ') {}
      temp_sv = newSVpvn((char *)buffer,char_ptr - (char *)buffer + 1);
      hv_store(new_hash,"name",4,temp_sv,0);

      hv_store(new_hash,"mode",4,newSViv(buffer[14]),0);
      hv_store(new_hash,"version",7,newSVpvn((char *)&buffer[15],2),0);

      return_sv = newRV_noinc((SV *)new_hash);
    } else if (mode == 301) {
      new_array = newAV();

      for (cnt = 1; cnt <= buffer[0]; cnt++) {
        new_hash = newHV();
        hv_store(new_hash,"set",3,newSViv(buffer[cnt*3-2]),0);
        hv_store(new_hash,"search",6,newSViv(buffer[cnt*3-1]),0);
        hv_store(new_hash,"sort",4,newSViv(buffer[cnt*3]),0);
        av_push(new_array,newRV_noinc((SV *)new_hash));
      }

      return_sv = newRV_noinc((SV *)new_array);
    } else if (mode == 207) {
      new_array = newAV();

      for (cnt = 1; cnt <= buffer[0]; cnt++) {
        av_push(new_array,newSViv(make_int(buffer,cnt*2+1)));
      }
      return_sv = newRV_noinc((SV *)new_array);
    } else if (mode == 103 || mode == 104 || 
               mode == 203 || mode == 204) {
      new_array = newAV();

      for (cnt = 1; cnt <= buffer[0]; cnt++) {
        av_push(new_array,newSViv(buffer[cnt]));
      }
      return_sv = newRV_noinc((SV *)new_array);
    } else if (mode == 113) {
      new_array = newAV();

      for (cnt = 0; cnt < 6; cnt++) {
        if (cnt == 1 || cnt == 5) {
          char_ptr = (char *)buffer + (2*cnt + 1);
          av_push(new_array,newSVpvn(char_ptr,1));
        } else {
          av_push(new_array,newSViv((unsigned short)buffer[cnt]));
        }
      }
      
      return_sv = newRV_noinc((SV *)new_array);
    } else if (mode == 208) {
      new_array = newAV();

      for (cnt = 0; cnt < 7; cnt++) {
        if (cnt == 3 || cnt == 7) {
          av_push(new_array,newSViv(intbuf[cnt]));
        } else {
          av_push(new_array,newSViv((unsigned int)intbuf[cnt]));
        }
      }
      return_sv = newRV_noinc((SV *)new_array);
    }
    free(buffer);
    return(return_sv);
  } /* _dbinfo */

  void _dblock(SV *basehandle, short mode, SV *descr) {
    short   status[10];
    SV    **entry;

    entry = hv_fetch((HV *)SvRV(basehandle),"handle",6,FALSE);
    if (entry == NULL) {
      croak("DbLock called without valid handle.");
    } 

    dblock(SvPV_nolen(*entry),SvPV_nolen(descr),&mode,status);
    setstatus(status);
  } /* _dblock */

  SV *_dbopen(char *basename, char *password, short mode) {
    short status[10];
    SV *base_name;
    SV *base_handle;
    HV *base_opened;

    base_name = newSVpv(basename,0);
    if (base_name == NULL) {
      croak("Unable to newSVpv base_name for %s",basename);
    }
    dbopen(basename,password,&mode,status);
    setstatus(status);
    base_opened = newHV();
    if (base_opened == NULL) {
      croak("Unable to newHV during _dbopen of %s\n",SvPV_nolen(base_name));
    }
    hv_store(base_opened,"name",4,base_name,0);
    if (status[0] == 0) { /* Successful open */
      base_handle = newSVpvn(basename,SvCUR(base_name));
      if (base_name == NULL) {
        croak("Unable to newSVpvn base_handle for %s",SvPV_nolen(base_name));
      }
      hv_store(base_opened,"handle",6,base_handle,0);
    }
    return newRV_noinc((SV*) base_opened);
  } /* _dbopen */

  void _dbput(SV *basehandle, SV *dset, SV *list, SV *buffer) {
    short   status[10];
    short   mode = 1;
    SV    **entry;
    short  *list_buffer;
    AV     *list_array;
    int     cnt;
    char   *dset_buf;
    short   dset_num;
    
    entry = hv_fetch((HV *)SvRV(basehandle),"handle",6,FALSE);
    if (entry == NULL) {
      croak("DbPut called without valid handle.");
    }
    if (SvROK(list)) { /* Got a list of item numbers */
      list_array = (AV *)SvRV(list);
      list_buffer = calloc(av_len(list_array)+2,2);
      list_buffer[0] = av_len(list_array)+1;
      for (cnt = 1; cnt <= list_buffer[0]; cnt++) {
        list_buffer[cnt] = SvIV(*av_fetch(list_array,cnt-1,FALSE));
      }
    } else {
      (char *)list_buffer = SvPV_nolen(list);
    }

    if (SvIOK(dset) || looks_like_number(dset)) {
      (short *)dset_buf = &dset_num;
      dset_num = SvIV(dset);
    } else {
      dset_buf = SvPV_nolen(dset);
    }

    dbput(SvPV_nolen(*entry),dset_buf,&mode,status,list_buffer,
          SvPV_nolen(buffer));
    setstatus(status);

  } /* _dbput */

  void _dbupdate(SV *basehandle, SV *dset, SV *list, SV *buffer) {
    short   status[10];
    short   mode = 1;
    SV    **entry;
    short  *list_buffer;
    AV     *list_array;
    int     cnt;
    char   *dset_buf;
    short   dset_num;
    
    entry = hv_fetch((HV *)SvRV(basehandle),"handle",6,FALSE);
    if (entry == NULL) {
      croak("DbUpdate called without valid handle.");
    }
    if (SvROK(list)) { /* Got a list of item numbers */
      list_array = (AV *)SvRV(list);
      list_buffer = calloc(av_len(list_array)+2,2);
      list_buffer[0] = av_len(list_array)+1;
      for (cnt = 1; cnt <= list_buffer[0]; cnt++) {
        list_buffer[cnt] = SvIV(*av_fetch(list_array,cnt-1,FALSE));
      }
    } else {
      (char *)list_buffer = SvPV_nolen(list);
    }

    if (SvIOK(dset) || looks_like_number(dset)) {
      (short *)dset_buf = &dset_num;
      dset_num = SvIV(dset);
    } else {
      dset_buf = SvPV_nolen(dset);
    }

    dbupdate(SvPV_nolen(*entry),dset_buf,&mode,status,list_buffer,
             SvPV_nolen(buffer));
    setstatus(status);

  } /* _dbupdate */

  void _dbunlock(SV *basehandle) {
    short   status[10];
    short   mode = 1;
    short   dset;
    SV    **entry;

    entry = hv_fetch((HV *)SvRV(basehandle),"handle",6,FALSE);
    if (entry == NULL) {
      croak("DbUnlock called without valid handle.");
    } 
    dbunlock(SvPV_nolen(*entry),&dset,&mode,status);
    setstatus(status);
  } /* _dbunlock */

  #define DBBEGIN  0
  #define DBEND    1
  #define DBMEMO   2
  #define DBXBEGIN 3
  #define DBXEND   4
  #define DBXUNDO  5

  SV *_doBEUM(SV *base_s, short mode, char *text, int call) {
    short   status[10];
    int     cnt;
    short  *db_array = NULL;
    SV    **entry;
    SV    **handle;
    SV     *ret_sv;
    short   textlen;
    char    callnames[49] = "DbBegin DbEnd   DbMemo  DbXBeginDbXEnd  DbXUndo ";
    char    callname[9] = "        ";

    textlen = -strlen(text);
    strncpy(callname,&callnames[call * 8],8);
    if (sv_isobject(base_s) && sv_derived_from(base_s, "MPE::IMAGE")) {
      handle = hv_fetch((HV *)SvRV(base_s),"handle",6,FALSE);
      if (handle == NULL) {
        croak("invalid database handle in call to %s",callname);
      }
      switch (call) {
        case DBBEGIN: 
          dbbegin(SvPV_nolen(*handle),text,&mode,status,&textlen); 
          break;
        case DBEND:
          dbend(SvPV_nolen(*handle),text,&mode,status,&textlen); 
          break;
        case DBMEMO:
          dbmemo(SvPV_nolen(*handle),text,&mode,status,&textlen);
          break;
        case DBXBEGIN:
          dbxbegin(SvPV_nolen(*handle),text,&mode,status,&textlen); 
          break;
        case DBXEND:
          dbxend(SvPV_nolen(*handle),text,&mode,status,&textlen); 
          break;
        case DBXUNDO:
          dbxundo(SvPV_nolen(*handle),text,&mode,status,&textlen); 
          break;
      }
      setstatus(status);
      return(&PL_sv_undef);
    } else if (sv_derived_from(base_s, "ARRAY")) {
      db_array = calloc(av_len((AV *)SvRV(base_s))+4,2);
      db_array[0] = db_array[1] = 0;
      db_array[2] = av_len((AV *)SvRV(base_s))+1;
      for (cnt = 0; cnt < db_array[2]; cnt++) {
        entry = av_fetch((AV *)SvRV(base_s),cnt,FALSE);
        if (entry == NULL) {
          croak("Unable to av_fetch array entry %d in %s",cnt,callname);
        }
        handle = hv_fetch((HV *)SvRV(*entry),"handle",6,FALSE);
        if (handle == NULL) {
          croak("Array element %d was not a database pointer in %s",
                cnt,callname);
        }
        db_array[3+cnt] = *(short *)SvPV_nolen(*handle);
      }
      switch (call) {
        case DBBEGIN:
          dbbegin(db_array,text,&mode,status,&textlen);
          break;
        case DBEND:
          dbend(db_array,text,&mode,status,&textlen);
          break;
        case DBMEMO:
          croak("DBMemo called with a a baseid list");
          break;
        case DBXBEGIN:
          dbxbegin(db_array,text,&mode,status,&textlen);
          break;
        case DBXEND:
          dbxend(db_array,text,&mode,status,&textlen);
          break;
        case DBXUNDO:
          dbxundo(db_array,text,&mode,status,&textlen);
          break;
      }
      setstatus(status);
      ret_sv = newSVpvn((char *)&db_array,(av_len((AV *)SvRV(base_s))+4)*2);
      free(db_array);
      return(ret_sv);
    } else { 
      switch (call) {
        case DBEND:
          dbend(SvPV_nolen(base_s),text,&mode,status,&textlen);
          break;
        case DBXEND:
          dbxend(SvPV_nolen(base_s),text,&mode,status,&textlen);
          break;
        case DBXUNDO:
          dbxundo(SvPV_nolen(base_s),text,&mode,status,&textlen);
          break;
        default:
          croak("%s called with without database reference.",callname);
      }
      setstatus(status);
      return(&PL_sv_undef);
    }
  } /* _doBEUM */

  /* These two work with the reals in packed form */
  SV *_IEEE_real_to_HP_real(SV *source) {
    float    sreal;
    double   lreal;
    int      status;
    short    except;

    if (SvCUR(source) == 4) {  /* 32-bit form */
      HPFPCONVERT(7,SvPV_nolen(source),&sreal,3,1,&status,&except,0);
      return(newSVpvn((char *)&sreal,4));
    } else {
      HPFPCONVERT(7,SvPV_nolen(source),&lreal,4,2,&status,&except,0);
      return(newSVpvn((char *)&lreal,8));
    }
  }

  SV *_HP_real_to_IEEE_real(SV *source) {
    float    sreal;
    double   lreal;
    int      status = 0;
    short    except = 0;

    if (SvCUR(source) == 4) {  /* 32-bit form */
      HPFPCONVERT(7,SvPV_nolen(source),&sreal,1,3,&status,&except,0);
      return(newSVpvn((char *)&sreal,4));
    } else {
      HPFPCONVERT(7,SvPV_nolen(source),&lreal,2,4,&status,&except,0);
      return(newSVpvn((char *)&lreal,8));
    }
  }


MODULE = MPE::IMAGE	PACKAGE = MPE::IMAGE	

PROTOTYPES: DISABLE

SV *
DbControl(basehandle, mode, func = &PL_sv_undef, set = &PL_sv_undef, flags = 0)
        SV *     basehandle
        short    mode
        SV *     func
        SV *     set
        short    flags

void
setDbError (ErrPtr)
	SV *	ErrPtr

void
DbExplain ()

void
_dbclose (basehandle, dataset, mode)
	SV *	basehandle
	SV *	dataset
	short	mode

void
_dbdelete (basehandle, dataset)
        SV *    basehandle
        SV *    dataset

void
_dbfind (basehandle, dataset, mode, item, argument)
         SV *    basehandle
         SV *    dataset
         short   mode
         SV *    item
         SV *    argument

SV *
_dbget (basehandle, dataset, mode, list, argument, size)
	SV *	basehandle
	SV *	dataset
	short	mode
	SV *	list
	SV *	argument
	int	size

SV *
_dbinfo (basehandle, qualifier, mode)
	SV *	basehandle
	SV *	qualifier
	short	mode

void
_dblock (basehandle, mode, descr)
        SV *    basehandle
        short   mode
        SV *    descr

SV *
_dbopen (basename, password, mode)
	char *	basename
	char *	password
	short	mode

void
_dbput (basehandle, dset, list, buffer)
        SV *    basehandle
        SV *    dset
        SV *    list
        SV *    buffer

void
_dbupdate (basehandle, dset, list, buffer)
        SV *    basehandle
        SV *    dset
        SV *    list
        SV *    buffer

SV *
DbBegin (base_s, mode, text = "")
	SV *    base_s
	short   mode
        char *  text
  CODE:
    RETVAL = _doBEUM(base_s, mode, text, DBBEGIN);

void
DbEnd (base_s, mode, text = "")
	SV *    base_s
	short   mode
        char *  text
  CODE:
    _doBEUM(base_s, mode, text, DBEND);

void
DbMemo (base_s, text = "", mode = 1)
        SV *    base_s
        short   mode
        char *  text
  CODE:
    _doBEUM(base_s, mode, text, DBMEMO);

void
DbUnlock (base_s)
          SV *    base_s
  CODE:
    _dbunlock(base_s);

SV *
DbXBegin (base_s, mode, text = "")
	SV *    base_s
	short   mode
        char *  text
  CODE:
    RETVAL = _doBEUM(base_s, mode, text, DBXBEGIN);

void
DbXEnd (base_s, mode, text = "")
	SV *    base_s
	short   mode
        char *  text
  CODE:
    _doBEUM(base_s, mode, text, DBXEND);

void
DbXUndo (base_s, mode, text = "")
	SV *    base_s
	short   mode
        char *  text
  CODE:
    _doBEUM(base_s, mode, text, DBXUNDO);

SV *
_IEEE_real_to_HP_real (source)
	SV *	source

SV *
_HP_real_to_IEEE_real (source)
	SV *	source

