#if defined(__CYGWIN__) || defined(_WIN32)
#define STDCALL __stdcall
#else
#define STDCALL
#endif

#ifdef _MSC_VER
#define EXPORT __declspec(dllexport)
#else
#define EXPORT
#endif

EXPORT
unsigned int STDCALL
fill_my_string(unsigned int size, char *buffer)
{
  static const char *my_string = "The quick brown fox jumps over the lazy dog.";
  int i=0;

  while(i < size-1 && my_string[i] != '\0')
  {
    buffer[i] = my_string[i];
    i++;
  }

  buffer[i] = '\0';

  return i+1;
}

