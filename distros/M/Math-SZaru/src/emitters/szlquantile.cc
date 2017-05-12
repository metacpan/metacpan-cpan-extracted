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

// Implements szl table structure for storing approximate quantiles
// in a table.  The implementation is based on the following paper:
//
// [MP80]  Munro & Paterson, "Selection and Sorting with Limited Storage",
//         Theoretical Computer Science, Vol 12, p 315-323, 1980.
//    More info available at
//    http://scholar.google.com/scholar?q=munro+paterson
//
// The above paper is not available online. You could read a detailed
// description of the same algorithm here:
//
// [MRL98] Manku, Rajagopalan & Lindsay, "Approximate Medians and other
//         Quantiles in One Pass and with Limited Memory", Proc. 1998 ACM
//         SIGMOD, Vol 27, No 2, p 426-435, June 1998.
//
// Also see  the following paper by Greenwald and Khanna, which contains
// another implementation that is thought to be slower:
// M. Greenwald and S. Khanna. Space-efficient online computation of
// quantile summerles. SIGMOD'01, pp. 58-66, Santa Barbara, CA, May
// 2001.
//
// Brief description of Munro-Paterson algorithm
// =============================================
// Imagine a binary tree of buffers. Every buffer has size "k". Now imagine
// populating the leaves of the tree (from left to right) with the input
// stream.  Munro-Paterson is very simple: As soon as both children of a
// buffer are full, we invoke a Collapse() operation.  What is a Collapse()?
// Basically, we take two buffers of size "k" each, sort them together and pick
// every other element in the sorted sequence. That's it!
//
// When the input stream runs dry, we would have populated some "b" buffers at
// various levels by following the Munro-Paterson algorithm.  How do we compute
// 100 quantiles from these "b" buffers? Assign a "weight" of 2^i to every
// element of a buffer at level i (leaves are at level 0).  Now sort all the
// elements (in various buffers) together. Then compute the "weighted 100
// splitters" of this sequence. Please see the code below or the paper above for
// furthe details.

#include <math.h>
#include <algorithm>

#include "public/porting.h"
// #include "public/logging.h"

