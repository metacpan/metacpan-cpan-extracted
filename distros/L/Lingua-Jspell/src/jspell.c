
/* -*- Mode: C; tab-width: 4; -*- */

/**
 * @file
 * @brief An interactive spelling corrector and word classificator
 */

/* jspell.c - An interactive spelling corrector and word classificator
 *
 * Copyright (c) 1983, by Pace Willisson
 * Copyright (c) 1992, 1993, Geoff Kuenning, Granada Hills, CA
 * Copyright (c) 1994-2010,
 *    Ulisses Pinto,
 *    José João Almeida,
 *    Alberto Simões,
 *
 *    Projecto Natura,
 *    Universidade do Minho
 */

#include <string.h>
#include <ctype.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>

#include "jsconfig.h"
#include "jspell.h"
#include "proto.h"
#include "msgs.h"
#include "version.h"

static void expandmode(int printorig);

/** ...  */
struct dent *last_found;

static int add_inc = 0;

static void usage(char *cmd)
{
    fprintf(stderr, ISPELL_C_USAGE1, cmd);
    fprintf(stderr, ISPELL_C_USAGE2, cmd);
    fprintf(stderr, ISPELL_C_USAGE3, cmd);
    fprintf(stderr, ISPELL_C_USAGE4, cmd);
    fprintf(stderr, ISPELL_C_USAGE5, cmd);
    fprintf(stderr, ISPELL_C_USAGE6, cmd);
    fprintf(stderr, ISPELL_C_USAGE7, cmd);
    exit(1);
}

/* wchars -  Characters in -w option, if any
 *           -w: may be used to specify characters other than
 *           alphabetics which may also appear in words 
 */
static void initckch(char *wchars)
{
    register ichar_t c;
    char num[4];

    for (c = 0; c < (ichar_t)(SET_SIZE + hashheader.nstrchars); ++c) {
	if (iswordch(c)) {
	    if (!mylower(c)) {
		Try[Trynum] = c;
		++Trynum;
	    }
	}
    }
    if (wchars != NULL) {
	while (Trynum < SET_SIZE && *wchars != '\0') {
	    if (*wchars != 'n' && *wchars != '\\') {
		c = *wchars;
		++wchars;
	    }
	    else {
		++wchars;
		num[0] = '\0';
		num[1] = '\0';
		num[2] = '\0';
		num[3] = '\0';
		if (isdigit (wchars[0])) {
		    num[0] = wchars[0];
		    if (isdigit (wchars[1])) {
			num[1] = wchars[1];
			if (isdigit(wchars[2]))
			    num[2] = wchars[2];
		    }
		}
		if (wchars[-1] == 'n') {
		    wchars += strlen(num);
		    c = atoi(num);
		}
		else {
		    wchars += strlen(num);
		    c = 0;
		    if (num[0])
			c = num[0] - '0';
		    if (num[1]) {
			c <<= 3;
			c += num[1] - '0';
		    }
		    if (num[2]) {
			c <<= 3;
			c += num[2] - '0';
		    }
		}
	    }
	    c &= NOPARITY;
	    if (!hashheader.wordchars[c]) {
		hashheader.wordchars[c] = 1;
		hashheader.sortorder[c] = hashheader.sortval++;
		Try[Trynum] = c;
		++Trynum;
	    }
	}
    }
}


/* the -v option causes ispell to print its current version
 * identification on the standard output and exit. If the switch is
 * doubled, ispell will also print the options that it was compiled
 * with.
 */
