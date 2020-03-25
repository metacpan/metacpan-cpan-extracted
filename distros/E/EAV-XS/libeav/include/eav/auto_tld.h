/* this file was auto-generated at 2020-03-24 13:10:53 */


#ifndef TLD_H
#define TLD_H


typedef struct tld_s {
    const char  *domain;
    size_t      length;
    int         type;
} tld_t;

enum {
    TLD_TYPE_UNUSED, /* tests only */
    TLD_TYPE_NOT_ASSIGNED,
    TLD_TYPE_COUNTRY_CODE,
    TLD_TYPE_GENERIC,
    TLD_TYPE_GENERIC_RESTRICTED,
    TLD_TYPE_INFRASTRUCTURE,
    TLD_TYPE_SPONSORED,
    TLD_TYPE_TEST,
    TLD_TYPE_SPECIAL,
    TLD_TYPE_MAX /* tests only */
};

extern const tld_t tld_list[];

#endif /* TLD_H */

