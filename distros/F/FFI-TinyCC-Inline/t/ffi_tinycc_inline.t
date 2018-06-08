use Test2::V0 -no_srand => 1;
use FFI::TinyCC::Inline qw( tcc_inline );

tcc_inline q{

int square(int value)
{
  return value * value;
}

static int foo = 1;

void f1(int value)
{
  foo = value;
}

int f2()
{
  return foo;
}

unsigned  int f3()
{
  return 100;
}

signed short f4()
{
  return -3;
}

unsigned short f5()
{
  return 300;
}

long f6(unsigned long value)
{
  return -value;
}

char f8()
{
  return 22;
}

float f9()
{
  return 1.5;
}

double f10()
{
  return 2.5;
}

const char *f11()
{
  return "message1";
}

char *f12()
{
  return "message2";
}

char *message3 = "message3";

void *f14()
{
  return message3;
}

const char *f15(void *value)
{
  return (const char *) value;
}

int sum(int argc, const char **argv)
{
  int i;
  int sum;
  for(i=0,sum=0; i<argc; i++)
  {
    sum += atoi(argv[i]);
  }
  return sum;
}

};

is square(4), 16, 'square(4) = 16';

is f2(), 1, 'f2() = 1';
f1(22);
is f2(), 22, 'f2() = 22';
is f3(), 100, 'f3() = 100';
is f4(), -3, 'f4() = -3';
is f5(), 300, 'f5() = 300';
is f6(200), -200, 'f6(200) = -200';
is f8(), 22, 'f8() = 22';
is f9(), 1.5, 'f9() = 1.5';
is f10(), 2.5, 'f10() = 2.5';
is f11(), "message1", "f11() = message1";
is f12(), "message2", "f12() = message2";
ok f14(), "f14() = " . f14();
is f15(f14()), "message3", "f15(f14()) = message3";

is sum("1", "2", "3"), 6, 'sum(1,2,3) = 6';

done_testing;
