#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <openssl/evp.h>
#include <openssl/x509.h>
#include <openssl/x509v3.h>
#include <openssl/pem.h>
#include <openssl/err.h>
#include <openssl/bn.h>
#include <openssl/rsa.h>
#include <openssl/ec.h>
#include <openssl/ecdsa.h>
#include <openssl/obj_mac.h>
#include <string.h>

#if OPENSSL_VERSION_NUMBER >= 0x30000000L
#include <openssl/param_build.h>
#include <openssl/core_names.h>
#endif

static int generate_mock_cert(pTHX_ char **cert_pem_out, char **key_pem_out) {
    EVP_PKEY *pkey = NULL;
    EVP_PKEY_CTX *pctx = NULL;
    X509 *x509 = NULL;
    X509_NAME *name = NULL;
    BIO *cert_bio = NULL;
    BIO *key_bio = NULL;
    char *cert_pem = NULL;
    char *key_pem = NULL;
    long cert_len = 0;
    long key_len = 0;
    int ret = 0;

    pctx = EVP_PKEY_CTX_new_id(EVP_PKEY_RSA, NULL);
    if (!pctx) goto cleanup;
    if (EVP_PKEY_keygen_init(pctx) <= 0) goto cleanup;
    if (EVP_PKEY_CTX_set_rsa_keygen_bits(pctx, 2048) <= 0) goto cleanup;
    if (EVP_PKEY_keygen(pctx, &pkey) <= 0) goto cleanup;

    x509 = X509_new();
    if (!x509) goto cleanup;

    if (X509_set_version(x509, 2) <= 0) goto cleanup;

    if (ASN1_INTEGER_set(X509_get_serialNumber(x509), 1) <= 0) goto cleanup;

    if (!X509_gmtime_adj(X509_get_notBefore(x509), 0)) goto cleanup;
    if (!X509_gmtime_adj(X509_get_notAfter(x509), 31536000L)) goto cleanup;

    if (X509_set_pubkey(x509, pkey) <= 0) goto cleanup;

    name = X509_get_subject_name(x509);
    if (!name) goto cleanup;
    if (X509_NAME_add_entry_by_txt(name, "C", MBSTRING_ASC, (unsigned char*)"BE", -1, -1, 0) <= 0) goto cleanup;
    if (X509_NAME_add_entry_by_txt(name, "O", MBSTRING_ASC, (unsigned char*)"Test", -1, -1, 0) <= 0) goto cleanup;
    if (X509_NAME_add_entry_by_txt(name, "OU", MBSTRING_ASC, (unsigned char*)"Test", -1, -1, 0) <= 0) goto cleanup;
    if (X509_NAME_add_entry_by_txt(name, "CN", MBSTRING_ASC, (unsigned char*)"Test", -1, -1, 0) <= 0) goto cleanup;
    if (X509_set_issuer_name(x509, name) <= 0) goto cleanup;

    if (X509_sign(x509, pkey, EVP_sha256()) <= 0) goto cleanup;

    key_bio = BIO_new(BIO_s_mem());
    if (!key_bio) goto cleanup;
    if (PEM_write_bio_PrivateKey(key_bio, pkey, NULL, NULL, 0, NULL, NULL) <= 0) goto cleanup;
    key_len = BIO_get_mem_data(key_bio, &key_pem);

    cert_bio = BIO_new(BIO_s_mem());
    if (!cert_bio) goto cleanup;
    if (PEM_write_bio_X509(cert_bio, x509) <= 0) goto cleanup;
    cert_len = BIO_get_mem_data(cert_bio, &cert_pem);

    Newx(*cert_pem_out, cert_len + 1, char);
    memcpy(*cert_pem_out, cert_pem, cert_len);
    (*cert_pem_out)[cert_len] = '\0';

    Newx(*key_pem_out, key_len + 1, char);
    memcpy(*key_pem_out, key_pem, key_len);
    (*key_pem_out)[key_len] = '\0';
    memcpy(*key_pem_out, key_pem, key_len);
    (*key_pem_out)[key_len] = '\0';

    ret = 1;

cleanup:
    if (cert_bio) BIO_free(cert_bio);
    if (key_bio) BIO_free(key_bio);
    if (x509) X509_free(x509);
    if (pkey) EVP_PKEY_free(pkey);
    if (pctx) EVP_PKEY_CTX_free(pctx);
    return ret;
}

