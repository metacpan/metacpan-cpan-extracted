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

#ifndef _SZARU_TOPHEAP_
#define _SZARU_TOPHEAP_

#include <stdint.h>
#include <string>

namespace SZaru{

class TopHeap {
 public:
  // Combination of a value & weight.
  struct Elem {
    std::string value;
    double weight;

   private:
    friend class SzlTopHeap;
    int heap;           // position in heap for fixups on reweighting
  };

  static TopHeap* Create(int maxElems);
  
  virtual ~TopHeap() {};

  // Number of candidate biggest elements current held.
  virtual uint32_t nElems() const = 0;

  // Max. elements we ever hold.
  virtual uint32_t maxElems() const = 0;

  // Return an ordered element.
  // The elements are reordered by AddElem or Sort.
  // REQUIRES 0 <= i < nElems().
  virtual Elem* Element(int i) const = 0;

  // Find a candidate by value.  returns NULL if not present.
  // REQUIRES: created with hasFind.
  virtual Elem* Find(const std::string& s) = 0;

  // Add a new element to the heap.
  // REQUIRES: heap not full.
  virtual void AddNewElem(const std::string& value, const double w) = 0;

  // Add w to the weight of an existing candidate.
  virtual void AddToWeight(const double w, Elem* e)  = 0;

  // Replace the smallest candidate.
  // Returns the amount of extra memory allocated (or deallocated).
  virtual void ReplaceSmallest(const std::string& value, const double w)  = 0;

  // Return the candidate with the smallest value.
  virtual Elem* Smallest() const  = 0;

  // Sort in place so biggest element is first.
  // After sorting, !IsHeap, so can't call AddElem.
  virtual void Sort() = 0;

  // Reverses Sort() so smallest element is first.
  // This restores the heap as a side-effect.
  virtual void ReHeap() = 0;

  // Estimate memory currently allocated.
  // int Memory();

  // Validity check.
  virtual bool IsHeap() = 0;

  // Clear all stored elements.
  virtual void Clear() = 0;
  
};
}

#endif // _SZARU_TOPHEAP_
