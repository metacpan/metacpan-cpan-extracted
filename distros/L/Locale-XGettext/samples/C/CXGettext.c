/*
 * This file is in the public domain.
 * 
 * Extractor example in C.
 * 
 * It should show you all you need to write a typical string extractor in C.
 *
 * It is not a tutorial for writing portable C code.  It may not even 
 * compile on your platform but then you will know how to fix it.
 *
 * It is also not a tutorial for accessing the Perl API.  I know
 * way to little about the Perl API for writing such a tutorial.  In
 * particular, the code could leak memory.
 *
 * Last but not least, this is not a good example for writing C
 * code at all.
 */

 /* "perl.h" was automatically included by Inline::C.  */
#include <stdio.h>
#include <sys/types.h>
#include <limits.h>
#include <math.h>

/*
 * We inevitably have to use glue code between Perl and C here, even
 * if we are using Inline::C.  If you are really interested, read
 * "perldoc perlapi" and "perldoc perlcall" for FMTYEWTK.  But the
 * sample code should contain Cut & Paste templates for everything
 * that you need.  Note that we use stack macros from "INLINE.h" 
 * here that are a little bit more readable. see
 * http://search.cpan.org/~tinita/Inline-C/lib/Inline/C.pod#THE_INLINE_STACK_MACROS
 * for more details!
 *
 * All non-static C functions are in the namespace of the extractor class 
 * and are therefore automatically methods.
 */

/* 
 * Some helper functions and definitions.  Note that static functions are
 * not visible to Perl.
 */

/* One entry for a PO file.  */
struct po_entry {
        const char *msgid;
        const char *msgid_plural;

        /* These two items will be merged into a reference of the
         * form "FILENAME:LINENO"
         */
        const char *filename;
        size_t lineno;

        /* If you set this to non-NULL, Locale::XGettext will add
         * automatic comments for you, if they had been specified
         * on the command-line for that particular keyword. 
         */
        const char *keyword;

        /* Set this to something like "c-format" or "no-c-format"
         * as appropriate.  You can comma-separate multiple flags.
         */
        const char *flags;
         
        /* This is a so-called automatic comment.  Automatic
         * commands are prefixed with "#." in the PO files.
         * The only reason why you want to add them is actually
         * that it had been specified on the command-line with
         * "--add-comment."  But in that case it is actually
         * easier to just specify the keyword and then Locale::XGettext
         * will do that automaticaslly for you, when it is 
         * needed.
         */
        const char *comment;

        /* Add more members here, when you need them.  But in that case
         * you have to add the required code to addEntry() as well!
         */
};

/* The equivalent of Locale::XGettext::Util::Keyword in C.  */
struct keyword {
        /* The name of the function.  */
        const char *function;

        /* Position of singular form.  */
        unsigned int singular;

        /* Position of plural form or 0.  */
        unsigned int plural;

        /* Position of message context argument or 0.  */
        unsigned int context;

        /* Automatic comment for that keyword or NULL.  */
        const char *comment;
};

/* Add ENTRY to the extractor SELF.  COMMENT should point to any
 * source code comment preceding the message but without the
 * comment delimiter of your language.  The string is then parsed
 * by Locale::XGettext, especially for translator comments specified
 * on the command-line with "--add-comment".
 *
 * The method is just a thin wrapper against addEntry() of the 
 * underlying Perl object.
 */
static void addEntry(SV *self, struct po_entry *entry, const char *comment);

/* Initialize a "struct entry".  The argument is not(!) the pointer
 * but the structure.  Why would you need a pointer in the first
 * place?
 */
#define init_po_entry(entry) memset(&entry, 0, sizeof(struct po_entry))

/* Get all valid keyword definitions.  That is the merge of 
 * default keywords and those specified on the command-line.
 * Pass the return value to free_keywords() in order to free
 * all resources again.
 */
static struct keyword **keywords(SV *self);

/* Get the value of a certain option.  */
static SV *option(SV *self, const char *option);

/* Free all resources associated with the set of keywords.  */
static void free_keywords(struct keyword **keywords);

