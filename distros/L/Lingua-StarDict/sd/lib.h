#ifndef __SD_LIB_H__
#define __SD_LIB_H__

#ifdef HAVE_CONFIG_H
#  include "config.h"
#endif

#include "dictziplib.h"

#include <stdio.h>
#include <glib.h>

#include "types.hpp"

struct cacheItem{
  glong offset;
  gchar *data;
  cacheItem() : data(NULL){}
  ~cacheItem(){g_free(data);}//g_free work corectly with NULL pointer value
};

const int WORDDATA_CACHE_NUM = 10;
const int INVALID_INDEX=-100;

class DictBase{
public:
  DictBase();
  ~DictBase();
  gchar * GetWordData(glong idxitem_offset, glong idxitem_size);
protected:
  gchar *sametypesequence;
  FILE *dictfile;
  dictData *dictdzfile;
private:
  struct cacheItem cache[WORDDATA_CACHE_NUM];
  gint cache_cur;	
};

class Lib : public DictBase{
private:
  glong wordcount;
  gchar *bookname;
  gchar* name_of_ifofile;
  
  FILE *idxfile;
	
  union {
    gchar **wordlist;
    glong *wordoffset;
  };

#ifdef HAVE_MMAP
  int mmap_fd;
  unsigned long mmap_idxmap_size;
#endif

  union {
    gchar *idxdatabuffer;
    glong cur_wordindex;
  };

  gchar wordentry_buf[256]; // The length of "word_str" should be less than 256. See src/tools/DICTFILE_FORMAT.
  glong wordentry_offset;
  glong wordentry_size;
	
  gboolean load_ifofile(const char *ifofilename, gulong *idxfilesize);

  void loadwordlist();
  gboolean loadwordoffset(const char *idxfilename, gulong idxfilesize);
public:
  Lib();
  ~Lib();
  gboolean load(const char *ifofilename);
  inline glong length() { return(wordcount); }
  inline gchar* GetBookname() { return(bookname); }
  inline gchar* NameOfIfoFile(void){return name_of_ifofile;}
  gboolean Lookup(const char* sWord,glong *pIndex);
  gboolean LookupWithRule(GPatternSpec *pspec,glong *aIndex,int iBuffLen);
  gchar * GetWord(glong index);
  gchar * GetWordData(glong index);
};

//============================================================================
class Libs{
private:
  std::string stardict_data_dir;
  Lib **oLib; // word library.
  gint libcount;
	
  void LoadDir(const gchar *dirname, const StringsList & enable_list, 
	       const StringsList & disable_list);
public:
  explicit Libs(const char *_stardict_data_dir=NULL);
  ~Libs();
      
  void Load(const StringsList & enable_list, const StringsList & disable_list);
  glong iLength(int iLib);
  gchar* GetBookname(int iLib);
  gchar* NameOfIfoFile(int iLib);
  inline gint total_libs() { return(libcount); }
  gchar * poGetWord(glong iIndex,int iLib);
  gchar * poGetWordData(glong iIndex,int iLib);
  gchar * poGetCurrentWord(glong * iCurrent);
  gchar * poGetNextWord(const gchar *word,glong * iCurrent);
  gchar * poGetPreWord(glong * iCurrent);
  gboolean LookupWord(const gchar* sWord,glong& iWordIndex,int iLib);
  gboolean LookupSimilarWord(const gchar* sWord,glong& iWordIndex,int iLib);
  gboolean SimpleLookupWord(const gchar* sWord,glong& iWordIndex,int iLib);
  gboolean LookdupWordsWithRule(GPatternSpec *pspec,glong* aiIndexes,int iLen,
				int iLib);
};

inline gboolean bIsVowel(gchar inputchar);

#endif