MODULE = Google::Auth   PACKAGE = Google::Auth

PROTOTYPES: ENABLE

SV *
generate_self_signed_cert()
    PREINIT:
        char *cert_pem = NULL;
        char *key_pem = NULL;
        HV *hv = NULL;
        SV *result = NULL;
    CODE:
        if (generate_mock_cert(aTHX_ &cert_pem, &key_pem)) {
            hv = newHV();
            hv_stores(hv, "cert", newSVpv(cert_pem, 0));
            hv_stores(hv, "key", newSVpv(key_pem, 0));
            result = newRV_noinc((SV *)hv);
            free(cert_pem);
            free(key_pem);
        } else {
            XSRETURN_UNDEF;
        }
        RETVAL = result;
    OUTPUT:
        RETVAL

SV *
load_rsa_pubkey(SV *n_sv, SV *e_sv)
    PREINIT:
        unsigned char *n_bin = NULL;
        unsigned char *e_bin = NULL;
        STRLEN n_len, e_len;
        EVP_PKEY *pkey = NULL;
        RSA *rsa = NULL;
        BIGNUM *n_bn = NULL;
        BIGNUM *e_bn = NULL;
        SV *retval = NULL;
    CODE:
        n_bin = (unsigned char *)SvPV(n_sv, n_len);
        e_bin = (unsigned char *)SvPV(e_sv, e_len);

 #if OPENSSL_VERSION_NUMBER >= 0x30000000L
        OSSL_PARAM_BLD *bld = OSSL_PARAM_BLD_new();
        OSSL_PARAM *params = NULL;
        EVP_PKEY_CTX *pctx = NULL;

        if (!bld) XSRETURN_UNDEF;

        n_bn = BN_bin2bn(n_bin, n_len, NULL);
        e_bn = BN_bin2bn(e_bin, e_len, NULL);
        if (!n_bn || !e_bn) {
            if (n_bn) BN_free(n_bn);
            if (e_bn) BN_free(e_bn);
            OSSL_PARAM_BLD_free(bld);
            XSRETURN_UNDEF;
        }

        if (!OSSL_PARAM_BLD_push_BN(bld, OSSL_PKEY_PARAM_RSA_N, n_bn) ||
            !OSSL_PARAM_BLD_push_BN(bld, OSSL_PKEY_PARAM_RSA_E, e_bn)) {
            BN_free(n_bn);
            BN_free(e_bn);
            OSSL_PARAM_BLD_free(bld);
            XSRETURN_UNDEF;
        }

        params = OSSL_PARAM_BLD_to_param(bld);
        pctx = EVP_PKEY_CTX_new_from_name(NULL, "RSA", NULL);
        if (pctx && params) {
            if (EVP_PKEY_fromdata_init(pctx) > 0) {
                EVP_PKEY_fromdata(pctx, &pkey, EVP_PKEY_PUBLIC_KEY, params);
            }
        }

        if (params) OSSL_PARAM_free(params);
        if (bld) OSSL_PARAM_BLD_free(bld);
        if (pctx) EVP_PKEY_CTX_free(pctx);
        BN_free(n_bn);
        BN_free(e_bn);

        if (!pkey) XSRETURN_UNDEF;
 #else
        rsa = RSA_new();
        if (!rsa) XSRETURN_UNDEF;

        n_bn = BN_bin2bn(n_bin, n_len, NULL);
        e_bn = BN_bin2bn(e_bin, e_len, NULL);
        if (!n_bn || !e_bn) {
            if (n_bn) BN_free(n_bn);
            if (e_bn) BN_free(e_bn);
            RSA_free(rsa);
            XSRETURN_UNDEF;
        }

        if (RSA_set0_key(rsa, n_bn, e_bn, NULL) <= 0) {
            BN_free(n_bn);
            BN_free(e_bn);
            RSA_free(rsa);
            XSRETURN_UNDEF;
        }

        pkey = EVP_PKEY_new();
        if (!pkey) {
            RSA_free(rsa);
            XSRETURN_UNDEF;
        }

        if (EVP_PKEY_assign_RSA(pkey, rsa) <= 0) {
            RSA_free(rsa);
            EVP_PKEY_free(pkey);
            XSRETURN_UNDEF;
        }
 #endif

        retval = newSViv(PTR2IV(pkey));
        retval = newRV_noinc(retval);
        sv_bless(retval, gv_stashpv("Google::Auth::PublicKey", 1));

        RETVAL = retval;
    OUTPUT:
        RETVAL