static void option_v(char *cmd, int argc, char *argv[], int arglen)
{
    char ** versionp;
    char *p;

    if (arglen > 3)
	usage(cmd);
    for (versionp = Version_ID; *versionp; ) {
	p = *versionp++;
	if (strncmp(p, "(#) ", 5) == 0)
	    p += 5;
	printf("%s\n", p);
    }
    if ((*argv)[2] == 'v') {
	printf(ISPELL_C_OPTIONS_ARE);
	printf("\tBAKEXT = \"%s\"\n", BAKEXT);
/*	printf("\tBINDIR = \"%s\"\n", BINDIR); */
#ifdef BOTTOMCONTEXT
	printf("\tBOTTOMCONTEXT\n");
#else /* BOTTOMCONTEXT */
	printf("\t!BOTTOMCONTEXT\n");
#endif /* BOTTOMCONTEXT */
#if TERM_MODE == CBREAK
	printf("\tCBREAK\n");
#endif /* TERM_MODE */
#ifdef COMMANDFORSPACE
	printf("\tCOMMANDFORSPACE\n");
#else /* COMMANDFORSPACE */
	printf("\t!COMMANDFORSPACE\n");
#endif /* COMMANDFORSPACE */
#ifdef CONTEXTROUNDUP
	printf("\tCONTEXTROUNDUP\n");
#else /* CONTEXTROUNDUP */
	printf("\t!CONTEXTROUNDUP\n");
#endif /* CONTEXTROUNDUP */
	printf("\tCONTEXTPCT = %d\n", CONTEXTPCT);
	printf("\tDEFHASH = \"%s\"\n", DEFHASH);
	printf("\tDEFINCSTR = \"%s\"\n", DEFINCSTR);
	printf("\tDEFLANG = \"%s\"\n", DEFLANG);
	printf("\tDEFNOBACKUPFLAG = %d\n", DEFNOBACKUPFLAG);
	printf("\tDEFPAFF = \"%s\"\n", DEFPAFF);
	printf("\tDEFPDICT = \"%s\"\n", DEFPDICT);
	printf("\tDEFTEXFLAG = %d\n", DEFTEXFLAG);
	printf("\tEGREPCMD = \"%s\"\n", EGREPCMD);
#ifdef EQUAL_COLUMNS
	printf("\tEQUAL_COLUMNS\n");
#else /* EQUAL_COLUMNS */
	printf("\t!EQUAL_COLUMNS\n");
#endif /* EQUAL_COLUMNS */
#ifdef IGNOREBIB
	printf ("\tIGNOREBIB\n");
#else /* IGNOREBIB */
	printf ("\t!IGNOREBIB\n");
#endif /* IGNOREBIB */
	printf("\tINCSTRVAR = \"%s\"\n", INCSTRVAR);
	printf("\tINPUTWORDLEN = %d\n", INPUTWORDLEN);
	printf("\tLANGUAGES = \"%s\"\n", LANGUAGES);
	printf("\tLIBDIR = \"%s\"\n", LIBDIR); 
#ifndef REGEX_LOOKUP
#endif /* REGEX_LOOKUP */
	printf("\tMAKE_SORTTMP = \"%s\"\n", MAKE_SORTTMP);
	printf("\tMALLOC_INCREMENT = %d\n", MALLOC_INCREMENT);
	/* printf("\tMAN1DIR = \"%s\"\n", MAN1DIR); */
	/* printf("\tMAN1EXT = \"%s\"\n", MAN1EXT); */
	/* printf("\tMAN4DIR = \"%s\"\n", MAN4DIR); */
	/* printf("\tMAN4EXT = \"%s\"\n", MAN4EXT); */
	printf("\tMASKBITS = %d\n", MASKBITS);
	printf("\tMASKTYPE = %s\n", MASKTYPE_STRING);
	printf("\tMASKTYPE_WIDTH = %d\n", MASKTYPE_WIDTH);
	printf("\tMAXAFFIXLEN = %d\n", MAXAFFIXLEN);
	printf("\tMAXCONTEXT = %d\n", MAXCONTEXT);
	printf("\tMAXINCLUDEFILES = %d\n", MAXINCLUDEFILES);
	printf("\tMAXNAMLEN = %d\n", MAXNAMLEN);
	printf("\tMAXPATHLEN = %d\n", MAXPATHLEN);
	printf("\tMAXPCT = %d\n", MAXPCT);
	printf("\tMAXSEARCH = %d\n", MAXSEARCH);
	printf("\tMAXSTRINGCHARLEN = %d\n", MAXSTRINGCHARLEN);
	printf("\tMAXSTRINGCHARS = %d\n", MAXSTRINGCHARS);
	printf("\tMAX_HITS = %d\n", MAX_HITS);
	printf("\tMINCONTEXT = %d\n", MINCONTEXT);
#ifdef MINIMENU
	printf("\tMINIMENU\n");
#else /* MINIMENU */
	printf("\t!MINIMENU\n");
#endif /* MINIMENU */
	printf("\tMINWORD = %d\n", MINWORD);
	printf("\tMSGLANG = %s\n", MSGLANG);
#ifdef NO_CAPITALIZATION_SUPPORT
	printf("\tNO_CAPITALIZATION_SUPPORT\n");
#else /* NO_CAPITALIZATION_SUPPORT */
	printf ("\t!NO_CAPITALIZATION_SUPPORT\n");
#endif /* NO_CAPITALIZATION_SUPPORT */
#ifdef NO8BIT
	printf("\tNO8BIT\n");
#else /* NO8BIT */
	printf("\t!NO8BIT (8BIT)\n");
#endif /* NO8BIT */
	printf("\tNRSPECIAL = \"%s\"\n", NRSPECIAL);
	printf("\tOLDPAFF = \"%s\"\n", OLDPAFF);
	printf("\tOLDPDICT = \"%s\"\n", OLDPDICT);
	printf("\tPDICTVAR = \"%s\"\n", PDICTVAR);
#ifdef PIECEMEAL_HASH_WRITES
	printf("\tPIECEMEAL_HASH_WRITES\n");
#else /* PIECEMEAL_HASH_WRITES */
	printf("\t!PIECEMEAL_HASH_WRITES\n");
#endif /* PIECEMEAL_HASH_WRITES */
#if TERM_MODE != CBREAK
	printf("\tRAW\n");
#endif /* TERM_MODE */
#ifdef REGEX_LOOKUP
	printf("\tREGEX_LOOKUP\n");
#else /* REGEX_LOOKUP */
	printf ("\t!REGEX_LOOKUP\n");
#endif /* REGEX_LOOKUP */
	printf("\tSIGNAL_TYPE = %s\n", SIGNAL_TYPE_STRING);
	printf("\tSORTPERSONAL = %d\n", SORTPERSONAL);
	printf("\tTEMPNAME = \"%s\"\n", TEMPNAME);
	/* printf("\tTERMLIB = \"%s\"\n", TERMLIB); */
	printf("\tTEXSPECIAL = \"%s\"\n", TEXSPECIAL);
	printf("\tWORDS = \"%s\"\n", WORDS);
    }
    exit(0);
}


