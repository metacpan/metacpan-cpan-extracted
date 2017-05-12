/*
 * Copyright (c) 2003, Stockholms Universitet
 * (Stockholm University, Stockholm Sweden)
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the university nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <sys/un.h>
#include <krb5.h>
#include <kadm5/admin.h>
#include <kadm5/kadm5_err.h>

#include "consts.h"

typedef struct shandle_t {
  int modcount;
  void *ptr;
  kadm5_config_params params;
  krb5_context context;
} shandle_t;

typedef struct sprincipal_t {
  shandle_t               *handle;
  int                      mask;
  kadm5_principal_ent_rec  principal;
} sprincipal_t;

static sprincipal_t *
create_sprincipal(shandle_t *handle)
{
  sprincipal_t *p = (sprincipal_t *)safemalloc(sizeof(sprincipal_t));
  
  memset(p,0,sizeof(*p));
  p->handle = handle;
  return p;
}

static void
destroy_sprincipal(sprincipal_t *spp)
{
  kadm5_free_principal_ent(spp->handle,&spp->principal);
  safefree(spp);
}

static shandle_t *
sv2server_handle(SV *sv)
{
  if (SvROK(sv) && sv_isa(sv,"Heimdal::Kadm5::SHandle"))
    return (shandle_t *)SvIV(SvRV(sv));
  else
    croak("Argument to sv2server_handle not referenced in package \"Heimdal::Kadm5::SHandle\"");
}

static sprincipal_t *
sv2sprincipal(SV *sv)
{
  if (SvROK(sv) && sv_isa(sv,"Heimdal::Kadm5::Principal"))
    return (sprincipal_t *)SvIV(SvRV(sv));
  else
    croak("Argument to sv2kadm5_principal not referenced in package \"Heimdal::Kadm5::Principal\"");
}

static int
set_param_strval(HV *hv, char **str, char *key)
{
  SV **val = hv_fetch(hv, key, strlen(key), 0);
  //fprintf(stderr,"%s=\"%s\"\n",key,val != NULL ? SvPV_nolen(*val):"(null)");
  if (val != NULL)
    {
       *str = SvPV_nolen(*val);
       return 1;
     }
  return 0;
}

static int
set_param_intval(HV *hv, int *ival, char *key)
{
  SV **val = hv_fetch(hv, key, 0, 0);
  if (val)
    {
      *ival = (int)SvIV(*val);
      return 1;
    }
  return 0;
}

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}


struct kadm_func {
    kadm5_ret_t (*chpass_principal) (void *, krb5_principal, char*);
    kadm5_ret_t (*create_principal) (void*, kadm5_principal_ent_t, 
                                     u_int32_t, char*);
    kadm5_ret_t (*delete_principal) (void*, krb5_principal);
    kadm5_ret_t (*destroy) (void*);
    kadm5_ret_t (*flush) (void*);
    kadm5_ret_t (*get_principal) (void*, krb5_principal, 
                                  kadm5_principal_ent_t, u_int32_t);
    kadm5_ret_t (*get_principals) (void*, const char*, char***, int*);
    kadm5_ret_t (*get_privs) (void*, u_int32_t*);
    kadm5_ret_t (*modify_principal) (void*, kadm5_principal_ent_t, u_int32_t);
    kadm5_ret_t (*randkey_principal) (void*, krb5_principal, 
                                      krb5_keyblock**, int*);
    kadm5_ret_t (*rename_principal) (void*, krb5_principal, krb5_principal);
    kadm5_ret_t (*chpass_principal_with_key) (void *, krb5_principal,
                                              int, krb5_key_data *);
};

typedef struct kadm5_client_context {
    krb5_context context;
    krb5_boolean my_context;
    struct kadm_func funcs;
    /* */
    krb5_auth_context ac;
    char *realm;
    char *admin_server;
    int kadmind_port;
    int sock;
    char *client_name;
    char *service_name;
    krb5_prompter_fct prompter;
    const char *keytab;
    krb5_ccache ccache;
    kadm5_config_params *realm_params;
}kadm5_client_context;



MODULE = Heimdal::Kadm5::SHandle		PACKAGE = Heimdal::Kadm5::SHandle		PREFIX=kadm5_
PROTOTYPES: ENABLE

