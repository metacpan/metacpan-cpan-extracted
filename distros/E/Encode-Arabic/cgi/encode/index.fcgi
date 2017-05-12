#!/usr/bin/perl

# ###################################################################### Otakar Smrz, 2003/01/23
#
# Encode Arabic ################################################################################

use lib '/home/smrz/share/perl/5.10.1',
        '/home/smrz/lib/perl5/site_perl/5.10.0', '/home/smrz/lib/perl5/5.10.0',
        '/home/smrz/lib/perl5/site_perl/5.10.0/i386-linux-thread-multi',
        '/home/smrz/lib/perl5/site_perl/5.10.0/i386-linux-thread-multi/auto';

use Encode::Arabic::CGI;

Encode::Arabic::CGI->new()->run();
