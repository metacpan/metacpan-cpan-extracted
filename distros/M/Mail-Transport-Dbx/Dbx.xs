#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "libdbx/libdbx.h"
#include "libdbx/timeconv.h"

#include "const-c.inc"

/* This is not gentlemen-like:
 * But under Win32: (PerlIO*) == (FILE*) */
#ifdef _WIN32
# define PerlIO_exportFILE(f,fl) ((FILE*)(f))
#endif

#define glob_ref(sv) (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVGV)
#define sv_to_file(sv) (PerlIO_exportFILE(IoIFP(sv_2io(sv)), NULL))

#define WARN        fprintf(stderr, "%i\n", __LINE__)
#define WARNi(arg)  fprintf(stderr, "%i: %i\n", __LINE__, arg)

/* We're not thread-safe anyway. :-)
 * But we cannot do without for garbage-collecting. */
int IN_DBX_DESTROY = 0;

struct dbx_email {
    SV          *dbx;		/* Mail::Transport::Dbx object */
    DBXEMAIL    *email;
    char        *header;	/* just the header */
    char        *body;		/* just the body */
};

struct dbx_folder {
    SV          *dbx;		/* Mail::Transport::Dbx object */
    DBXFOLDER   *folder;  
    AV		*fullpath;
};

struct dbx_box {
    DBX		*dbx;
    SV		**subfolders;	/* Mail::Transport::Dbx::Folder objects */
    /* originally used for fullpath() but now obsolete */
/*  int		*indexid;
    int		indexsize;
*/
};

typedef struct dbx_email    DBX_EMAIL;
typedef struct dbx_folder   DBX_FOLDER;
typedef struct dbx_box	    DBX_BOX;

typedef struct {
    char *name;
    int pid;
} folder_info;

/* copied from perl/pp_sys.c */
static char *dayname[] = {
    "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"
};
static char *monname[] = {
    "Jan", "Feb", "Mar", "Apr", "May", "Jun", 
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
};

char * errstr () {
        switch(dbx_errno) {
            /* messages copied from libdbx.h */
            case DBX_NOERROR:
                return "No error";
            case DBX_BADFILE:
                return "Dbx file operation failed (open or close)";
            case DBX_ITEMCOUNT:
                return "Reading of Item Count from dbx file failed";
            case DBX_INDEX_READ:
                return "Reading of Index Pointer from dbx file failed";
            case DBX_INDEX_UNDERREAD:
                return 
                "Number of indexes read from dbx file is less than expected";
            case DBX_INDEX_OVERREAD:
                return
                "Request was made for index reference greater than exists";
            case DBX_INDEXCOUNT:
                return "Index out of range";
            case DBX_DATA_READ:
                return "Reading of data from dbx file failed";
            case DBX_NEWS_ITEM:
                return "Item is a news item not an email";
            default:
                break;
        }
        return "Odd...an unknown error occured";
}

void split_mail (pTHX_ DBX_EMAIL *self) {

    if (self->header)
        return;
    
    else {
        char *ptr;
        int count = 0;

        /* email data not yet loaded */
        if (!self->email->email) 
            (void) dbx_get_email_body(((DBX_BOX*)SvIV((SV*)SvRV(self->dbx)))->dbx, 
                                      self->email);
        
        ptr = self->email->email;
        
        if (dbx_errno == DBX_DATA_READ) {
            /* A message can be there and not be there at the same time!
             * Explanation:
             * newsgroup items can be downloaded partially in OutlookX
             * In this case dbx_get_email_body() will store nothing in
             * self->email->email in which case header and body would be 
             * empty. then dbx_errno is set to DBX_DATA_READ which we
             * don't consider an error here */
            dbx_errno = DBX_NOERROR;
            return;
        }
        if (dbx_errno == DBX_BADFILE)
            croak("dbx panic: file stream disappeared");

        while (ptr+4) {
            /* two newlines is separator */
            if (strnEQ(ptr, "\r\n\r\n", 4)) {
                break;
            }
            count++; ptr++;
        }
        /* +3: +"\r\n\0" */
        self->header = (char*) safemalloc(sizeof(char) * (count+3));
        self->body = (char*) 
            safemalloc(sizeof(char) * (strlen(self->email->email) - count));
        
        strncpy(self->header, self->email->email, count+2);
        self->header[count+2] = '\0';
        /* +4 to ommit the two newlines ("\r\n\r\n") */
        strcpy(self->body, ptr+4);
    }
}
    
