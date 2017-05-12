
use strict;

use ExtUtils::MakeMaker 6.48;


my %WriteMakefileArgs = (
    NAME           => 'Device::Osram::Lightify',
    VERSION_FROM   => 'lib/Device/Osram/Lightify.pm',
    EXE_FILES      => ["bin/ol" ],

    BUILD_REQUIRES => {

        # solely for the test-suite.
        'Test::More'   => 0,
        'Test::Pod'    => 0,
        'Test::Strict' => 0,
        'Test::NoTabs' => 0,

    },
    ABSTRACT         => 'Interface to the Osram Lightify system.',
    AUTHOR           => 'Steve Kemp <steve@steve.org.uk>',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.008',
    META_MERGE       => {
              resources => {
                  license    => 'http://dev.perl.org/licenses/',
                  homepage   => 'https://github.com/skx/Device-Osram-Lightify/',
                  bugtracker => 'https://github.com/skx/Device-Osram-Lightify/issues',
                  repository => 'https://github.com/skx/Device-Osram-Lightify.git',
              },
    },
);


WriteMakefile(%WriteMakefileArgs);


package MY;

sub metafile
{
    my $self = shift;
    my $meta = $self->SUPER::metafile_target(@_);
    my ($extra) = $self->echo( 'license: perl_5', 'MYMETA.yml', 1 );
    return "$meta\t$extra\n";
}
