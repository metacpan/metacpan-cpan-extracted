use strict;
use warnings;
use ExtUtils::MakeMaker;
eval 'use ExtUtils::MakeMaker::Coverage';
if( $@ ) {
    warn "Optional ExtUtils::MakeMaker::Coverage not available\n";
}
else {
    my $covconfig = ExtUtils::MakeMaker::Coverage->config();
    # We don't need POD testing here since we have a separate POD test
    $covconfig->cover_pod( 0 );
}

WriteMakefile(
    NAME                => 'Error::Exception',
    AUTHOR              => 'Stephen Vance <steve@vance.com>',
    VERSION_FROM        => 'lib/Error/Exception.pm',
    ABSTRACT_FROM       => 'lib/Error/Exception.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'        => 0,
        'Error'             => 0,
        'Exception::Class'  => 0,
        'Module::Locate'    => 0,
        'Test::Unit'        => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Error-Exception-*' },
);
