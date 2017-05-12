use inc::Module::Install;

name('Kwiki-DNSBL');
author('Jon Aslund <aslund.org>');
abstract('Blocks edit from ip addresses in DNS Blackhole lists');
license('perl');
version_from('lib/Kwiki/DNSBL.pm');

requires(qw(
    perl 5.6.1
    Kwiki 0.36
    Net::DNSBLLookup 0
));

check_nmake();

&WriteAll();
