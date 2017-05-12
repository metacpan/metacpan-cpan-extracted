#ifndef __ThinPlateSpline_h_
#define __ThinPlateSpline_h_

#include <boost/numeric/ublas/matrix.hpp>
#include <vector>
#include <exception>
#include <string>
#include <iostream>
#include "linalg3d.h"
#include "TPSException.h"

namespace TPS {
  class ThinPlateSpline {
  public:
    ThinPlateSpline(const std::vector<Vec>& controlPoints, const double regularization = 0.);
    ThinPlateSpline(std::istream& input); //< whatever was dumped by DumpAsString
    ThinPlateSpline(); //< for stl containers
    ~ThinPlateSpline() {};

    double Evaluate(const double x, const double y) const;
    std::vector<double> Evaluate(const std::vector<double>& x, const std::vector<double>& y) const;

    const std::vector<Vec>& GetControlPoints() const { return fControlPoints; }
    double GetRegularization() const { return fRegularization; }

    double GetBendingEnergy() const;
    void WriteToStream(std::ostream& stream) const;

  private:
    static double tps_base_func(double r);
    void InitializeMatrix();
    void DumpMatrix(std::ostream& stream, const boost::numeric::ublas::matrix<double>& matrix) const;
    boost::numeric::ublas::matrix<double> ReadMatrix(std::istream& in) const;

    double fRegularization;
    std::vector<Vec> fControlPoints;

    boost::numeric::ublas::matrix<double> fMtx_l;
    boost::numeric::ublas::matrix<double> fMtx_v;
    boost::numeric::ublas::matrix<double> fMtx_orig_k;
  };

  std::ostream& operator<<(std::ostream& stream, const ThinPlateSpline& tps);

} // end namespace TPS

#endif
