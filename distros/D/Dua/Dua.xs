#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "dua.h"

MODULE = Dua PACKAGE = Dua

PROTOTYPES: ENABLE

ldap_session_t *
dua_create()
CODE:
     /* initialize initial "position" in the DIT 
     /* any call requiring a DN will start from the ROOT until
      * the user calls dua_moveto.
      */
     ldap_session_t *session;
     if ((session = (ldap_session_t *)malloc(sizeof(ldap_session_t))) == NULL)
         fatal (DUA_ERR_MALLOC);

    session->dua_pos = NULL;
    if ((session->dua_pos = (char **)malloc(sizeof(char **))) == NULL) {
      free(session);
      fatal (DUA_ERR_MALLOC);
    }

     *session->dua_pos = NULL;
     session->dua_dn = NULL;
     session->dua_errstr = "";

     /* initialize default values for asynchronous timeout */
     dua_settmout(session,30L,0L);
     RETVAL = session;
OUTPUT:
     RETVAL

void
dua_free(session)
ldap_session_t *session
CODE:
    if (session != NULL) {
       if (session->dua_pos != NULL)
           free(session->dua_pos);
	free(session);	
    }    

char *
dua_errstr(session)
ldap_session_t *session
CODE:
   RETVAL = session->dua_errstr;
OUTPUT:
   RETVAL

int
dua_settmout (session, sec, usec)
ldap_session_t *session
long sec
long usec
 
int
dua_open (session, dsa, port, dn, passwd)
ldap_session_t *session
char *dsa
int port
char *dn
char *passwd


int
dua_modrdn (session, dn, newrdn)
ldap_session_t *session
char *dn
char *newrdn

int
dua_delete (session, rdn)
ldap_session_t *session
char *rdn

int
dua_close (session)
ldap_session_t *session

int
dua_moveto (session, dn)
ldap_session_t *session
char *dn

int 
dua_add (session, rdn, ...)
ldap_session_t *session
char *rdn
CODE:
{
  atlist_t *atlist;
  register int i;

  if ((items - 2) % 2 != 0)
  {
    croak ("Number of attribute/value pairs must be even");
  }
  atlist = NULL;
  for(i=2;i<items;(i++,i++))
    dua_addpair(&atlist,(char *)SvPV(ST(i), na),(char *)SvPV(ST(i+1), na));
  RETVAL = dua_add (session, rdn, atlist);
  dua_freelist (atlist);
}
OUTPUT:
  RETVAL

int 
dua_modattr (session, rdn, ...)
ldap_session_t *session
char *rdn
CODE:
{
  atlist_t *atlist;
  register int i;
  if ((items - 2) % 2 != 0) 
  {
    croak ("Number of attribute/value pairs must be even");
  }
  atlist = NULL;
  for(i=2;i<items;(i++,i++))
    dua_addpair(&atlist,(char *)SvPV(ST(i), na),(char *)SvPV(ST(i+1), na));
  RETVAL = dua_modattr (session, rdn, atlist);
  dua_freelist (atlist);
}
OUTPUT:
  RETVAL

int 
dua_delattr (session, rdn, ...)
ldap_session_t *session
char *rdn
CODE:
{
  atlist_t *atlist;
  register int i;

  atlist = NULL;
  for(i=2;i<items;i++)
    dua_addpair(&atlist,(char *)SvPV(ST(i), na),"\0");
  RETVAL = dua_delattr (session, rdn, atlist);
  dua_freelist (atlist);
}
OUTPUT:
  RETVAL

void
dua_find (session, rdn, filter, scope, all)
ldap_session_t *session
char *rdn
char *filter
int scope
int all
PREINIT:
  atlist_t *	atlist;
  register atlist_t *temp;
PPCODE:
  atlist = (atlist_t *) 0;
  dua_find(session,rdn,filter,scope,1,all,&atlist);
  temp = atlist;
  while (temp != NULL) 
  {
    XPUSHs(sv_2mortal(newSVpv(temp->attr,0)));
    XPUSHs(sv_2mortal(newSVpv(temp->value,0)));
    temp = temp->next;
  }
  dua_freelist (atlist);


void
dua_show (session,rdn)
ldap_session_t *session
char *rdn
PREINIT:
  atlist_t *	atlist;
  register atlist_t *temp;
PPCODE:
  atlist = (atlist_t *) 0;
  dua_find(session,rdn,NULL,0,0,0,&atlist);
  temp = atlist;
  while (temp != NULL) 
  {
    XPUSHs(sv_2mortal(newSVpv(temp->attr,0)));
    XPUSHs(sv_2mortal(newSVpv(temp->value,0)));
    temp = temp->next;
  }
  dua_freelist (atlist);

void
dua_attribute (session,rdn,attr)
ldap_session_t *session
char *rdn
char *attr
PREINIT:
  int scope = LDAP_SCOPE_BASE;
  char *filter = "objectclass=*";
  char attrsonly = 0;
  char *attrs[2];

  struct berval **values;
  char **attribute;
  LDAPMessage *result, *entry;
  int i;
PPCODE:

  attrs[0] = attr;
  attrs[1] = NULL;
  if (ldap_search_s(session->dua_ld,rdn,scope,filter,attrs,attrsonly,&result)
      != LDAP_SUCCESS) {
      ldap_perror(session->dua_ld,"ldap_search_s");
      return;
  }

  if (ldap_count_entries(session->dua_ld,result) != 1) {
    session->dua_errstr = "More than one entry returned";
    return;
  }

  if ((entry = ldap_first_entry(session->dua_ld,result)) == NULL) {
    session->dua_errstr = ldap_err2string(session->dua_ld->ld_errno);
    return;
  }

  attribute = attrs;
  while(*attribute) {
    values = ldap_get_values_len(session->dua_ld,entry,*attribute);
    for(i = 0; i < ldap_count_values_len(values); i++) {
      XPUSHs(sv_2mortal(newSVpv(values[i]->bv_val,values[i]->bv_len)));
    }
    ldap_value_free_len (values);
    attribute++;
  }