shandle_t *
new(self,sv)
     SV *self
     SV *sv
     CODE:
     {
       if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVHV)
       {
	 HV *hv = (HV *)SvRV(sv);
	 shandle_t *handle = (shandle_t *)safemalloc(sizeof(shandle_t));
	 kadm5_ret_t ret;
	 
	 memset(handle,0,sizeof(*handle));
	 ret = krb5_init_context(&handle->context);
	 if (ret)
	 {
	   safefree(handle);
	   croak("[Heimdal::Kadm5] krb5_init_context failed: %s\n",krb5_get_err_text(handle->context, ret));
	   handle = NULL;
	   goto cleanup;
	 }
 	
	 if (set_param_strval(hv,&handle->params.realm,"Realm"))
	 {
           /* fprintf(stderr,"Realm=\"%s\"\n",handle->params.realm); */
	   krb5_set_default_realm(handle->context, handle->params.realm);
	   handle->params.mask |= KADM5_CONFIG_REALM;
	 }
	 /* set_param_strval(hv,&handle->params.profile,"Profile"); */
	 if (set_param_intval(hv,&handle->params.kadmind_port,"Port"))
       	    handle->params.mask |= KADM5_CONFIG_KADMIND_PORT;
	 if (set_param_strval(hv,&handle->params.admin_server,"Server"))
	    handle->params.mask |= KADM5_CONFIG_ADMIN_SERVER;
	 
	 cleanup:
	 RETVAL = handle;
       }
       else
       {
         croak("[Heimdal::Kadm5] Argument to \"Heimdal::Kadm5::SHandle::new\" must be a hash-reference");
	 RETVAL = NULL;
       }
     }
     OUTPUT:
          RETVAL

void
DESTROY(handle)
     shandle_t *handle
     CODE:
     {
       if (handle->modcount > 0)
	 {
	   kadm5_c_flush(handle->ptr);
	 }
       if (handle->ptr)
          kadm5_c_destroy(handle->ptr);
       if (handle->context)
          krb5_free_context(handle->context);
       safefree(handle);
     }

void
kadm5_c_init_with_password (handle, client_name, password, service_name, struct_version, api_version)
     shandle_t *handle
     char *client_name
     char *password
     char *service_name
     unsigned long struct_version
     unsigned long api_version
     CODE:
     {
       kadm5_ret_t ret = kadm5_c_init_with_password_ctx(handle->context,
							client_name,
							password,
							KADM5_ADMIN_SERVICE, 
							&handle->params,
							struct_version, 
							api_version,
							&handle->ptr);
       if(ret)
	    croak("[Heimdal::Kadm5] kadm5_c_init_with_password_ctx failed: %s\n",
		  krb5_get_err_text(handle->context, ret));

       if (password != NULL && *password != '\0')
           ((kadm5_client_context *)handle->ptr)->prompter = NULL;
     }

void
kadm5_c_init_with_skey (handle, client_name, keytab, service_name, struct_version, api_version)
     shandle_t *handle
     char *client_name
     char *keytab
     char *service_name
     unsigned long struct_version
     unsigned long api_version
     CODE:
     {
       kadm5_ret_t ret = kadm5_c_init_with_skey_ctx(handle->context,
						    client_name,
						    keytab,
						    KADM5_ADMIN_SERVICE, 
						    &handle->params,
						    struct_version, 
						    api_version,
						    &handle->ptr);
       if(ret)
	    croak("[Heimdal::Kadm5] kadm5_c_init_with_skey_ctx failed: %s\n",
		  krb5_get_err_text(handle->context, ret));
     }

void
kadm5_c_flush(handle)
     shandle_t *handle
     CODE:
     {
       kadm5_ret_t ret = kadm5_c_flush(handle->ptr);
       if (ret)
	 croak("[Heimdal::Kadm5] kadm5_c_flush failed: %s\n",krb5_get_err_text(handle->context, ret));
       handle->modcount = 0;
     }

void
kadm5_c_modify_principal(handle,spp,mask)
     shandle_t     *handle
     sprincipal_t  *spp
     int            mask
     CODE:
     {
       kadm5_ret_t ret;

       if (mask == 0)
	 mask = spp->mask;
       ret = kadm5_c_modify_principal(handle->ptr, &spp->principal, mask);
       if (ret)
	 {
	   if (ret)
	     croak("[Heimdal::Kadm5] kadm5_c_modify_principal failed: %s\n",
		   krb5_get_err_text(handle->context, ret));
	 }
       handle->modcount++;
     }

