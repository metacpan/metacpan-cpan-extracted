#ifndef _IntAndString_h_
#define _IntAndString_h_

#include <string>

class IntAndString {
public:
  IntAndString();
  IntAndString(const char* str, int arg);
  ~IntAndString() {}

  int GetInt() { return fInt; }
  const char* GetString();

  void SetValue(int arg);
  void SetValue(const char* arg);


private:
  std::string fString;
  int fInt;
};

#endif

