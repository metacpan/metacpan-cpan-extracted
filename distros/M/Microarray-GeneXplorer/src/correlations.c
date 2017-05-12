/*
 * File : correlations.c
 * Author : Gavin Sherlock
 * Date : September 29th 1999
 * Version 1.0
 *
 * This program reads a preclustering file, and produces a file that contains a sorted list of correlations.
 * The user can input a cutoff (as low as .5) and a number (as many as 50)
 */


#include "correlations.h"

/* Main */

int main(int argc, char *argv[]){
  
  char	ifile[1024];				/* Path names must be 1024 chars or less */
  int	numExperiments=0;
  int	numLines=0;
  float	*dataMatrix;
  clusterRec cluster;
  float  *eWeights;
  FILE	*istream;
  char **experimentNames;
  
  
  /* get relevant input information */
  
  if(argc==1 || argc==0){
    printf ("Enter input file: ");
    gets (ifile);
    GetUserInput();
  }else{
    ParseOptions(ifile, argc, argv);
  }
  
  /* Read in the Data */
  
  istream=OpenInFile(ifile);
  
  GetDataSize(istream, &numExperiments, &numLines);
  
  cluster.numGenes=numLines; /* put these in experiment to cut down on number of arguments that need passing */
  
  DoMemoryAllocation(&eWeights, numExperiments, &experimentNames, &cluster, &dataMatrix);
  
  rewind(istream);	
  ReadInData(istream, &cluster, numExperiments, eWeights, experimentNames, dataMatrix);
  fclose (istream);
  
  /* transform data if necessary */
  
  if(gLogData) LogTransformData(dataMatrix, cluster.numGenes, numExperiments);
    
  MakeCorrelations(&cluster, dataMatrix, numExperiments, eWeights, ifile);
    
  free (dataMatrix);
  free (eWeights);
  FreeExperimentNames(experimentNames, numExperiments);
  FreeCluster(&cluster);
  
  printf("Finished\n");
  fflush(stdout);
  
  return 0;
  
}


/* Function: OpenInFile
 * Usage: istream=OpenInFile(ifile)
 * ----------------------
 * This functions attempts to open a file using the name
 * passed into it, and reports an error if it fails, otherwise
 * returns a file handle for reading.
 */

FILE* OpenInFile(char *ifile){
  
  FILE *istream;
  
  if ((istream = fopen(ifile, "rb")) == NULL){ /* Open the file OK? */
    Error("\nError opening input\n");		/* NO, say so */
  } /* end if */
  return (istream);
}

/*
 * Function : GetFilePrefix
 * Usage : prefix=GetFilePrefix(ifile)
 * -----------------------------------
 * This function returns the prefix to a filename, which
 * is all characters up to the last '.' character, or if
 * one is not encountered, then all characters.  If a unique
 * identifier was passed in, via the -u option, then the directory
 * path, plus the UID will be returned instead.
 */
 
char *GetFilePrefix(char *ifile){

  char* prefix;
  int letter=0;
  int last=0;
  int seen=0;
  int dirLet=0;

  while (ifile[letter]!='\0'){
    if (ifile[letter]=='.'){
      last=letter;
      seen=1;
    }else if (ifile[letter]=='/'){
      seen=0;
      if (gUID) dirLet=letter; /* remember the directory path */
    }
    letter++;
    if (letter==1024) Error("The name of your input file is longer than 1024 characters");
  }
  
  

  if (seen && !gUID){ /* saw a period */
    prefix=malloc((last+2)*sizeof(char));
    if (prefix==NULL) Error ("Not enough room for prefix\n");
    strncpy(prefix, ifile, last+1);
    prefix[last+1]='\0';
  }else if (!gUID){ /* no period */
    prefix=malloc((letter+2)*sizeof(char));
    if (prefix==NULL) Error ("Not enough room for prefix\n");
    strcpy(prefix, ifile);
    prefix[letter]='.';
    prefix[letter+1]='\0';
  }else{ /* a UID was passed in */
    prefix=malloc((dirLet+strlen(gPrefix)+3)*sizeof(char));
    if (dirLet) {
      strncpy(prefix, ifile, dirLet+1);
      prefix[dirLet+1]='\0';
      strcat(prefix, gPrefix);
    }else{
      strcpy(prefix, gPrefix);
    }
    strcat(prefix, ".");
    prefix[dirLet+2+strlen(gPrefix)]='\0';
  }
  
  return (prefix);
  
}

/*
 * Function: GetUserInput
 * Usage: GetUserInput()
 * ---------------------------
 * This function gets input form the user, as regards whether they want to cluster
 * experiments, and whether they want to use a centered metric for correlation.
 * It also checks whether they want to partition the data (and how), whether they
 * want to log transform the data, and whether they want to normalize of filter the data.
 */
 
void GetUserInput(){

  	GetTransformationOptions();
  		  	  
   	GetGeneMetric();
   	
   	GetCutOff();
   	
   	GetNumCorrelations();
    	
}


/*
 * Function: GetTransformationOptions
 * Usage:
 * ----------------------------------
 * This function checks whether they want to log transform the data
 */
 
