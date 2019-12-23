#ifdef _MSC_VER
#define EXPORT __declspec(dllexport)
#else
#define EXPORT
#endif

EXPORT
unsigned char
f0(unsigned char input)
{
  return input;
}
  
