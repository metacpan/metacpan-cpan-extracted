#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include <math.h>


MODULE = Location::GeoTool		PACKAGE = Location::GeoTool

void
p2v_xs(f,a,rd,lat,lon,tlat,tlon)
    double f
    double a
    double rd
    double lat
    double lon
    double tlat
    double tlon

    PPCODE:
    double e2,r,tu1,tu2;
    double cu1,su1,cu2,s1,b1,f1,x,d;
    double sx,cx,sy,cy,y,sa,c2a,cz,e,c;
    double dir,dis;
    int iter;

    e2 = 2.0*f - f*f;
    r = 1.0 - f;
    tu1 = r * tan(lat);
    tu2 = r * tan(tlat);
    cu1 = 1.0 / sqrt(1.0 + tu1*tu1);
    su1 = cu1 * tu1;
    cu2 = 1.0 / sqrt(1.0 + tu2*tu2); 
    s1 = cu1 * cu2;
    b1 = s1 * tu2;
    f1 = b1 * tu1;
    x = tlon - lon;
    d = x + 1;

    iter =1;

    while ((fabs(d - x) > 0.00000000005) && (iter < 100))
    {
      iter++;
      sx = sin(x);
      cx = cos(x);
      tu1 = cu2 * sx;
      tu2 = b1 - su1 * cu2 * cx;
      sy = sqrt(tu1*tu1 + tu2*tu2);
      cy = s1 * cx + f1;
      y = atan2(sy,cy);
      sa = s1 * sx / sy;
      c2a = 1.0 - sa*sa;
      cz = f1 + f1;
      if (c2a > 0.0)
      {
        cz = cy - cz / c2a;
      }
      e = cz*cz * 2.0 - 1.0;
      c = ((-3.0 * c2a + 4.0) * f + 4.0) * c2a * f / 16.0;
      d = x;
      x = ((e * cy * c + cz) * sy * c + y) * sa;
      x = (1.0 - c) * x * f + tlon - lon;
    }
    dir = atan2(tu1,tu2) / rd;
    x = sqrt((1 / (r*r) -1) * c2a +1);
    x += 1;
    x = (x - 2.0) / x;
    c = 1.0 - x;
    c = (x*x / 4.0 + 1.0) / c;
    d = (0.375 * x*x - 1.0) * x;
    x = e * cy;
    dis = ((((sy*sy * 4.0 - 3.0) * (1.0 - e - e) * cz * d / 6.0 - x) * d / 4.0 + cz) * sy * d + y) * c * a * r;

    XPUSHs(sv_2mortal(newSVnv(dir)));
    XPUSHs(sv_2mortal(newSVnv(dis)));

void
v2p_xs(f,a,rd,lat,lon,dir,dis)
    double f
    double a
    double rd
    double lat
    double lon
    double dir
    double dis

    PPCODE:
    double r,tu,sf,cf,b,cu,su,sa,c2a,x;
    double c,d,y,sy,cy,cz,e;
    double rlat,rlon;

    lat = lat *rd;
    lon = lon *rd;
    dir = dir * rd;

    r = 1 - f;
    tu = r * tan(lat);
    sf = sin(dir);
    cf = cos(dir);
    if (cf == 0) b = 0.0;
      else b = 2.0 * atan2(tu,cf);

    cu = 1.0 / sqrt(1 + tu*tu);
    su = tu * cu;
    sa = cu * sf;
    c2a = 1 - sa*sa;
    x = 1.0 + sqrt(1.0 + c2a * (1.0/(r*r)-1.0));
    x = (x - 2.0) / x;

    c = 1.0 - x;
    c = (x*x / 4.0 + 1.0) / c;
    d = (0.375 * x*x - 1.0) * x;
    tu = dis / (r * a * c);
    y = tu;
    c = y + 1;

    while (fabs(y - c) > 0.00000000005)
    {
      sy = sin(y);
      cy = cos(y);
      cz = cos(b + y);
      e = 2.0 * cz*cz -1.0;
      c = y;
      x = e * cy;
      y = e + e - 1;
      y = (((sy*sy * 4.0 - 3.0) * y * cz * d / 6.0 + x) * d / 4.0 - cz) * sy * d + tu;
    }
		
    b = cu * cy * cf - su * sy;
    c = r * sqrt(sa*sa + b*b);
    d = su * cy + cu * sy * cf;
    rlat = atan2(d,c);

    c = cu * cy - su * sy * cf;
    x = atan2(sy * sf, c); 
    c = ((-3.0 * c2a + 4.0) * f + 4.0) * c2a * f / 16.0;
    d = ((e * cy * c + cz) * sy * c + y) * sa;
    rlon = lon + x - (1.0 - c) * d * f;
    
    rlat = rlat/rd;
    rlon = rlon/rd;
    
    XPUSHs(sv_2mortal(newSVnv(rlat)));
    XPUSHs(sv_2mortal(newSVnv(rlon)));

void
molodensky_xs(b,l,h,a,f,ab,fb,dx,dy,dz,rd)
    double b
    double l
    double h
    double a
    double f
    double ab
    double fb
    double dx
    double dy
    double dz
    double rd

    PPCODE:
    double bda,e2,da,df,db,dl,dh;
    double sb,cb,sl,cl,rn,rm;
    double rb,rl,rh;

    b *= rd;
    l *= rd;

    e2 = 2*f - f*f;
    bda = 1- f;
    da = ab - a;
    df = fb - f;
   
    sb = sin(b);
    cb = cos(b);
    sl = sin(l);
    cl = cos(l);

    rn = 1 / sqrt(1 - e2*sb*sb); 
    rm = a * (1 - e2) * rn * rn * rn;
    rn *= a;

    db = -dx*sb*cl - dy*sb*sl + dz*cb
    + da*rn*e2*sb*cb/a + df*(rm/bda+rn*bda)*sb*cb;
    db /= rm + h;
    dl = -dx*sl + dy*cl;
    dl /= (rn+h) * cb;
    dh = dx*cb*cl + dy*cb*sl + dz*sb
    - da*a/rn + df*bda*rn*sb*sb;
 
    rb = (b+db)/rd;
    rl = (l+dl)/rd;
    rh = h+dh;

    XPUSHs(sv_2mortal(newSVnv(rb)));
    XPUSHs(sv_2mortal(newSVnv(rl)));
    XPUSHs(sv_2mortal(newSVnv(rh)));
