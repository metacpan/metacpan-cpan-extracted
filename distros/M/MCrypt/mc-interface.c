/*
  Copyright (c) 2000 Frey Kuo

   You may distribute under the terms of either the GNU General Public
   License or the Artistic License, as specified in the Perl README file,
   with the exception that it cannot be placed on a CD-ROM or similar media
   for commercial distribution without the prior approval of the author.

  THIS SOFTWARE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
  EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DAMAGES RESULTING FROM
  THE USE OF THIS SOFTWARE.                      
*/
#include <mcrypt.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "mc-interface.h"

#define _TESTING_ 0
#define CIPHER_NAME_SIZE 64  //size of the array to hold the cipher name
#define CIPHER_NAME_PREFIX "MCRYPT_"

/* Get the name of the specified cipher */
char *
pmcrypt_get_cipher_name( int cipher )
{
    char *cipher_name = NULL ;
    char *retval      = NULL ;  
    
    cipher_name = mcrypt_get_algorithms_name(cipher) ;

    if( !cipher_name ) {
        return NULL ;
    }
    retval = strdup(cipher_name) ;
    free(cipher_name) ;
    return( retval );
}

/* Get the block size of the specified cipher */
int
pmcrypt_get_block_size(int cipher)
{
    return(mcrypt_get_block_size(cipher));
}

/* Get the key size of the specified cipher */
int
pmcrypt_get_key_size(int cipher)
{
    return(mcrypt_get_key_size(cipher)) ;
}

/* Create an initialization vector (IV) from a "random" source */
char *
pmcrypt_create_iv(int size, char *source)
{
// NOT IMPLEMENTED IN THIS VERSION
    return NULL ;
}

/* ECB crypt/decrypt using key key with cipher cipher */
char *
pmcrypt_ecb(int cipher, char *key, char *data, int mode, int conv_hex)
{
    int td ;
    int keylen, encrypt = 0;
    char *ndata ;
    size_t blocksize, nr, nsize, datalen ;
    
    if(data == NULL || key == NULL )
        return NULL ;

    if(mode)
        encrypt = 1 ;
    else
        encrypt = 0 ;
    
    blocksize = mcrypt_get_block_size( cipher ) ;
    keylen    =  strlen( key ) ;
    datalen   =  strlen( data ) ;

    // how many blocks we need for the data
    nr    = (datalen + blocksize - 1) / blocksize ;
    nsize = nr * blocksize ;
    ndata = calloc(1, nsize);

    td = init_mcrypt_ecb(cipher, key, keylen);
    
    if( td == -1 ) {
	// we should really produce an error or something
        return NULL ;
    }

    if (encrypt) {
        memcpy( ndata, data, datalen ) ;
        mcrypt_ecb( td, ndata, nsize ) ;
        end_mcrypt_ecb(td) ;
        return( ( conv_hex ? bin2hex(ndata, nsize) : ndata ) );
    } else {
        //hex2bin conversion needs 1/2 less space
        conv_hex ?
            memcpy( ndata, hex2bin(data,datalen),  datalen / 2 ) :
            memcpy( ndata, data, datalen ) ;
        mdecrypt_ecb( td, ndata, nsize ) ;
        end_mcrypt_ecb(td) ;
        return( ndata );
    }
}

/* CBC crypt/decrypt data using key key with cipher cipher using
   optional IV */
