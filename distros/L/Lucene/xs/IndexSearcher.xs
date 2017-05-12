IndexSearcher *
new(CLASS, directory)
const char* CLASS;
Directory* directory
    CODE:
        RETVAL = new IndexSearcher(directory);
//        printf("created indexsearcher\n");
    OUTPUT:
        RETVAL
    CLEANUP:
        // Memorize Directory in returned blessed hash reference.
        // We don't want it to be destroyed by perl before the C++ object it
        // contains gets destroyed by C++. Otherwise this would cause a seg fault.
        hv_store((HV *) SvRV(ST(0)), "Directory", 9, newRV(SvRV(ST(1))), 1);


Hits * 
search(self, query, obj2 = 0, obj3 = 0)
    CASE: items == 2
        IndexSearcher* self
        Query* query
        PREINIT:
          const char* CLASS = "Lucene::Search::Hits";
        CODE:
          try {
            RETVAL = self->search(query);
          } catch (CLuceneError& e) {
            die("[Lucene::Search::IndexSearcher->search()] %s\n", e.what());
          }
        OUTPUT:
          RETVAL
    CASE: items == 3 && sv_derived_from(ST(2), "Lucene::Search::Sort")
        IndexSearcher* self
        Query* query
        Sort* obj2
        PREINIT:
          const char* CLASS = "Lucene::Search::Hits";
        CODE:
          try {
            RETVAL = self->search(query, obj2);
          } catch (CLuceneError& e) {
            die("[Lucene::Search::IndexSearcher->search()] %s\n", e.what());
          }
        OUTPUT:
          RETVAL
    CASE: items == 3
        IndexSearcher* self
        Query* query
        Filter* obj2
        PREINIT:
          const char* CLASS = "Lucene::Search::Hits";
        CODE:
          try {
            RETVAL = self->search(query, obj2);
          } catch (CLuceneError& e) {
            die("[Lucene::Search::IndexSearcher->search()] %s\n", e.what());
          }
        OUTPUT:
          RETVAL
    CASE: items == 4
        IndexSearcher* self
        Query* query
        Filter* obj2
        Sort* obj3
        PREINIT:
          const char* CLASS = "Lucene::Search::Hits";
        CODE:
          try {
            RETVAL = self->search(query, obj2, obj3);
          } catch (CLuceneError& e) {
            die("[Lucene::Search::IndexSearcher->search()] %s\n", e.what());
          }
        OUTPUT:
          RETVAL
    CASE:
       CODE:
         die("Usage: Lucene::Search::IndexSearcher::search(self, query, [sort | filter | filter, sort])");

void 
_search(self, query, hit_collector)
    IndexSearcher* self
    Query* query
    HitCollector* hit_collector
    CODE:
      try {
        self->_search(query, NULL, hit_collector);
      } catch (CLuceneError& e) {
        die("[Lucene::Search::IndexSearcher->_search()] %s\n", e.what());
      }


void
setSimilarity(self, similarity)
IndexSearcher* self
Similarity* similarity
    CODE:
        self->setSimilarity(similarity);
    CLEANUP:
        // This garantees that perl will keep the similarity for as long as
        // this object exists. Otherwise we might end up with a pointer to a
        // deleted similarity which will cause a seg fault
        hv_store((HV *) SvRV(ST(0)), "Similarity", 10, newRV(SvRV(ST(1))), 1);


void
close(self)
IndexSearcher* self
    CODE:
        self->close();
    OUTPUT:

Explanation*
explain(self, query, doc_num)
IndexSearcher* self
Query* query
int32_t doc_num
    PREINIT:
        const char* CLASS = "Lucene::Search::Explanation";
    CODE:
        Explanation* explanation = new Explanation();
        self->explain(query, doc_num, explanation);
        RETVAL = explanation;
    OUTPUT:
        RETVAL

void
DESTROY(self)
        IndexSearcher * self
    CODE:
        delete self;
//        printf("deleted indexsearcher\n");

