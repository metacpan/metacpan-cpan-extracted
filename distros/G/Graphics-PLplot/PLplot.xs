/*

  PLplot.xs

  Copyright (C) 2004 Tim Jenness. All Rights Reserved.
 
This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.
 
This program is distributed in the hope that it will be useful,but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.
 
You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 59 Temple
Place,Suite 330, Boston, MA  02111-1307, USA
 
*/
 
#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"   /* std perl include */
#include "perl.h"     /* std perl include */
#include "XSUB.h"     /* XSUB include */
  /* #include "ppport.h" */
#ifdef __cplusplus
}
#endif

#include "plplot/plplotP.h"
#include "plplot/plplot.h"
#include "arrays.h"
char ** pack1Dchar( AV * );
char ** pack1Dchar_sz( AV * , int * );
AV * unpack1Dchar(char **, int );

/* Use typedef for StripChart ID */
typedef PLINT PLSTRIPID;

/* For 2D perl arrays */
typedef PLFLT PLFLT2D;


/* Helper routine for packing string arrays */

char ** pack1Dchar( AV * avref ) {
  int nelem;
  return pack1Dchar_sz( avref, &nelem );
}

char ** pack1Dchar_sz( AV * avref, int * nelem ) {
  int i;
  SV ** elem;
  char ** outarr;
  int len;
  STRLEN linelen;
 
  /* number of elements */
  len  = av_len( avref ) + 1;
  /* Temporary storage */
  outarr = get_mortalspace( len,'v');
 
  for (i=0; i<len; i++) {
    elem = av_fetch( avref, i, 0);
    if (elem == NULL ) {
      /* undef */
      char * temp = get_mortalspace(1,'c');
      temp = "\0";
      outarr[i] = temp;
    } else {
      outarr[i] = SvPV( *elem, linelen);
    }
  }
  if (nelem != NULL) *nelem = len;
  return outarr;
}

/* Helper routine for unpacking char ** */

AV* unpack1Dchar( char ** inarr, int nelem ) {
   AV* arr = newAV();
   SV * string;
   SV** elem;
   int i;

   for (i = 0; i < nelem ; i++ ) {
       string = newSVpv( inarr[i], 0);
       elem = av_store(  arr, i, string );
       if (elem == NULL)
          SvREFCNT_dec(string);
   }
   return arr;
}


MODULE = Graphics::PLplot     PACKAGE = Graphics::PLplot PREFIX = c_


void
c_pl_setcontlabelformat( lexp, sigdig )
  PLFLT lexp
  PLFLT sigdig


void
c_pl_setcontlabelparam( offset, size, active, spacing )
  PLFLT offset
  PLFLT size
  PLFLT active
  PLFLT spacing

void
c_pladv( sub )
  PLINT sub


void
c_plaxes( x0, y0, xopt, xtick, nxsub, yopt, ytick, nysub )
  PLFLT x0
  PLFLT y0
  char * xopt
  PLFLT xtick
  PLINT nxsub
  char * yopt
  PLFLT ytick
  PLINT nysub

void
c_plbin( x, y, center )
  PLFLT * x
  PLFLT * y
  PLINT center
 CODE:
  c_plbin( ix_x, x, y, center);

void
c_plbop()
 ALIAS:
  plpage = 1

void
c_plbox(xopt, xtick, nxsub, yopt, ytick, nysub)
  char * xopt
  PLFLT xtick
  PLINT nxsub
  char * yopt
  PLFLT ytick
  PLINT nysub

void
c_plbox3( xopt, xlabel, xtick, nxsub, yopt, ylabel, ytick, nysub, zopt, zlabel, ztick, nzsub)
  char * xopt
  char * xlabel
  PLFLT xtick
  PLINT nxsub
  char * yopt
  char * ylabel
  PLFLT ytick
  PLINT nysub
  char * zopt
  char * zlabel
  PLFLT ztick
  PLINT nzsub

# ($wx, $wy, $window ) = plcalc_world( $rx, $ry );

