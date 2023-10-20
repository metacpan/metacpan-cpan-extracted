
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <ctype.h>

#define TRACE_INTERNAL  7  /* synchronize this with the %trace_levels */
#define NO_TRACE        6  /*   in Mail::Reporter                     */
#define TRACE_ERRORS    5
#define TRACE_WARNINGS  4
#define TRACE_PROGRESS  3
#define TRACE_NOTICES   2
#define TRACE_DEBUG     1

/* [3.007] Although the rfc5322 spec says max 1000, we do permit a larger
 * header-line for "robustness"
 */

#ifndef DFLT_LINE
#define DFLT_LINE       1024
#endif

#ifndef NULL
#define NULL
#endif

#ifndef EOL
#define EOL  '\0'
#endif

#ifndef CR
#define CR   '\015'
#endif

#ifndef LF
#define LF   '\012'
#endif

#define MAX_FOLD       512
#define FOLDSTART      " "
#define COPYSIZE       4096

typedef struct separator
{   char             * line;
    int                length;
    struct separator * next;
} Separator;

typedef struct
{   char      * filename;
    FILE      * file;
    Separator * separators;

    int         trace;
    int         dosmode;

    int         strip_gt;
    int         keep_line;         /* unget line */

    char      * line;
    int         line_buf_size;
    long        line_start;
} Mailbox;

static Mailbox ** boxes = NULL;
static int nr_boxes     = 0;

/*
 * new_mailbox
 */

Mailbox * new_mailbox(char *filename)
{   Mailbox * box;

    New(0, box, 1, Mailbox);
    box->keep_line    = 0;
    box->strip_gt     = 0;
    box->dosmode      = 1;  /* will be set to 0 if not true */
    box->separators   = NULL;

    /* Copy the filename. */
    New(0, box->filename, strlen(filename)+1, char);
    strcpy(box->filename, filename);

    New(0, box->line, DFLT_LINE, char);
    box->line_buf_size = DFLT_LINE;
    return box;
}

/*
 * take_box_slot
 */

static int take_box_slot(Mailbox *new)
{   int boxnr;

    if(boxes==NULL)
    {   nr_boxes = 10;
        Newz(0, boxes, nr_boxes, Mailbox *);
        boxnr    = 0;
    }
    else
    {   for(boxnr = 0; boxnr < nr_boxes; boxnr++)
            if(boxes[boxnr]==NULL) break;

        if(boxnr >= nr_boxes)
        {   /* Add 10 more slots for MailBoxes. */
            int i;
            Renew(boxes, nr_boxes + 10, Mailbox *);

            for(i=0; i<10; i++)
                 boxes[nr_boxes++] = NULL;
        }
    }

    /*fprintf(stderr, "Occupy slot %d\n", boxnr);*/
    boxes[boxnr] = new;
    return boxnr;
}

/*
 * free_box_slot
 */

static void free_box_slot(int boxnr)
{
    if(boxnr >= 0 && boxnr < nr_boxes)   /* bit careful */
        boxes[boxnr] = NULL;
}

/*
 * get_box
 */

static Mailbox *get_box(int boxnr)
{
    if(boxnr < 0 || boxnr >= nr_boxes) return NULL;
    return boxes[boxnr];
}

/*
 * get_one_line
 */

static char * get_one_line(Mailbox *box)
{
    if(box->keep_line)
    {   box->keep_line = 0;
        return box->line;
    }

    box->line_start = (long)ftell(box->file);
    int bufsize     = box->line_buf_size;
    int bytes       = 0;

    while(1)
    {   if(!fgets(box->line + bytes, bufsize - bytes, box->file))
            break;

        bytes = strlen(box->line);
        if(bytes < bufsize-1 || box->line[bufsize-1]=='\n')
            break;

        /* Extend header line buffer to contain more than DFLT_SIZE
         * chars.  Rfc5322 restricts size to 998 octets, but larger
         * headers are encountered in the wild.
         */
        bufsize = box->line_buf_size *= 2;
        Renew(box->line, bufsize, char);
    }

    if(!bytes)
        return NULL;


    if(box->dosmode)
    {   int len = strlen(box->line);
        if(len >= 2 && box->line[len-2]==CR)
        {   box->line[len-2] = '\n';         /* Remove CR's before LF's      */
            box->line[len-1] = EOL;
        }
        else
        if(len==0 || box->line[len-1]!='\n') /* Last line on Win* may lack   */
        {   box->line[len]   = '\n';         /*   newline.  Add it silently  */
            box->line[len+1] = EOL;
        }
        else box->dosmode = 0;               /* Apparently not dosmode at all*/
    }

    return box->line;
}