char *
pmcrypt_cbc(int cipher, char *key, char *data, int mode, char *IV, int conv_hex)
{
    int td ;
    int keylen, encrypt = 0;
    char *ndata ;
    size_t blocksize, nr, nsize, datalen ;
    
    if(data == NULL || key == NULL )
        return NULL ;

    if(mode)
        encrypt = 1 ;
    else
        encrypt = 0 ;
    
    blocksize = mcrypt_get_block_size( cipher ) ;
    keylen    = strlen( key ) ;
    datalen   = strlen( data ) ;

    // how many blocks we need for the data
    nr    = (datalen + blocksize - 1) / blocksize ;
    nsize = nr * blocksize ;
    ndata = calloc(1, nsize);
    
    if( ( IV != NULL && strlen(IV) != blocksize ) )
        return NULL ;

    if (IV == NULL) {
        td = init_mcrypt_cbc(cipher, key, keylen);
    } else {
        td =  init_mcrypt_cbc_iv(cipher, key, keylen, IV);
    }

    if( td == -1 ) {
	// we should really produce an error or something
        return NULL ;
    }
    if( IV != NULL )
        // initialize with our IV
        mcrypt( td, IV ) ;    

    if (encrypt) {
        memcpy( ndata, data, datalen ) ;
        mcrypt_cbc( td, ndata, nsize ) ;
        end_mcrypt_cbc(td) ;
        return( conv_hex ? bin2hex(ndata, nsize) : ndata );
    } else {
        //hex2bin conversion needs 1/2 less space
        conv_hex ?
            memcpy( ndata, hex2bin(data,datalen), datalen / 2 ) :
            memcpy( ndata, data, datalen ) ;
        mdecrypt_cbc( td, ndata, nsize ) ;
        end_mcrypt_cbc(td) ;
        return( ndata );
    }
}

/* OFB crypt/decrypt data using key key with cipher cipher starting
   with IV */
char *
pmcrypt_ofb(int cipher, char *key, char *data, int mode, char *IV, int conv_hex)
{
    int td ;
    int keylen, encrypt = 0;
    char *ndata ;
    size_t blocksize, nr, nsize, datalen ;
    
    if(data == NULL || key == NULL || IV == NULL )
        return NULL ;

    if(mode)
        encrypt = 1 ;
    else
        encrypt = 0 ;
    
    blocksize = mcrypt_get_block_size( cipher ) ;
    keylen    = strlen( key ) ;
    datalen   = strlen( data ) ;

    // how many blocks we need for the data
    nr    = (datalen + blocksize - 1) / blocksize ;
    nsize = nr * blocksize ;
    ndata = calloc(1, nsize);
    
    if( ( IV != NULL && strlen(IV) != blocksize ) )
        return NULL ;

    td =  init_mcrypt_ofb(cipher, key, keylen, IV);

    if( td == -1 ) {
	// we should really produce an error or something
        return NULL ;
    }

    if (encrypt) {
        memcpy( ndata, data, datalen ) ;
        mcrypt_ofb( td, ndata, nsize ) ;
        end_mcrypt_ofb(td) ;
        return( conv_hex ? bin2hex(ndata, nsize) : ndata );
    } else {
        //hex2bin conversion needs 1/2 less space
        conv_hex ?
            memcpy( ndata, hex2bin(data,datalen), datalen / 2 ) :
            memcpy( ndata, data, datalen ) ;
        mdecrypt_ofb( td, ndata, nsize ) ;
        end_mcrypt_ofb(td) ;
        return( ndata );
    }
}

/* CFB crypt/decrypt data using key key with cipher cipher starting
   with IV */
char *
pmcrypt_cfb(int cipher, char *key, char *data, int mode, char *IV, int conv_hex)
{
    int td ;
    int keylen, encrypt = 0;
    char *ndata ;
    size_t blocksize, nr, nsize, datalen ;
    
    if(data == NULL || key == NULL || IV == NULL )
        return NULL ;

    if(mode)
        encrypt = 1 ;
    else
        encrypt = 0 ;
    
    blocksize = mcrypt_get_block_size( cipher ) ;
    keylen    = strlen( key ) ;
    datalen   = strlen( data ) ;

    // how many blocks we need for the data
    nr    = (datalen + blocksize - 1) / blocksize ;
    nsize = nr * blocksize ;
    ndata = calloc(1, nsize);
    
    if( ( IV != NULL && strlen(IV) != blocksize ) )
        return NULL ;

    td =  init_mcrypt_cfb(cipher, key, keylen, IV);

    if( td == -1 ) {
	// we should really produce an error or something
        return NULL ;
    }

    if (encrypt) {
        memcpy( ndata, data, datalen ) ;
        mcrypt_cfb( td, ndata, nsize ) ;
        end_mcrypt_cfb(td) ;
        return( conv_hex ? bin2hex(ndata, nsize) : ndata );
    } else {
        //hex2bin conversion needs 1/2 less space
        conv_hex ?
            memcpy( ndata, hex2bin(data,datalen), datalen / 2 ) :
            memcpy( ndata, data, datalen ) ;
        mdecrypt_cfb( td, ndata, nsize ) ;
        end_mcrypt_cfb(td) ;
        return( ndata );
    }
}
/* Ripped out of php3.0.16 */
static char hexconvtab[] = "0123456789abcdef";
static char *bin2hex( const unsigned char *old, const size_t oldlen ) 
{
  unsigned char *new = NULL;
  size_t i, j;
  
  new = (char *) malloc(oldlen * 2 * sizeof(char));
  if(!new) {
    return new;
  }
  
  for(i = j = 0; i < oldlen; i++) {
    new[j++] = hexconvtab[old[i] >> 4];
    new[j++] = hexconvtab[old[i] & 15];
  }  
  new[j] = '\0';
  return new;
}