void
c_plcalc_world( rx, ry)
  PLFLT rx
  PLFLT ry
 PREINIT:
  PLFLT wx;
  PLFLT wy;
  PLINT window;
 PPCODE:
  c_plcalc_world( rx, ry, &wx, &wy, &window );
  XPUSHs( sv_2mortal(newSVnv(wx)));
  XPUSHs( sv_2mortal(newSVnv(wy)));
  XPUSHs( sv_2mortal(newSViv(window)));


void
c_plclear()


void
c_plcol0( color )
  PLINT color
 ALIAS:
  plcol = 1

void
c_plcol1( color )
  PLFLT color

# plcont XXXXX

# plcpstrm

void
c_plcpstrm( iplsr, flags)
  PLINT iplsr
  PLINT flags


# plend

void
c_plend()

void
c_plend1()

# plenv

void
c_plenv( xmin, xmax, ymin, ymax, just, axis )
  PLFLT xmin
  PLFLT xmax
  PLFLT ymin
  PLFLT ymax
  PLINT just
  PLINT axis

void
c_plenv0( xmin, xmax, ymin, ymax, just, axis )
  PLFLT xmin
  PLFLT xmax
  PLFLT ymin
  PLFLT ymax
  PLINT just
  PLINT axis

void
c_pleop()
 ALIAS:
  plclr = 1

void
c_plerrx( xmin, xmax, y )
  PLFLT * xmin
  PLFLT * xmax
  PLFLT * y
 CODE:
  c_plerrx( ix_y, xmin, xmax, y );


void
c_plerry( x, ymin, ymax )
  PLFLT * x
  PLFLT * ymin
  PLFLT * ymax
 CODE:
  c_plerry( ix_x, x, ymin, ymax );

void
c_plfamadv()

void
c_plfill( x, y )
  PLFLT * x
  PLFLT * y
 CODE:
  c_plfill( ix_x, x, y );

void
c_plfill3( x, y, z )
  PLFLT * x
  PLFLT * y
  PLFLT * z
 CODE:
  c_plfill3( ix_x, x, y, z );


# plflush

void
c_plflush()

# plfont

void
c_plfont( input )
  PLINT input

void
c_plfontld( set )
  PLINT set

# plgchr

void
c_plgchr()
 PREINIT:
  PLFLT p_def;
  PLFLT p_ht;
 PPCODE:
  c_plgchr( &p_def, &p_ht );
  XPUSHs( sv_2mortal(newSVnv(p_def)));
  XPUSHs( sv_2mortal(newSVnv(p_ht)));

void
c_plgcol0(icol0)
  PLINT icol0
 PREINIT:
  PLINT r;
  PLINT g;
  PLINT b;
 PPCODE:
  c_plgcol0( icol0, &r, &g, &b );
  XPUSHs( sv_2mortal(newSViv(r)));
  XPUSHs( sv_2mortal(newSViv(g)));
  XPUSHs( sv_2mortal(newSViv(b)));

void
c_plgcolbg()
 PREINIT:
  PLINT r;
  PLINT g;
  PLINT b;
 PPCODE:
  c_plgcolbg( &r, &g, &b );
  XPUSHs( sv_2mortal(newSViv(r)));
  XPUSHs( sv_2mortal(newSViv(g)));
  XPUSHs( sv_2mortal(newSViv(b)));

PLINT
plgcompression()
 CODE:
  plgcompression( &RETVAL );
 OUTPUT:
  RETVAL

char *
c_plgdev()
 PREINIT:
   char ver[80];
 CODE:
   RETVAL = ver;
   c_plgdev( RETVAL );
 OUTPUT:
   RETVAL

void
c_plgdidev()
 PREINIT:
  PLFLT p_mar;
  PLFLT p_aspect;
  PLFLT p_jx;
  PLFLT p_jy;
 PPCODE:
  c_plgdidev( &p_mar, &p_aspect, &p_jx, &p_jy );
  XPUSHs( sv_2mortal(newSVnv(p_mar)));
  XPUSHs( sv_2mortal(newSVnv(p_aspect)));
  XPUSHs( sv_2mortal(newSVnv(p_jx)));
  XPUSHs( sv_2mortal(newSVnv(p_jy)));

PLFLT
plgdiori()
 CODE:
  plgdiori( &RETVAL );
 OUTPUT:
  RETVAL