void GetTransformationOptions(void){

	char inputLine[64];
 
 	printf("\nDo the data need to be log transformed?(yes/no)\n");
 	
 	CheckYesOrNo(inputLine);
 	
 	if ((!strcmp(inputLine, "yes"))||(!strcmp(inputLine, "YES"))){
		gLogData=1;
	}

}


/*
 * Function: GetGeneMetric
 * Usage: GetGeneMetric()
 * ------------------------
 * This function checks whether they want to use a centered or 
 * uncentered metric for the genes, if pearson was chosen as the
 * distance metric.
 */
 
void GetGeneMetric(void){

	char inputLine[64];
	
    printf("Do you want to use a correlation with a centered metric (yes/no)? \n");
    CheckYesOrNo(inputLine);	
    	
    if ((!strcmp(inputLine, "yes"))||(!strcmp(inputLine, "YES"))){
		gCentered=1;
   	}
  	
}

/*
 * Function: GetCutOff
 * Usage: GetCutoff()
 * -------------------
 * This functions finds out what cutoff the user wants.  If they enter less than 0.2
 * it will use 0.2.  The default is 0.8
 */
 
void GetCutOff(void){

	 char inputLine[64];
	 
	 printf("What do you want to use as a cutoff?\n");
	 printf("(Enter a value greater than 0.2, or hit return to use the default of 0.8)");
	 
	 gets(inputLine);
	 
	 if (!strcmp(inputLine, "")){ 
	 	/* they just hit return, so use default */
	 }else{
	 	gCutOff=StringToReal(inputLine);
	 	if (gCutOff < 0.2){
	 		printf("You entered a cutoff less than 0.2.  .2 will be used as a cutoff\n");
	 		gCutOff = 0.2;
	 	}
	 	if (gCutOff > 1) Error("You chose a cutoff greater than 1");
	 } 
	 
}


/*
 * Function: GetNumCorrelations
 * Usage : GetNumCorrelations();
 * -----------------------------
 * This function finds out the number of correlations that the person wants to store.
 * The default is 20, and they can have up to 50.
 */
 
void GetNumCorrelations(void){

	char inputLine[64];
	
	printf("How many correlations do you want?\n");
	printf("(Enter a number, or hit return to get the default of 20)");
	
	gets(inputLine);

	if (!strcmp(inputLine, "")){ 
	 	/* they just hit return, so use default */
	 }else{
	 	gMaxNumCorrelations=(int)StringToReal(inputLine);
	 	if (gMaxNumCorrelations < 1) Error("You chose a value less than 1");
	 } 
	 
}	
	
	 
/*
 * Function: GetYesOrNo
 * Usage:
 * --------------------
 * This function simply asks for an input, and checks whether it is yes or no.
 * It stays continues prompting for a yes or no until one is received.
 */
 
void CheckYesOrNo(char *inputLine){

	while(1){
		gets(inputLine);
		if (!((!strcmp(inputLine, "yes"))||(!strcmp(inputLine, "YES"))||(!strcmp(inputLine, "no"))
			||(!strcmp(inputLine, "NO")))){
	    	printf("Please answer yes or no\n");
		}else{
			break;
		}
	}
}

/*
 * Function: ParseOptions
 * Usage: ParseOptions(ifile, argc, argv)
 * ----------------------------------------------
 * This function parses supplied command line options.
 * Command line options are as follows:
 * -f filename
 * -g 1|2 ; 1 indicates non-centered metric, 2 indicates centered metric.  1 is default.
 * -e 0|1|2 ; 0 indicates no experiment clustering, see above for 1 and 2.  0 is the default.
 * The arguments can be passed in any order.
 */

void ParseOptions(char *ifile, int argc, char** argv){
  
	int i;
 	int foundFileName=0;
  	int length;
  	
  	if (!(strcmp("-h", argv[1]))){ /* they want help */
  	
  		Usage();
  		exit(0); /* NOTE EXITING PROGRAM HERE!!!! */
  		
  	}	
  
  	if ((argc-1)%2)Error("Incorrect number of command line arguments");
  
  	for(i=1; i<argc; i+=2){
    
    	if (!(strcmp("-l", argv[i]))){  /* log transformation */
      
      		if(!(strcmp("0", argv[i+1]))){ /* default, no action needed */
	
      		}else if (!(strcmp("1", argv[i+1]))){
	
				gLogData=1;
	
      		}else{
	
				Error("Unrecognized value for the \"-l\" option.  Only 0 and 1 are valid");
	
      		}
      
    	}else if (!(strcmp("-u", argv[i]))){ /* want a unique id */
      
      		length=strlen(argv[i+1]);
      
      		gPrefix=malloc((length+1)*sizeof(char));
      
      		strcpy(gPrefix, argv[i+1]);
      
      		gPrefix[length]='\0';
      
      		gUID=1;
      
    	}else if (!(strcmp("-f", argv[i]))){ /* filename */
      
      		strcpy(ifile, argv[i+1]);
      
      		foundFileName=1;
      
    	}else if (!(strcmp("-corr", argv[i]))){ /* correlation parameter */
      
      		if (!(strcmp("1", argv[i+1]))){ /* default, no action needed */
	
      		}else if (!(strcmp("2", argv[i+1]))){
	
				gCentered=1;
	
      		}else{
	
				Error("Unrecognized value for the \"-corr\" option.  Only 1 and 2 are valid");
	
      		}
      		
      	}else if (!(strcmp("-cutoff", argv[i]))){ /* cutoff parameter */
      	
      		gCutOff=StringToReal(argv[i+1]);
      		
      		if (gCutOff <0.2){
      			printf("You entered a cutoff less than 0.2.  .2 will be used as a cutoff\n");
	 			gCutOff = 0.2;
	 		}
	 		if (gCutOff > 1) Error("You chose a cutoff greater than 1");
      			
      	}else if (!(strcmp("-num", argv[i]))){ /* number of correlations that they want */
      	
      		gMaxNumCorrelations=(int)StringToReal(argv[i+1]);
		if (gMaxNumCorrelations < 1) Error("You chose a value less than 1");

	}else if (!(strcmp("-showCorr", argv[i]))){ /* indicating whether they want the correlations */

	  gShowCorrelations = (int)StringToReal(argv[i+1]);
	  if (gShowCorrelations > 1 || gShowCorrelations < 0){
	    Error("You have chosen an out of range value for defining whether to show correlations or not.");
	  }
      
    	}else{
      
      		Error("Unrecognized command line option.  Only -f, -corr, -cutoff, -num, -l and -u are valid (currently!)");
      
    	}
    
  	}
  
  	if(!foundFileName)Error("You passed in command line arguments without specifying a filename");
    
}

