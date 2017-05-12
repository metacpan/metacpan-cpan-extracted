//////////////////////////////////////////////////////////////////
//
//    FreeLing - Open Source Language Analyzers
 //
//    Copyright (C) 2004   TALP Research Center
//                         Universitat Politecnica de Catalunya
//
//    This library is free software; you can redistribute it and/or
//    modify it under the terms of the GNU General Public
//    License as published by the Free Software Foundation; either
//    version 2.1 of the License, or (at your option) any later version.
//
//    This library is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//    General Public License for more details.
//
//    You should have received a copy of the GNU General Public
//    License along with this library; if not, write to the Free Software
//    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
//
//    contact: Lluis Padro (padro@lsi.upc.es)
//             TALP Research Center
//             despatx C6.212 - Campus Nord UPC
//             08034 Barcelona.  SPAIN
//
////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////
//
//  freeling_perlAPI.i
//  This is the SWIG input file, used to generate perl API.
//
////////////////////////////////////////////////////////////////

%module "Lingua::FreeLing3::Bindings"

%{
 #include "freeling.h"
 #include "freeling/tree.h"
 #include "freeling/morfo/traces.h"
 using namespace std;
%}

////////////////////////////////////////////////////////////////
//
//  templates.i
//  This is a SWIG input file, used to generate java/perl/python APIs.
//
////////////////////////////////////////////////////////////////

%include swig_backups/std_list.i
%include swig_backups/std_vector.i
%include std_map.i
%include std_pair.i

%template(VectorWord) std::vector<freeling::word>;
%template(ListWord) std::list<freeling::word>;
%template(ListAnalysis) std::list<freeling::analysis>;
%template(ListSentence) std::list<freeling::sentence>;
%template(ListParagraph) std::list<freeling::paragraph>;

%template(ListString) std::list<std::wstring>;
%template(ListInt) std::list<int>;
%template(VectorListInt) std::vector<std::list<int> >;
%template(VectorListString) std::vector<std::list<std::wstring> >;
%template(VectorString) std::vector<std::wstring>;

%template(PairDoubleString) std::pair<double,std::wstring >;
%template(VectorPairDoubleString) std::vector<std::pair<double,std::wstring> >;

%template(PairStringString) std::pair<std::wstring,std::wstring >;
%template(VectorPairStringString) std::vector<std::pair<std::wstring,std::wstring> >;

### Typemaps ###

%typemap(in) const std::wstring & (std::wstring wtemp)  {
  std::string aux (SvPV($input, PL_na));
  wtemp = freeling::util::string2wstring(aux);
  $1 = &wtemp;
}

%typemap(in) std::wstring (std::wstring wtemp) {
  std::string aux (SvPV($input, PL_na));
  wtemp = freeling::util::string2wstring(aux);
  $1 = wtemp;
}

%typemap(out) const std::wstring & {
  std::string temp;
  temp = freeling::util::wstring2string($1);
  $result = sv_2mortal(newSVpv(temp.c_str(), 0));
  argvi++;
  SvUTF8_on ($result);
} 

%typemap(out) std::list< std::wstring > {
  std::list<std::wstring>::const_iterator i;
  unsigned int j;
  int len = (& $1)->size();
  SV **svs = new SV*[len];
  for (i=(& $1)->begin(), j=0; i!=(& $1)->end(); i++, j++) {
    std::string ptr = freeling::util::wstring2string(*i);
    svs[j] = sv_2mortal(newSVpv(ptr.c_str(), 0));
    SvUTF8_on(svs[j]);
  }
  AV *myav = av_make(len, svs);
  delete[] svs;
  $result = newRV_noinc((SV*) myav);
  sv_2mortal($result);
  argvi++;
}

%typemap(out) std::wstring = const std::wstring &;

%typemap(typecheck) const std::wstring & = char *;

#define FL_API_PERL
////////////////////////////////////////////////////////////////
//
//  freeling.i
//  This is the SWIG input file, used to generate java/perl/python APIs.
//
////////////////////////////////////////////////////////////////
 

%rename(operator_assignment) operator=;

///////////////  FREELING LANGUAGE DATA CLASSES /////////////

namespace freeling {

// predeclarations
template <class T> class tree;

template <class T> class generic_iterator;
template <class T> class preorder_iterator;
template <class T> class sibling_iterator;

template <class T> class generic_const_iterator;
template <class T> class const_preorder_iterator;
template <class T> class const_sibling_iterator;

/// Generic iterator, to derive all the others
template<class T, class N>
class tree_iterator {
 protected:
  N *pnode;
 public: 
  tree_iterator();
  tree_iterator(tree<T> *);
  tree_iterator(const tree_iterator<T,N> &);
  ~tree_iterator();

  const tree<T>& operator*() const;
  const tree<T>* operator->() const;
  bool operator==(const tree_iterator<T,N> &) const;
  bool operator!=(const tree_iterator<T,N> &) const;
};

template<class T>
class generic_iterator : public tree_iterator<T,tree<T> > {
 friend class generic_const_iterator<T>;
 public:
  generic_iterator();
  generic_iterator(tree<T> *);
  generic_iterator(const generic_iterator<T> &);
  tree<T>& operator*() const;
  tree<T>* operator->() const;
  ~generic_iterator();
};

/// sibling iterator: traverse all children of the same node

template<class T>
class sibling_iterator : public generic_iterator<T> {
 public:
  sibling_iterator();
  sibling_iterator(const sibling_iterator<T> &);
  sibling_iterator(tree<T> *);
  ~sibling_iterator();