/*
 * file_position
 * Give the file-position of the line to be processed.
 */

static long file_position(Mailbox *box)
{   return box->keep_line ? box->line_start : (long)ftell(box->file);
}

/*
 * goto_position
 * Jump to a different place in the file.
 */

static int goto_position(Mailbox *box, long where)
{   box->keep_line = 0;
    return fseek(box->file, where, 0);
}

/*
 * read_header_line
 */

static int read_header_line(Mailbox *box, SV **field, SV **content)
{
    char * line;
    char * reader;
    int    length, field_error;

    line   = get_one_line(box);
    if(line==NULL)    return 0;  /* end of file.          */
    if(line[0]=='\n') return 0;  /* normal end of header. */

    /*
     * Read the header's field.
     */

    for(reader = line; *reader!=':' && *reader!='\n'; reader++)
        ;

    if(*reader=='\n')
    {   fprintf(stderr, "Unexpected end of header (C parser):\n  %s", line);
        box->keep_line = 1;
        return 0;
    }

    field_error = 0;
    for(length=reader-line-1; length >= 0 && isspace(line[length]); --length)
        field_error++;

    if(field_error && box->trace <= TRACE_WARNINGS)
    {   fprintf(stderr, "Blanks stripped after header-fieldname:\n  %s",line);
    }

    *field = newSVpvn(line, length+1);

    /*
     * Now read the content.
     */

    /* skip leading blanks. */
    for(++reader; isspace(*reader); ++reader)
        ;
    *content = newSVpv(reader, 0);

    /*
     * Add folded lines.
     */

    while(1)
    {   line = get_one_line(box);
        if(line==NULL) break;

        if( !isspace(line[0]) || line[0]=='\n')
        {   box->keep_line = 1;
            break;
        }
        sv_catpv(*content, line);
    }

    return 1;
}

/*
 * is_good_end
 * Look if the predicted size of the message may be real.  Real means
 * that after the given location is end-of-file, or some blank lines
 * and then the active separator.
 *
 * This function returns whether this seems the right end.
 */

static int is_good_end(Mailbox *box, long where)
{   char      *line;
    int        found;
    Separator *sep;
    long       old_location;

    sep   = box->separators;
    if(sep==NULL) return 1;       /* no seps, than we have to trust it. */

    old_location   = file_position(box);
    if(where >= 0)
    {   if(goto_position(box, where)!=0)
        {   /* File too short. */
            goto_position(box, old_location);
            return 0;             /* Impossible seek. */
        }
        box->keep_line = 0;       /* carefully destroy unget-line. */
    }

    line = get_one_line(box);     /* find first non-empty line. */
    while(line!=NULL && line[0]=='\n' && line[1]==EOL)
        line = get_one_line(box);

    found = (line==NULL || strncmp(line, sep->line, sep->length)==0);

    goto_position(box, old_location);
    return found;
}

/*
 * skip_empty_lines
 */

static void skip_empty_lines(Mailbox *box)
{   char * line;

    while(1)
    {   line = get_one_line(box);

        if(line==NULL)
            break;

        if(line[0]!='\n')
        {   box->keep_line = 1;
            break;
        }
    }
}

/*
 * read_stripped_lines
 * In dosmode, each line must be stripped from the \r, and
 * when we have the From-line seperator, /^>+From / must be stripped
 * from one >.
 *
 * Reading from a Windows file will translate \r\n into \n.  But it
 * is hard to find-out if this is the case.  However, the Content-Length
 * field count these line-seps both.  That's why the ftell() is asked
 * to provide the real location.
 */

static int is_separator(Separator *sep, char *line)
{  
   if(strncmp(sep->line, line, sep->length)!=0) return 0;

   if(strcmp(sep->line, "From ") !=0) return 1;

   /* From separators shall contain a year in the line */
   while(*line)
   {   if(   (line[0]=='1' || line[0]=='2')
          && isdigit(line[1]) && isdigit(line[2]) && isdigit(line[3])
         ) return 1;

       line++;
   }

   return 0;
}

