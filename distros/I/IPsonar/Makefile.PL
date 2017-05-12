use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'IPsonar',
    AUTHOR              => q{George Budd <gbudd@cpan.org>},
    VERSION_FROM        => 'lib/IPsonar.pm',
    ABSTRACT_FROM       => 'lib/IPsonar.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Net::SSLeay' => 0,
        'LWP::UserAgent' => 0,
        'XML::Simple' => 0,
        'URI' => 0,
        'MIME::Base64' => 0,
        'Carp' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'IPsonar-*' },
);
