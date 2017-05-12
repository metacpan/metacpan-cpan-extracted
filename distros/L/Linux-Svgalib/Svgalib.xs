
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <vga.h>

/* I move all that ugly constant stuff to another file */

extern double
_constant(char *name, int len, int arg);

char *av2char(AV *av_colors)
{
   char *_colors;
   I32 no_colors;
   I32 c_index;
   SV *color_temp;

   no_colors = av_len(av_colors);
       
   Newx(_colors,((int)no_colors + 1),char);

   if (_colors)
   {
     for( c_index = 0; c_index < no_colors; c_index++ )
     {
       color_temp = *av_fetch(av_colors,c_index,0);
       _colors[c_index] = *SvPV_nolen(color_temp);
     }
     _colors[no_colors] = (char)0;

     return(_colors);
   }
   else
   {
     return(0);
   }
}

MODULE = Linux::Svgalib		PACKAGE = Linux::Svgalib		


double
constant(sv,arg)
    PREINIT:
	STRLEN		len;
    INPUT:
	SV *		sv
	char *		s = SvPV(sv, len);
	int		arg
    CODE:
	RETVAL = _constant(s,len,arg);
    OUTPUT:
	RETVAL


void
addmode(self,xdim, ydim, cols, xbytes, bytespp)
SV *self
int xdim
int ydim
int cols
int xbytes
int bytespp
   PPCODE:
      IV newmode;
      SV *retmode; 

      newmode = (IV)vga_addmode(xdim, ydim, cols, xbytes, bytespp);

      retmode = newSViv(newmode);
      EXTEND(SP,1);
      PUSHs(sv_2mortal(retmode));

void
addtiming(self,pixelClock, HDisplay, HSyncStart, HSyncEnd, HTotal, VDisplay, VSyncStart, VSyncEnd, VTotal, flags)
SV *self
int	pixelClock
int	HDisplay
int	HSyncStart
int	HSyncEnd
int	HTotal
int	VDisplay
int	VSyncStart
int	VSyncEnd
int	VTotal
int	flags
   PPCODE:
      vga_addtiming(pixelClock, 
                       HDisplay, 
                       HSyncStart, 
                       HSyncEnd, 
                       HTotal, 
                       VDisplay, 
                       VSyncStart, 
                       VSyncEnd, 
                       VTotal, 
                       flags);
      

void
changetiming(self,pixelClock, HDisplay, HSyncStart, HSyncEnd, HTotal, VDisplay, VSyncStart, VSyncEnd, VTotal, flags)
SV *self
int	pixelClock
int	HDisplay
int	HSyncStart
int	HSyncEnd
int	HTotal
int	VDisplay
int	VSyncStart
int	VSyncEnd
int	VTotal
int	flags
   PPCODE:
      vga_changetiming(pixelClock, 
                       HDisplay, 
                       HSyncStart, 
                       HSyncEnd, 
                       HTotal, 
                       VDisplay, 
                       VSyncStart, 
                       VSyncEnd, 
                       VTotal, 
                       flags);
      

void
clear(self)
SV *self
   PPCODE:
      vga_clear();  

void
disabledriverreport(self)
SV *self
    PPCODE:
       vga_disabledriverreport();

void
drawline(self,x1, y1, x2, y2)
SV *self
int  x1
int  y1
int  x2
int  y2
  PPCODE:
     vga_drawline(x1,y1,x2,y2);

void
drawpixel(self,x, y)
SV *self
SV  *x
SV  *y 
   PPCODE: 
     int i_x;
     int i_y;

     i_x = (int)SvIV(x);
     i_y = (int)SvIV(y);
     vga_drawpixel(i_x,i_y); 


void
drawscanline(self,line, colors)
SV *self
SV *line
SV *colors
   PPCODE:
      int _line;
      char *_colors;
      AV *av_colors;

      if (SvROK(colors) && (SvTYPE(SvRV(colors)) == SVt_PVAV))
      {
         av_colors = (AV *)SvRV(colors);  
         _line = (int)SvIV(line);
         if(_colors = av2char(av_colors))
         {
           vga_drawscanline(_line,_colors);
           Safefree(_colors);
         }
      }
      else
      {
        croak("Not an array reference"); 
      }


void
drawscansegment(self,colors, x, y)
SV *self
SV *colors
SV *x
SV *y
   PPCODE:  
      int i_x;
      int i_y;
      int length; 
      char *_colors;
      AV *av_colors;

      if (SvROK(colors) && (SvTYPE(SvRV(colors)) == SVt_PVAV))
      {
         av_colors = (AV *)SvRV(colors); 
         length = av_len(av_colors); 
         i_x = (int)SvIV(x);
         i_y = (int)SvIV(y);

         if( _colors = av2char(av_colors))
         {
           vga_drawscansegment(_colors,i_x,i_y,length);
           Safefree(_colors);
         }
      }
      else
      {
        croak("Not an array reference");
      }

