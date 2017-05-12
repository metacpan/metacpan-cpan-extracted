/*
 * reimplementation of Daniel Bernstein's buffer library.
 * placed in the public domain by Uwe Ohse, uwe@ohse.de.
 */
#ifndef BUFFER_H
#define BUFFER_H

typedef int (*buffer_op) (int, char *,unsigned int);
typedef struct buffer {
  char *buf;
  unsigned int pos;
  unsigned int len;
  int fd;
  buffer_op op;
} buffer;

#define BUFFER_INIT(op,fd,buf,len) { (buf), 0, (len), (fd), (op) }
#define BUFFER_INSIZE 4096
#define BUFFER_OUTSIZE 4096

extern void buffer_init(buffer *,buffer_op,int fd,char *,unsigned int);
extern int buffer_flush(buffer *);
extern int buffer_put(buffer *,const char *,unsigned int);
extern int buffer_putalign(buffer *,const char *,unsigned int);
extern int buffer_putflush(buffer *,const char *,unsigned int);
extern int buffer_puts(buffer *,const char *);
extern int buffer_putsalign(buffer *,const char *);
extern int buffer_putsflush(buffer *,const char *);

#define buffer_PUTC(s,c) \
  ( ((s)->len != (s)->pos) \
    ? ( (s)->buf[(s)->pos++] = (c), 0 ) \
    : buffer_put((s),&(c),1) \
  )

extern int buffer_get(buffer *,char *,unsigned int);
extern int buffer_bget(buffer *,char *,unsigned int);
extern int buffer_feed(buffer *);

extern char *buffer_peek(buffer *);
extern void buffer_seek(buffer *,unsigned int);

#define buffer_PEEK(b) ( (b)->buf + (b)->len )
#define buffer_SEEK(b,skip) ( ( (b)->pos -= (skip) ) , ( (b)->len += (skip) ) )

#define buffer_GETC(b,ch) \
  ( ((b)->pos > 0) \
    ? ( *(ch) = (b)->buf[(b)->len], buffer_SEEK((b),1), 1 ) \
    : buffer_get((b),(ch),1) \
  )

extern int buffer_copy(buffer *,buffer *);

extern buffer *buffer_0;
extern buffer *buffer_0small;
extern buffer *buffer_1;
extern buffer *buffer_1small;
extern buffer *buffer_2;

#endif
