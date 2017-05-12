
int32_t
read(self, start = 0, len = 0)
    CASE: items == 1
            Reader* self
        CODE:
            try {
                RETVAL = self->read();
            } catch(CLuceneError& e) {
                die("[Lucene::Utils::Reader->read()] %s\n", e.what());
            }
        OUTPUT:
            RETVAL
    CASE: items == 2
            Reader* self
            const wchar_t* start
        CODE:
            try {
                RETVAL = self->read(start);
            } catch(CLuceneError& e) {
                die("[Lucene::Utils::Reader->read()] %s\n", e.what());
            }
        OUTPUT:
            RETVAL
    CASE: items == 3
            Reader* self
            const wchar_t *start
            int32_t len
        CODE:
            try {
                RETVAL = self->read(start, len);
            } catch(CLuceneError& e) {
                die("[Lucene::Utils::Reader->read()] %s\n", e.what());
            }
        OUTPUT:
            RETVAL

int64_t
skip(self, ntoskip)
        Reader* self
        int64_t ntoskip
    CODE:
        try {
            RETVAL = self->skip(ntoskip);
        } catch(CLuceneError& e) {
            die("[Lucene::Utils::Reader->skip()] %s\n", e.what());
        }
    OUTPUT:
        RETVAL


int64_t
mark(self, readAheadlimit)
        Reader* self
        int32_t readAheadlimit
    CODE:
        try {
            RETVAL = self->mark(readAheadlimit);
        } catch(CLuceneError& e) {
            die("[Lucene::Utils::Reader->mark()] %s\n", e.what());
        }
    OUTPUT:
        RETVAL

int64_t
reset(self, pos)
        Reader* self
        int64_t pos
    CODE:
        try {
            RETVAL = self->reset(pos);
        } catch(CLuceneError& e) {
            die("[Lucene::Utils::Reader->reset()] %s\n", e.what());
        }
    OUTPUT:
        RETVAL