/* Free all resources associated with one keyword.  */
static void free_keyword(struct keyword *keyword);

/* Retreive an unsigned integer from a hash (reference) or 0.
 */
static unsigned int fetch_hash_uvalue(HV *hash, const char *key);

/* Retreive a string from a hash (reference).  The return value
 * is either NULL or the string that should be free()d, when
 * no longer used.
 */
static char *fetch_hash_svalue(HV *hash, const char *key);

/*
 * The most important method.
 */
void 
readFile(SV *self, const char *filename)
{
        FILE *fp = fopen(filename, "r");
        char *line = NULL;
        size_t lineno = 0;
        size_t linecap = 0;
        ssize_t linelen;
        struct po_entry entry;

        if (!fp) {

               croak("Unable to open open '%s': %s", 
                     filename, strerror(errno));
        }

        while ((linelen = getline(&line, &linecap, fp)) > 0) {
                /* Clear the PO entry.  */
                init_po_entry(entry);

                entry.msgid = line;
                entry.filename = filename;
                entry.lineno = ++lineno;

                /* For a real language you should also set the keyword
                 * for this entry.
                 */
                entry.keyword = "greet";
                entry.flags = "no-perl-format, c-format";

                /* In our case we don't have a comment and pass NULL
                 * as the third argument.  
                 */
                addEntry(self, &entry, NULL);
        }
}

/* All of the following methods are optional.  You do not have to
 * implement them.  
 */

/* This method gets called right after all input files have been
 * processed and before the PO entries are sorted.  That means that you
 * can add more entries here.
 *
 * In this example we don't add any strings here but rather abuse the
 * method for showing advanced stuff like getting option values or
 * interpreting keywords.  Invoke the extractor with the option
 * "--test-binding" in order to see this in action.  
 */
void
extractFromNonFiles(SV *self)
{
        struct keyword **records;
        struct keyword **crs;
        struct keyword *keyword;

        if (!SvTRUE(option(self, "test_binding")))
               return;

        puts("Keyword as command-line-options:");

        records = crs = keywords(self);

        while (*crs) {
                keyword = *crs;
                printf("function: %s\n", keyword->function);

                if (keyword->context)
                        printf("  context: argument #%u\n", keyword->context);
                else
                        puts("  context: [none]");

                if (keyword->singular)
                        printf("  singular: argument #%u\n", keyword->singular);
                else
                        puts("  singular: [none]");

                if (keyword->plural)
                        printf("  plural: argument #%u\n", keyword->plural);
                else
                        puts("  plural: [none]");

                if (keyword->comment)
                        printf("  automatic comment %s\n", keyword->comment);
                else
                        puts("  automatic comment: [none]");

                ++crs;
        }

        free_keywords(records);
        
        /* Extracting the valid flags is left as an exercise to
         * the reader.  File a bug report if you cannot find yourself
         * how to do it.
         */
}

/* Describe the type of input files.  */
char *
fileInformation(SV *self)
{
    /* For simple types like this, the return value is automatically
     * converted.  No need to use the Perl API.
     */
    return "\
Input files are plain text files and are converted into one PO entry\n\
for every non-empty line.";
}

/* Return an array with the default keywords.  This is only used if the
 * method canKeywords() (see below) returns a truth value.  For the lines
 * extractor you would rather NULL or an empty array.
 */
SV *
defaultKeywords(SV *self)
{
        AV *keywords = newAV();

        av_push(keywords, newSVpv("gettext:1", 9));
        av_push(keywords, newSVpv("ngettext:1,2", 12));
        av_push(keywords, newSVpv("pgettext:1c,2", 13));
        av_push(keywords, newSVpv("npgettext:1c,2,3", 16));

        return newRV_noinc((SV *) keywords);

}

/*
 * You can add more language specific options here.  It is your
 * responsibility that the option names do not conflict with those of the
 * wrapper.
 *
 * This method should actually return an array of arrays.  But we
 * can also just return a flat list, that gets then promoted by the
 * Perl code.  When returning multiple or complex values it is best
 * to return them on the Perl stack.
 */
