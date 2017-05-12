/***************************************************************************
    Haar 2d transform implemented in C/C++ to speed things up
                             -------------------
    Implemented for imgSeek by nieder|at|mail.ru
    based off of
    ***************************************************************************
    *    Wavelet algorithms, metric and query ideas based on the paper        *
    *    Fast Multiresolution Image Querying                                  *
    *    by Charles E. Jacobs, Adam Finkelstein and David H. Salesin.         *
    *    <http://www.cs.washington.edu/homes/salesin/abstracts.html>          *
    ***************************************************************************
    Version from imgSeek Copyright (C) 2003 Ricardo Niederberger Cabral
    XS version derived & Copyright (C) 2005 Simon Cozens

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#include "EXTERN.h"
#include "perl.h"
#include <queue>
#include "haar.h"
#include <math.h> 
#include <stdio.h> 
#include <stdlib.h> 
                
inline double *absarray(double* a) {
  double * b;
  New(200, b, 16384, double);
  int i;
  for (i=0;i<16384;i++) b[i] = fabs(a[i]);
  return b;
}

inline void truncq(double* a,double* b,double limit,int* data) {
/* set every element on data to 0 (if < limit) or to a positive/negative int when abs(value) > limit.
   a is the absolute value of array b   
*/ 
  int i,c=0;
  Zero(data,40, int);
  for (i=0;i<16384;i++) {
    if (a[i]>limit) {
      if (b[i]>0) data[c]=i;
      else data[c]=-1*i;
      c++;
      if (c==40) { return; }
    }
  }
}
void transformChar(unsigned char* c1,unsigned char* c2,unsigned char* c3,double* a,double* b,double* c) {
  // do the Haar tensorial 2d transform itself
  // here input RGB data is on unsigned char arrays
  int i,h,j,k;
  double *d1, *d2, *d3, *Ab1, *Ab2, *Ab3;
  New(200, d1, 16384, double);
  New(200, d2, 16384, double);
  New(200, d3, 16384, double);
  New(200, Ab1, 128, double);
  New(200, Ab2, 128, double);
  New(200, Ab3, 128, double);

  /* RGB -> YIQ */
  for (i=0;i<16384;i++) {
    d1[i]=(c1[i]*0.299+c2[i]*0.587+c3[i]*0.114)/256.0;
    d2[i]=(c1[i]*0.596+c2[i]*(-0.274)+c3[i]*(-0.322))/256.0;
    d3[i]=(c1[i]*0.212+c2[i]*(-0.523)+c3[i]*0.311)/256.0;
  }
  // decompose rows
  for (i=0;i<128;i++) {
    h=128;
    for (j=0;j<128;j++) {
      d1[i*128+j] /= 11.314;
      d2[i*128+j] /= 11.314;
      d3[i*128+j] /= 11.314;      
    }
    while(h>1) {
      h/=2;
      for (k=0;k<h;k++) {
        Ab1[k]=(d1[i*128+2*k]+d1[i*128+2*k+1])/1.414;
        Ab2[k]=(d2[i*128+2*k]+d2[i*128+2*k+1])/1.414;
        Ab3[k]=(d3[i*128+2*k]+d3[i*128+2*k+1])/1.414;
        
        Ab1[k+h]=(d1[i*128+2*k]-d1[i*128+2*k+1])/1.414;
        Ab2[k+h]=(d2[i*128+2*k]-d2[i*128+2*k+1])/1.414;
        Ab3[k+h]=(d3[i*128+2*k]-d3[i*128+2*k+1])/1.414;
      }
      memcpy(d1+i*128,Ab1,2*h*sizeof(double));
      memcpy(d2+i*128,Ab2,2*h*sizeof(double));
      memcpy(d3+i*128,Ab3,2*h*sizeof(double));
    }
  }
  // decompose cols
  for (i=0;i<128;i++) {
    h=128;
    for (j=0;j<128;j++) {
      d1[j*128+i] /= 11.314;
      d2[j*128+i] /= 11.314;
      d3[j*128+i] /= 11.314;      
    }
    while(h>1) {
      h/=2;
      for (k=0;k<h;k++) {
        Ab1[k]=(d1[i+2*k*128]+d1[i+(2*k+1)*128])/1.414;
        Ab2[k]=(d2[i+2*k*128]+d2[i+(2*k+1)*128])/1.414;
        Ab3[k]=(d3[i+2*k*128]+d3[i+(2*k+1)*128])/1.414;
        
        Ab1[k+h]=(d1[i+2*k*128]-d1[i+(2*k+1)*128])/1.414;
        Ab2[k+h]=(d2[i+2*k*128]-d2[i+(2*k+1)*128])/1.414;
        Ab3[k+h]=(d3[i+2*k*128]-d3[i+(2*k+1)*128])/1.414;
      }
      for (j=0;j<2*h;j++) {
        d1[j*128+i]=Ab1[j];
        d2[j*128+i]=Ab2[j];
        d3[j*128+i]=Ab3[j];
      }
    }
  }
  memcpy(a,d1,16384*sizeof(double));
  memcpy(b,d2,16384*sizeof(double));
  memcpy(c,d3,16384*sizeof(double));
  Safefree(d1);Safefree(d2);Safefree(d3);
  Safefree(Ab1);Safefree(Ab2);Safefree(Ab3);
}

