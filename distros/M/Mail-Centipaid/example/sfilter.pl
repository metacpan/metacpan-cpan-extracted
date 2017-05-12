#!/usr/bin/perl

# simple filter used to test if Mail::Audit is being called
# properly, and it delivers mail to the mailbox
#

use Mail::Audit;
Mail::Audit->new->accept;
