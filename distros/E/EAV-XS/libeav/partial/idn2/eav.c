#include <stdio.h>
#include <stdlib.h>
#include <idn2.h>
#include <eav.h>
#include <eav/private.h>
#include <eav/auto_tld.h>


static int
init_idn (eav_t *eav)
{
    if (eav->initialized)
        return EEAV_NO_ERROR;

    eav->initialized = true;

    return EEAV_NO_ERROR;
}


extern int
eav_setup (eav_t *eav)
{
    switch (eav->rfc) {
    case EAV_RFC_822:   eav->ascii_cb = is_822_email;    break;
    case EAV_RFC_5321:  eav->ascii_cb = is_5321_email;   break;
    case EAV_RFC_5322:  eav->ascii_cb = is_5322_email;   break;
    case EAV_RFC_6531:
        eav->utf8 = true;
        eav->utf8_cb = is_6531_email;
        return init_idn (eav);
    default:
        return EEAV_INVALID_RFC;
    }

    if (eav->initialized) {
        eav->initialized = false;
    }

    /* always set this */
    eav->utf8 = false;

    return EEAV_NO_ERROR;
}


extern int
eav_is_email (eav_t *eav, const char *email, size_t length)
{
    bool tld_test = false;

    /* mark that there is not idn error*/
    if (eav->idnmsg)
        eav->idnmsg = NULL;

    if (eav->utf8)
        eav->result = eav->utf8_cb (email, length, eav->tld_check);
    else
        eav->result = eav->ascii_cb (email, length, eav->tld_check);

    if (eav->result.rc == 0) {
        eav->errcode = EEAV_NO_ERROR;
        return (YES);
    }

    if (eav->result.rc < 0) {
        eav->errcode = inverse(eav->result.rc);

        if (eav->errcode == EEAV_IDN_ERROR) {
            eav->idnmsg = idn2_strerror (eav->result.idn_rc);
        }

        return (NO);
    }

    /* user tld preferences */
    switch (eav->result.rc) {
    case TLD_TYPE_NOT_ASSIGNED:
        eav->errcode = EEAV_TLD_NOT_ASSIGNED;
        tld_test = (eav->allow_tld & EAV_TLD_NOT_ASSIGNED);
        break;
    case TLD_TYPE_COUNTRY_CODE:
        eav->errcode = EEAV_TLD_COUNTRY_CODE;
        tld_test = (eav->allow_tld & EAV_TLD_COUNTRY_CODE);
        break;
    case TLD_TYPE_GENERIC:
        eav->errcode = EEAV_TLD_GENERIC;
        tld_test = (eav->allow_tld & EAV_TLD_GENERIC);
        break;
    case TLD_TYPE_GENERIC_RESTRICTED:
        eav->errcode = EEAV_TLD_GENERIC_RESTRICTED;
        tld_test = (eav->allow_tld & EAV_TLD_GENERIC_RESTRICTED);
        break;
    case TLD_TYPE_INFRASTRUCTURE:
        eav->errcode = EEAV_TLD_INFRASTRUCTURE;
        tld_test = (eav->allow_tld & EAV_TLD_INFRASTRUCTURE);
        break;
    case TLD_TYPE_SPONSORED:
        eav->errcode = EEAV_TLD_SPONSORED;
        tld_test = (eav->allow_tld & EAV_TLD_SPONSORED);
        break;
    case TLD_TYPE_TEST:
        eav->errcode = EEAV_TLD_TEST;
        tld_test = (eav->allow_tld & EAV_TLD_TEST);
        break;
    case TLD_TYPE_SPECIAL:
        eav->errcode = EEAV_TLD_SPECIAL;
        tld_test = (eav->allow_tld & EAV_TLD_SPECIAL);
        break;
    default:
        /* should not happen */
        abort ();
    };

    if (tld_test) {
        eav->errcode = EEAV_NO_ERROR;
        return (YES);
    }

    return (NO);
}


extern void
eav_init (eav_t *eav)
{
    eav->utf8 = false;
    eav->rfc = EAV_RFC_6531;
    eav->tld_check = true;
    eav->allow_tld =    EAV_TLD_COUNTRY_CODE |
                        EAV_TLD_GENERIC |
                        EAV_TLD_GENERIC_RESTRICTED |
                        EAV_TLD_INFRASTRUCTURE |
                        EAV_TLD_SPONSORED |
                        EAV_TLD_SPECIAL;
    eav->utf8_cb = NULL;
    eav->ascii_cb = NULL;
    eav->initialized = false;
    eav->errcode = EEAV_NO_ERROR;
}


extern void
eav_free (eav_t *eav)
{
    (void)(eav);
}