int datify (pTHX_ FILETIME *wintime, int method) {
    dSP;
    time_t time = FileTimeToUnixTime(wintime, NULL);
    struct tm *tstruct;
    (void) POPs; /* removing pending object which is in ST(0) */

    if (method == 0)  /* localtime */
        tstruct = localtime(&time);
    else              /* gmtime */
        tstruct = gmtime(&time);
    
    if (GIMME == G_ARRAY) {
        EXTEND(SP, 9);
        PUSHs(sv_2mortal(newSViv(tstruct->tm_sec)));
        PUSHs(sv_2mortal(newSViv(tstruct->tm_min)));
        PUSHs(sv_2mortal(newSViv(tstruct->tm_hour)));
        PUSHs(sv_2mortal(newSViv(tstruct->tm_mday)));
        PUSHs(sv_2mortal(newSViv(tstruct->tm_mon)));
        PUSHs(sv_2mortal(newSViv(tstruct->tm_year)));
        PUSHs(sv_2mortal(newSViv(tstruct->tm_wday)));
        PUSHs(sv_2mortal(newSViv(tstruct->tm_yday)));
        PUSHs(sv_2mortal(newSViv(tstruct->tm_isdst)));
        PUTBACK;
        return 9;
    } else {
        SV *str = newSVpvf("%s %s %2d %02d:%02d:%02d %d",
                  dayname[tstruct->tm_wday],
                  monname[tstruct->tm_mon],
                  tstruct->tm_mday,
                  tstruct->tm_hour,
                  tstruct->tm_min,
                  tstruct->tm_sec,
                  tstruct->tm_year + 1900);                   
        EXTEND(SP, 1);
        PUSHs(sv_2mortal(str));
        PUTBACK;
        return 1;
    }
}

int get_folder (SV *o, int index, SV **sv) {
    DBX_FOLDER *folder;
    DBX_BOX *dbx = (DBX_BOX*)SvIV(SvRV(o));
    DBXFOLDER *ret = (DBXFOLDER*)dbx_get(dbx->dbx, index, 0);
    New(0, folder, 1, DBX_FOLDER);
    folder->dbx = o;
    folder->folder = ret;
    folder->fullpath = Nullav;
    *sv = sv_setref_pv(newSV(0), "Mail::Transport::Dbx::Folder", (void*)folder);
    SvREFCNT_inc(o);
    return ret->id;
}
	
MODULE = Mail::Transport::Dbx PACKAGE = Mail::Transport::Dbx

INCLUDE: const-xs.inc
PROTOTYPES: DISABLED

DBX_BOX *
new (CLASS, dbx)
        char *CLASS;
        SV *dbx;
    PREINIT:
        STRLEN len;
    CODE:
	New(0, RETVAL, 1, DBX_BOX);
	RETVAL->subfolders = NULL;
        if (glob_ref(dbx) && !errno)
            RETVAL->dbx = dbx_open_stream(sv_to_file(dbx));
        else
            RETVAL->dbx = dbx_open(SvPV(dbx, len));

        if (!RETVAL->dbx)
            croak("%s", errstr());

    OUTPUT:
        RETVAL

