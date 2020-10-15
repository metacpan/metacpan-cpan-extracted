require 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefile_args = (
    'NAME'             => 'Digest',
    'AUTHOR'           => 'Gisle Aas <gisle@activestate.com>',
    'VERSION_FROM'     => 'lib/Digest.pm',
    'ABSTRACT_FROM'    => 'lib/Digest.pm',
    'LICENSE'          => 'perl',
    'MIN_PERL_VERSION' => '5.006',
    'PREREQ_PM'        => {
        'MIME::Base64' => 0,
    },
    'TEST_REQUIRES' => {
        'Test::More' => '0.47',
        'File::Temp' => '0',
    },
    'INSTALLDIRS' => ( ( $] >= '5.009005' && $] < '5.012' ) ? 'perl' : 'site' ),
    'dist'        => { 'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz', },
    'clean'       => { 'FILES' => 'Digest-*' },

    'META_MERGE' => {
        'meta-spec'      => { 'version' => 2 },
        'dynamic_config' => 0,
        'resources'      => {
            'license'    => ['http://dev.perl.org/licenses/'],
            'bugtracker' => { 'web' => 'https://github.com/Dual-Life/digest/issues' },
            'repository' => {
                'type' => 'git',
                'url'  => 'https://github.com/Dual-Life/digest.git',
                'web'  => 'https://github.com/Dual-Life/digest',
            },
        }
    },
);

delete $WriteMakefile_args{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION('6.31') };
delete $WriteMakefile_args{META_MERGE}
  unless eval { ExtUtils::MakeMaker->VERSION('6.46') };
delete $WriteMakefile_args{MIN_PERL_VERSION}
  unless eval { ExtUtils::MakeMaker->VERSION('6.48') };
unless ( eval { ExtUtils::MakeMaker->VERSION('6.64') } ) {
    my $test_requires = delete $WriteMakefile_args{TEST_REQUIRES};
    $WriteMakefile_args{PREREQ_PM}{$_} = $test_requires->{$_} for keys %$test_requires;
}

WriteMakefile(%WriteMakefile_args);
