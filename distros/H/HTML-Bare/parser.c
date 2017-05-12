#include "parser.h"
#include<stdio.h>
#ifdef DARWIN
  #include "stdlib.h"
#endif
#ifdef NOSTRING
  void memset(char *s, int c, int n) {
    char *se = s + n;
    while(s < se)	*s++ = c;
	}
#else
  #include <string.h>
#endif

int dh_memcmp(char *a,char *b,int n) {
  int c = 0;
  while( c < n ) {
    if( *a != *b ) return c+1;
    a++; b++; c++;
  }
  return 0;
}

int dh_memcmp2(char *a,int na,char *b,int nb) {
  int c = 0;
  if( na != nb ) return 0;
  while( c < na ) {
    if( *a != *b ) return c+1;
    a++; b++; c++;
  }
  return 0;
}

struct nodec *new_nodecp( struct nodec *newparent ) {
  static int pos = 0;
  int size = sizeof( struct nodec );
  struct nodec *self = (struct nodec *) malloc( size );
  memset( (char *) self, 0, size );
  self->parent      = newparent;
  self->pos = ++pos;
  return self;
}

struct nodec *new_nodec() {
  int size = sizeof( struct nodec );
  struct nodec *self = (struct nodec *) malloc( size );
  memset( (char *) self, 0, size );
  return self;
}

struct namec *new_namec( struct namec *last, char *name, int namelen ) {
  int size = sizeof( struct namec );
  struct namec *self = (struct namec *) malloc( size );
  //memset( (char *) self, 0, size );
  self->prev = last;
  self->name = name;
  self->namelen = namelen;
  if( last ) self->depth = last->depth + 1;
  else self->name = NULL;
  return self;
}

struct namec *del_namec( struct namec *name ) {
  struct namec *prev = name->prev;
  free( name );
  return prev;
}

void del_nodec( struct nodec *node ) {
  struct nodec *curnode;
  struct attc *curatt;
  struct nodec *next;
  struct attc *nexta;
  curnode = node->firstchild;
  while( curnode ) {
    next = curnode->next;
    del_nodec( curnode );
    if( !next ) break;
    curnode = next;
  }
  curatt = node->firstatt;
  while( curatt ) {
    nexta = curatt->next;
    free( curatt );
    curatt = nexta;
  }
  free( node );
}

struct attc* new_attc( struct nodec *newparent ) {
  int size = sizeof( struct attc );
  struct attc *self = (struct attc *) malloc( size );
  memset( (char *) self, 0, size );
  self->parent  = newparent;
  return self;
}

//#define DEBUG

#define ST_val_1 1
#define ST_val_x 2
#define ST_comment_1dash 3
#define ST_comment_2dash 4
#define ST_comment 5
#define ST_comment_x 6
#define ST_pi 7
#define ST_bang 24
#define ST_cdata 8
#define ST_name_1 9
#define ST_name_x 10
#define ST_name_gap 11
#define ST_att_name1 12
#define ST_att_space 13
#define ST_att_name 14
#define ST_att_nameqs 15
#define ST_att_nameqsdone 16
#define ST_att_eq1 17
#define ST_att_eqx 18
#define ST_att_quot 19
#define ST_att_quots 20
#define ST_att_tick 21
#define ST_ename_1 22
#define ST_ename_x 23

