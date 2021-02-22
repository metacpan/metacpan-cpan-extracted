/* A tconv version of iconv, using only tconv API */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stddef.h>
#include <errno.h>
#include <tconv.h>
#include <optparse.h>
#include <genericLogger.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <locale.h>
#ifndef _WIN32
#  include <unistd.h>
#else
#  include <io.h>
#endif
#include "tconv_config.h"

#ifndef EXIT_FAILURE
#  define EXIT_FAILURE 1
#endif
#ifndef EXIT_SUCCESS
#  define EXIT_SUCCESS 0
#endif
#ifndef O_BINARY
#  ifdef _O_BINARY
#    define O_BINARY _O_BINARY
#  endif
#endif

#ifndef S_IREAD
#  ifdef S_IRUSR
#    define S_IREAD S_IRUSR
#  else
#    ifdef _S_IREAD
#      define S_IREAD _S_IREAD
#    endif
#  endif
#endif

#ifndef S_IWRITE
#  ifdef S_IWUSR
#    define S_IWRITE S_IWUSR
#  else
#    ifdef _S_IWRITE
#      define S_IWRITE _S_IWRITE
#    endif
#  endif
#endif

#ifndef BUFSIZ
#define BUFSIZ 1024
#endif

typedef struct tconv_helper_context {
  tconv_t tconvp;
  char   *filenames;
  int     fd;
  int     outputFd;
  char   *inbufp;
  size_t  bufsizel;
  short   guessb;
  short   fromPrintb;
  short   firstconsumercallb;
#ifndef TCONV_NTRACE
  short   verbose;
#endif
} tconv_helper_context_t;
  
static void _usage(char *argv0, short helpb);
#ifndef TCONV_NTRACE
static void traceCallback(void *userDatavp, const char *msgs);
#endif
static void fileconvert(int outputFd, char *filenames,
			char *tocodes, char *fromcodes, char *fallbacks,
                        tconv_convert_t *convertp, tconv_charset_t *charsetp,
			short guessb,
			size_t bufsizel,
			short fromPrintb
#ifndef TCONV_NTRACE
			, short verbose
#endif
			);