SV *
load_ec_pubkey(const char *curve_name, SV *x_sv, SV *y_sv)
    PREINIT:
        unsigned char *x_bin = NULL;
        unsigned char *y_bin = NULL;
        STRLEN x_len, y_len;
        EVP_PKEY *pkey = NULL;
        EC_KEY *eckey = NULL;
        EC_GROUP *group = NULL;
        EC_POINT *point = NULL;
        BIGNUM *x_bn = NULL;
        BIGNUM *y_bn = NULL;
        int nid;
        SV *retval = NULL;
    CODE:
        x_bin = (unsigned char *)SvPV(x_sv, x_len);
        y_bin = (unsigned char *)SvPV(y_sv, y_len);

        nid = EC_curve_nist2nid(curve_name);
        if (nid == NID_undef) {
            nid = OBJ_txt2nid(curve_name);
        }
        if (nid == NID_undef) XSRETURN_UNDEF;

 #if OPENSSL_VERSION_NUMBER >= 0x30000000L
        OSSL_PARAM_BLD *bld = OSSL_PARAM_BLD_new();
        OSSL_PARAM *params = NULL;
        EVP_PKEY_CTX *pctx = NULL;
        unsigned char point_bin[1 + 256];
        size_t point_len = 1 + x_len + y_len;

        if (!bld || point_len > sizeof(point_bin)) {
            if (bld) OSSL_PARAM_BLD_free(bld);
            XSRETURN_UNDEF;
        }

        point_bin[0] = 0x04;
        memcpy(point_bin + 1, x_bin, x_len);
        memcpy(point_bin + 1 + x_len, y_bin, y_len);

        if (!OSSL_PARAM_BLD_push_utf8_string(bld, OSSL_PKEY_PARAM_GROUP_NAME, (char *)curve_name, 0) ||
            !OSSL_PARAM_BLD_push_octet_string(bld, OSSL_PKEY_PARAM_PUB_KEY, point_bin, point_len)) {
            OSSL_PARAM_BLD_free(bld);
            XSRETURN_UNDEF;
        }

        params = OSSL_PARAM_BLD_to_param(bld);
        pctx = EVP_PKEY_CTX_new_from_name(NULL, "EC", NULL);
        if (pctx && params) {
            if (EVP_PKEY_fromdata_init(pctx) > 0) {
                EVP_PKEY_fromdata(pctx, &pkey, EVP_PKEY_PUBLIC_KEY, params);
            }
        }

        if (params) OSSL_PARAM_free(params);
        if (bld) OSSL_PARAM_BLD_free(bld);
        if (pctx) EVP_PKEY_CTX_free(pctx);

        if (!pkey) XSRETURN_UNDEF;
 #else
        eckey = EC_KEY_new();
        if (!eckey) XSRETURN_UNDEF;

        group = EC_GROUP_new_by_curve_name(nid);
        if (!group) {
            EC_KEY_free(eckey);
            XSRETURN_UNDEF;
        }

        if (EC_KEY_set_group(eckey, group) <= 0) {
            EC_GROUP_free(group);
            EC_KEY_free(eckey);
            XSRETURN_UNDEF;
        }

        point = EC_POINT_new(group);
        if (!point) {
            EC_GROUP_free(group);
            EC_KEY_free(eckey);
            XSRETURN_UNDEF;
        }

        x_bn = BN_bin2bn(x_bin, x_len, NULL);
        y_bn = BN_bin2bn(y_bin, y_len, NULL);
        if (!x_bn || !y_bn) {
            if (x_bn) BN_free(x_bn);
            if (y_bn) BN_free(y_bn);
            EC_POINT_free(point);
            EC_GROUP_free(group);
            EC_KEY_free(eckey);
            XSRETURN_UNDEF;
        }

        if (EC_POINT_set_affine_coordinates_GFp(group, point, x_bn, y_bn, NULL) <= 0) {
            BN_free(x_bn);
            BN_free(y_bn);
            EC_POINT_free(point);
            EC_GROUP_free(group);
            EC_KEY_free(eckey);
            XSRETURN_UNDEF;
        }

        if (EC_KEY_set_public_key(eckey, point) <= 0) {
            BN_free(x_bn);
            BN_free(y_bn);
            EC_POINT_free(point);
            EC_GROUP_free(group);
            EC_KEY_free(eckey);
            XSRETURN_UNDEF;
        }

        pkey = EVP_PKEY_new();
        if (!pkey) {
            BN_free(x_bn);
            BN_free(y_bn);
            EC_POINT_free(point);
            EC_GROUP_free(group);
            EC_KEY_free(eckey);
            XSRETURN_UNDEF;
        }

        if (EVP_PKEY_assign_EC_KEY(pkey, eckey) <= 0) {
            BN_free(x_bn);
            BN_free(y_bn);
            EC_POINT_free(point);
            EC_GROUP_free(group);
            EC_KEY_free(eckey);
            EVP_PKEY_free(pkey);
            XSRETURN_UNDEF;
        }

        BN_free(x_bn);
        BN_free(y_bn);
        EC_POINT_free(point);
        EC_GROUP_free(group);
 #endif

        retval = newSViv(PTR2IV(pkey));
        retval = newRV_noinc(retval);
        sv_bless(retval, gv_stashpv("Google::Auth::PublicKey", 1));

        RETVAL = retval;
    OUTPUT:
        RETVAL

