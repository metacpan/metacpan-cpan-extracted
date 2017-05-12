
#include <xtables.h>

/* Since v1.4.9 this define is needed (commit 0cb675b8)
 *  Orig defined in linux/netfilter/x_tables.h since kernel v2.6.35-rc1
 */
#ifndef XT_EXTENSION_MAXNAMELEN
#define XT_EXTENSION_MAXNAMELEN 29
#endif

#if   XTABLES_VERSION_CODE == 1
#warning "This version of xtables is not recommended"
#warning " please upgrade to at least v1.4.3.2"
#include "iptables.c-v1.4.4"

/* libxtables version 2: commit c4edfa6
 *  Range iptables v1.4.3.2 - v.1.4.4
 */
#elif XTABLES_VERSION_CODE == 2
#include "iptables.c-v1.4.4"

/* libxtables version 3: commit 332e4acc
 *  iptables v1.4.5 only
 */
#elif XTABLES_VERSION_CODE == 3
#include "iptables.c-v1.4.5"

/* libxtables version 4: commit bf97128
 *  Range iptables v1.4.6 - v1.4.8
 */
#elif XTABLES_VERSION_CODE == 4
#include "iptables.c-v1.4.8"

/* libxtables version 5: commit 11c2dd54
 *  Range iptables v1.4.9 - v1.4.10
 */
#elif XTABLES_VERSION_CODE == 5
#include "iptables.c-v1.4.10"

/* libxtables version 6: commit 3a32dcbb
 *  From iptables v1.4.11
 *  (suspect this version will not compile due changes in iptables.h)
 */
#elif XTABLES_VERSION_CODE == 6
#warning "This version of xtables is currently not supported by this Perl package"
#include "iptables.c-v1.4.11.1"

#elif XTABLES_VERSION_CODE > 6
#error "The libxtables is newer than this package support and know of - Sorry!"
#error " Please inform the package author of this issue, thanks! "

#endif /* XTABLES_VERSION_CODE */
