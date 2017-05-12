/*
 * Copyright (c) 1994,
 * The Board of Trustees of the California State University
 * All Rights Reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *	This product includes software developed by the California State
 *	University, and its contributors.
 * 4. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE TRUSTEES AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE TRUSTEES OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

/*
 * Modified by S.M.Pillinger Tue May 20 1997 to allow multiple instances
 * of ldap session to exist.
 */

/************************************************************************
* $Id: dua.c,v 1.16 1994/02/28 23:46:05 ericd Exp $
* dua.c:Perl/LDAP interface routines
************************************************************************/

#ifdef SVR4
#include <string.h>
#else
#include <strings.h>
#endif /* SVR4 */
#include <sys/time.h>
#include "EXTERN.h"

#include "perl.h"

#include "dua.h"
#include <lber.h>
#include <ldap.h>

#if defined (SVR4) || defined (SYSV) || defined (NO_INDEX)
#define index	strchr
#define rindex	strrchr
#endif /* SVR4 || SYSV || NO_INDEX */

/************************************************************************
* EXPORT VARIABLES FROM THIS MODULE
************************************************************************/
/* No Longer needed - S.M.Pillinger
char **dua_pos = (char **) NULL;
char *dua_dn = (char *) NULL;
char *dua_errstr = "";
struct timeval dua_tv;
*/

/************************************************************************
* INTERNAL VARIABLES FOR THIS MODULE
************************************************************************/
/* No Longer needed - S.M.Pillinger
static LDAP *dua_ld;
*/

/************************************************************************
* MODULE ROUTINES
************************************************************************/

/************************************************************************
* dua_settmout
*      Set the timeout value for asynchronous functions.
*
* Side effects: sets dua_tv.dua_tv_sec and dua_tv.tv_usec, global variables.
************************************************************************/
int
dua_settmout (session, sec, usec)
ldap_session_t *session;
long sec;
long usec;
{
  session->dua_tv.tv_sec = sec;
  session->dua_tv.tv_usec = usec;
  
  return 1;
}
 
/************************************************************************
* dua_open
*     Open a connection to the specified DSA.
*
* Side effects: sets dua_errstr.
************************************************************************/
int
dua_open (session, dsa, port, dn, passwd)
ldap_session_t *session;
char *dsa;
int port;
char *dn;
char *passwd;
{
  LDAPMessage *result;
  int id;
  
  if (port == 0)
    port = LDAP_PORT;
  
  if ((session->dua_ld = ldap_open (dsa, port)) == NULL) {
    session->dua_errstr = "Could not open connection to LDAP server";
    return 0;
  }
  
  id = ldap_simple_bind (session->dua_ld, dua_mkdn(session,dn), passwd);
  
  ldap_result (session->dua_ld, id, 1, &session->dua_tv, &result);
  
  if (ldap_result2error (session->dua_ld, result, 1) != LDAP_SUCCESS) {
    set_ldap_err (session,session->dua_ld->ld_errno);
    return 0;
  }
  return 1;
}


/************************************************************************
* dua_modrdn
*      Modify oldrdn to newrdn.
*
* Side effects: none.
************************************************************************/
int
dua_modrdn (session, dn, newrdn)
ldap_session_t *session;
char *dn;
char *newrdn;
{
  int id, retval;
  LDAPMessage *result;
  
  id = ldap_modrdn (session->dua_ld, dua_mkdn(session,dn), newrdn);
  
  retval = 1;
  retval = ldap_result (session->dua_ld, id, 1, &session->dua_tv, &result);
  
  if (ldap_result2error (session->dua_ld, result, 1) != LDAP_SUCCESS) {
    set_ldap_err (session,session->dua_ld->ld_errno);
    retval = 0;
  }
  
  return retval;
}


/************************************************************************
* dua_delete
*     Delete rdn from the DIT.
* 
* Side effects: none.
************************************************************************/
int
dua_delete (session, rdn)
ldap_session_t *session;
char *rdn;
{
  int id, retval;
  LDAPMessage *result;
  
  id = ldap_delete (session->dua_ld, dua_mkdn(session,rdn));
  
  retval = 1;
  retval = ldap_result (session->dua_ld, id, 1, &session->dua_tv, &result);
  
  if (ldap_result2error (session->dua_ld, result, 1) != LDAP_SUCCESS) {
    set_ldap_err (session,session->dua_ld->ld_errno);
    retval = 0;
  }
  
  return retval;
}


