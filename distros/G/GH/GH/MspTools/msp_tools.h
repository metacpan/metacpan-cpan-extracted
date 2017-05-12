
typedef struct _mspConfig {
  int tableSize;
  int wordSize;
  int extensionThresh;
  int mspThresh;
  int matchScore;
  int mismatchScore;
  int ovFudge;
} mspConfig;

int getMSPs(char *s1, char *s2, mspConfig *config, MSP **msp, int *numMSPs);
int findBestOverlapPath(char *s1, char *s2, MSP *msp, int numMSPs, mspConfig *c,
			MSP **bestPath, int *numInPath, int *bestCost);
int findBestInclusionPath(char *s1, char *s2, MSP *msp, int numMSPs, mspConfig *c,
			  MSP **bestPath, int *numInPath, int *bestCost);
int findInclusionsBulk(char *s1,
		       int count, char **names, char **seqs,
		       mspConfig *config,
		       MSP ***paths,
		       int **costs);
