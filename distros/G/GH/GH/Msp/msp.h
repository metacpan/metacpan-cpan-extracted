
typedef struct _msp {
  int pos1;
  int pos2;
  int len;
  int score;
  struct _msp *next_msp;
} MSP;

MSP *newMSP();

#define copyMSP(from, to)           \
   {                                \
   to->pos1 = from->pos1;           \
   to->pos2 = from->pos2;           \
   to->len = from->len;             \
   to->score = from->score;         \
   to->next_msp = from->next_msp ;  \
   }
