// JEdit mode Line -> :folding=indent:mode=c++:indentSize=2:noTabs=true:tabSize=2:
#include "EXTERN.h"
#define PERL_IN_HV_C
#define PERL_HASH_INTERNAL_ACCESS

#include "perl.h"
#include "XSUB.h"
#include "parser.h"

U32 vhash;
U32 chash;
U32 phash;
U32 ihash;
U32 cdhash;
U32 zhash;
U32 ahash;
U32 content_hash;

char *rootpos;

//#define DEBUG
  
SV *chtml2obj( struct parserc *parser, struct nodec *curnode ) {
  HV *output = newHV(); // the root
  SV *outputref = newRV_noinc( (SV *) output ); // return a reference to the root
  int i; // loop index; defined at the top because this is C
  struct attc *curatt; // current attribute being worked with
  int numatts = curnode->numatt; // total number of attributes on the current node
  SV *attval;
  SV *attatt;
  int cur_type;
      
  int length = curnode->numchildren;
  SV *svi = newSViv( curnode->pos );
  
  hv_store( output, "_pos", 4, svi, phash );
  hv_store( output, "_i", 2, newSViv( curnode->name - rootpos ), ihash );
  hv_store( output, "_z", 2, newSViv( curnode->z ), zhash );
  
  #ifdef DEBUG
  printf("Node: %.*s\n", curnode->namelen, curnode->name );
  #endif
  
  // node without children
  if( !length ) {
    if( curnode->vallen ) {
      SV * sv = newSVpvn( curnode->value, curnode->vallen );
      SvUTF8_on(sv);
      hv_store( output, "value", 5, sv, vhash );
      if( curnode->type ) {
        SV *svi = newSViv( 1 );
        hv_store( output, "_cdata", 6, svi, cdhash );
      }
    }
    if( curnode->comlen ) {
      SV * sv = newSVpvn( curnode->comment, curnode->comlen );
      SvUTF8_on(sv);
      hv_store( output, "comment", 7, sv, chash );
    }
  }
  
  // node with children
  else {
    if( curnode->vallen ) {
      SV *sv = newSVpvn( curnode->value, curnode->vallen );
      SvUTF8_on(sv);
      hv_store( output, "value", 5, sv, vhash );
      if( curnode->type ) {
        SV *svi = newSViv( 1 );
        hv_store( output, "_cdata", 6, svi, cdhash );
      }
    }
    if( curnode->comlen ) {
      SV *sv = newSVpvn( curnode->comment, curnode->comlen );
      SvUTF8_on(sv);
      hv_store( output, "comment", 7, sv, chash );
    }
    
    // loop through child nodes
    curnode = curnode->firstchild;
    for( i = 0; i < length; i++ ) {
      SV **cur = hv_fetch( output, curnode->name, curnode->namelen, 0 );
      
      // check for multi_[name] nodes
      if( curnode->namelen > 6 ) {
        if( !strncmp( curnode->name, "multi_", 6 ) ) {
          char *subname = &curnode->name[6];
          int subnamelen = curnode->namelen-6;
          SV **old = hv_fetch( output, subname, subnamelen, 0 );
          AV *newarray = newAV();
          SV *newarrayref = newRV_noinc( (SV *) newarray );
          if( !old ) {
            hv_store( output, subname, subnamelen, newarrayref, 0 );
          }
          else {
            if( SvTYPE( SvRV(*old) ) == SVt_PVHV ) { // check for hash ref
              SV *newref = newRV( (SV *) SvRV(*old) );
              hv_delete( output, subname, subnamelen, 0 );
              hv_store( output, subname, subnamelen, newarrayref, 0 );
              av_push( newarray, newref );
            }
          }
        }
      }
      
      if( !cur ) {
        SV *ob = chtml2obj( parser, curnode );
        hv_store( output, curnode->name, curnode->namelen, ob, 0 );
      }
      else { // there is already a node stored with this name
        cur_type = SvTYPE( SvRV( *cur ) );
        if( cur_type == SVt_PVHV ) { // sub value is a hash; must be anode
          AV *newarray = newAV();
          SV *newarrayref = newRV_noinc( (SV *) newarray );
          SV *newref = newRV( (SV *) SvRV( *cur ) );
          SV *ob;
          hv_delete( output, curnode->name, curnode->namelen, 0 );
          hv_store( output, curnode->name, curnode->namelen, newarrayref, 0 );
          av_push( newarray, newref );
          ob = chtml2obj( parser, curnode );
          av_push( newarray, ob );
        }
        else if( cur_type == SVt_PVAV ) {
          AV *av = (AV *) SvRV( *cur );
          SV *ob = chtml2obj( parser, curnode );
          av_push( av, ob );
        }
        else {
          // something else; probably an existing value node; just wipe it out
          SV *ob = chtml2obj( parser, curnode );
          hv_store( output, curnode->name, curnode->namelen, ob, 0 );
        }
      }
      if( i != ( length - 1 ) ) curnode = curnode->next;
    }
    
    curnode = curnode->parent;
  }
  
  if( numatts ) {
    curatt = curnode->firstatt;
    for( i = 0; i < numatts; i++ ) {
      HV *atth = newHV();
      SV *atthref = newRV_noinc( (SV *) atth );
      hv_store( output, curatt->name, curatt->namelen, atthref, 0 );
      
      if( curatt->value == -1 ) attval = newSVpvn( "1", 1 );
      else attval = newSVpvn( curatt->value, curatt->vallen );
      SvUTF8_on(attval);
      hv_store( atth, "value", 5, attval, vhash );
      attatt = newSViv( 1 );
      hv_store( atth, "_att", 4, attatt, ahash );
      if( i != ( numatts - 1 ) ) curatt = curatt->next;
    }
  }
  return outputref;
}

