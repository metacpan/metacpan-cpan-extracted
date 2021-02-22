#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <zlib.h>
#include <libdeflate.h>

int main()
{
    int repeat = 0x10000;
    int same = 50;
    int size;
    struct libdeflate_compressor * lc;
    struct libdeflate_decompressor * ld;
    int lcsize;
    int i;
    int bytes;
    int rtbytes;
    size_t ret;
    FILE * f;

    size = sizeof (char) * same * repeat;

    char * input = malloc (size);
    for (i = 0; i < repeat; i++) {
	int j;
	char c = '0';
	if ((random () % 2) == 1) {
	    c = '1';
	}
	for (j = 0; j < same; j++) {
	    input[i*same + j] = c;
	}
    }
    printf ("%d\n", strlen(input));
    f = fopen ("random01", "w");
    if (! f) {
	fprintf (stderr, "Too bad.\n");
	exit (1);
    }
    fwrite (input, sizeof (char), size, f);
    lc = libdeflate_alloc_compressor (12);
    lcsize = libdeflate_deflate_compress_bound(lc, size);
    char * output = malloc (lcsize);
    bytes = libdeflate_gzip_compress (lc, input, size, output, lcsize);
    printf ("%d\n", bytes);
    ld = libdeflate_alloc_decompressor ();
    char * rt = malloc (size);
    rtbytes = libdeflate_gzip_decompress (ld, output, bytes, rt, size, & ret);
    if (strcmp (rt, input) != 0) {
	printf ("Different.\n");
    }
    else {
	printf ("Same\n");
    }
}