int is_hex(char *given_chain, int len)
{
  int i; 
  for (i = 0; i < len; i++)
    if (isxdigit(given_chain[i]) == 0)
      return 0;
  return 1;
}

/*  Converts a string of (an even number of) hex digits to binary */
char *
hex2bin(char *hex, int len)
{
  char ch ;
  unsigned char val;
  char *tmpchain ;
  int nbytes = 0, i = 0, upper = 1 ;

  /* The chain should have 2*n characters */
  if (len % 2 != 0)
      return NULL ;
  if (!is_hex(hex, len))
      return NULL ;
  
  tmpchain = malloc((len / 2) + 1);
  
  for(; nbytes<len; hex++) {
    ch = *hex;
    if(ch == ' ') continue;
    if(islower(ch)) ch = (char)toupper(ch);
    if(isdigit(ch)) {
      val = (unsigned char) (ch - '0');
    } else if(ch>='A' && ch<='F') {
      val = (unsigned char)(ch - 'A' + 10);
      
      /* End of hex digits--time to bail out. */
    } else {
      return (upper ? tmpchain : 0);
    }
    
    /* If this is an upper digit, set the top 4 bits of the destination
     * byte with this value, else -OR- in the value.
     */
    if(upper) {
      tmpchain[i] = (unsigned char) (val << 4);
      upper = 0;
    } else {
      tmpchain[i++] |= val;
      upper = 1;
    }
  }
  tmpchain[(len / 2)] = '\0' ;
  return(tmpchain);
}

#ifdef _TESTING_
int
main() {
  int keysize, blocksize ;
  char *key; /* created using gen_key */
  char *IV, *block ;
  //char myshit[100] = "abcdefghijklmnopqrstuvwxyz";
  char myshit[200] = "abcdefghijklmnopqrstuvwxyzlkasdjfalsdkfjasdlkfjadslkfajdsflkasdjflkadsjflkasjfklsfjlksfkldsjfl";
  int len = strlen(myshit) ;
  char *shit ;
  int ciphernumber, bs, ks ;
  char *ciphername ;
  
  
  printf("len shit = %d\n",len);
  

  keysize   = mcrypt_get_key_size  ( MCRYPT_3DES ) ;
  blocksize = mcrypt_get_block_size( MCRYPT_3DES ) ;

  key   = calloc(1, keysize);
  block = calloc(1, blocksize);
  IV    = calloc(1, blocksize);  
  shit  = calloc(1, len+1);
  
  strcpy(key,   "key");
  strcpy(block, "block");
  strcpy(IV,    "IV") ;
  strncpy(shit,  myshit,len) ;

  printf("string = [%s], size=(%d) bs = %d\n",shit,strlen(shit),blocksize) ;  
  ciphername = pmcrypt_get_cipher_name(ciphernumber) ;
  ks = pmcrypt_get_key_size(ciphernumber) ;
  bs = pmcrypt_get_block_size(ciphernumber) ;
  
  printf("ciphernumber of %s = %d. bs=%d ks=%d (%d)\n",ciphername, ciphernumber,bs,ks,mcrypt_get_key_size(ciphernumber)) ;
  return 0;
}

