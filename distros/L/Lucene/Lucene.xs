#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
//#include "Av_CharPtrPtr.h"  /* XS_*_charPtrPtr() */
#ifdef __cplusplus
}
#endif


#include "CLucene.h"
#include "CLucene/CLConfig.h"
#include "CLucene/queryParser/MultiFieldQueryParser.h"
#include "CLucene/search/QueryFilter.h"
#include "CLucene/search/RangeFilter.h"
#include "CLucene/analysis/AnalysisHeader.h"
#include "CLucene/analysis/Analyzers.h"
#include "CLucene/analysis/standard/StandardFilter.h"
#include "CLucene/analysis/standard/StandardTokenizer.h"
#include "CLucene/util/Reader.h"

typedef lucene::analysis::KeywordAnalyzer KeywordAnalyzer;
typedef lucene::analysis::Analyzer Analyzer;
typedef lucene::analysis::SimpleAnalyzer SimpleAnalyzer;
typedef lucene::analysis::StopAnalyzer StopAnalyzer;
typedef lucene::analysis::WhitespaceAnalyzer WhitespaceAnalyzer;
typedef lucene::analysis::PerFieldAnalyzerWrapper PerFieldAnalyzerWrapper;
typedef lucene::analysis::standard::StandardTokenizer StandardTokenizer;
typedef lucene::analysis::standard::StandardAnalyzer StandardAnalyzer;
typedef lucene::analysis::standard::StandardFilter StandardFilter;
typedef lucene::analysis::Token Token;
typedef lucene::analysis::Tokenizer Tokenizer;
typedef lucene::analysis::CharTokenizer CharTokenizer;
typedef lucene::analysis::TokenFilter TokenFilter;
typedef lucene::analysis::LowerCaseTokenizer LowerCaseTokenizer;
typedef lucene::analysis::WhitespaceTokenizer WhitespaceTokenizer;
typedef lucene::analysis::LetterTokenizer LetterTokenizer;
typedef lucene::analysis::TokenStream TokenStream;
typedef lucene::analysis::StopFilter StopFilter;
typedef lucene::analysis::ISOLatin1AccentFilter ISOLatin1AccentFilter;
typedef lucene::analysis::LowerCaseFilter LowerCaseFilter;
typedef lucene::util::Reader Reader;
typedef lucene::document::Document Document;
typedef lucene::document::Field Field;
typedef lucene::index::IndexWriter IndexWriter;
typedef lucene::index::IndexReader IndexReader;
typedef lucene::index::Term Term;
typedef lucene::search::IndexSearcher IndexSearcher;
typedef lucene::search::Hits Hits;
typedef lucene::search::HitCollector HitCollector;
typedef lucene::search::Filter Filter;
typedef lucene::search::QueryFilter QueryFilter;
typedef lucene::search::RangeFilter RangeFilter;
typedef lucene::search::Sort Sort;
typedef lucene::search::SortField SortField;
typedef lucene::search::Query Query;
typedef lucene::search::Explanation Explanation;
typedef lucene::search::TermQuery TermQuery;
typedef lucene::search::FuzzyQuery FuzzyQuery;
typedef lucene::search::Similarity Similarity;
typedef lucene::queryParser::QueryParser QueryParser;
typedef lucene::queryParser::MultiFieldQueryParser MultiFieldQueryParser;
typedef lucene::store::Directory Directory;
typedef lucene::store::FSDirectory FSDirectory;
typedef lucene::store::RAMDirectory RAMDirectory;

typedef wchar_t wchar_t_keepalive;

#include "cpp/utils.cpp"
#include "cpp/MethodCall.cpp"
#include "cpp/Wrapper.cpp"
#include "cpp/Analyzer.cpp"
#include "cpp/Tokenizer.cpp"
#include "cpp/CharTokenizer.cpp"
#include "cpp/TokenFilter.cpp"

MODULE = Lucene        PACKAGE = Lucene
INCLUDE: xs/Constants.xs

MODULE = Lucene        PACKAGE = Lucene::Analysis::SimpleAnalyzer
INCLUDE: xs/SimpleAnalyzer.xs

MODULE = Lucene        PACKAGE = Lucene::Analysis::PerFieldAnalyzerWrapper
INCLUDE: xs/PerFieldAnalyzerWrapper.xs

MODULE = Lucene        PACKAGE = Lucene::Analysis::Analyzer
INCLUDE: xs/Analyzer.xs

MODULE = Lucene        PACKAGE = Lucene::Analysis::StopAnalyzer
INCLUDE: xs/StopAnalyzer.xs

