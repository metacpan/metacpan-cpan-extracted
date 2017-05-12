#ifndef _SOUP_PERL_PRIVATE_H_
#define _SOUP_PERL_PRIVATE_H_

#include "soup-perl.h"

void
soupperl_queue_message (SoupSession *session, SoupMessage *msg, SV  *sv_callback, SV *sv_user_data);

#endif /* _SOUP_PERL_PRIVATE_H_ */