/* The input file is in nroff/troff format */
static char *option_n(char *cmd, char *preftype, int arglen)
{
    if (arglen > 2)
	usage(cmd);
    tflag = 0;                /* nroff/troff mode */
    deftflag = 0;
    if (preftype == NULL)
	preftype = "nroff";
    return preftype;
}

/* The input file is in  TeX/LaTeX format */
static char *option_t(char *cmd, char *preftype, int arglen)
{
    if (arglen > 2)
	usage(cmd);
    tflag = 1;
    deftflag = 1;
    if (preftype == NULL)
	preftype = "tex";
    return preftype;
}

/* -T type - Assume a given formatter type for all files */
static char *option_T(char *cmd, int argc, char *argv[]) 
{
    char *p;
    
    p = (*argv)+2;
    if (*p == '\0') {
	argv++; argc--;
	add_inc = 1;
	if (argc == 0)
	    usage(cmd);
	p = *argv;
    }
    return p;
}

/* print a one-line verson identification message for each word */
static void option_A(char *cmd, int arglen)
{
    if (arglen > 2)
	usage(cmd);
    incfileflag = 1;
    aflag = 1;
}

/* Print after gclass */
static void option_J(char *cmd, int arglen)
{
    if (arglen > 2)
	usage(cmd);
    Jflag = 1;
}

/* print a one-line verson identification message for each word */
static void option_a(char *cmd, int arglen)
{
    if (arglen > 2)
	usage(cmd);
    aflag++;
}

/* causes the affix tables from the dictionary file to be dumped to
 * stdout */
static void option_D(char *cmd, int arglen)
{
    if (arglen > 2)
	usage(cmd);
    dumpflag++;
    nodictflag++;
}

/* expands affix flags to produce a list of words
 * is the reverse of -c */
