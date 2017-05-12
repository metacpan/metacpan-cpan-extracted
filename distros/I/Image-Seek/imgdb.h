/***************************************************************************
    imgSeek ::  databse C++ module
                             -------------------
    begin                : Fri Jan 17 2003
    email                : nieder|at|mail.ru
    Time-stamp:            <05/01/25 22:36:35 rnc>

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
***************************************************************************
*/

#ifndef IMGDBASE_H
#define IMGDBASE_H

float  weights[2][6][3]={
  {{5.00,19.21,34.37},{0.83,1.26,0.36},{1.01,0.44,0.45},{0.52,0.53,0.14},{0.47,0.28,0.18},{0.3 ,0.14,0.27}},
  {{4.04,15.14,22.62},{0.78,0.92,0.40},{0.46,0.53,0.63},{0.42,0.26,0.25},{0.41,0.14,0.15},{0.32,0.07,0.38}}
};        /* haar coefficients weight */

/* signature structure */
typedef struct sigStruct_{
  int* sig1;
  int* sig2;
  int* sig3;  
  long int id;
  double * avgl;
  double  score;               /* used when doing queries */
  /* image properties extracted when opened for the first time */

 bool operator< (const sigStruct_ & right) const {
  return score < (right.score);
 }

} sigStruct;

struct cmpf
{
  bool operator()(const long int s1, const long int s2) const
  {
    return s1<s2;
  }
};

int  imgBin[16384];
typedef std::map<const long int, sigStruct*, cmpf>::iterator sigIterator;
typedef std::list<long int> long_list;
typedef long_list::iterator long_listIterator;
typedef std::priority_queue < sigStruct > priqueue;
typedef std::list<long_list> long_list_2; /* a list of lists */

typedef std::map<const long int, sigStruct*, cmpf> sigMap;
sigMap sigs;
long_list imgbuckets[3][2][16384];
priqueue  pqResults;            /* results priority queue */
sigStruct curResult;            /* current result waiting to be returned */
int numres;                     /* number of results found */

// Misc functions
int hasImageMagick(void);
// Functions only available with imgmagick:
#ifdef ImMagick
int convert(char* f1,char* f2);
int magickThumb(char* f1,char* f2);
#endif

#endif
