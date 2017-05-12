#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include "epcrypto.h"

#if EPC_ENABLE

#include <openssl/evp.h>

 


int do_crypt_file(FILE *    in, 
                  FILE *    out, 
                  char *    output, 
                  int       outsize, 
                  int       do_encrypt, 
                  unsigned char * begin, 
                  unsigned char * header)

    {
    char inbuf[1024], outbuf[1024 + 8192];  /*EVP_MAX_BLOCK_LENGTH*/
    int inlen, outlen;
    int blen = 0 ;
    int outcnt = 0 ;    
    unsigned char * key = EPC_KEY ;
    unsigned char * iv  = "\0x01\0x02\0x03\0x04\0x05\0x06\0x07\0x08" ;
    EVP_CIPHER_CTX  ctx ;
    int klen ;
    int ivlen ;

    
    if (output && do_encrypt)
        return -3 ; /* not supported */
    
    /*
    printf("%d %d %d\n", EVP_MAX_IV_LENGTH, EVP_MAX_BLOCK_LENGTH, ((char*)&ctx.key_len) - ((char *)&ctx)) ;

    for (blen = 0; blen < EPC_KEYLEN;blen++)
         printf("n=%d = %x\n", blen, key[blen]) ;
    */
    
    EVP_CIPHER_CTX_init(&ctx) ;
    
    /*
    EVP_CipherInit(&ctx, EPC_CHIPER, NULL, NULL, do_encrypt);
        
    for (blen = 0; blen < sizeof(ctx);blen++)
        printf("n=%d = %x\n", blen, ((unsigned char *)(&ctx))[blen])
;

    klen = EVP_CIPHER_CTX_key_length(&ctx) ;
    ivlen = EVP_CIPHER_CTX_iv_length(&ctx) ;
        
    printf ("1 chiper=%s klen=%d ivlen=%d\n",
    EVP_CIPHER_CTX_cipher(&ctx), klen, ivlen) ;
    EVP_CIPHER_CTX_set_key_length(&ctx, EPC_KEYLEN);
    klen = EVP_CIPHER_CTX_key_length(&ctx) ;
    ivlen = EVP_CIPHER_CTX_iv_length(&ctx) ;
            

    printf ("2 chiper=%s klen=%d ivlen=%d\n",
    EVP_CIPHER_CTX_cipher(&ctx), klen, ivlen) ;
    */
    
    
    EVP_CipherInit(&ctx, EPC_CHIPER, key, iv, do_encrypt);
    
    EVP_CIPHER_CTX_set_key_length(&ctx, EPC_KEYLEN);
        
    klen = EVP_CIPHER_CTX_key_length(&ctx) ;
    ivlen = EVP_CIPHER_CTX_iv_length(&ctx) ;
                
    if (klen > EPC_KEYLEN || ivlen > 8)
        return -6 ;
        
    if (header)
        {
        int hlen = strlen(header) ;

        if (!do_encrypt)
            {
            inlen = fread(inbuf, 1, hlen, in);
            if (hlen != inlen || memcmp (inbuf, header, hlen) != 0)
                return -1 ; /* wrong header */
            }
        else
            fwrite(header, 1, hlen, out);
        }
    
    if (begin)
        {
        blen = strlen(begin) ;

        if (do_encrypt)
            {
            EVP_CipherUpdate(&ctx, outbuf, &outlen, begin, blen) ;
            fwrite(outbuf, 1, outlen, out);
            }
        }
        
    
    for(;;)
        {
        inlen = fread(inbuf, 1, 1024, in);
        if(inlen <= 0) 
	    break;
        
	EVP_CipherUpdate(&ctx, outbuf, &outlen, inbuf, inlen) ;
        
	if (blen && !do_encrypt && blen <= outlen)
            {
            if (memcmp (outbuf, begin, blen) != 0)
                return -2 ; /* wrong begin */
	    
	    if (blen < outlen)
		{
		if (output)
		    {
		    if (outcnt + outlen - blen > outsize)
			return -4 ; /* buffer overflow */
		    memcpy(output, outbuf + blen, outlen - blen) ;
		    output += outlen - blen ;
		    }
		else
		    {
		    if (blen < outlen)
			fwrite(outbuf + blen, 1, outlen - blen, out);
		    }
		}
            outcnt += outlen - blen ;
            blen = 0 ;
            }
        else
            {
            if (output)
                {
                if (outcnt + outlen > outsize)
                    return -4 ; /* buffer overflow */
                memcpy(output, outbuf, outlen) ;
                output += outlen ;
                }
            else
                {
                fwrite(outbuf, 1, outlen, out);
                }
            outcnt += outlen ;
            }

        }
    if(!EVP_CipherFinal(&ctx, outbuf, &outlen))
        return -5; /* error */

    if (output)
        {
        if (outcnt + outlen > outsize)
            return -4 ; /* buffer overflow */
        memcpy(output, outbuf, outlen) ;
        output += outlen ;
        }
    else
        {
        fwrite(outbuf, 1, outlen, out);
        }
    outcnt += outlen ;

    EVP_CIPHER_CTX_cleanup(&ctx);
    return outcnt ;
    }
    

#endif
  
            

#ifndef XS_VERSION

int main (int argc, char *argv[])

    {
#if EPC_ENABLE
    FILE * ifd ;
    FILE * ofd ;
    char * syntax = "Embperl" ;
    int rc ;
#endif

    puts ("\nEmbperl encryption tool / Vers. 1.0 / (c) 2001 G.Richter ecos gmbh\n") ;
    

#if EPC_ENABLE == 0

    puts ("\nEncryption not enabled! see crypto/epcrypt_config.h\n") ;
    exit (1) ;

#else


    if (argc < 3)
        {
        puts ("Usage: epcrypto <inputfile> <outputfile> [<syntax>] [<decrypt>]") ;
        puts ("       syntax defaults to 'Embperl'") ;
        puts ("       decrypt defaults to false") ;
        exit (1) ;
        }

    if (argc > 3)
        syntax = argv[3] ;

    if (!(ifd = fopen (argv[1], "r")))
        {
        printf ("Cannot open '%s' for reading (%s)\n", argv[1], strerror( errno ) ) ;
        exit (1) ;
        }


    if (!(ofd = fopen (argv[2], "w")))
        {
        printf ("Cannot open '%s' for writing (%s)\n", argv[2], strerror( errno ) ) ;
        exit (1) ;
        }

    if ((rc = do_crypt_file (ifd, ofd, NULL, 0, argc > 4 && argv[4][0] != '\0' && argv[4][0] != '0'?0:1, syntax, EPC_HEADER)) <= 0)
        {
        if (rc == -1)
            {
            printf ("'%s' is not an Embperl encrypted file\n", argv[1]) ;
            }
        else if (rc == -2)
            {
            printf ("'%s' is wrong Syntax for '%s'\n", syntax, argv[1]) ;
            }
        printf ("Error while processing '%s' (%s)\n", argv[1], strerror( errno ) ) ;
        exit (1) ;
        }
    

    return 0 ;
#endif

    }


#endif

