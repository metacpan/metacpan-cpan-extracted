/******************************************************************************
    imgSeek ::  C++ database implementation
    ---------------------------------------
    begin                : Fri Jan 17 2003
    email                : nieder|at|mail.ru

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
******************************************************************************/

/* STL Includes */
#include <map>
#include <queue>
#include <list>
#include <fstream>
#include <iostream>
// NOTE: when running build-ext.sh (auto swig wrappers) this namespace line has to be commented
using namespace std;

/* imgSeek includes */
#include "haar.h"
/* Database */
#include "imgdb.h"
/* C Includes */
#include <math.h>
#include <stdio.h>
#include "EXTERN.h"
#include "perl.h"

void removeID(long int id) {
  if (!sigs.count(id)) {
      return;
  }
  delete sigs[id];
  sigs.erase(id);
  for (int c = 0;c<3;c++)
    for (int pn=0;pn<2;pn++)
      for (int i = 0;i<16384;i++)
        imgbuckets[c][pn][i].remove(id);
}

void cleardb() {
  for (sigIterator it = sigs.begin(); it != sigs.end(); it++) {
    free((*it).second->sig1);
    free((*it).second->sig2);
    free((*it).second->sig3);
    free((*it).second->avgl);
    delete (*it).second;
  }
  sigs.clear();
  for (int c = 0;c<3;c++)  for (int pn=0;pn<2;pn++)
    for (int i = 0;i<16384;i++) {
      imgbuckets[c][pn][i].clear();
    }
}

int addImage(const long int id, unsigned char* red, unsigned char* green, unsigned char* blue) {
  /* id is a unique image identifier
     filename is the image location
     thname is the thumbnail location for this image
     doThumb should be set to 1 if you want to save the thumbnail on thname
     Images with a dimension smaller than ignDim are ignored
  */
  double* avgl = (double*)safesysmalloc(3*sizeof(double));
  int* sig1;
  int* sig2;
  int* sig3;
  double* cdata1, * cdata2, * cdata3;
  int i;
  New(200, cdata1, 16384, double);
  New(200, cdata2, 16384, double);
  New(200, cdata3, 16384, double);

  New(200, sig1, 40, int);
  New(200, sig2, 40, int);
  New(200, sig3, 40, int);

  sigStruct* nsig = new sigStruct();
  nsig->sig1 = sig1;
  nsig->sig2 = sig2;
  nsig->sig3 = sig3;
  nsig->avgl = avgl;
  nsig->id = id;

  transformChar(red, green, blue, cdata1,cdata2,cdata3);

  sigs[id] = nsig;

  calcHaar(cdata1,cdata2,cdata3,sig1,sig2,sig3,avgl);
  for (i = 0;i<40;i++) {         // populate buckets
    if (sig1[i]>0) imgbuckets[0][0][sig1[i]].push_back(id);
    if (sig1[i]<0) imgbuckets[0][1][-sig1[i]].push_back(id);

    if (sig2[i]>0) imgbuckets[1][0][sig2[i]].push_back(id);
    if (sig2[i]<0) imgbuckets[1][1][-sig2[i]].push_back(id);

    if (sig3[i]>0) imgbuckets[2][0][sig3[i]].push_back(id);
    if (sig3[i]<0) imgbuckets[2][1][-sig3[i]].push_back(id);   
  }

  free(cdata1);
  free(cdata2);
  free(cdata3);

  return 1;
}

/* Data:
    buckets[3][2][16835]
    sigs (hash)
*/

int loaddb(char* filename) {
  std::ifstream f(filename, ios::binary);
  if (!f.is_open()) return 0;
  int sz,coef,c,k;
  long int id;

  // read buckets
  for ( c = 0;c<3;c++)  for (int pn=0;pn<2;pn++)
    for (int i = 0;i<16384;i++) {
      f.read ((char*)&(sz), sizeof(int) );
      for ( k = 0;k<sz;k++) {
        f.read ((char*)&(id), sizeof(long int) );
        imgbuckets[c][pn][i].push_back(id); 
      }
    }
  // read sigs
  f.read ((char*)&(sz), sizeof(int) );
  for ( k = 0;k<sz;k++) {
    f.read ((char*)&(id), sizeof(long int) );
    sigs[id] = new sigStruct();
    sigs[id]->id = id;
    sigs[id]->sig1 = (int*)(safesysmalloc(40*sizeof(int)));
    sigs[id]->sig2 = (int*)(safesysmalloc(40*sizeof(int)));
    sigs[id]->sig3 = (int*)(safesysmalloc(40*sizeof(int)));
    sigs[id]->avgl = (double*)safesysmalloc(3*sizeof(double));
    // sig
    for ( c = 0;c<40;c++) {
      f.read ((char*)&(coef), sizeof( int) );   
      sigs[id]->sig1[c] = coef;
      f.read ((char*)&(coef), sizeof( int) );   
      sigs[id]->sig2[c] = coef;
      f.read ((char*)&(coef), sizeof( int) );   
      sigs[id]->sig3[c] = coef;    
    }
    // avgl
    for ( c = 0;c<3;c++) {
      f.read ((char*)&(sigs[id]->avgl[c]), sizeof( double) );      
    }
  }
  f.close();
  return 1;
}