namespace SZaru {
// We compute the "smallest possible k" satisfying two inequalities:
//    1)   (b - 2) * (2 ^ (b - 2)) + 0.5 <= epsilon * MAX_TOT_ELEMS
//    2)   k * (2 ^ (b - 1)) \geq MAX_TOT_ELEMS
//
// For an explanation of these inequalities, please read the Munro-Paterson or
// the Manku-Rajagopalan-Linday papers.
template<typename Key>
int64 QuantileEstimatorImpl<Key>::ComputeK() {
  const double epsilon = 1.0 / (num_quantiles_ - 1);
  int b = 2;
  while ((b - 2) * (0x1LL << (b - 2)) + 0.5 <= epsilon * MAX_TOT_ELEMS) {
    ++b;
  }
  const int64 k = MAX_TOT_ELEMS / (0x1LL << (b - 1));
  // VLOG(2) << StringPrintf(
  // "ComputeK(): returning k = %lld for num_quantiles_ = %d (epsilon = %f)",
  // k, num_quantiles_, epsilon);
  return k;
}


// If buffer_[level] already exists, do nothing.
// Else create a new buffer_[level] that is empty.
template<typename Key>
void QuantileEstimatorImpl<Key>::EnsureBuffer(const int level) {
  // int extra_memory = 0;
  if (buffer_.size() < static_cast<size_t>(level) + 1) {
    // size_t old_capacity = buffer_.capacity();
    buffer_.resize(level + 1, NULL);
    // extra_memory +=
    // (buffer_.capacity() - old_capacity) * sizeof(vector<string>*);
  }
  if (buffer_[level] == NULL) {
    // VLOG(2) << StringPrintf("Creating buffer_[%d] ...", level);
    buffer_[level] = new vector<Key>();
    // extra_memory += sizeof(*(buffer_[level]));
  }
  // return extra_memory;
}

// For Collapse(), both "a" and "b" should be vectors of length "k_".
// Conceptually, Collapse() combines "a" and "b" into a single vector, sorts
// this vector and then chooses every other member of this vector.
// The result is stored in "output".
//
// The return value is the change is memory requirements. What causes
// increase/decrease in memory?  (i) "output" is populated and (ii) just before
// returning, both "a" and "b" are cleared.
template<typename Key>
void QuantileEstimatorImpl<Key>::Collapse(vector<Key> *const a,
                                            vector<Key> *const b,
                                            vector<Key> *const output) {
  // CHECK_EQ(a->size(), k_);
  // CHECK_EQ(b->size(), k_);
  // CHECK_EQ(output->size(), 0);

  // int memory_delta = 0;
  int index_a = 0;
  int index_b = 0;
  int count = 0;
  const Key* smaller;

  while (index_a < k_ || index_b < k_) {
    if (index_a >= k_ || (index_b < k_ && a->at(index_a) >= b->at(index_b))) {
      smaller = &(b->at(index_b++));
    } else {
      smaller = &(a->at(index_a++));
    }

    if ((count++ % 2) == 0) {  // remember "smallest"
      output->push_back(*smaller);
    } else {  // forget "smallest"
      // memory_delta -= smaller->size();
    }
  }

  // Account for the memory taken by output and a & b.
  // memory_delta += (output->capacity() - a->capacity() - b->capacity())
  // * sizeof(string);

  // Make sure we completely deallocate the memory taken by a & b.
  {
    vector<Key> tmp;
    a->swap(tmp);
  }
  {
    vector<Key> tmp;
    b->swap(tmp);
  }

  // return memory_delta;
}

// Algorithm for RecursiveCollapse():
//
// 1. Let "merged" denote the output of Collapse("buf", "buffer_[level]")
//
// 2. If "buffer_[level + 1]" is full (i.e., already exists)
//      Collapse("merged", "buffer_[level + 1]")
//    else
//      "buffer_[level + 1]"  <-- "merged"
//
// The return value is the difference in memory usage.
template<typename Key>
void QuantileEstimatorImpl<Key>::RecursiveCollapse(vector<Key> *buf,
                                                     const int level) {
  // VLOG(2) << StringPrintf("RecursiveCollapse() invoked with level = %d", level);

  // CHECK_EQ(buf->size(), k_);
  // CHECK_GE(level, 1);
  // CHECK_GE(buffer_.size(), level + 1);
  // CHECK(buffer_[level] != NULL);
  // CHECK_EQ(buffer_[level]->size(), k_);

  // int memory_delta = EnsureBuffer(level + 1);
  EnsureBuffer(level + 1);

  vector<Key> *merged;
  if (buffer_[level + 1]->size() == 0) {  // buffer_[level + 1] is empty
    merged = buffer_[level + 1];
  } else {                                // buffer_[level + 1] is full
    merged = new vector<Key>;
    // merged is going to be filled with k_ elements we might as well
    // reserve the space now.
    merged->reserve(k_);
  }
  // We account for the memory taken by merged even if it's a
  // temporary vector, since in this case it will be passed to
  // RecursiveCollapse, which will substract the memory it takes.
  // memory_delta += Collapse(buffer_[level], buf, merged);
  Collapse(buffer_[level], buf, merged);
  if (buffer_[level + 1] == merged) {
    // return memory_delta;
    return;
  }
  //memory_delta += RecursiveCollapse(merged, level + 1);
  RecursiveCollapse(merged, level + 1);
  delete merged;
  // return memory_delta;
}

// Goal: Add a new element ("elem" is a SzlEncoded value).
// Return value: "diff in memory usage".
//
// Algorithm:
//   if (buffer_[0] is not full (i.e., has less than k_ elements)) {
//       insert "elem" into buffer_[0]
//   } else if buffer_[1] is not full (i.e., has less than k_ elements) {
//       insert "elem" into "buffer_[1]"
//   } else {
//       Sort buffer_[0] and buffer_[1]
//       RecursiveCollapse(buffer_[0], buffer_[1])
//       Insert into buffer_[0]
//   }
template<typename Key>
void QuantileEstimatorImpl<Key>::AddElem(const Key& elem) {
  // int memory_delta = 0;

  // Update min_ and max_.
  if ((tot_elems_ == 0) || (elem < min_)) {
    // memory_delta += elem.size() - min_.size();
    min_ = elem;
    // VLOG(3) << "AddElem(" << elem << "): min_ updated to " << min_;
  }
  if ((tot_elems_ == 0) || (max_ < elem)) {
    // memory_delta += elem.size() - max_.size();
    max_ = elem;
    // VLOG(3) << "AddElem(" << elem << "): max_ updated to " << max_;
  }

  // First, test if both buffer_[0] and buffer_[1] are full.
  // This is equivalent to testing
  //    (tot_elems_ > 0)    &&   (tot_elems_ % (2 * k_) == 0).
  // If so, sort buffer_[0] and buffer_[1] and invoke RecursiveCollapse().
  // When RecursiveCollapse() returns, both buffer_[0] and buffer_[1] would be
  // "empty" (i.e., with zero elements in them).
  if ((tot_elems_ > 0) && (tot_elems_ % (2 * k_) == 0)) {
    // CHECK(buffer_[0] != NULL);
    // CHECK(buffer_[1] != NULL);
    // CHECK_EQ(buffer_[0]->size(), k_);
    // CHECK_EQ(buffer_[1]->size(), k_);
    // VLOG(2) << "AddElem(" << elem << "): Sorting buffer_[0] ...";
    sort(buffer_[0]->begin(), buffer_[0]->end());
    // VLOG(2) << "AddElem(" << elem << "): Sorting buffer_[1] ...";
    sort(buffer_[1]->begin(), buffer_[1]->end());
    const int level = 1;
    // RecursiveCollapse will start with Collapse(buffer_[0], buffer_[level]).
    // memory_delta += RecursiveCollapse(buffer_[0], level);
    RecursiveCollapse(buffer_[0], level);
  }

  // At this point, we are sure that either buffer_[0] or buffer_[1] can
  // accommodate "elem".
  //memory_delta += EnsureBuffer(0);
  //memory_delta += EnsureBuffer(1);
  EnsureBuffer(0);
  EnsureBuffer(1);
  // CHECK((buffer_[0]->size(), k_) || (buffer_[1]->size(), k_));
  int index = (buffer_[0]->size() < k_) ? 0 : 1;
  // VLOG(3) << "AddElem(" << elem << "): Inserting into buffer_[" << index << "]";
  // int old_capacity = buffer_[index]->capacity();
  buffer_[index]->push_back(elem);
  // memory_delta += elem.size()
  // + (buffer_[index]->capacity() - old_capacity) * sizeof(string);
  ++tot_elems_;
  // VLOG(3) << StringPrintf("AddElem(%s): returning with tot_elems_ = %lld",
  // elem.c_str(), tot_elems_);
  // return memory_delta;
}

// Imported from src/emitters/szlcomputequantiles.cc by Yuji Kaneda.
// 
// Please read the short description of the Munro-Paterson algorithm at the
// beginning of sawquantile.cc
//
// Basically, our goal is to compute quantiles from a bunch of buffers.
// We assign a "weight" of 2^i to every element of a buffer at
// level i in the binary tree (leaves are at level 0).  Now sort all the
// elements (in various buffers) together. Then compute the "weighted 100
// splitters" of this sequence.
template<typename Key>
void ComputeQuantiles(const vector<vector<Key>* >& buffer,
                      const Key& min_Key, const Key& max_Key,
                      size_t num_quantiles, int64 tot_elems,
                      vector<Key>* quantiles) {
  // CHECK(max_Key >= min_Key);
  // CHECK_GE(buffer.size(), 1);

  quantiles->clear();

  // VLOG(2) << "ComputeQuantiles(): min=" << min_Key;
  quantiles->push_back(min_Key);

  // buffer[0] and buffer[1] may be unsorted; all others are already sorted.
  if (buffer[0] == NULL) {
    // VLOG(2) << "ComputeQuantiles(): Not sorting buffer[0] (it is NULL).";
  } else {
    // VLOG(2) << "ComputeQuantiles(): Sorting buffer[0] ...";
    sort(buffer[0]->begin(), buffer[0]->end());
  }
  if ((buffer.size() < 2) || (buffer[1] == NULL)) {
    // VLOG(2) << "ComputeQuantiles(): Not sorting buffer[1] (it doesn't exist).";
  } else {
    // VLOG(2) << "ComputeQuantiles(): Sorting buffer[1] ...";
    sort(buffer[1]->begin(), buffer[1]->end());
  }

  // Simple sanity check: the weighted sum of all buffers should equal
  // "tot_elems".  The weight of buffer[i] is 2^(i-1) for i >= 2. Otherwise,
  // the weight is 1.
  // int64 t = 0;
  // for (int j = 0; j < buffer.size(); ++j) {
  // const int64 weight = (j <= 1) ? 1LL : (0x1LL << (j - 1));
  // t += (buffer[j] == NULL) ? 0 : (buffer[j]->size() * weight);
  // }
  // CHECK_EQ(t, tot_elems);

  vector<size_t> index(buffer.size(), 0);

  // Our goal is to identify the weighted "num_quantiles - 2" splitters in the
  // sorted sequence of all buffers taken together.
  // "S" will store the cumulative weighted sum so far.
  int64 S = 0;
  for (size_t i = 1; i <= num_quantiles - 2; ++i) {
    // Target "S" for the next splitter (next quantile).
    const int64 target_S
      = static_cast<int64>(ceil(i * (tot_elems / (num_quantiles - 1.0))));
    // CHECK_LE(target_S, tot_elems);

    while (true) {
      // Identify the smallest element among buffer_[0][index[0]],
      // buffer_[1][index[1]],  buffer_[2][index[2]], ...
      Key smallest = max_Key;
      int min_buffer_id = -1;
      for (size_t j = 0; j < buffer.size(); ++j) {
        if ((buffer[j] != NULL) && (index[j] < buffer[j]->size())) {
          if (!(smallest < buffer[j]->at(index[j]))) {
            smallest = buffer[j]->at(index[j]);
            min_buffer_id = j;
          }
        }
      }
      // CHECK_GE(min_buffer_id, 0);

      // Now increment "S" by the weight associated with "min_buffer_id".
      //
      // Note: The "weight" of elements in buffer[0] and buffer[1] is 1 (these
      //       are leaf nodes in the Munro-Paterson "tree of buffers".
      //       The weight of elements in buffer[i] is 2^(i-1) for i >= 2.
      int64 S_incr = (min_buffer_id <= 1) ? 1 : (0x1LL << (min_buffer_id - 1));

      // If we have met/exceeded "target_S", we have found the next quantile.
      // Then break the loop. Otherwise, just update index[min_buffer_id] and S
      // appropriately.
      if (S + S_incr >= target_S) {
        // CHECK(buffer[min_buffer_id]->at(index[min_buffer_id]) == smallest);
        quantiles->push_back(smallest);
        break;
      } else {
        ++index[min_buffer_id];
        S += S_incr;
      }
    }
  }

  // VLOG(2) << KeyPrintf("ComputeQuantiles(): max=%s", max_Key.c_str());
  quantiles->push_back(max_Key);
}

template<typename Key>
void QuantileEstimatorImpl<Key>::Estimate(vector<Key>& output) {
  output.clear();
  if (tot_elems_ == 0) {
    output.push_back(Key());
    return;
  }
  // We display the quantiles, not the raw output.
  ComputeQuantiles<Key>(buffer_, min_, max_, num_quantiles_, tot_elems_, &output);
}

}
