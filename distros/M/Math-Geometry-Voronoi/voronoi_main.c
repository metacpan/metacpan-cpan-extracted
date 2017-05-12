/*** MAIN.C ***/

#include <stdio.h>
#include <stdlib.h>  /* realloc(), qsort() */


#include "vdefs.h"

Site * readone(void), * nextone(void) ;
void readsites(void) ;

int sorted, triangulate, plot, debug, nsites, siteidx ;
double xmin, xmax, ymin, ymax ;
Site * sites ;
Freelist sfl ;
AV *lines_out, *edges_out, *vertices_out;

int
compute_voronoi(Site *sites_in, int nsites_in, 
                double xmin_in, double xmax_in, 
                double ymin_in, double ymax_in, 
                int debug_in,
                AV *lines_out_in, 
                AV *edges_out_in, 
                AV *vertices_out_in)
    {
    int c ;
    Site *(*next)() ;

    freeinit(&sfl, sizeof(Site)) ;

    sorted = triangulate = plot = debug = 0 ;
    debug = debug_in;

    lines_out = lines_out_in;
    edges_out = edges_out_in;
    vertices_out = vertices_out_in;
    
    nsites = nsites_in;
    sites = sites_in;
    xmin = xmin_in;
    xmax = xmax_in;
    ymin = ymin_in;
    ymax = ymax_in;

    next = nextone;

    siteidx = 0 ;
    geominit() ;
    if (plot)
        {
        plotinit() ;
        }
    voronoi(next) ;

    free_all();
    return (0) ;
}

/*** return a single in-storage site ***/

Site *
nextone(void)
    {
    Site * s ;

    if (siteidx < nsites)
        {
        s = &sites[siteidx++];
        return (s) ;
        }
    else
        {
        return ((Site *)NULL) ;
        }
    }