  #ifndef FL_API_PYTHON
  sibling_iterator& operator++();
  sibling_iterator& operator--();
  sibling_iterator operator++(int);
  sibling_iterator operator--(int);
  #endif
};

/// traverse the tree in preorder (parent first, then children)
template<class T>
class preorder_iterator : public generic_iterator<T> {
 public:
  preorder_iterator();
  preorder_iterator(const preorder_iterator<T> &);
  preorder_iterator(tree<T> *);
  preorder_iterator(const sibling_iterator<T> &);
  ~preorder_iterator();

  #ifndef FL_API_PYTHON
  preorder_iterator& operator++();
  preorder_iterator& operator--();
  preorder_iterator operator++(int);
  preorder_iterator operator--(int);
  #endif
};

#ifndef FL_API_JAVA
template<class T>
class generic_const_iterator : public tree_iterator<T,const tree<T> >  {
 public:
  generic_const_iterator();
  generic_const_iterator(const generic_iterator<T> &);
  generic_const_iterator(const generic_const_iterator<T> &);
  generic_const_iterator(const tree<T> *);
  ~generic_const_iterator();
};

template<class T>
class const_sibling_iterator : public generic_const_iterator<T> {
 public:
  const_sibling_iterator();
  const_sibling_iterator(const const_sibling_iterator<T> &);
  const_sibling_iterator(const sibling_iterator<T> &);
  const_sibling_iterator(tree<T> *);
  ~const_sibling_iterator();

  #ifndef FL_API_PYTHON
  const_sibling_iterator& operator++();
  const_sibling_iterator& operator--();
  const_sibling_iterator operator++(int);
  const_sibling_iterator operator--(int);
  #endif
};

template<class T>
class const_preorder_iterator : public generic_const_iterator<T> {
 public:
  const_preorder_iterator();
  const_preorder_iterator(tree<T> *);
  const_preorder_iterator(const const_preorder_iterator<T> &);
  const_preorder_iterator(const preorder_iterator<T> &);
  const_preorder_iterator(const const_sibling_iterator<T> &);
  const_preorder_iterator(const sibling_iterator<T> &);
  ~const_preorder_iterator();
  
  #ifndef FL_API_PYTHON
  const_preorder_iterator& operator++();
  const_preorder_iterator& operator--();
  const_preorder_iterator operator++(int);
  const_preorder_iterator operator--(int);
  #endif
};
#endif

template <class T> 
class tree { 
  friend class preorder_iterator<T>;
  friend class sibling_iterator<T>;

  #ifndef FL_API_JAVA
  friend class const_preorder_iterator<T>;
  friend class const_sibling_iterator<T>;
  #endif

 public:
  T info;
  typedef class preorder_iterator<T> preorder_iterator;
  typedef class sibling_iterator<T> sibling_iterator;
  typedef preorder_iterator iterator;
  #ifndef FL_API_JAVA
  typedef class const_preorder_iterator<T> const_preorder_iterator;
  typedef class const_sibling_iterator<T> const_sibling_iterator;
  typedef const_preorder_iterator const_iterator;
  #endif

  tree();
  tree(const T&);
  tree(const tree<T>&);
  tree(const typename tree<T>::preorder_iterator&);
  ~tree();
  tree<T>& operator=(const tree<T>&);

  unsigned int num_children() const;
  sibling_iterator nth_child(unsigned int) const;
  iterator get_parent() const;
  tree<T> & nth_child_ref(unsigned int) const;
  T& get_info();
  void append_child(const tree<T> &);
  void hang_child(tree<T> &, bool=true);
  void clear();
  bool empty() const;

  sibling_iterator sibling_begin();
  sibling_iterator sibling_end();
  sibling_iterator sibling_rbegin();
  sibling_iterator sibling_rend();
  preorder_iterator begin();
  preorder_iterator end();

  #ifndef FL_API_JAVA
  const_sibling_iterator sibling_begin() const;
  const_sibling_iterator sibling_end() const;
  const_sibling_iterator sibling_rbegin() const;
  const_sibling_iterator sibling_rend() const;
  const_preorder_iterator begin() const;
  const_preorder_iterator end() const;
  #endif
};
 

%template(TreeIteratorNode) tree_iterator<freeling::node,tree<freeling::node> >;
%template(GenericIteratorNode) generic_iterator<freeling::node>;
%template(PreorderIteratorNode) preorder_iterator<freeling::node>;
%template(SiblingIteratorNode) sibling_iterator<freeling::node>;

%template(TreeIteratorDepnode) tree_iterator<freeling::depnode,tree<freeling::depnode> >;
%template(GenericIteratorDepnode) generic_iterator<freeling::depnode>;
%template(PreorderIteratorDepnode) preorder_iterator<freeling::depnode>;
%template(SiblingIteratorDepnode) sibling_iterator<freeling::depnode>;

#ifndef FL_API_JAVA
%template(TreeIteratorNodeConst) tree_iterator<freeling::node,tree<freeling::node> const>;
%template(GenericConstIteratorNode) generic_const_iterator<freeling::node>;
%template(ConstPreorderIteratorNode) const_preorder_iterator<freeling::node>;
%template(ConstSiblingIteratorNode) const_sibling_iterator<freeling::node>;

%template(TreeIteratorDepnodeConst) tree_iterator<freeling::depnode,tree<freeling::depnode> const>;
%template(GenericConstIteratorDepnode) generic_const_iterator<freeling::depnode>;
%template(ConstPreorderIteratorDepnode) const_preorder_iterator<freeling::depnode>;
%template(ConstSiblingIteratorDepnode) const_sibling_iterator<freeling::depnode>;
#endif

%template(TreeNode) tree<freeling::node>;
%template(TreeDepnode) tree<freeling::depnode>;


class analysis {
   public:
      /// user-managed data, we just store it.
      std::vector<std::wstring> user;

