// Copyright 2010 Google Inc.
// Modified by Yuji Kaneda
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

// Implementation of SzlTabWriter and SzlTabEntry for unique tables in Sawzall.
// Structure for calculating the number of unique elements.
// The technique used is:
// 1) Convert all elements to unique evenly spaced hash keys.
// 2) Keep track of the smallest N element ("nelems") of these elements.
// 3) "nelems" cannot glow beyond maxelems.
// 4) Based on the coverage of the space, compute an estimate
//    of the total number of unique elements, where biggest-small-elem
//    means largest element among kept "maxelems" elements.
//    unique = nelems < maxelems
//           ? nelems
//           : (maxelems << bits-in-hash) / biggest-small-elem

#include <stdint.h>
#include <stdio.h>
#include <string>
#include <vector>

#include "public/porting.h"
// #include "public/logging.h"
#include "public/hashutils.h"
#include "public/hash_set.h"

#include "szaru.h"

namespace SZaru {


class UniqueEstimatorImpl: public UniqueEstimator{
public:
  explicit UniqueEstimatorImpl(int param)
    : tot_elems_(0),
      heap_(),
      exists_(10),   // STL defaults to 100 buckets, which is a lot.
      maxElems_(param),
      isSorted_(false) {
  }  

  void AddElem(const std::string& elm);

  void AddElemInCIF(const char *data, size_t size);
  
  int64 Estimate() const;

  // ToDo: move to super class
  // Get the number of elements added to this entry in the table.
  uint64 TotElems() const { return tot_elems_; }
  
private:
  // type of hash values kept.
  typedef uint64 HashVal;
  
  static HashVal PackUniqueHash(const uint8* mem);
  static void UnpackUniqueHash(HashVal hash, uint8* mem);

  int AddHash(HashVal hash);

  void FixHeapUp(int h);
  void FixHeapDown(int h, int nheap);
  
  template <typename T>
  struct identity {
    inline const T& operator()(const T& t) const { return t; }
  };

  // ToDo: move to super class
  // Total elements added to this entry in the sum table.
  uint64 tot_elems_;

  std::vector<HashVal> heap_;
  
  // This also keeps only smallest "maxElems_" elements.
  typedef hash_set<HashVal, identity<HashVal> > Exists;
  Exists exists_;
  
  // Size of the hash we keep.
  static const int kHashSize = 24;

  // Max elements we keep track of.
  // This needs to be a constant to maintain estimate accuracy.
  const uint32 maxElems_;

