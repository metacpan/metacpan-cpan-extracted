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

// Implementation of SzlTabWriter and SzlTabEntry for top tables in Sawzall.
// This type is for estimating the most common entries based on the
// CountSketch algorithm from "Finding Frequent Items in Data Streams",
// Moses Charikar, Kevin Chen and Martin Farach-Colton.
// Most of the implementation is delegated to SzlTopHeap and SzlSketch.

#include <assert.h>
#include <string>
#include <vector>

#include "public/porting.h"
// #include "public/logging.h"

// #include "utilities/strutils.h"

// #include "public/szltype.h"
// #include "public/szlvalue.h"
// #include "public/szlencoder.h"
// #include "public/szldecoder.h"
// #include "public/szltabentry.h"

#include "emitters/szltopheap.h"
#include "emitters/szlsketch.h"

#include "szaru.h"

namespace SZaru {

template<typename Value>
class TopEstimatorImpl : public TopEstimator<Value> {
public:
  explicit TopEstimatorImpl(int param)
    : param_(param),
      sketch_(NULL),
      tops_(param * 10),
      totElems_(0) {
    SzlSketch<Value>::Dims(param * 100, &sketchTabs_, &sketchTabSize_);
    sketch_ = NULL;
  }
  ~TopEstimatorImpl()  { delete sketch_; }

  typedef typename TopEstimator<Value>::Elem Elem;
  
  virtual void AddElem(const string& elem) {
    return AddWeightedElem(elem, Value(static_cast<int64>(1)));
  }
  
  virtual void AddWeightedElem(const string& elem, Value weight);
  // virtual void Flush(string* output);
  // virtual void FlushForDisplay(vector<string>* output);
  // virtual SzlTabEntry::MergeStatus Merge(const string& vals);

  virtual void Estimate(std::vector<Elem>& topElems);

  // virtual void Clear() {
//     totElems_ = 0;
//     tops_.Clear();
//     if (sketch_ != NULL)
//       delete sketch_;
//     sketch_ = NULL;
//   }
  
  // virtual int Memory() {
  //     int memory_used =  sizeof(TopEstimatorImpl) + tops_.Memory();
  //     if (sketch_ != NULL) {
  //       memory_used += sketch_->Memory();
  //     }
  //     return memory_used;
  //   }
  
  virtual int TupleCount() {
    int ntops = tops_.nElems();
    return (param() > ntops) ? ntops : param();
  }
  
  // const SzlOps& weight_ops() const  { return weight_ops_; }
  int param() const  { return param_; }
  // const SzlValueCmp& less() const { return less_; }

  // Get the number of elements added to this entry in the table.
  uint64 TotElems() const { return totElems_; }

private:
  static const int kMaxTops = 1000;
  

  // const SzlOps& weight_ops_;
  const int param_;
  // const SzlValueLess less_;
  
  
  // Structure for keeping track of weights for elements not in the top.
  // Lazily allocated with an added element or non-empty merge.
  SzlSketch<Value>* sketch_;
  
  // Structure for keeping track of the current top elements.
  // TODO: Add an iterator for sorted output to improve
  // Flush performance.
  SzlTopHeap<Value> tops_;
  
  // Number and the size of tables in the sketch.
  int sketchTabs_;
  int sketchTabSize_;
  
  // Total elements ever added to this entry in the table.
  int64 totElems_;
};

