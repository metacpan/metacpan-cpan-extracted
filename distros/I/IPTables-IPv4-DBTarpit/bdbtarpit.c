/*	bdbtarpit.c
 *
 *	VERSION information is in bdbtarpit.h
 *
 *   Copyright 2003 - 2009, Michael Robinton <michael@bizsystems.com>           *
 *                                                                              *
 *   This program is free software; you can redistribute it and/or modify       *
 *   it under the same terms as Perl itself.                                    *
 *                                                                              *
 * **************************************************************************** *
 */

#include <sys/types.h>
#include <netinet/in.h>
#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include "bdbtarpit.h"

char versionstring[100];

/*  from BDB
    typedef struct {
	void *data;
	u_int32_t size;
	u_int32_t ulen;
	u_int32_t dlen;
	u_int32_t doff;
	u_int32_t flags;
    } DBT;
 */

/* ****************************	*
 *	close environment	*
 * ****************************	*/

void
dbtp_env_close(DBTPD * dbtp)
{
  if (dbtp->dbenv != NULL) {
#if DB_VERSION_MAJOR == 2
    dbtp->dberr = db_appexit(dbtp->dbenv);
#else	/* DB_VERSION_MAJOR > 2	*/
    dbtp->dberr = dbtp->dbenv->close(dbtp->dbenv, 0);
#endif
  }
  dbtp->dbenv = NULL;
}

/* ****************************	*
 *	finish & exit		*
 * ****************************	*/

void
dbtp_close(DBTPD * dbtp)
{
/*	close database(s)	*/
  int ai;

  if (dbtp->dbenv == NULL)
    return;
    
  for(ai=0; ai<DBTP_MAXdbf; ai++) {
    if (dbtp->dbaddr[ai] == NULL)
    	continue;

    (void)dbtp->dbaddr[ai]->close(dbtp->dbaddr[ai],0);
    dbtp->dbaddr[ai] = NULL;
  }
  dbtp_env_close(dbtp);
}

/* ***************************************************************************
 *				init database
 *	init all databases present in the name array if 'index' is < 0
 *	otherwise initialize only the specific database pointed to by 'index'
 *
 *	Exception:	if index == DB_RUNRECOVERY, then DBENV->remove
 *			is performed before the environment is opened.
 * ***************************************************************************

Returns:	0 on success, or error code
 */