void
get (self, index)
        SV *self; 
        int index;
    PREINIT:
        void *ret_type;
	DBX_BOX *dbx;
    CODE:
        dbx = (DBX_BOX*)SvIV((SV*)SvRV(self));
        ret_type = dbx_get(dbx->dbx, index, 0);
        if (!ret_type)
            XSRETURN_UNDEF;

	/* objects derived from a DBX struct keep a pointer
	 * to this struct because it is needed later; so
	 * we need to increment the DBX's refcount */
	SvREFCNT_inc(self); 
	if (dbx->dbx->type == DBX_TYPE_EMAIL) {
	    DBX_EMAIL *ret;
	    New(0, ret, 1, DBX_EMAIL);
	    ST(0) = sv_newmortal();
	    ret->dbx = self;
	    ret->email = (DBXEMAIL*) ret_type;
	    ret->header = NULL;
	    ret->body = NULL;
	    sv_setref_pv(ST(0), "Mail::Transport::Dbx::Email", (void*)ret);
	    XSRETURN(1);
	}
	else if (dbx->dbx->type == DBX_TYPE_FOLDER) {
	    if (!dbx->subfolders) {
		int id;
		SV *sv;
		Newz(0, dbx->subfolders, dbx->dbx->indexCount, SV*);
		/* New(0, dbx->indexid, dbx->indexsize = dbx->dbx->indexCount, int); */
		id = get_folder(self, index, &dbx->subfolders[index]);
		/*
		if (id >= dbx->indexsize) {
		    dbx->indexsize = id+1;
		    Renew(dbx->indexid, dbx->indexsize, int);
		}
		dbx->indexid[id] = index;
		*/
		ST(0) = sv_mortalcopy(dbx->subfolders[index]);
	    } else 
		ST(0) = sv_mortalcopy(dbx->subfolders[index]);
	    //SvREFCNT_inc(self);
	    XSRETURN(1);
	}

int 
error (...)
    CODE:
        RETVAL = dbx_errno;
    OUTPUT:
        RETVAL

char*
errstr (...)
    CODE:
        RETVAL = errstr();
    OUTPUT:
        RETVAL

int
msgcount (self)
        DBX_BOX *self;
    CODE:
        RETVAL = self->dbx->indexCount;
    OUTPUT:
        RETVAL

void
emails (object)
        SV *object;
    PREINIT:
        DBX_BOX *self;
    PPCODE:
        self = (DBX_BOX*)SvIV((SV*)SvRV(object));
        if (GIMME_V == G_SCALAR) {
            if (self->dbx->type == DBX_TYPE_EMAIL) 
                XSRETURN_YES;
            else
                XSRETURN_NO;
        }
        if (GIMME_V == G_ARRAY) {
            int i;
            if (self->dbx->type != DBX_TYPE_EMAIL || self->dbx->indexCount == 0)
                XSRETURN_EMPTY;
            for (i = 0; i < self->dbx->indexCount; i++) {
                SV *o = sv_newmortal();
                void *item = dbx_get(self->dbx, i, 0);
                DBX_EMAIL *ret = (DBX_EMAIL*) safemalloc(sizeof(DBX_EMAIL));
                ret->dbx = object;
                ret->email = (DBXEMAIL*) item;
                ret->header = NULL;
                ret->body = NULL;
                SvREFCNT_inc(object);
                o = sv_setref_pv(o, "Mail::Transport::Dbx::Email", (void*)ret);
                XPUSHs(o);
            }
            XSRETURN(i);
        }

