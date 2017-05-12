use strict;
use warnings;
use ExtUtils::MakeMaker;

eval 'use ExtUtils::MakeMaker::Coverage';

require 5.008;

my %ARGS = (
    ( MM->can( 'signature_target' ) ? ( SIGN => 1 ) : () ),
    NAME          => 'HTTP::Proxy::GreaseMonkey',
    AUTHOR        => 'Andy Armstrong <andy@hexten.net>',
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/HTTP/Proxy/GreaseMonkey.pm',
    ABSTRACT_FROM => 'lib/HTTP/Proxy/GreaseMonkey.pm',
    PL_FILES      => {},
    EXE_FILES     => ['examples/gmproxy'],
    PREREQ_PM     => {
        'Carp'             => 0,
        'Data::UUID'       => 0,
        'File::Spec'       => 0,
        'HTML::Tiny'       => '1.01',
        'HTTP::Proxy'      => '0.20',
        'JSON'             => '2.01',
        'LockFile::Simple' => 0,
        'Test::More'       => 0,
        'YAML'             => 0,
    },
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'HTTP-Proxy-GreaseMonkey-*' },
);

if ( $^O eq 'darwin' ) {
    $ARGS{PL_FILES} = { 'helper/patchbin.PL' =>
          '$(INSTALLSITEBIN) examples/net.hexten.gmproxy.plist' };
}

WriteMakefile( %ARGS );
