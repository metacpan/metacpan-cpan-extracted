/*
 * hash_64 - 64 bit Fowler/Noll/Vo-0 hash code
 *
 * @(#) $Revision: 5.1 $
 * @(#) $Id: hash_64.c,v 5.1 2009/06/30 09:01:38 chongo Exp $
 * @(#) $Source: /usr/local/src/cmd/fnv/RCS/hash_64.c,v $
 *
 ***
 *
 * Fowler/Noll/Vo hash
 *
 * The basis of this hash algorithm was taken from an idea sent
 * as reviewer comments to the IEEE POSIX P1003.2 committee by:
 *
 *      Phong Vo (http://www.research.att.com/info/kpv/)
 *      Glenn Fowler (http://www.research.att.com/~gsf/)
 *
 * In a subsequent ballot round:
 *
 *      Landon Curt Noll (http://www.isthe.com/chongo/)
 *
 * improved on their algorithm.  Some people tried this hash
 * and found that it worked rather well.  In an EMail message
 * to Landon, they named it the ``Fowler/Noll/Vo'' or FNV hash.
 *
 * FNV hashes are designed to be fast while maintaining a low
 * collision rate. The FNV speed allows one to quickly hash lots
 * of data while maintaining a reasonable collision rate.  See:
 *
 *      http://www.isthe.com/chongo/tech/comp/fnv/index.html
 *
 * for more details as well as other forms of the FNV hash.
 *
 ***
 *
 * NOTE: The FNV-0 historic hash is not recommended.  One should use
 *	 the FNV-1 hash instead.
 *
 * To use the 64 bit FNV-0 historic hash, pass FNV0_64_INIT as the
 * Fnv64_t hashval argument to fnv_64_buf() or fnv_64_str().
 *
 * To use the recommended 64 bit FNV-1 hash, pass FNV1_64_INIT as the
 * Fnv64_t hashval argument to fnv_64_buf() or fnv_64_str().
 *
 ***
 *
 * Please do not copyright this code.  This code is in the public domain.
 *
 * LANDON CURT NOLL DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE,
 * INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO
 * EVENT SHALL LANDON CURT NOLL BE LIABLE FOR ANY SPECIAL, INDIRECT OR
 * CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF
 * USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
 * OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
 * PERFORMANCE OF THIS SOFTWARE.
 *
 * By:
 *	chongo <Landon Curt Noll> /\oo/\
 *      http://www.isthe.com/chongo/
 *
 * Share and Enjoy!	:-)
 */

#include <stdlib.h>
#include "fnv.h"

/*
 * 64 bit magic FNV-0 and FNV-1 prime
 */
#define FNV_64_PRIME_LOW ((unsigned long)0x1b3)	/* lower bits of FNV prime */
#define FNV_64_PRIME_SHIFT (8)		/* top FNV prime shift above 2^32 */

Fnv64_t *
fnv64_t(char *str)
{
    unsigned char *s = (unsigned char *)str;	/* unsigned string */
    Fnv64_t *hval = malloc(sizeof(Fnv64_t));
    if (!hval) return ((Fnv64_t *)0UL);

    unsigned long val[4];	/* hash value in base 2^16 */
    unsigned long tmp[4];	/* tmp 64 bit value */

    /*
     * Convert Fnv64_t hval into a base 2^16 array
     */
    val[0] = FNV1_64_LOWER;
    val[1] = (val[0] >> 16);
    val[0] &= 0xffff;
    val[2] = FNV1_64_UPPER;
    val[3] = (val[2] >> 16);
    val[2] &= 0xffff;

    /*
     * FNV-1 hash each octet of the string
     */
    while (*s)
    {
        /**/

        /*
         * multiply by the 64 bit FNV magic prime mod 2^64
         *
         * Using 1099511628211, we have the following digits base 2^16:
         *
         *	0x0	0x100	0x0	0x1b3
         *
         * which is the same as:
         *
         *	0x0	1<<FNV_64_PRIME_SHIFT	0x0	FNV_64_PRIME_LOW
         */
        /* multiply by the lowest order digit base 2^16 */
        tmp[0] = val[0] * FNV_64_PRIME_LOW;
        tmp[1] = val[1] * FNV_64_PRIME_LOW;
        tmp[2] = val[2] * FNV_64_PRIME_LOW;
        tmp[3] = val[3] * FNV_64_PRIME_LOW;
        /* multiply by the other non-zero digit */
        tmp[2] += val[0] << FNV_64_PRIME_SHIFT;	/* tmp[2] += val[0] * 0x100 */
        tmp[3] += val[1] << FNV_64_PRIME_SHIFT;	/* tmp[3] += val[1] * 0x100 */
        /* propagate carries */
        tmp[1] += (tmp[0] >> 16);
        val[0] = tmp[0] & 0xffff;
        tmp[2] += (tmp[1] >> 16);
        val[1] = tmp[1] & 0xffff;
        val[3] = tmp[3] + (tmp[2] >> 16);
        val[2] = tmp[2] & 0xffff;
        /*
         * Doing a val[3] &= 0xffff; is not really needed since it simply
         * removes multiples of 2^64.  We can discard these excess bits
         * outside of the loop when we convert to Fnv64_t.
         */
    
        /* xor the bottom with the current octet */
        val[0] ^= (unsigned long)(*s++);
    }

    /*
     * Convert base 2^16 array back into an Fnv64_t
     */
    hval->upper = ((val[3]<<16) | val[2]);
    hval->lower = ((val[1]<<16) | val[0]);

    /* return our new hash value */
    return hval;
}
