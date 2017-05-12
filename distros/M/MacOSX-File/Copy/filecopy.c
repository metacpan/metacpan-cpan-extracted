/*
 * $Id: filecopy.c,v 0.70 2005/08/09 15:47:00 dankogai Exp $
 */

#undef I_POLL
#include <Files.h>
#include "common/util.c"

#ifdef _INC_PERL_XSUB_H
static int
setcopyerr(int err, char *filename, int line)
{
    SV *OSerr;
    OSerr = perl_get_sv("MacOSX::File::CopyErr", 1);
    if (err){
        sv_setpvf(OSerr, "err=%d,file=%s,line=%d", err, filename, line);
    }else{
	sv_setiv(OSerr, 0);
    }
    return err;
}
#endif /* _INC_PERL_XSUB_H */

static UniCharCount 
Utf8toUni(UInt8 *src, UniChar *dst){
    UInt32        utf32;
    UInt8         c1, c2, c3, c4;
    UniCharCount  nchar = 0;

    for(; *src != '\0'; src++, nchar++){
	if (*src < 0x80) {     /* 1 byte */
	    utf32 = *src;
	}else if (*src < 0xE0){ /* 2 bytes */
	    c1 = *src++; c2 = *src;
	    utf32 = ((c1 & 0x1F) << 6) | (c2 & 0x3F);
	}else if (*src < 0xF0){                 /* 3 bytes */
	    c1 = *src++; c2 = *src++; c3 = *src;
	    utf32 = ((c1 & 0x0F) << 12) | ((c2 & 0x3F) << 6)| (c3 & 0x3F);
	}else{
	    c1 = *src++; c2 = *src++; c3 = *src++; c4 = *src;
	    utf32 = ((c1 & 0x07) << 16) | 
		((c2 & 0x3F) << 12)| ((c3 & 0x3F) << 6) | (c4 & 0x3F);
	}
	if (utf32 <= 0xffff){
	    *dst++ = (utf32 & 0xffff);
	}else{ /* ensurrogate */
	    *dst++ = ((utf32 - 0x10000) >> 10)   + 0xD800;
	    *dst++ = ((utf32 - 0x10000) & 0x3FF) + 0xDC00;
	    nchar++;
	}
    }
    return nchar;
}

static OSErr 
newfile(char *path, FSRef *FSrefp, FSCatalogInfo *Catp){
    FSRef         parentFS;
    UniCharCount  namelen;
    UniChar       name[256];
    Boolean       isDir = 1;
    OSErr err;

    if (err = FSPathMakeRef(dirname(path), &parentFS, &isDir)){
	return setcopyerr(err, __FILE__, __LINE__);
    }
    if ((namelen = Utf8toUni(colon2slash(basename(path)), name)) == 0){
	return fnfErr;
    }
    
    /* Create the file with same finder info  */
    err =  FSCreateFileUnicode(&parentFS,
			       namelen, name,
			       kFSCatInfoFinderInfo, Catp,
			       FSrefp, NULL);
    if (err == paramErr){
	/* Try reestablishing FSRef; file is created already */
	err == FSPathMakeRef(path, FSrefp, NULL);
    }
    return setcopyerr(err, __FILE__, __LINE__);
}

#define MINCOPYBUFSIZE 4096
static UInt8 MinCopyBuf[MINCOPYBUFSIZE];

typedef struct{
    UInt64  s;
    UInt8  *b;
} copybuf ;

static copybuf CopyBuf = { MINCOPYBUFSIZE, MinCopyBuf };

#ifdef FILECOPY_DEBUG
#define fpf fprintf
#else
static void fpf(FILE *fp, ...){};
#endif

static void
freebuf() {
    if(CopyBuf.b != MinCopyBuf){ 
	fpf(stderr, "free(CopyBuf.b = 0x%x)\n", CopyBuf.b);
	free(CopyBuf.b); 
	CopyBuf.s = MINCOPYBUFSIZE; CopyBuf.b = MinCopyBuf;
    }
}

