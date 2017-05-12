
#define TT800_N 25
#define TT800_M 7
#define TT800_INV_MOD 2.3283064370807974e-10            /* 1.0 / (2^32-1) */

struct tt800_state
        {
	U32		x[TT800_N];		/* make use of the perl type */
	int             k;
	};

typedef struct tt800_state *TT800;

extern struct tt800_state tt800_initial_state;
U32 tt800_get_next_int(TT800 g);