/*
 * Function: Usage
 * Usage : Usage()
 * ---------------
 * This functions prints out the command line arguments that may be used with the program,
 * and what they mean.
 */
 
void Usage(void){

	printf("\n\nThe program \"correlations\" will take a preclustering file as an input, and produce a\n");
	printf("file containing the correlations for each gene in sorted order.\n");
	printf("The output file will be named with the same stem as the input file, but with a .stdCor suffix\n\n");
	printf("Usage:\n");
  	printf("The following command line arguments may be used:\n\n");
  	printf("-f            Allows you to specify the preclustering filename.  Relative paths may be used\n\n");
  	printf("-corr   1|2   Allows you to specify whether you want an uncentered (1) or a centered (2) metric.\n");
  	printf("              1 is the default\n\n");
  	printf("-cutoff       Allows you to specify a cutoff, correlations above which will be stored\n\n");
  	printf("-num          Allows you to specify the number of correlations that you would like to store\n");
  	printf("              20 is the default\n\n"); 
  	printf("-l      0|1   Allows you to specify if you want to log transform the data (1)\n");
  	printf("              0 is the default\n\n");
  	printf("-u            Allows you to specify a unique id by which you output file will be named\n");
  	printf("              eg.  correlations -f sample.pcl -u 888\n");
  	printf("              will produce an output file named 888.stdCor\n\n");
	printf("-showCorr 0|1 specifies whether you want to see thhe correlations themselves.\n");
	printf("              1 is the default\n\n");
  	printf("Questions or comments should be addressed to sherlock@genome.stanford.edu\n\n");
  	
}
	

/*
 * Function: OpenOutFile
 * Usage: outfile=OpenOutFile("outfile.txt")
 * -----------------------------------------
 * This functions attempts to open a file using the name
 * passed into it, and reports an error if it fails, otherwise
 * returns a file handle for writing.
 */
 
FILE* OpenOutFile(char *ofile){

  FILE *ostream;
  
  if ((ostream = fopen(ofile, "w")) == NULL){ /* Open the file OK? */
    Error("\nError opening output file: %s\n", ofile);		/* NO, say so */
  } /* end if */
  return (ostream);
}

/*
 * Function: OpenForAppend
 * Usage: outfile=OpenForAppend("outfile.txt")
 * -----------------------------------------
 * This functions attempts to open a file for appending using the name
 * passed into it, and reports an error if it fails, otherwise
 * returns a file handle for appending.
 */
 
FILE* OpenForAppend(char *ofile){

  FILE *ostream;
  
  if ((ostream = fopen(ofile, "a")) == NULL){ /* Open the file OK? */
    Error("\nError opening output file: %s\n", ofile);		/* NO, say so */
  } /* end if */
  return (ostream);
}

/* Function: GetDataSize
 * Usage:GetDataSize(istream, &numExperiments, &numLines)
 * --------------------------------------------------
 * This functions parses the data file, to determine the number
 * of genes and experiments represented therein.  Because the
 * variables are passed in by address then there is no return argument.
 */

void GetDataSize(FILE *istream, int *numExperiments, int *numLines){
	
  int	nextbyte;
  int	extraChar;
  
  printf("Getting size of data...\n");

  fflush(stdout);
  
  while ((nextbyte = fgetc(istream))){ /* get characters from input file */
    
    if (nextbyte=='\t'){ /* count tabs to get number of columns */
      (*numExperiments)++;
    }
    
    /* the next bit looks for the end of line, whether it's PC ('\r\n'), 
     * Mac ('\r') or UNIX ('\n').  It checks to see if the following character
     * has to do with the end of line also.  If not, it puts it back in the stream.
     */
    
    if ((nextbyte=='\r') || (nextbyte=='\n')){ /* look for end of line */
      extraChar=fgetc(istream);
      if (extraChar!='\n'  && extraChar!=EOF){
	ungetc(extraChar, istream);
      }
      break; /* only reading first line to get number of columns */
    }
     
  }
  
  (*numExperiments)-=2; /* the first two tabs didn't precede data so decrease the number */
  
  while((nextbyte = fgetc(istream)) != EOF){  /* Read char.s until end of file */
    switch (nextbyte)						/* What char was read? */
      {
      case '\r': /* on the Mac or the PC, \r will be the first thing seen to indicate an end of line */
	(*numLines)++;
	extraChar=fgetc(istream); /* get rid of extra character if needs be */
	if (extraChar!='\n'  && extraChar!=EOF){
	  ungetc(extraChar, istream);
	}
	break;
      case '\n': /* on UNIX \n will be seen as the end of line */
	(*numLines)++;
	break;
      default:
	break;					
      } /* end switch */
  } /* end while */
  
  (*numLines)--; /* because there's an extra line in the file */
  
}