void 
languageSpecificOptions(SV *self) 
{
    Inline_Stack_Vars;

    Inline_Stack_Reset;

    Inline_Stack_Push(sv_2mortal(newSVpv("test-binding", 0)));
    Inline_Stack_Push(sv_2mortal(newSVpv("test_binding", 0)));
    Inline_Stack_Push(sv_2mortal(newSVpv("    --test-binding", 0)));
    Inline_Stack_Push(sv_2mortal(newSVpv("print additional information for testing the language binding", 0)));

    /* Add more groups of 4 items for more options.  */

    Inline_Stack_Done;
}

/* Does the program honor the option -a, --extract-all?  The default
 * implementation returns false.
 */
int
canExtractAll(SV *self)
{
        return 0;
}

/* Does the program honor the option -k, --keyword?  The default
 * implementation returns true.
 */
int 
canKeywords(SV *self)
{
        return 1;
}

/* Does the program honor the option --flag?  The default
 * implementation returns true.
 */
int
canFlags(SV *self)
{
        return 1;
}

static void
addEntry(SV *self, struct po_entry *entry, const char *comment)
{
        /* When calling a Perl method we have to use the regular
         * macros from the Perl API, not the Inline stack
         * macros.
         */
        dSP; /* Declares a local copy of the Perl stack.  */
        size_t reflen;
        char *reference = NULL;
        size_t num_items;
                 
        /* We have to call the method "addEntry().  For that we
         * have to push the instance (variable "self") on the
         * Perl stack followed by all the arguments.  
         *
         * The method has to alternative calling conventions.
         * We pick the simpler one, where we pass key-value
         * pairs, followed by one optional comment.
         */

        /* Boilerplate Perl API code.  */
        ENTER;
        SAVETMPS;
                 
        PUSHMARK(SP);
                 
        /* Make space for all items on the stack.  */
        num_items = 3;  /* The instance plus 2 for the msgid.  */
        if (entry->msgid_plural) num_items += 2;
        if (entry->filename) num_items += 2;
        if (entry->keyword) num_items += 2;
        if (entry->flags) num_items += 2;
        if (entry->comment) num_items += 2;
        if (comment) num_items += 1;

        EXTEND(SP, num_items);
                 
        /* The first item on the stack must be the instance
         * that the method is called upon.
         */
        PUSHs(self);
                 
        /* The second argument to newSVpv is the length of the
         * string.  If you pass 0 then the length is calculated
         * using strlen().
         */
        PUSHs(sv_2mortal(newSVpv("msgid", 5)));
        PUSHs(sv_2mortal(newSVpv(entry->msgid, 0)));

        if (entry->msgid_plural) {
                PUSHs(sv_2mortal(newSVpv("msgid_plural", 5)));
                PUSHs(sv_2mortal(newSVpv(entry->msgid_plural, 0)));        
        }

        if (entry->filename) {
                reflen = strlen(entry->filename) + 3 + (size_t) floor(log10(UINT_MAX));
                reference = malloc(reflen);
                if (!reference) croak("virtual memory exhausted");
                snprintf(reference, reflen, "%s:%lu", entry->filename, 
                         (unsigned long) entry->lineno);
                PUSHs(sv_2mortal(newSVpv("reference", 9)));
                PUSHs(sv_2mortal(newSVpv(reference, 0)));
        }

        if (entry->keyword) {
                PUSHs(sv_2mortal(newSVpv("keyword", 7)));
                PUSHs(sv_2mortal(newSVpv(entry->keyword, 0)));        
        }

        if (entry->flags) {
                PUSHs(sv_2mortal(newSVpv("flags", 5)));
                PUSHs(sv_2mortal(newSVpv(entry->flags, 0)));        
        }

        if (entry->comment) {
                PUSHs(sv_2mortal(newSVpv("comment", 7)));
                PUSHs(sv_2mortal(newSVpv(entry->comment, 0)));
        }

        if (comment) {
                PUSHs(sv_2mortal(newSVpv(comment, 0)));
        }
        
        /* More Perl stuff.  */
        PUTBACK;
                 
        call_method("addEntry", G_DISCARD);
        
        /* Closing bracket for Perl calling.  */
        FREETMPS;
        LEAVE;
        /* Done calling the Perl method.  */
 
        if (reference) free(reference);        
}