int
kadm5_c_randkey_principal(handle,name)
     shandle_t    *handle
     char         *name
     CODE:
     {
       krb5_keyblock *new_keys;
       int n_keys, i;
       krb5_principal principal;
       krb5_error_code err;
       kadm5_ret_t ret;

       err = krb5_parse_name(handle->context, name, &principal);
       if (err)
	 croak("[Heimdal::Kadm5] krb5_parse_name failed on \"%s\": %s\n",
	       name,krb5_get_err_text(handle->context, err));
       
       ret = kadm5_randkey_principal(handle->ptr, principal, &new_keys, &n_keys);
       if(ret)
	 {
	   krb5_free_principal(handle->context, principal);
	   croak("[Heimdal::Kadm5] kadm5_c_randkey_principal failed: %s\n",
		 krb5_get_err_text(handle->context, ret));
	 }
       for(i = 0; i < n_keys; i++)
	 krb5_free_keyblock_contents(handle->context, &new_keys[i]);
       free(new_keys);
       krb5_free_principal(handle->context, principal);
       handle->modcount++;
       RETVAL = n_keys;
     }
     OUTPUT:
     RETVAL

void
kadm5_c_chpass_principal(handle,name,password)
     shandle_t   *handle
     char        *name
     char        *password
     CODE:
     {
       kadm5_ret_t ret;
       krb5_error_code ret2;
       krb5_principal principal;
       
       ret2 = krb5_parse_name(handle->context, name, &principal);
       if (ret2)
	 croak("[Heimdal::Kadm5] krb5_parse_name failed on \"%s\": %s\n",
	       name,krb5_get_err_text(handle->context, ret2));
       
       ret = kadm5_c_chpass_principal(handle->ptr,principal,password);
       if (ret)
	 croak("[Heimdal::Kadm5] kadm5_c_chpass_principal failed on \"%s\": %s\n",
	       name,krb5_get_err_text(handle->context, ret));
       handle->modcount++;
     }

void
kadm5_c_create_principal(handle,spp,password,mask)
     shandle_t    *handle
     sprincipal_t *spp
     char         *password
     int           mask
     CODE:
     {
       kadm5_ret_t ret;

       if (mask == 0)
	 mask = spp->mask;
       
       ret = kadm5_c_create_principal(handle->ptr,&spp->principal,mask,password);
       if (ret)
	 {
	   char *p;
	   krb5_error_code ret2;
	   
	   ret2 = krb5_unparse_name(handle->context,spp->principal.principal,&p);
	   if (ret2)
	     {
	       safefree(p);
	       croak("[Heimdal::Kadm5] krb5_unparse_name failed: %s\n",
		     krb5_get_err_text(spp->handle->context, ret2));
	     }
	   croak("[Heimdal::Kadm5] krb5_c_create_principal failed on \"%s\": %s\n",
		 p,krb5_get_err_text(handle->context, ret));
	 }
       handle->modcount++;
     }

void
kadm5_c_rename_principal(handle, src, trg)
     shandle_t   *handle
     char        *src
     char        *trg
     CODE:
     {
       krb5_error_code ret;
       krb5_principal source, target;
       kadm5_ret_t err;

       ret = krb5_parse_name(handle->context, src, &source);
       if (ret)
	 {
	   croak("[Heimdal::Kadm5] krb5_parse_name failed on \"%s\": %s\n",
		 src,krb5_get_err_text(handle->context, ret));
	 }
       
       ret = krb5_parse_name(handle->context, trg, &target);
       if (ret)
	 {
	   krb5_free_principal(handle->context, target);
	   croak("[Heimdal::Kadm5] krb5_parse_name failed on \"%s\": %s\n",
		 trg,krb5_get_err_text(handle->context, ret));
	 }
       
       err = kadm5_c_rename_principal(handle->ptr, source, target);
       if (err)
	 {
	   krb5_free_principal(handle->context, source);
	   krb5_free_principal(handle->context, target);
	   croak("[Heimdal::Kadm5] kadm5_rename_principal \"%s\" to \"%s\" failed: %s\n",
		 src,trg,krb5_get_err_text(handle->context, err));
	 }
       krb5_free_principal(handle->context, source);
       krb5_free_principal(handle->context, target);
       handle->modcount++;
     }

