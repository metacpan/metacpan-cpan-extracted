/*
 *
 * Copyright 2000 Frey Kuo.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the same terms as Perl itself.
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define _TESTING_ 0

MODULE = MCrypt		PACKAGE = MCrypt		

char *
_mcrypt_cbc(cipher, key, data, mode, IV = NULL, conv_hex = 0)
        int  cipher
        char * key
        char * data
        int    mode
	char * IV
        int conv_hex
	PROTOTYPE: $$$$;$;$
CODE:
          {
            int HAS_IV = 0 ;
            int encrypt = 0 ;
            int IV_len ;
            int blocksize ;
            char *return_string;
            
	    if(conv_hex == 1 && !is_hex(data,strlen(data)) && !mode)
	    {
		croak("mcrypt_cbc: non hex characters detected when in hex mode!\n") ;
	    }
            if(mode == 1)
	    {
		encrypt = 1 ;
		if(_TESTING_) printf("ENCrypting using cipher = %d.\n",cipher) ;
	    }   else {
		if(_TESTING_) printf("DECrypting using cipher = %d.\n",cipher) ;
		encrypt = 0 ;
	    }
            if(data == NULL || key == NULL )
                croak("mcrypt_cbc: Please supply a non-null value for data or key.") ;
            
            if(IV != NULL)
	    {
		if(!(IV_len = strlen(IV))) {
		    IV = NULL ;
		} else {
		    blocksize = pmcrypt_get_block_size(cipher) ;    
		    if(IV_len != blocksize) 
			croak("mcrypt_cbc: The blocksize is %d bytes for this cipher, the IV length must match it.\n", blocksize) ;
		}
	    }
            
            //printf("XS: data = %s, key = %s\n",data,key) ;
	    
            return_string = (char *)pmcrypt_cbc( cipher, key, data, mode, IV, (int)conv_hex ? 1 : 0 );
            RETVAL = return_string;
          }
OUTPUT:
        RETVAL

char *
_mcrypt_ecb(cipher, key, data, mode, conv_hex = 0)
        int  cipher
        char * key
        char * data
        int    mode
        int conv_hex
  PROTOTYPE: $$$$;$
CODE:
          {
	    int encrypt = 0 ;
            char *return_string;
	    
	    if(mode == 1)
	      {
		encrypt = 1 ;
		if(_TESTING_) printf("ENCrypting using cipher = %d.\n",cipher) ;
	      }   else {
		if(_TESTING_) printf("DECrypting using cipher = %d.\n",cipher) ;
		encrypt = 0 ;
	      }
	    if(data == NULL || key == NULL )
	    croak("mcrypt_ecb: Please supply a non-null value for data or key.") ;

	    //printf("XS: data = %s, key = %s\n",data,key) ;
            return_string = (char *)pmcrypt_ecb( cipher, key, data, mode, (int)conv_hex ? 1 : 0 );
	    RETVAL = return_string;
        }
OUTPUT:
        RETVAL

char *
_mcrypt_ofb(cipher, key, data, mode, IV, conv_hex = 0 )
        int  cipher
        char * key
        char * data
        int    mode
	char * IV
        int conv_hex
	PROTOTYPE: $$$$$;$
CODE:
          {
	    int HAS_IV = 0 ;
	    int encrypt = 0 ;
	    int IV_len ;
            int blocksize ;
	    char *return_string;
	    
	    if(mode == 1)
	      {
		encrypt = 1 ;
		if(_TESTING_) printf("ENCrypting using cipher = %d.\n",cipher) ;
	      }   else {
		if(_TESTING_) printf("DECrypting using cipher = %d.\n",cipher) ;
		encrypt = 0 ;
	      }
	    if(data == NULL || key == NULL || IV == NULL )
                croak("mcrypt_ofb: Please supply a non-null value for data or key or IV.") ;
            
	    blocksize = pmcrypt_get_block_size(cipher) ;
	    if(strlen(IV) != blocksize)
		croak("mcrypt_ofb: The blocksize is %d bytes for this cipher, the IV length must match it.\n", blocksize) ;
	    
	    //printf("XS: data = %s, key = %s\n",data,key) ;
            return_string = (char *)pmcrypt_ofb( cipher, key, data, mode, IV, conv_hex ? 1 : 0 );
	    RETVAL = return_string;
        }
OUTPUT:
        RETVAL

char *
_mcrypt_cfb(cipher, key, data, mode, IV, conv_hex = 0)
        int  cipher
        char * key
        char * data
        int    mode
	char * IV
        int conv_hex
	PROTOTYPE: $$$$$;$
CODE:
          {
	    int HAS_IV = 0 ;
	    int encrypt = 0 ;
	    int IV_len ;
	    int blocksize ;
            char *return_string;
	    
	    if(mode == 1)
	    {
		encrypt = 1 ;
		if(_TESTING_) printf("ENCrypting using cipher = %d.\n",cipher) ;
	    }   else {
		if(_TESTING_) printf("DECrypting using cipher = %d.\n",cipher) ;
		encrypt = 0 ;
	    }
	    if( data == NULL || key == NULL || IV == NULL )
		croak("mcrypt_cfb: Please supply a non-null value for data or key or IV.") ;
	    
	    blocksize = pmcrypt_get_block_size(cipher) ;
	    if(strlen(IV) != blocksize)
		croak("mcrypt_cfb: The blocksize is %d bytes for this cipher, the IV length must match it.\n",blocksize) ;
	    
	    //printf("XS: data = %s, key = %s\n",data,key) ;
            return_string = (char *)pmcrypt_cfb( cipher, key, data, mode, IV, conv_hex ? 1 :0 );
	    RETVAL = return_string;
        }
OUTPUT:
        RETVAL

char *
mcrypt_get_cipher_name(cipher)
         int cipher
         PROTOTYPE: $
CODE:
          {
	      RETVAL = (char *) pmcrypt_get_cipher_name(cipher) ;
	  }
OUTPUT:
       RETVAL

int
mcrypt_get_key_size(cipher)
         int cipher
         PROTOTYPE: $
CODE:
         {
	     RETVAL = (int) pmcrypt_get_key_size(cipher) ;
	 }
OUTPUT:
         RETVAL

int 
mcrypt_get_block_size(cipher)
         int cipher
         PROTOTYPE: $
CODE:
         {
	     RETVAL = (int) pmcrypt_get_block_size( cipher ) ;
	 }
OUTPUT:
         RETVAL