/************************************************************************
* dua_close
*      Close the association to the DSA.
*
* Side effects: none.
************************************************************************/
int
dua_close (session)
ldap_session_t *session;
{
  if (ldap_unbind(session->dua_ld) < 0)
    return set_ldap_err (session,session->dua_ld->ld_errno);
  return 1;
}

/************************************************************************
* dua_moveto
*      Move to dn in the DIT.
*
* Side effects: sets `dua_pos'.
************************************************************************/
int
dua_moveto (session,dn)
ldap_session_t *session;
char *dn;
{
  register char **newtemp, **oldtemp;
  char **new;
  u_int new_size;
  
  if (*dn == '@') {
    /* Move to an absolute position in the DIT */
    free_vector (session->dua_pos);
    
    if (strlen (dn) == 1) {
      /* Move to root */
      if ((session->dua_pos = (char **) malloc (sizeof (char **))) == NULL)
	fatal (DUA_ERR_MALLOC);
      *session->dua_pos = NULL;
      return 1;
    }
    
    /* Make a stack by calling dishdn2dn () */
    session->dua_pos = dishdn2dn (dn);
    return 1;
    
  } else {
    /* Move relative to our current position. Create
     * a new stack like above, but append current stack
     * to end by copying the strings.
     */
    new = dishdn2dn (dn);
    
    new_size = 1;
    /* Count number of elements in new */
    for (newtemp = new; *newtemp != NULL; newtemp++)
      new_size++;
    for (newtemp = session->dua_pos; *newtemp != NULL; newtemp++)
      new_size++;
    
    /* Allocate enough space for both arrays, remembering that
     * both currently have a NULL terminator, and the new array
     * will only need one
     */
    if ((new = (char **)realloc(new, (sizeof (char *) *new_size) 
				- sizeof (char *))) == NULL)
      fatal (DUA_ERR_MALLOC);
    
    for (newtemp = new; *newtemp != NULL; newtemp++)
      /* EMPTY */ ;
    for (oldtemp = session->dua_pos; *oldtemp != NULL; oldtemp++) {
      if ((*newtemp = (char *) malloc (strlen (*oldtemp) + 1)) == NULL)
	fatal (DUA_ERR_MALLOC);
      strcpy (*newtemp, *oldtemp);
      newtemp++;
    }
    
    /* NULL terminate the array */
    *newtemp = NULL;
    
    free (session->dua_pos);	/* Don't need this anymore */
    session->dua_pos = new;
    return 1;
  }
}

/************************************************************************
* set_ldap_err
*      Set dua_errstr equal to the current LDAP error.
*
* Side effects: sets the global variable `dua_errstr'.
************************************************************************/
static int
set_ldap_err (session,err)
ldap_session_t *session;
int err;
{
  session->dua_errstr = ldap_err2string (err);
  return 0;
}

/************************************************************************
* dua_quoteme
*      Return non-zero if `value' contains a character which should
*      be quoted from OSI-DS-23 interpretation. Returns zero if the
*      string is otherwise okay.
************************************************************************/
int
dua_quoteme (value)
char *value;
{
  register char *temp;

  for (temp = value; *temp != '\0'; temp++) {
    switch (*temp) {
    case ',':
    case '=':
    case '+':
    case '>':
    case '#':
    case ';':
      return 1;
    }
  }
  return 0;
}