static char **read_stripped_lines(Mailbox *box,
    int expect_chars, int expect_lines,
    int *nr_chars,    int *nr_lines)
{   char   ** lines      = NULL;
    int       max_lines;
    long      start      = file_position(box);
    int       last_blank = 0;
    long      last_position;

    last_position = start;
    max_lines     = expect_lines >= 0 ? (expect_lines+10) : 1000;

    /*fprintf(stderr, "maxlines %ld\n", (long)max_lines);*/
    New(0, lines, max_lines, char *);
    *nr_lines = 0;
    *nr_chars = 0;

    while(1)
    {   char      *line;
        char      *linecopy;
        Separator *sep;
        int        length;

        if(*nr_lines == expect_lines && is_good_end(box, -1))
            break;

        if(file_position(box)-start == expect_chars && is_good_end(box,-1))
            break;

        line = get_one_line(box);
        if(line==NULL)   /* remove empty line before eof.*/
        {   if(last_blank && box->separators)
            {   Safefree( lines[ --(*nr_lines) ] );
                (*nr_chars)--;
                goto_position(box, last_position);
                last_blank = 0;
            }
            break;
        }

        /*
         * Check for separator
         */

        sep = box->separators;
        while(sep != NULL && !is_separator(sep, line))
            sep = sep->next;

        if(sep!=NULL)
        {   /* Separator found */
            box->keep_line = 1;      /* keep separator line to read later.  */

            if(last_blank)           /* Remove blank line before separator. */
            {   Safefree( lines[ --(*nr_lines) ] );
                (*nr_chars)--;
                goto_position(box, last_position);
                last_blank = 0;
            }

            break;
        }

        /*
         *   >>>>From becomes >>>From
         */

        if(box->strip_gt && line[0]=='>')
        {   char *reader = line;
            while(*reader == '>') reader++;
            if(strncmp(reader, "From ", 5)==0)
               line++;
        }

        /*
         * Store line
         */

        if(*nr_lines >= max_lines)
        {   max_lines = max_lines + max_lines/2;
            lines = Renew(lines, max_lines, char *);
        }

        length           = strlen(line);
        last_blank       = length==1;
        last_position    = box->line_start;

        New(0, linecopy, length+1, char);
        strcpy(linecopy, line);

        lines[*nr_lines] = linecopy;

        (*nr_lines)++;
        *nr_chars       += length;
    }

    return lines;
}

/*
 * scan_stripped_lines
 * Like read_stripped_lines, but then without allocation memory.
 */

static int scan_stripped_lines(Mailbox *box,
    int expect_chars, int expect_lines,
    int *nr_chars,    int *nr_lines)
{   long      start          = file_position(box);
    long      last_position;
    int       last_blank     = 0;

    *nr_lines     = 0;
    *nr_chars     = 0;
    last_position = start;

    while(1)
    {   char      *line;
        Separator *sep;
        int        length;

        if(*nr_lines == expect_lines && is_good_end(box, -1))
            break;

        if(file_position(box)-start == expect_chars && is_good_end(box,-1))
            break;

        line = get_one_line(box);
        if(line==NULL)
        {   /* remove empty line before eof if separator.*/
            if(last_blank && box->separators)
            {   (*nr_lines)--;
                (*nr_chars)--;
                goto_position(box, last_position);
                last_blank = 0;
            }
            break;
        }

        /*
         * Check for separator
         */

        sep = box->separators;
        while(sep != NULL && !is_separator(sep, line))
            sep = sep->next;

        if(sep!=NULL)
        {   /* Separator found */
            box->keep_line = 1;  /* keep separator line to read later  */
            if(last_blank)       /* remove empty line before separator */
            {   (*nr_lines)--;
                (*nr_chars)--;
                goto_position(box, last_position);
                last_blank = 0;
            }
            break;
        }

        /*
         *   >>>>From becomes >>>From
         */

        if(box->strip_gt && line[0]=='>')
        {   char *reader = line;
            while(*reader == '>') reader++;
            if(strncmp(reader, "From ", 5)==0)
               line++;
        }

        /*
         * Count
         */

        (*nr_lines)++;
        length        = strlen(line);
        *nr_chars    += length;
        last_blank    = length==1;
        last_position = box->line_start;
    }

/**hier**/
/*fprintf(stderr, "Scanning done\n");*/
    return 1;
}

