IndexReader *
open(CLASS, directory)
const char* CLASS
Directory* directory
    CODE:
        try {
          RETVAL = IndexReader::open(directory);
        } catch (CLuceneError& e) {
          die("[Lucene::Index::IndexReader->open()] %s\n", e.what());
        }

    OUTPUT:
        RETVAL
    CLEANUP:
        // Memorize Directory in returned blessed hash reference.
        // We don't want it to be destroyed by perl before the C++ object it
        // contains gets destroyed by C++. Otherwise this would cause a seg fault.
        hv_store((HV *) SvRV(ST(0)), "Directory", 9, newRV(SvRV(ST(1))), 1);

void
deleteDocument(self, doc_num)
IndexReader* self
const int32_t doc_num
    CODE:
        try {
          self->deleteDocument(doc_num);
        } catch (CLuceneError& e) {
          die("[Lucene::Index::IndexReader->deleteDocument()] %s\n", e.what());
        }

int
deleteDocuments(self, term)
IndexReader* self
Term* term
    CODE:
        try {
          RETVAL = self->deleteDocuments(term);
        } catch (CLuceneError& e) {
          die("[Lucene::Index::IndexReader->deleteDocuments()] %s\n", e.what());
        }
    OUTPUT:
        RETVAL

int
numDocs(self)
IndexReader* self
    CODE:
        RETVAL = self->numDocs();
    OUTPUT:
        RETVAL

int32_t
docFreq(self, term)
IndexReader* self
Term* term
    CODE:
        RETVAL = self->docFreq(term);
    OUTPUT:
        RETVAL

Document* 
document(self, n)
IndexReader* self
const int32_t n
    PREINIT:
      const char* CLASS = "Lucene::Document";
    CODE:
       RETVAL = self->document(n);
    OUTPUT:
       RETVAL

void
close(self)
IndexReader* self
    CODE:
        self->close();
    OUTPUT:

int
hasDeletions(self) 
IndexReader* self
    CODE:
        RETVAL = self->hasDeletions();
    OUTPUT:
        RETVAL

void
undeleteAll(self)
IndexReader* self
    CODE:
        self->undeleteAll();

void
unlock(CLASS, directory)
const char* CLASS
Directory* directory
    CODE:
        IndexReader::unlock(directory);

int
isLocked(CLASS, directory)
const char* CLASS
Directory* directory
    CODE:
        RETVAL = IndexReader::isLocked(directory);
    OUTPUT:
        RETVAL

int
indexExists(CLASS, directory)
const char* CLASS
Directory* directory
    CODE:
        RETVAL = IndexReader::indexExists(directory);
    OUTPUT:
        RETVAL

void
DESTROY(self)
IndexReader* self
    CODE:
        delete self;

