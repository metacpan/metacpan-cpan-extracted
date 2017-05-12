use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Geo::Distance::Google',
    'AUTHOR'    => 'Lee Carmichael <lcarmich@cpan.org>',
    'LICENSE'   => 'perl',
    'VERSION_FROM'     => 'lib/Geo/Distance/Google.pm', # finds $VERSION
    'ABSTRACT_FROM'    => 'lib/Geo/Distance/Google.pm',
    'MIN_PERL_VERSION' => '5.008001',
    'PREREQ_PM' => {
        LWP => 0,
        JSON => 0,
        Encode => 0,
        URI => 0,
        'HTTP::Request' => 0,
        'Params::Validate' => 0
    },
    'BUILD_REQUIRES' => {
        'Test::More' => 0.32,
        'Test::Number::Delta' => 0,
        'Digest::HMAC_SHA1' => 0,
        'MIME::Base64' => 0,
    },
    META_MERGE      => {
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            bugtracker  => 'https://github.com/lecar-red/Geo-Distance-Google/issues',
            repository  => 'https://github.com/lecar-red/Geo-Distance-Google',
        },
    }, 
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-DirectAdmin-API-*' }
);
