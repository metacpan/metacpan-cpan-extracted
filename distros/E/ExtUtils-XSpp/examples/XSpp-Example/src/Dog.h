#ifndef _Dog_h_
#define _Dog_h_

#include <Animal.h>
#include <string>

class Dog : public Animal {
public:
  Dog(const std::string& name);

  void Bark() const;
  void MakeSound() const;

  Dog* Clone() const;

  static void MakeDogBark(const Dog& d);
};


#endif
