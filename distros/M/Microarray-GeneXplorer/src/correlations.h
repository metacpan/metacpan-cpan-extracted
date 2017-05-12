/* File : correlations.h : contains all function protypes, structs, #includes, #defines etc. ****************/

/********************************************************************** # includes *********************/

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <stdarg.h>
#include <time.h>

/********************************************************************** # defines **********************/

#define NODATA 99999.00

/************************************************ structs that are used to store data structures *****/

/* the nameRec structure is used to identify a list of correlations associated 
 * with either a gene, or a node.  In the clusterRec struct there is an array of
 * nameRec structs that are dynamically allocated.  There is enough space allocated
 * to store 2*numLines-1 nameRecs, where numLines is the number of genes for which
 * there is data.  The nameRecs from 0 to numLines-1 correspond to genes, and the 
 * nameRecs from numLines to 2*numLines-1 correspond to nodes.  This same array is
 * reused to store the correlations that are used when experiments are clustered.  In
 * this case 2*numExperiments-1 nameRecs are used, the first numExperiments worth are used for
 * experiments, the rest for compound nodes.
 */

typedef struct{
  char *orf;
  char *name;
  float rowWeight;
  int joined; /* to check whether a gene/experiment or node has been joined to another gene/experiment or node yet */
  struct correlationRec *first;
  struct correlationRec *last;
  int numCorrelations;
} nameRec;

typedef struct{
  nameRec *genes;
  int numGenes;
} clusterRec;

typedef struct correlationRec{
  int ORFnumber;
  float corr;
  struct correlationRec *next;
} correlationRec;

/************************************************************** Global Variables ******************************/

int		gLogData=0; /* whether to log transform the data */
int		gCentered=0; /* keeps track of whether to use a centered metric for the genes */
char*	gPrefix; /* if they want to pass in a unique identifier, as oppposed to using the filename */
int 	gUID=0; /* whether they passed in a unique identifier */
float	gCutOff=0.8; /* the cut off below which they don't see correlations */
int		gMaxNumCorrelations=20; /* number of correlations to save */
int     gShowCorrelations = 1; /* whether to show the correlations or not */

/************************************************************** Function Prototypes ***************************/

/************************************************************** General Functions *****************************/

int     main(int argc, char *argv[]);
void    ParseOptions(char *ifile, int argc, char **argv);
void 	Usage(void);
char	*GetFilePrefix(char *ifile);

void	GetUserInput();
void	GetTransformationOptions(void);
void	GetGeneMetric(void);
void	GetCutOff(void);
void	GetNumCorrelations(void);
void	CheckYesOrNo(char *inputLine);

void	MakeFileName(char *ifile, char **fileName);

void	GetDataSize(FILE *istream, int *numExperiments, int *numLines);
void	DoMemoryAllocation(float **eWeights, int numExperiments, char ***experimentNames,
			   clusterRec *cluster, float **dataMatrix);
void 	FreeCorrelations(correlationRec **node);
float	*ReadInData(FILE *istream, clusterRec *cluster, int numExperiments, float *eWeights, 
		    char **experimentNames, float *dataMatrix);
void	InitializeArray(nameRec *names);
void	ReadOneLine(FILE *istream, float *dataMatrix, int numExperiments, int currLine, nameRec *names);
double	StringToReal(char *s);
FILE	*OpenInFile(char *ifile);
FILE	*OpenOutFile(char *ofile);
FILE    *OpenForAppend(char *ofile);
void	LogTransformData(float *dataMatrix, int numGenes, int numExperiments);

/*************************************************************** Functions for Hierarchically Clustering ********/

void	FreeCluster(clusterRec *cluster);
void	MakeCorrelations(clusterRec *cluster, float *dataMatrix, int numExperiments, float *eWeights, char *ifile);
float	CalculateCorrelation(float *genePtr, float *cmpPtr, int numExperiments,
			     float *eWeights);
void	CheckToInsert(clusterRec *cluster, int geneCounter, int comparedToCounter, float pearsonCorrelation);
void	InsertSorted(correlationRec **list, correlationRec *newOne);
correlationRec *SwitchLast(correlationRec **list, correlationRec* newOne);
correlationRec	*DeleteLast(correlationRec **list);
correlationRec	*MakeNewRecord(double correlation, int geneNumber);

void 	Error(char *msg, ...);
void 	FreeExperimentNames(char **experimentNames, int numExperiments);

/**************************************************** Functions for debugging purposes *****************************************/

void 	PrintOneGene(correlationRec *list, FILE *outfile, clusterRec *cluster);
