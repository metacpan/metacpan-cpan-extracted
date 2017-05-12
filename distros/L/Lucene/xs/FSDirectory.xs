FSDirectory *
getDirectory(CLASS, path, create)
const char* CLASS;
const char* path
bool create
    CODE:
        try {
          RETVAL = FSDirectory::getDirectory(path, create);
        } catch (CLuceneError& e) {
          die("[Lucene::Store::FSDirectory->getDirectory()] %s\n", e.what());
        }
    OUTPUT:
        RETVAL

void 
close(self)
       FSDirectory * self
    CODE:
       self->close();

void
DESTROY(self)
       FSDirectory * self
    CODE:
       self->close();
       delete self;

