#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "Av_CharPtrPtr.h"  /* XS_*_charPtrPtr() */
#ifdef __cplusplus
}
#endif


#include "CLucene.h"
#include "CLucene/highlighter/HighlightScorer.h"
#include "CLucene/highlighter/QueryScorer.h"
#include "CLucene/highlighter/Highlighter.h"
#include "CLucene/highlighter/SimpleHTMLFormatter.h"

typedef lucene::analysis::Analyzer Analyzer;
typedef lucene::analysis::TokenStream TokenStream;
typedef lucene::util::StringReader StringReader;
typedef lucene::search::Query Query;
typedef lucene::search::highlight::HighlightScorer Scorer;
typedef lucene::search::highlight::QueryScorer QueryScorer;
typedef lucene::search::highlight::Highlighter Highlighter;
typedef lucene::search::highlight::Formatter Formatter;
typedef lucene::search::highlight::SimpleHTMLFormatter SimpleHTMLFormatter;

MODULE = Lucene::Search::Highlight    PACKAGE = Lucene::Search::Highlight::QueryScorer
INCLUDE: xs/QueryScorer.xs

MODULE = Lucene::Search::Highlight    PACKAGE = Lucene::Search::Highlight::Highlighter
INCLUDE: xs/Highlighter.xs

MODULE = Lucene::Search::Highlight    PACKAGE = Lucene::Search::Highlight::SimpleHTMLFormatter
INCLUDE: xs/SimpleHTMLFormatter.xs
