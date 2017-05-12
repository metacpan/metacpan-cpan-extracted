
/************************************************************************
* dua.h: Common definitions for DUAP
************************************************************************/

#ifndef _DUA_H
#define _DUA_H

/****
	added by S.M.Pillinger
 ****/

#define fatal croak

/************************************************************************
* GLOBAL TYPE DECLARATIONS
************************************************************************/
#include <sys/time.h>
#include <lber.h>
#include <ldap.h>

typedef struct ldap_session {
  char **dua_pos;
  char *dua_dn;
  char *dua_errstr;
  struct timeval dua_tv;
  LDAP *dua_ld;
} ldap_session_t;

typedef struct atlist {
     char *attr;
     char *value;
     struct atlist *next;
} atlist_t;

#ifndef POSIX
char *strdup();
#endif /* not POSIX */

/************************************************************************
* GLOBAL DEFINES
************************************************************************/
#ifndef DUA_GIVEUP
#define DUA_GIVEUP 3		/* no. of rev's to make on ret. values */
#endif /* DUA_GIVEUP */

#ifndef u_int
#define u_int	unsigned int
#define u_long	unsigned long
#endif /* u_int */

#define DUA_ERR_MALLOC	"Couldn't allocate some critical memory."

/************************************************************************
* FUNCTION TYPES
************************************************************************/
int dua_settmout (ldap_session_t *, long, long);
int dua_open (ldap_session_t *, char *, int, char *, char *);
int dua_modrdn (ldap_session_t *, char *, char *);
int dua_delete (ldap_session_t *, char *);
int dua_close (ldap_session_t *);
int dua_moveto (ldap_session_t *,char *);
static int set_ldap_err (ldap_session_t *,int);
int dua_quoteme (char *);
char * dua_mkdn (ldap_session_t *, char *);
void dua_addpair (atlist_t **, char *, char *);
void dua_freelist (atlist_t *);
int dua_add (ldap_session_t *, char * ,atlist_t *);
int dua_modattr (ldap_session_t *, char *, atlist_t *);
int dua_delattr (ldap_session_t *, char *, atlist_t *);
char * ntoa (int);
int dua_find (ldap_session_t *, char *, char *, int, int, int, atlist_t **);
char ** split_multi (char *);
void free_vector (char **);
char ** dishdn2dn (char *);
/* smp - Old Perl4 stuff
int init_duaperl(); 
static int usersub();
static int userset ();
static int userval ();
*/
#endif /* _DUA_H */