void
kadm5_c_delete_principal(handle,name)
     shandle_t   *handle
     char        *name
     CODE:
     {
       krb5_error_code ret;
       krb5_principal principal;
       kadm5_ret_t err;
       
       ret = krb5_parse_name(handle->context, name, &principal);
       if (ret)
	 croak("[Heimdal::Kadm5] krb5_parse_name failed on \"%s\": %s\n",
	       name,krb5_get_err_text(handle->context, ret));
       
       err = kadm5_c_delete_principal(handle->ptr,principal);
       if (err)
	 {
	   krb5_free_principal(handle->context, principal);
	   croak("[Heimdal::Kadm5] kadm5_c_delete_principal failed for \"%s\": %s\n",
		 name,krb5_get_err_text(handle->context, err));
	 }
       handle->modcount++;
       krb5_free_principal(handle->context, principal);
     }


sprincipal_t *
kadm5_c_get_principal(handle, name, mask)
     shandle_t *handle
     char      *name
     IV         mask
     CODE:
     {
       krb5_principal principal;
       krb5_error_code ret;
       sprincipal_t *spp;
       
       ret = krb5_parse_name(handle->context, name, &principal);
       if (ret)
	 croak("[Heimdal::Kadm5] krb5_parse_name failed on \"%s\": %s\n",
	       name,krb5_get_err_text(handle->context, ret));
       
       spp = create_sprincipal(handle);
       ret = kadm5_c_get_principal(handle->ptr,
				   principal,
				   &spp->principal,
				   mask);
       if (ret)
	 {
           if (ret == KADM5_UNK_PRINC) {
              destroy_sprincipal(spp); 
              spp = NULL;
           } else {
	      krb5_free_principal(handle->context, principal);
              destroy_sprincipal(spp); 
	      croak("[Heimdal::Kadm5] kadm5_c_get_principal failed for \"%s\": %s\n",
		    name,krb5_get_err_text(handle->context, ret));
           }
	 }
       krb5_free_principal(handle->context,principal);
       RETVAL = spp;
     }
     OUTPUT:
     RETVAL

void
kadm5_c_get_principals(handle,exp)
     shandle_t *handle
     char      *exp
     PPCODE:
     {
       char **princs;
       int num_princs,i;
       kadm5_ret_t ret;

       ret = kadm5_c_get_principals(handle->ptr,exp,&princs,&num_princs);
       if (ret)
	 {
	   croak("[Heimdal::Kadm5] kadm5_c_get_principals failed for \"%s\": %s\n",
		 exp,krb5_get_err_text(handle->context, ret));
	 }
       EXTEND(SP,num_princs);
       for (i = 0; i < num_princs; i++)
	 {
	   PUSHs(sv_2mortal(newSVpv(princs[i],0)));
	 }
       kadm5_free_name_list(handle->ptr,princs,&num_princs);
     }

int
kadm5_c_get_privs(handle)
     shandle_t *handle
     CODE:
     {
       int privs;
       kadm5_ret_t ret = kadm5_c_get_privs(handle->ptr,&privs);
       if (ret)
	 {
	   croak("[Heimdal::Kadm5] kadm5_c_get_privs failed: %s\n",
		 krb5_get_err_text(handle->context, ret));
	 }
       RETVAL = privs;
     }
     OUTPUT:
     RETVAL

void
kadm5_c_ext_keytab(handle,spp,keytab)
     shandle_t   *handle
     sprincipal_t *spp
     char        *keytab
     CODE:
     {
       int i;
       krb5_keytab kt;
       krb5_error_code ret;
       
       if(keytab)
	 ret = krb5_kt_resolve(handle->context, keytab, &kt);
       else
	 ret = krb5_kt_default(handle->context, &kt);
       
       if (ret)
	 croak("[Heimdal::Kadm5] krb5_kt_resolv failed: %s\n",
	       krb5_get_err_text(handle->context, ret));
       
       for(i = 0; i < spp->principal.n_key_data; i++)
	 {
	   krb5_keytab_entry key;
	   krb5_key_data *k = &spp->principal.key_data[i];
	   
	   key.principal = spp->principal.principal;
	   key.vno = k->key_data_kvno;
	   key.keyblock.keytype = k->key_data_type[0];
	   key.keyblock.keyvalue.length = k->key_data_length[0];
	   key.keyblock.keyvalue.data = k->key_data_contents[0];
	   ret = krb5_kt_add_entry(handle->context, kt, &key);
	   if (ret)
	     croak("[Heimdal::Kadm5] krb5_kt_add_entry failed: %s\n",
		   krb5_get_err_text(handle->context, ret));
	 }
       
       krb5_kt_close(handle->context, kt);
     }

