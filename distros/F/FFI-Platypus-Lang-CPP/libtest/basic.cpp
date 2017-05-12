class MyInteger {
public:
  static int int_sum(int, int);
};

int
MyInteger :: int_sum(int a, int b)
{
  return a+b;
}

extern "C" int c_int_sum(int a, int b)
{
  return a+b;
}