/*****************************************************************************/
int main(int argc, char **argv)
/*****************************************************************************/
{
  int                  longindex      = 0;
  short                fromPrintb     = 0;
  char                *fromcodes      = NULL;
  short                guessb         = 0;
  char                *charsetEngines = NULL;
  char                *convertEngines = NULL;
  short                helpb          = 0;
  char                *outputs        = NULL;
  size_t              bufsizel        = BUFSIZ;
  char                *tocodes        = NULL;
  short                usageb         = 0;
#ifndef TCONV_NTRACE
  short                verbose        = 0;
#endif
  char                *fallbacks      = NULL;
  struct optparse_long longopts[] = {
    {       "bufsize", 'b', OPTPARSE_REQUIRED},
    {"convert-engine", 'C', OPTPARSE_REQUIRED},
    {     "from-code", 'f', OPTPARSE_REQUIRED},
    {    "from-print", 'F', OPTPARSE_OPTIONAL},
    {         "guess", 'g', OPTPARSE_OPTIONAL},
    {"charset-engine", 'G', OPTPARSE_REQUIRED},
    {          "help", 'h', OPTPARSE_OPTIONAL},
    { "from-fallback", 'k', OPTPARSE_OPTIONAL},
    {        "output", 'o', OPTPARSE_REQUIRED},
    {       "to-code", 't', OPTPARSE_REQUIRED},
    {         "usage", 'u', OPTPARSE_OPTIONAL},
#ifndef TCONV_NTRACE
    {       "verbose", 'v', OPTPARSE_OPTIONAL},
#endif
    {       "version", 'V', OPTPARSE_OPTIONAL},
    {0}
  };

  char                *args;
  int                  outputFd;
  int                  option;
  struct optparse      options;
  tconv_charset_t     *charsetp = NULL;
  tconv_charset_t      charset;
  tconv_convert_t     *convertp = NULL;
  tconv_convert_t      convert;
  short                haveoptionsb = 0;

  optparse_init(&options, argv);
  while ((option = optparse_long(&options, longopts, &longindex)) != -1) {
    switch (option) {
    case 'b':
      bufsizel = atoi(options.optarg);
      break;
    case 'C':
      convertEngines = options.optarg;
      if (strcmp(convertEngines, "ICU") == 0) {
        convert.converti = TCONV_CONVERT_ICU;
        convert.u.ICUOptionp = NULL;
      } else if (strcmp(convertEngines, "ICONV") == 0) {
        convert.converti = TCONV_CONVERT_ICONV;
        convert.u.iconvOptionp = NULL;
      } else {
        convert.converti = TCONV_CONVERT_PLUGIN;
        convert.u.plugin.optionp = NULL;
        convert.u.plugin.news = NULL;
        convert.u.plugin.runs = NULL;
        convert.u.plugin.frees = NULL;
        convert.u.plugin.filenames = convertEngines;
      }
      convertp = &convert;
      break;
    case 'f':
      fromcodes = options.optarg;
      break;
    case 'F':
      fromPrintb = 1;
      break;
    case 'g':
      guessb = 1;
      break;
    case 'G':
      charsetEngines = options.optarg;
      if (strcmp(charsetEngines, "ICU") == 0) {
        charset.charseti = TCONV_CHARSET_ICU;
        charset.u.ICUOptionp = NULL;
      } else if (strcmp(charsetEngines, "CCHARDET") == 0) {
        charset.charseti = TCONV_CHARSET_CCHARDET;
        charset.u.cchardetOptionp = NULL;
      } else {
        charset.charseti = TCONV_CHARSET_PLUGIN;
        charset.u.plugin.optionp = NULL;
        charset.u.plugin.news = NULL;
        charset.u.plugin.runs = NULL;
        charset.u.plugin.frees = NULL;
        charset.u.plugin.filenames = charsetEngines;
      }
      charsetp = &charset;
      break;
    case 'h':
      helpb = 1;
      break;
    case 'k':
      fallbacks = options.optarg;
      break;
    case 'o':
      outputs = options.optarg;
      break;
    case 't':
      tocodes = options.optarg;
      break;
    case 'u':
      usageb = 1;
      break;
#ifndef TCONV_NTRACE
    case 'v':
      verbose = 1;
      break;
#endif
    case 'V':
      GENERICLOGGER_INFOF(NULL, "tconv %s", TCONV_VERSION);
      exit(EXIT_SUCCESS);
      break;
    case '?':
      GENERICLOGGER_ERRORF(NULL, "%s: %s", argv[0], options.errmsg);
      _usage(argv[0], 0);
      exit(EXIT_FAILURE);
    default:
      break;
    }
  }

  if (guessb != 0) {
    fromPrintb = 1;
    fromcodes = NULL;
    tocodes = NULL;
    outputs = "";
  }

  if ((helpb != 0) || (usageb != 0) || (bufsizel <= 0)) {
    int rci = ((helpb != 0) || (usageb != 0)) ? EXIT_SUCCESS : EXIT_FAILURE;
    _usage(argv[0], helpb);
    exit(rci);
  }
  
  if (outputs != NULL) {
    if (strlen(outputs) > 0) {
      outputFd = open(outputs,
                      O_RDWR|O_CREAT|O_TRUNC
#ifdef O_BINARY
                      |O_BINARY
#endif
                      , S_IREAD|S_IWRITE);
      if (outputFd < 0) {
	GENERICLOGGER_ERRORF(NULL, "Failed to open %s: %s", outputs, strerror(errno));
	exit(EXIT_FAILURE);
      }
    } else {
      outputFd = -1;
    }
  } else {
    outputFd = fileno(stdout);
  }

  setlocale(LC_ALL, "");
#ifndef TCONV_NTRACE
#define TCONV_FILECONVERT(outputFd, args, tocodes, fromcodes, fallbacks, convertp, charsetp, guessb, bufsizel, fromPrintb) \
  fileconvert(outputFd, args, tocodes, fromcodes, fallbacks, convertp, charsetp, guessb, bufsizel, fromPrintb, verbose)
#else
#define TCONV_FILECONVERT(outputFd, args, tocodes, fromcodes, fallbacks, convertp, charsetp, guessb, bufsizel, fromPrintb) \
  fileconvert(outputFd, args, tocodes, fromcodes, fallbacks, convertp, charsetp, guessb, bufsizel, fromPrintb)
#endif

  while ((args = optparse_arg(&options)) != NULL) {
    haveoptionsb = 1;
    TCONV_FILECONVERT(outputFd, args, tocodes, fromcodes, fallbacks, convertp, charsetp, guessb, bufsizel, fromPrintb);
  }
  if (! haveoptionsb) {
    TCONV_FILECONVERT(outputFd, NULL, tocodes, fromcodes, fallbacks, convertp, charsetp, guessb, bufsizel, fromPrintb);
  }

  if ((outputFd >= 0) && (outputFd != fileno(stdout))) {
    if (close(outputFd) != 0) {
      GENERICLOGGER_WARNF(NULL, "Failed to close %s: %s", outputs, strerror(errno));
    }
  }

  exit(EXIT_SUCCESS);
}