      /// constructor
      analysis();
      /// constructor
      analysis(const std::wstring &, const std::wstring &);
      /// assignment
      analysis& operator=(const analysis&);
      ~analysis();

      void init(const std::wstring &l, const std::wstring &t);
      void set_lemma(const std::wstring &);
      void set_tag(const std::wstring &);
      void set_prob(double);
      void set_distance(double);
      void set_retokenizable(const std::list<freeling::word> &);

      bool has_prob() const;

      bool has_distance() const;
      std::wstring get_lemma() const;
      std::wstring get_tag() const;
      double get_prob() const;
      double get_distance() const;
      bool is_retokenizable() const;
      std::list<freeling::word> get_retokenizable() const;

      std::list<std::pair<std::wstring,double> > get_senses() const;
      void set_senses(const std::list<std::pair<std::wstring,double> > &);
      // useful for java API
      std::wstring get_senses_string() const;

      /// Comparison to sort analysis by *decreasing* probability
      bool operator>(const analysis &) const;
      /// Comparison to sort analysis by *increasing* probability
      bool operator<(const analysis &) const;
      /// Comparison (to please MSVC)
      bool operator==(const analysis &) const;

      // find out whether the analysis is selected in the tagger
      // k-th best sequence
      bool is_selected(int k=0) const;
      // mark this analysis as selected in k-th best sequence
      void mark_selected(int k=0);
      // unmark this analysis as selected in k-th best sequence
      void unmark_selected(int k=0);
};


////////////////////////////////////////////////////////////////
///   Class word stores all info related to a word: 
///  form, list of analysis, list of tokens (if multiword).
////////////////////////////////////////////////////////////////

class word : public std::list<freeling::analysis> {
   public:
      /// user-managed data, we just store it.
      std::vector<std::wstring> user;

      /// constructor
      word();
      /// constructor
      word(const std::wstring &);
      /// constructor
      word(const std::wstring &, const std::list<freeling::word> &);
      /// constructor
      word(const std::wstring &, const std::list<freeling::analysis> &, const std::list<freeling::word> &);
      /// Copy constructor
      word(const word &);
      /// assignment
      word& operator=(const word&);

      ~word();

      /// copy analysis from another word
      void copy_analysis(const word &);
      /// Get the number of selected analysis
      int get_n_selected() const;
      /// get the number of unselected analysis
      int get_n_unselected() const;
      /// true iff the word is a multiword compound
      bool is_multiword() const;
      /// true iff the word is a multiword marked as ambiguous
      bool is_ambiguous_mw() const;
      /// set mw ambiguity status
      void set_ambiguous_mw(bool);
      /// get number of words in compound
      int get_n_words_mw() const;
      /// get word objects that compound the multiword
      const std::list<freeling::word> &get_words_mw() const;
      /// get word form
      std::wstring get_form() const;
      /// Get word form, lowercased.
      std::wstring get_lc_form() const;
      /// Get word phonetic form
      std::wstring get_ph_form() const;
      /// Get an iterator to the first selected analysis
      word::iterator selected_begin(int k=0);
      /// Get an iterator to the end of selected analysis list
      word::iterator selected_end(int k=0);
      /// Get an iterator to the first unselected analysis
      word::iterator unselected_begin(int k=0);
      /// Get an iterator to the end of unselected analysis list
      word::iterator unselected_end(int k=0);

      #ifndef FL_API_JAVA
      /// Get an iterator to the first selected analysis
      word::const_iterator selected_begin(int k=0) const;
      /// Get an iterator to the end of selected analysis list
      word::const_iterator selected_end(int k=0) const;
      /// Get an iterator to the first unselected analysis
      word::const_iterator unselected_begin(int k=0) const;
      /// Get an iterator to the end of unselected analysis list
      word::const_iterator unselected_end(int k=0) const;
      #endif

      /// Get how many kbest tags the word has
      unsigned int num_kbest() const;
      /// get lemma for the selected analysis in list
      std::wstring get_lemma(int k=0) const;
      /// get tag for the selected analysis
      std::wstring get_tag(int k=0) const;

      /// get sense list for the selected analysis
      std::list<std::pair<std::wstring,double> > get_senses(int k=0) const;
      // useful for java API
      std::wstring get_senses_string(int k=0) const;
      /// set sense list for the selected analysis
      void set_senses(const std::list<std::pair<std::wstring,double> > &,int k=0);

      /// get token span.
      unsigned long get_span_start() const;
      unsigned long get_span_finish() const;

      /// get in_dict
      bool found_in_dict() const;
      /// set in_dict
      void set_found_in_dict(bool);
      /// check if there is any retokenizable analysis
      bool has_retokenizable() const;
      /// mark word as having definitive analysis
      void lock_analysis();
      /// check if word is marked as having definitive analysis
      bool is_locked() const;

      /// add an alternative to the alternatives list
      void add_alternative(const std::wstring &, int);
      /// replace alternatives list with list given
      void set_alternatives(const std::list<std::pair<std::wstring,int> > &);
      /// clear alternatives list
      void clear_alternatives();
      /// find out if the speller checked alternatives
      bool has_alternatives() const;
      /// get alternatives list &
      std::list<std::pair<std::wstring,int> >& get_alternatives();
      /// get alternatives begin iterator
      std::list<std::pair<std::wstring,int> >::iterator alternatives_begin();
      /// get alternatives end iterator
      std::list<std::pair<std::wstring,int> >::iterator alternatives_end();

      #ifndef FL_API_JAVA
      /// get alternatives list const &
      const std::list<std::pair<std::wstring,int> >& get_alternatives() const;
      /// get alternatives begin iterator
      std::list<std::pair<std::wstring,int> >::const_iterator alternatives_begin() const;
      /// get alternatives end iterator
      std::list<std::pair<std::wstring,int> >::const_iterator alternatives_end() const;
      #endif