void transform(double* a,double* b,double* c) {
  // do the Haar tensorial 2d transform itself
  // here input RGB data is on double char arrays
  int i,h,j,k;
  double *d1, *d2, *d3, *Ab1, *Ab2, *Ab3;
  New(200, d1, 16384, double);
  New(200, d2, 16384, double);
  New(200, d3, 16384, double);
  New(200, Ab1, 128, double);
  New(200, Ab2, 128, double);
  New(200, Ab3, 128, double);
  /* RGB -> YIQ */
  for (i=0;i<16384;i++) {
    d1[i]=(a[i]*0.299+b[i]*0.587+c[i]*0.114)/256.0;
    d2[i]=(a[i]*0.596+b[i]*(-0.274)+c[i]*(-0.322))/256.0;
    d3[i]=(a[i]*0.212+b[i]*(-0.523)+c[i]*0.311)/256.0;
  }
  // decompose rows
  for (i=0;i<128;i++) {
    h=128;
    for (j=0;j<128;j++) {
      d1[i*128+j] /= 11.314;
      d2[i*128+j] /= 11.314;
      d3[i*128+j] /= 11.314;      
    }
    while(h>1) {
      h/=2;
      for (k=0;k<h;k++) {
        Ab1[k]=(d1[i*128+2*k]+d1[i*128+2*k+1])/1.414;
        Ab2[k]=(d2[i*128+2*k]+d2[i*128+2*k+1])/1.414;
        Ab3[k]=(d3[i*128+2*k]+d3[i*128+2*k+1])/1.414;
        
        Ab1[k+h]=(d1[i*128+2*k]-d1[i*128+2*k+1])/1.414;
        Ab2[k+h]=(d2[i*128+2*k]-d2[i*128+2*k+1])/1.414;
        Ab3[k+h]=(d3[i*128+2*k]-d3[i*128+2*k+1])/1.414;
      }
      memcpy(d1+i*128,Ab1,2*h*sizeof(double));
      memcpy(d2+i*128,Ab2,2*h*sizeof(double));
      memcpy(d3+i*128,Ab3,2*h*sizeof(double));
    }
  }
  // decompose cols
  for (i=0;i<128;i++) {
    h=128;
    for (j=0;j<128;j++) {
      d1[j*128+i] /= 11.314;
      d2[j*128+i] /= 11.314;
      d3[j*128+i] /= 11.314;      
    }
    while(h>1) {
      h/=2;
      for (k=0;k<h;k++) {
        Ab1[k]=(d1[i+2*k*128]+d1[i+(2*k+1)*128])/1.414;
        Ab2[k]=(d2[i+2*k*128]+d2[i+(2*k+1)*128])/1.414;
        Ab3[k]=(d3[i+2*k*128]+d3[i+(2*k+1)*128])/1.414;
        
        Ab1[k+h]=(d1[i+2*k*128]-d1[i+(2*k+1)*128])/1.414;
        Ab2[k+h]=(d2[i+2*k*128]-d2[i+(2*k+1)*128])/1.414;
        Ab3[k+h]=(d3[i+2*k*128]-d3[i+(2*k+1)*128])/1.414;
      }
      for (j=0;j<2*h;j++) {
        d1[j*128+i]=Ab1[j];
        d2[j*128+i]=Ab2[j];
        d3[j*128+i]=Ab3[j];
      }
    }
  }
  memcpy(a,d1,16384*sizeof(double));
  memcpy(b,d2,16384*sizeof(double));
  memcpy(c,d3,16384*sizeof(double));
  Safefree(d1);Safefree(d2);Safefree(d3);Safefree(Ab1);Safefree(Ab2);Safefree(Ab3);
}

int calcHaar(double* cdata1,double* cdata2,double* cdata3,int* sig1,int* sig2,int* sig3,double * avgl)
{
  //TODO: Speed up..
  int cnt,i;
  valStruct vals[41];

  double * cadata1=absarray(cdata1);
  double * cadata2=absarray(cdata2);
  double * cadata3=absarray(cdata3);

  avgl[0]=cdata1[0];
  avgl[1]=cdata2[0];
  avgl[2]=cdata3[0];
  // determines the 40th largest absolute value. For each color channel
  valqueue  vq;
  cnt=0;
  for (i=0;i<16384;i++) {
    if (cnt==40) {
      vals[40].d=cadata1[i];
      vq.push(vals[40]);
      vals[40]=vq.top();
      vq.pop();
    }
    else {
      vals[cnt].d=cadata1[i];
      vq.push(vals[cnt]);
      cnt++;
    }
  }
  truncq(cadata1,cdata1,vq.top().d,sig1);

  while(!vq.empty()) vq.pop();
  cnt=0;
  for (i=0;i<16384;i++) {
    if (cnt==40) {
      vals[40].d=cadata2[i];
      vq.push(vals[40]);
      vals[40]=vq.top();
      vq.pop();
    }
    else {
      vals[cnt].d=cadata2[i];
      vq.push(vals[cnt]);      
      cnt++;
    }
  }
  truncq(cadata2,cdata2,vq.top().d,sig2);

  while(!vq.empty()) vq.pop();
  cnt=0;
  for (i=0;i<16384;i++) {
    if (cnt==40) {
      vals[40].d=cadata3[i];
      vq.push(vals[40]);
      vals[40]=vq.top();
      vq.pop();
    }
    else {
      vals[cnt].d=cadata3[i];
      vq.push(vals[cnt]);      
      cnt++;
    }
  }
  truncq(cadata3,cdata3,vq.top().d,sig3);

  Safefree(cadata1);
  Safefree(cadata2);
  Safefree(cadata3);
  return 1;
}