/*
 * take_scalar
 * Take a block of file-data into one scalar, as efficient as possible.
 */

static SV* take_scalar(Mailbox *box, long begin, long end)
{
    char     buffer[COPYSIZE];
    size_t   tocopy = end - begin;
    size_t   bytes  = 1;
    SV      *result = newSVpv("", 0);

    /* pre-grow the scalar, so Perl doesn't need to re-alloc */
    SvGROW(result, tocopy);

    goto_position(box, begin);
    while(tocopy > 0 && bytes > 0)
    {   int take = tocopy < COPYSIZE ? tocopy : COPYSIZE;
        bytes    = fread(buffer, take, 1, box->file);
        sv_catpvn(result, buffer, bytes);
        tocopy  -= bytes;
    }

    return result;
}

/***
 *** HERE XS STARTS
 ***/

MODULE = Mail::Box::Parser::C PACKAGE = Mail::Box::Parser::C  PREFIX = MBPC_

PROTOTYPES: ENABLE

#
# open_filename
#

int
MBPC_open_filename(char *name, char *mode, int trace)

  PREINIT:
    Mailbox * box;
    int       boxnr;
    FILE    * file;

  CODE:

    /* Open the file. */
    file = fopen(name, mode);
    if(file==NULL)
    {   /*fprintf(stderr, "Unable to open file %s for %s.\n", name, mode);*/
        XSRETURN_UNDEF;
    }

    box       = new_mailbox(name);
    box->file = file;

    boxnr     = take_box_slot(box);

    /*fprintf(stderr, "Open is done.\n");*/
    RETVAL    = boxnr;

  OUTPUT:
    RETVAL

#
# open_filehandle
#

int
MBPC_open_filehandle(FILE *fh, char *name, int trace)

  PREINIT:
    Mailbox * box;
    int       boxnr;

  CODE:
    box       = new_mailbox(name);
    box->file = fh;

    boxnr     = take_box_slot(box);

    /*fprintf(stderr, "Open with filehande is done.\n");*/
    RETVAL    = boxnr;

  OUTPUT:
    RETVAL


#
# close_file
#

void
MBPC_close_file(int boxnr)

  PREINIT:
    Mailbox   * box;
    Separator * sep;

  CODE:
    box  = get_box(boxnr);
    if(box==NULL) return;

    free_box_slot(boxnr);

    if(box->file != NULL)
    {   fclose(box->file);
        box->file = NULL;
    }

    sep = box->separators;
    while(sep!=NULL)
    {   Separator * next = sep->next;
        Safefree(sep->line);
        Safefree(sep);
        sep = next;
    }

    Safefree(box->filename);
    Safefree(box);


#
# push_separator
#

void
MBPC_push_separator(int boxnr, char *line_start)

  PREINIT:
    Mailbox *box;
    Separator  *sep;

  PPCODE:
    box  = get_box(boxnr);
    if(box==NULL) return;

    /*fprintf(stderr, "separator %s\n", line_start);*/
    New(0, sep, 1, Separator);
    sep->length     = strlen(line_start);

    /*fprintf(stderr, "separator %ld\n", (long)sep->length+1);*/
    New(0, sep->line, sep->length+1, char);
    strcpy(sep->line, line_start);

    sep->next       = box->separators;
    box->separators = sep;

    if(strncmp(sep->line, "From ", sep->length)==0)
        box->strip_gt++;


#
# pop_separator
#

SV *
MBPC_pop_separator(int boxnr)

  PREINIT:
    Mailbox   *box;
    Separator *old;

  CODE:
    box  = get_box(boxnr);
    if(box==NULL) XSRETURN_UNDEF;

    old = box->separators;
    if(old==NULL) XSRETURN_UNDEF;

    if(strncmp(old->line, "From ", old->length)==0)
        box->strip_gt--;

    /*fprintf(stderr, "pop sep %s\n", old->line);*/
    box->separators = old->next;
    RETVAL = newSVpv(old->line, old->length);

    Safefree(old->line);
    Safefree(old);

  OUTPUT:
    RETVAL


#
# get_position
#

long
MBPC_get_position(int boxnr)

  PREINIT:
    Mailbox *box;

  CODE:
    box  = get_box(boxnr);
    if(box==NULL) RETVAL = 0;
    else          RETVAL = file_position(box);

  OUTPUT:
    RETVAL