/*****************************************************************************/
static void traceCallback(void *userDatavp, const char *msgs)
/*****************************************************************************/
{
  GENERICLOGGER_TRACE(NULL, msgs);
}

/*****************************************************************************/
static void _usage(char *argv0, short helpb)
/*****************************************************************************/
{
  printf("Usage:\n"
	 "  %s [-f FROM-CODE] [-o OUTPUT] -t TO-CODE "
	 "[-bCFGgGuV"
#ifndef TCONV_NTRACE
	 "v"
#endif
	 "] [--help] input...\n"
	 ,
	 argv0
	 );
  if (helpb != 0) {
    printf("\n");
    printf("  Options with arguments:\n");
    printf("\n");
    printf("  -b, --bufsize        BUFSIZE    Internal buffer size.     Default: %d. Must be > 0.\n", (int) BUFSIZ);
    printf("  -C, --convert-engine ENGINE     Convertion engine.        Default: tconv default (see notes below).\n");
    printf("  -f, --from-code      FROM-CODE  Original code set.        Default: guessed from first read buffer.\n");
    printf("  -G, --charset-engine ENGINE     Charset detection engine. Default: tconv default (see notes below).\n");
    printf("  -o, --output         OUTPUT     Output filename.          Default: standard output. An empty value disables output.\n");
    printf("  -t, --to-code        TO-CODE    Destination code set.     Default: FROM-CODE.\n");
    printf("\n");

    printf("  Options without argument:\n");
    printf("\n");
    printf("  -F, --from-print            Print original code set.\n");
    printf("  -g, --guess                 Print codeset guess. Shortcut for -F -o \"\", though having precedence to the laters.\n");
    printf("  -h, --help                  Print this help and exit.\n");
    printf("  -u, --usage                 Print usage and exit.\n");
    printf("  -V, --version               Print version and exit.\n");
#ifndef TCONV_NTRACE
    printf("  -v, --verbose               Verbose mode.\n");
#endif
    printf("  -k, --from-fallback         Fallback charset when --from-code is not given and guess failed exit.\n");

    printf("\n");
    printf("Examples:");
    printf("\n");
    printf("  Validate that a file is in ISO-8859-1\n");
    printf("  %s -f ISO-8859-1 input\n", argv0);
    printf("\n");
    printf("  Transform a file from TIS-620 to UTF-16\n");
    printf("  %s -f TIS-620 -t \"UTF-16//IGNORE//TRANSLIT\" input\n", argv0);
    printf("\n");
    printf("  Print and validate the guessed encoding of a file\n");
    printf("  %s -o \"\" -F input\n", argv0);
    printf("\n");
    printf("  Print charset guess of all input files\n");
    printf("  %s -g *\n", argv0);
    printf("\n");
    printf("NOTES\n");
    printf("- Any unprocessed argument is treaded as a filename, where \"-\" is an alias for standard input. If there is no unprocessed argument, standard input is assumed.\n");
    printf("- Entry points to a charset plugin are not available via options.\n\tThe environment variables TCONV_ENV_CHARSET_NEW, TCONV_ENV_CHARSET_RUN and TCONV_ENV_CHARSET_FREE can be used to overwrite the default function names.\n\tDefault functions entry point names are: \"tconv_charset_newp\", \"tconv_charset_run\" and \"tconv_charset_free\".\n");
    printf("- Entry points to a convert plugin are not available via options.\n\tThe environment variables TCONV_ENV_CONVERT_NEW, TCONV_ENV_CONVERT_RUN and TCONV_ENV_CONVERT_FREE can be used to overwrite the default function names.\n\tDefault functions entry point names are: \"tconv_convert_newp\", \"tconv_convert_run\" and \"tconv_convert_free\".\n");
    printf("- The default convert engine is ICU if tconv has been compiled with it, else iconv if it has been compiled with it, else none.\n");
    printf("\tIf the --convert-engine option value is \"ICU\", tconv is forced to use ICU, and will fail if it does not have this support.\n");
    printf("\tSimilarly for iconv, if the option value is \"ICONV\".\n");
    printf("\tAny other option value will be considered like a path to a plugin, that will be loaded dynamically. Up to the plugin to be able to get options via, eventually, environment variables.\n");
    printf("- The default charset detection engine is cchardet and is always available. tconv optionally have support of ICU charset detection engine if it has been compiled with it.\n");
    printf("\tIf the --charset-engine option value is \"CCHARDET\", tconv will use cchardet.\n");
    printf("\tIf the option value is \"ICU\", tconv is forced to use ICU, and will fail if it does have this support.\n");
    printf("\tAlike the convert engine, any other option value will be considered like a path to a plugin, same remark as above for the plugin option.\n");
    printf("\n");
    printf("This help has been generated by tconv version %s.\n", TCONV_VERSION);
  }
}

