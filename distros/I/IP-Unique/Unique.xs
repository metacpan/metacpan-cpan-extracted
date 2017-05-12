#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef __cplusplus
}
#endif

#include "ppport.h"

#ifdef __CYGWIN__
int main(int, char**) {}
#endif

#include "ipuniq.h"

MODULE = IP::Unique		PACKAGE = IP::Unique

ipuniq*
ipuniq::new()

void
ipuniq::DESTROY()

void
ipuniq::compact()

int
ipuniq::add_ip(ipstr)
	char* ipstr

unsigned int
ipuniq::unique()

unsigned int
ipuniq::total()
