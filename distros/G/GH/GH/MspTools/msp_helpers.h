
int getMSPConfig(mspConfig **mspC);
SV *getMSPs_helper(char *s1, char *s2);
SV *MSPMismatches_helper(MSP *msp, char *s1, char *s2);
SV *getMSPsBulk_helper(char *s1, SV *arrayRef);
SV *findBestOverlap_helper(char *s1, char *s2);
SV *findBestInclusion_helper(char *s1, char *s2);
SV *tmpPlace_helper(char *s1, char *s2);
SV *findBestInclusionBulk_helper(char *s1, SV *arrayRef);