static void option_e(char *cmd, int arglen, char *argv[])
{
    if (arglen > 3) usage(cmd);
    eflag = 1;
    if ((*argv)[2] == 'e')
	eflag = 2;
    else if ((*argv)[2] >= '1'  &&  (*argv)[2] <= '4')
	eflag = (*argv)[2] - '0';
    else if ((*argv)[2] != '\0')
	usage(cmd);
    nodictflag++;
}

/* causes a list of words to be read from the standard input for each
 * word, a list of possible root words and affixes will be written to
 * the standard output  */
static void option_c(char *cmd, int arglen, char *argv[])
{
    if (arglen > 2) usage(cmd);
    cflag++;
    lflag++;
}

/* Create a backup file by appending ".bak" to the name of the input
 * file  */
static void option_b(char *cmd, int arglen) 
{
    if (arglen > 2) usage(cmd);
    xflag = 0; 
}

/* Don't create a backup file */
static void option_x(char *cmd, int arglen)
{
    if (arglen > 2) usage(cmd);
    xflag = 1;       
}

/* used in conjunction with -a or -A options -f filename: write its
 * results to the given file, rather than std. output  */
static void option_f(char *cmd, int argc, char *argv[]) 
{
    char *p;

    fflag++;
    p = (*argv)+2;
    if (*p == '\0') {
	argv++; argc--;
	add_inc = 1;
	if (argc == 0)
	    usage(cmd);
	p = *argv;
    }
    askfilename = p;
    if (*askfilename == '\0')
	askfilename = NULL;
}

/* L context: Look up words in system dictionary (controlled by the
 * WORDS compilation option */
static void option_L(char *cmd, int argc, char *argv[])
{
    char *p;

    p = (*argv)+2;
    if (*p == '\0') {
	argv++; argc--;
	if (argc == 0)
	    usage(cmd);
	p = *argv;
    }
    contextsize = atoi(p);
}

/* produce a list of misspelled words */
static void option_l(char *cmd, int arglen)
{
    if (arglen > 2) usage(cmd);
    lflag++;
}

/* Sort the list of guesses by probable correctness */
static void option_S(char *cmd, int arglen)
{
    if (arglen > 2) usage(cmd);
    sortit = 0;
}

/* Report run-together words with missing blanks as spelling errors */
static void option_B(char *cmd, int arglen)
{
    if (arglen > 2) usage(cmd);
    missingspaceflag = 1;
}

/* Consider run-together words as legal compounds  */
static void option_C(char *cmd, int arglen)
{
    if (arglen > 2) usage(cmd);
    missingspaceflag = 0;
}

/* Don't generate extra root/affix combinations  */
static void option_P(char *cmd, int arglen)
{
    if (arglen > 2) usage(cmd);
    tryhardflag = 0;
}

/* Make possible root/affix combinations that aren't in the
 * dictionary */
static void option_m(char *cmd, int arglen)
{
    if (arglen > 2) usage(cmd);
    tryhardflag = 1;
}

/* suppress the mini-menu */
static void option_N(char *cmd, int arglen)
{
    if (arglen > 2) usage(cmd);
    minimenusize = 0;
}

/* activate mini-menu at the bottom of the screen with these
 * options */
static void option_M(char *cmd, int arglen)
{
    if (arglen > 2) usage(cmd);
    minimenusize = 2;
}

/* p file: specify an alternate personal dictionary */
static void option_p(char *LibDict, char **cpd, char *cmd, int argc, char *argv[])
{
	char *c;
    c = (*argv)+2;
    if (*c == '\0') {
		argv++; argc--;
		add_inc = 1;
		if (argc == 0)
		    usage(cmd);
		c = *argv;
		if (*c == '\0')
		    c = NULL;
    }
	*cpd = c;
    LibDict = NULL;
}

/* d file: specify an alternate dictionary file */
static void option_d(char *LibDict, char *cpd, char *cmd, int argc, char *argv[])
{
    char *p;

    p = (*argv)+2;
    if (*p == '\0') {
		argv++; argc--;
		add_inc = 1;
		if (argc == 0)
		    usage(cmd);
		p = *argv;
    }
    if (index(p, '/') != NULL)
		strcpy(hashname, p);
    else
		sprintf(hashname, "%s/%s", LIBDIR, p);
    if (cpd == NULL  &&  *p != '\0')
		LibDict = p;
    p = rindex(p, '.');
    if (p != NULL  &&  strcmp(p, ".hash") == 0)
		*p = '\0';        /* Don't want ext. in LibDict */
    else
		strcat(hashname, ".hash");
}