int
dbtp_init(DBTPD * dbtp, unsigned char * home, int index)
{
  u_int32_t eflags = DB_CREATE | DB_INIT_CDB | DB_INIT_MPOOL;
  u_int32_t dflags = DB_CREATE;
  u_int32_t info = DB_RECNUM;
  DBTYPE type = DB_BTREE;
  int mode = 0664;
  int ai;

/*
 *	OPEN / CREATE ENVIRONMENT
 *
 *	Since the databases are not transactional, we really don't run recovery.
 *	All that is typically corrupted is the DB environment so destroy the 
 *	environment files and recreate them instead. If this does not work,
 *	operator intervention will be necessary.
 */
 
#if DB_VERSION_MAJOR == 2
  if (index == DB_RUNRECOVERY)
	goto DBTP_env_err;		/* sorry, can't do recovery unless > version 2	*/

  if ((dbtp->dbenv = (DB_ENV *) calloc(sizeof(DB_ENV), 1)) == NULL )
	return (dbtp->dberr = errno);

  if (dbtp->dberr = db_appinit(home, NULL, dbtp->dbenv, eflags | DB_USE_ENVIRON) != 0)
  {
    free(dbtp->dbenv);
DBTP_env_err:
    dbtp->dbenv = NULL;
    return(dbtp->dberr);
  }

#else	/*	DB_VERSION_MAJOR > 2	*/

DBTP_reopen:
  if ((dbtp->dberr = db_env_create(&dbtp->dbenv,0)) != 0)
	goto DBTP_env_err;

  if (index == DB_RUNRECOVERY) {
#ifdef IS_DB_3_0_x
    if ((dbtp->dberr = dbtp->dbenv->remove(dbtp->dbenv, (char *)home, NULL, DB_FORCE)) != 0)
#else	/*	> 3.0	*/
    if ((dbtp->dberr = dbtp->dbenv->remove(dbtp->dbenv, (char *)home, DB_FORCE)) != 0)
#endif
	goto DBTP_env_err;

    index = -1;
    dbtp->dbenv = NULL;
    goto DBTP_reopen;
  }

#ifdef IS_DB_3_0_x
  if ((dbtp->dberr = dbtp->dbenv->open(dbtp->dbenv, (char *)home, NULL, eflags, mode)) != 0) {
#else	/*	> 3.0	*/
  if ((dbtp->dberr = dbtp->dbenv->open(dbtp->dbenv, (char *)home, eflags, mode)) != 0) {
#endif
    (void)dbtp->dbenv->close(dbtp->dbenv, 0);
DBTP_env_err:
    dbtp->dbenv = NULL;
    return(dbtp->dberr);
  }

#endif	/*	DB_VERSION_MAJOR > 2	*/

/*
 *	CREATE / OPEN DATABASE's
 */

  for(ai=0; ai<DBTP_MAXdbf; ai++) {
    if (index < 0) {
      if (dbtp->dbfile[ai] == NULL) {
        if (ai)
	  return(dbtp->dberr);		/* last status if end of array and something opened	*/
        else {
	  dbtp_env_close(dbtp);
          return(dbtp->dberr = ENODATA);		/* fatal if nothing to open	*/
        }    
      }
    }
    else {
      ai = index;
      index = 1;		/* always 'positive' if active	*/
    }
    if ((dbtp->dberr = db_create(&dbtp->dbaddr[ai],dbtp->dbenv,0)) != 0)
    {
  Bail:
      dbtp_close(dbtp);
      return(dbtp->dberr);
    }
    if ((dbtp->dberr = dbtp->dbaddr[ai]->set_flags(dbtp->dbaddr[ai], info)) != 0)
	goto Bail;
#if DB_VERSION_MAJOR > 2
#ifdef AT_LEAST_DB_4_1
    if ((dbtp->dberr = (dbtp->dbaddr[ai]->open(dbtp->dbaddr[ai], NULL, dbtp->dbfile[ai], NULL, type, dflags, mode))) != 0)
#else
    if ((dbtp->dberr = (dbtp->dbaddr[ai]->open(dbtp->dbaddr[ai], dbtp->dbfile[ai], NULL, type, dflags, mode))) != 0)
#endif /* AT_LEAST_DB_4_1 */
#else /* DB_VERSION_MAJOR == 2 */
    if ((dbtp->dberr = db_open(dbtp->dbfile[ai], type, dflags, mode, dbtp->dbenv, info, &dbtp->dbaddr[ai]))) != 0)
#endif /* DB_VERSION_MAJOR == 2 */
	goto Bail;
    if (index > 0)
      break;
  }  
  return(dbtp->dberr);
}

/*	returns 0 if addr and *addr are valid
 *	else it returns DB_KEYEMPTY
 */
int
_dbtp_set(DBTPD * dbtp, void * addr, size_t size)
{
  if (size != sizeof(u_int32_t) || addr == NULL || *(u_int32_t *)addr == 0)
  	return(DB_KEYEMPTY);
  memset(&dbtp->keydbt, 0, sizeof(DBT));
  memset(&dbtp->mgdbt, 0, sizeof(DBT));
  dbtp->keydbt.data = addr;
  dbtp->keydbt.size = (u_int32_t)size;
  return(0);
}

/* ****************************	*
 *	return 0 on success	*
 *	or the bdb error code	*
 *	external data structure	*
 *	mgdbt is filled		*
 *
 *	typedef struct {
 *           void *data;
 *           u_int32_t size;
 *           u_int32_t ulen;
 *           u_int32_t dlen;
 *           u_int32_t doff;
 *           u_int32_t flags;
 *	} DBT;
 *
 */

int
dbtp_get(DBTPD * dbtp, int ai, void * addr, size_t size)
{
  if(dbtp->dbaddr[ai] == NULL)
  	return(dbtp->dberr = ENODATA);

  if ((dbtp->dberr = _dbtp_set(dbtp,addr,size)))
  	return(dbtp->dberr); 
  return(dbtp->dberr = dbtp->dbaddr[ai]->get(dbtp->dbaddr[ai], NULL, &dbtp->keydbt, &dbtp->mgdbt, 0));
}

/* ****************************	*
 *	return 0 on success	*
 *	or the bdb error code	*
 *	external data structure	*
 *	mgdbt and keydbt are	*
 *	filled			*
 *
 *	typedef struct {
 *           void *data;
 *           u_int32_t size;
 *           u_int32_t ulen;
 *           u_int32_t dlen;
 *           u_int32_t doff;
 *           u_int32_t flags;
 *	} DBT;
 *
 */
 
