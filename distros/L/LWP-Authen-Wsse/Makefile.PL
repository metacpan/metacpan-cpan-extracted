use strict;
use inc::Module::Install;

name            'LWP-Authen-Wsse';
author          'Audrey Tang <audrey@audrey.org>';
all_from        'lib/LWP/Authen/Wsse.pm';

requires        'LWP';
requires        'Digest::SHA1';
requires        'MIME::Base64';

sign;
WriteAll;
