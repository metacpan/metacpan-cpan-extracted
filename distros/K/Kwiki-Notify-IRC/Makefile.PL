use inc::Module::Install;

name('Kwiki-Notify-IRC');
abstract('announce updates to your Kwiki on IRC channels');
author('Ian Langworth <ian@cpan.org>');
version_from('lib/Kwiki/Notify/IRC.pm');
license('perl');

requires(qw(
    perl                                5.6.1
    Kwiki                               0.32
    POE::Component::IKC::ClientLite     0
    POE::Component::IRC                 0
    YAML                                0
    Term::ANSIColor                     0
));

check_nmake();

&WriteAll();
