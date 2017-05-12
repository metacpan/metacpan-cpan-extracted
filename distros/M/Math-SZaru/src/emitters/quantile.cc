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

#include "emitters/szlquantile.h"

namespace SZaru {


template <>
QuantileEstimator<int32_t>* 
QuantileEstimator<int32_t>::Create(uint32_t numQuantiles) {
  return new QuantileEstimatorImpl<int32_t>(numQuantiles);
}

template <>
QuantileEstimator<int64_t>* 
QuantileEstimator<int64_t>::Create(uint32_t numQuantiles) {
  return new QuantileEstimatorImpl<int64_t>(numQuantiles);
}

template <>
QuantileEstimator<double>* 
QuantileEstimator<double>::Create(uint32_t numQuantiles) {
  return new QuantileEstimatorImpl<double>(numQuantiles);
}

}