void
c_plgdiplt()
 PREINIT:
  PLFLT p_xmin;
  PLFLT p_ymin;
  PLFLT p_xmax;
  PLFLT p_ymax;
 PPCODE:
  c_plgdiplt( &p_xmin, &p_ymin, &p_xmax, &p_ymax );
  XPUSHs( sv_2mortal(newSVnv(p_xmin)));
  XPUSHs( sv_2mortal(newSVnv(p_ymin)));
  XPUSHs( sv_2mortal(newSVnv(p_xmax)));
  XPUSHs( sv_2mortal(newSVnv(p_ymax)));


void
c_plgfam()
 PREINIT:
  PLINT fam;
  PLINT num;
  PLINT bmax;
 PPCODE:
  c_plgfam( &fam, &num, &bmax );
  XPUSHs( sv_2mortal(newSViv(fam)));
  XPUSHs( sv_2mortal(newSViv(num)));
  XPUSHs( sv_2mortal(newSViv(bmax)));


char *
c_plgfnam()
 PREINIT:
   char ver[80];
 CODE:
   RETVAL = ver;
   c_plgfnam( RETVAL );
 OUTPUT:
   RETVAL

PLINT
c_plglevel()
 CODE:
   c_plglevel( &RETVAL );
 OUTPUT:
   RETVAL

void
c_plgpage()
 PREINIT:
  PLFLT xp;
  PLFLT yp;
  PLINT xleng;
  PLINT yleng;
  PLINT xoff;
  PLINT yoff;
 PPCODE:
  c_plgpage( &xp, &yp, &xleng, &yleng, &xoff, &yoff);
  XPUSHs( sv_2mortal(newSVnv(xp)));
  XPUSHs( sv_2mortal(newSVnv(yp)));
  XPUSHs( sv_2mortal(newSViv(xleng)));
  XPUSHs( sv_2mortal(newSViv(yleng)));
  XPUSHs( sv_2mortal(newSViv(xoff)));
  XPUSHs( sv_2mortal(newSViv(yoff)));

void
plgra()

#  plgriddata - XXXXX Not yet
#    Need to know what to do with the 1-D perl output array
#    How do we make it usable without PDL?


void
c_plgspa()
 PREINIT:
  PLFLT xmin;
  PLFLT ymin;
  PLFLT xmax;
  PLFLT ymax;
 PPCODE:
  c_plgspa( &xmin, &ymin, &xmax, &ymax );
  XPUSHs( sv_2mortal(newSVnv(xmin)));
  XPUSHs( sv_2mortal(newSVnv(ymin)));
  XPUSHs( sv_2mortal(newSVnv(xmax)));
  XPUSHs( sv_2mortal(newSVnv(ymax)));


PLINT
c_plgstrm()
 CODE:
   c_plgstrm( &RETVAL );
 OUTPUT:
   RETVAL


# plgvers

char *
c_plgver()
 PREINIT:
   char ver[80];
 CODE:
   RETVAL = ver;
   c_plgver( RETVAL );
 OUTPUT:
   RETVAL

# plgvpd
void
c_plgvpd()
 PREINIT:
  PLFLT p_xmin;
  PLFLT p_xmax;
  PLFLT p_ymin;
  PLFLT p_ymax;
 PPCODE:
  c_plgvpd( &p_xmin, &p_xmax, &p_ymin, &p_ymax );
  XPUSHs( sv_2mortal(newSVnv(p_xmin)));
  XPUSHs( sv_2mortal(newSVnv(p_xmax)));
  XPUSHs( sv_2mortal(newSVnv(p_ymin)));
  XPUSHs( sv_2mortal(newSVnv(p_ymax)));

void
c_plgvpw()
 PREINIT:
  PLFLT p_xmin;
  PLFLT p_xmax;
  PLFLT p_ymin;
  PLFLT p_ymax;
 PPCODE:
  c_plgvpw( &p_xmin, &p_xmax, &p_ymin, &p_ymax );
  XPUSHs( sv_2mortal(newSVnv(p_xmin)));
  XPUSHs( sv_2mortal(newSVnv(p_xmax)));
  XPUSHs( sv_2mortal(newSVnv(p_ymin)));
  XPUSHs( sv_2mortal(newSVnv(p_ymax)));

