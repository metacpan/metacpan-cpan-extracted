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

MODULE = Mhash		PACKAGE = Mhash		

char *
_mhash(hash, data, conv_hex = 0)
        int  hash
        char * data
	int conv_hex
	PROTOTYPE: $$;$
CODE:
          {
              int blocksize ;
              char *return_string;
              
              if(data == NULL ) 
              croak("mhash: Please supply a non-null value for data.") ;

              return_string = (char *) pmhash( hash, data, conv_hex );
              RETVAL = return_string;
          }
OUTPUT:
        RETVAL

char *
_mhash_hmac(hash, data, key, conv_hex = 0)
        int  hash
        char * data
	char * key
	int conv_hex
	PROTOTYPE: $$$;$
CODE:
          {
              int blocksize ;
              char *return_string;
              
              if(data == NULL || key == NULL ) 
              croak("mhash_hmac: Please supply a non-null value for data or key.") ;

              return_string = (char *) pmhash_hmac( hash, data, key, conv_hex );
              RETVAL = return_string;
          }
OUTPUT:
        RETVAL

char *
mhash_get_hash_name(hash)
         int hash
         PROTOTYPE: $
CODE:
          {
	      RETVAL = (char *) pmhash_get_hash_name(hash) ;
	  }
OUTPUT:
       RETVAL

int 
mhash_get_block_size(hash)
         int hash
         PROTOTYPE: $
CODE:
         {
	     RETVAL = (int) pmhash_get_block_size( hash ) ;
	 }
OUTPUT:
         RETVAL

int 
mhash_count()
         PROTOTYPE: 
CODE:
         {
	     RETVAL = (int) pmhash_count() ;
	 }
OUTPUT:
         RETVAL