/*
 * Function: DoMemoryAllocation
 * Usage: DoMemoryAllocation(&eWeights, numExperiments, &experimentNames, &cluster, &dataMatrix);
 * -------------------------------------------------------------------------------------------------------------------
 * This function does the DMA that is needed for all the data structures that are required,
 * including the dataMatrix, the experiment names, and the nameRecs.
 */
 
void DoMemoryAllocation(float **eWeights, int numExperiments, char ***experimentNames,
			clusterRec *cluster, float **dataMatrix){
  
	nameRec *namePtr;
  
  	*eWeights=malloc(numExperiments*sizeof(float));
  	if (*eWeights==NULL) Error("Not enough memory available for eWeights");
  
  	*experimentNames=malloc(numExperiments*sizeof(char*));
  	if (*experimentNames==NULL) Error ("No memory available for experimentNames");
  
 	(*cluster).genes=malloc(cluster->numGenes * sizeof(nameRec)); /* allocate the memory for the name records */
    if ((*cluster).genes==NULL) Error("No memory available for nameRecs");
  
  	/* now initialize the genes array */
  
  	for (namePtr=&(cluster->genes[0]); namePtr<&(cluster->genes[cluster->numGenes]); namePtr++){
		InitializeArray(namePtr);
   	}
  
  	/* allocate dataMatrix */
  
    *dataMatrix=malloc(numExperiments*(cluster->numGenes)*sizeof(float));
  	if (*dataMatrix==NULL) Error("No memory available for dataMatrix");
  
}

/*
 * Function: ReadInData
 * Usage: ReadInData(istream, &cluster, numExperiments, eWeights, numLines, &experimentNames, dataMatrix)
 * -------------------------------------------------------------
 * This functions parses the data file, to retrieve the log transformed data.
 * it also retrieves the eWeights, that form the second line of the file.
 */
 
float *ReadInData(FILE *istream, clusterRec *cluster, int numExperiments, float *eWeights, char **experimentNames, float *dataMatrix){
  char buffer[1024];
  char nextbyte;
  char extraChar;
  int currCol=0;
  int letter=0;
  int dataCol=0;
  int currLine=0;
  
  printf("Reading Data...\n");

  fflush(stdout);
  
  /* parse the first line for the experiment names
   * should really consolidate code for parsing first and second lines
   * by switching again, dependent on the lineNumber, 1 or 2
   */
  
  while ((nextbyte=fgetc(istream))){
    if (nextbyte=='\t'){
      buffer[letter]='\0';
      switch (++currCol){ /* depends what column we're looking at as to what we'll do */
      case 1: 
      case 2: 
      case 3: 
	letter=0;
	break;
      default: /* other columns must be data columns */
	if (letter!=0){
	  experimentNames[dataCol]=malloc((letter+1)*sizeof(char));
	}else{
	  Error("An experiment is unnamed at data column %d\n", dataCol+1);
	}
	if (experimentNames[dataCol]==NULL) Error("Not enough memory for experiment name %d", dataCol+1);
	strcpy(experimentNames[dataCol], buffer);
	letter=0;
	dataCol++;
	break;
      } /* end switch */
    }else if (nextbyte=='\r' || nextbyte=='\n'){
      buffer[letter]='\0';
      if (letter!=0){
	experimentNames[dataCol]=malloc((letter+1)*sizeof(char));
      }else{
	Error("An experiment is unnamed at data column %d\n", dataCol+1);
      }			
      if (experimentNames[dataCol]==NULL) Error("Not enough memory for experiment name %d", dataCol+1);
      strcpy(experimentNames[dataCol], buffer);
      extraChar=fgetc(istream); /* get rid of extra character if needs be */
      if (extraChar!='\n'  && extraChar!=EOF){
	ungetc(extraChar, istream);
      }
      break;
    }else{	
      if (letter>=1024) Error("An experiment name longer than 1024 bytes exists in the file on the first line.");
      buffer[letter++]=nextbyte;
    }
  }
  
  letter=0;
  dataCol=0;
  currCol=0;
  
  /* Now read in the eWeights line */
  while ((nextbyte=fgetc(istream))){
    if (nextbyte=='\t'){
      buffer[letter]='\0';
      switch (++currCol){
      case 1: 	
      case 2:	
      case 3: 
	letter=0;
	break;
      default: /* other columns must be data columns */
	eWeights[dataCol]=StringToReal(buffer);
	letter=0;
	dataCol++;
	break;
      } /* end switch */
    }else if (nextbyte=='\r' || nextbyte=='\n'){
      	buffer[letter]='\0';
      	eWeights[dataCol]=StringToReal(buffer);
      	extraChar=fgetc(istream); /* get rid of extra character if needs be */
	if (extraChar!='\n'  && extraChar!=EOF){
	  ungetc(extraChar, istream);
    	}
      	break;
    }else{	
      if (letter>=1024) Error("A token longer than 1024 bytes exists in the file on the second line.");
      buffer[letter++]=nextbyte;
    }
  }
  
  for (currLine=0; currLine<cluster->numGenes; currLine++){
    ReadOneLine(istream, dataMatrix, numExperiments, currLine, &(cluster->genes[currLine]));
  }
  
  printf("Done reading data...\n");
  fflush(stdout);
  return (dataMatrix);
}