/* style to print characters not in the 7-bit ANSI character set */
static void option_V(char *cmd, int arglen)
{
    if (arglen > 2) usage(cmd);
    vflag = 1;
}

/* Specify length of words that are always legal */
static void option_W(char *cmd, int argc, char *argv[]) 
{
    if ((*argv)[2] == '\0') {
	argv++; argc--;
	add_inc = 1;
	if (argc == 0)
	    usage(cmd);
	minword = atoi(*argv);
    }
    else
	minword = atoi(*argv + 2);
}

/* o - define new output format */
static void option_o(char *cmd, int argc, char *argv[])
{
    char *o_form2;
    
    oflag = 1;
    o_form2 = (*argv)+2;
    if (*o_form2 == '\0') {
	argv++; argc--;
	add_inc = 1;
	if (argc == 0)
	    usage(cmd);
	o_form2 = *argv;
	if (*o_form2 == '\0')
	    o_form2 = NULL;
    }
    if (o_form2) strcpy(o_form, o_form2);
    else o_form[0] = '\0';
}

/* g - display "good" options only - do not display "near misses" */
static void option_g(char *cmd, int arglen)
{
    if (arglen > 2) usage(cmd);
    gflag = 1;
}

/* y - do not display typing errors in "near misses" */
static void option_y(char *cmd, int arglen)
{
    if (arglen > 2) usage(cmd);
    yflag = 1;
}

/* u - no punct - signal is not word */
static void option_u(char *cmd, int arglen)
{
    if (arglen > 2) usage(cmd);
    signal_is_word = 0;
}

/* z - */
static void option_z(char *cmd, int arglen)
{
    if (arglen > 2) usage(cmd);
    showflags = 1;
}

static void verify_files(int argc, char *argv[])
{
    /* Because of the high cost of reading the dictionary, we stat the
     * files specified first to see if they exist. If at least one
     * exists, we continue.
     */
    int argno;

    for (argno = 0; argno < argc; argno++) {
	if (access(argv[argno], R_OK) >= 0) break;
    }
    if (argno >= argc  &&  !lflag  &&  !aflag  &&  !eflag  &&  !dumpflag) {
	fprintf(stderr, argc == 1 ? ISPELL_C_NO_FILE : ISPELL_C_NO_FILES);
	exit(1);
    }
}

static void det_prefstringchar(char *preftype)
{
    if (preftype != NULL) {
	prefstringchar = findfiletype(preftype, 1, &deftflag);
	if (prefstringchar < 0              &&  
            strcmp(preftype, "tex") != 0    && 
            strcmp(preftype, "nroff") != 0)
        {
	    fprintf(stderr, ISPELL_C_BAD_TYPE, preftype);
	    exit(1);
	}
    }
}

static void process_LibDict(char *LibDict, char *cpd)
{
	char *p;
	static char libdictname[sizeof DEFHASH];

	if (LibDict == NULL) {
		strcpy(libdictname, DEFHASH);
		LibDict = libdictname;
		p = rindex(libdictname, '.');
		if (p != NULL  &&  strcmp(p, ".hash") == 0)
	    	*p = '\0'; /* Don't want ext. in LibDict */
    }
    if (!nodictflag)
		treeinit(cpd, LibDict);
}

static int process_a_e_and_d_flags(void) 
{
	int res;
    
	res = 0;
	if (aflag) {
		if (!islib) {
			askmode();
			treeoutput();
		}
	} else if (eflag) {
		expandmode(eflag);
	} else if (dumpflag) {
		dumpmode();
	} else {
		res = 1;		
	}
    return res;
}

/**
 * @brief Max number of...
 */
#define MAX_SOL 15

/**
 * @brief ...
 * @param argc
 * @param argv
 * @param lib
 */