      /// add one analysis to current analysis list  (no duplicate check!)
      void add_analysis(const analysis &);
      /// set analysis list to one single analysis, overwriting current values
      void set_analysis(const analysis &);
      /// set analysis list, overwriting current values
      void set_analysis(const std::list<freeling::analysis> &);
      /// set word form
      void set_form(const std::wstring &);
      /// Set word phonetic form
      void set_ph_form(const std::wstring &);
      /// set token span
      void set_span(unsigned long, unsigned long);

      // get/set word position in sentence
      void set_position(size_t);
      size_t get_position() const;

      /// look for an analysis with a tag matching given regexp
      bool find_tag_match(freeling::regexp &);

      /// get number of analysis in current list
      int get_n_analysis() const;
      /// empty the list of selected analysis
      void unselect_all_analysis(int k=0);
      /// mark all analysisi as selected
      void select_all_analysis(int k=0);
      /// add the given analysis to selected list.
      void select_analysis(word::iterator, int k=0);
      /// remove the given analysis from selected list.
      void unselect_analysis(word::iterator, int k=0);
      /// get list of analysis (useful for perl API)
      std::list<freeling::analysis> get_analysis() const;
      /// get begin iterator to analysis list (useful for perl/java API)
      word::iterator analysis_begin();
      /// get end iterator to analysis list (useful for perl/java API)
      word::iterator analysis_end();
      #ifndef FL_API_JAVA
      /// get begin iterator to analysis list (useful for perl/java API)
      word::const_iterator analysis_begin() const;
      /// get end iterator to analysis list (useful for perl/java API)
      word::const_iterator analysis_end() const;
      #endif
};

////////////////////////////////////////////////////////////////
///   Class parse tree is used to store the results of parsing
///  Each node in the tree is either a label (intermediate node)
///  or a word (leaf node)
////////////////////////////////////////////////////////////////

class node {
  public:
    /// constructors
    node();
    node(const std::wstring &);
    ~node();

    /// get node identifier
    std::wstring get_node_id() const;
    /// set node identifier
    void set_node_id(const std::wstring &);
    /// get node label
    std::wstring get_label() const;
    /// get node word
    word & get_word();
    #ifndef FL_API_JAVA
    const word & get_word() const;
    #endif
    /// set node label
    void set_label(const std::wstring &);
    /// set node word
    void set_word(word &);
    /// find out whether node is a head
    bool is_head() const;
    /// set whether node is a head
    void set_head(const bool);
    /// find out whether node is a chunk
    bool is_chunk() const;
    /// set position of the chunk in the sentence
    void set_chunk(const int);
    /// get position of the chunk in the sentence
    int  get_chunk_ord() const;
};

////////////////////////////////////////////////////////////////
/// class dep_tree stores a constituent tree
////////////////////////////////////////////////////////////////

class parse_tree : public tree<freeling::node> {
  public:
    parse_tree();
    parse_tree(parse_tree::iterator p);
    parse_tree(const node &);

    /// assign an id to each node and build index
    void build_node_index(const std::wstring &);
    /// rebuild index maintaining node id's
    void rebuild_node_index();
    /// access the node with given id
    parse_tree::iterator get_node_by_id(const std::wstring &);
    /// access the node by word position
    parse_tree::iterator get_node_by_pos(size_t);

    #ifndef FL_API_JAVA
    /// access the node with given id
    parse_tree::const_iterator get_node_by_id(const std::wstring &) const;
    /// access the node by word position
    parse_tree::const_iterator get_node_by_pos(size_t) const;
    #endif
};


////////////////////////////////////////////////////////////////
/// class denode stores nodes of a dependency tree and
///  parse tree <-> deptree relations
////////////////////////////////////////////////////////////////

class depnode : public node {
  public:
    depnode();
    depnode(const std::wstring &);
    depnode(const node &);
    ~depnode();

    void set_link(const parse_tree::iterator);
    parse_tree::iterator get_link(void);
    #ifndef FL_API_JAVA
    parse_tree::const_iterator get_link(void) const;
    #endif
    tree<freeling::node>& get_link_ref(void);

    // explicitly inherit from node (swig not always ports 
    // correctly class hierarchies)
    void set_label(const std::wstring &);
};

////////////////////////////////////////////////////////////////
/// class dep_tree stores a dependency tree
////////////////////////////////////////////////////////////////

class dep_tree :  public tree<freeling::depnode> {
  public:
    dep_tree();
    dep_tree(const depnode &);

    /// get depnode corresponding to word in given position
    dep_tree::iterator get_node_by_pos(size_t);
    #ifndef FL_API_JAVA
    /// get depnode corresponding to word in given position
    dep_tree::const_iterator get_node_by_pos(size_t) const;
    #endif
    /// rebuild index maintaining words positions
    void rebuild_node_index();
};


////////////////////////////////////////////////////////////////
///   Class sentence is just a list of words that someone
/// (the splitter) has validated it as a complete sentence.
/// It may include a parse tree.
////////////////////////////////////////////////////////////////

class sentence : public std::list<freeling::word> {
 public:
  sentence();
  sentence(const std::list<freeling::word>&);
  /// Copy constructor
  sentence(const sentence &);
  /// assignment
  sentence& operator=(const sentence&);

  // destructor
  ~sentence();

  /// find out how many kbest sequences the tagger computed
  unsigned int num_kbest() const;
  /// add a word to the sentence
  void push_back(const word &);
  /// rebuild word positional index
  void rebuild_word_index();
  // empty sentence
  void clear(); 

