// on Linux compile with: g++ -fPIC --shared -o exception.so exception.cpp
// elsewhere, consult your C++ compiler documentation

#include <stdlib.h>

class FooException {
  const char *msg;
public:
  FooException(const char *);
  const char *message();
};

FooException::FooException(const char *the_message)
{
  msg = the_message;
}

const char *
FooException::message()
{
  return msg;
}

class Foo {

public:

  Foo() { bar = 0; };
  ~Foo() { };

  int get_bar();
  void set_bar(int);

  int _size();

private:

  int bar;

};

extern "C" Foo*
Foo_new()
{
  return new Foo();
}

extern "C" void
Foo_delete(Foo *foo)
{
  delete foo;
}

int
Foo::get_bar()
{
  return bar;
}

void
Foo::set_bar(int value)
{
  if(value > 512)
    throw new FooException("too hot");
  if(value < 0)
    throw new FooException("too cold");
  bar = value;
}

int
Foo::_size()
{
  return sizeof(Foo);
}

static FooException *last_exception = NULL;

extern "C" FooException *
Foo_get_exception()
{
  return last_exception;
}

extern "C" void
Foo_reset_exception()
{
  if(last_exception != NULL)
    delete last_exception;
  last_exception = NULL;
}

extern "C" void
Foo_set_bar(Foo *foo, int value)
{
  try
  {
    Foo_reset_exception();
    foo->set_bar(value);
  }
  catch(FooException *e)
  {
    last_exception = e;
  }
}

