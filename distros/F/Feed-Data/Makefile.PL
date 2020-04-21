use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Feed::Data',
    AUTHOR           => q{LNATION <email@lnation.org>},
    VERSION_FROM     => 'lib/Feed/Data.pm',
    ABSTRACT_FROM    => 'lib/Feed/Data.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'LWP::Protocol::https' => 6.07,
	'Moo' => 2.004000,
	'MooX::HandlesVia' => 0.001008,
	'Type::Tiny' => 1.010001,
	'Carp' => 0,
	'JSON' => 4.02,
	'Compiled::Params::OO' => 0.04,
	'XML::RSS::LibXML' => 0.3105,
    	'HTTP::Message' => 6.22,
	'LWP::UserAgent' => 6.44,
	'HTML::LinkExtor' => 0,
	'HTML::Strip' => 2.10,
	'XML::Atom::Feed' => 0,
   	'Class::Load' => 0.25, 
    	'Ref::Util' => 0.204,
	'Text::CSV_XS' => 1.41,
        'HTML::TableContent' => 1.00
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Feed-Data-*' },
);