/*****************************************************************************/
static short producer(tconv_helper_t *tconv_helperp, void *voidp, char **bufpp, size_t *countlp)
/*****************************************************************************/
{
  tconv_helper_context_t *contextp = (tconv_helper_context_t *) voidp;
  size_t                  countl   = (size_t) read(contextp->fd, contextp->inbufp, contextp->bufsizel);

#ifndef TCONV_NTRACE
  if (contextp->verbose) {
    GENERICLOGGER_TRACEF(NULL, "%s: reading %ld bytes returned %ld bytes", (contextp->filenames != NULL) ? contextp->filenames : "(standard input)", (unsigned long) contextp->bufsizel, (long) countl);
  }
#endif

  if (countl == (size_t)-1) {
    return 0;
  }
  *bufpp   = contextp->inbufp;
  *countlp = countl;

  if (contextp->guessb) {
    /* We do not want to continue */
#ifndef TCONV_NTRACE
    if (contextp->verbose) {
      GENERICLOGGER_TRACEF(NULL, "%s: guess mode - forcing end", (contextp->filenames != NULL) ? contextp->filenames : "(standard input)");
    }
#endif
    return tconv_helper_endb(tconv_helperp);
  } else if (countl == 0) {
    /* For a file descriptor, if countl is 0 then this is a eof */
#ifndef TCONV_NTRACE
    if (contextp->verbose) {
      GENERICLOGGER_TRACEF(NULL, "%s: eof", (contextp->filenames != NULL) ? contextp->filenames : "(standard input)");
    }
#endif
    return tconv_helper_endb(tconv_helperp);
  } else {
    return 1;
  }
}

/*****************************************************************************/
static short consumer(tconv_helper_t *tconv_helperp, void *voidp, char *bufp, size_t countl, size_t *countlp)
/*****************************************************************************/
{
  tconv_helper_context_t *contextp  = (tconv_helper_context_t *) voidp;
  size_t                  consumedl;

  if (contextp->outputFd >= 0) {
    consumedl = write(contextp->outputFd, bufp, countl);
  } else {
    consumedl = 0;
  }

  *countlp = consumedl;

  if (contextp->guessb || contextp->fromPrintb) {
    if (contextp->firstconsumercallb != 0) {
      GENERICLOGGER_INFOF(NULL, "%s: %s", (contextp->filenames != NULL) ? contextp->filenames : "(standard input)", tconv_fromcode(contextp->tconvp));
      contextp->firstconsumercallb = 0;
    }
  }

  return 1;
}

