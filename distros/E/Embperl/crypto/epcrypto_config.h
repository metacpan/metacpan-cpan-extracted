/*###################################################################################
#
#   Embperl - Copyright (c) 1997-2008 Gerald Richter / ecos gmbh  www.ecos.de
#   Embperl - Copyright (c) 2008-2014 Gerald Richter
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#   For use with Apache httpd and mod_perl, see also Apache copyright.
#
#   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#   $Id: epcrypto_config.h 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################*/

/*
*   Configuration for Embperl source code encrytion, 
*   you need to set the correct values for
*
*   EPC_ENABLE
*   EPC_CHIPER
*   EPC_KEY 
*   EPC_KEYLEN
*   EPC_UNENCYRPTED 
*
*   before you can use it.
*/

/* ----------------------------------------------------------------------------
*
* Enable source code encryption
*
* Set to 1 for yes and to 0 for no
*
* -------------------------------------------------------------------------- */

#define EPC_ENABLE 0


/* ----------------------------------------------------------------------------

Possible Chipers, an up to date list can be found at

http://www.openssl.org/docs/crypto/EVP_EncryptInit.html#CIPHER_LISTING

-------------------------------------------------------------------------------

CIPHER LISTING
==============

All algorithms have a fixed key length unless otherwise stated. 

EVP_enc_null()
Null cipher: does nothing. 

EVP_des_cbc(void), EVP_des_ecb(void), EVP_des_cfb(void), EVP_des_ofb(void)
DES in CBC, ECB, CFB and OFB modes respectively. 

EVP_des_ede_cbc(void), EVP_des_ede(), EVP_des_ede_ofb(void), EVP_des_ede_cfb(void)
Two key triple DES in CBC, ECB, CFB and OFB modes respectively. 

EVP_des_ede3_cbc(void), EVP_des_ede3(), EVP_des_ede3_ofb(void), EVP_des_ede3_cfb(void)
Three key triple DES in CBC, ECB, CFB and OFB modes respectively. 

EVP_desx_cbc(void)
DESX algorithm in CBC mode. 

EVP_rc4(void)
RC4 stream cipher. This is a variable key length cipher with default key length 128 bits. 

EVP_rc4_40(void)
RC4 stream cipher with 40 bit key length. This is obsolete and new code should 
use EVP_rc4() and the EVP_CIPHER_CTX_set_key_length() function. 

EVP_idea_cbc() EVP_idea_ecb(void), EVP_idea_cfb(void), EVP_idea_ofb(void), EVP_idea_cbc(void)
IDEA encryption algorithm in CBC, ECB, CFB and OFB modes respectively. 

EVP_rc2_cbc(void), EVP_rc2_ecb(void), EVP_rc2_cfb(void), EVP_rc2_ofb(void)
RC2 encryption algorithm in CBC, ECB, CFB and OFB modes respectively. This is a 
variable key length cipher with an additional parameter called ``effective key 
bits'' or ``effective key length''. By default both are set to 128 bits. 

EVP_rc2_40_cbc(void), EVP_rc2_64_cbc(void)
RC2 algorithm in CBC mode with a default key length and effective key length of 
40 and 64 bits. These are obsolete and new code should use EVP_rc2_cbc(), 
EVP_CIPHER_CTX_set_key_length() and EVP_CIPHER_CTX_ctrl() to set the key length and effective key length. 

EVP_bf_cbc(void), EVP_bf_ecb(void), EVP_bf_cfb(void), EVP_bf_ofb(void);
Blowfish encryption algorithm in CBC, ECB, CFB and OFB modes respectively. 
This is a variable key length cipher. 

EVP_cast5_cbc(void), EVP_cast5_ecb(void), EVP_cast5_cfb(void), EVP_cast5_ofb(void)
CAST encryption algorithm in CBC, ECB, CFB and OFB modes respectively. 
This is a variable key length cipher. 

EVP_rc5_32_12_16_cbc(void), EVP_rc5_32_12_16_ecb(void), EVP_rc5_32_12_16_cfb(void), EVP_rc5_32_12_16_ofb(void)
RC5 encryption algorithm in CBC, ECB, CFB and OFB modes respectively. 
This is a variable key length cipher with an additional ``number of rounds'' 
parameter. By default the key length is set to 128 bits and 12 rounds. 

---------------------------------------------------------------------------- */

/* ----------------------------------------------------------------------------
*
* Chiper to use, choose one of the above
* or any function that returns a valid EVP_CIPHER structure.
*
* -------------------------------------------------------------------------- */

#define EPC_CHIPER EVP_rc4()


/* ----------------------------------------------------------------------------
*
* Key and it's length
*
* the below value must be suitable to use a initializer for an char pointer.
* either specify an constant or any function that returns a pointer a string
*
* !!!!!!!! Make sure to change to key below and make it length fit to used chiper !!!!!!!!
* !!!!!!!! Keep this file secret, anybody who has access to this and therefore    !!!!!!!!
* !!!!!!!!   to the key value can easy decrypt anything                           !!!!!!!!
* 
* -------------------------------------------------------------------------- */

#define EPC_KEY "\x88\0x56\xff\x78\xbc\xaa\x94\x1a\xfe" 
#define EPC_KEYLEN (sizeof (EPC_KEY) - 1)


/* ----------------------------------------------------------------------------
*
* Allow unencrypted files to be served by Embperl ? 
*
* Set to 1 for yes and to 0 for no
*
* -------------------------------------------------------------------------- */

#define EPC_UNENCYRPTED 1

