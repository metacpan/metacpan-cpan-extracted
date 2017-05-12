#ifndef _Animal_h_
#define _Animal_h_

#include <string>
#include <exception>

class CannotMakeSoundException : public std::exception {
public:
  virtual const char* what() const throw()
  { return "This animal does not make sounds."; }
};

class Animal {
public:
  Animal(const std::string& name);

  void SetName(const std::string& newName);
  std::string GetName() const;

  void MakeSound() const;

private:
  std::string fName;
};

#endif
