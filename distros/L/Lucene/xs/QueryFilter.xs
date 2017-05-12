QueryFilter *
new(CLASS, query)
const char* CLASS;
Query* query
    CODE:
        // query gets cloned in QueryFilter, so no worries.
        RETVAL = new QueryFilter(query);
    OUTPUT:
        RETVAL

void
DESTROY(self)
        QueryFilter * self
    CODE:
        delete self;

