#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#include "openssl/objects.h"
#include "openssl/rsa.h"

#include "openssl/err.h"
#include "openssl/x509.h"
#include "openssl/x509_vfy.h"
#include "openssl/pem.h"
#include "openssl/bio.h"
#include "openssl/sha.h"

MODULE = ELF::sign      PACKAGE = ELF::sign

PKCS7 *
PEM_read_bio_PKCS7(bp, x, cb, u)
   BIO *	bp
   PKCS7 **	x
   pem_password_cb *cb
   void *u

unsigned char*
datasign(data, certificate, privateKey)
      SV* data;
      X509 *certificate;
      EVP_PKEY *privateKey;
   CODE:
      unsigned long bufLength = 0;
      unsigned char *buf = NULL;
      int64_t filesize = 0;
      PKCS7 *sig7 = NULL;
      BIO *sigRaw = BIO_new(BIO_s_mem()), *digestRaw = NULL;
      const EVP_MD * digestSha512 = NULL;

      ST(0) = sv_newmortal();
      STRLEN datalen;
      char * dataptr = SvPVbyte(data, datalen);
      if (!(digestRaw = BIO_new_mem_buf(dataptr, datalen))) {
         sv_setpv(ST(0), 0);
         //sv_setpvn(ST(0), "BIO_new_mem_buf", 15);
         goto end;
      }
      int flags = 0x00 | PKCS7_NOSMIMECAP | PKCS7_BINARY | PKCS7_STREAM; // | PKCS7_DETACHED;
      sig7 = PKCS7_sign(NULL, NULL, NULL, digestRaw, flags);
      if (!sig7) {
         sv_setpv(ST(0), 0);
         //sv_setpvn(ST(0), "PKCS7_sign", 10);
         goto end;
      }
      digestSha512 = EVP_get_digestbyname("SHA512");
      PKCS7_sign_add_signer(sig7, certificate, privateKey, digestSha512, flags);
      PKCS7_final(sig7, digestRaw, flags);
      if (!PEM_write_bio_PKCS7(sigRaw, sig7)) {
         sv_setpv(ST(0), 0);
         //sv_setpvn(ST(0), "PEM_write_bio_PKCS7", 19);
         goto end;
      }
      bufLength = BIO_get_mem_data(sigRaw, &buf);
      sv_setpvn(ST(0), buf, bufLength);
      end:
         if (sigRaw)
            BIO_free(sigRaw);
         if (digestRaw)
            BIO_free(digestRaw);
         if (sig7)
            PKCS7_free(sig7);

unsigned char*
dataverify(data, certificate, p7)
      SV* data;
      X509 *certificate;
      PKCS7 *p7;
   CODE:
      BIO *digestRaw = NULL;
      STACK_OF(PKCS7_SIGNER_INFO) *signerStack = NULL;
      int64_t filesize = 0;
      PKCS7_SIGNER_INFO *si;
      int i;
      char buf[64*1024];

      ST(0) = sv_newmortal();
      STRLEN datalen;
      char * dataptr = SvPVbyte(data, datalen);
      if (!(digestRaw = BIO_new_mem_buf(dataptr, datalen))) {
        sv_setpvn(ST(0), "BIO_new_mem_buf", 15);
        goto end;
      }
      signerStack = PKCS7_get_signer_info(p7);
      if (signerStack == NULL) {
         sv_setpvn(ST(0), "No signatures", 15);
         goto end;
      }
      BIO * p7bio=PKCS7_dataInit(p7,digestRaw);
      for (;;) {
          i=BIO_read(p7bio,buf,sizeof(buf));
          if (i <= 0) break;
      }
      for (i=0; i<sk_PKCS7_SIGNER_INFO_num(signerStack); i++) {
         ASN1_UTCTIME *tm;
         char *str1,*str2;
         int rc;
         si = sk_PKCS7_SIGNER_INFO_value(signerStack,i);
         //printf("Verifying\n");
         // TODO:XXX:FIXME: Das prueft nur obs vom angegebenen Certificat ist, nicht aber ob das zu einer CA passt!
         // ... vermutlich wie in http://docs.huihoo.com/doxygen/openssl/1.0.1c/pk7__doit_8c_source.html#l00960 ?
         if ((rc= PKCS7_signatureVerify(p7bio, p7, si, certificate)) != 1) {
            unsigned long err = 0;
            err = ERR_get_error();
            if (err == 0) {
               sv_setpvn(ST(0), "PKCS7_signatureVerify: No get_error", 35);
            } else {
               char error[200];
               snprintf(error, sizeof(error), "Verify failed num=%d error=%s", err, ERR_error_string(err, 0));
               sv_setpvn(ST(0), error, strlen(error));
            }
            goto end;
         }
      }

      sv_setpv(ST(0), 0);
      end:
      if (p7bio)
         BIO_free(p7bio);
      if (digestRaw)
         BIO_free(digestRaw);
      if (p7)
         PKCS7_free(p7);
