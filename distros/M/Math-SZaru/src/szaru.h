// Copyright 2010 Yuji Kaneda
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//      http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// ------------------------------------------------------------------------

/*!
  @mainpage SZaru: Porting of excellent Sawzall aggregators.

  <h2>Overview</h2>
  
  SZaru is a library to use <a href="http://code.google.com/p/szl/">Sawzall</a> aggregators 
  in pure C++, Ruby and Python.
  Currently, I have implemented the following 3 aggregators:
      <dl>
	<dt>Top</dt>
	<dd>
	  Statistical samplings that record the 'top N' data items
	  based on CountSketch algorithm from "Finding Frequent Items in Data Streams",
	  Moses Charikar, Kevin Chen and Martin Farach-Colton, 2002.
	</dd>

	<dt>Unique</dt>
	<dd>
	  Statistical estimators for the total number of unique data items.
	</dd>

	<dt>Quantile</dt>
	<dd>
	  Approximate N-tiles for data items from an ordered domain based on 
	  the following paper:
	  Munro &amp; Paterson, "Selection and Sorting with Limited Storage",
          Theoretical Computer Science, Vol 12, p 315-323, 1980.
	</dd>
      </dl>

  <h2>Example</h2>
<pre>#include <iostream> 
#include <szaru.h>                              
using namespace std;
using namespace SZaru;                                                       

TopEstimator<int32_t> *topEst = TopEstimator<int32_t>::Create(3);                                         
topEst->AddWeightedElem("abc", 1);                                                                        
topEst->AddWeightedElem("def", 2);                                                                        
topEst->AddWeightedElem("ghi", 3);                                                                        
topEst->AddWeightedElem("def", 4);                                                                        
topEst->AddWeightedElem("jkl", 5);
                                                                    
vector< TopEstimator<int32_t>::Elem > topElems;                                                           
topEst->Estimate(topElems);
                                                                              
cout << topElems[0].value << ", " << topElems[0].weight << endl; // => def, 6                                 
cout << topElems[1].value << ", " << topElems[1].weight << endl; // => jkl, 5                             
cout << topElems[2].value << ", " << topElems[2].weight << endl; // => ghi, 3
                                       
delete topEst;          
</pre>

  <h2 id="license">License</h2>
  <a href="http://www.apache.org/licenses/LICENSE-2.0">Apache License Version 2.0</a>
 */

#ifndef _SZARU_
#define _SZARU_

#include <stdint.h>
#include <string>
#include <vector>

namespace SZaru {
  
const char* const VERSION = "0.1.0";

//! Statistical estimators for the total number of unique data items.
/*!
  Structure for calculating the number of unique elements.

  The technique used is:
  - Convert all elements to unique evenly spaced hash keys.
  - Keep track of the smallest N element ("nElemes") of these elements.
  - "nelems" cannot glow beyond maxelems.
  - Based on the coverage of the space, compute an estimate
  of the total number of unique elements, where biggest-small-elem
  means largest element among kept "maxelems" elements.

  unique = nElemes < maxelems
  ? nElems
  : (maxelems << bits-in-hash) / biggest-small-elem
 */
class UniqueEstimator {
public:
  //! Create a UniqueEstimator object.
  /*!
    @param nElemes tuning parameter. If nElemes is bigger, the estimation becomes more accurate but consuming more memory.
   */
  static UniqueEstimator* Create(int nElemes);
  
  virtual ~UniqueEstimator() {};
  
  //! Add a new element to this entry.
  /*!
    @param elm element to add
   */
  virtual void AddElem(const std::string& elm) = 0;

  //! Add a new element to this entry in C sylte interface.
  /*!
    @param data element data
    @param size element size
   */
  virtual void AddElemInCIF(const char *data, size_t size) = 0;

  //! Estimate the number of unique entries.
  /*!
    @return the estimated number of unique entries.
  */
  virtual int64_t Estimate() const = 0;

  //! Get the number of elements added to this entry in the table.
  /*!
    @return the number of added elements
  */
  virtual uint64_t TotElems() const = 0;

protected:
  UniqueEstimator() {}
};

//! Statistical samplings that record the 'top N' data items.
/*!
  Note: Currently only 3 types (int32_t, int64_t, double) can be set to Value template.
  
  Statistical samplings that record the 'top N' data items
  based on CountSketch algorithm from "Finding Frequent Items in Data Streams",
  Moses Charikar, Kevin Chen and Martin Farach-Colton, 2002.
 */
template<typename Value>
class TopEstimator {
public:
  //! Create a TopEstimator object.
  /*!
    @param numTops number of top elements to be estimate.
  */
  static TopEstimator* Create(uint32_t numTops);
  
  virtual ~TopEstimator() {};

  //! Combination of a value & weight.
  struct Elem {
    std::string value;
    Value weight;
  };
  
  //! Add a new element to this entry.
  /*!
    @param elm element to add
   */
  virtual void AddElem(const std::string& elm) = 0;

  //! Add a new element with weight to this entry.
  /*!
    @param elm element to add
    @param weight weight of element
   */
  virtual void AddWeightedElem(const std::string& elem, Value weight) = 0;
  
  //! Estimate the number of top entries.
  /*!
    @param topElems estimated top entries
   */
  virtual void Estimate(std::vector<Elem>& topElems) = 0;
  
  //! Get the number of elements added to this entry in the table.
  /*!
    @return the number of added elements
  */
  virtual uint64_t TotElems() const = 0;

protected:
  TopEstimator() {}
};

//! Approximate N-tiles for data items from an ordered domain.
/*!
  Note: Currently only 3 types (int32_t, int64_t, double) can be set to Key template.
  
  Approximate N-tiles for data items from an ordered domain based on 
  the following paper:
  Munro &amp; Paterson, "Selection and Sorting with Limited Storage",
  Theoretical Computer Science, Vol 12, p 315-323, 1980.
 */
template <typename Key>
class QuantileEstimator {
public:
  //! Create a QuantileEstimator object.
  /*!
    @param numQuantiles number of tiles to be estimate.
  */
  static QuantileEstimator* Create(uint32_t numQuantiles);

  virtual ~QuantileEstimator() {};
  
  //! Add a new element to this entry.
  /*!
    @param elm element to add
   */  
  virtual void AddElem(const Key& elm) = 0;

  //! Estimate the quantile entries.
  /*!
    @param output estimated quantile.
   */
  virtual void Estimate(std::vector<Key>& output) = 0;

  //! Get the number of elements added to this entry in the table.
  /*!
    @return the number of added elements
  */
  virtual uint64_t TotElems() const = 0;

protected:
  QuantileEstimator() {}
};




// template specialization
template <>
TopEstimator<int32_t>* 
TopEstimator<int32_t>::Create(uint32_t numTops);

template <>
TopEstimator<int64_t>* 
TopEstimator<int64_t>::Create(uint32_t numTops);

template <>
TopEstimator<double>* 
TopEstimator<double>::Create(uint32_t numTops);

template <>
QuantileEstimator<int32_t>* 
QuantileEstimator<int32_t>::Create(uint32_t numQuantiles);

template <>
QuantileEstimator<int64_t>* 
QuantileEstimator<int64_t>::Create(uint32_t numQuantiles);

template <>
QuantileEstimator<double>* 
QuantileEstimator<double>::Create(uint32_t numQuantiles);

}

#endif  //  _SZARU_
