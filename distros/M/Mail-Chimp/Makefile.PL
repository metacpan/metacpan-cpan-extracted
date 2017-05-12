use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Mail::Chimp',
    VERSION_FROM => 'lib/Mail/Chimp.pm',
    AUTHOR       => 'Dave Pirotte (dpirotte@gmail.com)',
    ABSTRACT     => 'Perl wrapper around the Mailchimp v1.2 API',
    PREREQ_PM    => {
                     'Moose'        => 0,
                     'XMLRPC::Lite' => '0.710.06',
                     'Test::Simple' => '0.44',
                     'MooseX::Types::DateTimeX' => 0,
                    },
);