/*
 * Function: InitializeArray
 * Usage: InitializeArray(&(names[count]));
 * ----------------------------------------
 * This simply initializes the fields of each nameRec to be zero or NULL
 */

void InitializeArray(nameRec *names){	
  names->orf=NULL;
  names->name=NULL;
  names->joined=0;
  names->numCorrelations=0;
  names->last=NULL;
  names->first=NULL;
}

/* Function: ReadOneLine
 * Usage: ReadOneLine(istream, dataMatrix, &numDataPoints, numExperiments, currLine, &(names[currLine]))
 * ---------------------------------------------------
 * This function is called from ReadInData, and will parse one
 * line of data, depositing the data into dataMatrix, the space for
 * which was allocated in the ReadInData function.
 */

void ReadOneLine(FILE *istream, float *dataMatrix, int numExperiments, int currLine, nameRec *names){
  char buffer[1024];
  int currCol=0;
  int dataCol=0;
  int tabCount=0; /* if two tabs next to each other, then a null value exists */
  char nextbyte;
  char extraChar;
  int letter=0;
  
  /* initialize gene records */
  
  while ((nextbyte=fgetc(istream))!=EOF){
    
    switch (nextbyte){
    case '\t':
      tabCount++;
      if (dataCol>=numExperiments) Error("There are more columns of data than expected on data line %d.  Only %d columns were expected.\n", currLine+1, numExperiments);
      if (tabCount==2){ /* a null data point exists, or there's a missing name */
	if (currCol>2){
	  dataMatrix[currLine*numExperiments+dataCol]=NODATA;
	  currCol++;
	  dataCol++;
	  tabCount=1;
	  letter=0;
	  break;
	}else{
	  tabCount=0;
	}
      }
      buffer[letter]='\0';
      switch (currCol++){
      case 0: /* First column is the ORF name */
	if (letter>0){
	  names->orf=malloc((letter+1)*sizeof(char));
	  if (names->orf==NULL) Error("Not Enough Memory Available for orfs\n");
	  strcpy(names->orf, buffer);
	}else{
	  /*printf("Missing Name\n");*/
	}
	letter=0;
	break;
      case 1: /* Second column is the SGD name */
	if (letter>0){
	  names->name=malloc((letter+1)*sizeof(char));
	  if (names->name==NULL) Error("Not Enough Memory Available for names\n");
	  strcpy(names->name, buffer);
	}else{
	  /*printf("Missing Name\n");*/
	}
	letter=0;
			break;
      case 2: /* Third column is the row weight */
	names->rowWeight=(float)(StringToReal(buffer));
	letter=0;
	break;
      default: /* other columns must be data columns */
	dataMatrix[currLine*numExperiments+dataCol]=(float)(StringToReal(buffer));
	letter=0;
	dataCol++;
	break;
      }		
      break;
    case '\r':
    case '\n':
      extraChar=fgetc(istream); /* get rid of extra character if needs be */
      if (extraChar!='\n'  && extraChar!=EOF){
	ungetc(extraChar, istream);
      }
      tabCount++;
      if (dataCol>=numExperiments) Error("There are more columns of data than expected on data line %d.  Only %d columns were expected, but %d were found.\n", currLine+1, numExperiments, dataCol+1);
      if(dataCol<numExperiments-1)Error("There are less columns of data than expected on data line %d.  %d columns were expected, but only %d were found.\n", currLine+1, numExperiments, dataCol+1);
      if (tabCount==2){ /* a null data point exists */
	dataMatrix[currLine*numExperiments+dataCol]=NODATA;
      }else{
	buffer[letter]='\0';
	dataMatrix[currLine*numExperiments+dataCol]=(float)(StringToReal(buffer));
      }
      return;
      break;
    default:
      if (letter>=1024) Error("A token longer than 1024 bytes exists in the file on line %d", currLine);
      buffer[letter++]=nextbyte;
      tabCount=0;
      break;
    }
  }
   
}


/* 
 * Function: StringToReal
 * Usage: s=StringToReal(buffer)
 * ---------------------------
 * This function converts a string representing a real number
 * into its corresponding value.  If the string is not a legal
 * floating point number, or it contains extraneous characters,
 * StringToReal signals an Error condition.  This code was taken
 * from Eric Roberts' book "The Art and Science of C".
 */
 
