#ifndef __GOOD_H__
#define __GOOD_H__

int good(ichar_t * word, int ignoreflagbits, int allhits, int add_poss,
            int reconly);
int bgood(ichar_t *w, int ignoreflagbits, int allhits, int add_poss);

void flagpr(register ichar_t *word, int preflag, int prestrip, int preadd,
            ichar_t *preclass, int sufflag, int sufadd, ichar_t *sufclass);
void try_direct_match_in_dic(ichar_t *w, ichar_t *nword,
                             int allhits, int add_poss, int n);
#endif
