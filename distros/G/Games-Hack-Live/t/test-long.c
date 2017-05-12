
#include <stdio.h>


int rek(long a, long b, long c, long d)
{
	return ((a != 0) ? rek(a+1, b, c, d) : 0) + 1;
}


int main(void)
{
	static long v
		__attribute__ ((aligned(4096)))
		= 51*71*131;
	char buf[31];

	while (fgets(buf, sizeof(buf), stdin)) {
		v += 257;
		printf("\n========= NEW VALUE: %d\n", v);
		buf[0] = rek(-100, -5, -7, -2);
	}
	return 0;
}