void
c_plgxax()
 PREINIT:
  PLINT digmax;
  PLINT digits;
 PPCODE:
  c_plgxax( &digmax, &digits );
  XPUSHs( sv_2mortal(newSViv(digmax)));
  XPUSHs( sv_2mortal(newSViv(digits)));

void
c_plgyax()
 PREINIT:
  PLINT digmax;
  PLINT digits;
 PPCODE:
  c_plgyax( &digmax, &digits );
  XPUSHs( sv_2mortal(newSViv(digmax)));
  XPUSHs( sv_2mortal(newSViv(digits)));

void
c_plgzax()
 PREINIT:
  PLINT digmax;
  PLINT digits;
 PPCODE:
  c_plgzax( &digmax, &digits );
  XPUSHs( sv_2mortal(newSViv(digmax)));
  XPUSHs( sv_2mortal(newSViv(digits)));



void
c_plhist( data, datmin, datmax, nbin, oldwin )
  PLFLT * data
  PLFLT datmin
  PLFLT datmax
  PLINT nbin
  PLINT oldwin
 CODE:
  c_plhist( ix_data, data, datmin, datmax, nbin, oldwin);


# plhls is now deprecated

# plimage - takes 2D perl array [see PGPLOT::pgimag]
# You should be using PDL instead
#  Currently do not determine nx and ny from data

void
c_plimage( pdata,xmin, xmax, ymin, ymax, zmin, zmax, Dxmin, Dxmax, Dymin, Dymax, ...)
  PLFLT2D * pdata
  PLFLT xmin
  PLFLT xmax
  PLFLT ymin
  PLFLT ymax
  PLFLT zmin
  PLFLT zmax
  PLFLT Dxmin
  PLFLT Dxmax
  PLFLT Dymin
  PLFLT Dymax
 PREINIT:
  PLFLT ** data;
  int i;
  int j;
  int k = 0;
 CODE:
  /* Allow two additional optional arguments */
  if (items < 11 || items > 13)
        Perl_croak(aTHX_ "Usage: Graphics::PLplot::plimage(pdata, xmin, xmax, ymin, ymax, zmin, zmax, Dxmin, Dxmax, Dymin,Dymax,[nx,ny]");

  /* Read optional arguments */
  if (items > 11)
    nx_pdata = (PLINT)SvIV(ST(11));
  if (items > 12)
    ny_pdata = (PLINT)SvIV(ST(12));

  /* this is incredibly inefficient since we go from a 2D perl array
     to some C memory to some more C memory. Needs tidying up a lot.
     May as well just support a serialised 1D perl array */
  plAlloc2dGrid(&data, nx_pdata, ny_pdata);
  for (i = 0; i < nx_pdata; i++) {
    for (j = 0; j < ny_pdata; j++) {
      data[i][j] = pdata[k];
      k++;
    }
  }
  plimage( data, nx_pdata, ny_pdata, xmin, xmax, ymin, ymax, zmin, zmax, Dxmin, Dxmax, Dymin, Dymax);
  plFree2dGrid(data,nx_pdata,ny_pdata);


# plinit

void
c_plinit()

void
c_pljoin( x1, y1, x2, y2 )
 PLFLT x1
 PLFLT y1
 PLFLT x2
 PLFLT y2


# pllab

void
c_pllab( xlabel, ylabel, tlabel)
  char * xlabel
  char * ylabel
  char * tlabel

void
c_pllightsource(x,y,z )
  PLFLT x
  PLFLT y
  PLFLT z

# plline

void
c_plline( x, y )
  PLFLT * x
  PLFLT * y
 CODE:
  c_plline( ix_x, x, y );

void
c_plline3( x, y, z )
  PLFLT * x
  PLFLT * y
  PLFLT * z
 CODE:
  c_plline3( ix_x, x, y, z );

void
c_pllsty( input )
  PLINT input

# plmesh - not yet XXXXX

# plmeshc - not yet XXXXX

PLINT
c_plmkstrm()
 CODE:
   c_plmkstrm( &RETVAL );
 OUTPUT:
   RETVAL

