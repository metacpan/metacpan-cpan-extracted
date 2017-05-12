SortField *
new(CLASS, fieldname, type_or_reverse = 0, reverse = 0)
  CASE: items == 2
    const char* CLASS;
    wchar_t* fieldname
    CODE:
        RETVAL = new SortField(fieldname);
    OUTPUT:
        RETVAL
  CASE: items == 3
    const char* CLASS;
    wchar_t* fieldname
    int type_or_reverse
    CODE:
        RETVAL = new SortField(fieldname, SortField::AUTO, type_or_reverse);
    OUTPUT:
        RETVAL
  CASE: items == 4
    const char* CLASS;
    wchar_t* fieldname
    int type_or_reverse
    int reverse
    CODE:
        RETVAL = new SortField(fieldname, type_or_reverse, reverse);
    OUTPUT:
        RETVAL
  CASE:
    CODE:
     die("Usage: Lucene::Search::SortField->new(fieldname, [reverse | type, reverse])");
    

SortField *
FIELD_SCORE(CLASS)
const char* CLASS;
  CODE:
       RETVAL = new SortField (NULL, SortField::DOCSCORE, false);
  OUTPUT:
       RETVAL

SortField *
FIELD_DOC(CLASS)
const char* CLASS;
  CODE:
       RETVAL = new SortField (NULL, SortField::DOC, false);
  OUTPUT:
       RETVAL

