// on Linux compile with: g++ --shared -o basic.so basic.cpp
// elsewhere, consult your C++ compiler documentation

class Foo {

public:

  Foo();
  ~Foo();

  int get_bar();
  void set_bar(int);

  int _size();

private:

  int bar;

};

Foo::Foo()
{
  bar = 0;
}

Foo::~Foo()
{
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
