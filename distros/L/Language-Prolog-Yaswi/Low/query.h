

void savestate_query(pTHX_ pMY_CXT);

void close_query(pTHX_ pMY_CXT);

void test_no_query(pTHX_ pMY_CXT);

void test_query(pTHX_ pMY_CXT);

int is_query(pTHX_ pMY_CXT);

fid_t frame(pTHX_ pMY_CXT);

void push_frame(pTHX_ pMY_CXT);

void pop_frame(pTHX_ pMY_CXT);

void rewind_frame(pTHX_ pMY_CXT);
