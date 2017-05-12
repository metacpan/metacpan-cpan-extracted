#BEGIN { require 5.006 } # ‘our’ is used in the tests

use ExtUtils::MakeMaker;

%prq = (
# WildCardQuery:
	base                         => 0,
#	KSx::Search::RegexpTermQuery => 0,
	strict                       => 0,
	warnings                     => 0,
# RegexpTermQuery:
         base     => 0,
         Hash::Util::FieldHash::Compat        => 0,
         KinoSearch::Search::Compiler         => 0,
         KinoSearch::Search::Span             => 0,
         KinoSearch::Search::Query            => 0,
         KinoSearch::Search::Matcher          => 0,
         strict                               => 0,
         warnings                             => 0,

# for testing:
	KinoSearch::Analysis::Tokenizer            => 0,
	KinoSearch'FieldType'FullTextType          => 0,
	KinoSearch::Indexer                        => 0,
	KinoSearch::Schema                         => 0,
	KinoSearch::Searcher                       => 0,
	KinoSearch::Store::RAMFolder               => 0,
	strict                                     => 0,
	Test::More                                 => 0,
	utf8                                       => 0,
	warnings                                   => 0,
);


eval{require KinoSearch::Search::Matcher}
 and eval{ KinoSearch::Search::Matcher->can('score')}
or $prq{KinoSearch} = 9999, print <<, "\n" ;
This module requires the development version of KinoSearch, revision
4810 or later, which can be obtained from the following URL:
http://www.rectangular.com/svn/kinosearch/trunk


WriteMakefile(
    NAME                => 'KSx::Search::WildCardQuery',
    AUTHOR              => 'Father Chrysostomos <sprout [hat] cpan . org>',
    VERSION_FROM        => 'lib/KSx/Search/WildCardQuery.pm',
    ABSTRACT_FROM       => 'lib/KSx/Search/WildCardQuery.pm',
    PL_FILES            => {},
    PREREQ_PM           => \%prq,
    dist               => { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
                            TAR => 'COPYFILE_DISABLE=1 tar' },
    clean              => { FILES => 'KSx-Search-WildCardQuery-*' },
);
