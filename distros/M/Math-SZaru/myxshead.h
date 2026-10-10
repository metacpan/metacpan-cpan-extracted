using namespace SZaru;

#include <vector>
#include <string>
#include <cmath>

static inline void check_szaru_constructor_param(SV *n_sv, double max_val, const char *name) {
  dTHX;
  if (!n_sv || !SvOK(n_sv) || (!SvIOK(n_sv) && !looks_like_number(n_sv)))
    croak("%s: parameter must be a positive integer", name);
  double n_dbl = SvNV(n_sv);
  if (n_dbl <= 0.0 || n_dbl > max_val || n_dbl != (double)(int64_t)n_dbl)
    croak("%s: parameter must be an integer between 1 and %ld", name, (long)max_val);
}

class PTopEstimator {
public:
  ~PTopEstimator()
  {
    delete t;
  }

  PTopEstimator(const PTopEstimator&) = delete;
  PTopEstimator& operator=(const PTopEstimator&) = delete;

  PTopEstimator(uint32_t numTops)
  {
    t = SZaru::TopEstimator<double>::Create(numTops);
  }

  void
  add_elem(const std::string& elm)
  {
    t->AddElem(elm);
  }

  void
  add_weighted_elem(const std::string& elem, double weight)
  {
    if (!std::isfinite(weight))
      croak("TopEstimator: weight must be a finite number (not NaN or Inf)");
    t->AddWeightedElem(elem, weight);
  }

  void
  estimate(std::vector< SZaru::TopEstimator<double>::Elem >& v)
  {
    t->Estimate(v);
  }

  uint64_t
  tot_elems()
  {
    return t->TotElems();
  }

private:
  SZaru::TopEstimator<double> *t;
};

class PQuantileEstimator {
public:
  ~PQuantileEstimator()
  {
    delete q;
  }

  PQuantileEstimator(const PQuantileEstimator&) = delete;
  PQuantileEstimator& operator=(const PQuantileEstimator&) = delete;

  PQuantileEstimator(uint32_t numQuantiles)
  {
    q = SZaru::QuantileEstimator<double>::Create(numQuantiles);
  }
  
  void
  add_elem(const double& elm)
  {
    if (!std::isfinite(elm))
      croak("QuantileEstimator: element must be a finite number (not NaN or Inf)");
    q->AddElem(elm);
  }

  uint64_t
  tot_elems()
  {
    return q->TotElems();
  }

  void
  estimate(std::vector< double >& output)
  {
    q->Estimate(output);
  }

private:
  SZaru::QuantileEstimator<double> *q;
};
