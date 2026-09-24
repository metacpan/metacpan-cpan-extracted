use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Linux::Event::Kernel::Inotify',
    VERSION_FROM     => '../lib/Linux/Event/Kernel/Inotify.pm',
    ABSTRACT         => 'inotify filesystem notifications for Linux::Event',
    AUTHOR           => 'Joshua S. Day <hax@cpan.org>',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.036000',
    PM               => {},
    XS               => { 'Inotify.xs' => 'Inotify.c' },
    OBJECT           => 'Inotify$(OBJ_EXT)',
    clean            => { FILES => 'Inotify.c' },
);