# plmtex

void
c_plmtex( side, disp, pos, just, text )
  char * side
  PLFLT disp
  PLFLT pos
  PLFLT just
  char * text

# plot3d - not yet  XXXXX
# plot3dc - not yet  XXXXX

# plpage - see plbop



void
c_plpat( inc, del )
  PLINT * inc
  PLINT * del
 CODE:
  c_plpat( ix_inc, inc, del);



# plpoin

void
c_plpoin( x, y, code )
  PLFLT * x
  PLFLT * y
  PLINT code
 CODE:
  c_plpoin( ix_x, x, y, code);

void
c_plpoin3( x, y, z, code )
  PLFLT * x
  PLFLT * y
  PLFLT * z
  PLINT code
 CODE:
  c_plpoin3( ix_x, x, y, z, code);

void
c_plpoly3( x, y, z, draw, ifcc )
  PLFLT * x
  PLFLT * y
  PLFLT * z
  PLINT * draw
  PLINT ifcc
 CODE:
  c_plpoly3( ix_x, x, y, z, draw, ifcc);

void
c_plprec( set, prec )
  PLINT set
  PLINT prec

void
c_plpsty(n)
  PLINT n

# plptex

void
c_plptex( x, y, dx, dy, just, text )
  PLFLT x
  PLFLT y
  PLFLT dx
  PLFLT dy
  PLFLT just
  char * text

void
c_plreplot()

# plrgb - deprecated

# plschr

void
c_plschr( def, scale )
  PLFLT def
  PLFLT scale

void
c_plscmap0( r, g, b )
  PLINT * r
  PLINT * g
  PLINT * b
 CODE:
  c_plscmap0( r, g, b, ix_r );

void
c_plscmap0n( ncol0 )
  PLINT ncol0

void
c_plscmap1( r, g, b )
  PLINT * r
  PLINT * g
  PLINT * b
 CODE:
  c_plscmap1( r, g, b, ix_r );

# plscmap1l - need to allow rev to be an empty array
#   If @rev is empty we pass a NULL to the C routine.

void
c_plscmap1l(itype, pos, coord1, coord2, coord3, rev)
  PLINT itype
  PLFLT * pos
  PLFLT * coord1
  PLFLT * coord2
  PLFLT * coord3
  PLINT * rev
 CODE:
  if (ix_rev == 0) rev ==NULL;
  c_plscmap1l( itype, ix_pos, pos, coord1, coord2, coord3, rev);


void
c_plscmap1n( ncol1 )
  PLINT ncol1

void
c_plscol0( icol0, r, g, b)
  PLINT icol0
  PLINT r
  PLINT g
  PLINT b

void
c_plscolbg( r, g, b)
  PLINT r
  PLINT g
  PLINT b

void
c_plscolor( color )
  bool color
 CODE:
  c_plscolor( (PLINT)color );

void
c_plscompression( compression )
  PLINT compression

# plsdev

void
c_plsdev( devname )
  char * devname

void
c_plsdidev( mar, aspect, jx, jy)
  PLFLT mar
  PLFLT aspect
  PLFLT jx
  PLFLT jy

# plsdimap - Not yet public interface

void
c_plsdiori( rot )
  PLFLT rot

void
c_plsdiplt( xmin, ymin, xmax, ymax )
  PLFLT xmin
  PLFLT ymin
  PLFLT xmax
  PLFLT ymax

void
c_plsdiplz( xmin, ymin, xmax, ymax )
  PLFLT xmin
  PLFLT ymin
  PLFLT xmax
  PLFLT ymax

void
c_plsesc( esc )
  char esc

void
c_plsetopt( opt, optarg )
  char * opt
  char * optarg

void
c_plsfam( fam, num, bmax )
  PLINT fam
  PLINT num
  PLINT bmax

void
c_plsfnam( input )
  char * input

# plshades NOT YET - XXXX

void
c_plsmaj( def, scale )
  PLFLT def
  PLFLT scale

# plsmem - NOT YET XXXX

void
c_plsmin( def, scale )
  PLFLT def
  PLFLT scale

void
c_plsori( ori )
  PLINT ori