int my_main(int argc, char *argv[], char lib)
{
    char *wchars = NULL;
    char *preftype = NULL;
    static char outbuf[BUFSIZ];
    int arglen, old_argc;
    char *cpd = NULL;
    char *Cmd = *argv;
    /* Pointer to name of $(LIBDIR)/dict */
    char *LibDict = NULL; 

    islib = lib;
    old_argc = argc;
    Trynum = 0;
    sprintf(hashname, "%s/%s", LIBDIR, DEFHASH);
    strcpy(signs, DEFAULT_SIGNS);

    argv++;
    argc--;
    while (argc && **argv == '-') {
		/*
		 * Trying to add a new flag?  Can't remember what's been used?
		 * Here's a handy guide:
		 *
		 * Used:
		 *        ABCDEFGHIJKLMNOPQRSTUVWXYZ 0123456789
		 *        ^^^^       ^^^ ^  ^^ ^^
		 *        abcdefghijklmnopqrstuvwxyz
		 *        ^^^^^^*    ^^^*^  ^^*^^^*
		 */
		arglen = strlen(*argv);
		add_inc = 0;
	
		switch ((*argv)[1]) {
		case 'v':
		    option_v(Cmd, argc, argv, arglen);
		    break;
		case 'n':
		    preftype = option_n(Cmd, preftype, arglen);
		    break;
		case 't': /* TeX mode */
		    preftype = option_t(Cmd, preftype, arglen);
		    break;
		case 'T': /* Set preferred file type */
		    preftype = option_T(Cmd, argc, argv);
		    break;
		case 'A':
		    option_A(Cmd, arglen);
		    break;
		case 'a':
		    option_a(Cmd, arglen);
		    break;
		case 'D':
		    option_D(Cmd, arglen);
		    break;
		case 'J':
		    option_J(Cmd, arglen);
		    break;
		case 'e':
		    option_e(Cmd, arglen, argv);
		    break;
		case 'c':
		    option_c(Cmd, arglen, argv);
		    break;
		case 'b':
		    option_b(Cmd, arglen);
		    break;
		case 'x':
		    option_x(Cmd, arglen);
		    break;
		case 'f':
		    option_f(Cmd, argc, argv); 
		    break;
		case 'L':
		    option_L(Cmd, argc, argv);
		    break;
		case 'l':
		    option_l(Cmd, arglen);
		    break;
		case 'S':
		    option_S(Cmd, arglen);
		    break;
		case 'B':   /* -B: report missing blanks */
		    option_B(Cmd, arglen);
		    break;
		case 'C':   /* -C: compound words are acceptable */
		    option_C(Cmd, arglen);
		    break;
		case 'P':   /* -P: don't gen non-dict poss's */
		    option_P(Cmd, arglen);
		    break;
		case 'm':   /* -m: make all poss affix combos*/
		    option_m(Cmd, arglen);
		    break;
		case 'N':   /* -N:  suppress minimenu */
		    option_N(Cmd, arglen);
		    break;
		case 'M':
		    option_M(Cmd, arglen);
		    break;   /* -M:  force minimenu */
		case 'p':
		    option_p(LibDict, &cpd, Cmd, argc, argv);
		    break;
		case 'd':
		    option_d(LibDict, cpd, Cmd, argc, argv);
		    break;
		case 'V':    /* Display 8-bit characters as M-xxx */
		    option_V(Cmd, arglen);
		    break;
		case 'w':
		    wchars = (*argv)+2;
		    if (*wchars == '\0') {
				argv++; argc--;
				if (argc == 0)
				    usage(Cmd);
				wchars = *argv;
		    }
		    break;
		case 'W':
		    option_W(Cmd, argc, argv);
		    break;
		case 'o':
		    option_o(Cmd, argc, argv); 
		    break;
		case 'g':
		    option_g(Cmd, arglen);
		    break;
		case 'u':
		    option_u(Cmd, arglen);
		    break;
		case 'y':
		    option_y(Cmd, arglen);
		    break;
		case 'z':
		    option_z(Cmd, arglen);
		    break;
		default:
		    usage(Cmd);
		}  /* end switch */
	
		if (add_inc) {
		    argv++; argc--;
		}
		argv++; argc--;
    }

    if (!argc  &&  !lflag  &&  !aflag   &&  !eflag  &&  !dumpflag)
		usage(Cmd);

    verify_files(argc, argv);

    if (!oflag) strcpy(o_form, DEF_OUT);
	if (linit() < 0) exit(1); /* Force an error */

    det_prefstringchar(preftype);

    if (prefstringchar < 0)
		defdupchar = 0;
    else
		defdupchar = prefstringchar;

    if (missingspaceflag < 0)
		missingspaceflag = hashheader.defspaceflag;
    if (tryhardflag < 0)
		tryhardflag = hashheader.defhardflag;

    initckch(wchars);

    process_LibDict(LibDict, cpd);

    if (process_a_e_and_d_flags() == 0)
		return 0;

    if (!islib)
		setbuf(stdout, outbuf);

    /* process lflag (also used with the -c option) */
    if (lflag) {
		infile = stdin;
		outfile = stdout;
		if (!islib)
	    	checkfile();
		return 0;
    }

    /* n. of parameters advanced */
    return old_argc - argc; 
}