/************************************************************************
* dua_mkdn
*      Convert an @ delimited string to a DN as specified
*      by OSI-DS-23 ``A String Representation of Distinguished Names''
*      by S.E. Hardcastle-Kille.
*
* Side effects: may call fatal ().
************************************************************************/
char *
dua_mkdn (session,dn)
ldap_session_t *session;
char *dn;
{
  char **dncomp;
  char **dncompptr;
  char *temp;
  char *attribute, *value;
  u_int size, asize, vsize;
  int beenhere = 0;
  
  if (session->dua_dn != NULL) {
    /* free any old space alloc'd for dua_dn */
    free (session->dua_dn);
    session->dua_dn = NULL;
  }
  
  if ((*dn == '@' && strlen (dn) == 1) || strlen (dn) == 0)
    return NULL;
  
  dncomp = dishdn2dn (dn);
  size = asize = vsize = 0;
  
 vamp:
  for (dncompptr = dncomp; *dncompptr != NULL; dncompptr++) {
    temp = index (*dncompptr, '=');
    asize = (u_int) (temp - *dncompptr);
    vsize = strlen (temp + 1);
    if ((attribute = (char *) malloc (asize + 1)) == NULL)
      fatal (DUA_ERR_MALLOC);
    if ((value = (char *) malloc (vsize + 1)) == NULL)
      fatal (DUA_ERR_MALLOC);
    strncpy (attribute, *dncompptr, asize);
    attribute [asize] = '\0';
    strcpy (value, temp + 1);
    if (dua_quoteme (value)) {
      size += strlen (*dncompptr) + 3;
      if (session->dua_dn == NULL) {
	if ((session->dua_dn = (char *) malloc (size + 1)) == NULL)
	  fatal (DUA_ERR_MALLOC);
	(void) sprintf (session->dua_dn, "%s=\"%s\"", attribute, value);
      } else {
	if ((session->dua_dn = (char *) realloc (session->dua_dn, 
						 strlen (session->dua_dn)
						 + size)) == NULL)
	  fatal (DUA_ERR_MALLOC);
	(void) sprintf (session->dua_dn, "%s,%s=\"%s\"", 
			session->dua_dn, attribute, value);
      }
    } else {
      size += strlen (*dncompptr) + 1;
      if (session->dua_dn == NULL) {
	if ((session->dua_dn = (char *) malloc (size + 1)) == NULL)
	  fatal (DUA_ERR_MALLOC);
	(void) sprintf (session->dua_dn, "%s=%s", attribute, 
			value);
      } else {
	if ((session->dua_dn = (char *) realloc (session->dua_dn,
						 strlen (session->dua_dn)
						 + size)) == NULL)
	  fatal (DUA_ERR_MALLOC);
	(void) sprintf (session->dua_dn, "%s,%s=%s",
			session->dua_dn, attribute, value);
      }
    }
  }
  
  if (*dn != '@' && !beenhere) {
    beenhere++;
    dncomp = session->dua_pos;
    goto vamp;
  }
  return session->dua_dn;
}


/************************************************************************
* dua_addpair
*      Add an attribute/value pair node the list `atlist'.
*
* Side effects: may call fatal ().
************************************************************************/
void
dua_addpair (atlist, attr, value)
atlist_t **atlist;
char *attr;
char *value;
{
  register atlist_t *temp;
  
  if (*atlist == NULL) {
    /* allocate a new list head */
    if ((*atlist = (atlist_t *) malloc (sizeof (atlist_t))) == NULL)
      fatal (DUA_ERR_MALLOC);
    
    temp = *atlist;
  } else {
    for (temp = *atlist; temp->next != NULL; temp = temp->next)
      /* EMPTY */ ;
    if ((temp->next = (atlist_t *) malloc (sizeof (atlist_t))) == NULL)
      fatal (DUA_ERR_MALLOC);
    temp = temp->next;
  }
  
  temp->attr = strdup (attr);
  temp->value = strdup (value);
  temp->next = NULL;
  
  return;
}


/************************************************************************
* dua_freelist
*      Free memory occupied by `atlist'
*
* Side Effects: none
************************************************************************/
void
dua_freelist (atlist)
atlist_t *atlist;
{
  register atlist_t *temp;

  while (atlist != NULL) {
    temp = atlist->next;
    free (atlist->attr);
    free (atlist->value);
    free (atlist);
    atlist = temp;
  }
  return;
}


