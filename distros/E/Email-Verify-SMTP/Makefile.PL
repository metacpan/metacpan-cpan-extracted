use strict;
use warnings;
use inc::Module::Install;
use 5.008005;

name 'Email-Verify-SMTP';
perl_version '5.008005';
license 'perl';
all_from 'lib/Email/Verify/SMTP.pm';

test_requires 'Test::More'        => 0;
requires  'Carp'                  => 0;
requires  'IO::Socket::Telnet'    => 0;
requires  'Net::Nslookup'         => 0;

tests_recursive();
WriteAll();

