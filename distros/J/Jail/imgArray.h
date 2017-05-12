
#ifndef __imgARRAY__
#define __imgARRAY__

#include <vector.h>

class imgArray {
 public:
  imgArray();
  ~imgArray();

  int size();

  void push(class imgProcess *image);
  void unshift(class imgProcess *image);

  class imgProcess *pop();
  class imgProcess *shift();

  short loadIndexed(const char *prefix, int startSuffix, const char *suffix, int amount);
  short saveIndexed(const char *prefix, int startSuffix, const char *suffix, const char *format);

  short getVideoStream(int frameAmount);

  void printError();
  char *getErrorString();
  short getStatus();

 private:
  void deleteArray();
  void setError(const char *str);
  void setError(const char *str, short errno);

  char *_error;
  short _errno;
  vector<class imgProcess *> _array;
};

#endif