SV *
getch(self)
SV *self
  PPCODE:
    UV c;
    SV *ret;

    c = (UV)vga_getch();

   ret = newSViv(c);
   EXTEND(SP,1);
   PUSHs(sv_2mortal(ret));

SV *
getcolors(self)
SV *self
   PPCODE:
     SV *num_colors;

     num_colors = newSViv((IV)vga_getcolors());
     EXTEND(SP,1);
     PUSHs(sv_2mortal(num_colors));      

SV *
getcurrentchipset(self)
SV *self
   PPCODE:
     IV chipset;
     SV *ret;

     chipset = (IV)vga_getcurrentchipset();

     ret = newSViv(chipset);
     EXTEND(SP,1);
     PUSHs(sv_2mortal(ret));      


SV *
getcurrentmode(self)
SV *self
   PPCODE:
     IV mode;
     SV *ret;

     mode = (IV)vga_getcurrentmode();

     ret = newSViv(mode);
     EXTEND(SP,1);
     PUSHs(sv_2mortal(ret));      

void
getcurrenttiming(self)
SV *self
   PPCODE:
	int *pixelClock;
	int *HDisplay;
	int *HSyncStart;
	int *HSyncEnd;
	int *HTotal;
	int *VDisplay;
	int *VSyncStart;
	int *VSyncEnd;
	int *VTotal;
	int *flags;

        vga_getcurrenttiming(pixelClock, 
                             HDisplay, 
                             HSyncStart, 
                             HSyncEnd, 
                             HTotal, 
                             VDisplay, 
                             VSyncStart, 
                             VSyncEnd, 
                             VTotal, 
                             flags);
        EXTEND(SP,10);
        PUSHs(sv_2mortal(newSViv((IV) *pixelClock)));
        PUSHs(sv_2mortal(newSViv((IV) *HDisplay)));
        PUSHs(sv_2mortal(newSViv((IV) *HSyncStart)));
        PUSHs(sv_2mortal(newSViv((IV) *HSyncEnd)));
        PUSHs(sv_2mortal(newSViv((IV) *HTotal)));
        PUSHs(sv_2mortal(newSViv((IV) *VDisplay)));
        PUSHs(sv_2mortal(newSViv((IV) *VSyncStart)));
        PUSHs(sv_2mortal(newSViv((IV) *VSyncEnd)));
        PUSHs(sv_2mortal(newSViv((IV) *VTotal)));
        PUSHs(sv_2mortal(newSViv((IV) *flags)));

void
getdefaultmode(self)
SV *self
  PPCODE:
    SV *ret;

    ret = newSViv(vga_getdefaultmode());
    EXTEND(SP,1);
    PUSHs(sv_2mortal(ret));


void
getkey(self)
SV *self
   PPCODE:
     int _key;
     SV *key;

     _key = vga_getkey();

     key = newSViv((IV)_key);

     EXTEND(SP,1);
     PUSHs(sv_2mortal(key));

void
getmodeinfo(self,mode)
SV *self
SV* mode
  PPCODE:
    vga_modeinfo *mi;
    
    HV *mi_stash;
    HV *mi_h;
    SV *mi_ref;


    if( mi = vga_getmodeinfo(SvIV(mode)) )
    {
       mi_h = newHV();
       hv_store(mi_h,"width",5,newSViv(mi->width),0); 
       hv_store(mi_h,"height",6,newSViv(mi->height),0); 
       hv_store(mi_h,"bytesperpixel",13,newSViv(mi->bytesperpixel),0); 
       hv_store(mi_h,"colors",6,newSViv(mi->colors),0); 
       hv_store(mi_h,"linewidth",9,newSViv(mi->linewidth),0); 

       mi_ref = newRV_noinc((SV *)mi_h);

       mi_stash = gv_stashpv("Linux::Svgalib::Modeinfo",1);

       sv_bless(mi_ref,mi_stash);
    }
    else
    {
       mi_ref = &PL_sv_undef;
    }

    EXTEND(SP,1);
    PUSHs(sv_2mortal(mi_ref));


SV *
getmodename(self,mode)
SV *self
SV *mode
    PPCODE:
       int i_mode;
       SV  *modename;


       i_mode = SvIV(mode);

       modename = newSVpv((char *)vga_getmodename(i_mode),0);
       
       EXTEND(SP,1);
       PUSHs(sv_2mortal(modename));

SV *
getmodenumber(self,name)
SV *self
SV *name
   PPCODE:
     SV *modenumber;
     char *modename;

     modename = SvPV_nolen(name);

     modenumber = newSViv(vga_getmodenumber(modename));

     EXTEND(SP,1);
     PUSHs(modenumber);

void
getmonitortype(self)
SV *self
   PPCODE:
     EXTEND(SP,1);
     PUSHs(sv_2mortal(newSViv(vga_getmonitortype())));

void
getpalette(self, index)
SV *self
int index
   PPCODE:
	int *	red;
	int *	green;
	int *	blue;

        vga_getpalette(index,red, green, blue);
        EXTEND(SP,3);
        PUSHs(sv_2mortal(newSViv((IV)*red)));
        PUSHs(sv_2mortal(newSViv((IV)*green)));
        PUSHs(sv_2mortal(newSViv((IV)*blue)));