  // get/set sentence id
  void set_sentence_id(const std::wstring &);
  std::wstring get_sentence_id();

  void set_parse_tree(const parse_tree &, int k=0);
  parse_tree & get_parse_tree(int k=0);
  #ifndef FL_API_JAVA
  const parse_tree & get_parse_tree(int k=0) const;
  #endif
  bool is_parsed() const;  

  void set_dep_tree(const dep_tree &, int k=0);
  dep_tree & get_dep_tree(int k=0);
  #ifndef FL_API_JAVA
  const dep_tree & get_dep_tree(int k=0) const;
  #endif
  bool is_dep_parsed() const;

  /// get word list (useful for perl API)
  std::vector<freeling::word> get_words() const;
  /// get iterators to word list (useful for perl/java API)
  sentence::iterator words_begin(void);
  sentence::iterator words_end(void);

  #ifndef FL_API_JAVA
  sentence::const_iterator words_begin(void) const;
  sentence::const_iterator words_end(void) const;
  #endif
};

////////////////////////////////////////////////////////////////
///   Class paragraph is just a list of sentences that someone
///  has validated it as a paragraph.
////////////////////////////////////////////////////////////////

class paragraph : public std::list<freeling::sentence> {};

////////////////////////////////////////////////////////////////
///   Class document is a list of paragraphs. It may have additional 
///  information (such as title)
////////////////////////////////////////////////////////////////

class document : public std::list<freeling::paragraph> {
 public:
    document();
    ~document();

    void add_positive(const std::wstring &, int);
    void add_positive(const std::wstring &, const std::wstring &);
    int get_coref_group(const std::wstring &) const;
    std::list<std::wstring> get_coref_nodes(int) const;
    bool is_coref(const std::wstring &, const std::wstring &) const;
};



////////////////  FREELING ANALYSIS MODULES  ///////////////////


/*------------------------------------------------------------------------*/
class traces {
 public:
    // current trace level
    static int TraceLevel;
    // modules to trace
    static unsigned long TraceModule;
};


/*------------------------------------------------------------------------*/
class lang_ident {
   public:
      /// constructor
      lang_ident();
      lang_ident (const std::wstring &);
      ~lang_ident();

      void add_language(const std::wstring&);
      /// train a model for a language, store in modelFile, and add 
      /// it to the known languages list.
      void train_language(const std::wstring &, const std::wstring &, const std::wstring &);

      /// Identify language, return most likely language for given text,
      /// consider only languages in given set (empty --> all available languages)
      std::wstring identify_language(const std::wstring &, 
      				     const std::set<std::wstring> &ls=std::set<std::wstring>()) const;
      /// Identify language, return list of pairs<probability,language> 
      /// sorted by decreasing probability. Consider only languages
      /// in given set (empty --> all available languages).
      void rank_languages(std::vector<std::pair<double,std::wstring> > &, 
      			  const std::wstring &, 
      			  const std::set<std::wstring> &ls=std::set<std::wstring>()) const;
};


/*------------------------------------------------------------------------*/
class tokenizer {
   public:
       /// Constructor
       tokenizer(const std::wstring &);
       ~tokenizer();

       /// tokenize wstring 
       void tokenize(const std::wstring &, std::list<word> &) const;
       std::list<freeling::word> tokenize(const std::wstring &) const;
       /// tokenize string, tracking offset
       void tokenize(const std::wstring &, unsigned long &, std::list<word> &) const;
       std::list<freeling::word> tokenize(const std::wstring &, unsigned long &) const;
};

/*------------------------------------------------------------------------*/
class splitter {
   public:
      /// Constructor
      splitter(const std::wstring &);
      ~splitter();

      /// split sentences with default options
      void split(const std::list<word> &, bool, std::list<sentence> &ls);
      std::list<freeling::sentence> split(const std::list<freeling::word> &, bool);
};


/*------------------------------------------------------------------------*/
class maco_options {
 public:
    // Language analyzed
    std::wstring Lang;

    /// Morhpological analyzer active modules.
    bool AffixAnalysis,   MultiwordsDetection, 
         NumbersDetection, PunctuationDetection, 
         DatesDetection,   QuantitiesDetection, 
         DictionarySearch, ProbabilityAssignment,
         UserMap, NERecognition;

    /// Morphological analyzer modules configuration/data files.
    std::wstring LocutionsFile, QuantitiesFile, AffixFile, 
           ProbabilityFile, DictionaryFile, 
           NPdataFile, PunctuationFile,
           UserMapFile;

    /// module-specific parameters for number recognition
    std::wstring Decimal, Thousand;
    /// module-specific parameters for probabilities
    double ProbabilityThreshold;
    /// module-specific parameters for dictionary
    bool InverseDict,RetokContractions;

    /// constructor
    maco_options(const std::wstring &);
    ~maco_options();

    /// Option setting methods provided to ease perl interface generation. 
    /// Since option data members are public and can be accessed directly
    /// from C++, the following methods are not necessary, but may become
    /// convenient sometimes.
    void set_active_modules(bool,bool,bool,bool,bool,bool,bool,bool,bool,bool,bool dummy=false);
    void set_data_files(const std::wstring &,const std::wstring &,const std::wstring &,
                        const std::wstring &,const std::wstring &,const std::wstring &,
                        const std::wstring &,const std::wstring &, const std::wstring &dummy="");

    void set_nummerical_points(const std::wstring &,const std::wstring &);
    void set_threshold(double);
    void set_inverse_dict(bool);
    void set_retok_contractions(bool);
};

/*------------------------------------------------------------------------*/
class maco {
   public:
      /// Constructor
      maco(const maco_options &);
      ~maco();

