int 
length(self)
Hits* self
    CODE:
        RETVAL = self->length();
    OUTPUT:
        RETVAL

Document*
doc(self, num)
Hits* self
int num
    PREINIT:
      const char* CLASS = "Lucene::Document";
    CODE:
       // Get reference on Hits object
       SV* tmp_rv = newRV(SvRV(ST(0)));
       // Get doc identified by num
       Document& doc = self->doc(num);
       RETVAL = &doc;
    OUTPUT:
       RETVAL
    CLEANUP:
        // When the C++ Hits object gets destroyed the C++ Document object
        // gets destroyed as well. Therefore, we need to make sure that if the
        // PERL Document object is alive, the Perl Hits object is alive as well 
        hv_store((HV *) SvRV(ST(0)), "Hits", 4, tmp_rv, 0);
        // Indiquate that Document object is owned by the Hits object and
        // that its destruction shouldn't be handled by Perl.
        MarkObjCppOwned(ST(0));

int 
id(self, num)
Hits* self
int num
   CODE:
      RETVAL = self->id(num);
   OUTPUT:
      RETVAL


float
score(self, num)
Hits* self
int num
   CODE:
      RETVAL = self->score(num);
   OUTPUT:
      RETVAL


void
DESTROY(self)
Hits * self
    CODE:
        delete self;
//        printf("deleted Hits\n");