  //  REGISTER_SZL_TAB_WRITER(top, SzlTop);


// SzlTabWriter* SzlTop::Create(const SzlType& type, string* error) {
//   if (type.weight() == NULL)
//     LOG(ERROR) << "Internal error - top table without weight";
//   if (!SzlOps::IsNumeric(type.weight()->type())) {
//     *error = "top tables must be weighted by an int, float, or tuple thereof";
//     return NULL;
//   }
//   if (type.param() > kMaxTops) {
//     *error = StringPrintf("top tables can't report more than %d elements",
//                           kMaxTops);
//     return NULL;
//   }
//   return new SzlTop(type);
// }

template <typename Value>
void TopEstimatorImpl<Value>::AddWeightedElem(const string& elem,
                                         Value w) {
  ++totElems_;
  if (!tops_.maxElems())
    return;
  
  // Is the element in list of candidate tops?
  typename SzlTopHeap<Value>::Elem* e = tops_.Find(elem);
  if (e != NULL)
    return tops_.AddToWeight(w, e);  // Just adjust weight in candidate list.

  // Always add the elements until we are full.
  if (tops_.nElems() != tops_.maxElems())
    return tops_.AddNewElem(elem, w);

  // Lazily allocate the sketch.
  // int mem = 0;
  if (sketch_ == NULL) {
    // sketch_ = new SzlSketch(weight_ops(), sketchTabs_, sketchTabSize_);
    sketch_ = new SzlSketch<Value>(sketchTabs_, sketchTabSize_);
    // mem += sketch_->Memory();
  }

  // Add its weight from the sketch.
  typename SzlSketch<Value>::Index index;
  sketch_->ComputeIndex(elem, &index);
  Value sw = 0;
  sketch_->Estimate(&index, &sw);
  Value tw;
  // weight_ops().Assign(w, &tw);
  // weight_ops().Add(sw, &tw);
  tw = w + sw;
  // Is it still smaller than the smallest candidate?
  typename SzlTopHeap<Value>::Elem* worst = tops_.Smallest();
  // if (weight_ops().Less(tw, worst->weight)) {
  if (tw < worst->weight) {
    // Yup.  Just adjust the weight in the sketch.
    sketch_->AddSub(&index, w, 1);
  } else {
    // Swap with the smallest candidate.
    sketch_->AddSub(&index, sw, 0);
    sketch_->ComputeIndex(worst->value, &index);
    sketch_->AddSub(&index, worst->weight, 1);
    // mem += tops_.ReplaceSmallest(elem, tw);
  }
  // weight_ops().Clear(&sw);
  // weight_ops().Clear(&tw);
  return;
}

template <typename Value>
void TopEstimatorImpl<Value>::Estimate(std::vector<Elem>& topElems) {
  topElems.clear();
  int nTopElems;
  if (static_cast<size_t>(param_) < tops_.nElems()) {
    nTopElems = param_;
  } else {
    // when the number of added elems is too small
    nTopElems = tops_.nElems();
  }
  topElems.reserve(nTopElems);

  // Note: After sorting, heap is destroyed, so can't call AddElem.
  tops_.Sort();
  for (int i = 0; i < nTopElems; ++i) {
    const typename SzlTopHeap<Value>::Elem* e = tops_.Element(i);
    Elem outputElem;
    outputElem.value = e->value;
    outputElem.weight = e->weight;
    topElems.push_back(outputElem);
  }
  // restore the heap
  tops_.ReHeap();
}

//   // Combine all of the counts and tags into a single sorted string.
//   SzlEncoder enc;
//   enc.PutInt(totElems_ - tops_.nElems());
//   enc.PutInt(tops_.nElems());
//   tops_.Sort();
//   for (int i = 0; i < tops_.nElems(); ++i) {
//     const SzlTopHeap::Elem* e = tops_.Element(i);
//     enc.PutBytes(e->value.data(), e->value.size());
//     weight_ops().Encode(e->weight, &enc);
//   }

//   if (sketch_ != NULL) {
//     enc.PutInt(sketch_->tabSize());
//     enc.PutInt(sketchTabs_);
//     sketch_->Encode(&enc);
//   } else {
//     enc.PutInt(0);
//     enc.PutInt(0);
//   }
//   enc.Swap(output);
//   Clear();
// }

// void TopEstimatorImpl::FlushForDisplay(vector<string>* output) {
//   output->clear();
//   if (totElems_ == 0) {
//     output->push_back("");
//     return;
//   }

//   tops_.Sort();
//   const int nerrs = weight_ops().nflats();
//   Value* err = new Value[nerrs];
//   if (sketch_ != NULL) {
//     sketch_->StdDeviation(err);
//   } else {
//     for (int i = 0; i < nerrs; ++i) {
//       err[i] = 0.;
//     }
//   }
//   SzlEncoder encerr;
//   for (int i = 0; i < nerrs; ++i) {
//     encerr.PutFloat(err[i]);
//   }
//   const int ntops = tops_.nElems();
//   const int nv = (param() > ntops)? ntops: param();
//   for (int i = 0; i < nv; ++i) {
//     SzlEncoder enc;
//     const SzlTopHeap::Elem* e = tops_.Element(i);
//     // Encoding code and decoding code does not match because "e->value" is
//     // already SawEncode'ed.SzlEncoder string handling relies on '\0' and
//     // does not allow more than one wrapping.
//     weight_ops().Encode(e->weight, &enc);
//     string buf(e->value);
//     buf += enc.data();
//     buf += encerr.data();
//     output->push_back(buf);
//   }
//   tops_.ReHeap();
//   delete[] err;
// }


// Merge another TopEstimatorImpl state into the current state.
// This is complicated by the fact that a candidate may be in only one list,
// with its count in the sketch in the other TopEstimatorImpl.
// Note: we may end up with some values which are not in either candidate list
// but whose value in the sketch exceeds the value of some elements in the
// candidate list. Nothing can be done about this, since we've intentionally
// lost the identity of all of the elements in the sketch.
//
// Steps are
// 1) For each current candidate, update its weight from the new sketch.
// 2) Add each new candidate element.
// 3) Merge sketches.
// SzlTabEntry::MergeStatus TopEstimatorImpl::Merge(const string& val) {
//   if (val.empty())
//     return MergeOk;
//   SzlDecoder dec(val.data(), val.size());
//   int64 extra;
//   if (!dec.GetInt(&extra))
//     return MergeError;
//   int64 nvals;
//   if (!dec.GetInt(&nvals))
//     return MergeError;

//   // Check for consistent params.
//   if (nvals > tops_.maxElems())
//     return MergeError;

//   // Check input validity.
//   for (int i = 0; i < nvals; ++i) {
//     if (!dec.Skip(SzlType::BYTES) || !weight_ops().Skip(&dec)) {
//       return MergeError;
//     }
//   }

//   // Parse the sketch when the source is not empty.
//   int64 nTabs, tabSize;
//   if (!dec.GetInt(&tabSize) || !dec.GetInt(&nTabs))
//     return MergeError;

//   // "nTabs > 0" means sketch exists in the source.
//   SzlSketch* newsketch = NULL;
//   if (nTabs) {
//     if (nTabs != sketchTabs_ || tabSize != sketchTabSize_)
//       return MergeError;
//     newsketch = new SzlSketch(weight_ops(), nTabs, tabSize);
//     if (!newsketch->Decode(&dec)) {
//       return MergeError;
//     }
//   } else if (tabSize) {
//     return MergeError;
//   }

//   if (!dec.done()) {
//     return MergeError;
//   }

//   // From this point on, we are committed, and can't recover previous state
//   // from an error.

//   // Adjust existing candidates' weights.
//   SzlValue w;
//   if (nTabs) {
//     for (int i = 0; i < tops_.nElems(); ++i) {
//       SzlTopHeap::Elem* e = tops_.Element(i);
//       assert(e != NULL);

//       // Add its weight from the sketch.
//       SzlSketch<Value>::Index index;
//       newsketch->ComputeIndex(e->value, &index);
//       newsketch->Estimate(&index, &w);
//       tops_.AddToWeight(w, e);
//       newsketch->AddSub(&index, w, 0);
//     }
//   }

//   // Add the new candidates.
//   dec.Restart();
//   for (int i = 0; i < 2; i++) {
//     if (!dec.Skip(SzlType::INT))
//       return MergeError;
//   }
//   for (int i = 0; i < nvals; ++i) {
//     string s;
//     if (!dec.GetBytes(&s) || !weight_ops().Decode(&dec, &w))
//       return MergeError;
//     AddWeightedElem(s, w);
//   }

//   // Combine the two sketches.
//   if (nTabs) {
//     if (sketch_ == NULL) {
//       sketch_ = newsketch;
//       newsketch = NULL;
//     } else {
//       sketch_->AddSketch(*newsketch);
//     }
//   }
//   weight_ops().Clear(&w);

//   totElems_ += extra;
//   if (newsketch != NULL)
//     delete newsketch;

//   return MergeOk;
// }

}