      #ifndef FL_API_JAVA
      /// analyze sentence
      sentence analyze(const sentence &) const;
      /// analyze sentences
      std::list<freeling::sentence> analyze(const std::list<freeling::sentence> &) const;
      #else
      /// analyze sentence
      void analyze(sentence &) const;
      /// analyze sentences
      void analyze(std::list<freeling::sentence> &) const;
      #endif
};


/*------------------------------------------------------------------------*/
class RE_map {
    
 public:
  /// Constructor (config file)
  RE_map(const std::wstring &); 
  ~RE_map();

  /// annotate given word
  void annotate_word(word &) const;
 
  #ifndef FL_API_JAVA
  /// analyze sentence
  sentence analyze(const sentence &) const;
  /// analyze sentences
  std::list<freeling::sentence> analyze(const std::list<freeling::sentence> &) const;
  #else
  /// analyze sentence
  void analyze(sentence &) const;
  /// analyze sentences
  void analyze(std::list<freeling::sentence> &) const;
  #endif
};

/*------------------------------------------------------------------------*/
class numbers {
  public:
    // constructor: language (en), decimal (.), thousands (,)
    numbers(const std::wstring &, const std::wstring &, const std::wstring &);
    ~numbers();

    #ifndef FL_API_JAVA
    /// analyze sentence
    sentence analyze(const sentence &) const;
    /// analyze sentences
    std::list<freeling::sentence> analyze(const std::list<freeling::sentence> &) const;
    #else
    /// analyze sentence
    void analyze(sentence &) const;
    /// analyze sentences
    void analyze(std::list<freeling::sentence> &) const;
    #endif
};


/*------------------------------------------------------------------------*/
class punts {
 public:
  /// Constructor (config file)
  punts(const std::wstring &); 
  ~punts();

  #ifndef FL_API_JAVA
  /// analyze sentence
  sentence analyze(const sentence &) const;
  /// analyze sentences
  std::list<freeling::sentence> analyze(const std::list<freeling::sentence> &) const;
  #else
  /// analyze sentence
  void analyze(sentence &) const;
  /// analyze sentences
  void analyze(std::list<freeling::sentence> &) const;
  #endif
};

/*------------------------------------------------------------------------*/ 
class dates {
 public:   
  /// Constructor (config file)
  dates(const std::wstring &); 
  /// Destructor
  ~dates(); 

  #ifndef FL_API_JAVA
  /// analyze sentence
  sentence analyze(const sentence &) const;
  /// analyze sentences
  std::list<freeling::sentence> analyze(const std::list<freeling::sentence> &) const;
  #else
  /// analyze sentence
  void analyze(sentence &) const;
  /// analyze sentences
  void analyze(std::list<freeling::sentence> &) const;
  #endif
};  

/*------------------------------------------------------------------------*/
class dictionary {
 public:
  /// Constructor
  dictionary(const std::wstring &, const std::wstring &, bool, const std::wstring &, bool invDic=false, bool retok=true);
  /// Destructor
  ~dictionary();

  /// add analysis to dictionary entry (create entry if not there)
  void add_analysis(const std::wstring &, const analysis &);
  /// remove entry from dictionary
  void remove_entry(const std::wstring &);

  /// Get dictionary entry for a given form, add to given list.
  void search_form(const std::wstring &, std::list<freeling::analysis> &) const;
  /// Fills the analysis list of a word, checking for suffixes and contractions.
  /// Returns true iff the form is a contraction.
  bool annotate_word(word &, std::list<freeling::word> &, bool override=false) const;
  /// convenience equivalent to "annotate_word(w,dummy,true)"
  void annotate_word(word &) const;

  /// Get possible forms for a lemma+pos
  std::list<std::wstring> get_forms(const std::wstring &, const std::wstring &) const;

  #ifndef FL_API_JAVA
  /// analyze sentence, return analyzed copy
  sentence analyze(const sentence &) const;
  /// analyze sentences, return analyzed copy
  std::list<freeling::sentence> analyze(const std::list<freeling::sentence> &) const;
  #else
  /// analyze given sentence
  void analyze(sentence &) const;
  /// analyze given sentences
  void analyze(std::list<freeling::sentence> &) const;
  #endif
};

/*------------------------------------------------------------------------*/
class locutions {
 public:
  /// Constructor (config file)
  locutions(const std::wstring &);
  ~locutions();
  void add_locution(const std::wstring &);

  #ifndef FL_API_JAVA
  /// analyze sentence
  sentence analyze(const sentence &) const;
  /// analyze sentences
  std::list<freeling::sentence> analyze(const std::list<freeling::sentence> &) const;
  #else
  /// analyze sentence
  void analyze(sentence &) const;
  /// analyze sentences
  void analyze(std::list<freeling::sentence> &) const;
  #endif
};

/*------------------------------------------------------------------------*/
class ner {
 public:
  /// Constructor (config file)
  ner(const std::wstring &);
  /// Destructor
  ~ner();

  #ifndef FL_API_JAVA
  /// analyze sentence
  sentence analyze(const sentence &) const;
  /// analyze sentences
  std::list<freeling::sentence> analyze(const std::list<freeling::sentence> &) const;
  #else
  /// analyze sentence
  void analyze(sentence &) const;
  /// analyze sentences
  void analyze(std::list<freeling::sentence> &) const;
  #endif
};

/*------------------------------------------------------------------------*/
class quantities {
 public:
  /// Constructor (language, config file)
  quantities(const std::wstring &, const std::wstring &); 
  /// Destructor
  ~quantities(); 

