use strict;
use warnings;
use vars qw(%ENV);
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'MetaTrans',
    AUTHOR              => 'Jan Pomikalek <xpomikal@fi.muni.cz>',
    VERSION_FROM        => 'lib/MetaTrans.pm',
    ABSTRACT_FROM       => 'lib/MetaTrans.pm',
    EXE_FILES           => [ 'bin/metatrans', 'bin/runtrans' ],
    PREREQ_PM => {
        'Config::Find'          => 0,
        'Config::General'       => 0,
        'HTML::Entities'        => 0,
        'HTTP::Request'         => 0,
        'HTTP::Response'        => 0,
        'LWP::UserAgent'        => 0,
        'Proc::SyncExec'        => 0,
        'Tk'                    => 804.027,
        'Tk::BrowseEntry'       => 0,
        'Tk::DialogBox'         => 0,
        'Tk::HList'             => 0,
        'Tk::ItemStyle'         => 0,
        'Tk::LabFrame'          => 0,
        'Tk::ROText'            => 0,
        'URI::Escape'           => 0,
    },
    dist   => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean  => { FILES => 'MetaTrans-*', },
    macro  => { HOME  => $ENV{HOME}, }, 
);

sub MY::postamble
{
    return "install :: install_config\n\ninstall_config :\n\t" .
        '$(NOECHO)$(ECHO_N) "Installing configuration file to "; ' .
        '(cp -f config/metatrans.conf /etc/ 2> /dev/null && echo /etc/metatrans.conf) ' .
        '|| ' .
        '(cp -f config/metatrans.conf $(HOME)/.metatrans && echo $(HOME)/.metatrans)';
}
