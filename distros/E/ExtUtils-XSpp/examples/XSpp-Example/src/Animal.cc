#include "Animal.h"

#include <string>
#include <iostream>
#include <exception>

Animal::Animal(const std::string& name) :
  fName(name)
{}

void
Animal::SetName(const std::string& newName)
{
  fName = newName;
}

std::string
Animal::GetName()
  const
{
  return fName;
}

void
Animal::MakeSound()
  const
{
  throw CannotMakeSoundException();
}