double StringToReal(char *s){
	
  double result;
  char dummy;
  
  if (s==NULL) Error("NULL string passed to StringToReal");
  if (sscanf(s, " %lg %c", &result, &dummy) !=1){
    Error("StringToReal called on illegal number %s", s);
  }
  return (result);
  
}

/* 
 * Function: MakeCorrelations
 * Usage: MakeCorrelations(&cluster, dataMatrix, numExperiments, eWeights, numGenes, 'G')
 * 	  MakeCorrelations(&cluster, dataMatrix, numExperiments, eWeights, numExperiments, 'E')
 * --------------------------------------------------
 * This function generates the correlation coefficients
 * by comparing each profile to every other profile.
 * It cuts the work in half by not comparing A vs B, and
 * B vs A, which should be identical.  It will save up to gMaxNumCorrelations
 * of the top correlations.  This allows correlation scores to
 * be freed once the node has been joined.  The scores must be in
 * sorted order. There are pointers to both the top and bottom scores,
 * so that it can rapidly be decided whether a correlation is the highest,
 * or whether a newly calculated correlation should be included.
 * By passing in different "total", and "type", the function can be made to 
 * calculate correlations for experiments, or genes.
 */

void MakeCorrelations(clusterRec *cluster, float *dataMatrix, int numExperiments, float *eWeights, char *ifile){
  
 	int counter;
  	int comparedToCounter;
  	float pearsonCorrelation;
  	FILE *outfile;
  	int numAfterWhichToPrint=400000/cluster->numGenes;
  	char *filename;
  
  	printf("Making correlations\n");
  	fflush(stdout);
  	
  	MakeFileName(ifile, &filename);
  
  	outfile = OpenOutFile(filename);
  
  	for (counter=0; counter<cluster->numGenes-1; counter++){
    
    	for (comparedToCounter=counter+1; comparedToCounter<cluster->numGenes; comparedToCounter++){
      
      		pearsonCorrelation=CalculateCorrelation(&dataMatrix[counter*numExperiments], &dataMatrix[comparedToCounter*numExperiments], numExperiments, eWeights);
      
      		/* Once we have the correlation coefficient we have to check
      		 * if it's greater than the last value in the linked list
      		 * for BOTH the geneCounter gene, and the comparedToCounter
      		 * gene.  This way every linked list will contain its top
      		 * five most similar correlations.  If you only checked the
      		 * geneCounter gene, then it is possible (it does happen, I  
      		 *  checked) that you would not be storing the top correlations 
      		 * for some genes anywhere.
      		 */
      
      		CheckToInsert(cluster, counter, comparedToCounter, pearsonCorrelation);
      		CheckToInsert(cluster, comparedToCounter, counter, pearsonCorrelation);

 		}
 		
 		/* now print out relevant correlations for gene, then free those correlations */
      	
     	fprintf(outfile, "%s", cluster->genes[counter].orf);
    	PrintOneGene(cluster->genes[counter].first, outfile, cluster);
    		
    	FreeCorrelations(&(cluster->genes[counter].first));
    
  		if (!(counter%numAfterWhichToPrint)){
     		printf ("%d\n", counter);
    		fflush(stdout);
   		}
   		
  	}
  	
  	/* print correlations for final gene */
  	
  	fprintf(outfile, "%s", cluster->genes[counter].orf);
    PrintOneGene(cluster->genes[counter].first, outfile, cluster);
    		
    FreeCorrelations(&(cluster->genes[counter].first));
  	
  	printf("Done Making Correlations\n");
  	fflush(stdout);

	fclose(outfile);
	free(filename);

}

/*
 * Function: CalculateCorrelation
 * Usage: pearsonCorrelation=CalculateCorrelation(geneCounter, comparedToCounter, dataMatrix, numExperiments, eWeights, type, cluster->numGenes)
 * ------------------------------------------------------------------------------------------------------------------------
 * This function calculates the correlation between two expression profiles, whose identities are
 * indicated by geneCounter and comparedToCounter.  The algorithm calculates the pearson correlation
 * and only utilizes data where the two profiles have data (experiments) in common.  It is able
 * to keep running totals, so that it does not have to go over the datasets once again after it
 * has found which experiments are in common between two profiles.  This code is taken almost verbatim
 * from Mike Eisen's original correlation code.  One bug in that code has been fixed (the original
 * code wrongly used numExperiments, instead of Count, in the final calculation) and the data access looks
 * somewhat different to reflect the nature of the way that I have stored the data in what was a 
 * dynamically allocated array.  I have used pointers all the time to access the array data.  It looks
 * ugly and confusing, as I'm updating the pointers themselves, rather than a separate variable.  It is,
 * however, far quicker (~35%!).
 */
 
