#ifndef __TPSException_h_
#define __TPSException_h_

namespace TPS {
  class TPSException : public std::exception
  {
  public:
    TPSException() {}

    virtual const char* what() const throw() {
      return "Generic ThinPlateSpline exception. Nuke your programmer.";
    }
  };


  class EndOfFileException : public TPSException
  {
  public:
    EndOfFileException() {}

    virtual const char* what() const throw() {
      return "Prematurely reached the end of the input file.";
    }
  };


  class NotEnoughControlPointsException : public TPSException
  {
  public:
    NotEnoughControlPointsException() {}

    virtual const char* what() const throw() {
      return "Not enough control points for evaluating ThinPlateSpline";
    }
  };


  class SingularMatrixException : public TPSException
  {
  public:
    SingularMatrixException() {}

    virtual const char* what() const throw() {
      return "Singular matrix during LU decomposition";
    }
  };


  class BadNoCoordinatesException : public std::exception
  {
  public:
    BadNoCoordinatesException() {}

    virtual const char* what() const throw() {
      return "The number of x- and y- coordinates does not match.";
    }
  };
} // end namespace TPS

#endif