/* given the string name of the cipher, return the appropriate cipher
   identifier as specified in mcrypt.h */
int
getcipher( char *name )
{
/*
  // FOR reference - ripped from mcrypt 2.2.6 mcrypt.h
  #define MCRYPT_BLOWFISH_448 0
  #define MCRYPT_DES 1 
  #define MCRYPT_3DES 2
  #define MCRYPT_3WAY 3
  #define MCRYPT_GOST 4
  #define MCRYPT_SAFER_64 6
  #define MCRYPT_SAFER_128 7
  #define MCRYPT_CAST_128 8
  #define MCRYPT_XTEA 9
  #define MCRYPT_RC2_1024 11
  #define MCRYPT_TWOFISH_128 10
  #define MCRYPT_TWOFISH_192 12
  #define MCRYPT_TWOFISH_256 13
  #define MCRYPT_BLOWFISH_128 14
  #define MCRYPT_BLOWFISH_192 15
  #define MCRYPT_BLOWFISH_256 16
  #define MCRYPT_CAST_256 17
  #define MCRYPT_SAFERPLUS 18
  #define MCRYPT_LOKI97 19
  #define MCRYPT_SERPENT_128 20
  #define MCRYPT_SERPENT_192 21
  #define MCRYPT_SERPENT_256 22
  #define MCRYPT_RIJNDAEL_128 23
  #define MCRYPT_RIJNDAEL_192 24
  #define MCRYPT_RIJNDAEL_256 25
  #define MCRYPT_RC2_256 26
  #define MCRYPT_RC2_128 27
  #define MCRYPT_CRYPT 28
  
  #define MCRYPT_RC6_256 100
  #define MCRYPT_IDEA 101
  #define MCRYPT_RC6_128 102
  #define MCRYPT_RC6_192 103
  
  #define MCRYPT_RC4 MCRYPT_ARCFOUR
  #define MCRYPT_ARCFOUR 104
*/

    char cipher_name[CIPHER_NAME_SIZE] = CIPHER_NAME_PREFIX;
    
    int len , name_len;    
    
    if (name == NULL)
        // MCRYPT_BLOWFISH_448 is the default
        return 0 ;
    
    len = strlen(cipher_name) ;
    name_len = CIPHER_NAME_SIZE - ( len + 1 );    
    strncat(cipher_name, name, name_len) ;
    
    // WORKITEM: gotta find a faster way of doing this
    // mapping. Hashes perhaps.. or
    // This may involve just exporting these constants into perl and
    // forgetting this whole mapping business, but I will try this
    // first to be as non-intrusive as possible.

    if( strncasecmp(cipher_name,"MCRYPT_BLOWFISH_448",CIPHER_NAME_SIZE) == 0 )
        return 0 ;
    else if (strncasecmp(cipher_name,"MCRYPT_DES",CIPHER_NAME_SIZE) == 0 )
        return 1 ;
    else if (strncasecmp(cipher_name,"MCRYPT_3DES",CIPHER_NAME_SIZE) == 0 ) 
        return 2 ;
    else if (strncasecmp(cipher_name,"MCRYPT_3WAY",CIPHER_NAME_SIZE) == 0 ) 
        return 3 ;
    else if (strncasecmp(cipher_name,"MCRYPT_GOST",CIPHER_NAME_SIZE) == 0 ) 
        return 4 ;
    else if (strncasecmp(cipher_name,"MCRYPT_SAFER_64",CIPHER_NAME_SIZE) == 0 ) 
        return 6 ;
    else if (strncasecmp(cipher_name,"MCRYPT_SAFER_128",CIPHER_NAME_SIZE) == 0 ) 
        return 7 ;
    else if (strncasecmp(cipher_name,"MCRYPT_CAST_128",CIPHER_NAME_SIZE) == 0 )
        return 8 ;
    else if (strncasecmp(cipher_name,"MCRYPT_XTEA",CIPHER_NAME_SIZE) == 0 ) 
        return 9 ;
    else if (strncasecmp(cipher_name,"MCRYPT_RC2_1024",CIPHER_NAME_SIZE) == 0 ) 
        return 11 ;
    else if (strncasecmp(cipher_name,"MCRYPT_TWOFISH_128",CIPHER_NAME_SIZE) == 0 )
        return 10 ;
    else if (strncasecmp(cipher_name,"MCRYPT_TWOFISH_192",CIPHER_NAME_SIZE) == 0 )
        return 12 ;
    else if (strncasecmp(cipher_name,"MCRYPT_TWOFISH_256",CIPHER_NAME_SIZE) == 0 )
        return 13 ;
    else if (strncasecmp(cipher_name,"MCRYPT_BLOWFISH_128",CIPHER_NAME_SIZE) == 0 )
        return 14 ;
    else if (strncasecmp(cipher_name,"MCRYPT_BLOWFISH_192",CIPHER_NAME_SIZE) == 0 )
        return 15 ;
    else if (strncasecmp(cipher_name,"MCRYPT_BLOWFISH_256",CIPHER_NAME_SIZE) == 0 )
        return 16 ;
    else if (strncasecmp(cipher_name,"MCRYPT_CAST_256",CIPHER_NAME_SIZE) == 0 )
        return 17 ;
    else if (strncasecmp(cipher_name,"MCRYPT_SAFERPLUS",CIPHER_NAME_SIZE) == 0 )
        return 18 ;
    else if (strncasecmp(cipher_name,"MCRYPT_LOKI97",CIPHER_NAME_SIZE) == 0 ) 
        return 19 ;
    else if (strncasecmp(cipher_name,"MCRYPT_SERPENT_128",CIPHER_NAME_SIZE) == 0 )
        return 20 ;
    else if (strncasecmp(cipher_name,"MCRYPT_SERPENT_192",CIPHER_NAME_SIZE) == 0 )
        return 21 ;
    else if (strncasecmp(cipher_name,"MCRYPT_SERPENT_256",CIPHER_NAME_SIZE) == 0 )
        return 22 ;
    else if (strncasecmp(cipher_name,"MCRYPT_RIJNDAEL_128",CIPHER_NAME_SIZE) == 0 ) 
        return 23 ;
    else if (strncasecmp(cipher_name,"MCRYPT_RIJNDAEL_192",CIPHER_NAME_SIZE) == 0 )
        return 24 ;
    else if (strncasecmp(cipher_name,"MCRYPT_RIJNDAEL_256",CIPHER_NAME_SIZE) == 0 )
        return 25 ;
    else if (strncasecmp(cipher_name,"MCRYPT_RC2_256",CIPHER_NAME_SIZE) == 0 )
        return 26 ;
    else if (strncasecmp(cipher_name,"MCRYPT_RC2_128",CIPHER_NAME_SIZE) == 0 )
        return 27 ;
    else if (strncasecmp(cipher_name,"MCRYPT_CRYPT",CIPHER_NAME_SIZE) == 0 ) 
        return 28 ;
    else if (strncasecmp(cipher_name,"MCRYPT_RC6_256",CIPHER_NAME_SIZE) == 0 ) 
        return 100 ;
    else if (strncasecmp(cipher_name,"MCRYPT_IDEA",CIPHER_NAME_SIZE) == 0 ) 
        return 101 ;
    else if (strncasecmp(cipher_name,"MCRYPT_RC6_128",CIPHER_NAME_SIZE) == 0 ) 
        return 102 ;
    else if (strncasecmp(cipher_name,"MCRYPT_RC6_192",CIPHER_NAME_SIZE) == 0 ) 
        return 103 ;
    // MCRYPT_RC4 AND MCRYPT_ARCFOUR are the same.
    else if (strncasecmp(cipher_name,"MCRYPT_RC4",CIPHER_NAME_SIZE) == 0 ) 
        return 104 ;
    else if (strncasecmp(cipher_name,"MCRYPT_ARCFOUR",CIPHER_NAME_SIZE) == 0 ) 
        return 104 ;
    else
        // MCRYPT_BLOWFISH_448 is the default
        return 0 ;    
}
# endif 
