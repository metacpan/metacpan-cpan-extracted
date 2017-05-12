use ExtUtils::MakeMaker;
use strict;

my %opts = (
            'NAME'          => "Linux::Bootloader",
            'AUTHOR'        => "OSDL Engineering <eng\@osdl.org>",
            'ABSTRACT_FROM' => "lib/Linux/Bootloader.pm",
            'VERSION'       => '1.3',
            'EXE_FILES'     => [ qw( 
                                     scripts/boottool
                                     scripts/kernel_label
                                     scripts/linux_install
                                     scripts/linux_mkinitrd
                                     scripts/linux_release_tag
                                     ) ],
            'MAN1PODS'      => {
                'scripts/linux_install.pod' => 'blib/man1/linux_install.1',
                'scripts/linux_mkinitrd.pod' => 'blib/man1/linux_mkinitrd.1',
                'scripts/linux_release_tag.pod' => 'blib/man1/linux_release_tag.1',
            },
            'PREREQ_PM'     => {
                'Pod::Usage'     => 0,
                'Getopt::Long'   => 0,
            },
);

WriteMakefile( %opts )

# vi:set ai ts=4 sw=4 expandtab:
