#include<stdio.h>
#include "../../parser.h"

int main( int argc, char *argv[] ) {
  struct parserc parser;
  struct nodec *root;
  char *text;
  long pos;
  FILE *file;
  
  file = fopen(argv[1],"r");
  fseek( file, SEEK_END, 0);
  fseek( file, SEEK_SET, 0);
  pos = ftell( file );
  text = (char *) malloc( pos );
  fread( text, 1, pos, file );
  fclose( file );
  parserc_parse( &parser, text );
  root = parser.pcurnode;
  free( text );
}
