# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Filesys::POSIX',
    'VERSION_FROM' => 'lib/Filesys/POSIX.pm',
    'AUTHOR'       => 'Xan Tronix <xan@cpan.org>',
    'LICENSE'      => 'perl',
    'ABSTRACT'     => 'Provides POSIX-like filesystem semantics in pure Perl',

    'PREREQ_PM' => { 'Carp' => 0 },

    'BUILD_REQUIRES' => {
        'Test::Simple'     => '0.44',
        'Test::Exception'  => '0.26',
        'Test::NoWarnings' => '0.081',
        'Test::Builder'    => 0,
        'Test::Deep'       => 0,
        'Try::Tiny'        => 0
    },

    'TEST_REQUIRES' => {
        'autodie' => 0
    },

    'META_MERGE' => {
        'meta-spec' => { 'version' => 2 },
        'resources' => {
            'repository' => {
                'type' => 'git',
                'url'  => 'git://github.com/xantronix/Filesys-POSIX.git',
                'web'  => 'https://github.com/xantronix/Filesys-POSIX'
            }
        }
    }
);

package MY;

sub test {
    my ( $self, @args ) = @_;

    my $text = $self->SUPER::test(@args);

    my %substitutions = ( '$(FULLPERLRUN)' => '$(FULLPERLRUN) -It/lib' );

    foreach my $search ( sort keys %substitutions ) {
        my $replace = $substitutions{$search};

        $text =~ s/\Q$search\E/$replace/mg;
    }

    return $text;
}