void
getpixel(self,x, y)
SV *self
SV *x
SV *y
  PPCODE:
    IV pcol;
    int i_x;
    int i_y;
    SV *ret;

    i_x = (int)SvIV(x);
    i_y = (int)SvIV(y);

    pcol = (IV)vga_getpixel(i_x,i_y);

    ret = newSViv(pcol);
    EXTEND(SP,1);
    PUSHs(sv_2mortal(ret));
 
SV *
getscansegment(self, x, y, length)
SV *self
SV *x
SV *y
SV *length
     PPCODE:
       char *_colors;
       AV *av_colors;  
       SV *ret;
       int i_x;
       int i_y;
       int i_length; 
       int index;

       EXTEND(SP,1);
       i_length = SvIV(length);
       if(_colors =  malloc(sizeof(char) * i_length))
       {
         av_colors = newAV();
         i_x = SvIV(x);
         i_y = SvIV(y);

         vga_getscansegment(_colors, i_x, i_y,i_length);

         for( index = 0; index < i_length; index++ )
         {
           av_push(av_colors,newSViv(_colors[index] ));
         }

         Safefree(_colors);

         ret = newRV((SV *)av_colors);
  
       }
       else
       {
         ret = &PL_sv_undef;
       }
       PUSHs(sv_2mortal(ret));
       
void
getxdim(self)
SV *self
   PPCODE:
     SV *xdim;
   
     xdim = newSViv((IV)vga_getxdim());
     EXTEND(SP,1);
     PUSHs(sv_2mortal(xdim));

void
getydim(self)
SV *self
   PPCODE:
     SV *ydim;
   
     ydim = newSViv((IV)vga_getydim());
     EXTEND(SP,1);
     PUSHs(sv_2mortal(ydim));

SV *
hasmode(self,mode)
SV *self
SV *mode
   PPCODE:
      IV ret;
      SV *rc;
      int _mode;

      _mode = (int)SvIV(mode);

      ret = vga_hasmode(_mode);
      
      if ( ret != 0 )
      {
        rc = &PL_sv_yes;
      }
      else
      {
        rc = &PL_sv_no;
      }

      EXTEND(SP,1);
      PUSHs(sv_2mortal(rc)); 
     
SV *
init(self)
SV * self
  PPCODE:
    SV *ret;
      
    if (vga_init() != 0 )
    { 
      ret = &PL_sv_no;
    }
    else
    {
      ret = &PL_sv_yes;  
    } 


    EXTEND(SP,1);
    PUSHs(sv_2mortal(ret));
     
SV *
lastmodenumber(self)
SV *self
  PPCODE:
     SV *mode;
     mode = newSViv(vga_lastmodenumber());
     EXTEND(SP,1);
     PUSHs(sv_2mortal(mode));  

void
lockvc(self)
SV *self
  PPCODE:
    vga_lockvc();

SV *
oktowrite(self)
SV *self
  PPCODE:
    SV *ret;
    EXTEND(SP,1);
    if ( vga_oktowrite() == 0 )
    {
      ret = &PL_sv_yes;
    }
    else
    {
      ret = &PL_sv_no;
    }
    PUSHs(sv_2mortal(ret));
 

void
screenoff(self)
SV *self
   PPCODE:
     vga_screenoff();

void
screenon(self)
SV *self
   PPCODE:
    vga_screenon();

void
setcolor(self,color)
SV *self
SV *color
     PPCODE:
        IV  _color;

        _color = SvIV(color); 
 
        vga_setcolor(_color);

SV *
setmode(self,mode)
SV *self
SV *mode
   PPCODE:
     IV _mode;
     IV ret;
     SV *rc;

     _mode = SvIV(mode);

     ret = (IV)vga_setmode(_mode);

     if (ret == -1)
     {
       rc = &PL_sv_no;
     }
     else
     {
       rc = &PL_sv_yes;
     }

     EXTEND(SP,1);
     PUSHs(sv_2mortal(rc));  

void
setpalette(self,index, red, green, blue)
SV *self
SV *index
SV *red
SV *green
SV *blue
   PPCODE:
      int _index, _red, _green, _blue;

      _index = SvIV(index);
      _red   = SvIV(red);
      _green = SvIV(green);
      _blue  = SvIV(blue);

      vga_setpalette(_index,_red,_green,_blue);


void
setrgbcolor(self,red, green, blue)
SV *self
SV *red
SV *green
SV *blue
   PPCODE:
      int  _red, _green, _blue;

      _red   = SvIV(red);
      _green = SvIV(green);
      _blue  = SvIV(blue);

      vga_setrgbcolor(_red,_green,_blue);


void
unlockvc(self)
SV *self
    PPCODE:
      vga_unlockvc();

void
white(self)
SV *self
  PPCODE:
     SV *white;

     white = newSViv((IV)vga_white());

     EXTEND(SP,1);
     PUSHs(sv_2mortal(white));

