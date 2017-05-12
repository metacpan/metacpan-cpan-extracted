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

static double
constant(char *name, int arg)
{
    errno = 0;
    switch (*name) {
    case 'A':
	break;
    case 'B':
	break;
    case 'C':
	break;
    case 'D':
	break;
    case 'E':
	break;
    case 'F':
	break;
    case 'G':
	break;
    case 'H':
	break;
    case 'I':
	break;
    case 'J':
	break;
    case 'K':
      if (strEQ(name, "KRB5_KDB_DISALLOW_ALL_TIX"))
#ifdef KRB5_KDB_DISALLOW_ALL_TIX
	return KRB5_KDB_DISALLOW_ALL_TIX;
#else
        goto not_there;
#endif
      if (strEQ(name, "KADM5_API_VERSION_1"))
#ifdef KADM5_API_VERSION_1
	    return KADM5_API_VERSION_1;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_API_VERSION_2"))
#ifdef KADM5_API_VERSION_2
	    return KADM5_API_VERSION_2;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_ATTRIBUTES"))
#ifdef KADM5_ATTRIBUTES
	    return KADM5_ATTRIBUTES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_AUX_ATTRIBUTES"))
#ifdef KADM5_AUX_ATTRIBUTES
	    return KADM5_AUX_ATTRIBUTES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_CONFIG_ACL_FILE"))
#ifdef KADM5_CONFIG_ACL_FILE
	    return KADM5_CONFIG_ACL_FILE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_CONFIG_ADBNAME"))
#ifdef KADM5_CONFIG_ADBNAME
	    return KADM5_CONFIG_ADBNAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_CONFIG_ADB_LOCKFILE"))
#ifdef KADM5_CONFIG_ADB_LOCKFILE
	    return KADM5_CONFIG_ADB_LOCKFILE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_CONFIG_ADMIN_KEYTAB"))
#ifdef KADM5_CONFIG_ADMIN_KEYTAB
	    return KADM5_CONFIG_ADMIN_KEYTAB;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_CONFIG_ADMIN_SERVER"))
#ifdef KADM5_CONFIG_ADMIN_SERVER
	    return KADM5_CONFIG_ADMIN_SERVER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_CONFIG_DBNAME"))
#ifdef KADM5_CONFIG_DBNAME
	    return KADM5_CONFIG_DBNAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_CONFIG_DICT_FILE"))
#ifdef KADM5_CONFIG_DICT_FILE
	    return KADM5_CONFIG_DICT_FILE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_CONFIG_ENCTYPE"))
#ifdef KADM5_CONFIG_ENCTYPE
	    return KADM5_CONFIG_ENCTYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_CONFIG_ENCTYPES"))
#ifdef KADM5_CONFIG_ENCTYPES
	    return KADM5_CONFIG_ENCTYPES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_CONFIG_EXPIRATION"))
#ifdef KADM5_CONFIG_EXPIRATION
	    return KADM5_CONFIG_EXPIRATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_CONFIG_FLAGS"))
#ifdef KADM5_CONFIG_FLAGS
	    return KADM5_CONFIG_FLAGS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_CONFIG_KADMIND_PORT"))
#ifdef KADM5_CONFIG_KADMIND_PORT
	    return KADM5_CONFIG_KADMIND_PORT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_CONFIG_MAX_LIFE"))
#ifdef KADM5_CONFIG_MAX_LIFE
	    return KADM5_CONFIG_MAX_LIFE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_CONFIG_MAX_RLIFE"))
#ifdef KADM5_CONFIG_MAX_RLIFE
	    return KADM5_CONFIG_MAX_RLIFE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_CONFIG_MKEY_FROM_KEYBOARD"))
#ifdef KADM5_CONFIG_MKEY_FROM_KEYBOARD
	    return KADM5_CONFIG_MKEY_FROM_KEYBOARD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_CONFIG_MKEY_NAME"))
#ifdef KADM5_CONFIG_MKEY_NAME
	    return KADM5_CONFIG_MKEY_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_CONFIG_PROFILE"))
#ifdef KADM5_CONFIG_PROFILE
	    return KADM5_CONFIG_PROFILE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_CONFIG_REALM"))
#ifdef KADM5_CONFIG_REALM
	    return KADM5_CONFIG_REALM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_CONFIG_STASH_FILE"))
#ifdef KADM5_CONFIG_STASH_FILE
	    return KADM5_CONFIG_STASH_FILE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_FAIL_AUTH_COUNT"))
#ifdef KADM5_FAIL_AUTH_COUNT
	    return KADM5_FAIL_AUTH_COUNT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_KEY_DATA"))
#ifdef KADM5_KEY_DATA
	    return KADM5_KEY_DATA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_KVNO"))
#ifdef KADM5_KVNO
	    return KADM5_KVNO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_LAST_FAILED"))
#ifdef KADM5_LAST_FAILED
	    return KADM5_LAST_FAILED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_LAST_PWD_CHANGE"))
#ifdef KADM5_LAST_PWD_CHANGE
	    return KADM5_LAST_PWD_CHANGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_LAST_SUCCESS"))
#ifdef KADM5_LAST_SUCCESS
	    return KADM5_LAST_SUCCESS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_MAX_LIFE"))
#ifdef KADM5_MAX_LIFE
	    return KADM5_MAX_LIFE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_MAX_RLIFE"))
#ifdef KADM5_MAX_RLIFE
	    return KADM5_MAX_RLIFE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_MKVNO"))
#ifdef KADM5_MKVNO
	    return KADM5_MKVNO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_MOD_NAME"))
#ifdef KADM5_MOD_NAME
	    return KADM5_MOD_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_MOD_TIME"))
#ifdef KADM5_MOD_TIME
	    return KADM5_MOD_TIME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_POLICY"))
#ifdef KADM5_POLICY
	    return KADM5_POLICY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_POLICY_CLR"))
#ifdef KADM5_POLICY_CLR
	    return KADM5_POLICY_CLR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_POLICY_NORMAL_MASK"))
#ifdef KADM5_POLICY_NORMAL_MASK
	    return KADM5_POLICY_NORMAL_MASK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_PRINCIPAL"))
#ifdef KADM5_PRINCIPAL
	    return KADM5_PRINCIPAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_PRINCIPAL_NORMAL_MASK"))
#ifdef KADM5_PRINCIPAL_NORMAL_MASK
	    return KADM5_PRINCIPAL_NORMAL_MASK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_PRINC_EXPIRE_TIME"))
#ifdef KADM5_PRINC_EXPIRE_TIME
	    return KADM5_PRINC_EXPIRE_TIME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_PRIV_ADD"))
#ifdef KADM5_PRIV_ADD
	    return KADM5_PRIV_ADD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_PRIV_ALL"))
#ifdef KADM5_PRIV_ALL
	    return KADM5_PRIV_ALL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_PRIV_CPW"))
#ifdef KADM5_PRIV_CPW
	    return KADM5_PRIV_CPW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_PRIV_DELETE"))
#ifdef KADM5_PRIV_DELETE
	    return KADM5_PRIV_DELETE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_PRIV_GET"))
#ifdef KADM5_PRIV_GET
	    return KADM5_PRIV_GET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_PRIV_LIST"))
#ifdef KADM5_PRIV_LIST
	    return KADM5_PRIV_LIST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_PRIV_MODIFY"))
#ifdef KADM5_PRIV_MODIFY
	    return KADM5_PRIV_MODIFY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_PW_EXPIRATION"))
#ifdef KADM5_PW_EXPIRATION
	    return KADM5_PW_EXPIRATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_PW_HISTORY_NUM"))
#ifdef KADM5_PW_HISTORY_NUM
	    return KADM5_PW_HISTORY_NUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_PW_MAX_LIFE"))
#ifdef KADM5_PW_MAX_LIFE
	    return KADM5_PW_MAX_LIFE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_PW_MIN_CLASSES"))
#ifdef KADM5_PW_MIN_CLASSES
	    return KADM5_PW_MIN_CLASSES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_PW_MIN_LENGTH"))
#ifdef KADM5_PW_MIN_LENGTH
	    return KADM5_PW_MIN_LENGTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_PW_MIN_LIFE"))
#ifdef KADM5_PW_MIN_LIFE
	    return KADM5_PW_MIN_LIFE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_REF_COUNT"))
#ifdef KADM5_REF_COUNT
	    return KADM5_REF_COUNT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_STRUCT_VERSION"))
#ifdef KADM5_STRUCT_VERSION
	    return KADM5_STRUCT_VERSION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KADM5_TL_DATA"))
#ifdef KADM5_TL_DATA
	    return KADM5_TL_DATA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KRB5_KDB_DISALLOW_ALL_TIX"))
#ifdef KRB5_KDB_DISALLOW_ALL_TIX
	    return KRB5_KDB_DISALLOW_ALL_TIX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KRB5_KDB_DISALLOW_DUP_SKEY"))
#ifdef KRB5_KDB_DISALLOW_DUP_SKEY
	    return KRB5_KDB_DISALLOW_DUP_SKEY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KRB5_KDB_DISALLOW_FORWARDABLE"))
#ifdef KRB5_KDB_DISALLOW_FORWARDABLE
	    return KRB5_KDB_DISALLOW_FORWARDABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KRB5_KDB_DISALLOW_POSTDATED"))
#ifdef KRB5_KDB_DISALLOW_POSTDATED
	    return KRB5_KDB_DISALLOW_POSTDATED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KRB5_KDB_DISALLOW_PROXIABLE"))
#ifdef KRB5_KDB_DISALLOW_PROXIABLE
	    return KRB5_KDB_DISALLOW_PROXIABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KRB5_KDB_DISALLOW_RENEWABLE"))
#ifdef KRB5_KDB_DISALLOW_RENEWABLE
	    return KRB5_KDB_DISALLOW_RENEWABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KRB5_KDB_DISALLOW_SVR"))
#ifdef KRB5_KDB_DISALLOW_SVR
	    return KRB5_KDB_DISALLOW_SVR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KRB5_KDB_DISALLOW_TGT_BASED"))
#ifdef KRB5_KDB_DISALLOW_TGT_BASED
	    return KRB5_KDB_DISALLOW_TGT_BASED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KRB5_KDB_NEW_PRINC"))
#ifdef KRB5_KDB_NEW_PRINC
	    return KRB5_KDB_NEW_PRINC;
#else
	    goto not_there;
#endif

	if (strEQ(name, "KRB5_KDB_PWCHANGE_SERVICE"))
#ifdef KRB5_KDB_PWCHANGE_SERVICE
	    return KRB5_KDB_PWCHANGE_SERVICE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KRB5_KDB_REQUIRES_HW_AUTH"))
#ifdef KRB5_KDB_REQUIRES_HW_AUTH
	    return KRB5_KDB_REQUIRES_HW_AUTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KRB5_KDB_REQUIRES_PRE_AUTH"))
#ifdef KRB5_KDB_REQUIRES_PRE_AUTH
	    return KRB5_KDB_REQUIRES_PRE_AUTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KRB5_KDB_REQUIRES_PWCHANGE"))
#ifdef KRB5_KDB_REQUIRES_PWCHANGE
	    return KRB5_KDB_REQUIRES_PWCHANGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KRB5_KDB_SUPPORT_DESMD5"))
#ifdef KRB5_KDB_SUPPORT_DESMD5
	    return KRB5_KDB_SUPPORT_DESMD5;
#else
	    goto not_there;
#endif
	break;
    case 'L':
	break;
    case 'M':
	break;
    case 'N':
	break;
    case 'O':
	break;
    case 'P':
	break;
    case 'Q':
	break;
    case 'R':
	break;
    case 'S':
	break;
    case 'T':
	break;
    case 'U':
	if (strEQ(name, "USE_KADM5_API_VERSION"))
#ifdef USE_KADM5_API_VERSION
	    return USE_KADM5_API_VERSION;
#else
	    goto not_there;
#endif
	break;
    case 'V':
	break;
    case 'W':
	break;
    case 'X':
	break;
    case 'Y':
	break;
    case 'Z':
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}
