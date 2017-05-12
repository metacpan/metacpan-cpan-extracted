use strict;
use warnings;
use ExtUtils::MakeMaker;

my $makemakerversion = $ExtUtils::MakeMaker::VERSION;
$makemakerversion =~s/_//g;

WriteMakefile(
    NAME                => 'Frontier::Client::Easy',
    AUTHOR              => 'David J. Freedman <lochii@convergence.cx>',
    VERSION_FROM        => 'lib/Frontier/Client/Easy.pm',
    ABSTRACT_FROM       => 'lib/Frontier/Client/Easy.pm',
    ($makemakerversion >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Frontier::Client' =>0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Frontier-Client-Easy*' },
);