int
dbtp_getrecno(DBTPD * dbtp, int ai, u_int32_t cursor)
{
  if(dbtp->dbaddr[ai] == NULL)
  	return(dbtp->dberr = ENODATA);

REGET_by_cursor:
  memset(&dbtp->keydbt, 0, sizeof(DBT));
  memset(&dbtp->mgdbt, 0, sizeof(DBT));
  dbtp->keydbt.data = &cursor;
  dbtp->keydbt.size = (u_int32_t)sizeof(cursor);

  return(dbtp->dberr = dbtp->dbaddr[ai]->get(dbtp->dbaddr[ai], NULL, &dbtp->keydbt, &dbtp->mgdbt, DB_SET_RECNO));

  dbtp->dberr = dbtp->dbaddr[ai]->get(dbtp->dbaddr[ai], NULL, &dbtp->keydbt, &dbtp->mgdbt, DB_SET_RECNO);
  if (! dbtp->dberr && dbtp->keydbt.size != sizeof(INADDR_BROADCAST)) {
    dbtp_del(dbtp,ai,dbtp->keydbt.data,dbtp->keydbt.size);
    goto REGET_by_cursor;
  }
  return(dbtp->dberr);
}

/* get the number of keys or records from the target database, by index	*/

u_int32_t
dbtp_stati(DBTPD * dbtp, int ai)
{
  DB_BTREE_STAT * statistics = NULL;
  u_int32_t bt_nkeys;
  
  if(dbtp->dbaddr[ai] == NULL) {
    dbtp->dberr = DB_NOTFOUND;
    return(0);
  }

#ifdef AT_LEAST_DB_4_3
  dbtp->dberr = dbtp->dbaddr[ai]->stat(dbtp->dbaddr[ai],NULL,&statistics,DB_FAST_STAT);
#else  
# ifdef AT_LEAST_DB_3_3
  dbtp->dberr = dbtp->dbaddr[ai]->stat(dbtp->dbaddr[ai],&statistics,DB_FAST_STAT);
# else
  dbtp->dberr = dbtp->dbaddr[ai]->stat(dbtp->dbaddr[ai],&statistics,NULL,DB_RECORDCOUNT);
# endif
#endif

  if (dbtp->dberr)
	bt_nkeys = 0;
  else
#ifdef AT_LEAST_DB_3_1
	bt_nkeys = statistics->bt_nkeys;
#else
	bt_nkeys = statistics->bt_nrecs;
#endif

  free(statistics);
  return(bt_nkeys);
}

/* get the number of keys or records from the target database, by name	*/

u_int32_t
dbtp_statn(DBTPD * dbtp, char * name)
{
  int ai;
  
  if ((ai = dbtp_index(dbtp, name)) < 0)
  	return(0);
  return(dbtp_stati(dbtp, ai));
}

/* return pointer to database or NULL if name not matched	*/

int
dbtp_index(DBTPD * dbtp, char * name)
{
  int ai;

  for(ai=0; ai<DBTP_MAXdbf; ai++) {
    if(dbtp->dbfile[ai] == NULL)
        goto NotFound;
    if(strcmp(name,dbtp->dbfile[ai]))
    	continue;
    return(ai);
  }
 NotFound:
  dbtp->dberr = -1;
  return(-1);
}

/* read data from a particular database, enter with pointer to db and method	*/

int
dbtp_readOne(DBTPD * dbtp, u_char how, int ai, void * ptr, int is_network)
{
  int major, minor, patch;
  u_int32_t cursor;
  u_char * vp;

  if (how) {
/* it is a normal record access since 0 is never a valid record number */
    if (is_network)
      cursor = ntohl(*(u_int32_t *)ptr);
    else
      cursor = *(u_int32_t *)ptr;

    if (cursor)
      dbtp->dberr = dbtp_getrecno(dbtp,ai,cursor);
    else {
/* send back the number of keys in the database and the version number
 * All the data is stuffed into the DBT structure since it is not used to get the data
 *
 *	generate the version info
 */
      (void)db_version(&major,&minor,&patch);
      vp = (u_char *)&dbtp->keydbt.flags;
      dbtp->keydbt.data = vp;
      dbtp->keydbt.size = (u_int32_t)sizeof(u_int32_t);	/* size of IPv4 netaddr	*/
      *vp++ = 0;
      *vp++ = (u_char)major;
      *vp++ = (u_char)minor;
      *vp++ = (u_char)patch;
/*	generate the number of keys/records in the database	*/
      dbtp->mgdbt.data = &dbtp->mgdbt.flags;
      dbtp->mgdbt.size = (u_int32_t)sizeof(u_int32_t);
      dbtp->mgdbt.flags = dbtp_stati(dbtp,ai);
      if (is_network)
        dbtp->mgdbt.flags = htonl(dbtp->mgdbt.flags);

      return(0);
    }
  }
  else
    dbtp->dberr = dbtp_get(dbtp,ai,ptr,sizeof(void *));

  if (dbtp->mgdbt.size == sizeof(u_int32_t)) {		/* is this a u_int32_t ??, all other records are larger	*/
    if (is_network)
      *(u_int32_t *)(dbtp->mgdbt.data) = htonl(*(u_int32_t *)(dbtp->mgdbt.data));
  }
  return(dbtp->dberr);
}

