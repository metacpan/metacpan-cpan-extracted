/* vim: set sw=8 ts=8 si noet: */

/* written by Guido Socher.
*
* This program is free software; you can redistribute it
* and/or modify it under the same terms as Perl itself.
*/

/* read the following man pages to learn how to use XS and access
* perl from C: 
* perlxs              Perl XS application programming interface
* perlxstut           Perl XS tutorial
* perlguts            Perl internal functions, variables, data structures for
*                     C programmer
* perlcall            Perl calling conventions from C
*/

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#ifdef __cplusplus
}
#endif


/* tags longer than TAGREADER_MAX_TAGLEN produce a warning about
* not terminated tags, must be much smaler than BUFFLEN */
#define TAGREADER_MAX_TAGLEN 300
/* BUFFLEN is the units in which we re-allocate mem, must be much bigger than
* TAGREADER_MAX_TAGLEN */
#define BUFFLEN 6000
#define TAGREADER_TAGTYPELEN 20

typedef struct trstuct{
	char *filename;
	int fileline;
	int tagline; /* file line where the tag starts */
	int charpos; /* character pos in the line */
	int tagcharpos; /* character pos where tag starts */
	int currbuflen;
	PerlIO *fd;
	char tagtype[TAGREADER_TAGTYPELEN + 1];
	char *buffer;
} *HTML__TagReader;

/* WIN32 stuff from: DH <crazyinsomniac at yahoo.com>, 
 * http://testers.cpan.org/ */
#ifdef WIN32                                                                
#define THEINLINE __forceinline                                             
#else                                                                       
#define THEINLINE inline                                                    
#endif       
/* start of a html tag (first char in the tag) */
static THEINLINE int is_start_of_tag(int ch){
	if (ch=='!' || ch=='/' || ch=='?' || isalnum(ch)){
		return(1);
	}
	return(0);
}

MODULE = HTML::TagReader	PACKAGE = HTML::TagReader	PREFIX = tr_	

PROTOTYPES: ENABLE

HTML::TagReader 
tr_new(class, filename)
	SV *class
	SV *filename
CODE:
	int i;
	char *str;
	if (!SvPOKp(filename)){
		croak("ERROR: filename must be a string scalar");
	}    
	/* malloc and zero the struct */
        Newz(0, RETVAL, 1, struct trstuct );
	str=SvPV(filename,i);
	/* malloc */
        New(0, RETVAL->filename, i+1, char );
	strncpy(RETVAL->filename,str,i);
	/* malloc initial buffer */
        New(0, RETVAL->buffer, BUFFLEN+1, char );
	RETVAL->currbuflen=BUFFLEN;
	/* put a zero at the end of the string, perl might not do it */
	*(RETVAL->filename + i )=(char)0;
	RETVAL->fd=PerlIO_open(str,"r");
	if (RETVAL->fd == NULL){
		croak("ERROR: Can not read file \"%s\" ",str);
	}
	RETVAL->charpos=0;
	RETVAL->tagcharpos=0;
	RETVAL->fileline=1;
	RETVAL->tagline=0;
OUTPUT:
	RETVAL

void
DESTROY(self)
	HTML::TagReader self
CODE:
	Safefree(self->filename);
	Safefree(self->buffer);
	PerlIO_close(self->fd);
	Safefree(self);

void
tr_gettag(self,showerrors)
	HTML::TagReader self
	SV *showerrors
PREINIT:
	int bufpos;
	char ch;
	char chn;
	int state;
