MultiFieldQueryParser *
new(CLASS, fields, analyzer, boosts_href=0)
const char* CLASS;
wchar_t_keepalive** fields
Analyzer* analyzer
HV* boosts_href
    CODE:
        char* key;
        I32 klen;
        SV* val;

        CL_NS(queryParser)::BoostMap* boosts = NULL;

        if (boosts_href) {
           boosts = new CL_NS(queryParser)::BoostMap;

           hv_iterinit(boosts_href);
           while((val = hv_iternextsv(boosts_href, &key, &klen))) {
             NV boost = SvNV(val);
             TCHAR* field = STRDUP_AtoW(key);
             boosts->put(field, (float_t) boost);
           }
        }

        RETVAL = new MultiFieldQueryParser((const wchar_t**) fields, analyzer, boosts);

    OUTPUT:
        RETVAL
    CLEANUP:
        // Memorize Analyzer in returned blessed hash reference.
        // We don't want it to be destroyed by perl before the C++ object it
        // contains gets destroyed by C++. Otherwise this would cause a seg fault.
        hv_store((HV *) SvRV(ST(0)), "Analyzer", 8, newRV(SvRV(ST(2))), 1);

        // Memorize fields table
        hv_store((HV *) SvRV(ST(0)), "fields", 6, newSViv(PTR2IV(fields)) , 0);

        // Memorize boosts 
        if (boosts) {
          hv_store((HV *) SvRV(ST(0)), "boosts", 6, newSViv(PTR2IV(boosts)) , 0);
        }

void
DESTROY(self)
MultiFieldQueryParser *self
    CODE:
        SV **svp = hv_fetch((HV *) SvRV(ST(0)), "fields", 6, 0);
        if (!svp) {
          die("no fields in MultiFieldQueryParser hash\n"); 
        }
        wchar_t** fields = INT2PTR(wchar_t**, SvIV(*svp));
        if ( fields !=NULL ) {
          for(int xcda=0; fields[xcda] != NULL; xcda++) {
            delete [] fields[xcda];
          }
        }
        SAVEFREEPV(fields);

        SV **sv_boost = hv_fetch((HV *) SvRV(ST(0)), "boosts", 6, 0);
        if (sv_boost) {
          CL_NS(queryParser)::BoostMap* boosts = INT2PTR(CL_NS(queryParser)::BoostMap*, SvIV(*sv_boost));
          delete boosts;
        }

        delete self;


Query*
parse(self, query_string, wfields=0, analyzer=0)
  CASE: items == 2
  MultiFieldQueryParser* self
  wchar_t* query_string
    PREINIT:
        const char* CLASS = "Lucene::Search::Query";
    CODE:
        try {
          QueryParser *qp = (QueryParser*) self;
          RETVAL = qp->parse(query_string);
        } catch (CLuceneError& e) {
          die("[Lucene::MultiFieldQueryParser->parse()] %s\n", e.what());
        }
    OUTPUT:
        RETVAL

  CASE: items == 4
  const char* self;
  wchar_t* query_string
  wchar_t** wfields
  Analyzer* analyzer
    PREINIT:
        const char* CLASS = "Lucene::Search::Query";
    CODE:
        try {
          RETVAL = lucene::queryParser::MultiFieldQueryParser::parse(query_string, (const wchar_t**) wfields, analyzer);
        } catch (CLuceneError& e) {
          die("[Lucene::MultiFieldQueryParser->parse()] %s\n", e.what());
        }
    OUTPUT:
        RETVAL
    CLEANUP:
        // Allocated in typemap
        int i = 0;
        while (wfields[i]) {
          free(wfields[i]);
          i++;
        } 

void
setDefaultOperator(self, oper)
MultiFieldQueryParser* self
int oper
    CODE:
        QueryParser *qp = (QueryParser*) self;
        qp->setDefaultOperator(oper);

