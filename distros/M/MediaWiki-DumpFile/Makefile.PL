use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	META_MERGE => { recommends  => { 'XML::CompactTree::XS' => '0.02' } },
    NAME                => 'MediaWiki::DumpFile',
    AUTHOR              => q{"Tyler Riddle <triddle@cpan.org>"},
    VERSION_FROM        => 'lib/MediaWiki/DumpFile.pm',
    ABSTRACT_FROM       => 'lib/MediaWiki/DumpFile.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => '0.94',
        'Test::Simple' => '0.94',
        'Scalar::Util' => '1.21',
        'XML::TreePuller' => '0.1.0',
        'Data::Compare' => '1.2101',
        'Test::Exception' => '0.27',
        'File::Find::Rule' => '0.32',
        'File::Type' => '0.22',
        'IO::Uncompress::AnyUncompress' => '2.0.37',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'MediaWiki-DumpFile-*' },
);