void
subfolders (object)
        SV *object;
    PREINIT:
        DBX_BOX *self;
    PPCODE:
        self = (DBX_BOX*)SvIV((SV*)SvRV(object));

        if (GIMME_V == G_SCALAR) { 
            if (self->dbx->type == DBX_TYPE_FOLDER) 
                XSRETURN_YES;
            else
                XSRETURN_NO;
        }

        if (GIMME_V == G_ARRAY) {
            int i;
            if (self->dbx->type != DBX_TYPE_FOLDER || self->dbx->indexCount == 0)
                XSRETURN_EMPTY;
	    if (self->subfolders) {
		EXTEND(SP, self->dbx->indexCount);
		for (i = 0; i < self->dbx->indexCount; i++) {
		    if (!self->subfolders[i]) {
			int id = get_folder(object, i, &self->subfolders[i]);
			/*
			if (id >= self->indexsize) {
			    self->indexsize = id+1;
			    Renew(self->indexid, self->indexsize, int);
			}
			self->indexid[id] = i;
			*/
		    }
		    ST(i) = sv_mortalcopy(self->subfolders[i]);
		    SvREFCNT_inc(object);
		}
		XSRETURN(self->dbx->indexCount);
	    } else {
		EXTEND(SP, self->dbx->indexCount);
		New(0, self->subfolders, self->dbx->indexCount, SV*);
		/* New(0, self->indexid, self->indexsize = self->dbx->indexCount, int); */
		for (i = 0; i < self->dbx->indexCount; i++) {
		    int id = get_folder(object, i, &self->subfolders[i]);
		    /*
		    if (id >= self->indexsize) {
			self->indexsize = id+1;
			Renew(self->indexid, self->indexsize, int);
		    }
		    self->indexid[id] = i;
		    */
		    PUSHs(sv_mortalcopy(self->subfolders[i]));
		    SvREFCNT_inc(object);
		}
		XSRETURN(self->dbx->indexCount);
	    }
        }

void
DESTROY (self)
        DBX_BOX *self;
    PREINIT:
	register int i;
    CODE:
	IN_DBX_DESTROY = 1;
	if (self->subfolders) {
	    for (i = 0; i < self->dbx->indexCount; i++) {
		SvREFCNT_dec(self->subfolders[i]);
	    }
	    Safefree(self->subfolders);
	    /* Safefree(self->indexid); */
	    self->subfolders = NULL;
	}
        dbx_close(self->dbx);
	IN_DBX_DESTROY = 0;
        
MODULE = Mail::Transport::Dbx PACKAGE = Mail::Transport::Dbx::Email

char *
psubject (self)
        DBX_EMAIL *self;
    CODE:
        RETVAL = self->email->psubject;
    OUTPUT:
        RETVAL

char *
subject (self)
        DBX_EMAIL *self;
    CODE:
        RETVAL = self->email->subject;
    OUTPUT:
        RETVAL

char *
as_string (self)
        DBX_EMAIL *self;
    CODE:
        if (!(RETVAL = self->email->email)) {
            (void) dbx_get_email_body(((DBX_BOX*)SvIV((SV*)SvRV(self->dbx)))->dbx, 
                                      self->email);
            if (dbx_errno == DBX_DATA_READ)
                /* see comment in split_mail() */        
                XSRETURN_UNDEF;
            RETVAL = self->email->email;
        }
    OUTPUT:
        RETVAL

char *
header (self)
        DBX_EMAIL *self;
    CODE:
        split_mail(aTHX_ self);
        if (!(RETVAL = self->header))
            XSRETURN_UNDEF;
    OUTPUT:
        RETVAL

char *
body (self)
        DBX_EMAIL *self;
    CODE:
        split_mail(aTHX_ self);
        if (!(RETVAL = self->body))
            XSRETURN_UNDEF;
    OUTPUT:
        RETVAL

char *
msgid (self)
        DBX_EMAIL *self;
    CODE:
        RETVAL = self->email->messageid;
    OUTPUT:
        RETVAL

char *
parents_ids (self)
        DBX_EMAIL *self;
    CODE:
        RETVAL = self->email->parent_message_ids;
    OUTPUT:
        RETVAL

char *
sender_name (self)
        DBX_EMAIL *self;
    CODE:
        RETVAL = self->email->sender_name;
    OUTPUT:
        RETVAL

char *
sender_address (self)
        DBX_EMAIL *self;
    CODE:
        RETVAL = self->email->sender_address;
    OUTPUT:
        RETVAL

char *
recip_name (self)
        DBX_EMAIL *self;
    CODE:
        RETVAL = self->email->recip_name;
    OUTPUT:
        RETVAL

char *
recip_address (self)
        DBX_EMAIL *self;
    CODE:
        RETVAL = self->email->recip_address;
    OUTPUT:
        RETVAL