MODULE = Heimdal::Kadm5::Principal         PACKAGE = Heimdal::Kadm5::Principal

sprincipal_t *
new(self,handle)
     SV *self
     shandle_t *handle
     CODE: 
     {
       sprincipal_t *spp = create_sprincipal(handle);
       RETVAL = spp;
     }
     OUTPUT:
     RETVAL

void
DESTROY(spp)
     sprincipal_t *spp
     CODE:
     {
       destroy_sprincipal(spp);
     }

SV *
getPrincipal(spp)
     sprincipal_t *spp
     CODE:
     {
       char *p;
       krb5_error_code ret;
       
       ret = krb5_unparse_name(spp->handle->context,spp->principal.principal,&p);
       if (ret)
	 {
	   safefree(p);
	   croak("[Heimdal::Kadm5] krb5_unparse_name failed: %s\n",
		 krb5_get_err_text(spp->handle->context, ret));
	 }
       RETVAL = newSVpv(p,0);
     }
     OUTPUT:
     RETVAL

void
setPrincipal(spp,p)
     sprincipal_t *spp
     char         *p
     CODE:
     {
       krb5_error_code ret;
       
       ret = krb5_parse_name(spp->handle->context,p,&spp->principal.principal);
       if (ret)
	 {
	   croak("[Heimdal::Kadm5] krb5_parse_name failed for \"%s\": %s\n",
		 p,krb5_get_err_text(spp->handle->context, ret));
	 }
       spp->mask |= KADM5_PRINCIPAL;
     }

int
getPrincExpireTime(spp)
     sprincipal_t *spp
     PPCODE:
     {
       XPUSHi(spp->principal.princ_expire_time);
     }

void
setPrincExpireTime(spp,val)
     sprincipal_t *spp
     IV            val
     CODE:
     {
       spp->principal.princ_expire_time = val;
       spp->mask |= KADM5_PRINC_EXPIRE_TIME;
     }

IV
getLastPwdChange(spp)
     sprincipal_t *spp
     CODE:
     {
       RETVAL = spp->principal.last_pwd_change;
     }
     OUTPUT:
     RETVAL

IV
getKvno(spp)
     sprincipal_t *spp
     CODE:
     {
       RETVAL = spp->principal.kvno;
     }
     OUTPUT:
     RETVAL

IV
getMKvno(spp)
     sprincipal_t *spp
     CODE:
     {
       RETVAL = spp->principal.mkvno;
     }
     OUTPUT:
     RETVAL

IV
getPwExpiration(spp)
     sprincipal_t *spp
     CODE:
     {
       RETVAL = spp->principal.pw_expiration;
     }
     OUTPUT:
     RETVAL

void
setPwExpiration(spp,val)
     sprincipal_t *spp
     IV            val
     CODE:
     {
       spp->principal.pw_expiration = val;
       spp->mask |= KADM5_PW_EXPIRATION;
     }

IV
getMaxLife(spp)
     sprincipal_t *spp
     CODE:
     {
       RETVAL = spp->principal.max_life;
     }
     OUTPUT:
     RETVAL

void
setMaxLife(spp,val)
     sprincipal_t *spp
     IV            val
     CODE:
     {
       spp->principal.max_life = val;
       spp->mask |= KADM5_MAX_LIFE;
     }

SV *
getModName(spp)
     sprincipal_t *spp
     CODE:
     {
       char *p;
       krb5_error_code ret;
       
       ret = krb5_unparse_name(spp->handle->context,spp->principal.mod_name,&p);
       if (ret)
	 {
	   safefree(p);
	   croak("[Heimdal::Kadm5] krb5_unparse_name failed: %s\n",
		 krb5_get_err_text(spp->handle->context, ret));
	 }
       RETVAL = newSVpv(p,0);
     }
     OUTPUT:
     RETVAL

IV
getModDate(spp)
     sprincipal_t *spp
     CODE:
     {
       RETVAL = spp->principal.mod_date;
     }
     OUTPUT:
     RETVAL

SV *
getPolicy(spp)
     sprincipal_t *spp
     CODE:
     {
       if (spp->principal.policy)
	 RETVAL = newSVpv(spp->principal.policy,0);
       else
	 RETVAL = &PL_sv_undef;
     }
     OUTPUT:
     RETVAL