  // Is heap_ actually a sorted array, biggest to smallest?
  bool isSorted_;
};

UniqueEstimator *
UniqueEstimator::Create(int maxElems) {
  return new UniqueEstimatorImpl(maxElems);
}

inline UniqueEstimatorImpl::HashVal
UniqueEstimatorImpl::PackUniqueHash(const uint8* mem) {
  uint32 hhi = (mem[0] << 24) | (mem[1] << 16) | (mem[2] << 8) | mem[3];
  uint32 hlo = (mem[4] << 24) | (mem[5] << 16) | (mem[6] << 8) | mem[7];
  uint64 h = hhi;
  return (h << 32) | hlo;
}


inline void
UniqueEstimatorImpl::UnpackUniqueHash(HashVal hash, uint8* mem) {
  uint32 hhi = hash >> 32;
  uint32 hlo = hash;
  mem[0] = hhi >> 24;
  mem[1] = hhi >> 16;
  mem[2] = hhi >> 8;
  mem[3] = hhi;
  mem[4] = hlo >> 24;
  mem[5] = hlo >> 16;
  mem[6] = hlo >> 8;
  mem[7] = hlo;
}

void UniqueEstimatorImpl::AddElem(const std::string& elem)
{
  uint8 digest[MD5_DIGEST_LENGTH];
  
  MD5Digest(elem.data(), elem.size(), &digest);
  AddHash(PackUniqueHash(digest));
}

void UniqueEstimatorImpl::AddElemInCIF(const char *data, size_t size)
{
  uint8 digest[MD5_DIGEST_LENGTH];
  
  MD5Digest(data, size, &digest);
  AddHash(PackUniqueHash(digest));
}

int UniqueEstimatorImpl::AddHash(HashVal hash) {
  ++tot_elems_;
  if (maxElems_ <= 0)
    return 0;

  // Add it only if it isn't already there.
  if (exists_.find(hash) != exists_.end())
    return 0;

  // Add it if the heap isn't full.
  if (heap_.size() < maxElems_) {
    // int memory = Memory();
    isSorted_ = false;
    heap_.push_back(hash);
    FixHeapUp(heap_.size() - 1);
    exists_.insert(hash);
    // return Memory() - memory;
    return 0;
  } else if (hash < heap_[0]) {
    // Otherwise, replace the biggest of stored if the new value is smaller.
    isSorted_ = false;
    exists_.erase(heap_[0]);               ;
    heap_[0] = hash;
    FixHeapDown(0, heap_.size());
    exists_.insert(hash);
    return 0;
  }
  return 0;
}

// Move an element up the heap to its proper position.
void UniqueEstimatorImpl::FixHeapUp(int h) {
  if (h >= 0 && (uint32)h < heap_.size()) {
    HashVal e = heap_[h];

    while (h != 0) {
      int parent = (h - 1) >> 1;
      HashVal pe = heap_[parent];
      if (!(e > pe))
        break;
      heap_[h] = pe;
      h = parent;
    }
    heap_[h] = e;
  } else {
    fputs("heap error in unique table\n", stderr);
  }
}

// Move an element down the heap to its proper position.
void UniqueEstimatorImpl::FixHeapDown(int h, int nheap) {
  if (h >= 0 && h < nheap) {
    HashVal e = heap_[h];
    for (;;) {
      int kid = (h << 1) + 1;
      if (kid >= nheap)
        break;
      HashVal ke = heap_[kid];
      if (kid + 1 < nheap) {
        HashVal ke1 = heap_[kid + 1];
        if (ke1 > ke) {
          ke = ke1;
          ++kid;
        }
      }
      if (!(ke > e))
        break;
      heap_[h] = ke;
      h = kid;
    }
    heap_[h] = e;
  } else {
    fputs("heap error in unique table\n", stderr);
  }
}


// Estimate the number of unique entries.
// estimate = (maxelems << bits-in-hash) / biggest-small-elem
int64 UniqueEstimatorImpl::Estimate() const {
  if (maxElems_ <= 0) {
    return 0;
  }
  if (heap_.size() < maxElems_) {
    return heap_.size();
  }

  // The computation is a 64bit / 32bit, which will have
  // approx. msb(num) - msb(denom) bits of precision,
  // where msb is the most significant bit in the value.
  // We try to make msb(num) == 63, 24 <= msb(denom) < 32,
  // which gives about 32 bits of precision in the intermediate result,
  // and then rescale.
  //
  // Strip leading zero bytes to maintain precision.
  // Do this by byte to maintain same estimate.
  uint8 unpacked[MD5_DIGEST_LENGTH];
  UnpackUniqueHash(heap_[0], unpacked);
  int z = 0;
  // Number of leading denom. bytes of zeros stripped.
  for (; z < MD5_DIGEST_LENGTH; ++z) {
    if (unpacked[z]) {
      break;
    }
  }
  uint32 biggestsmall = (unpacked[z] << 24) | (unpacked[z + 1] << 16)
                      | (unpacked[z + 2] << 8) | unpacked[z + 3];
  if (biggestsmall == 0) {
    biggestsmall = 1;
  }
  int msbnum = Log2Int(heap_.size());
  uint64 r = (static_cast<uint64>(heap_.size() << (31 - msbnum)) << 32)
      / biggestsmall;

  int renorm = z * 8 - (31 - msbnum);
  if (renorm < 0) {
    r >>= -renorm;
  } else {
    // Make sure we don't overflow.
    // This test isn't strictly an overflow test, but assures that r
    // won't be bigger than the max acceptable value afer normalization.
    if (r > (TotElems() >> renorm))
      return TotElems();
    r <<= renorm;
  }
  // Although this will introduce skew, never generate an estimate larger
  // than total elements added to the table.
  if (r > TotElems()) {
    return TotElems();
  }
  return r;
}

}
