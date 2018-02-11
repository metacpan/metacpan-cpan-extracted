use strict ;

use blib ;

use Inline(
	Java => 'STUDY',
	SHARED_JVM => 1,
) ;

print "Shared JVM server started\n" ;
while (1){
	sleep(60) ;
}