char *
oe_account_name (self)
        DBX_EMAIL *self;
    CODE:
        RETVAL = self->email->oe_account_name;
    OUTPUT:
        RETVAL

char *
oe_account_num (self)
        DBX_EMAIL *self;
    CODE:
        RETVAL = self->email->oe_account_num;
    OUTPUT:
        RETVAL

char *
fetched_server (self)
        DBX_EMAIL *self;
    CODE:
        RETVAL = self->email->fetched_server;
    OUTPUT:
        RETVAL

void
rcvd_localtime (self)
        DBX_EMAIL *self;
    PPCODE:
        XSRETURN(datify(aTHX_ &(self->email->date), 0));

void
rcvd_gmtime (self)
        DBX_EMAIL *self;
    PPCODE:
        XSRETURN(datify(aTHX_ &(self->email->date), 1));

char *
date_received (self, ...)
        DBX_EMAIL *self;
    PREINIT:
        char *format = "%a %b %e %H:%M:%S %Y";
        STRLEN n_a;
        size_t max_len = 25;
        time_t time;
        struct tm *tstruct;
        char *string;
    CODE:
        if (items > 1)
            format = (char *) SvPV(ST(1), n_a);
        if (items > 2)
            max_len = (int) SvIV(ST(2));   

        time = FileTimeToUnixTime(&(self->email->date), NULL);

        if (items > 3 && SvTRUE(ST(3)))
            tstruct = gmtime(&time);
        else 
            tstruct = localtime(&time);

        string = (char*) safemalloc(sizeof(char) * max_len);
        strftime(string, max_len, format, tstruct);
        RETVAL = string;
    OUTPUT:
        RETVAL

int
is_seen (self)
        DBX_EMAIL *self;
    CODE:
        RETVAL = (self->email->flag & DBX_EMAIL_FLAG_ISSEEN) > 0 ? 1 : 0;
    OUTPUT:
        RETVAL

int
is_email (self)
        DBX_EMAIL *self;
    CODE:
        RETVAL = 1;
    OUTPUT:
        RETVAL

int
is_folder (self)
        DBX_EMAIL *self;
    CODE:
        RETVAL = 0;
    OUTPUT:
        RETVAL

void
DESTROY (self)
        DBX_EMAIL *self;
    CODE:
        if (self->header)
            safefree(self->header);
        if (self->body)
            safefree(self->body);
        
        dbx_free(((DBX_BOX*)SvIV((SV*)SvRV(self->dbx)))->dbx, self->email);
        SvREFCNT_dec(self->dbx);
        self->dbx = NULL;
        safefree(self);
        

MODULE = Mail::Transport::Dbx PACKAGE = Mail::Transport::Dbx::Folder

int
num (self)
        DBX_FOLDER *self;
    CODE:
        RETVAL = self->folder->num;
    OUTPUT:
        RETVAL

int
type (self)
        DBX_FOLDER *self;
    CODE:
        RETVAL = self->folder->type;
    OUTPUT:
        RETVAL

char *
name (self)
        DBX_FOLDER *self;
    CODE:
        RETVAL = self->folder->name;
    OUTPUT:
        RETVAL

char *
file (self)
        DBX_FOLDER *self;
    CODE:
        RETVAL = self->folder->fname;
    OUTPUT:
        RETVAL

int
id (self)
        DBX_FOLDER *self;
    CODE:
        RETVAL = self->folder->id;
    OUTPUT:
        RETVAL

int 
parent_id (self)
        DBX_FOLDER *self;
    CODE:
        RETVAL = self->folder->parentid;
    OUTPUT:
        RETVAL

int
is_email (self)
        DBX_FOLDER *self;
    CODE:
        RETVAL = 0;
    OUTPUT:
        RETVAL

int
is_folder (self)
        DBX_FOLDER *self;
    CODE:
        RETVAL = 1;
    OUTPUT:
        RETVAL
       
