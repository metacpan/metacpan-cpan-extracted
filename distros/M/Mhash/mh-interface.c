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
#include <mhash.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#define _TESTING_ 0

static char hexconvtab[] = "0123456789abcdef";
static unsigned char *
bin2hex( const unsigned char *old, const size_t oldlen ) 
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

/* Get the name of the specified hash */
char *
pmhash_get_hash_name( int hash )
{
    char *hash_name = NULL ;
    char *retval    = NULL ;  
    
    hash_name = mhash_get_hash_name(hash) ;

    if( !hash_name ) {
        return NULL ;
    }
    retval = strdup(hash_name) ;
    free(hash_name) ;
    return( retval ) ;
}

/* Get the block size of the specified hash */
int
pmhash_get_block_size(int hash)
{
    return(mhash_get_block_size(hash));
}

/* Get the number of available hashes */
int
pmhash_count()
{
    return(mhash_count());
}

char *
pmhash(int hash, char *data, int conv_hex)
{
    MHASH td ;
    unsigned char *hashdata = NULL ;
    unsigned char *retval   = NULL ;
    int blocksize           = 0 ;
    
    if(!data || hash < 0)
        return NULL ;

    blocksize = mhash_get_block_size(hash) ;
    td = mhash_init(hash) ;
    if(td == MHASH_FAILED) {
        // we should produce an error
        return NULL ;
    }
    mhash(td, data, strlen(data)) ;
    hashdata = mhash_end(td) ;
    
    if(hashdata) {
        retval = strdup(hashdata);
        free(hashdata) ;
        return ( ( conv_hex ? bin2hex(retval,blocksize) : retval)) ;
    } else {
        return NULL ;
    }
}

char *
pmhash_hmac(int hash, char *data, char *key, int conv_hex)
{
    MHASH td ;
    unsigned char *mac    = NULL ;
    unsigned char *retval = NULL ;
    int blocksize         = 0 ;

    blocksize = mhash_get_block_size(hash) ;
    td = mhash_hmac_init(hash, key, strlen(key),
                         mhash_get_hash_pblock(hash)) ;
    if(td == MHASH_FAILED) {
        return NULL ;
    }
    
    mhash(td, data, strlen(data));
    mac = mhash_hmac_end(td);

    if(mac) {
        retval = strdup(mac);
        free(mac) ;
        return(conv_hex ? bin2hex(retval,blocksize) : retval);
    } else {
        return NULL ;
    }
}

#if _TESTING_
int
main() {

    int i, j, len, blocksize, num_hashes ;  
    MHASH td ;
    unsigned char *hash ;
    unsigned char *mac ;
    char text[] = "what do ya want for nothing?";
    char key[]  = "Jefe" ;
    char *hash_name ;

    /* HMAC(MD5) should be 750c783e6ab0b503eaa86e310a5db738
       according to RFC 2104 */
    
    num_hashes = mhash_count() ;

    printf("num_hashes = %d\n",num_hashes) ;
    
    for(i = 0; i <= num_hashes; i++) {
        hash_name=mhash_get_hash_name(i) ;
        if(hash_name) {
            blocksize = mhash_get_block_size(i);
            printf("[%d]MHASH_%s(%d): ", i,hash_name,blocksize) ;
        
        td = mhash_init(i) ;
        if (td == MHASH_FAILED) exit(1);
        mhash(td,text,strlen(text)) ;
        hash = mhash_end(td);
        
        for(j=0;j<blocksize;j++) 
            printf("%.2x",hash[j]);
        printf("\n");
        
        //printf("%s (%d bytes)\n\n",hash,strlen(hash)) ;
        free(hash);
        }
    }
    printf("\n=========== H M A C ===================\n") ;
    
    for(i = 0; i <= num_hashes; i++) {
        hash_name=mhash_get_hash_name(i) ;
        if(hash_name) {
            blocksize = mhash_get_block_size(i);
            printf("[%d]MHASH_%s (HMAC): ", i,hash_name) ;
            
        td = mhash_hmac_init(i,key,strlen(key),mhash_get_hash_pblock(i)) ;
        if (td == MHASH_FAILED) exit(1);
        mhash(td,text,strlen(text)) ;
        mac = mhash_hmac_end(td);
        
        for(j=0;j<blocksize;j++) 
            printf("%.2x",mac[j]);
        printf("\n");
        
        //printf("%s (%d bytes)\n\n",mac,strlen(mac)) ;
        free(mac);
        }
    }
    
  return 0;
}
# endif 