/*	reads from database
 *	how	= 0, read by key
 *	how	= 1, read by record number
 *	name	= database name
 *	ptr	= pointer to key or cursor
 *	is_net	= 1 reads must convert network to host order
 *	returns same as dbtp_get* above
 */

int
dbtp_readDB(DBTPD * dbtp, u_char how, char * name, void * ptr, int is_network)
{
  int ai;
  if ((ai = dbtp_index(dbtp,name)) < 0 )
	 return(DB_NOTFOUND);
  
  return(dbtp_readOne(dbtp,how,ai,ptr,is_network));
}

int
_dbtp_halfput(DBTPD * dbtp, int ai, void * data, size_t size)
{
  dbtp->mgdbt.data = data;
  dbtp->mgdbt.size = (u_int32_t)size;
  return(dbtp->dberr = dbtp->dbaddr[ai]->put(dbtp->dbaddr[ai], NULL, &dbtp->keydbt, &dbtp->mgdbt, 0));
}

int
dbtp_put(DBTPD * dbtp, int ai, void * addr, size_t asize, void * data, size_t dsize)
{
  if (dbtp->dbaddr[ai] == NULL)
  	return(dbtp->dberr = ENODATA);

  if ((dbtp->dberr = _dbtp_set(dbtp,addr,asize)))
  	return(dbtp->dberr);
  return(_dbtp_halfput(dbtp,ai,data,dsize));
}

int
dbtp_sync(DBTPD * dbtp, int ai)
{
  if(dbtp->dbaddr[ai] == NULL)
  	return(dbtp->dberr = ENODATA);

  return(dbtp->dberr = dbtp->dbaddr[ai]->sync(dbtp->dbaddr[ai],0));
}

/* ****************************	*
 *	check for match		*
 * ****************************	*

Returns:
  false if addr is not in the database
  true + stores timestamp if addr
	is present in the database
 */

int
dbtp_find_addr(DBTPD * dbtp, int ai, void * addr, u_int32_t timestamp)
{
  if (dbtp_get(dbtp,ai,addr,sizeof(void *)))	/* size of a pointer	*/
	return(0);

/*  (void)	*/
    dbtp->dberr = _dbtp_halfput(dbtp,ai,&timestamp,sizeof(timestamp));
/*  dbtp->dberr = dbtp->dbaddr[ai]->sync(dbtp->dbaddr[ai],0);	*/
  return(1);
}

int
dbtp_del(DBTPD * dbtp, int ai, void * addr, size_t size)
{
  DBT key;

  if(dbtp->dbaddr[ai] == NULL)
  	return(dbtp->dberr = ENODATA);

  bzero(&key,sizeof(DBT));
  key.data = addr;
  key.size = (u_int32_t)size;
  return(dbtp->dberr = dbtp->dbaddr[ai]->del(dbtp->dbaddr[ai],NULL,&key,0));
}

int
dbtp_notfound()
{
  return(DB_NOTFOUND);
}

char *
dbtp_libversion(int * major, int * minor, int * patch)
{
  extern char versionstring[];
  if (major != NULL)
  	*major = DBTP_MAJOR;
  if (minor != NULL)
  	*minor = DBTP_MINOR;
  if (patch != NULL)
  	*patch = DBTP_PATCH;
  sprintf(versionstring,"dbtarpit library version %d.%d.%d: %s",DBTP_MAJOR,DBTP_MINOR,DBTP_PATCH,DBTP_DATE);
  return(versionstring);
}

char *
dbtp_bdbversion(int * major, int * minor, int * patch)
{
  return(db_version(major,minor,patch));
}

char *
dbtp_strerror(int err)
{
  return(db_strerror(err));
}
