#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

struct Alpr;
typedef struct Alpr Alpr;
typedef char fchar;

extern Alpr* initialize(char*, char*, char*);
extern void  dispose(Alpr*);
extern bool  isLoaded(Alpr*);
extern char* recognizeFile(Alpr*, char*);
extern char* recognizeArray(Alpr*, char*, int);
extern void  setCountry(Alpr*, char*);
extern void  setPrewarp(Alpr*, char*);
extern void  setDefaultRegion(Alpr*, char*);
extern void  setTopN(Alpr*, int);
extern char* getVersion(Alpr*);
extern void  freeJsonMem(char*);

MODULE = Image::OpenALPR PACKAGE = Image::OpenALPR
PROTOTYPES: ENABLE

Alpr* initialize(char* country, char* config_file = "", char* runtime_dir = "")

void dispose(Alpr* alpr)

bool isLoaded(Alpr* alpr)

fchar* recognizeFile(Alpr* alpr, char* image_file)

fchar* recognizeArray(Alpr* alpr, char* buf, int length(buf))

void setString(Alpr* alpr, char* value)
  INTERFACE: setCountry setPrewarp setDefaultRegion

void setTopN(Alpr* alpr, int top_n)

fchar* getVersion(Alpr* alpr)