/************************************************************************
* dua_add
*      Add the attribute/value pairs in `atlist' to the DIT
*      specified by `rdn'. This code is paralleled (for the
*      most part) in dua_modattr (). 
*      If a significant bug fix is applied to this code, check
*      in dua_modattr () to see if it also needs to be applied there.
*
* Side effects: none
************************************************************************/
int
dua_add (session, rdn, attrs)
ldap_session_t *session;
char *rdn;
atlist_t *attrs;
{
  register atlist_t *temp;
  LDAPMod **mods;
  register int i;
  int id, retval;
  LDAPMessage *result;

  /* start out with enough space for 20 attributes,
   * we'll malloc more when we need it.
   */
  if ((mods = (LDAPMod **) malloc (sizeof (LDAPMod)*20)) == NULL)
    fatal (DUA_ERR_MALLOC);
  
  i = 0;
  for (temp = attrs; temp != NULL; temp = temp->next) {
    /* malloc more pointer space if we're on a 
     * multiple of 20
     */
    if (i % 20 == 0)
      if ((mods = (LDAPMod **) realloc (mods, sizeof (LDAPMod)*20)) == NULL)
	fatal (DUA_ERR_MALLOC);

    /* malloc space for this mod */
    if ((mods[i] = (LDAPMod *) malloc (sizeof (LDAPMod))) == NULL)
      fatal (DUA_ERR_MALLOC);
    
    
    /* initialize all fields to non-garbage values */
    mods[i]->mod_op = LDAP_MOD_ADD;
    mods[i]->mod_next = (LDAPMod *) 0;
    /*
     * this is a pointer assignment only, do not free
     * the space pointed to by temp, as it will be free'd
     * by dua_freelist () by our parent caller.
     */
    mods[i]->mod_type = temp->attr;
    mods[i]->mod_values = split_multi (temp->value);
    
    i++;
  }
  
  /* NULL terminate the end of the mods list */
  mods[i] = (LDAPMod *) 0;
  
  /* initiate the add operation */
  id = ldap_add (session->dua_ld, dua_mkdn(session,rdn), mods);
  
  /* wait for result */
  retval = 1;
  retval = ldap_result (session->dua_ld, id, 0, &session->dua_tv, &result);
  
  /* check result error */
  if (ldap_result2error (session->dua_ld, result, 1) != LDAP_SUCCESS) {
    set_ldap_err (session,session->dua_ld->ld_errno);
    retval = 0;
  }
  
  /* free the memory associated with the mods array */
  for (--i; i > 0; i--) {
    free_vector (mods[i]->mod_values);
    free (mods[i]);
  }
  return retval;
}


/************************************************************************
* dua_modattr
*      Modify the attributes for rdn given in attrs.
*      This code should parallel (for the most part) that
*      in dua_add (). If a significant bug fix is required in
*      in either function, then check the other functions
*      to see if it needs to be changed there.
*
* Side effects: may call fatal ().
************************************************************************/
int 
dua_modattr (session, rdn, attrs)
ldap_session_t *session;
char *rdn;
atlist_t *attrs;
{
  register atlist_t *temp;
  LDAPMod **mods;
  register int i;
  int id, retval;
  LDAPMessage *result;

  /* start out with enough space for 20 attributes,
   * we'll malloc more when we need it.
   */
  if ((mods = (LDAPMod **) malloc (sizeof (LDAPMod)*20)) == NULL)
    fatal (DUA_ERR_MALLOC);

  i = 0;
  for (temp = attrs; temp != NULL; temp = temp->next) {
    /* malloc more pointer space if we're on a 
     * multiple of 20
     */
    if (i % 20 == 0)
      if ((mods = (LDAPMod **) realloc (mods, sizeof (LDAPMod)*20)) == NULL)
	fatal (DUA_ERR_MALLOC);

    /* malloc space for this mod */
    if ((mods[i] = (LDAPMod *) malloc (sizeof (LDAPMod))) == NULL)
      fatal (DUA_ERR_MALLOC);

    /* initialize all fields to non-garbage values */
    mods[i]->mod_next = (LDAPMod *) 0;
    /*
     * this is a pointer assignment only, do not free
     * the space pointed to by temp, as it will be free'd
     * by dua_freelist () by our parent caller.
     */
    mods[i]->mod_type = temp->attr;
    if (*temp->value == '\0')
    {
      mods[i]->mod_op = LDAP_MOD_DELETE;
      mods[i]->mod_values = NULL;
    }
    else
    {
      mods[i]->mod_op = LDAP_MOD_REPLACE;
      mods[i]->mod_values = split_multi (temp->value);
    }
    i++;
  }

  /* NULL terminate the end of the mods list */
  mods[i] = (LDAPMod *) 0;

  /* initiate the add operation */
  id = ldap_modify (session->dua_ld, dua_mkdn(session,rdn), mods);
  
  /* wait for result */
  retval = 1;
  retval = ldap_result (session->dua_ld, id, 0, &session->dua_tv, &result);
  
  /* check result error */
  if (ldap_result2error (session->dua_ld, result, 1) != LDAP_SUCCESS) {
    set_ldap_err (session,session->dua_ld->ld_errno);
    retval = 0;
  }
  
  /* free the memory associated with the mods array */
  for (--i; i > 0; i--) {
    free_vector (mods[i]->mod_values);
    free (mods[i]);
  }
  return retval;
}


