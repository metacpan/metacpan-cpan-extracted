using namespace SZaru;

#include <vector>

class PTopEstimator {
public:
  ~PTopEstimator()
  {
    delete t;
  }

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

  PQuantileEstimator(uint32_t numQuantiles)
  {
    q = SZaru::QuantileEstimator<double>::Create(numQuantiles);
  }
  
  void
  add_elem(const double& elm)
  {
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
