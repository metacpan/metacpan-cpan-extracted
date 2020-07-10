// on Linux compile with: g++ -fPIC --shared -o wrapper.so wrapper.cpp
// elsewhere, consult your C++ compiler documentation

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

extern "C"
Foo* Foo_new()
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
  bar = value;
}

int
Foo::_size()
{
  return sizeof(Foo);
}