PPCODE:
        if (! self->fileline){
		croak("Object not initialized");
	}
	/* initialize */
	state=0;
	bufpos=0;
	ch=(char)0;
	chn=(char)0;
	self->tagline=self->fileline;
	/* find the next tag */
	while(state != 3 && (chn=PerlIO_getc(self->fd))!=EOF ){
		self->charpos++;
		if (ch==0){ /* read one more character ahead so we have always 2 */
			ch=chn;
			continue;
		}
		/* we can not run out of mem because TAGREADER_MAX_TAGLEN
		* is much smaller than BUFFLEN */
		if (bufpos > TAGREADER_MAX_TAGLEN){
			if (SvTRUE(showerrors)){
				PerlIO_printf(PerlIO_stderr(),"%s:%d:%d: Warning, tag not terminated or too long.\n",self->filename,self->tagline,self->charpos);
			}
			self->buffer[bufpos]=ch;bufpos++;
			self->buffer[bufpos]=(char)0;bufpos++;
			state=3;
			continue; /* jump out of while */
		}
		if (ch=='\n') {
			self->fileline++;
			self->charpos=0;
		}
		if (ch=='\n'|| ch=='\r' || ch=='\t' || ch==' ') {
			ch=' ';
			if (chn=='\n'|| chn=='\r' || chn=='\t' || chn==' '){
				/* delete mupltiple spaces */
				ch=chn; /* shift next char */
				continue;
			}
		}
		switch (state) {
		/*---*/
			case 0:
			/* outside of tag and we start tag here*/
			if (ch=='<') {
				if (is_start_of_tag(chn)) {
					self->buffer[0]=(char)0;
					bufpos=0;
					self->tagcharpos=self->charpos;
					/*line where tag starts*/
					self->tagline=self->fileline;
					self->buffer[bufpos]=ch;bufpos++;
					state=1;
				}else{
					if (SvTRUE(showerrors)){
						PerlIO_printf(PerlIO_stderr(),"%s:%d:%d: Warning, single \'<\' should be written as &lt;\n",self->filename,self->fileline,self->charpos);
					}
				}
			}
			break;
		/*---*/
			case 1:
			self->buffer[bufpos]=ch;bufpos++;
			if (ch=='!' && chn=='-' && self->buffer[bufpos-2]=='<'){
				/* start of comment handling */
				state=30; 
			}
			if (ch=='>'){
				state=3; /* note the exit state is hardcoded
				          * as well in the while loop above */
				self->buffer[bufpos]=(char)0;bufpos++;
			}
			if(ch=='<'){
				/* the tag that we were reading was not terminated but instead we ge a new opening */
				if (SvTRUE(showerrors)){
					PerlIO_printf(PerlIO_stderr(),"%s:%d:%d: Warning, \'>\' inside a tag should be written as &gt;\n",self->filename,self->tagline,self->charpos);
				}
				state=1;
				bufpos=0;
				self->buffer[bufpos]=ch;bufpos++;
				self->tagline=self->fileline;
			}
			break;
		/*---*/
			case 30: /*comment handling,
				*we have found "<!--", wait for
				*comment termination with "->" */
				if(ch=='-' && chn=='>'){
					/* done reading this comment tag 
					* just get the closing '>'*/
					state=31;
				}
			break;
		/*---*/
			case 31: 
				/* done reading this comment tag */
				state=0;
				self->buffer[0]=(char)0; /* zero buffer*/
				bufpos=0;
			break;
		/*---*/
			default:
				PerlIO_printf(PerlIO_stderr(),"%s:%d: Programm Error, state = %d\n",self->filename,self->fileline,state);
				exit(1);
		}
		/* shift this and next char */
		ch=chn;
	}
	/* put back chn for the next round */
	self->charpos--;
	if (chn!=EOF && PerlIO_ungetc(self->fd,chn)==EOF){
		PerlIO_printf(PerlIO_stderr(),"%s:%d: ERROR, TagReader library can not ungetc \"%c\" before returning\n",self->filename,self->fileline,chn);
		exit(1);
	}
	/* buffer was already terminated above */
	if (state == 3){
		/* we have found a tag */
		if(GIMME == G_ARRAY){
			EXTEND(SP,3);
			XST_mPV(0,self->buffer);
			XST_mIV(1,self->tagline);
			XST_mIV(2,self->tagcharpos);
			XSRETURN(3);
		}else{
			EXTEND(SP,1);
			XST_mPV(0,self->buffer);
			XSRETURN(1);
		}
	}else{
		/* we are at the end of the file and no tag was found 
		 * return an empty list or string such that the user 
		 * will probably call destroy.
		 */
		 XSRETURN_EMPTY;
	}

void
tr_getbytoken(self,showerrors)
	HTML::TagReader self
	SV *showerrors
PREINIT:
	int bufpos;
	char ch;
	char chn; /* next character */
	int typepos;
	int typeposdone;
	int state;