  #ifndef FL_API_JAVA
  /// analyze sentence
  sentence analyze(const sentence &) const;
  /// analyze sentences
  std::list<freeling::sentence> analyze(const std::list<freeling::sentence> &) const;
  #else
  /// analyze sentence
  void analyze(sentence &) const;
  /// analyze sentences
  void analyze(std::list<freeling::sentence> &) const;
  #endif
};

/*------------------------------------------------------------------------*/
class probabilities {
 public:
  /// Constructor (language, config file, threshold)
  probabilities(const std::wstring &, double);
  ~probabilities();

  /// Assign probabilities for each analysis of given word
  void annotate_word(word &) const;
  /// Turn guesser on/of
  void set_activate_guesser(bool);

  #ifndef FL_API_JAVA
  /// analyze sentence
  sentence analyze(const sentence &) const;
  /// analyze sentences
  std::list<freeling::sentence> analyze(const std::list<freeling::sentence> &) const;
  #else
  /// analyze sentence
  void analyze(sentence &) const;
  /// analyze sentences
  void analyze(std::list<freeling::sentence> &) const;
  #endif
};

/*------------------------------------------------------------------------*/
class hmm_tagger {
 public:
  /// Constructor
  hmm_tagger(const std::wstring &, bool, unsigned int, unsigned int kb=1);
  ~hmm_tagger();
  
  /// Given an *annotated* sentence, compute (log) probability of k-th best
  /// sequence according to HMM parameters.
  double SequenceProb_log(const sentence &, int k=0) const;

  #ifndef FL_API_JAVA
  /// analyze sentence
  sentence analyze(const sentence &) const;
  /// analyze sentences
  std::list<freeling::sentence> analyze(const std::list<freeling::sentence> &) const;
  #else
  /// analyze sentence
  void analyze(sentence &) const;
  /// analyze sentences
  void analyze(std::list<freeling::sentence> &) const;
  #endif
};


/*------------------------------------------------------------------------*/
class relax_tagger {
 public:
  /// Constructor, given the constraints file and config parameters
  relax_tagger(const std::wstring &, int, double, double, bool, unsigned int);
  ~relax_tagger();

  #ifndef FL_API_JAVA
  /// analyze sentence
  sentence analyze(const sentence &) const;
  /// analyze sentences
  std::list<freeling::sentence> analyze(const std::list<freeling::sentence> &) const;
  #else
  /// analyze sentence
  void analyze(sentence &) const;
  /// analyze sentences
  void analyze(std::list<freeling::sentence> &) const;
  #endif
};

/*------------------------------------------------------------------------*/
  class alternatives {

  public:
    /// Constructor
    alternatives(const std::wstring &);
    /// Destructor
    ~alternatives();

    /// direct access to results of underlying automata
    void get_similar_words(const std::wstring &, std::list<std::pair<std::wstring,int> > &) const;

    #ifndef FL_API_JAVA
    /// analyze sentence
    sentence analyze(const sentence &) const;
    /// analyze sentences
    std::list<freeling::sentence> analyze(const std::list<freeling::sentence> &) const;
    #else
    /// analyze sentence
    void analyze(sentence &) const;
    /// analyze sentences
    void analyze(std::list<freeling::sentence> &) const;
    #endif

  };

/*------------------------------------------------------------------------*/
class phonetics {  
 public:
  /// Constructor, given config file
  phonetics(const std::wstring&);
  ~phonetics();
  
  /// Returns the phonetic sound of the word
  std::wstring get_sound(const std::wstring &) const;

  #ifndef FL_API_JAVA
  /// analyze sentence
  sentence analyze(const sentence &) const;
  /// analyze sentences
  std::list<freeling::sentence> analyze(const std::list<freeling::sentence> &) const;
  #else
  /// analyze sentence
  void analyze(sentence &) const;
  /// analyze sentences
  void analyze(std::list<freeling::sentence> &) const;
  #endif
};

/*------------------------------------------------------------------------*/
class nec {
 public:
  /// Constructor
  nec(const std::wstring &); 
  /// Destructor
  ~nec();
  
  #ifndef FL_API_JAVA
  /// analyze sentence
  sentence analyze(const sentence &) const;
  /// analyze sentences
  std::list<freeling::sentence> analyze(const std::list<freeling::sentence> &) const;
  #else
  /// analyze sentence
  void analyze(sentence &) const;
  /// analyze sentences
  void analyze(std::list<freeling::sentence> &) const;
  #endif
};


/*------------------------------------------------------------------------*/
class chart_parser {
 public:
   /// Constructors
   chart_parser(const std::wstring&);
   ~chart_parser();

   /// Get the start symbol of the grammar
   std::wstring get_start_symbol(void) const;

   #ifndef FL_API_JAVA
   /// analyze sentence
   sentence analyze(const sentence &) const;
   /// analyze sentences
   std::list<freeling::sentence> analyze(const std::list<freeling::sentence> &) const;
   #else
   /// analyze sentence
   void analyze(sentence &) const;
   /// analyze sentences
   void analyze(std::list<freeling::sentence> &) const;
   #endif
};


/*------------------------------------------------------------------------*/
class dep_txala {
 public:   
   dep_txala(const std::wstring &, const std::wstring &);
   ~dep_txala();

   #ifndef FL_API_JAVA
   /// analyze sentence
   sentence analyze(const sentence &) const;
   /// analyze sentences
   std::list<freeling::sentence> analyze(const std::list<freeling::sentence> &) const;
   #else
   /// analyze sentence
   void analyze(sentence &) const;
   /// analyze sentences, return analyzed copy
   void analyze(std::list<freeling::sentence> &) const;
   #endif
};



/*------------------------------------------------------------------------*/
class senses {
 public:
  /// Constructor
  senses(const std::wstring &); 
  /// Destructor
  ~senses(); 
  
