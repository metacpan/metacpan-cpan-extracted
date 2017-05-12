#ifndef SIM_PRNT_H
#define SIM_PRNT_H
/* $Id: prnt.h,v 1.1 2002/12/03 20:12:37 hartzell Exp $ */

typedef unsigned int edit_op_t; /* 32 bits */

void print_align_header(SEQ *seq1, SEQ *seq2, argv_scores_t *ds);
void print_align(int score, uchar *seq1, uchar *seq2, int beg1, int end1, int beg2, int end2, int *S);


#endif
