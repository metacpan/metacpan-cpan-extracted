
typedef struct _editop {
  int type;
  int count;
  struct _editop *next;
} EditOp;

EditOp *newEditOp();

/* make sure that these match the constants in EditOp.pm. */
#define NOP 0
#define MATCH 1
#define MISMATCH 2
#define INSERT_S1 3
#define INSERT_S2 4
#define OVERHANG_S1 5
#define OVERHANG_S2 6