void
c_plspage( xp, yp, xleng, yleng, xoff, yoff )
  PLFLT xp
  PLFLT yp
  PLINT xleng
  PLINT yleng
  PLINT xoff
  PLINT yoff

void
c_plspause( pause )
  bool pause
 CODE:
  c_plspause( (PLINT)pause );

void
c_plsstrm( strm )
  PLINT strm

# plssub

void
c_plssub( nx, ny )
  PLINT nx
  PLINT ny

void
c_plssym( def, scale)
  PLFLT def
  PLFLT scale

void
c_plstar(nx, ny)
 PLINT nx
 PLINT ny

void
c_plstart(device, nx, ny)
  char * device
  PLINT nx
  PLINT ny

# Strip chart stuff goes in its own namespace

# This does not look like a constructor

PLSTRIPID
c_plstripc(xspec,yspec,xmin,xmax,xjump,ymin,ymax,xlpos,ylpos,y_ascl,acc,colbox, collab,colline,styline,legline,labx,laby,labtop)
  char * xspec
  char * yspec
  PLFLT xmin
  PLFLT xmax
  PLFLT xjump
  PLFLT ymin
  PLFLT ymax
  PLFLT xlpos
  PLFLT ylpos
  bool  y_ascl
  bool  acc
  PLINT colbox
  PLINT collab
  PLINT * colline
  PLINT * styline
  char ** legline
  char * labx
  char * laby
  char * labtop
 CODE:
   c_plstripc( &RETVAL, xspec, yspec, xmin, xmax, xjump, ymin, ymax, xlpos, ylpos, (PLINT)y_ascl, (PLINT)acc, colbox, collab, colline, styline, legline, labx, laby, labtop);
 OUTPUT:
  RETVAL

MODULE = Graphics::PLplot   PACKAGE = Graphics::PLplot::StripChart PREFIX = c_

# Provide an alias in the standard namespace for non method use

void
c_plstripa(id, p, x, y)
  PLSTRIPID id
  PLINT p
  PLFLT x
  PLFLT y
 ALIAS:
  Graphics::PLplot::plstripa = 1

# plstripd - implemented as auto destructor

void
DESTROY( id )
  PLSTRIPID id
CODE:
  c_plstripd( id );

# Back to the normal namespace

MODULE = Graphics::PLplot   PACKAGE = Graphics::PLplot PREFIX = c_


# plsurf3d

void
c_plsurf3d( x, y, z, opt, clevel )
  PLFLT * x
  PLFLT * y
  PLFLT2D * z
  PLINT opt
  PLFLT * clevel
 PREINIT:
  PLFLT ** zdata;
  int i;
  int j;
  int k = 0;
 CODE:
  if (ix_x != nx_z)
     Perl_croak(aTHX_ "Dimension of X array must be same as first dimension of Z array [%d != %d]",ix_x,nx_z);
  if (ix_y != ny_z)
     Perl_croak(aTHX_ "Dimension of Y array must be same as first dimension of Z array [%d != %d]",ix_y,ny_z);

  /* this is incredibly inefficient since we go from a 2D perl array
     to some C memory to some more C memory. Needs tidying up a lot.
     May as well just support a serialised 1D perl array */
  plAlloc2dGrid(&zdata, nx_z, ny_z);
  for (i = 0; i < nx_z; i++) {
    for (j = 0; j < ny_z; j++) {
      zdata[i][j] = z[k];
      k++;
    }
  }
  plsurf3d(x,y,zdata,nx_z,ny_z,opt,clevel, ix_clevel);



# plstyl - empty arrays are allowed

void
c_plstyl( mark, space )
  PLINT * mark
  PLINT * space
 CODE:
  c_plstyl( ix_mark, mark, space );


void
c_plsxax( digimax, digits )
  PLINT digimax
  PLINT digits


void
c_plsyax( digimax, digits )
  PLINT digimax
  PLINT digits

void
c_plsvpa(xmin, xmax, ymin, ymax)
  PLFLT xmin
  PLFLT xmax
  PLFLT ymin
  PLFLT ymax


void
c_plszax( digimax, digits )
  PLINT digimax
  PLINT digits


# plsym