int savedb(char* filename) {
/*
  Serialization order:
  for each color {0,1,2}:
      for {positive,negative}:
          for each 128x128 coefficient {0-16384}:
              [int] bucket size (size of list of ids)
              for each id:
                  [long int] image id
  [int] number of images (signatures)
  for each image:
      [long id] image id
      for each sig coef {0-39}:  (the 40 greatest coefs)
          for each color {0,1,2}:
              [int] coef index (signed)
      for each color {0,1,2}:
          [double] average luminance
      [int] image height

*/
  std::ofstream f(filename, ios::binary);
  if (!f.is_open()) return 0;
  int sz,c;
  long int id;
  // save buckets
  for ( c = 0;c<3;c++)  for (int pn=0;pn<2;pn++)
    for (int i = 0;i<16384;i++) {
      sz = imgbuckets[c][pn][i].size();
      f.write((char*)&(sz), sizeof(int) );
      for (long_listIterator it = imgbuckets[c][pn][i].begin(); it != imgbuckets[c][pn][i].end(); it++) {
        f.write ((char*)&((*it)), sizeof(long int) );
      }
    }
  // save sigs
  sz = sigs.size();
  f.write ((char*)&(sz), sizeof(int) );
  for (sigIterator it = sigs.begin(); it != sigs.end(); it++) {
    id = (*it).first;
    f.write ((char*)&(id), sizeof(long int));
    // sigs 
    for ( c = 0;c<40;c++) {
      f.write ((char*)&((*it).second->sig1[c]), sizeof( int));
      f.write ((char*)&((*it).second->sig2[c]), sizeof( int));
      f.write ((char*)&((*it).second->sig3[c]), sizeof( int));
    }
    // avgl
    for ( c = 0;c<3;c++) 
      f.write ((char*)&((*it).second->avgl[c]), sizeof(double));
  }
  f.close();
  return 1;
}

/* sig1,2,3 are int arrays of lenght 40 
   avgl is the average luminance
   numres is the max number of results
   scanned tells which set of weights to use
*/
void queryImgData(int* sig1,int* sig2,int* sig3,double * avgl,int numres,int scanned) {
  int idx,c;
  bool pn;
  int * sig[3] = {sig1,sig2,sig3};
  int nres = numres+1;
  int i,j;
  if (!imgBin[0]) {
      for (i = 0;i<128;i++) for (j=0;j<128;j++) imgBin[i*128+j] = min(max(i,j),5);
  }
  for (sigIterator sit = sigs.begin(); sit!=sigs.end(); sit++) { //#TODO3: do I really need to score every single sig on db?
    (*sit).second->score = 0;
    for (c = 0; c<3; c++) {
      (*sit).second->score += weights[scanned][0][c]*fabs((*sit).second->avgl[c]-avgl[c]);
    }
  }
  for (int b = 0;b<40;b++) {      // for every coef on a sig
    for ( c = 0;c<3;c++) {
      pn = 0;
      if (sig[c][b]>0) {
        pn = 0;
        idx = sig[c][b];
      } else {
        pn = 1;
        idx = -sig[c][b];
      }
      // update the score of every image which has this coef
      for (long_listIterator uit = imgbuckets[c][pn][idx].begin(); uit != imgbuckets[c][pn][idx].end(); uit++) {
        sigs[(*uit)]->score -= weights[scanned][imgBin[idx]][c];
      }
    }
  }
  while(!pqResults.empty()) pqResults.pop(); // make sure pqResults is empty. TODO: any faster way to empty it ? didn't find any on STL refs.
  int cnt = 0;
  for (sigIterator it = sigs.begin(); it != sigs.end(); it++) {
    cnt++;
    pqResults.push(*(*it).second);
    if (cnt>nres) {
      pqResults.pop();
    }     
  }
}

void queryImgID(long int id,int numres) {
  if (!sigs.count(id)) {
    return;
  }
  queryImgData(sigs[id]->sig1,sigs[id]->sig2,sigs[id]->sig3,sigs[id]->avgl, numres, 0);
}
