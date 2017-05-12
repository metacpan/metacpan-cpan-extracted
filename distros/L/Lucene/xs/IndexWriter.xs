IndexWriter *
new(CLASS, directory, analyzer, create)
const char* CLASS;
Directory* directory
Analyzer* analyzer
bool create
    CODE:
        try {
          RETVAL = new IndexWriter(directory, analyzer, create);
        } catch (CLuceneError& e) {
          die("[Lucene::Index::IndexWriter->new()] %s\n", e.what());
        }
    OUTPUT:
        RETVAL
    CLEANUP:
        // Memorize Directory and Analyzer in returned blessed hash reference.
        // We don't want them to be destroyed by perl before the C++ object they
        // contain gets destroyed by C++. Otherwise this would cause a seg fault.
        hv_store((HV *) SvRV(ST(0)), "Directory", 9, newRV(SvRV(ST(1))), 1);
        hv_store((HV *) SvRV(ST(0)), "Analyzer", 8, newRV(SvRV(ST(2))), 1);

void
addDocument(self, document)
IndexWriter* self
Document* document
    CODE:
        try {
          self->addDocument(document);
        } catch (CLuceneError& e) {
          die("[Lucene::Index::IndexWriter->addDocument()] %s\n", e.what());
        }
    OUTPUT:

void
addIndexes(self, ...)
IndexWriter* self
    PREINIT:
        int i;
        Directory **directories = NULL;
    CODE:
        directories = (Directory **) malloc(sizeof(Directory *) * items);
        for (i = 0; i < items - 1; i++) {
          directories[i] = SvToPtr<Directory *>(ST(i + 1));
        }
        directories[items - 1] = NULL;

        try {
          self->addIndexes(directories);
        } catch (CLuceneError& e) {
          die("[Lucene::Index::IndexWriter->addIndexes()] %s\n", e.what());
        }

        free(directories);


void setMaxFieldLength(self, max_tokens)
IndexWriter* self
int max_tokens
    CODE:
       self->setMaxFieldLength(max_tokens);


int getMaxFieldLength(self)
IndexWriter* self
    CODE:
        RETVAL = self->getMaxFieldLength();
    OUTPUT:
        RETVAL


void setMergeFactor(self, factor)
IndexWriter* self
int factor
    CODE:
       self->setMergeFactor(factor);


int getMergeFactor(self)
IndexWriter* self
    CODE:
        RETVAL = self->getMergeFactor();
    OUTPUT:
        RETVAL


void setMinMergeDocs(self, factor)
IndexWriter* self
int factor
    CODE:
       self->setMinMergeDocs(factor);


int getMinMergeDocs(self)
IndexWriter* self
    CODE:
        RETVAL = self->getMinMergeDocs();
    OUTPUT:
        RETVAL


void setMaxMergeDocs(self, factor)
IndexWriter* self
int factor
    CODE:
       self->setMaxMergeDocs(factor);


int getMaxMergeDocs(self)
IndexWriter* self
    CODE:
        RETVAL = self->getMaxMergeDocs();
    OUTPUT:
        RETVAL


void
setUseCompoundFile(self, value)
IndexWriter* self
bool value
    CODE:
        self->setUseCompoundFile(value);

void 
setSimilarity(self, similarity)
IndexWriter* self
Similarity* similarity
    CODE:
        self->setSimilarity(similarity);
    CLEANUP:
        // Memorize Directory and Analyzer in returned blessed hash reference.
        // We don't want them to be destroyed by perl before the C++ object they
        // contain gets destroyed by C++. Otherwise this would cause a seg fault.
        hv_store((HV *) SvRV(ST(0)), "Similarity", 10, newRV(SvRV(ST(1))), 1);

void
optimize(self)
IndexWriter* self
    CODE:
        try {
          self->optimize();
        } catch (CLuceneError& e) {
          die("[Lucene::Index::IndexWriter->optimize()] %s\n", e.what());
        }
    OUTPUT:

int
docCount(self)
IndexWriter* self
    CODE:
       RETVAL = self->docCount();
    OUTPUT:
       RETVAL

void
close(self)
IndexWriter* self
    CODE:
        self->close();
    OUTPUT:

void
DESTROY(self)
        IndexWriter * self
    CODE:
        delete self;