IV
getMaxRenewableLife(spp)
     sprincipal_t *spp
     CODE:
     {
       RETVAL = spp->principal.max_renewable_life;
     }
     OUTPUT:
     RETVAL

void
setMaxRenewableLife(spp,val)
     sprincipal_t *spp
     IV            val
     CODE:
     {
       spp->principal.max_renewable_life = val;
       spp->mask |= KADM5_MAX_RLIFE;
     }

IV
getLastSuccess(spp)
     sprincipal_t *spp
     CODE:
     {
       RETVAL = spp->principal.last_success;
     }
     OUTPUT:
     RETVAL

IV
getLastFailed(spp)
     sprincipal_t *spp
     CODE:
     {
       RETVAL = spp->principal.last_failed;
     }
     OUTPUT:
     RETVAL

IV
getFailAuthCount(spp)
     sprincipal_t *spp
     CODE:
     {
       RETVAL = spp->principal.fail_auth_count;
     }
     OUTPUT:
     RETVAL

IV
getFailAuthCounts(spp)
     sprincipal_t *spp
     CODE:
     {
       RETVAL = spp->principal.fail_auth_count;
     }
     OUTPUT:
     RETVAL

IV
getAttributes(spp)
     sprincipal_t *spp
     CODE:
     {
       RETVAL = spp->principal.attributes;
     }
     OUTPUT:
     RETVAL

void
setAttributes(spp,val)
     sprincipal_t *spp
     IV            val
     CODE:
     {
       spp->principal.attributes = val;
       spp->mask |= KADM5_ATTRIBUTES;
     }

SV *
getKeytypes(spp)
     sprincipal_t *spp
     CODE:
     {
       int i;
       AV *lst = newAV();
       
       for (i = 0; i < spp->principal.n_key_data; ++i) 
	 {
	   krb5_key_data *k = &spp->principal.key_data[i];
	   krb5_error_code ret;
	   char *e_string, *s_string;
	   SV *ksv[2];
	   
	   ret = krb5_enctype_to_string (spp->handle->context,
					 k->key_data_type[0],
					 &e_string);
	   if (ret)
	     asprintf (&e_string, "unknown(%d)", k->key_data_type[0]);
	   ksv[0] = newSVpv(e_string,0);
	   
	   ret = krb5_salttype_to_string (spp->handle->context,
					  k->key_data_type[0],
					  k->key_data_type[1],
					  &s_string);
	   if (ret)
	     asprintf (&s_string, "unknown(%d)", k->key_data_type[1]);
	   ksv[1] = newSVpv(s_string,0);
	   
	   av_push(lst,newRV_inc((SV *)av_make(2,ksv)));
	   free (e_string);
	   free (s_string);
	 }
       RETVAL = newRV_inc((SV *)lst);
     }
     OUTPUT:
     RETVAL

void
delKeytypes(spp,enctype)
     sprincipal_t *spp
     char *enctype
     CODE:
     {
       krb5_key_data *new_key_data = malloc(spp->principal.n_key_data * sizeof(*new_key_data));
       krb5_enctype *etypes        = malloc(sizeof(*etypes));
       int i, j;

       krb5_string_to_enctype(spp->handle->context, enctype, etypes);

       for (i = 0, j = 0; i < spp->principal.n_key_data; ++i) {
           krb5_key_data *key = &spp->principal.key_data[i];

           if (*etypes == key->key_data_type[0]) {
               int16_t ignore = 1;
               kadm5_free_key_data (spp->handle, &ignore, key);
           } else {
               new_key_data[j++] = *key;
           }
       }

       free (spp->principal.key_data);
       spp->principal.n_key_data = j;
       spp->principal.key_data   = new_key_data;

       spp->mask |= KADM5_KEY_DATA;
       spp->handle->modcount++;

     }


SV *
getPassword(spp)
     sprincipal_t *spp
     CODE:
     {
#ifdef KRB5_TL_PASSWORD
       krb5_tl_data *tl = spp->principal.tl_data;

       while (tl != NULL)
         {
	   if (tl->tl_data_type == KRB5_TL_PASSWORD)
	     break;
	   tl = tl->tl_data_next;
         }

       if (tl)
	 RETVAL = newSVpv(tl->tl_data_contents,0);
       else
#endif
	 RETVAL = &PL_sv_undef;
     }
     OUTPUT:
     RETVAL


MODULE = Heimdal::Kadm5                    PACKAGE = Heimdal::Kadm5

double
constant(name,arg)
        char *          name
        int             arg
