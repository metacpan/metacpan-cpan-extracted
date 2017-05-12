/*  This file is meant to be used with TinyXML
    To compile this file you should place it in the
    TinyXML source directory; overwriting the default
    xmltest.xpp and then do a normal build of TinyXML.
    The resulting xmltest.exe can then be used with benchmarking
    for loading and parsing combined */
#include <stdio.h>
#include "tinyxml.h"

int main( int argc, char *argv[] ) {
  TiXmlDocument doc( argv[1] );
  if ( !doc.LoadFile() ) {
    printf( "TinyXML failed: %s\n", doc.ErrorDesc() );
    exit( 1 );
  }
}


