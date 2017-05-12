/*
Copyright 2013 Yuriy Nazarov.
This program is free software; you can redistribute it and/or modify it under the terms of either: the GNU General Public License as published by the Free Software Foundation; or the Artistic License.
*/
#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <sys/acl.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/acl.h>
#include <acl/libacl.h>
#ifdef __cplusplus
}
#endif

#define USER_KEY "user"
#define USER_KEY_LENGTH 4
#define GROUP_KEY "group"
#define GROUP_KEY_LENGTH 5
#define OTHER_KEY "other"
#define OTHER_KEY_LENGTH 5
#define MASK_KEY "mask"
#define MASK_KEY_LENGTH 4
#define USER_OBJ_KEY "uperm"
#define USER_OBJ_KEY_LENGTH 5
#define GROUP_OBJ_KEY "gperm"
#define GROUP_OBJ_KEY_LENGTH 5

#define CONSTANT_YES 0
#define CONSTANT_NO  1

HV* derefHV(SV *hashref){
	HV *ret_hash;
	if (! SvROK(hashref))	//check that input value is really reference
		return NULL;
	ret_hash = (HV *)SvRV(hashref);
	if (SvTYPE((SV *)ret_hash) != SVt_PVHV)	//check that it's really hash
		return NULL;
	return ret_hash;
}

void add_perm_to_hash(HV *hash, int r, int w, int x, char *key, U32 key_len){
	HV* perm_hash = newHV();

	hv_store(perm_hash, "r", 1, newSViv( r!=0 ), 0);
	hv_store(perm_hash, "w", 1, newSViv( w!=0 ), 0);
	hv_store(perm_hash, "x", 1, newSViv( x!=0 ), 0);

	hv_store(hash, key, key_len, newRV_noinc((SV*) perm_hash), 0);
}

void add_to_hash(HV *hash, acl_entry_t *ent, char *key, U32 key_len){
	acl_permset_t permset;
	
	acl_get_permset(*ent, &permset);
	add_perm_to_hash(hash, acl_get_perm(permset, ACL_READ), acl_get_perm(permset, ACL_WRITE), acl_get_perm(permset, ACL_EXECUTE), key, key_len);
}

void set_perm(acl_entry_t ent, mode_t perm)
{
	acl_permset_t set;

	acl_get_permset(ent, &set);
	if (perm & ACL_READ)
		acl_add_perm(set, ACL_READ);
	else
		acl_delete_perm(set, ACL_READ);
	if (perm & ACL_WRITE)
		acl_add_perm(set, ACL_WRITE);
	else
		acl_delete_perm(set, ACL_WRITE);
	if (perm & ACL_EXECUTE)
		acl_add_perm(set, ACL_EXECUTE);
	else
		acl_delete_perm(set, ACL_EXECUTE);
}

int get_perm_from_hash(HV *hash, const char *key, int key_len){
	HV *perm;
	SV **perm_ref;
	SV **atom_ref;
	int perm_val = 0;
	if(perm_ref = hv_fetch(hash, key, key_len, 0)){
		perm = derefHV(*perm_ref);
		if(NULL==perm){
			return 0;
		}

		if(atom_ref = hv_fetch(perm, "r", 1, 0)){
			if (! SvIOK(*atom_ref))
				return 0;
			perm_val |= SvIV(*atom_ref)?ACL_READ:0;
		}

		if(atom_ref = hv_fetch(perm, "w", 1, 0)){
			if (! SvIOK(*atom_ref))
				return 0;
			perm_val |= SvIV(*atom_ref)?ACL_WRITE:0;
		}

		if(atom_ref = hv_fetch(perm, "x", 1, 0)){
			if (! SvIOK(*atom_ref))
				return 0;
			perm_val |= SvIV(*atom_ref)?ACL_EXECUTE:0;
		}
	}
	return perm_val;
}

