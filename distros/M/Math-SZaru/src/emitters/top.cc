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

#include "emitters/szltop.cc"

namespace SZaru {

template <>
TopEstimator<int32_t>* 
TopEstimator<int32_t>::Create(uint32_t numTops) {
  return new TopEstimatorImpl<int32_t>(numTops);
}

template <>
TopEstimator<int64_t>* 
TopEstimator<int64_t>::Create(uint32_t numTops) {
  return new TopEstimatorImpl<int64_t>(numTops);
}

template <>
TopEstimator<double>* 
TopEstimator<double>::Create(uint32_t numTops) {
  return new TopEstimatorImpl<double>(numTops);
}

}