MODULE = Lucene        PACKAGE = Lucene::Analysis::WhitespaceAnalyzer
INCLUDE: xs/WhitespaceAnalyzer.xs

MODULE = Lucene        PACKAGE = Lucene::Analysis::KeywordAnalyzer
INCLUDE: xs/KeywordAnalyzer.xs

MODULE = Lucene        PACKAGE = Lucene::Analysis::Standard::StandardAnalyzer
INCLUDE: xs/StandardAnalyzer.xs

MODULE = Lucene        PACKAGE = Lucene::Document
INCLUDE: xs/Document.xs

MODULE = Lucene        PACKAGE = Lucene::Document::Field
INCLUDE: xs/Field.xs

MODULE = Lucene        PACKAGE = Lucene::Index::IndexWriter
INCLUDE: xs/IndexWriter.xs

MODULE = Lucene        PACKAGE = Lucene::Index::IndexReader
INCLUDE: xs/IndexReader.xs

MODULE = Lucene        PACKAGE = Lucene::Index::Term
INCLUDE: xs/Term.xs

MODULE = Lucene        PACKAGE = Lucene::Search::IndexSearcher
INCLUDE: xs/IndexSearcher.xs

MODULE = Lucene        PACKAGE = Lucene::Search::Hits
INCLUDE: xs/Hits.xs

MODULE = Lucene        PACKAGE = Lucene::Search::Explanation
INCLUDE: xs/Explanation.xs

MODULE = Lucene        PACKAGE = Lucene::Search::QueryFilter
INCLUDE: xs/QueryFilter.xs

MODULE = Lucene        PACKAGE = Lucene::Search::RangeFilter
INCLUDE: xs/RangeFilter.xs

MODULE = Lucene        PACKAGE = Lucene::Search::Sort
INCLUDE: xs/Sort.xs

MODULE = Lucene        PACKAGE = Lucene::Search::SortField
INCLUDE: xs/SortField.xs

MODULE = Lucene        PACKAGE = Lucene::Search::Query
INCLUDE: xs/Query.xs

MODULE = Lucene        PACKAGE = Lucene::Search::TermQuery
INCLUDE: xs/TermQuery.xs

MODULE = Lucene        PACKAGE = Lucene::Search::FuzzyQuery
INCLUDE: xs/FuzzyQuery.xs

MODULE = Lucene        PACKAGE = Lucene::QueryParser
INCLUDE: xs/QueryParser.xs

MODULE = Lucene        PACKAGE = Lucene::MultiFieldQueryParser
INCLUDE: xs/MultiFieldQueryParser.xs

MODULE = Lucene        PACKAGE = Lucene::Store::FSDirectory
INCLUDE: xs/FSDirectory.xs

MODULE = Lucene        PACKAGE = Lucene::Store::RAMDirectory
INCLUDE: xs/RAMDirectory.xs

MODULE = Lucene        PACKAGE = Lucene::Analysis::LowerCaseFilter
INCLUDE: xs/LowerCaseFilter.xs

MODULE = Lucene        PACKAGE = Lucene::Analysis::StopFilter
INCLUDE: xs/StopFilter.xs

MODULE = Lucene        PACKAGE = Lucene::Analysis::StandardFilter
INCLUDE: xs/StandardFilter.xs

MODULE = Lucene        PACKAGE = Lucene::Analysis::ISOLatin1AccentFilter
INCLUDE: xs/ISOLatin1AccentFilter.xs

MODULE = Lucene        PACKAGE = Lucene::Analysis::StandardTokenizer
INCLUDE: xs/StandardTokenizer.xs

MODULE = Lucene        PACKAGE = Lucene::Analysis::LowerCaseTokenizer
INCLUDE: xs/LowerCaseTokenizer.xs

MODULE = Lucene        PACKAGE = Lucene::Analysis::WhitespaceTokenizer
INCLUDE: xs/WhitespaceTokenizer.xs

MODULE = Lucene        PACKAGE = Lucene::Analysis::Tokenizer
INCLUDE: xs/Tokenizer.xs

MODULE = Lucene        PACKAGE = Lucene::Analysis::CharTokenizer
INCLUDE: xs/CharTokenizer.xs

MODULE = Lucene        PACKAGE = Lucene::Analysis::Token
INCLUDE: xs/Token.xs

MODULE = Lucene        PACKAGE = Lucene::Utils::Reader
INCLUDE: xs/Reader.xs

MODULE = Lucene        PACKAGE = Lucene::Analysis::TokenFilter
INCLUDE: xs/TokenFilter.xs

