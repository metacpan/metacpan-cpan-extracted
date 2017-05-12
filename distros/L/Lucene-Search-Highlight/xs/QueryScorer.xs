QueryScorer *
new(CLASS, query)
const char* CLASS;
Query* query
    CODE:
        // query gets cloned in QueryScorer, so no worries.
        RETVAL = new QueryScorer(query);
    OUTPUT:
        RETVAL

void
DESTROY(self)
        QueryScorer * self
    CODE:
        delete self;

