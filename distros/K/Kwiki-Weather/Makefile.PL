use inc::Module::Install;

name('Kwiki-Weather');
abstract('Weather button and WAFL for your Kwiki');
author('Ian Langworth <ian@cpan.org>');
version_from('lib/Kwiki/Weather.pm');
license('perl');

requires(qw(
    perl 5.6.1
    Kwiki 0.32
    Kwiki::Zipcode 0.11
    Geo::Weather 0
));

check_nmake();

&WriteAll();
