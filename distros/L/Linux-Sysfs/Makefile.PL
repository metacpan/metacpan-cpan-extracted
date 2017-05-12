use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Linux::Sysfs',
    AUTHOR              => 'Florian Ragwitz <rafl@debian.org>',
    VERSION_FROM        => 'lib/Linux/Sysfs.pm',
    ABSTRACT_FROM       => 'lib/Linux/Sysfs.pm',
    XSPROTOARG          => '-noprototypes',
    LIBS                => [qw( -lsysfs )],
    INC                 => '-Ic',
    CCFLAGS             => '-Wall',
    PL_FILES            => {},
    EXE_FILES           => ['script/systool.pl'],
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Linux-Sysfs-*' },
    do {
        my @clean;
        my @OBJECT;
        my %XS;

        for my $xs (<xs/*.xs>) {
            (my $c = $xs) =~ s/\.xs$/\.c/i;
            (my $o = $xs) =~ s/\.xs$/\$(OBJ_EXT)/i;

            $XS{$xs} = $c;
            push @OBJECT, $o;
            push @clean, $o;
        }

        for my $c (<c/*.c>) {
            (my $o = $c) =~ s/\.c$/\$(OBJ_EXT)/i;

            push @OBJECT, $o;
            push @clean, $o;
        }

        clean   => { FILES => 'Linux-Sysfs-* '. join(' ', @clean), },
        OBJECT  => join(' ', @OBJECT),
        XS      => \%XS,
    },
);

package MY;

use strict;
use warnings;
use Config;

sub const_cccmd {
    my $inherited = shift->SUPER::const_cccmd(@_);
    return '' unless $inherited;

    if ($Config{cc} eq 'cl') {
        warn 'you are using MSVC... my condolences.';
        $inherited .= ' /Fo$@';
    } else {
        $inherited .= ' -o $@';
    }

    return $inherited;
}