int getfacl_internal(char *filename, HV **out_acl, HV **out_default_acl){	//returns count
	struct stat st;
	int i;
	HV        **acl_hashes[2] = {out_acl,         out_default_acl};
	acl_type_t acl_types[2]   = {ACL_TYPE_ACCESS, ACL_TYPE_DEFAULT};
	*out_acl         = NULL;
	*out_default_acl = NULL;

	if (stat(filename, &st) != 0) {
		return 0;
	}
	
	for(i=0; i<2; i++){
		HV* acl_hash;
		HV* ret_acl_uperm;
		HV* ret_acl_gperm;
		acl_entry_t ent;
		acl_t acl;
		int ret;
		acl = acl_get_file(filename, acl_types[i]);
		if (acl == NULL) {
			continue;
		}

		ret = acl_get_entry(acl, ACL_FIRST_ENTRY, &ent);
		if (ret != 1){
			continue;
		}

		acl_hash = newHV();
		ret_acl_uperm = newHV();
		ret_acl_gperm = newHV();
		
		while (ret > 0) {
			acl_tag_t e_type;
			acl_get_tag_type(ent, &e_type);
			char id_str[30];	//Enough to print uint64_t
			U32 id_str_len;
			id_t *id_p;

			switch(e_type) {
				case ACL_USER_OBJ:	add_to_hash(acl_hash, &ent, USER_OBJ_KEY,  USER_OBJ_KEY_LENGTH);	break;
				case ACL_GROUP_OBJ:	add_to_hash(acl_hash, &ent, GROUP_OBJ_KEY, GROUP_OBJ_KEY_LENGTH);	break;
				case ACL_MASK:		add_to_hash(acl_hash, &ent, MASK_KEY,      MASK_KEY_LENGTH);	break;
				case ACL_OTHER:		add_to_hash(acl_hash, &ent, OTHER_KEY,     OTHER_KEY_LENGTH);	break;
				case ACL_USER:
					id_p = acl_get_qualifier(ent);
					id_str_len = sprintf(id_str, "%d", *id_p);
					add_to_hash(ret_acl_uperm, &ent, id_str, id_str_len);
					break;
				case ACL_GROUP:
					id_p = acl_get_qualifier(ent);
					id_str_len = sprintf(id_str, "%d", *id_p);
					add_to_hash(ret_acl_gperm, &ent, id_str, id_str_len);
					break;
			}
			ret = acl_get_entry(acl, ACL_NEXT_ENTRY, &ent);
		}
		hv_store(acl_hash, USER_KEY,  USER_KEY_LENGTH,  newRV_noinc((SV*) ret_acl_uperm), 0);
		hv_store(acl_hash, GROUP_KEY, GROUP_KEY_LENGTH, newRV_noinc((SV*) ret_acl_gperm), 0);
		*(acl_hashes[i]) = acl_hash;
	}
	if(NULL==*out_acl && NULL==*out_default_acl){
		*out_acl = newHV();
		add_perm_to_hash(*out_acl, st.st_mode && S_IRUSR, st.st_mode && S_IWUSR, st.st_mode && S_IXUSR, USER_OBJ_KEY,  USER_OBJ_KEY_LENGTH);
		add_perm_to_hash(*out_acl, st.st_mode && S_IRGRP, st.st_mode && S_IWGRP, st.st_mode && S_IXGRP, GROUP_OBJ_KEY, GROUP_OBJ_KEY_LENGTH);
		add_perm_to_hash(*out_acl, st.st_mode && S_IROTH, st.st_mode && S_IWOTH, st.st_mode && S_IXOTH, OTHER_KEY,     OTHER_KEY_LENGTH);
	}

	return (NULL==*out_acl)?0:( (NULL==*out_default_acl)?1:2 );
}

