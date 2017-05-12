
SV * dubble(SV * in) {
 return newSViv(SvIV(in) * 2);
}

int dubb (int in) {
 return (in * 2);
}

/*
#define Inline_Stack_Vars	dXSARGS
#define Inline_Stack_Items      items
#define Inline_Stack_Item(x)	ST(x)
#define Inline_Stack_Reset      sp = mark
#define Inline_Stack_Push(x)	XPUSHs(x)
#define Inline_Stack_Done	PUTBACK
#define Inline_Stack_Return(x)	XSRETURN(x)
#define Inline_Stack_Void       XSRETURN(0)
*/

void dv( int in ) {
  dXSARGS;
  sp = mark;
  XPUSHs(sv_2mortal(newSViv(in * 2)));
  PUTBACK;
  XSRETURN(1);
}

void vv ( int in ) {
  printf("%d\n", in * 2);
}

int dub( SV * in ) {
  return (SvIV(in) * 2);
}

unsigned long dubul (SV* in) {
  return (SvUV(in) * 2);
}

double dubd (double in) {
  return (in * 2.0);
}


SV * call_dub(SV * in) {
  return newSVuv(dub(in));
}

SV * call_dubd ( SV* in ) {
  double ret = dubd((double)SvNV(in));
  return newSVuv(ret);
}