/**
 * @brief ...
 * @param opt
 */
void init_jspell(char *opt)
{
    int i, argc;
    static char aux[1];
    char options[255];
    static char *argv[MAX_SOL];
    
    strcpy(options, opt);
    argc = 1;
    aux[0] = '\0';
    argv[0] = aux;
    i = 0;
    while (options[i] != '\0') {
        argv[argc] = options+i;
        argc++;
        /* advance letters */
        while (options[i] != ' ' && options[i] != '\0')
            i++;
        /* advance spaces */
        while (options[i] == ' ') {
            options[i] = '\0';
            i++;
        }
    }
    /*   for (i = 0; i < argc; i++)
         printf("%d %s\n", i, argv[i]); */
    my_main(argc, argv, 1);
}



static void det_tflag(char *filename)
{
    char *cp;

    /* See if the file is a .tex file.  If so, set the appropriate flags. */
    tflag = deftflag;
    if ((cp = rindex(filename, '.')) != NULL  &&  strcmp(cp, ".tex") == 0)
        tflag = 1;
}

static void det_defdupchar(char *filename)
{
    if (prefstringchar < 0) {
        defdupchar = findfiletype(filename, 0, &tflag);
        if (defdupchar < 0) defdupchar = 0;
    }
}

static void det_readonly_access(char *filename)
{
    readonly = access(filename, W_OK) < 0;
    if (readonly) {
        fprintf(stderr, ISPELL_C_CANT_WRITE, filename);
        sleep((unsigned) 2);
    }
}

static void open_outfile(struct stat *statbuf)
{
    int file_descriptor;
    
    fstat(fileno(infile), statbuf);
    strcpy(tempfile, TEMPNAME);
#ifdef __WIN__
	file_descriptor = open(mktemp(tempfile),O_CREAT | O_RDWR | O_BINARY);
#else
    file_descriptor = mkstemp(tempfile);
#endif
    if ((outfile = fdopen(file_descriptor, "w")) == NULL) {
		fprintf(stderr, CANT_CREATE, tempfile);
		sleep((unsigned) 2);
		return;
    }
    chmod(tempfile, statbuf->st_mode);
}

static void update_file(char *filename, struct stat *statbuf)
{
    char bakfile[256];
    int c;

    if ((infile = fopen(tempfile, "r")) == NULL) {
		fprintf(stderr, ISPELL_C_TEMP_DISAPPEARED, tempfile);
		sleep((unsigned) 2);
		return;
    }

    sprintf(bakfile, "%s%s", filename, BAKEXT);

    if (strncmp(filename, bakfile, MAXNAMLEN) != 0)
		unlink(bakfile);        /* unlink so we can write a new one. */
#ifdef __WIN__
#else
    if (link(filename, bakfile) == 0)
		unlink(filename);
#endif
    /* if we can't write new, preserve .bak regardless of xflag */
    if ((outfile = fopen(filename, "w")) == NULL) {
		fprintf(stderr, CANT_CREATE, filename);
		sleep((unsigned) 2);
		return;
    }

    chmod(filename, statbuf->st_mode);

    while ((c = getc(infile)) != EOF)
        putc(c, outfile);

    fclose(infile);
    fclose(outfile);

    if (xflag  &&  strncmp(filename, bakfile, MAXNAMLEN) != 0)
        unlink(bakfile);
}

