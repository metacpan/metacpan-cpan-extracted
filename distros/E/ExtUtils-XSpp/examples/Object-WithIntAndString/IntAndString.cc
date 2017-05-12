#include "IntAndString.h"

#include <string>

using namespace std;

IntAndString::IntAndString() :
  fString(string("")),
  fInt(0)
{
}

IntAndString::IntAndString(const char* str, int arg) :
  fString(std::string(str)),
  fInt(arg)
{
}

const char* IntAndString::GetString() {
  return fString.c_str();
}

void IntAndString::SetValue(int arg) {
  fInt = arg;
}

void IntAndString::SetValue(const char* arg) {
  fString = string(arg);
}