static UInt64
setbufsiz(UInt64 newsize){
    UInt8 *newb;
    fpf(stderr, "Request %qd: Current %qd\n", newsize, CopyBuf.s);
    if (CopyBuf.s < newsize){ /* (re|m)alloc only when larger */
	if (CopyBuf.b == MinCopyBuf){ /* first time */
	    if ((newb = (UInt8 *)malloc(newsize)) != NULL){
		fpf(stderr, "malloc ok (0x%x)\n", newb);
		CopyBuf.b = newb; CopyBuf.s = newsize;
	    }else{
		fpf(stderr, "malloc failed! using MinCopyBuf\n");
		CopyBuf.b = MinCopyBuf; CopyBuf.s = MINCOPYBUFSIZE;
	    }
	}else{
	    if ((newb = (UInt8 *)realloc((UInt8 *)CopyBuf.b, newsize))
		!= NULL)
	    {
		fpf(stderr, "realloc ok (0x%x)\n", newb);
		CopyBuf.b = newb;
	    }else{
		fpf(stderr, "remalloc failed! using old value.\n");
	    }
	}
    }
    fpf(stderr, "Buffer size == %qd\n", CopyBuf.s);
    return CopyBuf.s;
}

static OSErr 
copyfork(HFSUniStr255 *forkName, FSRef *src, FSRef *dst){
    OSErr err, eof;
    SInt16 srcfork, dstfork;
    UInt32 bufsize;
    ByteCount nread;
   
    if (err = FSOpenFork(src, forkName->length, forkName->unicode,
			 fsRdPerm, &srcfork)){ 
	fpf(stderr, "Cannot open src. fork\n");
	return setcopyerr(err, __FILE__, __LINE__); 
    }
    if (err = FSOpenFork(dst, forkName->length, forkName->unicode,
			 fsWrPerm, &dstfork)){ 
	fpf(stderr, "Cannot open dst. fork\n");
	FSCloseFork(srcfork); /* src fork is already open ! */
	return setcopyerr(err, __FILE__, __LINE__); 
    }
    while(1){
	eof = FSReadFork(srcfork, fsAtMark, 0, CopyBuf.s, CopyBuf.b, &nread);
	if (err = FSWriteFork(dstfork, fsAtMark, 0, nread, CopyBuf.b, NULL)){
	    goto CLOSE;
	}
	if (eof){ goto CLOSE; }
    }
	
 CLOSE:
    FSCloseFork(srcfork);
    FSCloseFork(dstfork);
    return setcopyerr(err, __FILE__, __LINE__);
}

#define min(x, y) ((x) < y) ? (x) : (y)

static OSErr
filecopy(char *src, char *dst, UInt64 maxbufsize, int preserve){
    OSErr err;
    FSCatalogInfo srcCat, dstCat;
    FSRef srcFS, dstFS;
    HFSUniStr255 forkName;
    UTCDateTime  now;
    
    if (err = FSPathMakeRef(src, &srcFS, NULL)) 
    { return err; }
    
    if (err = FSGetCatalogInfo(&srcFS, kFSCatInfoGettableInfo, &srcCat, 
			       NULL, NULL, NULL))
    { return err; }

    bcopy(&srcCat, &dstCat, sizeof(FSCatalogInfo));

    if (err = newfile(dst, &dstFS, &dstCat)){ 
	fpf(stderr, "Cannot Create File %s\n", dst);
	return err; 
    }
    if (srcCat.dataLogicalSize){
	setbufsiz(min(srcCat.dataPhysicalSize, maxbufsize));
	FSGetDataForkName(&forkName); 
	if (err = copyfork(&forkName, &srcFS, &dstFS))
	{ return err; }
    }
    if (srcCat.rsrcLogicalSize){
	setbufsiz(min(srcCat.rsrcPhysicalSize, maxbufsize));
	FSGetResourceForkName(&forkName);
	if (err = copyfork(&forkName, &srcFS, &dstFS))
	{ return err; }
    }
    freebuf();
    if (preserve){
	err =  FSSetCatalogInfo(&dstFS, kFSCatInfoSettableInfo, &srcCat);
    }
    return err;
}

/*
static OSErr 
filemove(char *src, char *dst){
}
*/

#ifndef _INC_PERL_XSUB_H

int main(int argc, char **argv){
    OSErr         err;
    int preserve = (argc > 3) ? 1 : 0;
    if (argc > 2){
	err = filecopy(argv[1], argv[2], 0, preserve);
	fpf(stderr, "Err = %d, preserve = %d\n", err, preserve);
    }
}

#endif