/**
 * @brief ...
 * @param filename
 */
void dofile(char *filename)
{
    struct stat statbuf;

    currentfile = filename;

    /* Checks if this is a tex file */
    det_tflag(filename);
    det_defdupchar(filename);

    if ((infile = fopen(filename, "r")) == NULL) {
		fprintf(stderr, CANT_OPEN, filename);
		sleep((unsigned) 2);
		return;
    }

    det_readonly_access(filename);
    open_outfile(&statbuf);

    quit = 0;
    changes = 0;

    checkfile();

    fclose(infile);
    fclose(outfile);

    if (!cflag)
        treeoutput();

    if (changes && !readonly)
        update_file(filename, &statbuf);
    unlink(tempfile);
}


/** ... */
extern char *root;
/** ... */
extern char *root_class;
/** ... */
extern char suf_class[MAXCLASS];

/* How to print: 
 * 1 = expansions only 
 * 2 = original line + expansions 
 * 3 = original paired w/ expansions 
 * 4 = add length ratio 
 */
static void expandmode(int option) {
    char           buf[BUFSIZ];
    int            explength;         /* Total length of all expansions */
    register char *flagp;             /* Pointer to next flag char */
    ichar_t        ibuf[BUFSIZ];
    MASKTYPE       mask[MASKSIZE];
    char           origbuf[BUFSIZ];   /* Original contents of buf */
    char           ratiobuf[20];      /* Expansion/root length ratio */
    int            rootlength;        /* Length of root word */
    register int   temp;
    /* char           strg_out[MAXSOLLEN]; */
    
    while (xgets(buf, sizeof buf, stdin) != NULL) {
        rootlength = strlen(buf);
        if (buf[rootlength - 1] == '\n')
            buf[--rootlength] = '\0';
        strcpy(origbuf, buf);
        if ((flagp = index(buf, hashheader.flagmarker)) != NULL) {
            rootlength = flagp - buf;
            *flagp++ = '\0';
        }
        if (option == 2  ||  option == 3  ||  option == 4)
            printf("%s ", origbuf);
        if (flagp != NULL) {
            if (flagp - buf > INPUTWORDLEN)
                buf[INPUTWORDLEN] = '\0';
        }
        else {
            if ((int) strlen(buf) > INPUTWORDLEN - 1)
                buf[INPUTWORDLEN] = '\0';
        }
        fputs(buf, stdout);
        fputc(' ', stdout);
        /* strtoichar(ibuf, buf, sizeof ibuf, 1);
           if (good(ibuf, 0, 0, 0)) {
           get_info(hits[0]);
           sprintf(strg_out, o_form, root, macro(root_class), pre_class,
           macro(suf_class), suf2_class);
           printf("%s ", strg_out);
           }
        */
        if (flagp != NULL) {
            bzero((char *) mask, sizeof(mask));
            while (*flagp != '\0'  &&  *flagp != '\n') {
#if MASKBITS <= 32
                temp = CHARTOBIT(mytoupper(chartoichar(*flagp)));
#else
                temp = CHARTOBIT((unsigned char) *flagp);
#endif
                if (temp >= 0  &&  temp <= LARGESTFLAG)
                    SETMASKBIT (mask, temp);
                flagp++;
                /* Accept old-format dicts with extra slashes */
                if (*flagp == hashheader.flagmarker)
                    flagp++;
            }
            if (strtoichar(ibuf, buf, sizeof ibuf, 1))
                fprintf(stderr, WORD_TOO_LONG(buf));
            explength = expand_pre(origbuf, ibuf, mask, option, "");
            explength += expand_suf(origbuf, ibuf, mask, 0, option, "", "");
            explength += rootlength;
            if (option == 4) {
                sprintf(ratiobuf, " %f",
                        (double) explength / (double) rootlength);
                fputs(ratiobuf, stdout);
                expand_pre(origbuf, ibuf, mask, 3, ratiobuf);
                expand_suf(origbuf, ibuf, mask, 0, 3, ratiobuf, "");
            }
        }
        printf(SEP4);
    }
}
