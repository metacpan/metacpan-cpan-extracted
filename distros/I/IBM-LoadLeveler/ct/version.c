#include <stdio.h>
#include "llapi.h"

/* 
 * This is a simple C representation of test t/01version
 * The Perl test will check the result of this with it's own for consistency
 */
 
main(int argc, char *argv[])
{
	const char	*version;
	
	version=ll_version();
	
	printf("VERSION=%s\n",version);
	return(0);
}
