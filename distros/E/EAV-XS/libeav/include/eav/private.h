#ifndef IS_LOCAL_H
#define IS_LOCAL_H

#include <ctype.h>

#define ISASCII(c) isascii(_UCHAR_(c))
#define _UCHAR_(c) ((unsigned char)(c))
#define ISCNTRL(c) (ISASCII(c) && iscntrl(_UCHAR_(c)))
#define ISDIGIT(c) (ISASCII(c) && isdigit(_UCHAR_(c)))
#define ISALNUM(c) (ISASCII(c) && isalnum(_UCHAR_(c)))

#define YES (1)
#define NO  (0)

#define inverse(x) (-1 * (x))

#define DOMAIN_SIZE (1024)

#define ARRAY_SIZE(a) (sizeof(a)/sizeof(a[0]))

#define VALID_HOSTNAME_LEN  255 /* RFC 1035 */
#define VALID_LABEL_LEN     63  /* RFC 1035 */
#define VALID_LPART_LEN     64  /* RFC 5321 */

#endif /* IS_LOCAL_H */
