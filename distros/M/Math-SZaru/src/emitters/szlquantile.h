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

#include <stdint.h>
#include <string>
#include <vector>

#include "szaru.h"

using namespace std;
// Structure for storing approx quantiles for each key in the table.
// Declared as: table quantile(N)[...] of value: <ordered sawtype>
// The parameter N (>=2) sets the relative error (eps_) that we are ready to
// tolerate. eps_ is set equal to 1/(N-1). This means that if
// there are "tot_elems_ " total emits to a particular key, then an
// element that we claim has rank X could have true rank in the range
// [X - eps_*tot_elems_, X + eps_*tot_elems_].

namespace SZaru {
  // The entry for each key inserted in a szl "table". If the
  // table is not indexed then there is only one entry
  // for the entire table.
  template<typename Key>
  class QuantileEstimatorImpl : public QuantileEstimator<Key> {
   public:
    explicit QuantileEstimatorImpl(int param)
      : tot_elems_(0),
	num_quantiles_(std::max(param, 2)) {
      k_ = ComputeK();
      Clear();
    }
    virtual ~QuantileEstimatorImpl() { Clear(); }
    
    virtual void AddElem(const Key& elem);
    // virtual void Flush(string* output);
    // virtual void FlushForDisplay(vector<string>* output);
    // virtual SzlTabEntry::MergeStatus Merge(const string& val);

    void Clear() {
      for (size_t i = 0; i < buffer_.size(); i++)
	delete buffer_[i];
      buffer_.clear();
      tot_elems_ = 0;
    }

    //     virtual int Memory();
    virtual uint64_t TotElems() const  { return tot_elems_; }
    virtual int TupleCount()  { return buffer_.size(); }

    virtual void Estimate(vector<Key>& output);

    // const SzlOps& element_ops() const  { return element_ops_; }

   private:
    // const SzlOps& element_ops_;

    // We support quantiles over a sequence of upto MAX_TOT_ELEMS = 1 Trillion
    // elements. The value of k_, the buffer-size in the Munro-Paterson algorithm
    // grows roughly logarithmically as MAX_TOT_ELEMS. So we set
    // MAX_TOT_ELEMS to a "large-enough" value, and not to kint64max.
    static const int64_t MAX_TOT_ELEMS = 1024LL * 1024LL * 1024LL * 1024LL;

    int64_t ComputeK();
    void EnsureBuffer(const int level);
    void Collapse(std::vector<Key> *const a, std::vector<Key> *const b,
                 std::vector<Key> *const output);
    void RecursiveCollapse(std::vector<Key> *buf, const int level);
    // bool EncodingToString(SzlDecoder *const dec, string *const output);
    
    uint64_t tot_elems_;
    const int num_quantiles_;  // #quantiles
    std::vector<std::vector<Key>* > buffer_;
    int64_t k_;  // max #elements in any buffer_[i]
    Key min_;
    Key max_;
  };

}

#include "emitters/szlquantile.cc"