#
# set_position
#

int
MBPC_set_position(int boxnr, long where)

  PREINIT:
    Mailbox *box;

  CODE:
    box  = get_box(boxnr);

    if(box==NULL) RETVAL = 0;
    else          RETVAL = goto_position(box, where)==0;

  OUTPUT:
    RETVAL

#
# read_header
# Returns (begin, end, list-of-fields)
# Where
#     begin and end represent file-locations before resp after the header
#     each field is a ref to an array with a name/content pair, representing
#          one line.
#

void
MBPC_read_header(int boxnr)

  PREINIT:
    Mailbox * box;
    SV      * name;
    SV      * content;
    SV      * end;

  PPCODE:
    box = get_box(boxnr);
    if(box==NULL || box->file==NULL) return;

    XPUSHs(sv_2mortal(newSViv((IV)file_position(box))));
    XPUSHs(end = sv_newmortal());

    while(read_header_line(box, &name, &content))
    {   AV * field = newAV();
        av_push(field, name);     /* av_push does not increase refcount */
        av_push(field, content);
        XPUSHs(sv_2mortal(newRV_noinc((SV *)field)));
    }
 
    /*fprintf(stderr, "Header has been read\n");*/
    sv_setiv(end, (IV)file_position(box));

#
# in_dosmode
#

int
MBPC_in_dosmode(int boxnr)

  PREINIT:
    Mailbox *box;

  CODE:
    box   = get_box(boxnr);
    if(box==NULL)
        XSRETURN_UNDEF;

    RETVAL = box->dosmode;

  OUTPUT:
    RETVAL


#
# read_separator
# Return a line with the last defined separator.  Empty lines before this
# are permitted, but no other lines.
#

void
MBPC_read_separator(int boxnr)

  PREINIT:
    Mailbox   *box;
    Separator *sep;
    char      *line;

  PPCODE:
    box  = get_box(boxnr);
    if(box==NULL)
        XSRETURN_EMPTY;

    sep  = box->separators;    /* Never success when there is no sep */
    if(sep==NULL)
        XSRETURN_EMPTY;

    line = get_one_line(box);  /* Get first real line. */
    while(line!=NULL && line[0]=='\n' && line[1]==EOL)
        line = get_one_line(box);

    if(line==NULL)             /* EOF reached. */
        XSRETURN_EMPTY;

    if(strncmp(sep->line, line, sep->length)!=0)
    {   box->keep_line = 1;
        return;
    }

    EXTEND(SP, 2);
    PUSHs(sv_2mortal(newSViv(box->line_start)));
    PUSHs(sv_2mortal(newSVpv(line, strlen(line))));


#
# body_as_string
# Read the whole body into one scalar, and return it.
# When lines need a post-processing, we read line-by-line.  Otherwise
# we can read the block as a whole.
#

void
MBPC_body_as_string(int boxnr, int expect_chars, int expect_lines)

  PREINIT:
    Mailbox *box;
    SV      *result;
    char   **lines;
    int      nr_lines = 0;
    int      nr_chars = 0;
    int      line_nr;
    long     begin;

  PPCODE:
    box  = get_box(boxnr);
    if(box==NULL)
        XSRETURN_EMPTY;

    begin = file_position(box);

    if(!box->dosmode && !box->strip_gt && expect_chars >=0)
    {
        long  end = begin + expect_chars;

        if(is_good_end(box, end))
        {   EXTEND(SP, 3);
            PUSHs(sv_2mortal(newSViv(begin)));
            PUSHs(sv_2mortal(newSViv(file_position(box))));
            PUSHs(sv_2mortal(take_scalar(box, begin, end)));
            XSRETURN(3);
        }
    }

    lines = read_stripped_lines(box, expect_chars, expect_lines,
        &nr_chars, &nr_lines);

    if(lines==NULL)
        XSRETURN_EMPTY;

    /* Join the strings. */
    result = newSVpv("",0);
    SvGROW(result, (unsigned int)nr_chars);

    for(line_nr=0; line_nr<nr_lines; line_nr++)
    {   sv_catpv(result, lines[line_nr]);
        Safefree(lines[line_nr]);
    }

    skip_empty_lines(box);
    Safefree(lines);

    EXTEND(SP, 3);
    PUSHs(sv_2mortal(newSViv(begin)));
    PUSHs(sv_2mortal(newSViv(file_position(box))));
    PUSHs(sv_2mortal(result));