SV *chtml2obj_simple( struct parserc *parser, struct nodec *curnode ) {
  int i;
  struct attc *curatt;
  int numatts = curnode->numatt;
  SV *attval;
  SV *attatt;
  HV *output;
  SV *outputref;
  
  int length = curnode->numchildren;
  if( ( length + numatts ) == 0 ) {
    if( curnode->vallen ) {
      SV * sv = newSVpvn( curnode->value, curnode->vallen );
      SvUTF8_on(sv);
      return sv;
    }
    return newSVpvn( "", 0 );
  }
  
  output = newHV();
  outputref = newRV_noinc( (SV *) output );
  
  if( length ) {
    curnode = curnode->firstchild;
    for( i = 0; i < length; i++ ) {
      SV *namesv = newSVpvn( curnode->name, curnode->namelen );
      SvUTF8_on(namesv);
      
      SV **cur = hv_fetch( output, curnode->name, curnode->namelen, 0 );
      
      if( curnode->namelen > 6 ) {
        if( !strncmp( curnode->name, "multi_", 6 ) ) {
          char *subname = &curnode->name[6];
          int subnamelen = curnode->namelen-6;
          SV **old = hv_fetch( output, subname, subnamelen, 0 );
          AV *newarray = newAV();
          SV *newarrayref = newRV_noinc( (SV *) newarray );
          if( !old ) {
            hv_store( output, subname, subnamelen, newarrayref, 0 );
          }
          else {
            if( SvTYPE( SvRV(*old) ) == SVt_PVHV ) { // check for hash ref
              SV *newref = newRV_noinc( (SV *) SvRV(*old) );
              hv_delete( output, subname, subnamelen, 0 );
              hv_store( output, subname, subnamelen, newarrayref, 0 );
              av_push( newarray, newref );
            }
          }
        }
      }
        
      if( !cur ) {
        SV *ob = chtml2obj_simple( parser, curnode );
        hv_store( output, curnode->name, curnode->namelen, ob, 0 );
      }
      else {
        if( SvROK( *cur ) ) {
          if( SvTYPE( SvRV(*cur) ) == SVt_PVHV ) {
            AV *newarray = newAV();
            SV *newarrayref = newRV_noinc( (SV *) newarray );
            SV *newref = newRV( (SV *) SvRV( *cur ) );
            hv_delete( output, curnode->name, curnode->namelen, 0 );
            hv_store( output, curnode->name, curnode->namelen, newarrayref, 0 );
            av_push( newarray, newref );
            av_push( newarray, chtml2obj_simple( parser, curnode ) );
          }
          else {
            AV *av = (AV *) SvRV( *cur );
            av_push( av, chtml2obj_simple( parser, curnode ) );
          }
        }
        else {
          AV *newarray = newAV();
          SV *newarrayref = newRV( (SV *) newarray );
          
          STRLEN len;
          char *ptr = SvPV(*cur, len);
          SV *newsv = newSVpvn( ptr, len );
          SvUTF8_on(newsv);
          
          av_push( newarray, newsv );
          hv_delete( output, curnode->name, curnode->namelen, 0 );
          hv_store( output, curnode->name, curnode->namelen, newarrayref, 0 );
          av_push( newarray, chtml2obj_simple( parser, curnode ) );
        }
      }
      if( i != ( length - 1 ) ) curnode = curnode->next;
    }
    curnode = curnode->parent;
  }
  else {
    if( curnode->type ) { // store cdata value under content, even if empty or spaces
      SV * sv = newSVpvn( curnode->value, curnode->vallen );
      SvUTF8_on(sv);
      hv_store( output, "content", 7, sv, content_hash );
    }
    else {
      int hasval = 0;
      for( i=0;i<curnode->vallen;i++ ) {
        char let = curnode->value[ i ];
        if( let != ' ' && let != 0x0d && let != 0x0a ) {
          hasval = 1;
          break;
        }
      }
      if( hasval ) {
        SV * sv = newSVpvn( curnode->value, curnode->vallen );
        SvUTF8_on(sv);
        hv_store( output, "content", 7, sv, content_hash );
      }
    }
  }
  
  if( numatts ) {
    curatt = curnode->firstatt;
    for( i = 0; i < numatts; i++ ) {
      if( curatt->value == -1 ) attval = newSVpvn( "1", 1 );
      else attval = newSVpvn( curatt->value, curatt->vallen );
      SvUTF8_on(attval);
      hv_store( output, curatt->name, curatt->namelen, attval, 0 );
      if( i != ( numatts - 1 ) ) curatt = curatt->next;
    }
  }
  
  return outputref;
}