SV *
load_pubkey_from_x509_cert(SV *cert_pem_sv)
    PREINIT:
        char *pem_str = NULL;
        STRLEN pem_len;
        BIO *bio = NULL;
        X509 *x509 = NULL;
        EVP_PKEY *pkey = NULL;
        SV *retval = NULL;
    CODE:
        pem_str = SvPV(cert_pem_sv, pem_len);
        bio = BIO_new_mem_buf(pem_str, pem_len);
        if (!bio) XSRETURN_UNDEF;

        x509 = PEM_read_bio_X509(bio, NULL, NULL, NULL);
        BIO_free(bio);
        if (!x509) XSRETURN_UNDEF;

        pkey = X509_get_pubkey(x509);
        X509_free(x509);
        if (!pkey) XSRETURN_UNDEF;

        retval = newSViv(PTR2IV(pkey));
        retval = newRV_noinc(retval);
        sv_bless(retval, gv_stashpv("Google::Auth::PublicKey", 1));
        
        RETVAL = retval;
    OUTPUT:
        RETVAL

int
verify_signature(SV *key_obj_sv, SV *message_sv, SV *signature_sv)
    PREINIT:
        EVP_PKEY *pkey = NULL;
        char *msg_str = NULL;
        char *sig_str = NULL;
        STRLEN msg_len, sig_len;
        EVP_MD_CTX *mdctx = NULL;
        int verify_res = 0;
        unsigned char *actual_sig = NULL;
        unsigned int actual_sig_len = 0;
        unsigned char *der_buf = NULL;
        ECDSA_SIG *ec_sig = NULL;
    CODE:
        if (sv_derived_from(key_obj_sv, "Google::Auth::PublicKey")) {
            IV tmp = SvIV((SV*)SvRV(key_obj_sv));
            pkey = INT2PTR(EVP_PKEY *, tmp);
        }
        if (!pkey) XSRETURN_NO;

        msg_str = SvPV(message_sv, msg_len);
        sig_str = SvPV(signature_sv, sig_len);

        actual_sig = (unsigned char *)sig_str;
        actual_sig_len = sig_len;

        if (EVP_PKEY_base_id(pkey) == EVP_PKEY_EC) {
            if (sig_len % 2 == 0) {
                int half_len = sig_len / 2;
                BIGNUM *r_bn = BN_bin2bn((unsigned char *)sig_str, half_len, NULL);
                BIGNUM *s_bn = BN_bin2bn((unsigned char *)sig_str + half_len, half_len, NULL);
                if (r_bn && s_bn) {
                    ec_sig = ECDSA_SIG_new();
                    if (ec_sig) {
                        ECDSA_SIG_set0(ec_sig, r_bn, s_bn);
                        int der_len = i2d_ECDSA_SIG(ec_sig, NULL);
                        if (der_len > 0) {
                            der_buf = (unsigned char *)malloc(der_len);
                            if (der_buf) {
                                unsigned char *p = der_buf;
                                i2d_ECDSA_SIG(ec_sig, &p);
                                actual_sig = der_buf;
                                actual_sig_len = der_len;
                            }
                        }
                    } else {
                        BN_free(r_bn);
                        BN_free(s_bn);
                    }
                }
            }
        }

        mdctx = EVP_MD_CTX_new();
        if (mdctx) {
            if (EVP_VerifyInit_ex(mdctx, EVP_sha256(), NULL) > 0 &&
                EVP_VerifyUpdate(mdctx, msg_str, msg_len) > 0) {
                verify_res = EVP_VerifyFinal(mdctx, actual_sig, actual_sig_len, pkey);
            }
            EVP_MD_CTX_free(mdctx);
        }

        if (ec_sig) ECDSA_SIG_free(ec_sig);
        if (der_buf) free(der_buf);

        if (verify_res > 0) {
            XSRETURN_YES;
        } else {
            XSRETURN_NO;
        }

