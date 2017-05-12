BEGIN { require 5.006 } # ‘our’ is used in the tests

use ExtUtils::MakeMaker;

%prq = (
         Hash::Util::FieldHash::Compat      => 0,
         KinoSearch::Highlight::Highlighter => 0,
         List::Util                         => 0,
         Number::Range                      => 0,
         strict                             => 0,
         warnings                           => 0,
# for testing:
	base                                       => 0,
	KinoSearch::Analysis::Tokenizer            => 0,
	KinoSearch::FieldType::FullTextType        => 0,
	KinoSearch::Indexer                        => 0,           
	KinoSearch::Searcher                       => 0,
	KinoSearch::Schema                         => 0,
	KinoSearch::Store::RAMFolder               => 0,
	Test::More                                 => 0,
	utf8                                       => 0,
);

eval(<<'version_test') or $prq{KinoSearch} = 9999, print <<, "\n" ;
# Set up the schema
require KinoSearch::Schema;
require KinoSearch::Analysis::Tokenizer;
require KinoSearch::FieldType::FullTextType;
my $schema = new KinoSearch::Schema;
{
 my $analyser = KinoSearch::Analysis::Tokenizer->new;
 $schema->spec_field(
  name => 'content', type =>
   new KinoSearch::FieldType::FullTextType
    analyzer => $analyser,
    highlightable => 1,
 );
}

use KinoSearch::Searcher;
use KinoSearch::Indexer;
use KinoSearch::Store::RAMFolder;

my $indexer   = KinoSearch::Indexer->new(
    index => my $folder = KinoSearch::Store::RAMFolder->new,
    schema => $schema,
);

my $phi = "\x{03a6}";
$indexer->add_doc( { content => "$phi a b c d x y z h i j k " } );
$indexer->commit;

my $searcher = KinoSearch::Searcher->new( index => $folder );

my $q = qq|"x y z" AND $phi|;
my $hits = $searcher->hits( query => $q );
my $hit = $hits->next;

my $posits =
 $searcher->glean_query($q)->make_compiler(searchable => $searcher)
  ->highlight_spans(
   searchable => $searcher,
   field      => 'content',
   doc_vec    => $searcher->fetch_doc_vec( $hit->get_doc_id )
  );
use Scalar::Util "blessed";
!blessed(
 KinoSearch::Highlight::HeatMap->new(
        spans  => $posits,
        window => $limit*2
     )->get_spans
)
version_test
This module requires the development version of KinoSearch, revision
4604 or later, which can be obtained from the following URL:
http://www.rectangular.com/svn/kinosearch/trunk


WriteMakefile(
    NAME                => 'KSx::Highlight::Summarizer',
    AUTHOR              => 'Father Chrysostomos <sprout [hat] cpan . org>',
    VERSION_FROM        => 'lib/KSx/Highlight/Summarizer.pm',
    ABSTRACT_FROM       => 'lib/KSx/Highlight/Summarizer.pm',
    PL_FILES            => {},
    PREREQ_PM => \%prq,
    dist               => { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
                            TAR => 'COPYFILE_DISABLE=1 tar' },
    clean              => { FILES => 'KSx-Highlight-Summarizer-*' },
);
