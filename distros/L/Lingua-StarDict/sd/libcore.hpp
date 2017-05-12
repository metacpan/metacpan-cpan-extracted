#ifndef LIBCORE_HPP
#define LIBCORE_HPP

#include <glib.h>
#include <string>
#include <vector>

#include "types.hpp"
#include "lib.h"
 

//notice!!! when you change these DEFAULT const value,
//remember that you'd better change data/stardict.schemas.in too!

const int MAX_MATCH_ITEM_PER_LIB=100;
const int MAX_FUZZY_MATCH_ITEM=100;
const int MAX_FLOAT_WINDOW_FUZZY_MATCH_ITEM=5;

const int LIST_WIN_ROW_NUM = 30; //how many words show in the list win.
const int MAX_FUZZY_DISTANCE= 3; // at most MAX_FUZZY_DISTANCE-1 differences allowed when find similar words

struct BookInfo{
  std::string bookname;
  glong wordcount;
  std::string name_of_ifofile;
  BookInfo(const char *bn, glong w, const char *n_ifofile)
    : bookname(bn), wordcount(w), name_of_ifofile(n_ifofile){}
};

class LibCore : protected Libs{
public:
  struct SearchResult{
    std::string bookname;
    std::string definition;
    std::string explanation;
    SearchResult(void){}
    SearchResult(const std::string & b, const std::string & d, const std::string & e)
      : bookname(b), definition(d), explanation(e){}
  };
  typedef std::vector<SearchResult> SearchResultsList;
  typedef SearchResultsList::iterator PSearchResult;
private:
  // struct
  struct Fuzzystruct {
    char * pMatchWord;
    int iMatchWordDistance;
  };

  int iMaxFuzzyDistance;	
  glong *iCurrentIndex;

  static int FuzzystructCompare(const void * s1, const void * s2);
  static int MatchWordCompare(const void * s1, const void * s2);
  
  gboolean InternalSimpleLookup(const gchar* sWord,glong* piIndex, SearchResultsList & res,
				gboolean piIndexValid = false, gboolean bTryMoreIfNotFound = false);
public:  
  LibCore(const StringsList & enable_list, const StringsList & disable_list, const char *_stardict_data_dir=NULL);
  ~LibCore();

  bool SimpleLookup(const char* sWord, SearchResultsList & res);
  bool LookupWithFuzzy(const gchar *sWord, SearchResultsList & res);
  bool LookupWithRule(const gchar* wordd, SearchResultsList & res);

  SearchResultsList SearchResultsToExternalFormat(gchar **word, gchar **data, 
					    const gchar *sOriginWord);
  std::vector<BookInfo> GetBooksInfo(void);
};


#endif/*libcore.hpp*/