/************************************************************************
* ntoa (n)
*      Return a string formed by the integer n.
*
* Side effects: may call fatal ().
************************************************************************/
char *
ntoa (n)
int n;
{
  char *temp;

  if ((temp = (char *) malloc (11)) == NULL) 
    fatal (DUA_ERR_MALLOC);
  
  sprintf (temp, "%d", n);
  return (temp);
}


/************************************************************************
* dua_find
*      dua_find () is used to perform search and list operations 
*      on the DIT. `rdn' is the RDN to fully-qualify and search (list).
*      `filter' is a filter to hand to ldap_search as specified 
*      by the BNF accompanying the LDAP libraries. If `find' is 0,
*      then the operation will be a list operation on the object
*      specified. If `find' is non-zero, the operation will commence
*      as a search of the object's children. If `scope' is 0, then
*      the search operation will be limited to the object's immediate
*      children, if `scope' is non-zero, the search will commence
*      throughout the entire subtree. If `all' is 0 and the operation
*      is a search (`find' > 0), then only the attribute/value pairs
*      of each object found will be returned in the associative array,
*      indexed by the ordinal number in which they were received.
*      'attrs' is the linked-list to return the results in.
************************************************************************/
int
dua_find (session, rdn, filter, scope, find, all, attrs)
ldap_session_t *session;
char *rdn;
char *filter;
int scope;
int find;
int all;
atlist_t **attrs;
{
  int id, retval;
  register int i, num;
  LDAPMessage *result, *entry;
  BerElement *berptr;
  char *attribute;
  char **values;
  char *temp;
  int size;
  
  /* figure out search type */
  if (find)
    scope = scope ? LDAP_SCOPE_SUBTREE : LDAP_SCOPE_ONELEVEL;
  else {
    scope = LDAP_SCOPE_BASE;
    filter = (filter == NULL ? "objectclass=*" : filter);
  }
  
  /* initiate search request */
  id = ldap_search (session->dua_ld, dua_mkdn(session,rdn), scope, 
		    filter, NULL, 0);

  result = entry = NULL;

  /* collect responses */
  i = 0;
  while ((retval = ldap_result (session->dua_ld, id, 1, &session->dua_tv,
				&result)) == 0) {
    i++;
    if (i > DUA_GIVEUP)
      break;
  }

  /* check for error conditions, return to caller if necessary.
   * if no error conditions exist, parse out results.
   */
  if (retval < 0) {
    /* error condition */
    ldap_result2error (session->dua_ld, result, 1);
    set_ldap_err (session,session->dua_ld->ld_errno);
    return 0;
  } else { 
    /* got something, parse it */
    if ((entry = ldap_first_entry (session->dua_ld, result)) == NULL) {
      set_ldap_err (session,session->dua_ld->ld_errno);
      return 0;
    }
    num = 0;
    while (entry != NULL) {
      if (all == 0 && find) {
	attribute = ntoa (num);
	temp = ldap_get_dn (session->dua_ld, entry);
	dua_addpair (attrs, attribute, temp);
	num++;
	free (attribute);
	free (temp);
	entry = ldap_next_entry (session->dua_ld, entry);
	continue;	/* next loop */
      }
      attribute = ldap_first_attribute (session->dua_ld, entry, &berptr);
      while (attribute != NULL) {
	if ((values = ldap_get_values (session->dua_ld, entry, attribute))
	    == NULL) {
	  set_ldap_err (session,session->dua_ld->ld_errno);
	  return 0;
	}
	
	/* calculate the size of the string needed to 
	 * contain all attribute values returned 
	 */
	size = 0;
	for (i = 0; ; i++) {
	  if (values[i] == NULL)
	    break;
	  size += strlen (values[i]);
	}
	/* add space for separators and terminator */
	size += i + 1;
	
	/* allocate our temp area */
	if ((temp = (char *) malloc (size)) == NULL)
	  fatal (DUA_ERR_MALLOC);
	
	for (i = 0; ; i++) {
	  if (i == 0)
	    strcpy (temp, values[0]);
	  else {
	    if (values[i] == NULL)
	      break;
	    else
	      sprintf (temp, "%s&%s",
		       temp, values[i]);
	  }
	}
	
	dua_addpair (attrs, attribute, temp);
		    num++;
	/* free up all memory we no longer need */
	free (temp);
	ldap_value_free (values); 
	attribute = ldap_next_attribute (session->dua_ld, entry, berptr);
      }
      entry = ldap_next_entry (session->dua_ld, entry);
    }
    /* free up memory allocated by ldap routines */
    free (entry);
    free (result);
    return num;
  }
}