PPCODE:
        if (! self->fileline){
		croak("Object not initialized");
	}
	/* initialize */
	state=0;
	bufpos=0;
	typeposdone=0;
	typepos=0;
	self->buffer[bufpos]=(char)0;
	self->tagline=self->fileline;
	self->tagtype[typepos]=(char)0;
	ch=(char)0;chn=(char)0;
	/* find the next tag */
	while(state != 3 && (chn=PerlIO_getc(self->fd))!=EOF ){
		self->charpos++;
		if (ch==0){ /* read one more character ahead so we have always 2 */
			ch=chn;
			continue;
		}
		if (ch=='\n') {
			self->fileline++;
			self->charpos=0;
		}
		//printf("DBG ch%c chn%c state%d\n",ch ,chn,state);
		self->buffer[bufpos]=ch;bufpos++;
		switch (state) {
		/*---*/
			case 0:
			self->tagcharpos=self->charpos;
			if (ch=='<'){
				if ( is_start_of_tag(chn)) { 
					state=1; /* we will be reading a tag */
				}else{
					state=2; /* we will be reading a text/paragraph */
					if (SvTRUE(showerrors)){
						PerlIO_printf(PerlIO_stderr(),"%s:%d:%d: Warning, single \'<\' should be written as &lt;\n",self->filename,self->fileline,self->charpos);
					}
				}
			}else{
				state=2; /* we will be reading a text/paragraph */
			}
			break;
		/*---*/
			case 1:
			/* inside a tag. Wait for '>' */
			if (typeposdone==0 && typepos < TAGREADER_TAGTYPELEN -1 ){ 
				if (is_start_of_tag(ch)){
					self->tagtype[typepos]=tolower(ch);typepos++;
				}else{
					/* end of tag type e.g "<a " -> save only "a" in 
					*  tagtype array */
					self->tagtype[typepos]=(char)0;
					typeposdone=1; /* mark end */
				}
			}
			if (ch=='<' && SvTRUE(showerrors)) {
				PerlIO_printf(PerlIO_stderr(),"%s:%d: Warning, single \'<\' or tag starting at line %d not terminated\n",self->filename,self->fileline,self->tagline);
			}
			if (SvTRUE(showerrors) && bufpos > TAGREADER_MAX_TAGLEN){
				PerlIO_printf(PerlIO_stderr(),"%s:%d: Warning, tag not terminated or too long.\n",self->filename,self->tagline);
				state=3;
			}
			if (ch=='>') {
				/* done reading this tag */
				state=3;
			}
			if (ch=='!' && chn=='-' && bufpos > 1 && self->buffer[bufpos-2]=='<'){
				/* start of comment handling */
				state=30; 
				/* some comments are <!-----, but we want always
				* the same tagtype for all comments: */
				strcpy(&(self->tagtype[0]),"!--");
				typepos=3;
			}
			break;
		/*---*/
			case 2:
			/* inside a text. Wait for start of tag */
			if (ch=='>') {
				if (SvTRUE(showerrors)){
					PerlIO_printf(PerlIO_stderr(),"%s:%d:%d: Warning, single \'>\' should be written as &gt;\n",self->filename,self->fileline,self->charpos);
				}
			}
			if (ch=='<'){
				if ( is_start_of_tag(chn)) { /* first char */
					/* put the start of tag back, we want to
					* return only the text part */
					self->charpos--;
					if (PerlIO_ungetc(self->fd,chn)==EOF){
						PerlIO_printf(PerlIO_stderr(),"%s:%d: ERROR, TagReader library can not ungetc \"%c\"\n",self->filename,self->fileline,chn);
						exit(1);
					}
					chn=ch;
					bufpos--;
					state=3;
				}else{
					state=2; /* we will be reading a text/paragraph */
					if (SvTRUE(showerrors)){
						PerlIO_printf(PerlIO_stderr(),"%s:%d:%d: Warning, single \'<\' should be written as &lt;\n",self->filename,self->fileline,self->charpos);
					}
				}
			}
			break;
		/*---*/
			case 30: /*comment handling,
				*we have found "<!--", wait for
				*comment termination with "->" */
				if(ch=='-' && chn=='>'){
					/* done reading this comment tag 
					* just get the closing '>'*/
					state=31;
				}
			break;
		/*---*/
			case 31: 
				/* done reading this comment tag */
				state=3;
			break;
		/*---*/
			default:
				PerlIO_printf(PerlIO_stderr(),"%s:%d: Programm Error, state = %d\n",self->filename,self->fileline,state);
				exit(1);
		}
		/* shift this and next char */
		ch=chn;
		if (bufpos > self->currbuflen - 3){
			/* we need more memory */
			Renew(self->buffer, self->currbuflen + BUFFLEN + 1, char );
			self->currbuflen+=BUFFLEN;
		}
	} /* end of while */
	if (chn==EOF){
		/* put the last char (ch) in the buffer */
		if (ch) {
			self->buffer[bufpos]=ch;bufpos++;
		}
	}else{
		/* put back chn for the next round */
		self->charpos--;
		if (PerlIO_ungetc(self->fd,chn)==EOF){
			PerlIO_printf(PerlIO_stderr(),"%s:%d: ERROR, TagReader library can not ungetc \"%c\" before returning\n",self->filename,self->fileline,chn);
			exit(1);
		}
	}
	/* terminate buffer*/
	self->buffer[bufpos]=(char)0; 
	self->tagtype[typepos]=(char)0;
	/* state == 3 is here or eof */
	if (bufpos>0){
		/* we have a tag or text and we return it */
		if(GIMME == G_ARRAY){
			EXTEND(SP,4);
			XST_mPV(0,self->buffer);
			XST_mPV(1,self->tagtype);
			XST_mIV(2,self->tagline);
			XST_mIV(3,self->tagcharpos);
			XSRETURN(4);
		}else{
			EXTEND(SP,1);
			XST_mPV(0,self->buffer);
			XSRETURN(1);
		}
	}else{
		/* we are at the end of the file and no tag was found 
		 * return an empty list or string such that the user 
		 * will probably call destroy.
		 */
		 XSRETURN_EMPTY;
	}

	/* end of file */