void init_hashes() {
  PERL_HASH(vhash, "value", 5);
  PERL_HASH(ahash, "_att", 4);
  PERL_HASH(chash, "comment", 7);
  PERL_HASH(phash, "_pos", 4);
  PERL_HASH(ihash, "_i", 2 );
  PERL_HASH(zhash, "_z", 2 );
  PERL_HASH(cdhash, "_cdata", 6 );
}

MODULE = HTML::Bare         PACKAGE = HTML::Bare

SV *
html2obj( parsersv )
  SV *parsersv
  CODE:
    struct parserc *parser;
    parser = INT2PTR( struct parserc *, SvUV( parsersv ) );
    if( parser->err ) RETVAL = newSViv( parser->err );
    else {
      RETVAL = chtml2obj( parser, parser->rootnode );
      //printf("refcnt: %i\n", SvREFCNT( RETVAL ) );
    }
  OUTPUT:
    RETVAL
    
SV *
html2obj_simple( parsersv )
  SV *parsersv
  CODE:
    PERL_HASH( content_hash, "content", 7 );
    struct parserc *parser;
    parser = INT2PTR( struct parserc *, SvUV( parsersv ) );
    if( parser->err ) RETVAL = newSViv( parser->err );
    else {
      RETVAL = chtml2obj_simple( parser, parser->rootnode );
      //printf("refcnt: %i\n", SvREFCNT( RETVAL ) );
    }
  OUTPUT:
    RETVAL

SV *
c_parse_more( text, parsersv )
  char * text
  SV *parsersv
  CODE:
    struct parserc *parser = INT2PTR( struct parserc *, SvUV( parsersv ) );
    int err = parserc_parse( parser, text );
    RETVAL = newSVuv( PTR2UV( parser ) );
  OUTPUT:
    RETVAL

SV *
c_parse(text)
  char * text
  CODE:
    init_hashes();
    
    struct parserc *parser = (struct parserc *) malloc( sizeof( struct parserc ) );
    parser->last_state = 0;
    int err = parserc_parse( parser, text );
    RETVAL = newSVuv( PTR2UV( parser ) );
  OUTPUT:
    RETVAL

SV *
c_parse_unsafely(text)
  char * text
  CODE:
    init_hashes();
    
    struct parserc *parser = (struct parserc *) malloc( sizeof( struct parserc ) );
    parser->last_state = 0;
    int err = parserc_parse_unsafely( parser, text );
    RETVAL = newSVuv( PTR2UV( parser ) );
  OUTPUT:
    RETVAL

SV *
c_parsefile(filename)
  char * filename
  CODE:
    char *data;
    unsigned long len;
    FILE *handle;
    
    init_hashes();
    
    handle = fopen(filename,"r");
    
    fseek( handle, 0, SEEK_END );
    
    len = ftell( handle );
    
    fseek( handle, 0, SEEK_SET );
    data = (char *) malloc( len );
    rootpos = data;
    fread( data, 1, len, handle );
    fclose( handle );
    struct parserc *parser = (struct parserc *) malloc( sizeof( struct parserc ) );
    parser->last_state = 0;
    int err = parserc_parse( parser, data );
    //free( parser );
    RETVAL = newSVuv( PTR2UV( parser ) );
  OUTPUT:
    RETVAL

void
free_tree_c( parsersv )
  SV *parsersv
  CODE:
    struct parserc *parser;
    parser = INT2PTR( struct parserc *, SvUV( parsersv ) );
    struct nodec *rootnode = parser->rootnode;
    del_nodec( rootnode ); // note this frees the pointer as well
    free( parser );