static struct keyword **
keywords(SV *self)
{
        SV *records;
        HV *keyword_hash;
        HE *entry;
        int num_keywords, i;
        SV *sv_key;
        SV *sv_val;
        struct keyword **retval;
        struct keyword *keyword;
        SV **keyword_entry;
        HV *hv;
        dSP;
        int count;
        
        /* First call the method keywords() to get a hash 
         * with all valid keyword definitions.
         */
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        EXTEND(SP, 1);

        PUSHs(self);
        PUTBACK;

        count = call_method("keywords", G_SCALAR);

        SPAGAIN;

        if (count != 1)
                croak("option() returned %d values.\n", count);

        records = newSVsv(POPs);

        PUTBACK;
        FREETMPS;
        LEAVE;

        if (!SvROK(records))
                croak("keywords is not a reference");

        keyword_hash = (HV*)SvRV(records);
        num_keywords = hv_iterinit(keyword_hash);

        size_t size = sizeof(struct keyword *);
        retval = calloc(sizeof(struct keyword *), 1 + num_keywords);
        if (!retval)
                croak("virtual memory exhausted");
                
        for (i = 0; i < num_keywords; ++i) {
                keyword = retval[i] = malloc(sizeof *keyword);
                if (!keyword)
                        croak("virtual memory exhausted");

                entry = hv_iternext(keyword_hash);
                sv_key = hv_iterkeysv(entry);

                keyword->function = strdup(SvPV(sv_key, PL_na));
                if (!keyword->function)
                        croak("virtual memory exhausted");
                
                /* The values are objects of type Locale::XGettext::Util::Keyword.
                 * These objects have getter methods but for simplicity we
                 * access the members directly.  First we retrieve the value and
                 * convert it into a new hash.
                 */
                sv_val = hv_iterval(keyword_hash, entry);
                if (!SvROK(sv_val) || SvTYPE(SvRV(sv_val)) != SVt_PVHV)
                        croak("entry for keyword is not a hash reference");

                hv = (HV*) SvRV(sv_val);

                keyword->singular = fetch_hash_uvalue(hv, "singular");
                keyword->plural = fetch_hash_uvalue(hv, "plural");
                keyword->context = fetch_hash_uvalue(hv, "context");
                keyword->comment = fetch_hash_svalue(hv, "comment");
        }
        retval[num_keywords] = (struct keyword *) NULL;

        return retval;
}

/* Get the value of a certain option.  Note that the return value can be
 * just about anything!
 */
static SV *
option(SV *self, const char *option)
{
        dSP;
        int count;
        SV *retval;

        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        EXTEND(SP, 2);

        PUSHs(self);
        PUSHs(sv_2mortal(newSVpv(option, 0)));
        PUTBACK;

        count = call_method("option", G_SCALAR);

        SPAGAIN;

        if (count != 1)
                croak("option() returned %d values.\n", count);

        retval = newSVsv(POPs);

        PUTBACK;
        FREETMPS;
        LEAVE;

        return retval;
}

static void
free_keywords(struct keyword **keywords)
{
        struct keyword **current = keywords;

        while (*current) {
                free_keyword(*current);
                ++current;
        }

        if (keywords)
                free((void *) keywords);
}

static void
free_keyword(struct keyword *self)
{
        if (!self)
                return;
        
        if (self->function)
                free((void *) self->function);

        if (self->comment)
                free((void *) self->comment);
        
        free((void *) self);
}

static unsigned int
fetch_hash_uvalue(HV *hv, const char *key)
{
        SV **value = hv_fetch(hv, key, strlen(key), 0);

        if (!value)
                return 0;
        
        return SvUV(*value);
}


static char *
fetch_hash_svalue(HV *hv, const char *key)
{
        SV **value = hv_fetch(hv, key, strlen(key), 0);
        char *retval;

        if (!value)
                return 0;
        
        retval = strdup(SvPV_nolen(*value));
        if (!retval)
                croak("virtual memory exhausted");
        
        return retval;
}
