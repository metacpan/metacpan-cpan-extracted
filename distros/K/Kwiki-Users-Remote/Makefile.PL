use inc::Module::Install;

name('Kwiki-Users-Remote');
abstract('automatically set Kwiki user name from HTTP authentication');
author('Ian Langworth <ian@cpan.org>');
version_from('lib/Kwiki/Users/Remote.pm');
license('perl');

requires(
    qw(
        perl 5.6.1
        Kwiki 0.32
        Kwiki::Users 0
        Kwiki::UserName 0.14
        )
);

check_nmake();

&WriteAll();