float CalculateCorrelation(float *genePtr, float *cmpPtr, int numExperiments, float *colPtr){
  float Sum1, Sum2, Sum11, Sum22, Sum12, Ave1, Ave2, Count, Corr, norm;
  register float colWeight;
  register float geneVal;
  register float cmpVal;
  float *max=genePtr+numExperiments;
  Sum1 = Sum2 = Sum11 = Sum22 = Sum12 = Count = Ave1 = Ave2 = 0;
  Corr=-1.0;
  
  
  for(; genePtr<max; genePtr++, cmpPtr++, colPtr++){
    
    geneVal=*genePtr;
    cmpVal=*cmpPtr;
    if(geneVal!=NODATA && cmpVal!=NODATA){
      colWeight=*colPtr;
      Sum1+=colWeight * geneVal;
      Sum2+=colWeight * cmpVal;
      Sum11+=colWeight * geneVal * geneVal;
      Sum22+=colWeight * cmpVal * cmpVal;
      Sum12+=colWeight * geneVal * cmpVal;
      Count+=colWeight;
    }
  }
  
  if (Count){
    if(gCentered){
      Ave1 = Sum1/Count;
      Ave2 = Sum2/Count;
      norm=sqrt((Sum11 - 2 * Ave1 * Sum1 + Count * Ave1 * Ave1)*(Sum22 - 2 * Ave2 * Sum2 + Count * Ave2 * Ave2));
      if (norm>0){
	Corr = (Sum12 - Sum1 * Ave2 - Sum2 * Ave1 + Count * Ave1 * Ave2) /norm;
      }
    }else{
      norm=sqrt(Sum11*Sum22);
      if (norm>0){
	Corr=(Sum12/norm);
      }
    }
  }else{
    Corr=0;
  }
  
  return (Corr);
  
}

/*
 * Function: CheckToInsert
 * Usage: CheckToInsert(cluster, geneCounter, comparedToCounter, pearsonCorrelation);
 * -------------------------------------------------------------------------------------
 * This function checks whether a correlation that was just made is
 * worthy of insertion into a list of correlations, based on it's value.
 * if so it makes a new record, which contains a number that indicates
 * the gene to which the geneCounter gene is correlated to, then calls
 * a function to insert it.  It will also check whether there are enough
 * correlations already in the list, and delete the lowest one if appropriate.
 */
 
void CheckToInsert(clusterRec *cluster, int geneCounter, int comparedToCounter, float pearsonCorrelation){
	
  correlationRec *newOne;
  
  if (pearsonCorrelation > gCutOff && ((cluster->genes[geneCounter].last==NULL)||
      (pearsonCorrelation > cluster->genes[geneCounter].last->corr)|| (cluster->genes[geneCounter].numCorrelations<gMaxNumCorrelations))){
    
    if (cluster->genes[geneCounter].numCorrelations==gMaxNumCorrelations){
      
      cluster->genes[geneCounter].last->corr=pearsonCorrelation;
      cluster->genes[geneCounter].last->ORFnumber=comparedToCounter;
      
      cluster->genes[geneCounter].last=SwitchLast(&(cluster->genes[geneCounter].first), cluster->genes[geneCounter].last);
    }else{
      
      newOne=MakeNewRecord(pearsonCorrelation, comparedToCounter);
      
      InsertSorted(&(cluster->genes[geneCounter].first), newOne);
      
      if (newOne->next==NULL){
	cluster->genes[geneCounter].last=newOne;
      }
      
      ++cluster->genes[geneCounter].numCorrelations;
      
    }
  }
  
} 

/*
 * Function: SwitchLast
 */
 
correlationRec *SwitchLast(correlationRec **list, correlationRec* newOne){
  correlationRec *curr, *prev;
  prev=NULL;
  
  for (curr=*list; curr->next!=NULL; curr=curr->next){
    if (curr->corr<newOne->corr) break; /* We passed it, so now want to insert here */
    prev=curr;
  }
  
  /* now curr points to the entry to delete (we already actually knew this)
   * and prev points to the entry that will now be the end of the list
   */
  
  newOne->next=curr;
  
  if (prev!=NULL){
    prev->next=newOne;
  }else{
    *list=newOne;
  }
  
  for(;curr->next!=newOne;curr=curr->next){}
  
  curr->next=NULL;
  return curr;
  
}

/*
 * Function: MakeNewRecord
 * Usage: MakeNewRecord(pearsonCorrelation, comparedToCounter)
 * -----------------------------------------------------------
 * This function allocates space for a new correlationRec
 * and initializes its fields
 */
correlationRec *MakeNewRecord(double correlation, int geneNumber){

  correlationRec *newOne;
  newOne=malloc(sizeof(correlationRec));
  if (newOne==NULL) Error("Not enough memory available for a new correlationRec");
  newOne->corr=correlation;
  newOne->ORFnumber=geneNumber;
  newOne->next=NULL;
  return (newOne);
  
}
/*
 * Function: InsertSorted
 * Usage: InsertSorted(&(cluster->genes[geneCounter]), cp)
 * ----------------------------------------------------------
 * This function will insert a correlationRec in order (with 
 * respect to the value of the correlation it contains).  It 
 * handles the special case of their being no previous correlationRecs
 * in the list.  This is why the list has to be passed in as a double
 * pointer.
 */
 
void InsertSorted(correlationRec **list, correlationRec *newOne){
	
  correlationRec *prev, *curr;
  prev=NULL;
  for (curr=*list; curr!=NULL; curr=curr->next){
    if (curr->corr<newOne->corr) break; /* We passed it, so now want to insert here */
    prev=curr;
  }
  
  /* now, "prev" points to the one before where the newOne will be inserted,
     next "curr" points to the one after */
  
  newOne->next=curr;
  
  if (prev !=NULL){
    prev->next=newOne;
  }else{
    *list = newOne;
  }
  
}