void
c_plsym( x, y, code )
  PLFLT * x
  PLFLT * y
  PLINT code
 CODE:
  c_plsym( ix_x, x, y, code);

void
c_pltext()

void
c_plvasp(aspect)
  PLFLT aspect

void
c_plvpas(xmin, xmax, ymin, ymax,aspect)
  PLFLT xmin
  PLFLT xmax
  PLFLT ymin
  PLFLT ymax
  PLFLT aspect


void
c_plvpor( xmin, xmax, ymin, ymax )
  PLFLT xmin
  PLFLT xmax
  PLFLT ymin
  PLFLT ymax

void
c_plvsta()

void
c_plw3d(basex,basey,height,xmin,xmax,ymin,ymax,zmin,zmax,alt,az )
  PLFLT basex
  PLFLT basey
  PLFLT height
  PLFLT xmin
  PLFLT xmax
  PLFLT ymin
  PLFLT ymax
  PLFLT zmin
  PLFLT zmax
  PLFLT alt
  PLFLT az

void
c_plwid( width )
  PLINT width

void
c_plwind( xmin, xmax, ymin, ymax )
  PLFLT xmin
  PLFLT xmax
  PLFLT ymin
  PLFLT ymax

bool
c_plxormod( mode )
  bool mode
 PREINIT:
  PLINT status;
 CODE:
  c_plxormod( (PLINT)mode, &status);
  RETVAL = status;
 OUTPUT:
  RETVAL

### The C specific routines

void
plgFileDevs()
 PREINIT:
  char ** menustr;
  char ** devname;
  int ndev;
 PPCODE:
  /* Guess at largest number of drivers !! */
  menustr = get_mortalspace( 1024, 'v');
  devname = get_mortalspace( 1024, 'v');
  plgFileDevs(&menustr, &devname, &ndev);
  XPUSHs( newRV_noinc( (SV*)unpack1Dchar( menustr, ndev) ));
  XPUSHs( newRV_noinc( (SV*)unpack1Dchar( devname, ndev) ));

void
plgDevs()
 PREINIT:
  char ** menustr;
  char ** devname;
  int ndev;
 PPCODE:
  /* Guess at largest number of drivers !! */
  menustr = get_mortalspace( 1024, 'v');
  devname = get_mortalspace( 1024, 'v');
  plgDevs(&menustr, &devname, &ndev);
  XPUSHs( newRV_noinc( (SV*)unpack1Dchar( menustr, ndev) ));
  XPUSHs( newRV_noinc( (SV*)unpack1Dchar( devname, ndev) ));

## plsKeyEH - XXXXX not yet

## plsButtonEH - XXXXX not yet

## plsbobH     - XXXXX not yet

## plseopH     - XXXXX not yet

## plsError    - XXXXX not yet decided

## plsexit     - XXXXX not yet

## plsabort    - XXXXX not yet


## plClearOpts

void
plClearOpts()

void
plResetOpts()


# Returns status and all the unprocessed contents of @ARGV in ref to array

void
plParseOpts( argv, mode )
  char ** argv
  PLINT mode
 PREINIT:
  int status;
 PPCODE:
  /* $ARGV[0] is not the program name in perl */
  status = plParseOpts( &ix_argv, argv, mode | PL_PARSE_NOPROGRAM );
  XPUSHs( sv_2mortal(newSViv(status) ));  
  XPUSHs( newRV_noinc( (SV*)unpack1Dchar( argv, ix_argv) ));


# plMergeOpts should be done by perl GetOpt::Long



void
plSetUsage( program_string, usage_string )
  char * program_string
  char * usage_string

void
plOptUsage()

# This may cause problems since perl may well attempt to close
# this file itself

FILE *
plgfile()
 CODE:
  plgfile(&RETVAL);
 OUTPUT:
  RETVAL

void
plsfile( file )
  FILE * file

char
plgesc()
 CODE:
   plgesc(&RETVAL);
 OUTPUT:
   RETVAL

# Not really much need for plFindName or plFindCommand etc

# plGetCursor - return list of keyword value pairs
#  If not translation to world coordinates is possible, they
#  are not returned in the list