/*****************************************************************************/
static void fileconvert(int outputFd, char *filenames,
                        char *tocodes, char *fromcodes, char *fallbacks,
                        tconv_convert_t *convertp, tconv_charset_t *charsetp,
                        short guessb,
                        size_t bufsizel,
                        short fromPrintb
#ifndef TCONV_NTRACE
                        , short verbose
#endif
                        )
/*****************************************************************************/
{
  char                   *inbufp = NULL;
  int                     fd     = -1;
  tconv_t                 tconvp = (tconv_t)-1;
  tconv_option_t          tconvOption;
  tconv_helper_t         *tconv_helperp = NULL;
  tconv_helper_context_t  context;

  inbufp = (char *) malloc(bufsizel);
  if (TCONV_UNLIKELY(inbufp == NULL)) {
    GENERICLOGGER_ERRORF(NULL, "malloc: %s", strerror(errno));
    goto end;
  }

  if ((filenames == NULL) || (strcmp(filenames, "-") == 0)) {
    fd = fileno(stdin);
  } else {
    fd = open(filenames,
              O_RDONLY
#ifdef O_BINARY
              |O_BINARY
#endif
              );
  }
  if (fd < 0) {
    GENERICLOGGER_ERRORF(NULL, "Failed to open %s: %s", filenames, strerror(errno));
    goto end;
  }

  tconvOption.charsetp = charsetp;
  tconvOption.convertp = convertp;
  tconvOption.traceCallbackp =
#ifndef TCONV_NTRACE
    (verbose != 0) ? traceCallback :
#endif
    NULL;
  tconvOption.traceUserDatavp = NULL;
  tconvOption.fallbacks = fallbacks;
  
#ifndef TCONV_NTRACE
  /* For very early trace */
  putenv("TCONV_ENV_TRACE=1");
#endif

  tconvp = tconv_open_ext(tocodes, fromcodes, &tconvOption);
  if (tconvp == (tconv_t) -1) {
    GENERICLOGGER_ERRORF(NULL, "tconv_open_ext: %s", strerror(errno));
    goto end;
  }

#ifndef TCONV_NTRACE
  if (verbose != 0) {
    tconv_trace_on(tconvp);
  }
#endif

  context.tconvp             = tconvp;
  context.filenames          = filenames;
  context.fd                 = fd;
  context.outputFd           = outputFd;
  context.inbufp             = inbufp;
  context.bufsizel           = bufsizel;
  context.guessb             = guessb;
  context.fromPrintb         = fromPrintb;
  context.firstconsumercallb = 1;
#ifndef TCONV_NTRACE
  context.verbose   = verbose;
#endif

  tconv_helperp = tconv_helper_newp(tconvp, &context, producer, consumer);
  if (tconv_helperp == NULL) {
    goto end;
  }
  
  if (! tconv_helper_runb(tconv_helperp)) {
    GENERICLOGGER_ERRORF(NULL, "%s: %s", filenames, strerror(errno));
  }

 end:
  if (inbufp != NULL) {
    free(inbufp);
  }
  if ((filenames != NULL) && (strcmp(filenames, "-") != 0)) {
    if (fd >= 0) {
      if (close(fd) != 0) {
        GENERICLOGGER_WARNF(NULL, "Failed to close %s: %s", filenames, strerror(errno));
      }
    }
  }
  if (tconv_helperp != NULL) {
    tconv_helper_freev(tconv_helperp);
  }
  if (tconvp != (tconv_t) -1) {
    if (tconv_close(tconvp) != 0) {
      GENERICLOGGER_WARNF(NULL, "Failed to close tconv: %s", strerror(errno));
    }
  }
}