#
# body_as_list
# Read the whole body into a list of scalars.
#

void
MBPC_body_as_list(int boxnr, int expect_chars, int expect_lines)

  PREINIT:
    Mailbox *box;
    char   **lines;
    int      nr_lines = 0;
    int      nr_chars = 0;
    int      line_nr;
    long     begin;
    AV     * results;

  PPCODE:
    box   = get_box(boxnr);
    if(box==NULL)
        XSRETURN_EMPTY;

    begin = file_position(box);
    lines = read_stripped_lines(box, expect_chars, expect_lines,
        &nr_chars, &nr_lines);

    if(lines==NULL) return;

    XPUSHs(sv_2mortal(newSViv(begin)));
    XPUSHs(sv_2mortal(newSViv(file_position(box))));

    /* Allocating the lines for real. */

    results = (AV *)sv_2mortal((SV *)newAV());
    av_extend(results, nr_lines);

    for(line_nr=0; line_nr<nr_lines; line_nr++)
    {   char *line = lines[line_nr];
        av_push(results, newSVpv(line, 0));
        Safefree(line);
    }

    XPUSHs(sv_2mortal(newRV((SV *)results)));

    skip_empty_lines(box);
    Safefree(lines);


#
# body_as_file
# Read the whole body into a file.
#

void
MBPC_body_as_file(int boxnr, FILE *out, int expect_chars, int expect_lines)

  PREINIT:
    Mailbox *box;
    char   **lines;
    int      nr_lines=0;
    int      nr_chars=0;
    int      line_nr;
    long     begin;

  PPCODE:
    box    = get_box(boxnr);
    if(box==NULL)
        XSRETURN_EMPTY;

    begin = file_position(box);
    lines = read_stripped_lines(box, expect_chars, expect_lines,
        &nr_chars, &nr_lines);

    if(lines==NULL)
        XSRETURN_EMPTY;

    EXTEND(SP, 3);
    PUSHs(sv_2mortal(newSViv((IV)begin)));
    PUSHs(sv_2mortal(newSViv((IV)file_position(box))));
    PUSHs(sv_2mortal(newSViv((IV)nr_lines)));

    /* write the lines to file. */

    for(line_nr=0; line_nr<nr_lines; line_nr++)
    {   fprintf(out, "%s", lines[line_nr]);
        Safefree(lines[line_nr]);
    }

    skip_empty_lines(box);
    Safefree(lines);


#
# body_delayed
# Skip the whole body, only counting chars and lines.
#

void
MBPC_body_delayed(int boxnr, int expect_chars, int expect_lines)

  PREINIT:
    Mailbox *box;
    int      nr_lines = 0;
    int      nr_chars = 0;
    long     begin;

  PPCODE:
    box   = get_box(boxnr);
    if(box==NULL)
        XSRETURN_EMPTY;

    begin = file_position(box);

    if(expect_chars >=0)
    {
        long  end    = begin + expect_chars;
        if(is_good_end(box, end))
        {   /*  Accept new end  */
            goto_position(box, end);

            EXTEND(SP, 4);
            PUSHs(sv_2mortal(newSViv((IV)begin)));
            PUSHs(sv_2mortal(newSViv((IV)end)));
            PUSHs(sv_2mortal(newSViv((IV)expect_chars)));
            PUSHs(sv_2mortal(newSViv((IV)expect_lines)));
            skip_empty_lines(box);
            XSRETURN(4);
        }
    }

    if(scan_stripped_lines(box, expect_chars, expect_lines,
        &nr_chars, &nr_lines))
    {   EXTEND(SP, 4);
        PUSHs(sv_2mortal(newSViv((IV)begin)));
        PUSHs(sv_2mortal(newSViv((IV)file_position(box))));
        PUSHs(sv_2mortal(newSViv((IV)nr_chars)));
        PUSHs(sv_2mortal(newSViv((IV)nr_lines)));
        skip_empty_lines(box);
    }

#
# get_filehandle
#

FILE *
MBPC_get_filehandle(int boxnr)

  PREINIT:
    Mailbox * box;

  CODE:
    box       = get_box(boxnr);
    if(box==NULL) XSRETURN_UNDEF;

    RETVAL    = box->file;

  OUTPUT:
    RETVAL

