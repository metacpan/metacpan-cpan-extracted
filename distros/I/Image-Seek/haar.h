/***************************************************************************
    imgSeek ::  This file is the haar 2d transform implemented in C/C++ to speed things up
                             -------------------
    begin                : Fri Jan 17 2003
    email                : nieder|at|mail.ru
    Time-stamp:            <03/05/09 21:29:35 rnc>

    Copyright (C) 2003 Ricardo Niederberger Cabral
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
#ifndef HAAR_H
#define HAAR_H

/* signature structure */
typedef struct valStruct_{
  double  d;
 bool operator< (const valStruct_ & right) const {
  return d > (right.d);
 }

} valStruct;

typedef std::priority_queue < valStruct > valqueue;

#define max(a, b)  (((a) > (b)) ? (a) : (b))
#define min(a, b)  (((a) > (b)) ? (b) : (a))

void initImgBin();
void truncq(double* a,double* b,double limit,int* data);
void transform(double* a,double* b,double* c);
void transformChar(unsigned char* c1,unsigned char* c2,unsigned char* c3,double* a,double* b,double* c);
int calcHaar(double* cdata1,double* cdata2,double* cdata3,int* sig1,int* sig2,int* sig3,double * avgl);
double *absarray(double* a);

#endif