SV *
rsa_sign_sha256(SV *private_key_pem_sv, SV *message_sv)
    PREINIT:
        char *pem_str = NULL;
        char *msg_str = NULL;
        STRLEN pem_len, msg_len;
        BIO *bio = NULL;
        EVP_PKEY *pkey = NULL;
        EVP_MD_CTX *mdctx = NULL;
        unsigned char sig[4096];
        unsigned int sig_len = 0;
        SV *retval = NULL;
    CODE:
        pem_str = SvPV(private_key_pem_sv, pem_len);
        msg_str = SvPV(message_sv, msg_len);

        bio = BIO_new_mem_buf(pem_str, pem_len);
        if (!bio) XSRETURN_UNDEF;

        pkey = PEM_read_bio_PrivateKey(bio, NULL, NULL, NULL);
        BIO_free(bio);
        if (!pkey) XSRETURN_UNDEF;

        mdctx = EVP_MD_CTX_new();
        if (!mdctx) {
            EVP_PKEY_free(pkey);
            XSRETURN_UNDEF;
        }

        if (EVP_SignInit_ex(mdctx, EVP_sha256(), NULL) <= 0 ||
            EVP_SignUpdate(mdctx, msg_str, msg_len) <= 0 ||
            EVP_SignFinal(mdctx, sig, &sig_len, pkey) <= 0) {
            EVP_MD_CTX_free(mdctx);
            EVP_PKEY_free(pkey);
            XSRETURN_UNDEF;
        }

        EVP_MD_CTX_free(mdctx);
        EVP_PKEY_free(pkey);

        retval = newSVpv((char *)sig, sig_len);
        RETVAL = retval;
    OUTPUT:
        RETVAL

MODULE = Google::Auth   PACKAGE = Google::Auth::PublicKey

void
DESTROY(self)
        SV *self
    PREINIT:
        EVP_PKEY *pkey = NULL;
    CODE:
        if (sv_derived_from(self, "Google::Auth::PublicKey")) {
            IV tmp = SvIV((SV*)SvRV(self));
            pkey = INT2PTR(EVP_PKEY *, tmp);
            if (pkey) {
                EVP_PKEY_free(pkey);
            }
        }
