Sort *
new(CLASS, sortfield1, sortfield2 = 0)
 CASE: items == 2
    const char* CLASS;
    SortField* sortfield1
    CODE:
        RETVAL = new Sort(sortfield1);
    OUTPUT:
        RETVAL
 CASE: items == 3
    const char* CLASS;
    SortField* sortfield1
    SortField* sortfield2
    CODE:
        SortField* sortfields[3];
        sortfields[0] = sortfield1;
        sortfields[1] = sortfield2;
        sortfields[2] = NULL;
        RETVAL = new Sort(sortfields);
    OUTPUT:
        RETVAL

Sort *
RELEVANCE(CLASS)
  const char* CLASS
  CODE:
        RETVAL = new Sort();
  OUTPUT:
        RETVAL

Sort *
INDEXORDER(CLASS)
  const char* CLASS
  CODE:
        RETVAL = new Sort(SortField::FIELD_DOC);
  OUTPUT:
        RETVAL


void
DESTROY(self)
        Sort * self
    CODE:
        delete self;