void
plGetCursor()
 PREINIT:
   PLGraphicsIn gin;
   int status;
 PPCODE:
  status = plGetCursor( &gin );
  XPUSHs(sv_2mortal(newSVpv( "dX", 0 )));
  XPUSHs(sv_2mortal(newSVnv( gin.dX )));
  XPUSHs(sv_2mortal(newSVpv( "dY", 0 )));
  XPUSHs(sv_2mortal(newSVnv( gin.dY )));
  XPUSHs(sv_2mortal(newSVpv( "pX", 0 )));
  XPUSHs(sv_2mortal(newSVnv( gin.pX )));
  XPUSHs(sv_2mortal(newSVpv( "pY", 0 )));
  XPUSHs(sv_2mortal(newSVnv( gin.pY )));
  if (status == 1 ) {
    XPUSHs(sv_2mortal(newSVpv( "wX", 0 )));
    XPUSHs(sv_2mortal(newSVnv( gin.wX )));
    XPUSHs(sv_2mortal(newSVpv( "wY", 0 )));
    XPUSHs(sv_2mortal(newSVnv( gin.wY )));
    XPUSHs(sv_2mortal(newSVpv( "subwindow", 0 )));
    XPUSHs(sv_2mortal(newSViv( gin.subwindow )));
  }
  XPUSHs(sv_2mortal(newSVpv( "state", 0 )));
  XPUSHs(sv_2mortal(newSVuv( gin.state )));
  XPUSHs(sv_2mortal(newSVpv( "keysym", 0 )));
  XPUSHs(sv_2mortal(newSVuv( gin.keysym )));
  XPUSHs(sv_2mortal(newSVpv( "button", 0 )));
  XPUSHs(sv_2mortal(newSVuv( gin.button )));
  XPUSHs(sv_2mortal(newSVpv( "string", 0 )));
  XPUSHs(sv_2mortal(newSVpv( gin.string, 0 )));

char*
plP_getinitdriverlist()
  PREINIT:
    char buffer[1024];
  CODE:
    RETVAL = buffer;
    plP_getinitdriverlist( buffer );
  OUTPUT:
    RETVAL

bool
plP_checkdriverinit(list)
  char * list


### PRIVATE ROUTINES that should not be exported

PLFLT
plstrl( string )
  char * string


MODULE = Graphics::PLplot  PACKAGE = Graphics::PLplot PREFIX = PL_

int
PL_PARSE_FULL()
 PROTOTYPE:
 CODE:
  RETVAL = PL_PARSE_FULL;
 OUTPUT:
  RETVAL

int
PL_PARSE_QUIET()
 PROTOTYPE:
 CODE:
  RETVAL = PL_PARSE_QUIET;
 OUTPUT:
  RETVAL

int
PL_PARSE_NODELETE()
 PROTOTYPE:
 CODE:
  RETVAL = PL_PARSE_NODELETE;
 OUTPUT:
  RETVAL

int
PL_PARSE_SHOWALL()
 PROTOTYPE:
 CODE:
  RETVAL = PL_PARSE_SHOWALL;
 OUTPUT:
  RETVAL

int
PL_PARSE_NODASH()
 PROTOTYPE:
 CODE:
  RETVAL = PL_PARSE_NODASH;
 OUTPUT:
  RETVAL

int
PL_PARSE_SKIP()
 PROTOTYPE:
 CODE:
  RETVAL = PL_PARSE_SKIP;
 OUTPUT:
  RETVAL


int
FACETED()
 PROTOTYPE:
 CODE:
  RETVAL = FACETED;
 OUTPUT:
  RETVAL


int
MAG_COLOR()
 PROTOTYPE:
 CODE:
  RETVAL = MAG_COLOR;
 OUTPUT:
  RETVAL

int
SURF_CONT()
 PROTOTYPE:
 CODE:
  RETVAL = SURF_CONT;
 OUTPUT:
  RETVAL

int
BASE_CONT()
 PROTOTYPE:
 CODE:
  RETVAL = BASE_CONT;
 OUTPUT:
  RETVAL

int
DRAW_SIDES()
 PROTOTYPE:
 CODE:
  RETVAL = DRAW_SIDES;
 OUTPUT:
  RETVAL








