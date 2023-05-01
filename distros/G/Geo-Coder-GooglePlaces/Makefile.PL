use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'      => 'Geo::Coder::GooglePlaces',
    # 'AUTHOR'    => 'Tatsuhiko Miyagawa <miyagawa@bulknews.net>',
    'AUTHOR'    => 'Nigel Horne <njh@bandsman.co.uk>',
    'LICENSE' => 'perl',
    'VERSION_FROM' => 'lib/Geo/Coder/GooglePlaces.pm', # finds $VERSION
    'ABSTRACT_FROM' => 'lib/Geo/Coder/GooglePlaces.pm',
    'MIN_PERL_VERSION' => '5.008001',
    'PREREQ_PM' => {
        'LWP::UserAgent' => 5.5,
        'JSON::MaybeXS' => 0,
        Carp => 0,
        Encode => 0,
        URI => 0,
        'HTTP::Request' => 0,
    }, BUILD_REQUIRES => {
	'Test::Most' => 0,
	'Test::NoWarnings' => 0,
        'Test::Number::Delta' => 0,
        'Digest::HMAC_SHA1' => 0,
        'MIME::Base64' => 0,
    },
    META_MERGE      => {
        'meta-spec' => { version => 2 },
        resources => {
            bugtracker  => {
                # web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Geo-Coder-GooglePlaces',
		web => 'https://github.com/nigelhorne/Geo-Coder-GooglePlaces/issues',
		url => 'https://github.com/nigelhorne/Geo-Coder-GooglePlaces/issues',
                mailto => 'bug-Geo-Coder-GooglePlaces@rt.cpan.org',
            }, repository  => {
                type => 'git',
		url => 'https://github.com/nigelhorne/Geo-Coder-GooglePlaces.git',
		web => 'https://github.com/nigelhorne/Geo-Coder-GooglePlaces',
		mailto => 'bug-CGI-Info@rt.cpan.org'
            },
        },
    },
    dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean		=> { FILES => 'Geo-Coder-GooglePlaces-*' },
);