/*
 * Function: DeleteLast
 * Usage: cluster->genes[geneCounter].last=DeleteLast(cluster->genes[geneCounter].first)
 * -------------------------------------------------------
 * This function is invoked when the last correlation in a list is to a gene
 * that has just been joined into a node.  Hence the correlationRec associated
 * with that correlation is deleted, and the one in the list previous to it
 * is returned as now being at the end of the list.
 */
 
correlationRec *DeleteLast(correlationRec **list){
  correlationRec *curr, *prev;
  prev=NULL;
  
  for (curr=*list; curr->next!=NULL; curr=curr->next){
    prev=curr;
  }
  
  /* now curr points to the entry to delete (we already actually knew this)
   * and prev points to the entry that will now be the end of the list
   */
  
  prev->next=NULL;
  free (curr);
  return prev;
  
}

	 

/*
 * Function: FreeCluster
 * Usage: FreeCluster(cluster)
 * ---------------------------------
 * This function frees the memory associated with a particular dataset,
 * including all ORF and genes names.
 */

void FreeCluster(clusterRec *cluster){
  int counter;
  
  for (counter=0; counter<cluster->numGenes; counter++){
    if (cluster->genes[counter].orf!=NULL) free(cluster->genes[counter].orf);
    if (cluster->genes[counter].name!=NULL) free(cluster->genes[counter].name);
  }
  free (cluster->genes);
  
}

/*
 * Function: FreeCorrelations
 * Usage: FreeCorrelations(&(cluster->genes[node1].first))
 * ----------------------------------------------------------
 * This function walks through a linked list freeing the memory
 * associated with each stored correlation.
 */
 
void FreeCorrelations(correlationRec **node){

  correlationRec *curr, *next;
  
  for (curr=*node; curr!=NULL;){
    next=curr->next;
    free(curr);
    curr=next;
  }
}

/*
 * Function: MakeFile
 * Usage: MakeFileNames(ifile, &fileName)
 * -----------------------------------------------------------------------
 * This function simply determines from the name of the input file, what the
 * output files should be called.
 */

void MakeFileName(char *ifile, char **fileName){
  
  char* prefix;
  
  prefix=GetFilePrefix(ifile);
  
  *fileName=malloc((strlen(prefix)+7)*sizeof(char));
  if(*fileName==NULL)Error("Not enough memory for filenames");
  strcpy(*fileName, prefix);
  strcpy(*fileName+strlen(prefix), "stdCor\0");
  
  free(prefix);
  
}


/*
 * Function: Error
 * Usage: Error(msg, ...)
 * ----------------------
 * This function generates an error string, expanding % constructions
 * appearing in the error message string just as printf does.
 * After printing the error message, the program terminates,
 * This code was taken from Eric Roberts' "The Art and Science of C".
 */

void Error(char *msg, ...){

  va_list args;
  
  va_start(args, msg);
  fprintf(stderr, "Error: ");
  vfprintf(stderr, msg, args);
  fprintf(stderr, "\n");
  va_end(args);
  exit(1);
  
}



/* Function: FreeExperimentNames
 * Usage: FreeExperimentNames(experimentNames, numExperiments)
 * --------------------------------------------------------------
 * This function frees the storage associated with keeping track of the experiment names
 */
 
void FreeExperimentNames(char **experimentNames, int numExperiments){
  int i;
  
  for (i=0; i<numExperiments; i++){
    free (experimentNames[i]);
  }
  
  free(experimentNames);
  
}

/*
 * Function: PrintOneGene
 * Usage: PrintOneGene(cluster->genes[counter].first, outfile)
 * --------------------------------------------------------------
 * This function will print out the correlations to a particular gene,
 * The output is tab delimited, and consists of both the gene name,
 * and the correlation value itself.
 */
 
void PrintOneGene(correlationRec *list, FILE *outfile, clusterRec *cluster){

  correlationRec *curr;
  
  for (curr=list; curr!=NULL; curr=curr->next){
      
    fprintf(outfile, "\t%s", cluster->genes[(curr->ORFnumber)].orf);
    if (gShowCorrelations){
      fprintf(outfile, "\t%f", curr->corr);
    }
  }
  
  fprintf(outfile, "\n");
  
}

/*
 * Function : LogTransformData
 * Usage : LogTransformData(dataMatrix, numGenes, numExperiments)
 * --------------------------------------------------------------
 * This function transforms all the data in the dataMatrix into
 * into log base2
 */
 
void LogTransformData(float *dataMatrix, int numGenes, int numExperiments){

  int gene;
  int experiment;
  float log2=log(2);
  
  printf("Log Transforming Data\n");
  
  for (experiment=0; experiment<numExperiments; experiment++){
    
    for (gene=0; gene<numGenes; gene++){
      
      if (dataMatrix[gene*numExperiments+experiment]!=NODATA){
	
	if (dataMatrix[gene*numExperiments+experiment]<=0){ 
	  
	  Error("There's is a value in gene %d, experiment %d, at or below zero, that can't be logged", gene, experiment);
	  
	}else{
	  
	  dataMatrix[gene*numExperiments+experiment]=log(dataMatrix[gene*numExperiments+experiment])/log2;
	  
	}
	
      }
      
    }
    
  }
  
}
