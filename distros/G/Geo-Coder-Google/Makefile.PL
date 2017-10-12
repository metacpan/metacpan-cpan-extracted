use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Geo::Coder::Google',
    'AUTHOR'    => 'Tatsuhiko Miyagawa <miyagawa@bulknews.net>',
    'LICENSE' => 'perl',
    'VERSION_FROM' => 'lib/Geo/Coder/Google.pm', # finds $VERSION
    'ABSTRACT_FROM' => 'lib/Geo/Coder/Google.pm',
    'MIN_PERL_VERSION' => '5.008001',
    'PREREQ_PM' => {
        LWP => 5.5,
        JSON => 2.27,
        URI => 0,
        'HTTP::Request' => 0,
    },
    'TEST_REQUIRES' => {
        'Test::More' => 0.32,
        'Test::Number::Delta' => 0,
        'Digest::HMAC_SHA1' => 0,
        'MIME::Base64' => 0,
    },
    META_MERGE      => {
        'meta-spec' => { version => 2 },
        resources => {
            bugtracker  => {
                web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Geo-Coder-Google',
                mailto => 'bug-Geo-Coder-Google@rt.cpan.org',
            },
            repository  => {
                type => 'git',
                url => 'https://github.com/arcanez/geo-coder-google.git',
                web => 'https://github.com/arcanez/geo-coder-google',
            },
        },
    },
);