int parserc_parse( struct parserc *self, char *htmlin ) {
    // Variables that represent current 'state'
    struct nodec *root    = NULL;
    char  *tagname        = NULL; int    tagname_len    = 0;
    char  *attname        = NULL; int    attname_len    = 0;
    char  *attval         = NULL; int    attval_len     = 0;
    int    att_has_val    = 0;
    struct nodec *curnode = NULL;
    struct attc  *curatt  = NULL;
    int    last_state     = 0;
    self->rootpos = htmlin;
    // HTML stuff
    struct namec *curname = new_namec( NULL, "", 0 );
    
    // Variables used temporarily during processing
    struct nodec *temp;
    char   *cpos          = &htmlin[0];
    int    res            = 0;
    int    dent;
    register int let;
    
    if( self->last_state ) {
      #ifdef DEBUG
      printf( "Resuming parse in state %i\n", self->last_state );
      #endif
      self->err = 0;
      root = self->rootnode;
      curnode = self->curnode;
      curatt = self->curatt;
      tagname = self->tagname; tagname_len = self->tagname_len;
      attname = self->attname; attname_len = self->attname_len;
      attval = self->attval; attval_len = self->attval_len;
      att_has_val = self->att_has_val;
      switch( self->last_state ) {
        case ST_val_1: goto val_1;
        case ST_val_x: goto val_x;
        case ST_comment_1dash: goto comment_1dash;
        case ST_comment_2dash: goto comment_2dash;
        case ST_comment: goto comment;
        case ST_comment_x: goto comment_x;
        case ST_pi: goto pi;
        case ST_bang: goto bang;
        case ST_cdata: goto cdata;
        case ST_name_1: goto name_1;
        case ST_name_x: goto name_x;
        case ST_name_gap: goto name_gap;
        case ST_att_name1: goto att_name1;
        case ST_att_space: goto att_space;
        case ST_att_name: goto att_name;
        case ST_att_nameqs: goto att_nameqs;
        case ST_att_nameqsdone: goto att_nameqsdone;
        case ST_att_eq1: goto att_eq1;
        case ST_att_eqx: goto att_eqx;
        case ST_att_quot: goto att_quot;
        case ST_att_quots: goto att_quots;
        case ST_att_tick: goto att_tick;
        case ST_ename_1: goto ename_1;
        case ST_ename_x: goto ename_x;
      }
    }
    else {
      self->err = 0;
      curnode = root = self->rootnode = new_nodec();
    }
    
    #ifdef DEBUG
    printf("Entry to C Parser\n");
    #endif
    
    val_1:
      #ifdef DEBUG
      printf("val_1: %c\n", *cpos);
      #endif
      let = *cpos;
      switch( let ) {
        case 0: last_state = ST_val_1; goto done;
        case '<': goto val_x;
      }
      if( !curnode->numvals ) {
        curnode->value = cpos;
        curnode->vallen = 1;
      }
      curnode->numvals++;
      cpos++;
      
    val_x:
      #ifdef DEBUG
      printf("val_x: %c\n", *cpos);
      #endif
      let = *cpos;
      switch( let ) {
        case 0: last_state = ST_val_x; goto done;
        case '<':
          switch( *(cpos+1) ) {
            case '!':
              if( *(cpos+2) == '[' ) { // <![
                //if( !strncmp( cpos+3, "CDATA", 5 ) ) {
                if( *(cpos+3) == 'C' &&
                    *(cpos+4) == 'D' &&
                    *(cpos+5) == 'A' &&
                    *(cpos+6) == 'T' &&
                    *(cpos+7) == 'A'    ) {
                  cpos += 9;
                  curnode->type = 1;
                  goto cdata;
                }
                else {
                  cpos++; cpos++;
                  goto val_x;//actually goto error...
                }
              }
              else if( *(cpos+2) == '-' && // <!--
                *(cpos+3) == '-' ) {
                  cpos += 4;
                  goto comment;
              }
              else {
                cpos++;
                goto bang;
              }
            case '?':
              cpos+=2;
              goto pi;
          }
          tagname_len = 0; // for safety
          cpos++;
          goto name_1;
      }
      if( curnode->numvals == 1 ) curnode->vallen++;
      cpos++;
      goto val_x;
      
    comment_1dash:
      cpos++;
      let = *cpos;
      if( let == '-' ) goto comment_2dash;
      if( !let ) { last_state = ST_comment_1dash; goto done; }
      goto comment_x;
      
    comment_2dash:
      cpos++;
      let = *cpos;
      if( let == '>' ) {
        cpos++;
        goto val_1;
      }
      if( !let ) { last_state = ST_comment_2dash; goto done; }
      goto comment_x;
      
    comment:
      let = *cpos;
      switch( let ) {
        case 0:   last_state = ST_comment; goto done;
        case '-': goto comment_1dash;
      }
      if( !curnode->numcoms ) {
        curnode->comment = cpos;
        curnode->comlen = 1;
      }
      curnode->numcoms++;
      cpos++;
    
    comment_x:
      let = *cpos;
      switch( let ) {
        case 0: last_state = ST_comment_x; goto done;
        case '-': goto comment_1dash;
      }
      if( curnode->numcoms == 1 ) curnode->comlen++;
      cpos++;
      goto comment_x;
      
    pi:
      let = *cpos;
      if( let == '?' && *(cpos+1) == '>' ) {
        cpos += 2;
        goto val_1;
      }
      if( !let ) { last_state = ST_pi; goto done; }
      cpos++;
      goto pi;

    bang:
      let = *cpos;
      if( let == '>' ) {
        cpos++;
        goto val_1;
      }
      if( !let ) { last_state = ST_bang; goto done; }
      cpos++;
      goto bang;
    
    cdata:
      let = *cpos;
      if( !let ) { last_state = ST_cdata; goto done; }
      if( let == ']' && *(cpos+1) == ']' && *(cpos+2) == '>' ) {
        cpos += 3;
        goto val_1;
      }
      if( !curnode->numvals ) {
        curnode->value = cpos;
        curnode->vallen = 0;
        curnode->numvals = 1;
      }
      if( curnode->numvals == 1 ) curnode->vallen++;
      cpos++;
      goto cdata;
      
    name_1:
      #ifdef DEBUG
      printf("name_1: %c\n", *cpos);
      #endif
      let = *cpos;
      switch( let ) {
        case 0: last_state = ST_name_1; goto done;        
        case ' ':
        case 0x0d:
        case 0x0a:
          cpos++;
          goto name_1;
        case '/': // regular closing tag
          tagname_len = 0; // needed to reset
          cpos++;
          goto ename_1;
      }
      tagname       = cpos;
      tagname_len   = 1;
      cpos++;
      goto name_x;
      
    name_x:
      #ifdef DEBUG
      printf("name_x: %c\n", *cpos);
      #endif
      let = *cpos;
      switch( let ) {
        case 0: last_state = ST_name_x; goto done;
        case ' ':
        case 0x0d:
        case 0x0a:
          curnode     = nodec_addchildr( curnode, tagname, tagname_len );
          curname     = new_namec( curname, curnode->name, curnode->namelen );
          attname_len = 0;
          cpos++;
          goto name_gap;
        case '>':
          curnode     = nodec_addchildr( curnode, tagname, tagname_len );
          curname     = new_namec( curname, curnode->name, curnode->namelen );
          cpos++;
          goto val_1;
        case '/': // self closing
          temp = nodec_addchildr( curnode, tagname, tagname_len );
          temp->z = cpos +1 - htmlin;
          tagname_len            = 0;
          cpos+=2;
          goto val_1;
      }
      
      tagname_len++;
      cpos++;
      goto name_x;
          
    name_gap:
      #ifdef DEBUG
      printf("name_gap: %c\n", *cpos);
      #endif
      let = *cpos;
      switch( *cpos ) {
        case 0: last_state = ST_name_gap; goto done;
        case ' ':
        case 0x0d:
        case 0x0a:
          cpos++;
          goto name_gap;
        case '>':
          cpos++;
          goto val_1;
        case '/': // self closing
          curnode->z = cpos+1-htmlin;
          curname = del_namec( curname );
          curnode = curnode->parent;
          if( !curnode ) goto done;
          cpos+=2; // am assuming next char is >
          goto val_1;
        case '=':
          cpos++;
          goto name_gap;//actually goto error
      }
        
    att_name1:
      #ifdef DEBUG
      printf("attname1: %c\n", *cpos);
      #endif
      att_has_val = 0;
      let = *cpos;
      switch( let ) {
        case 0: last_state = ST_att_name1; goto done;
        case 0x27://'
          cpos++;
          attname = cpos;
          attname_len = 0;
          goto att_nameqs;
      }
      attname = cpos;
      attname_len = 1;
      cpos++;
      goto att_name;
      
    att_space:
      let = *cpos;
      switch( let ) {
        case 0: last_state = ST_att_space; goto done;
        case ' ':
        case 0x0d:
        case 0x0a:
          cpos++;
          goto att_space;
        case '=':
          att_has_val = 1;
          cpos++;
          goto att_eq1;
      }
      // we have another attribute name, so continue
      
    att_name:
      #ifdef DEBUG
      printf("attname: %c\n", *cpos);
      #endif
      let = *cpos;
      switch( let ) {
        case 0: last_state = ST_att_name; goto done;
        case '/': // self closing     !! /> is assumed !!
          curatt = nodec_addattr( curnode, attname, attname_len );
          if( !att_has_val ) { curatt->value = -1; curatt->vallen = 0; }
          attname_len            = 0;
          
          curnode->z = cpos+1-htmlin;
          curname = del_namec( curname );
          curnode = curnode->parent;
          if( !curnode ) goto done;
          cpos += 2;
          goto val_1;
        case ' ':
          if( *(cpos+1) == '=' ) {
            cpos++;
            goto att_name;
          }
          curatt = nodec_addattr( curnode, attname, attname_len );
          attname_len = 0;
          cpos++;
          goto att_space;
        case '>':
          curatt = nodec_addattr( curnode, attname, attname_len );
          if( !att_has_val ) { curatt->value = -1; curatt->vallen = 0; }
          attname_len = 0;
          cpos++;
          goto val_1;
        case '=':
          attval_len = 0;
          curatt = nodec_addattr( curnode, attname, attname_len );
          attname_len = 0;
          cpos++;
          goto att_eq1;
      }
      
      if( !attname_len ) attname = cpos;
      attname_len++;
      cpos++;
      goto att_name;
      
    att_nameqs:
      #ifdef DEBUG
      printf("nameqs: %c\n", *cpos);
      #endif
      let = *cpos;
      switch( let ) {
        case 0: last_state = ST_att_nameqs; goto done;
        case 0x27://'
          cpos++;
          goto att_nameqsdone;
      }
      attname_len++;
      cpos++;
      goto att_nameqs;
      
    att_nameqsdone:
      #ifdef DEBUG
      printf("nameqsdone: %c\n", *cpos);
      #endif
      let = *cpos;
      switch( let ) {
        case 0: last_state = ST_att_nameqsdone; goto done;
        case '=':
          attval_len = 0;
          curatt = nodec_addattr( curnode, attname, attname_len );
          attname_len = 0;
          cpos++;
          goto att_eq1;
      }
      goto att_nameqsdone;
      
    att_eq1:
      let = *cpos;
      switch( let ) {
        case 0: last_state = ST_att_eq1; goto done;
        case '/': // self closing
          if( *(cpos+1) == '>' ) {
            curnode->z = cpos+1-htmlin;
            curname = del_namec( curname );
            curnode = curnode->parent;
            if( !curnode ) goto done;
            cpos+=2;
            goto att_eq1;
          }
          break;
        case '"':  cpos++; goto att_quot;
        case 0x27: cpos++; goto att_quots; //'
        case '`':  cpos++; goto att_tick;
        case '>':  cpos++; goto val_1;
        case ' ':  cpos++; goto att_eq1;
      }  
      if( !attval_len ) attval = cpos;
      attval_len++;
      cpos++;
      goto att_eqx;
      
    att_eqx:
      let = *cpos;
      switch( let ) {
        case 0: last_state = ST_att_eqx; goto done;
        case '/': // self closing
          if( *(cpos+1) == '>' ) {
            curnode->z = cpos+1-htmlin;
            curname = del_namec( curname );
            curnode = curnode->parent;
            if( !curnode ) goto done; // bad error condition
            curatt->value = attval;
            curatt->vallen = attval_len;
            attval_len    = 0;
            cpos += 2;
            goto val_1;
          }
          break;
        case '>':
          curatt->value = attval;
          curatt->vallen = attval_len;
          attval_len    = 0;
          cpos++;
          goto val_1;
        case ' ':
          curatt->value = attval;
          curatt->vallen = attval_len;
          attval_len    = 0;
          cpos++;
          goto name_gap;
      }
      
      if( !attval_len ) attval = cpos;
      attval_len++;
      cpos++;
      goto att_eqx;
      
    att_quot:
      let = *cpos;
      
      if( let == '"' ) {
        if( attval_len ) {
          curatt->value = attval;
          curatt->vallen = attval_len;
          attval_len = 0;
        }
        cpos++;
        goto name_gap;
      }
      if( !let ) { last_state = ST_att_quot; goto done; }
      if( !attval_len ) attval = cpos;
      attval_len++;
      cpos++;
      goto att_quot;
      
    att_quots:
      let = *cpos;
      
      if( let == 0x27 ) { // '
        if( attval_len ) {
          curatt->value = attval;
          curatt->vallen = attval_len;
          attval_len = 0;
        }
        cpos++;
        goto name_gap;
      }
      if( !let ) { last_state = ST_att_quots; goto done; }
      
      if( !attval_len ) attval = cpos;
      attval_len++;
      cpos++;
      goto att_quots;
      
    att_tick:
      let = *cpos;
      
      if( let == '`' ) {
        if( attval_len ) {
          curatt->value = attval;
          curatt->vallen = attval_len;
          attval_len = 0;
        }
        cpos++;
        goto name_gap;
      }
      if( !let ) { last_state = ST_att_tick; goto done; }
      
      if( !attval_len ) attval = cpos;
      attval_len++;
      cpos++;
      goto att_tick;
      
    ename_1: // first character of a closing node "</Close>" ( the C )
      let = *cpos;
      if( let == '>' ) {
        curnode->namelen = tagname_len;
        curnode->z = cpos-htmlin;
        curnode = curnode->parent; // jump up
        if( !curnode ) goto done;
        tagname_len++;
        cpos++;
        root->err = -1;
        goto error;
      }
      if( !let ) { last_state = ST_ename_1; goto done; }
      tagname       = cpos;
      tagname_len   = 1;
      cpos++;
      // continue
      
    ename_x: // ending name
      let = *cpos;
      if( let == '>' ) {
        //if( curnode->namelen != tagname_len ) {
        //  goto error;
        //}
        while( curname ) {
            #ifdef DEBUG
            printf("Comparing: curname->name=%.*s to %.*s\n", curname->namelen, curname->name, tagname_len, tagname );
            #endif
            int res = dh_memcmp2( curname->name, curname->namelen, tagname, tagname_len );
            if( res ) { // ending tag does not match tag
                #ifdef DEBUG
                printf("Closing node not equal: curname->name=%.*s - opening tag=%.*s\n", tagname_len, curname->name, tagname_len, tagname );
                #endif
                curname = del_namec( curname );
                curnode = curnode->parent; // jump up
                if( !curnode ) goto done;
            }
            else break;
        }
        /*if( res = dh_memcmp( curnode->name, tagname, tagname_len ) ) {
          #ifdef DEBUG
          printf("Closing node not equal: curnode->name=%.*s - opening tag=%.*s\n", tagname_len, curnode->name, tagname_len, tagname );
          #endif
          cpos -= tagname_len;
          cpos += res - 1;
          goto error;
        }*/
        curnode->z = cpos-htmlin;
        curnode = curnode->parent; // jump up
        curname = del_namec( curname );
        if( !curnode ) goto done;
        tagname_len++;
        cpos++;
        
        goto val_1;
      }
      if( !let ) { last_state = ST_ename_x; goto done; }
      tagname_len++;
      cpos++;
      goto ename_x;
    error:
      self->err = - ( int ) ( cpos - &htmlin[0] );
      return self->err;
    done:
      #ifdef DEBUG
      printf("done\n", *cpos);
      #endif
      
      // store the current state of the parser
      self->last_state = last_state;
      self->curnode = curnode;
      self->curatt = curatt;
      self->tagname = tagname; self->tagname_len = tagname_len;
      self->attname = attname; self->attname_len = attname_len;
      self->attval  = attval;  self->attval_len  = attval_len;
      self->att_has_val = att_has_val;
      
      // clean up name stack
      while( curname ) {
        curname = del_namec( curname );
        #ifdef DEBUG
        printf("cleaning name stack\n");
        #endif
      }
      
      #ifdef DEBUG
      printf("returning\n", *cpos);
      #endif
      return 0;//no error
}

