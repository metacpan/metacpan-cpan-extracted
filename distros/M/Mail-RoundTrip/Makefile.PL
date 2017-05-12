use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Mail::RoundTrip',
    AUTHOR              => q{Chris Travers <chris.travers@gmail.com>},
    VERSION_FROM        => 'lib/Mail/RoundTrip.pm',
    ABSTRACT_FROM       => 'lib/Mail/RoundTrip.pm',
    PL_FILES            => {},
    PREREQ_PM           => { 
                           'JSON'            => 0,
                           'Test::More'      => 0,
                           'Test::Exception' => 0,
                           'Moo'             => 0,
                           'File::Slurp'     => 0,
                           'UUID::Tiny'      => 0,
                     'Email::Sender::Simple' => 0,
                           'Email::Simple'   => 0,
                    'Email::Simple::Creator' => 0,
                           },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Mail-*' },
    LICENSE             => 'BSD',
);

