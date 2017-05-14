%module Matrix;

typedef int jint;

class Matrix
{
public:
  Matrix (jint, jint);
  virtual void set (jint, jint, jint);
  virtual jint get (jint, jint);
  virtual ::Matrix *multiply (::Matrix *);
  virtual jint getRows ();
  virtual jint getCols ();
  virtual void print ();
private:
  static void populate (::Matrix *);
};
