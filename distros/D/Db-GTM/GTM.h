/* GTM2PERL database interface 
 *
 * Definitions & prototypes
 *
 */

//  --- Begin user modification section ---

// File locations, default environment variable settings
#define _GT_GTMCI_LOC "/usr/local/gtm/xc/calltab.ci"
#define _GT_GTMRTN_LOC "/home/vmacs/rtn-obj(/home/vmacs/rtn-cvs/misc)"
#define _GT_GTMGBL_LOC "/usr/local/vmacs/vpro.gld"

//  ---- End user modification section ----

// Flags to OR together to define how to pack a GVN
#define ZEROLEN_OK 1               // GLVN with final subscript of "" OK
#define NO_WARN 2                  // No verbal warning for errors
#define NO_PREFIX 4                // Don't prepend the usual prefix
#define TIED 8			   // We are a tied hash/scalar
#define IN_TXN 16		   // We are in the middle of a transaction

#define inTxn(x)	(x->flags & IN_TXN)

// #define _GT_VER 44              // Defined in the Makefile
#define _GT_MAX_BLOCKSIZE 32768    // Max block size (max data length)
#define _GT_MAX_GVNLENGTH 255      // Max length of global + subscripts

#if _GT_VER < 50 

// GTM v4.4-003 needs '_GT_NEED_TERMFIX' and '_GT_NEED_SIGFIX'
#define _GT_NEED_TERMFIX 1         // Restore terminal settings when exiting
#define _GT_NEED_SIGFIX 1          // Restore SIGINT handler after invoking GTM
#define _GT_MAX_GVNSIZE 8          // Max length of a global name

#else

// GTM v5.0-FT01 increases global/routine name length to 31 characters 
#define _GT_NEED_TERMFIX 1         // Restore terminal settings when exiting
#define _GT_NEED_SIGFIX 1          // Restore SIGINT handler after invoking GTM
#define _GT_MAX_GVNSIZE 31         // Max length of a global name

#endif



#ifdef _GT_NEED_TERMFIX
/* 
 * Store terminal settings from before GTM was invoked.  This
 * is a hack to get around GT.M v4.4-003's adjustment of term settings
 *
 */
#include <unistd.h>    // for STDIN_FILENO
#include <termios.h>   // for struct termios
struct termios *_GTMterm;
#endif

#ifdef _GT_NEED_SIGFIX
#include <signal.h>
#endif

// linked-list of pointers to the parts of a GTMglobal variable name
// used by; unpackgvn()
typedef struct _cppack  { char *loc; struct _cppack *next; } cppack;
typedef struct _strpack { 
  char *address; unsigned length; unsigned num; unsigned dummy;
} strpack;

// This is the GTM environment object all functions will be associated with
typedef struct _gtmenv  {
  strpack *prefix; unsigned pfx_elem; unsigned pfx_length;
  gtm_status_t last_err; char *errmsg;
  char *xfer_buf; unsigned flags; unsigned gtmEnvId;
} GtmEnv;

unsigned _GTMinvoc; // Set to 1 if GTM has been started

// Given a GT.M error code, print the error message as a warning
// used by; any function interacting with GT.M
static void err_gtm(const GtmEnv *gt);

// Given an array of strings, return a valid MumpsGlobal Variable Name
// char *packgvn(GtmEnv *gtenv,unsigned len,strpack strs[],const unsigned flags);
 int packgvn(GtmEnv *gtenv, unsigned len,strpack strs[],
            const unsigned flags, gtm_string_t *gvn);


// Given a global/local variable, return a list of pointers to it's
// separate elements.  NOTE: this is destructive to the passed-in string
cppack *unpackgvn(const char *gvn);

// De-allocate the strings in a stringpack
static void strpack_clear(strpack *start,unsigned len);

// Destroy a GTM Environment structure and free related buffers
static void gtenv_clear(GtmEnv *dmw);

// Check to see if a string is a canonical number
static unsigned int is_number(char *i);