DBX_BOX *
dbx (self)
        DBX_FOLDER *self;
    PREINIT:
        char *CLASS = "Mail::Transport::Dbx"; /* used in typemap */
    CODE:
        if (!self->folder->fname)
            XSRETURN_UNDEF;
	New(0, RETVAL, 1, DBX_BOX);
	RETVAL->subfolders = NULL;
        RETVAL->dbx = dbx_open(self->folder->fname);
    OUTPUT:
        RETVAL

SV*
_dbx (self)
	DBX_FOLDER *self;
    CODE:
	RETVAL = self->dbx;
	SvREFCNT_inc(RETVAL);
    OUTPUT:
	RETVAL

# fullparse() below is slower than an equivalent implementation
# in Perl, so we don't use it
#if 0
void
fullpath (self)
	DBX_FOLDER *self;
    PREINIT:
	register int i;
	DBX_BOX *dbx;
	int parent;
	SV *sv;
	AV *av;
	int numret;
    CODE:
	av = self->fullpath;
	if (av)
	    goto done;    

	av = newAV();

	dbx = (DBX_BOX*)SvIV(SvRV(self->dbx));

	if (!dbx->subfolders) {
	    Newz(0, dbx->subfolders, dbx->dbx->indexCount, SV*);
	    New(0, dbx->indexid, dbx->indexsize = dbx->dbx->indexCount, int);
	}
	    
	for (i = 0; i < dbx->dbx->indexCount; i++) {
	    if (!dbx->subfolders[i]) {
		int id = get_folder(self->dbx, i, &(dbx->subfolders[i]));
		if (id >= dbx->indexsize) {
		    dbx->indexsize = id+1;
		    Renew(dbx->indexid, dbx->indexsize, int);
		}
		dbx->indexid[id] = i;
	    }
	}

	parent = self->folder->parentid;
		
	while (1) {
	    SV *sv = dbx->subfolders[dbx->indexid[parent]];
	    DBX_FOLDER *f = (DBX_FOLDER*)SvIV(SvRV(sv));
	    av_push(av, newSVpv(f->folder->name, 0));
	    if (parent == 0)
		break;
	    parent = f->folder->parentid;
	}

    done:
	numret = av_len(av) + 1;
	for (i = 0; i < numret; i++)
	    ST(numret-i-1) = sv_mortalcopy(*av_fetch(av, i, FALSE));
	ST(numret) = sv_2mortal(newSVpv(self->folder->name, 0));
	XSRETURN(numret+1);

#endif

void
_DESTROY (self)
        DBX_FOLDER *self;
    PREINIT:
	DBX_BOX *dbx;
	SV *sv;
    CODE:
	/* we have a sort of circular destruction problem here:
	 * M::T::Dbx::DESTROY triggers M:T::DBX::Folder::DESTROY
	 * which itself decrements DBX_BOX' refcount so
	 * M::T::Dbx::DESTROY is called again which then calls
	 * M::T::DBX::Folder::DESTROY and so on. */
	if (IN_DBX_DESTROY)
	    XSRETURN_UNDEF;

	/* I don't know why I have to do this: 
	 * without this check it will segfault under certain circumstances 
	 * on threaded perls. */
	if ((sv = (SV*)SvRV(self->dbx))) {
	    dbx = (DBX_BOX*)SvIV(sv);
	    dbx_free(dbx->dbx, self->folder);
	}
	
        SvREFCNT_dec(self->dbx);
	if (self->fullpath) {
	    SV *sv;
	    while ((sv = av_pop(self->fullpath)) != &PL_sv_undef)
		SvREFCNT_dec(sv);
	    SvREFCNT_dec(self->fullpath);
	}
        self->dbx = NULL;
        Safefree(self);
	
MODULE = Mail::Transport::Dbx PACKAGE = Mail::Transport::Dbx::folder_info

void
DESTROY (sv)
    SV *sv;
    CODE:
    {
	folder_info *finfo = (folder_info*)SvIV(SvRV(sv));
	Safefree(finfo->name);
	Safefree(finfo);
    }
