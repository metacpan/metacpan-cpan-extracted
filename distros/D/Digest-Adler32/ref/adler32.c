#include <string.h>
#include <stdio.h>

/* Copied from RFC 1950 */

#define BASE 65521 /* largest prime smaller than 65536 */

unsigned long update_adler32(unsigned long adler,
			     unsigned char *buf, int len)
{
    unsigned long s1 = adler & 0xffff;
    unsigned long s2 = (adler >> 16) & 0xffff;
    int n;
    
    for (n = 0; n < len; n++) {
	s1 = (s1 + buf[n]) % BASE;
	s2 = (s2 + s1)     % BASE;
    }
    return (s2 << 16) + s1;
}

int main(int argc, char* argv[])
{
    int i;
    unsigned long adler = 1L;
    for (i = 1; i < argc; i++) {
	adler = update_adler32(adler, argv[i], strlen(argv[i]));
    }
    printf("adler32=%08lx\n", adler);
}