/************************************************************************
* split_multi ()
*      Split up multi-valued attribute values into the needed
*      character array vector for the LDAP routines.
*
* Side effects: may call fatal ().
************************************************************************/
char **
split_multi (val)
char *val;
{
  char *vptr, *uptr;
  char **res;
  u_int ssize, len;
  register int i;

  /* Initialize to some heap address, since some systems
   * can't cope with passing NULL to realloc()
   */
  if ((res = (char **) malloc (sizeof (char **))) == NULL)
    fatal (DUA_ERR_MALLOC);
  
  ssize = sizeof (char *) * 2;
  uptr = val;
  for (i = 0; ; i++) {
    if ((vptr = index (uptr, '&')) == NULL) {
      if ((res = (char **) realloc (res, ssize))
	  == NULL) 
	fatal (DUA_ERR_MALLOC);
      if ((res[i] = (char *) malloc (strlen (uptr) + 1))
	  == NULL)
	fatal (DUA_ERR_MALLOC);
      strcpy (res[i], uptr);
      res[i + 1] = NULL;
      
      return (res);
    }
    
    len = (u_int) vptr - (u_int) uptr;
    ssize += sizeof (char *);
    if ((res = (char **) realloc (res, ssize)) == NULL) 
      fatal (DUA_ERR_MALLOC);
    if ((res[i] = (char *) malloc (len + 1)) == NULL)
      fatal (DUA_ERR_MALLOC);
    strncpy (res[i], uptr, len);
    res[i][len] = '\0';
    res[i + 1] = NULL;
    
    uptr = ++vptr;
  }
}


/************************************************************************
* free_vector
*     Releases all memory occupied by a multi-dimensional array
*     of pointers.
************************************************************************/
void
free_vector (vec)
char **vec;
{
  register char **vptr;

  if (vec != NULL) {
    for (vptr = vec; *vptr != NULL; vptr++) {
      free (*vptr);
    }
    
    free (vec);
  }
  
  return;
}

/************************************************************************
* dishdn2dn
*    Convert a DISH style DN to an OSI-DS-23 DN, returning the
*    later in a multi-dimensional character array.
*
* Side effects: may call fatal ().
************************************************************************/
char **
dishdn2dn (dn)
char *dn;
{
  char *tempdn, *newdn;
  char **result;
  int rev, done;
  u_int size, res_size;
  
  /* malloc space for at least one element */
  if ((result = (char **) malloc (sizeof (char *) * 2)) == NULL)
    fatal (DUA_ERR_MALLOC);
  res_size = 1;
  
  /* Check for NULL or empty DN and return */
  if (dn == NULL || (*dn == '@' && strlen (dn) == 1)) {
    *result = NULL;
    return result;
  }
  
  /* adjust DN appropriately */
  if ((newdn = (char *) malloc (strlen (dn) + 1)) == NULL)
    fatal (DUA_ERR_MALLOC);
  
  if (*dn == '@') 
    strcpy (newdn, dn + 1);
  else
    strcpy (newdn, dn);
  
  
  done = 0;
  for (rev = 0;; rev++) {
    if ((tempdn = rindex (newdn, '@')) == NULL) {
      tempdn = newdn;
      done++;
    }
    else {
      *tempdn = '\0';
      tempdn++;
    }
    size = strlen (tempdn);
    
    if ((result = (char **) realloc (result,
				     sizeof (char *) * ++res_size)) == NULL)
      fatal (DUA_ERR_MALLOC);	

    if ((result [rev] = (char *) malloc (size + 1)) == NULL)
      fatal (DUA_ERR_MALLOC);
    strcpy (result [rev], tempdn);
    result [rev + 1] = NULL;
    
    if (done)
      return result;
  }
}