int setfacl_internal(char *filename, HV *in_acl_hash, HV *in_default_acl_hash){
	HV         *acl_hashes[3] = {in_acl_hash,     in_default_acl_hash, NULL};
	acl_type_t acl_types[3]   = {ACL_TYPE_ACCESS, ACL_TYPE_DEFAULT,    0};
	int i = 0;
	int rc = CONSTANT_YES;

	while(NULL != acl_hashes[i]){
		acl_t acl = NULL;
		acl_entry_t ent;
		HE *hash_entry;
		SV **hash_ref;
		HV *user_hash  = NULL;
		HV *group_hash = NULL;
		HV *current_acl = acl_hashes[i];

		if(hash_ref = hv_fetch(current_acl, USER_KEY, USER_KEY_LENGTH, 0)){
			user_hash = derefHV(*hash_ref);
		}else{
			//missing USER_KEY
		}

		if(hash_ref = hv_fetch(current_acl, GROUP_KEY, GROUP_KEY_LENGTH, 0)){
			group_hash = derefHV(*hash_ref);
		}else{
			//missing GROUP_KEY
		}

		acl = acl_init(0);
		if (!acl) {
			rc = CONSTANT_NO;
		}
		if (acl_create_entry(&acl, &ent) == 0){
			acl_set_tag_type(ent, ACL_USER_OBJ);
			set_perm(ent, get_perm_from_hash(current_acl, USER_OBJ_KEY, USER_OBJ_KEY_LENGTH));
		} else {
			rc = CONSTANT_NO;
		}
		if (acl_create_entry(&acl, &ent) == 0){
			acl_set_tag_type(ent, ACL_GROUP_OBJ);
			set_perm(ent, get_perm_from_hash(current_acl, GROUP_OBJ_KEY, GROUP_OBJ_KEY_LENGTH));
		} else {
			rc = CONSTANT_NO;
		}
		if (acl_create_entry(&acl, &ent) == 0){
			acl_set_tag_type(ent, ACL_MASK);
			set_perm(ent, get_perm_from_hash(current_acl, MASK_KEY, MASK_KEY_LENGTH));
		} else {
			rc = CONSTANT_NO;
		}
		if (acl_create_entry(&acl, &ent) == 0){
			acl_set_tag_type(ent, ACL_OTHER);
			set_perm(ent, get_perm_from_hash(current_acl, OTHER_KEY, OTHER_KEY_LENGTH));
		} else {
			rc = CONSTANT_NO;
		}
	
		if(NULL != user_hash){
			hv_iterinit(user_hash);
			while(hash_entry = hv_iternext(user_hash)){
				id_t id_p;
				I32 key_len;
				char *key = hv_iterkey(hash_entry, &key_len);
				id_p = atoi(key);
				if (acl_create_entry(&acl, &ent) == 0){
					acl_set_tag_type(ent, ACL_USER);
					acl_set_qualifier(ent, &id_p);
					set_perm(ent, get_perm_from_hash(user_hash, key, key_len));
				} else {
					rc = CONSTANT_NO;
				}
			}
		}

		if(NULL != group_hash){
			hv_iterinit(group_hash);
			while(hash_entry = hv_iternext(group_hash)){
				id_t id_p;
				I32 key_len;
				char *key = hv_iterkey(hash_entry, &key_len);
				id_p = atoi(key);
				if (acl_create_entry(&acl, &ent) == 0){
					acl_set_tag_type(ent, ACL_GROUP);
					acl_set_qualifier(ent, &id_p);
					set_perm(ent, get_perm_from_hash(group_hash, key, key_len));
				} else {
					rc = CONSTANT_NO;
				}
			}
		}

		if (acl_set_file(filename, acl_types[i], acl) == -1) {
			rc = CONSTANT_NO;
		}

		acl_free(acl);

		i++;
	}

	return rc;
}

/*
 * Exported code
 */

#define PACKAGE_NAME "Linux::ACL"

MODULE = Linux::ACL		PACKAGE = Linux::ACL

void
getfacl(filename)
	SV * filename;
	PPCODE:
		HV *acl, *default_acl;
		STRLEN filename_string_length;
		char *filename_string = SvPV(filename, filename_string_length);

		int count = getfacl_internal(filename_string, &acl, &default_acl);

		if(count>=1)
			XPUSHs(  sv_2mortal( newRV_noinc((SV*) acl) )  );
		if(count>=2)
			XPUSHs(  sv_2mortal( newRV_noinc((SV*) default_acl) )  );
		XSRETURN(count);


void
setfacl(filename, acl_hashref, ...)
	SV *filename;
	SV *acl_hashref;
	PPCODE:
		STRLEN filename_string_length;
		char* filename_string = SvPV(filename, filename_string_length);
		HV *acl_hash         = derefHV(acl_hashref);
		HV *default_acl_hash = NULL;
		if( items > 2 )
			default_acl_hash = derefHV(ST(2));

		if(NULL == acl_hash){
			XSRETURN_NO;
		}

		if( CONSTANT_YES == setfacl_internal(filename_string, acl_hash, default_acl_hash) ){
			XSRETURN_YES;
		}else{
			XSRETURN_NO;
		}
