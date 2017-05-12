/* GDCHART 0.94b  PIE CHART SAMPLE  3 Aug '99 */

#include <stdio.h>
#include <values.h>
#include <math.h>

#include "gdc.h"
#include "gdcpie.h"

main( )
{
    /* set data - can be loaded from anywhere, e.g., a DB */
    float          data[6]  = { 20.0,     40.0,     25.0,       15.0,     9.0,      11.0 };      /* data array */
    char           *lbls[6] = { "Radio",  "Print",  "Internet", "TV",     "Cable",  "other" };   /* label array */
    /* optional data */
    int            expl[6]  = { 0,        0,        18,         0,        0,        21 };        /* explode each slice */
    unsigned long  clrs[6]  = { 0xFF0000, 0x00FF00, 0x0000FF,   0xFF00FF, 0xFFFF00, 0x00FFFF };  /* color for each slice */

                                        /* open FILE* (can be stdout e.g. CGI use) */
    FILE           *fp = fopen( "3dpie.gif", "wb" );


    /* set some options - not required */
    GDCPIE_explode   = expl;            /* default - no explosion */
    GDCPIE_Color     = clrs;            /* default - gray */
    GDCPIE_EdgeColor = 0xFFFFFFL;       /* default - no edging */

    /* call the lib */
    pie_gif( 200,                       /* width             */
             175,                       /* height            */
             fp,                        /* open file pointer */
             GDC_3DPIE,                 /* or GDC_2DPIE      */
             6,                         /* number of slices  */
             lbls,                      /* slice labels      */
             data );                    /* data array        */

    fclose( fp );
    exit( 0 );
}