int parserc_parse_unsafely( struct parserc *self, char *htmlin ) {
    // Variables that represent current 'state'
    struct nodec *root    = NULL;
    char  *tagname        = NULL; int    tagname_len    = 0;
    char  *attname        = NULL; int    attname_len    = 0;
    char  *attval         = NULL; int    attval_len     = 0;
    int    att_has_val    = 0;
    struct nodec *curnode = NULL;
    struct attc  *curatt  = NULL;
    int    last_state     = 0;
    self->rootpos = htmlin;
    
    // Variables used temporarily during processing
    struct nodec *temp;
    char   *cpos          = &htmlin[0];
    int    res            = 0;
    int    dent;
    register int let;
    
    if( self->last_state ) {
      return -1; // unsafe doesn't support this
    }
    else {
      self->err = 0;
      curnode = root = self->rootnode = new_nodec();
    }
    
    #ifdef DEBUG
    printf("Entry to C Parser\n");
    #endif
    
    u_val_1: // content
      #ifdef DEBUG
      printf("val_1: %c\n", *cpos);
      #endif
      switch( *cpos ) {
        case 0: last_state = ST_val_1; goto u_done;
        case '<': goto u_val_x;
      }
      if( !curnode->numvals ) {
        curnode->value = cpos;
        curnode->vallen = 1;
      }
      curnode->numvals++;
      cpos++;
      
    u_val_x: // content
      #ifdef DEBUG
      printf("val_x: %c\n", *cpos);
      #endif
      switch( *cpos ) {
        case 0: last_state = ST_val_x; goto u_done;
        case '<':
          if( *(cpos+1) == '!' &&
              *(cpos+2) == '[' &&
              *(cpos+3) == 'C' &&
              *(cpos+4) == 'D' &&
              *(cpos+5) == 'A' &&
              *(cpos+6) == 'T' &&
              *(cpos+7) == 'A'    ) {
            cpos += 9;
            curnode->type = 1;
            goto u_cdata;
          }
          
          tagname_len = 0; // for safety
          cpos++;
          goto u_name_1;
      }
      if( curnode->numvals == 1 ) curnode->vallen++;
      cpos++;
      goto u_val_x;
    
    u_cdata:
      if( *cpos == ']' && *(cpos+1) == ']' && *(cpos+2) == '>' ) {
        cpos += 3;
        goto u_val_1;
      }
      if( !curnode->numvals ) {
        curnode->value = cpos;
        curnode->vallen = 0;
        curnode->numvals = 1;
      }
      if( curnode->numvals == 1 ) curnode->vallen++;
      cpos++;
      goto u_cdata;
      
    u_name_1: // node name
      #ifdef DEBUG
      printf("name_1: %c\n", *cpos);
      #endif
      switch( *cpos ) {
        case '/': // regular closing tag
          tagname_len = 0; // needed to reset
          cpos++;
          goto u_ename_1;
      }
      tagname       = cpos;
      tagname_len   = 1;
      cpos++;
      goto u_name_x;
      
    u_name_x: // node name
      #ifdef DEBUG
      printf("name_x: %c\n", *cpos);
      #endif
      switch( *cpos ) {
        case ' ':
          curnode     = nodec_addchildr( curnode, tagname, tagname_len );
          attname_len = 0;
          cpos++;
          goto u_name_gap;
        case '>':
          curnode     = nodec_addchildr( curnode, tagname, tagname_len );
          cpos++;
          goto u_val_1;
        case '/': // self closing
          temp = nodec_addchildr( curnode, tagname, tagname_len );
          tagname_len = 0;
          cpos+=2;
          goto u_val_1;
      }
      
      tagname_len++;
      cpos++;
      goto u_name_x;
          
    u_name_gap: // node name gap
      switch( *cpos ) {
        case ' ':
        case '>':
          cpos++;
          goto u_val_1;
        case '/': // self closing
          curnode = curnode->parent;
          if( !curnode ) goto u_done;
          cpos += 2; // am assuming next char is >
          goto u_val_1;
      }
        
    u_att_name1:
      #ifdef DEBUG
      printf("attname1: %c\n", *cpos);
      #endif
      att_has_val = 0;
      attname = cpos;
      attname_len = 1;
      cpos++;
      goto u_att_name;
      
    u_att_space:
      if( *cpos == '=' ) {
          att_has_val = 1;
          cpos++;
          goto u_att_eq1;
      }
      // we have another attribute name, so continue
      
    u_att_name:
      #ifdef DEBUG
      printf("attname: %c\n", *cpos);
      #endif
      let = *cpos;
      switch( let ) {
        case '/': // self closing     !! /> is assumed !!
          curatt = nodec_addattr( curnode, attname, attname_len );
          if( !att_has_val ) { curatt->value = -1; curatt->vallen = 0; }
          attname_len = 0;
          
          curnode = curnode->parent;
          if( !curnode ) goto u_done;
          cpos += 2;
          goto u_val_1;
        case ' ':
          if( *(cpos+1) == '=' ) {
            cpos++;
            goto u_att_name;
          }
          curatt = nodec_addattr( curnode, attname, attname_len );
          attname_len = 0;
          cpos++;
          goto u_att_space;
        case '>':
          curatt = nodec_addattr( curnode, attname, attname_len );
          if( !att_has_val ) { curatt->value = -1; curatt->vallen = 0; }
          attname_len = 0;
          cpos++;
          goto u_val_1;
        case '=':
          attval_len = 0;
          curatt = nodec_addattr( curnode, attname, attname_len );
          attname_len = 0;
          cpos++;
          goto u_att_eq1;
      }
      
      if( !attname_len ) attname = cpos;
      attname_len++;
      cpos++;
      goto u_att_name;
      
    u_att_eq1:
      switch( *cpos ) {
        case '/': // self closing
          if( *(cpos+1) == '>' ) {
            curnode = curnode->parent;
            if( !curnode ) goto u_done;
            cpos += 2;
            goto u_att_eq1;
          }
          break;
        case '"':  cpos++; goto u_att_quot;
        case 0x27: cpos++; goto u_att_quots; //'
        case '>':  cpos++; goto u_val_1;
        case ' ':  cpos++; goto u_att_eq1;
      }  
      if( !attval_len ) attval = cpos;
      attval_len++;
      cpos++;
      goto u_att_eqx;
      
    u_att_eqx:
      switch( *cpos ) {
        case '/': // self closing
          if( *(cpos+1) == '>' ) {
            curnode = curnode->parent;
            if( !curnode ) goto u_done; // bad error condition
            curatt->value = attval;
            curatt->vallen = attval_len;
            attval_len    = 0;
            cpos += 2;
            goto u_val_1;
          }
          break;
        case '>':
          curatt->value = attval;
          curatt->vallen = attval_len;
          attval_len    = 0;
          cpos++;
          goto u_val_1;
        case ' ':
          curatt->value = attval;
          curatt->vallen = attval_len;
          attval_len    = 0;
          cpos++;
          goto u_name_gap;
      }
      
      if( !attval_len ) attval = cpos;
      attval_len++;
      cpos++;
      goto u_att_eqx;
      
    u_att_quot:
      if( *cpos == '"' ) {
        if( attval_len ) {
          curatt->value = attval;
          curatt->vallen = attval_len;
          attval_len = 0;
        }
        cpos++;
        goto u_name_gap;
      }
      if( !attval_len ) attval = cpos;
      attval_len++;
      cpos++;
      goto u_att_quot;
      
    u_att_quots:
      if( *cpos == 0x27 ) { // '
        if( attval_len ) {
          curatt->value = attval;
          curatt->vallen = attval_len;
          attval_len = 0;
        }
        cpos++;
        goto u_name_gap;
      }
      if( !attval_len ) attval = cpos;
      attval_len++;
      cpos++;
      goto u_att_quots;
      
    u_ename_1:
      tagname       = cpos;
      tagname_len   = 1;
      cpos++;
      // continue
      
    u_ename_x: // ending name
      let = *cpos;
      if( let == '>' ) {
        curnode->z = cpos-htmlin;
        curnode = curnode->parent; // jump up
        if( !curnode ) goto u_done;
        tagname_len++;
        cpos++;
        
        goto u_val_1;
      }
      tagname_len++;
      cpos++;
      goto u_ename_x;
    
    u_done:
      #ifdef DEBUG
      printf("done\n", *cpos);
      #endif
      
      // store the current state of the parser
      self->last_state = last_state;
      self->curnode = curnode;
      self->curatt = curatt;
      self->tagname = tagname; self->tagname_len = tagname_len;
      self->attname = attname; self->attname_len = attname_len;
      self->attval  = attval;  self->attval_len  = attval_len;
      self->att_has_val = att_has_val;
      
      #ifdef DEBUG
      printf("returning\n", *cpos);
      #endif
      return 0;//no error
}

struct utfchar {
  char high;
  char low;
};

struct nodec *nodec_addchildr(  struct nodec *self, char *newname, int newnamelen ) {
  struct nodec *newnode = new_nodecp( self );
  newnode->name    = newname;
  newnode->namelen = newnamelen;
  if( self->numchildren == 0 ) {
    self->firstchild = newnode;
    self->lastchild  = newnode;
    self->numchildren++;
    return newnode;
  }
  else {
    self->lastchild->next = newnode;
    self->lastchild = newnode;
    self->numchildren++;
    return newnode;
  }
}

struct attc *nodec_addattr( struct nodec *self, char *newname, int newnamelen ) {
  struct attc *newatt = new_attc( self );
  newatt->name    = newname;
  newatt->namelen = newnamelen;
  
  if( !self->numatt ) {
    self->firstatt = newatt;
    self->lastatt  = newatt;
    self->numatt++;
    return newatt;
  }
  else {
    self->lastatt->next = newatt;
    self->lastatt = newatt;
    self->numatt++;
    return newatt;
  }
}
