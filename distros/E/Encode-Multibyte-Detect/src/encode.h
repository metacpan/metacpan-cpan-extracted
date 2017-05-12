#ifndef __ENCODE_H
#define __ENCODE_H

#include <stddef.h>

#define ENC_CHECK_BREAK_ON_BAD          0x00000001
#define ENC_CHECK_BREAK_ON_STRANGE      0x00000002

void utf8_check(const char *str, int *good, int *bad, int *strange, int flags);
void utf8_check_mem(const void *str, size_t size, int *good, int *bad, int *strange, int flags);

void euc_cn_check(const char *str, int *good, int *bad, int *strange, int flags);
void euc_cn_check_mem(const void *str, size_t size, int *good, int *bad, int *strange, int flags);

void euc_jp_check(const char *str, int *good, int *bad, int *strange, int flags);
void euc_jp_check_mem(const void *str, size_t size, int *good, int *bad, int *strange, int flags);

void euc_kr_check(const char *str, int *good, int *bad, int *strange, int flags);
void euc_kr_check_mem(const void *str, size_t size, int *good, int *bad, int *strange, int flags);

void euc_tw_check(const char *str, int *good, int *bad, int *strange, int flags);
void euc_tw_check_mem(const void *str, size_t size, int *good, int *bad, int *strange, int flags);

#endif //__ENCODE_H
