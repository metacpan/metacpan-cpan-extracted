use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'JIRA::REST::Lite',
    VERSION_FROM => 'lib/JIRA/REST/Lite.pm', # finds $VERSION
    PREREQ_PM    => {
        'REST::Client' => 0,
        'JSON'         => 0,
        'MIME::Base64' => 0,
    },
    ABSTRACT_FROM => 'lib/JIRA/REST/Lite.pm',
    AUTHOR        => 'Kawamura Shingo <pannakoota@gmail.com>',
    LICENSE       => 'perl',
);