  #ifndef FL_API_JAVA
  /// analyze sentence
  sentence analyze(const sentence &) const;
  /// analyze sentences
  std::list<freeling::sentence> analyze(const std::list<freeling::sentence> &) const;
  #else
  /// analyze sentence
  void analyze(sentence &) const;
  /// analyze sentences
  void analyze(std::list<freeling::sentence> &) const;
  #endif
};


/*------------------------------------------------------------------------*/
class ukb {
 public:
  /// Constructor
  ukb(const std::wstring &);
  /// Destructor
  ~ukb();
  
  #ifndef FL_API_JAVA
  /// analyze sentence
  sentence analyze(const sentence &) const;
  /// analyze sentences
  std::list<freeling::sentence> analyze(const std::list<freeling::sentence> &) const;
  #else
  /// analyze sentence
  void analyze(sentence &) const;
  /// analyze sentences
  void analyze(std::list<freeling::sentence> &) const;
  #endif
};


/*------------------------------------------------------------------------*/
class sense_info {
 public:
  /// sense code
  std::wstring sense;
  /// hyperonyms
  std::list<std::wstring> parents;
  /// WN semantic file code
  std::wstring semfile;
  /// list of synonyms (words in the synset)
  std::list<std::wstring> words;
  /// list of EWN top ontology properties
  std::list<std::wstring> tonto;

  /// constructor
  sense_info(const std::wstring &,const std::wstring &);
  std::wstring get_parents_string() const;
};


////////////////////////////////////////////////////////////////
/// Class semanticDB implements a semantic DB interface
////////////////////////////////////////////////////////////////

class semanticDB {
 public:
  /// Constructor
  semanticDB(const std::wstring &);
  /// Destructor
  ~semanticDB();
  
  /// Compute list of lemma-pos to search in WN for given word, according to mapping rules.
  void get_WN_keys(const std::wstring &, const std::wstring &, const std::wstring &, std::list<std::pair<std::wstring,std::wstring> > &) const;
  /// get list of words for a sense
  std::list<std::wstring> get_sense_words(const std::wstring &) const;
  /// get list of senses for a lemma+pos
  std::list<std::wstring> get_word_senses(const std::wstring &, const std::wstring &, const std::wstring &) const;
  /// get sense info for a sense
  sense_info get_sense_info(const std::wstring &) const;
};




////////////////////////////////////////////////////////////////
/// EAGLES tagset handler
////////////////////////////////////////////////////////////////

class tagset {

  public:
    /// constructor: load a map file
    tagset(const std::wstring &f);
    /// destructor
    ~tagset();

    /// get short version of given tag
    std::wstring get_short_tag(const std::wstring &tag) const;
    /// get list of <feature,value> pairs with morphological information
    std::list<std::pair<std::wstring,std::wstring> > get_msf_features(const std::wstring &tag) const;
    /// get list <feature,value> pairs with morphological information,
    ///  in a string format
    std::wstring get_msf_string(const std::wstring &tag) const;
};

////////////////////////////////////////////////////////////////
/// Wrapper for libfoma FSM

 class foma_FSM {

  public:
    /// build automaton from text file
    foma_FSM(const std::wstring &, const std::wstring &mcost=""); 
    /// clear 
    ~foma_FSM();

    /// Use automata to obtain closest matches to given form, and add them to given list.
    void get_similar_words(const std::wstring &, std::list<std::pair<std::wstring,int> > &) const;    
    /// set maximum edit distance of desired results
    void set_cutoff_threshold(int);
    /// set maximum number of desired results
    void set_num_matches(int);
    /// Set cost for basic SED operations
    void set_basic_operation_cost(int);
  };



////////////////////////////////////////////////////////////////
/// Utilities
////////////////////////////////////////////////////////////////

class util {
 public:
  /// Init the locale of the program, to properly handle unicode
  static void init_locale(const std::wstring &);

  /// conversion utilities
  static int wstring2int(const std::wstring &);
  static std::wstring int2wstring(const int);
  static double wstring2double(const std::wstring &);
  static std::wstring double2wstring(const double);
  static long double wstring2longdouble(const std::wstring &);
  static std::wstring longdouble2wstring(const long double);
  static std::wstring vector2wstring(const std::vector<std::wstring> &, const std::wstring &);
  static std::wstring list2wstring(const std::list<std::wstring> &, const std::wstring &);
  static std::wstring pairlist2wstring(const std::list<std::pair<std::wstring, double> > &, const std::wstring &, const std::wstring &);
  static std::wstring pairlist2wstring(const std::list<std::pair<std::wstring, std::wstring> > &, const std::wstring &, const std::wstring &);
  static std::list<std::wstring> wstring2list(const std::wstring &, const std::wstring &);
  static std::vector<std::wstring> wstring2vector(const std::wstring &, const std::wstring &);
};

}

%perlcode %{


__END__

=encoding utf8

=head1 NAME

 Lingua::FreeLing2::Bindings - Bindings to FreeLing library.

=head1 DESCRIPTION

This module is the base for the bindings between Perl and the C++
library, FreeLing. It was generated by Jorge Cunha Mendes, using as
base the module provided in the FreeLing distribution.

Given the high amount of modules and methods, the bindings are not
practical to be used directly. Therefore, C<Lingua::FreeLing>
encapsulates the binding behavior in more Perlish interfaces.

Please refer to L<Lingua::FreeLing> for the documentation table of
contents, and try not to use this module directly. You can always
request the authors an interface to any of these methods to be added
in the main modules.

=head1 SEE ALSO

Lingua::FreeLing2(3) for the documentation table of contents. The
freeling library for extra information, or perl(1) itself.

=head1 AUTHOR

Lluís Padró

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2013 by Projecto Natura

=cut

%}
