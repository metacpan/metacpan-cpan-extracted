#define PERL_constant_NOTFOUND	1
#define PERL_constant_NOTDEF	2
#define PERL_constant_ISIV	3
#define PERL_constant_ISNO	4
#define PERL_constant_ISNV	5
#define PERL_constant_ISPV	6
#define PERL_constant_ISPVN	7
#define PERL_constant_ISSV	8
#define PERL_constant_ISUNDEF	9
#define PERL_constant_ISUV	10
#define PERL_constant_ISYES	11

#ifndef NVTYPE
typedef double NV; /* 5.6 and later define NVTYPE, and typedef NV to it.  */
#endif
#ifndef aTHX_
#define aTHX_ /* 5.6 or later define this for threading support.  */
#endif
#ifndef pTHX_
#define pTHX_ /* 5.6 or later define this for threading support.  */
#endif

static int
constant_5 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     KEY_A KEY_B KEY_C KEY_D KEY_E KEY_F KEY_G KEY_H KEY_I KEY_J KEY_K KEY_L
     KEY_M KEY_N KEY_O KEY_P KEY_Q KEY_R KEY_S KEY_T KEY_U KEY_V KEY_W KEY_X
     KEY_Y KEY_Z false */
  /* Offset 4 gives the best switch position.  */
  switch (name[4]) {
  case 'A':
    if (memEQ(name, "KEY_", 4)) {
    /*                   A     */
#ifdef KEY_A
      *iv_return = KEY_A;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "KEY_", 4)) {
    /*                   B     */
#ifdef KEY_B
      *iv_return = KEY_B;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "KEY_", 4)) {
    /*                   C     */
#ifdef KEY_C
      *iv_return = KEY_C;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "KEY_", 4)) {
    /*                   D     */
#ifdef KEY_D
      *iv_return = KEY_D;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "KEY_", 4)) {
    /*                   E     */
#ifdef KEY_E
      *iv_return = KEY_E;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "KEY_", 4)) {
    /*                   F     */
#ifdef KEY_F
      *iv_return = KEY_F;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "KEY_", 4)) {
    /*                   G     */
#ifdef KEY_G
      *iv_return = KEY_G;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "KEY_", 4)) {
    /*                   H     */
#ifdef KEY_H
      *iv_return = KEY_H;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "KEY_", 4)) {
    /*                   I     */
#ifdef KEY_I
      *iv_return = KEY_I;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'J':
    if (memEQ(name, "KEY_", 4)) {
    /*                   J     */
#ifdef KEY_J
      *iv_return = KEY_J;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'K':
    if (memEQ(name, "KEY_", 4)) {
    /*                   K     */
#ifdef KEY_K
      *iv_return = KEY_K;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "KEY_", 4)) {
    /*                   L     */
#ifdef KEY_L
      *iv_return = KEY_L;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "KEY_", 4)) {
    /*                   M     */
#ifdef KEY_M
      *iv_return = KEY_M;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "KEY_", 4)) {
    /*                   N     */
#ifdef KEY_N
      *iv_return = KEY_N;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "KEY_", 4)) {
    /*                   O     */
#ifdef KEY_O
      *iv_return = KEY_O;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "KEY_", 4)) {
    /*                   P     */
#ifdef KEY_P
      *iv_return = KEY_P;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Q':
    if (memEQ(name, "KEY_", 4)) {
    /*                   Q     */
#ifdef KEY_Q
      *iv_return = KEY_Q;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "KEY_", 4)) {
    /*                   R     */
#ifdef KEY_R
      *iv_return = KEY_R;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "KEY_", 4)) {
    /*                   S     */
#ifdef KEY_S
      *iv_return = KEY_S;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "KEY_", 4)) {
    /*                   T     */
#ifdef KEY_T
      *iv_return = KEY_T;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "KEY_", 4)) {
    /*                   U     */
#ifdef KEY_U
      *iv_return = KEY_U;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "KEY_", 4)) {
    /*                   V     */
#ifdef KEY_V
      *iv_return = KEY_V;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'W':
    if (memEQ(name, "KEY_", 4)) {
    /*                   W     */
#ifdef KEY_W
      *iv_return = KEY_W;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "KEY_", 4)) {
    /*                   X     */
#ifdef KEY_X
      *iv_return = KEY_X;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Y':
    if (memEQ(name, "KEY_", 4)) {
    /*                   Y     */
#ifdef KEY_Y
      *iv_return = KEY_Y;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Z':
    if (memEQ(name, "KEY_", 4)) {
    /*                   Z     */
#ifdef KEY_Z
      *iv_return = KEY_Z;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'e':
    if (memEQ(name, "fals", 4)) {
    /*                   e     */
      *iv_return = false;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_6 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     KEY_F1 KEY_F2 KEY_F3 KEY_F4 KEY_F5 KEY_F6 KEY_F7 KEY_F8 KEY_F9 KEY_UP */
  /* Offset 5 gives the best switch position.  */
  switch (name[5]) {
  case '1':
    if (memEQ(name, "KEY_F", 5)) {
    /*                    1     */
#ifdef KEY_F1
      *iv_return = KEY_F1;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '2':
    if (memEQ(name, "KEY_F", 5)) {
    /*                    2     */
#ifdef KEY_F2
      *iv_return = KEY_F2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '3':
    if (memEQ(name, "KEY_F", 5)) {
    /*                    3     */
#ifdef KEY_F3
      *iv_return = KEY_F3;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '4':
    if (memEQ(name, "KEY_F", 5)) {
    /*                    4     */
#ifdef KEY_F4
      *iv_return = KEY_F4;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '5':
    if (memEQ(name, "KEY_F", 5)) {
    /*                    5     */
#ifdef KEY_F5
      *iv_return = KEY_F5;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '6':
    if (memEQ(name, "KEY_F", 5)) {
    /*                    6     */
#ifdef KEY_F6
      *iv_return = KEY_F6;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '7':
    if (memEQ(name, "KEY_F", 5)) {
    /*                    7     */
#ifdef KEY_F7
      *iv_return = KEY_F7;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '8':
    if (memEQ(name, "KEY_F", 5)) {
    /*                    8     */
#ifdef KEY_F8
      *iv_return = KEY_F8;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '9':
    if (memEQ(name, "KEY_F", 5)) {
    /*                    9     */
#ifdef KEY_F9
      *iv_return = KEY_F9;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "KEY_U", 5)) {
    /*                    P     */
#ifdef KEY_UP
      *iv_return = KEY_UP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_7 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     DEG2RAD KEY_END KEY_F10 KEY_F11 KEY_F12 KEY_ONE KEY_SIX KEY_TAB KEY_TWO
     RAD2DEG */
  /* Offset 6 gives the best switch position.  */
  switch (name[6]) {
  case '0':
    if (memEQ(name, "KEY_F1", 6)) {
    /*                     0     */
#ifdef KEY_F10
      *iv_return = KEY_F10;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '1':
    if (memEQ(name, "KEY_F1", 6)) {
    /*                     1     */
#ifdef KEY_F11
      *iv_return = KEY_F11;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '2':
    if (memEQ(name, "KEY_F1", 6)) {
    /*                     2     */
#ifdef KEY_F12
      *iv_return = KEY_F12;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "KEY_TA", 6)) {
    /*                     B     */
#ifdef KEY_TAB
      *iv_return = KEY_TAB;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "DEG2RA", 6)) {
    /*                     D     */
#ifdef DEG2RAD
      *iv_return = DEG2RAD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "KEY_EN", 6)) {
    /*                     D     */
#ifdef KEY_END
      *iv_return = KEY_END;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "KEY_ON", 6)) {
    /*                     E     */
#ifdef KEY_ONE
      *iv_return = KEY_ONE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "RAD2DE", 6)) {
    /*                     G     */
#ifdef RAD2DEG
      *iv_return = RAD2DEG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "KEY_TW", 6)) {
    /*                     O     */
#ifdef KEY_TWO
      *iv_return = KEY_TWO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "KEY_SI", 6)) {
    /*                     X     */
#ifdef KEY_SIX
      *iv_return = KEY_SIX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_8 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     FONT_SDF KEY_BACK KEY_DOWN KEY_FIVE KEY_FOUR KEY_HOME KEY_KP_0 KEY_KP_1
     KEY_KP_2 KEY_KP_3 KEY_KP_4 KEY_KP_5 KEY_KP_6 KEY_KP_7 KEY_KP_8 KEY_KP_9
     KEY_LEFT KEY_MENU KEY_NINE KEY_ZERO LOG_INFO MAP_BRDF */
  /* Offset 7 gives the best switch position.  */
  switch (name[7]) {
  case '0':
    if (memEQ(name, "KEY_KP_", 7)) {
    /*                      0     */
#ifdef KEY_KP_0
      *iv_return = KEY_KP_0;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '1':
    if (memEQ(name, "KEY_KP_", 7)) {
    /*                      1     */
#ifdef KEY_KP_1
      *iv_return = KEY_KP_1;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '2':
    if (memEQ(name, "KEY_KP_", 7)) {
    /*                      2     */
#ifdef KEY_KP_2
      *iv_return = KEY_KP_2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '3':
    if (memEQ(name, "KEY_KP_", 7)) {
    /*                      3     */
#ifdef KEY_KP_3
      *iv_return = KEY_KP_3;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '4':
    if (memEQ(name, "KEY_KP_", 7)) {
    /*                      4     */
#ifdef KEY_KP_4
      *iv_return = KEY_KP_4;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '5':
    if (memEQ(name, "KEY_KP_", 7)) {
    /*                      5     */
#ifdef KEY_KP_5
      *iv_return = KEY_KP_5;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '6':
    if (memEQ(name, "KEY_KP_", 7)) {
    /*                      6     */
#ifdef KEY_KP_6
      *iv_return = KEY_KP_6;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '7':
    if (memEQ(name, "KEY_KP_", 7)) {
    /*                      7     */
#ifdef KEY_KP_7
      *iv_return = KEY_KP_7;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '8':
    if (memEQ(name, "KEY_KP_", 7)) {
    /*                      8     */
#ifdef KEY_KP_8
      *iv_return = KEY_KP_8;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '9':
    if (memEQ(name, "KEY_KP_", 7)) {
    /*                      9     */
#ifdef KEY_KP_9
      *iv_return = KEY_KP_9;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "KEY_FIV", 7)) {
    /*                      E     */
#ifdef KEY_FIVE
      *iv_return = KEY_FIVE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "KEY_HOM", 7)) {
    /*                      E     */
#ifdef KEY_HOME
      *iv_return = KEY_HOME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "KEY_NIN", 7)) {
    /*                      E     */
#ifdef KEY_NINE
      *iv_return = KEY_NINE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "FONT_SD", 7)) {
    /*                      F     */
      *iv_return = FONT_SDF;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "MAP_BRD", 7)) {
    /*                      F     */
      *iv_return = MAP_BRDF;
      return PERL_constant_ISIV;
    }
    break;
  case 'K':
    if (memEQ(name, "KEY_BAC", 7)) {
    /*                      K     */
#ifdef KEY_BACK
      *iv_return = KEY_BACK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "KEY_DOW", 7)) {
    /*                      N     */
#ifdef KEY_DOWN
      *iv_return = KEY_DOWN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "KEY_ZER", 7)) {
    /*                      O     */
#ifdef KEY_ZERO
      *iv_return = KEY_ZERO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "LOG_INF", 7)) {
    /*                      O     */
      *iv_return = LOG_INFO;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "KEY_FOU", 7)) {
    /*                      R     */
#ifdef KEY_FOUR
      *iv_return = KEY_FOUR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "KEY_LEF", 7)) {
    /*                      T     */
#ifdef KEY_LEFT
      *iv_return = KEY_LEFT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "KEY_MEN", 7)) {
    /*                      U     */
#ifdef KEY_MENU
      *iv_return = KEY_MENU;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_9 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     KEY_COMMA KEY_EIGHT KEY_ENTER KEY_EQUAL KEY_GRAVE KEY_MINUS KEY_PAUSE
     KEY_RIGHT KEY_SEVEN KEY_SLASH KEY_SPACE KEY_THREE LOG_DEBUG LOG_ERROR
     LOG_OTHER */
  /* Offset 5 gives the best switch position.  */
  switch (name[5]) {
  case 'A':
    if (memEQ(name, "KEY_PAUSE", 9)) {
    /*                    ^         */
#ifdef KEY_PAUSE
      *iv_return = KEY_PAUSE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "KEY_SEVEN", 9)) {
    /*                    ^         */
#ifdef KEY_SEVEN
      *iv_return = KEY_SEVEN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "LOG_DEBUG", 9)) {
    /*                    ^         */
      *iv_return = LOG_DEBUG;
      return PERL_constant_ISIV;
    }
    break;
  case 'H':
    if (memEQ(name, "KEY_THREE", 9)) {
    /*                    ^         */
#ifdef KEY_THREE
      *iv_return = KEY_THREE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "KEY_EIGHT", 9)) {
    /*                    ^         */
#ifdef KEY_EIGHT
      *iv_return = KEY_EIGHT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "KEY_MINUS", 9)) {
    /*                    ^         */
#ifdef KEY_MINUS
      *iv_return = KEY_MINUS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "KEY_RIGHT", 9)) {
    /*                    ^         */
#ifdef KEY_RIGHT
      *iv_return = KEY_RIGHT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "KEY_SLASH", 9)) {
    /*                    ^         */
#ifdef KEY_SLASH
      *iv_return = KEY_SLASH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "KEY_ENTER", 9)) {
    /*                    ^         */
#ifdef KEY_ENTER
      *iv_return = KEY_ENTER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "KEY_COMMA", 9)) {
    /*                    ^         */
#ifdef KEY_COMMA
      *iv_return = KEY_COMMA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "KEY_SPACE", 9)) {
    /*                    ^         */
#ifdef KEY_SPACE
      *iv_return = KEY_SPACE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Q':
    if (memEQ(name, "KEY_EQUAL", 9)) {
    /*                    ^         */
#ifdef KEY_EQUAL
      *iv_return = KEY_EQUAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "KEY_GRAVE", 9)) {
    /*                    ^         */
#ifdef KEY_GRAVE
      *iv_return = KEY_GRAVE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "LOG_ERROR", 9)) {
    /*                    ^         */
      *iv_return = LOG_ERROR;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "LOG_OTHER", 9)) {
    /*                    ^         */
      *iv_return = LOG_OTHER;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_10 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     KEY_DELETE KEY_ESCAPE KEY_INSERT KEY_KP_ADD KEY_PERIOD MAP_ALBEDO
     MAP_HEIGHT MAP_NORMAL NPT_9PATCH WRAP_CLAMP */
  /* Offset 4 gives the best switch position.  */
  switch (name[4]) {
  case '9':
    if (memEQ(name, "NPT_9PATCH", 10)) {
    /*                   ^            */
      *iv_return = NPT_9PATCH;
      return PERL_constant_ISIV;
    }
    break;
  case 'A':
    if (memEQ(name, "MAP_ALBEDO", 10)) {
    /*                   ^            */
      *iv_return = MAP_ALBEDO;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "KEY_DELETE", 10)) {
    /*                   ^            */
#ifdef KEY_DELETE
      *iv_return = KEY_DELETE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "KEY_ESCAPE", 10)) {
    /*                   ^            */
#ifdef KEY_ESCAPE
      *iv_return = KEY_ESCAPE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "MAP_HEIGHT", 10)) {
    /*                   ^            */
      *iv_return = MAP_HEIGHT;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "KEY_INSERT", 10)) {
    /*                   ^            */
#ifdef KEY_INSERT
      *iv_return = KEY_INSERT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'K':
    if (memEQ(name, "KEY_KP_ADD", 10)) {
    /*                   ^            */
#ifdef KEY_KP_ADD
      *iv_return = KEY_KP_ADD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "MAP_NORMAL", 10)) {
    /*                   ^            */
      *iv_return = MAP_NORMAL;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "KEY_PERIOD", 10)) {
    /*                   ^            */
#ifdef KEY_PERIOD
      *iv_return = KEY_PERIOD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "WRAP_CLAMP", 10)) {
    /*                   ^            */
      *iv_return = WRAP_CLAMP;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_11 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     BLEND_ALPHA CAMERA_FREE FONT_BITMAP GESTURE_TAP KEY_KB_MENU KEY_PAGE_UP
     LOG_WARNING MAP_CUBEMAP MAP_DIFFUSE WRAP_MIRROR WRAP_REPEAT */
  /* Offset 7 gives the best switch position.  */
  switch (name[7]) {
  case 'E':
    if (memEQ(name, "KEY_PAGE_UP", 11)) {
    /*                      ^          */
#ifdef KEY_PAGE_UP
      *iv_return = KEY_PAGE_UP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "MAP_CUBEMAP", 11)) {
    /*                      ^          */
      *iv_return = MAP_CUBEMAP;
      return PERL_constant_ISIV;
    }
    break;
  case 'F':
    if (memEQ(name, "CAMERA_FREE", 11)) {
    /*                      ^          */
      *iv_return = CAMERA_FREE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "MAP_DIFFUSE", 11)) {
    /*                      ^          */
#ifdef MAP_DIFFUSE
      *iv_return = MAP_DIFFUSE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "BLEND_ALPHA", 11)) {
    /*                      ^          */
      *iv_return = BLEND_ALPHA;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "KEY_KB_MENU", 11)) {
    /*                      ^          */
#ifdef KEY_KB_MENU
      *iv_return = KEY_KB_MENU;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "LOG_WARNING", 11)) {
    /*                      ^          */
      *iv_return = LOG_WARNING;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "WRAP_REPEAT", 11)) {
    /*                      ^          */
      *iv_return = WRAP_REPEAT;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "WRAP_MIRROR", 11)) {
    /*                      ^          */
      *iv_return = WRAP_MIRROR;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "FONT_BITMAP", 11)) {
    /*                      ^          */
      *iv_return = FONT_BITMAP;
      return PERL_constant_ISIV;
    }
    break;
  case '_':
    if (memEQ(name, "GESTURE_TAP", 11)) {
    /*                      ^          */
      *iv_return = GESTURE_TAP;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_12 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     FILTER_POINT FONT_DEFAULT GESTURE_DRAG GESTURE_HOLD GESTURE_NONE
     KEY_KP_ENTER KEY_KP_EQUAL KEY_LEFT_ALT KEY_NUM_LOCK LOC_MAP_BRDF
     MAP_EMISSION MAP_SPECULAR */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'A':
    if (memEQ(name, "FONT_DEFAULT", 12)) {
    /*                       ^          */
      *iv_return = FONT_DEFAULT;
      return PERL_constant_ISIV;
    }
    break;
  case 'B':
    if (memEQ(name, "LOC_MAP_BRDF", 12)) {
    /*                       ^          */
      *iv_return = LOC_MAP_BRDF;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "GESTURE_DRAG", 12)) {
    /*                       ^          */
      *iv_return = GESTURE_DRAG;
      return PERL_constant_ISIV;
    }
    break;
  case 'H':
    if (memEQ(name, "GESTURE_HOLD", 12)) {
    /*                       ^          */
      *iv_return = GESTURE_HOLD;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "KEY_NUM_LOCK", 12)) {
    /*                       ^          */
#ifdef KEY_NUM_LOCK
      *iv_return = KEY_NUM_LOCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "GESTURE_NONE", 12)) {
    /*                       ^          */
      *iv_return = GESTURE_NONE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "KEY_KP_ENTER", 12)) {
    /*                       ^          */
#ifdef KEY_KP_ENTER
      *iv_return = KEY_KP_ENTER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "FILTER_POINT", 12)) {
    /*                       ^          */
      *iv_return = FILTER_POINT;
      return PERL_constant_ISIV;
    }
    break;
  case 'Q':
    if (memEQ(name, "KEY_KP_EQUAL", 12)) {
    /*                       ^          */
#ifdef KEY_KP_EQUAL
      *iv_return = KEY_KP_EQUAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "MAP_EMISSION", 12)) {
    /*                       ^          */
      *iv_return = MAP_EMISSION;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "MAP_SPECULAR", 12)) {
    /*                       ^          */
#ifdef MAP_SPECULAR
      *iv_return = MAP_SPECULAR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "KEY_LEFT_ALT", 12)) {
    /*                       ^          */
#ifdef KEY_LEFT_ALT
      *iv_return = KEY_LEFT_ALT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_13 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CAMERA_CUSTOM HMD_OCULUS_GO HMD_SONY_PSVR KEY_BACKSLASH KEY_BACKSPACE
     KEY_CAPS_LOCK KEY_KP_DIVIDE KEY_PAGE_DOWN KEY_RIGHT_ALT KEY_SEMICOLON
     KEY_VOLUME_UP MAP_METALNESS MAP_OCCLUSION MAP_PREFILTER MAP_ROUGHNESS */
  /* Offset 7 gives the best switch position.  */
  switch (name[7]) {
  case 'A':
    if (memEQ(name, "MAP_METALNESS", 13)) {
    /*                      ^            */
      *iv_return = MAP_METALNESS;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "CAMERA_CUSTOM", 13)) {
    /*                      ^            */
      *iv_return = CAMERA_CUSTOM;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "KEY_KP_DIVIDE", 13)) {
    /*                      ^            */
#ifdef KEY_KP_DIVIDE
      *iv_return = KEY_KP_DIVIDE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "KEY_PAGE_DOWN", 13)) {
    /*                      ^            */
#ifdef KEY_PAGE_DOWN
      *iv_return = KEY_PAGE_DOWN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "MAP_PREFILTER", 13)) {
    /*                      ^            */
      *iv_return = MAP_PREFILTER;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "MAP_ROUGHNESS", 13)) {
    /*                      ^            */
      *iv_return = MAP_ROUGHNESS;
      return PERL_constant_ISIV;
    }
    break;
  case 'H':
    if (memEQ(name, "KEY_RIGHT_ALT", 13)) {
    /*                      ^            */
#ifdef KEY_RIGHT_ALT
      *iv_return = KEY_RIGHT_ALT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "KEY_SEMICOLON", 13)) {
    /*                      ^            */
#ifdef KEY_SEMICOLON
      *iv_return = KEY_SEMICOLON;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'K':
    if (memEQ(name, "KEY_BACKSLASH", 13)) {
    /*                      ^            */
#ifdef KEY_BACKSLASH
      *iv_return = KEY_BACKSLASH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "KEY_BACKSPACE", 13)) {
    /*                      ^            */
#ifdef KEY_BACKSPACE
      *iv_return = KEY_BACKSPACE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "HMD_OCULUS_GO", 13)) {
    /*                      ^            */
      *iv_return = HMD_OCULUS_GO;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "MAP_OCCLUSION", 13)) {
    /*                      ^            */
      *iv_return = MAP_OCCLUSION;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "KEY_CAPS_LOCK", 13)) {
    /*                      ^            */
#ifdef KEY_CAPS_LOCK
      *iv_return = KEY_CAPS_LOCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "KEY_VOLUME_UP", 13)) {
    /*                      ^            */
#ifdef KEY_VOLUME_UP
      *iv_return = KEY_VOLUME_UP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Y':
    if (memEQ(name, "HMD_SONY_PSVR", 13)) {
    /*                      ^            */
      *iv_return = HMD_SONY_PSVR;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_14 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     BLEND_ADDITIVE CAMERA_ORBITAL FLAG_SHOW_LOGO KEY_APOSTROPHE KEY_KP_DECIMAL
     KEY_LEFT_SHIFT KEY_LEFT_SUPER LOC_MAP_ALBEDO LOC_MAP_HEIGHT LOC_MAP_NORMAL
     LOC_MATRIX_MVP MAP_IRRADIANCE */
  /* Offset 9 gives the best switch position.  */
  switch (name[9]) {
  case 'B':
    if (memEQ(name, "CAMERA_ORBITAL", 14)) {
    /*                        ^           */
      *iv_return = CAMERA_ORBITAL;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "KEY_KP_DECIMAL", 14)) {
    /*                        ^           */
#ifdef KEY_KP_DECIMAL
      *iv_return = KEY_KP_DECIMAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "LOC_MAP_HEIGHT", 14)) {
    /*                        ^           */
      *iv_return = LOC_MAP_HEIGHT;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "BLEND_ADDITIVE", 14)) {
    /*                        ^           */
      *iv_return = BLEND_ADDITIVE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "MAP_IRRADIANCE", 14)) {
    /*                        ^           */
      *iv_return = MAP_IRRADIANCE;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "LOC_MAP_ALBEDO", 14)) {
    /*                        ^           */
      *iv_return = LOC_MAP_ALBEDO;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "LOC_MAP_NORMAL", 14)) {
    /*                        ^           */
      *iv_return = LOC_MAP_NORMAL;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "KEY_APOSTROPHE", 14)) {
    /*                        ^           */
#ifdef KEY_APOSTROPHE
      *iv_return = KEY_APOSTROPHE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "KEY_LEFT_SHIFT", 14)) {
    /*                        ^           */
#ifdef KEY_LEFT_SHIFT
      *iv_return = KEY_LEFT_SHIFT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "KEY_LEFT_SUPER", 14)) {
    /*                        ^           */
#ifdef KEY_LEFT_SUPER
      *iv_return = KEY_LEFT_SUPER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "LOC_MATRIX_MVP", 14)) {
    /*                        ^           */
      *iv_return = LOC_MATRIX_MVP;
      return PERL_constant_ISIV;
    }
    break;
  case '_':
    if (memEQ(name, "FLAG_SHOW_LOGO", 14)) {
    /*                        ^           */
#ifdef FLAG_SHOW_LOGO
      *iv_return = FLAG_SHOW_LOGO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_15 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     FILTER_BILINEAR FLAG_VSYNC_HINT GAMEPAD_PLAYER1 GAMEPAD_PLAYER2
     GAMEPAD_PLAYER3 GAMEPAD_PLAYER4 KEY_KP_MULTIPLY KEY_KP_SUBTRACT
     KEY_RIGHT_SHIFT KEY_RIGHT_SUPER KEY_SCROLL_LOCK KEY_VOLUME_DOWN
     LOC_MAP_CUBEMAP LOC_MAP_DIFFUSE LOC_MATRIX_VIEW LOC_VECTOR_VIEW */
  /* Offset 14 gives the best switch position.  */
  switch (name[14]) {
  case '1':
    if (memEQ(name, "GAMEPAD_PLAYER", 14)) {
    /*                             1      */
#ifdef GAMEPAD_PLAYER1
      *iv_return = GAMEPAD_PLAYER1;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '2':
    if (memEQ(name, "GAMEPAD_PLAYER", 14)) {
    /*                             2      */
#ifdef GAMEPAD_PLAYER2
      *iv_return = GAMEPAD_PLAYER2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '3':
    if (memEQ(name, "GAMEPAD_PLAYER", 14)) {
    /*                             3      */
#ifdef GAMEPAD_PLAYER3
      *iv_return = GAMEPAD_PLAYER3;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '4':
    if (memEQ(name, "GAMEPAD_PLAYER", 14)) {
    /*                             4      */
#ifdef GAMEPAD_PLAYER4
      *iv_return = GAMEPAD_PLAYER4;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "LOC_MAP_DIFFUS", 14)) {
    /*                             E      */
#ifdef LOC_MAP_DIFFUSE
      *iv_return = LOC_MAP_DIFFUSE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'K':
    if (memEQ(name, "KEY_SCROLL_LOC", 14)) {
    /*                             K      */
#ifdef KEY_SCROLL_LOCK
      *iv_return = KEY_SCROLL_LOCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "KEY_VOLUME_DOW", 14)) {
    /*                             N      */
#ifdef KEY_VOLUME_DOWN
      *iv_return = KEY_VOLUME_DOWN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "LOC_MAP_CUBEMA", 14)) {
    /*                             P      */
      *iv_return = LOC_MAP_CUBEMAP;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "FILTER_BILINEA", 14)) {
    /*                             R      */
      *iv_return = FILTER_BILINEAR;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "KEY_RIGHT_SUPE", 14)) {
    /*                             R      */
#ifdef KEY_RIGHT_SUPER
      *iv_return = KEY_RIGHT_SUPER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "FLAG_VSYNC_HIN", 14)) {
    /*                             T      */
#ifdef FLAG_VSYNC_HINT
      *iv_return = FLAG_VSYNC_HINT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "KEY_KP_SUBTRAC", 14)) {
    /*                             T      */
#ifdef KEY_KP_SUBTRACT
      *iv_return = KEY_KP_SUBTRACT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "KEY_RIGHT_SHIF", 14)) {
    /*                             T      */
#ifdef KEY_RIGHT_SHIFT
      *iv_return = KEY_RIGHT_SHIFT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'W':
    if (memEQ(name, "LOC_MATRIX_VIE", 14)) {
    /*                             W      */
      *iv_return = LOC_MATRIX_VIEW;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LOC_VECTOR_VIE", 14)) {
    /*                             W      */
      *iv_return = LOC_VECTOR_VIEW;
      return PERL_constant_ISIV;
    }
    break;
  case 'Y':
    if (memEQ(name, "KEY_KP_MULTIPL", 14)) {
    /*                             Y      */
#ifdef KEY_KP_MULTIPLY
      *iv_return = KEY_KP_MULTIPLY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_16 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     BLEND_MULTIPLIED FILTER_TRILINEAR GESTURE_PINCH_IN GESTURE_SWIPE_UP
     KEY_LEFT_BRACKET KEY_LEFT_CONTROL KEY_PRINT_SCREEN LOC_MAP_EMISSION
     LOC_MAP_SPECULAR LOC_MATRIX_MODEL LOC_VERTEX_COLOR MAX_TOUCH_POINTS
     UNCOMPRESSED_R32 */
  /* Offset 12 gives the best switch position.  */
  switch (name[12]) {
  case 'C':
    if (memEQ(name, "KEY_LEFT_BRACKET", 16)) {
    /*                           ^          */
#ifdef KEY_LEFT_BRACKET
      *iv_return = KEY_LEFT_BRACKET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "GESTURE_SWIPE_UP", 16)) {
    /*                           ^          */
      *iv_return = GESTURE_SWIPE_UP;
      return PERL_constant_ISIV;
    }
    break;
  case 'H':
    if (memEQ(name, "GESTURE_PINCH_IN", 16)) {
    /*                           ^          */
      *iv_return = GESTURE_PINCH_IN;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "MAX_TOUCH_POINTS", 16)) {
    /*                           ^          */
#ifdef MAX_TOUCH_POINTS
      *iv_return = MAX_TOUCH_POINTS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "BLEND_MULTIPLIED", 16)) {
    /*                           ^          */
      *iv_return = BLEND_MULTIPLIED;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "FILTER_TRILINEAR", 16)) {
    /*                           ^          */
      *iv_return = FILTER_TRILINEAR;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "LOC_MATRIX_MODEL", 16)) {
    /*                           ^          */
      *iv_return = LOC_MATRIX_MODEL;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LOC_VERTEX_COLOR", 16)) {
    /*                           ^          */
      *iv_return = LOC_VERTEX_COLOR;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "KEY_PRINT_SCREEN", 16)) {
    /*                           ^          */
#ifdef KEY_PRINT_SCREEN
      *iv_return = KEY_PRINT_SCREEN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "LOC_MAP_EMISSION", 16)) {
    /*                           ^          */
      *iv_return = LOC_MAP_EMISSION;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "KEY_LEFT_CONTROL", 16)) {
    /*                           ^          */
#ifdef KEY_LEFT_CONTROL
      *iv_return = KEY_LEFT_CONTROL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "LOC_MAP_SPECULAR", 16)) {
    /*                           ^          */
#ifdef LOC_MAP_SPECULAR
      *iv_return = LOC_MAP_SPECULAR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "UNCOMPRESSED_R32", 16)) {
    /*                           ^          */
      *iv_return = UNCOMPRESSED_R32;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_17 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     FLAG_MSAA_4X_HINT GESTURE_DOUBLETAP GESTURE_PINCH_OUT KEY_RIGHT_BRACKET
     KEY_RIGHT_CONTROL LOC_COLOR_AMBIENT LOC_COLOR_DIFFUSE LOC_MAP_METALNESS
     LOC_MAP_OCCLUSION LOC_MAP_PREFILTER LOC_MAP_ROUGHNESS LOC_VERTEX_NORMAL
     MAX_MATERIAL_MAPS MOUSE_LEFT_BUTTON */
  /* Offset 11 gives the best switch position.  */
  switch (name[11]) {
  case 'A':
    if (memEQ(name, "LOC_MAP_METALNESS", 17)) {
    /*                          ^            */
      *iv_return = LOC_MAP_METALNESS;
      return PERL_constant_ISIV;
    }
    break;
  case 'B':
    if (memEQ(name, "GESTURE_DOUBLETAP", 17)) {
    /*                          ^            */
      *iv_return = GESTURE_DOUBLETAP;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "MOUSE_LEFT_BUTTON", 17)) {
    /*                          ^            */
#ifdef MOUSE_LEFT_BUTTON
      *iv_return = MOUSE_LEFT_BUTTON;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "GESTURE_PINCH_OUT", 17)) {
    /*                          ^            */
      *iv_return = GESTURE_PINCH_OUT;
      return PERL_constant_ISIV;
    }
    break;
  case 'F':
    if (memEQ(name, "LOC_MAP_PREFILTER", 17)) {
    /*                          ^            */
      *iv_return = LOC_MAP_PREFILTER;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "LOC_MAP_ROUGHNESS", 17)) {
    /*                          ^            */
      *iv_return = LOC_MAP_ROUGHNESS;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "LOC_COLOR_DIFFUSE", 17)) {
    /*                          ^            */
      *iv_return = LOC_COLOR_DIFFUSE;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "LOC_MAP_OCCLUSION", 17)) {
    /*                          ^            */
      *iv_return = LOC_MAP_OCCLUSION;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "MAX_MATERIAL_MAPS", 17)) {
    /*                          ^            */
#ifdef MAX_MATERIAL_MAPS
      *iv_return = MAX_MATERIAL_MAPS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "LOC_COLOR_AMBIENT", 17)) {
    /*                          ^            */
      *iv_return = LOC_COLOR_AMBIENT;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "LOC_VERTEX_NORMAL", 17)) {
    /*                          ^            */
      *iv_return = LOC_VERTEX_NORMAL;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "KEY_RIGHT_CONTROL", 17)) {
    /*                          ^            */
#ifdef KEY_RIGHT_CONTROL
      *iv_return = KEY_RIGHT_CONTROL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "KEY_RIGHT_BRACKET", 17)) {
    /*                          ^            */
#ifdef KEY_RIGHT_BRACKET
      *iv_return = KEY_RIGHT_BRACKET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "FLAG_MSAA_4X_HINT", 17)) {
    /*                          ^            */
#ifdef FLAG_MSAA_4X_HINT
      *iv_return = FLAG_MSAA_4X_HINT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_18 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CAMERA_PERSPECTIVE GESTURE_SWIPE_DOWN GESTURE_SWIPE_LEFT
     HMD_DEFAULT_DEVICE HMD_VALVE_HTC_VIVE LOC_COLOR_SPECULAR
     LOC_MAP_IRRADIANCE LOC_VERTEX_TANGENT MOUSE_RIGHT_BUTTON */
  /* Offset 4 gives the best switch position.  */
  switch (name[4]) {
  case 'C':
    if (memEQ(name, "LOC_COLOR_SPECULAR", 18)) {
    /*                   ^                    */
      *iv_return = LOC_COLOR_SPECULAR;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "HMD_DEFAULT_DEVICE", 18)) {
    /*                   ^                    */
      *iv_return = HMD_DEFAULT_DEVICE;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "MOUSE_RIGHT_BUTTON", 18)) {
    /*                   ^                    */
#ifdef MOUSE_RIGHT_BUTTON
      *iv_return = MOUSE_RIGHT_BUTTON;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "LOC_MAP_IRRADIANCE", 18)) {
    /*                   ^                    */
      *iv_return = LOC_MAP_IRRADIANCE;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "CAMERA_PERSPECTIVE", 18)) {
    /*                   ^                    */
      *iv_return = CAMERA_PERSPECTIVE;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "GESTURE_SWIPE_DOWN", 18)) {
    /*                   ^                    */
      *iv_return = GESTURE_SWIPE_DOWN;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "GESTURE_SWIPE_LEFT", 18)) {
    /*                   ^                    */
      *iv_return = GESTURE_SWIPE_LEFT;
      return PERL_constant_ISIV;
    }
    break;
  case 'V':
    if (memEQ(name, "HMD_VALVE_HTC_VIVE", 18)) {
    /*                   ^                    */
      *iv_return = HMD_VALVE_HTC_VIVE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "LOC_VERTEX_TANGENT", 18)) {
    /*                   ^                    */
      *iv_return = LOC_VERTEX_TANGENT;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_19 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CAMERA_FIRST_PERSON CAMERA_ORTHOGRAPHIC CAMERA_THIRD_PERSON
     COMPRESSED_DXT1_RGB COMPRESSED_ETC1_RGB COMPRESSED_ETC2_RGB
     COMPRESSED_PVRT_RGB GAMEPAD_PS3_AXIS_L2 GAMEPAD_PS3_AXIS_R2
     GESTURE_SWIPE_RIGHT HMD_OCULUS_RIFT_CV1 HMD_OCULUS_RIFT_DK2
     LOC_VERTEX_POSITION MOUSE_MIDDLE_BUTTON NPT_3PATCH_VERTICAL
     UNCOMPRESSED_R5G6B5 UNCOMPRESSED_R8G8B8 */
  /* Offset 16 gives the best switch position.  */
  switch (name[16]) {
  case '6':
    if (memEQ(name, "UNCOMPRESSED_R5G6B5", 19)) {
    /*                               ^         */
      *iv_return = UNCOMPRESSED_R5G6B5;
      return PERL_constant_ISIV;
    }
    break;
  case '8':
    if (memEQ(name, "UNCOMPRESSED_R8G8B8", 19)) {
    /*                               ^         */
      *iv_return = UNCOMPRESSED_R8G8B8;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "HMD_OCULUS_RIFT_CV1", 19)) {
    /*                               ^         */
      *iv_return = HMD_OCULUS_RIFT_CV1;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "NPT_3PATCH_VERTICAL", 19)) {
    /*                               ^         */
      *iv_return = NPT_3PATCH_VERTICAL;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "HMD_OCULUS_RIFT_DK2", 19)) {
    /*                               ^         */
      *iv_return = HMD_OCULUS_RIFT_DK2;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "GESTURE_SWIPE_RIGHT", 19)) {
    /*                               ^         */
      *iv_return = GESTURE_SWIPE_RIGHT;
      return PERL_constant_ISIV;
    }
    break;
  case 'H':
    if (memEQ(name, "CAMERA_ORTHOGRAPHIC", 19)) {
    /*                               ^         */
      *iv_return = CAMERA_ORTHOGRAPHIC;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "LOC_VERTEX_POSITION", 19)) {
    /*                               ^         */
      *iv_return = LOC_VERTEX_POSITION;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "COMPRESSED_DXT1_RGB", 19)) {
    /*                               ^         */
      *iv_return = COMPRESSED_DXT1_RGB;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "COMPRESSED_ETC1_RGB", 19)) {
    /*                               ^         */
      *iv_return = COMPRESSED_ETC1_RGB;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "COMPRESSED_ETC2_RGB", 19)) {
    /*                               ^         */
      *iv_return = COMPRESSED_ETC2_RGB;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "COMPRESSED_PVRT_RGB", 19)) {
    /*                               ^         */
      *iv_return = COMPRESSED_PVRT_RGB;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "CAMERA_FIRST_PERSON", 19)) {
    /*                               ^         */
      *iv_return = CAMERA_FIRST_PERSON;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "CAMERA_THIRD_PERSON", 19)) {
    /*                               ^         */
      *iv_return = CAMERA_THIRD_PERSON;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "MOUSE_MIDDLE_BUTTON", 19)) {
    /*                               ^         */
#ifdef MOUSE_MIDDLE_BUTTON
      *iv_return = MOUSE_MIDDLE_BUTTON;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "GAMEPAD_PS3_AXIS_L2", 19)) {
    /*                               ^         */
#ifdef GAMEPAD_PS3_AXIS_L2
      *iv_return = GAMEPAD_PS3_AXIS_L2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GAMEPAD_PS3_AXIS_R2", 19)) {
    /*                               ^         */
#ifdef GAMEPAD_PS3_AXIS_R2
      *iv_return = GAMEPAD_PS3_AXIS_R2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_20 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     COMPRESSED_DXT1_RGBA COMPRESSED_DXT3_RGBA COMPRESSED_DXT5_RGBA
     COMPRESSED_PVRT_RGBA FLAG_FULLSCREEN_MODE GAMEPAD_XBOX_AXIS_LT
     GAMEPAD_XBOX_AXIS_RT MAX_SHADER_LOCATIONS */
  /* Offset 14 gives the best switch position.  */
  switch (name[14]) {
  case '1':
    if (memEQ(name, "COMPRESSED_DXT1_RGBA", 20)) {
    /*                             ^            */
      *iv_return = COMPRESSED_DXT1_RGBA;
      return PERL_constant_ISIV;
    }
    break;
  case '3':
    if (memEQ(name, "COMPRESSED_DXT3_RGBA", 20)) {
    /*                             ^            */
      *iv_return = COMPRESSED_DXT3_RGBA;
      return PERL_constant_ISIV;
    }
    break;
  case '5':
    if (memEQ(name, "COMPRESSED_DXT5_RGBA", 20)) {
    /*                             ^            */
      *iv_return = COMPRESSED_DXT5_RGBA;
      return PERL_constant_ISIV;
    }
    break;
  case 'A':
    if (memEQ(name, "MAX_SHADER_LOCATIONS", 20)) {
    /*                             ^            */
#ifdef MAX_SHADER_LOCATIONS
      *iv_return = MAX_SHADER_LOCATIONS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "FLAG_FULLSCREEN_MODE", 20)) {
    /*                             ^            */
#ifdef FLAG_FULLSCREEN_MODE
      *iv_return = FLAG_FULLSCREEN_MODE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "COMPRESSED_PVRT_RGBA", 20)) {
    /*                             ^            */
      *iv_return = COMPRESSED_PVRT_RGBA;
      return PERL_constant_ISIV;
    }
    break;
  case 'X':
    if (memEQ(name, "GAMEPAD_XBOX_AXIS_LT", 20)) {
    /*                             ^            */
#ifdef GAMEPAD_XBOX_AXIS_LT
      *iv_return = GAMEPAD_XBOX_AXIS_LT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GAMEPAD_XBOX_AXIS_RT", 20)) {
    /*                             ^            */
#ifdef GAMEPAD_XBOX_AXIS_RT
      *iv_return = GAMEPAD_XBOX_AXIS_RT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_21 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     FILTER_ANISOTROPIC_4X FILTER_ANISOTROPIC_8X FLAG_WINDOW_RESIZABLE
     GAMEPAD_PS3_BUTTON_L1 GAMEPAD_PS3_BUTTON_L2 GAMEPAD_PS3_BUTTON_PS
     GAMEPAD_PS3_BUTTON_R1 GAMEPAD_PS3_BUTTON_R2 GAMEPAD_PS3_BUTTON_UP
     GAMEPAD_XBOX_BUTTON_A GAMEPAD_XBOX_BUTTON_B GAMEPAD_XBOX_BUTTON_X
     GAMEPAD_XBOX_BUTTON_Y LOC_MATRIX_PROJECTION LOC_VERTEX_TEXCOORD01
     LOC_VERTEX_TEXCOORD02 NPT_3PATCH_HORIZONTAL UNCOMPRESSED_R4G4B4A4
     UNCOMPRESSED_R5G5B5A1 UNCOMPRESSED_R8G8B8A8 */
  /* Offset 20 gives the best switch position.  */
  switch (name[20]) {
  case '1':
    if (memEQ(name, "GAMEPAD_PS3_BUTTON_L", 20)) {
    /*                                   1      */
#ifdef GAMEPAD_PS3_BUTTON_L1
      *iv_return = GAMEPAD_PS3_BUTTON_L1;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GAMEPAD_PS3_BUTTON_R", 20)) {
    /*                                   1      */
#ifdef GAMEPAD_PS3_BUTTON_R1
      *iv_return = GAMEPAD_PS3_BUTTON_R1;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "LOC_VERTEX_TEXCOORD0", 20)) {
    /*                                   1      */
      *iv_return = LOC_VERTEX_TEXCOORD01;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UNCOMPRESSED_R5G5B5A", 20)) {
    /*                                   1      */
      *iv_return = UNCOMPRESSED_R5G5B5A1;
      return PERL_constant_ISIV;
    }
    break;
  case '2':
    if (memEQ(name, "GAMEPAD_PS3_BUTTON_L", 20)) {
    /*                                   2      */
#ifdef GAMEPAD_PS3_BUTTON_L2
      *iv_return = GAMEPAD_PS3_BUTTON_L2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GAMEPAD_PS3_BUTTON_R", 20)) {
    /*                                   2      */
#ifdef GAMEPAD_PS3_BUTTON_R2
      *iv_return = GAMEPAD_PS3_BUTTON_R2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "LOC_VERTEX_TEXCOORD0", 20)) {
    /*                                   2      */
      *iv_return = LOC_VERTEX_TEXCOORD02;
      return PERL_constant_ISIV;
    }
    break;
  case '4':
    if (memEQ(name, "UNCOMPRESSED_R4G4B4A", 20)) {
    /*                                   4      */
      *iv_return = UNCOMPRESSED_R4G4B4A4;
      return PERL_constant_ISIV;
    }
    break;
  case '8':
    if (memEQ(name, "UNCOMPRESSED_R8G8B8A", 20)) {
    /*                                   8      */
      *iv_return = UNCOMPRESSED_R8G8B8A8;
      return PERL_constant_ISIV;
    }
    break;
  case 'A':
    if (memEQ(name, "GAMEPAD_XBOX_BUTTON_", 20)) {
    /*                                   A      */
#ifdef GAMEPAD_XBOX_BUTTON_A
      *iv_return = GAMEPAD_XBOX_BUTTON_A;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "GAMEPAD_XBOX_BUTTON_", 20)) {
    /*                                   B      */
#ifdef GAMEPAD_XBOX_BUTTON_B
      *iv_return = GAMEPAD_XBOX_BUTTON_B;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "FLAG_WINDOW_RESIZABL", 20)) {
    /*                                   E      */
#ifdef FLAG_WINDOW_RESIZABLE
      *iv_return = FLAG_WINDOW_RESIZABLE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "NPT_3PATCH_HORIZONTA", 20)) {
    /*                                   L      */
      *iv_return = NPT_3PATCH_HORIZONTAL;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "LOC_MATRIX_PROJECTIO", 20)) {
    /*                                   N      */
      *iv_return = LOC_MATRIX_PROJECTION;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "GAMEPAD_PS3_BUTTON_U", 20)) {
    /*                                   P      */
#ifdef GAMEPAD_PS3_BUTTON_UP
      *iv_return = GAMEPAD_PS3_BUTTON_UP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "GAMEPAD_PS3_BUTTON_P", 20)) {
    /*                                   S      */
#ifdef GAMEPAD_PS3_BUTTON_PS
      *iv_return = GAMEPAD_PS3_BUTTON_PS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "FILTER_ANISOTROPIC_4", 20)) {
    /*                                   X      */
      *iv_return = FILTER_ANISOTROPIC_4X;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "FILTER_ANISOTROPIC_8", 20)) {
    /*                                   X      */
      *iv_return = FILTER_ANISOTROPIC_8X;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "GAMEPAD_XBOX_BUTTON_", 20)) {
    /*                                   X      */
#ifdef GAMEPAD_XBOX_BUTTON_X
      *iv_return = GAMEPAD_XBOX_BUTTON_X;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Y':
    if (memEQ(name, "GAMEPAD_XBOX_BUTTON_", 20)) {
    /*                                   Y      */
#ifdef GAMEPAD_XBOX_BUTTON_Y
      *iv_return = GAMEPAD_XBOX_BUTTON_Y;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_22 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     FILTER_ANISOTROPIC_16X GAMEPAD_XBOX_BUTTON_LB GAMEPAD_XBOX_BUTTON_RB
     GAMEPAD_XBOX_BUTTON_UP UNCOMPRESSED_GRAYSCALE UNCOMPRESSED_R32G32B32 */
  /* Offset 20 gives the best switch position.  */
  switch (name[20]) {
  case '3':
    if (memEQ(name, "UNCOMPRESSED_R32G32B32", 22)) {
    /*                                   ^        */
      *iv_return = UNCOMPRESSED_R32G32B32;
      return PERL_constant_ISIV;
    }
    break;
  case '6':
    if (memEQ(name, "FILTER_ANISOTROPIC_16X", 22)) {
    /*                                   ^        */
      *iv_return = FILTER_ANISOTROPIC_16X;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "GAMEPAD_XBOX_BUTTON_LB", 22)) {
    /*                                   ^        */
#ifdef GAMEPAD_XBOX_BUTTON_LB
      *iv_return = GAMEPAD_XBOX_BUTTON_LB;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "UNCOMPRESSED_GRAYSCALE", 22)) {
    /*                                   ^        */
      *iv_return = UNCOMPRESSED_GRAYSCALE;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "GAMEPAD_XBOX_BUTTON_RB", 22)) {
    /*                                   ^        */
#ifdef GAMEPAD_XBOX_BUTTON_RB
      *iv_return = GAMEPAD_XBOX_BUTTON_RB;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "GAMEPAD_XBOX_BUTTON_UP", 22)) {
    /*                                   ^        */
#ifdef GAMEPAD_XBOX_BUTTON_UP
      *iv_return = GAMEPAD_XBOX_BUTTON_UP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_23 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     FLAG_WINDOW_TRANSPARENT FLAG_WINDOW_UNDECORATED GAMEPAD_ANDROID_DPAD_UP
     GAMEPAD_PS3_AXIS_LEFT_X GAMEPAD_PS3_AXIS_LEFT_Y GAMEPAD_PS3_BUTTON_DOWN
     GAMEPAD_PS3_BUTTON_LEFT UNCOMPRESSED_GRAY_ALPHA */
  /* Offset 22 gives the best switch position.  */
  switch (name[22]) {
  case 'A':
    if (memEQ(name, "UNCOMPRESSED_GRAY_ALPH", 22)) {
    /*                                     A      */
      *iv_return = UNCOMPRESSED_GRAY_ALPHA;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "FLAG_WINDOW_UNDECORATE", 22)) {
    /*                                     D      */
#ifdef FLAG_WINDOW_UNDECORATED
      *iv_return = FLAG_WINDOW_UNDECORATED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "GAMEPAD_PS3_BUTTON_DOW", 22)) {
    /*                                     N      */
#ifdef GAMEPAD_PS3_BUTTON_DOWN
      *iv_return = GAMEPAD_PS3_BUTTON_DOWN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "GAMEPAD_ANDROID_DPAD_U", 22)) {
    /*                                     P      */
#ifdef GAMEPAD_ANDROID_DPAD_UP
      *iv_return = GAMEPAD_ANDROID_DPAD_UP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "FLAG_WINDOW_TRANSPAREN", 22)) {
    /*                                     T      */
#ifdef FLAG_WINDOW_TRANSPARENT
      *iv_return = FLAG_WINDOW_TRANSPARENT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GAMEPAD_PS3_BUTTON_LEF", 22)) {
    /*                                     T      */
#ifdef GAMEPAD_PS3_BUTTON_LEFT
      *iv_return = GAMEPAD_PS3_BUTTON_LEFT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "GAMEPAD_PS3_AXIS_LEFT_", 22)) {
    /*                                     X      */
#ifdef GAMEPAD_PS3_AXIS_LEFT_X
      *iv_return = GAMEPAD_PS3_AXIS_LEFT_X;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Y':
    if (memEQ(name, "GAMEPAD_PS3_AXIS_LEFT_", 22)) {
    /*                                     Y      */
#ifdef GAMEPAD_PS3_AXIS_LEFT_Y
      *iv_return = GAMEPAD_PS3_AXIS_LEFT_Y;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_24 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     COMPRESSED_ASTC_4x4_RGBA COMPRESSED_ASTC_8x8_RGBA COMPRESSED_ETC2_EAC_RGBA
     GAMEPAD_ANDROID_BUTTON_A GAMEPAD_ANDROID_BUTTON_B GAMEPAD_ANDROID_BUTTON_C
     GAMEPAD_ANDROID_BUTTON_X GAMEPAD_ANDROID_BUTTON_Y GAMEPAD_ANDROID_BUTTON_Z
     GAMEPAD_PS3_AXIS_RIGHT_X GAMEPAD_PS3_AXIS_RIGHT_Y GAMEPAD_PS3_BUTTON_CROSS
     GAMEPAD_PS3_BUTTON_RIGHT GAMEPAD_PS3_BUTTON_START GAMEPAD_XBOX_AXIS_LEFT_X
     GAMEPAD_XBOX_AXIS_LEFT_Y GAMEPAD_XBOX_BUTTON_DOWN GAMEPAD_XBOX_BUTTON_HOME
     GAMEPAD_XBOX_BUTTON_LEFT */
  /* Offset 23 gives the best switch position.  */
  switch (name[23]) {
  case 'A':
    if (memEQ(name, "COMPRESSED_ASTC_4x4_RGB", 23)) {
    /*                                      A      */
      *iv_return = COMPRESSED_ASTC_4x4_RGBA;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "COMPRESSED_ASTC_8x8_RGB", 23)) {
    /*                                      A      */
      *iv_return = COMPRESSED_ASTC_8x8_RGBA;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "COMPRESSED_ETC2_EAC_RGB", 23)) {
    /*                                      A      */
      *iv_return = COMPRESSED_ETC2_EAC_RGBA;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "GAMEPAD_ANDROID_BUTTON_", 23)) {
    /*                                      A      */
#ifdef GAMEPAD_ANDROID_BUTTON_A
      *iv_return = GAMEPAD_ANDROID_BUTTON_A;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "GAMEPAD_ANDROID_BUTTON_", 23)) {
    /*                                      B      */
#ifdef GAMEPAD_ANDROID_BUTTON_B
      *iv_return = GAMEPAD_ANDROID_BUTTON_B;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "GAMEPAD_ANDROID_BUTTON_", 23)) {
    /*                                      C      */
#ifdef GAMEPAD_ANDROID_BUTTON_C
      *iv_return = GAMEPAD_ANDROID_BUTTON_C;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "GAMEPAD_XBOX_BUTTON_HOM", 23)) {
    /*                                      E      */
#ifdef GAMEPAD_XBOX_BUTTON_HOME
      *iv_return = GAMEPAD_XBOX_BUTTON_HOME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "GAMEPAD_XBOX_BUTTON_DOW", 23)) {
    /*                                      N      */
#ifdef GAMEPAD_XBOX_BUTTON_DOWN
      *iv_return = GAMEPAD_XBOX_BUTTON_DOWN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "GAMEPAD_PS3_BUTTON_CROS", 23)) {
    /*                                      S      */
#ifdef GAMEPAD_PS3_BUTTON_CROSS
      *iv_return = GAMEPAD_PS3_BUTTON_CROSS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "GAMEPAD_PS3_BUTTON_RIGH", 23)) {
    /*                                      T      */
#ifdef GAMEPAD_PS3_BUTTON_RIGHT
      *iv_return = GAMEPAD_PS3_BUTTON_RIGHT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GAMEPAD_PS3_BUTTON_STAR", 23)) {
    /*                                      T      */
#ifdef GAMEPAD_PS3_BUTTON_START
      *iv_return = GAMEPAD_PS3_BUTTON_START;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GAMEPAD_XBOX_BUTTON_LEF", 23)) {
    /*                                      T      */
#ifdef GAMEPAD_XBOX_BUTTON_LEFT
      *iv_return = GAMEPAD_XBOX_BUTTON_LEFT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "GAMEPAD_ANDROID_BUTTON_", 23)) {
    /*                                      X      */
#ifdef GAMEPAD_ANDROID_BUTTON_X
      *iv_return = GAMEPAD_ANDROID_BUTTON_X;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GAMEPAD_PS3_AXIS_RIGHT_", 23)) {
    /*                                      X      */
#ifdef GAMEPAD_PS3_AXIS_RIGHT_X
      *iv_return = GAMEPAD_PS3_AXIS_RIGHT_X;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GAMEPAD_XBOX_AXIS_LEFT_", 23)) {
    /*                                      X      */
#ifdef GAMEPAD_XBOX_AXIS_LEFT_X
      *iv_return = GAMEPAD_XBOX_AXIS_LEFT_X;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Y':
    if (memEQ(name, "GAMEPAD_ANDROID_BUTTON_", 23)) {
    /*                                      Y      */
#ifdef GAMEPAD_ANDROID_BUTTON_Y
      *iv_return = GAMEPAD_ANDROID_BUTTON_Y;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GAMEPAD_PS3_AXIS_RIGHT_", 23)) {
    /*                                      Y      */
#ifdef GAMEPAD_PS3_AXIS_RIGHT_Y
      *iv_return = GAMEPAD_PS3_AXIS_RIGHT_Y;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GAMEPAD_XBOX_AXIS_LEFT_", 23)) {
    /*                                      Y      */
#ifdef GAMEPAD_XBOX_AXIS_LEFT_Y
      *iv_return = GAMEPAD_XBOX_AXIS_LEFT_Y;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Z':
    if (memEQ(name, "GAMEPAD_ANDROID_BUTTON_", 23)) {
    /*                                      Z      */
#ifdef GAMEPAD_ANDROID_BUTTON_Z
      *iv_return = GAMEPAD_ANDROID_BUTTON_Z;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_25 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     GAMEPAD_ANDROID_BUTTON_L1 GAMEPAD_ANDROID_BUTTON_L2
     GAMEPAD_ANDROID_BUTTON_R1 GAMEPAD_ANDROID_BUTTON_R2
     GAMEPAD_ANDROID_DPAD_DOWN GAMEPAD_ANDROID_DPAD_LEFT
     GAMEPAD_PS3_BUTTON_CIRCLE GAMEPAD_PS3_BUTTON_SELECT
     GAMEPAD_PS3_BUTTON_SQUARE GAMEPAD_XBOX_AXIS_RIGHT_X
     GAMEPAD_XBOX_AXIS_RIGHT_Y GAMEPAD_XBOX_BUTTON_RIGHT
     GAMEPAD_XBOX_BUTTON_START UNCOMPRESSED_R32G32B32A32 */
  /* Offset 21 gives the best switch position.  */
  switch (name[21]) {
  case '2':
    if (memEQ(name, "UNCOMPRESSED_R32G32B32A32", 25)) {
    /*                                    ^          */
      *iv_return = UNCOMPRESSED_R32G32B32A32;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "GAMEPAD_ANDROID_DPAD_DOWN", 25)) {
    /*                                    ^          */
#ifdef GAMEPAD_ANDROID_DPAD_DOWN
      *iv_return = GAMEPAD_ANDROID_DPAD_DOWN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "GAMEPAD_XBOX_AXIS_RIGHT_X", 25)) {
    /*                                    ^          */
#ifdef GAMEPAD_XBOX_AXIS_RIGHT_X
      *iv_return = GAMEPAD_XBOX_AXIS_RIGHT_X;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GAMEPAD_XBOX_AXIS_RIGHT_Y", 25)) {
    /*                                    ^          */
#ifdef GAMEPAD_XBOX_AXIS_RIGHT_Y
      *iv_return = GAMEPAD_XBOX_AXIS_RIGHT_Y;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "GAMEPAD_XBOX_BUTTON_RIGHT", 25)) {
    /*                                    ^          */
#ifdef GAMEPAD_XBOX_BUTTON_RIGHT
      *iv_return = GAMEPAD_XBOX_BUTTON_RIGHT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "GAMEPAD_ANDROID_DPAD_LEFT", 25)) {
    /*                                    ^          */
#ifdef GAMEPAD_ANDROID_DPAD_LEFT
      *iv_return = GAMEPAD_ANDROID_DPAD_LEFT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GAMEPAD_PS3_BUTTON_SELECT", 25)) {
    /*                                    ^          */
#ifdef GAMEPAD_PS3_BUTTON_SELECT
      *iv_return = GAMEPAD_PS3_BUTTON_SELECT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "GAMEPAD_ANDROID_BUTTON_L1", 25)) {
    /*                                    ^          */
#ifdef GAMEPAD_ANDROID_BUTTON_L1
      *iv_return = GAMEPAD_ANDROID_BUTTON_L1;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GAMEPAD_ANDROID_BUTTON_L2", 25)) {
    /*                                    ^          */
#ifdef GAMEPAD_ANDROID_BUTTON_L2
      *iv_return = GAMEPAD_ANDROID_BUTTON_L2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GAMEPAD_ANDROID_BUTTON_R1", 25)) {
    /*                                    ^          */
#ifdef GAMEPAD_ANDROID_BUTTON_R1
      *iv_return = GAMEPAD_ANDROID_BUTTON_R1;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GAMEPAD_ANDROID_BUTTON_R2", 25)) {
    /*                                    ^          */
#ifdef GAMEPAD_ANDROID_BUTTON_R2
      *iv_return = GAMEPAD_ANDROID_BUTTON_R2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "GAMEPAD_PS3_BUTTON_CIRCLE", 25)) {
    /*                                    ^          */
#ifdef GAMEPAD_PS3_BUTTON_CIRCLE
      *iv_return = GAMEPAD_PS3_BUTTON_CIRCLE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "GAMEPAD_XBOX_BUTTON_START", 25)) {
    /*                                    ^          */
#ifdef GAMEPAD_XBOX_BUTTON_START
      *iv_return = GAMEPAD_XBOX_BUTTON_START;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "GAMEPAD_PS3_BUTTON_SQUARE", 25)) {
    /*                                    ^          */
#ifdef GAMEPAD_PS3_BUTTON_SQUARE
      *iv_return = GAMEPAD_PS3_BUTTON_SQUARE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant (pTHX_ const char *name, STRLEN len, IV *iv_return) {
  /* Initially switch on the length of the name.  */
  /* When generated this function returned values for the list of names given
     in this section of perl code.  Rather than manually editing these functions
     to add or remove constants, which would result in this comment and section
     of code becoming inaccurate, we recommend that you edit this section of
     code, and use it to regenerate a new set of constant functions which you
     then use to replace the originals.

     Regenerate these constant functions by feeding this entire source file to
     perl -x

#!/usr/local/Cellar/perl/5.28.1/bin/perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(DEG2RAD FLAG_FULLSCREEN_MODE FLAG_MSAA_4X_HINT FLAG_SHOW_LOGO
	       FLAG_VSYNC_HINT FLAG_WINDOW_RESIZABLE FLAG_WINDOW_TRANSPARENT
	       FLAG_WINDOW_UNDECORATED GAMEPAD_ANDROID_BUTTON_A
	       GAMEPAD_ANDROID_BUTTON_B GAMEPAD_ANDROID_BUTTON_C
	       GAMEPAD_ANDROID_BUTTON_L1 GAMEPAD_ANDROID_BUTTON_L2
	       GAMEPAD_ANDROID_BUTTON_R1 GAMEPAD_ANDROID_BUTTON_R2
	       GAMEPAD_ANDROID_BUTTON_X GAMEPAD_ANDROID_BUTTON_Y
	       GAMEPAD_ANDROID_BUTTON_Z GAMEPAD_ANDROID_DPAD_CENTER
	       GAMEPAD_ANDROID_DPAD_DOWN GAMEPAD_ANDROID_DPAD_LEFT
	       GAMEPAD_ANDROID_DPAD_RIGHT GAMEPAD_ANDROID_DPAD_UP
	       GAMEPAD_PLAYER1 GAMEPAD_PLAYER2 GAMEPAD_PLAYER3 GAMEPAD_PLAYER4
	       GAMEPAD_PS3_AXIS_L2 GAMEPAD_PS3_AXIS_LEFT_X
	       GAMEPAD_PS3_AXIS_LEFT_Y GAMEPAD_PS3_AXIS_R2
	       GAMEPAD_PS3_AXIS_RIGHT_X GAMEPAD_PS3_AXIS_RIGHT_Y
	       GAMEPAD_PS3_BUTTON_CIRCLE GAMEPAD_PS3_BUTTON_CROSS
	       GAMEPAD_PS3_BUTTON_DOWN GAMEPAD_PS3_BUTTON_L1
	       GAMEPAD_PS3_BUTTON_L2 GAMEPAD_PS3_BUTTON_LEFT
	       GAMEPAD_PS3_BUTTON_PS GAMEPAD_PS3_BUTTON_R1
	       GAMEPAD_PS3_BUTTON_R2 GAMEPAD_PS3_BUTTON_RIGHT
	       GAMEPAD_PS3_BUTTON_SELECT GAMEPAD_PS3_BUTTON_SQUARE
	       GAMEPAD_PS3_BUTTON_START GAMEPAD_PS3_BUTTON_TRIANGLE
	       GAMEPAD_PS3_BUTTON_UP GAMEPAD_XBOX_AXIS_LEFT_X
	       GAMEPAD_XBOX_AXIS_LEFT_Y GAMEPAD_XBOX_AXIS_LT
	       GAMEPAD_XBOX_AXIS_RIGHT_X GAMEPAD_XBOX_AXIS_RIGHT_Y
	       GAMEPAD_XBOX_AXIS_RT GAMEPAD_XBOX_BUTTON_A GAMEPAD_XBOX_BUTTON_B
	       GAMEPAD_XBOX_BUTTON_DOWN GAMEPAD_XBOX_BUTTON_HOME
	       GAMEPAD_XBOX_BUTTON_LB GAMEPAD_XBOX_BUTTON_LEFT
	       GAMEPAD_XBOX_BUTTON_RB GAMEPAD_XBOX_BUTTON_RIGHT
	       GAMEPAD_XBOX_BUTTON_SELECT GAMEPAD_XBOX_BUTTON_START
	       GAMEPAD_XBOX_BUTTON_UP GAMEPAD_XBOX_BUTTON_X
	       GAMEPAD_XBOX_BUTTON_Y KEY_A KEY_APOSTROPHE KEY_B KEY_BACK
	       KEY_BACKSLASH KEY_BACKSPACE KEY_C KEY_CAPS_LOCK KEY_COMMA KEY_D
	       KEY_DELETE KEY_DOWN KEY_E KEY_EIGHT KEY_END KEY_ENTER KEY_EQUAL
	       KEY_ESCAPE KEY_F KEY_F1 KEY_F10 KEY_F11 KEY_F12 KEY_F2 KEY_F3
	       KEY_F4 KEY_F5 KEY_F6 KEY_F7 KEY_F8 KEY_F9 KEY_FIVE KEY_FOUR
	       KEY_G KEY_GRAVE KEY_H KEY_HOME KEY_I KEY_INSERT KEY_J KEY_K
	       KEY_KB_MENU KEY_KP_0 KEY_KP_1 KEY_KP_2 KEY_KP_3 KEY_KP_4
	       KEY_KP_5 KEY_KP_6 KEY_KP_7 KEY_KP_8 KEY_KP_9 KEY_KP_ADD
	       KEY_KP_DECIMAL KEY_KP_DIVIDE KEY_KP_ENTER KEY_KP_EQUAL
	       KEY_KP_MULTIPLY KEY_KP_SUBTRACT KEY_L KEY_LEFT KEY_LEFT_ALT
	       KEY_LEFT_BRACKET KEY_LEFT_CONTROL KEY_LEFT_SHIFT KEY_LEFT_SUPER
	       KEY_M KEY_MENU KEY_MINUS KEY_N KEY_NINE KEY_NUM_LOCK KEY_O
	       KEY_ONE KEY_P KEY_PAGE_DOWN KEY_PAGE_UP KEY_PAUSE KEY_PERIOD
	       KEY_PRINT_SCREEN KEY_Q KEY_R KEY_RIGHT KEY_RIGHT_ALT
	       KEY_RIGHT_BRACKET KEY_RIGHT_CONTROL KEY_RIGHT_SHIFT
	       KEY_RIGHT_SUPER KEY_S KEY_SCROLL_LOCK KEY_SEMICOLON KEY_SEVEN
	       KEY_SIX KEY_SLASH KEY_SPACE KEY_T KEY_TAB KEY_THREE KEY_TWO
	       KEY_U KEY_UP KEY_V KEY_VOLUME_DOWN KEY_VOLUME_UP KEY_W KEY_X
	       KEY_Y KEY_Z KEY_ZERO LOC_MAP_DIFFUSE LOC_MAP_SPECULAR
	       MAP_DIFFUSE MAP_SPECULAR MAX_MATERIAL_MAPS MAX_SHADER_LOCATIONS
	       MAX_TOUCH_POINTS MOUSE_LEFT_BUTTON MOUSE_MIDDLE_BUTTON
	       MOUSE_RIGHT_BUTTON RAD2DEG),
            {name=>"BLEND_ADDITIVE", type=>"IV", macro=>"1"},
            {name=>"BLEND_ALPHA", type=>"IV", macro=>"1"},
            {name=>"BLEND_MULTIPLIED", type=>"IV", macro=>"1"},
            {name=>"CAMERA_CUSTOM", type=>"IV", macro=>"1"},
            {name=>"CAMERA_FIRST_PERSON", type=>"IV", macro=>"1"},
            {name=>"CAMERA_FREE", type=>"IV", macro=>"1"},
            {name=>"CAMERA_ORBITAL", type=>"IV", macro=>"1"},
            {name=>"CAMERA_ORTHOGRAPHIC", type=>"IV", macro=>"1"},
            {name=>"CAMERA_PERSPECTIVE", type=>"IV", macro=>"1"},
            {name=>"CAMERA_THIRD_PERSON", type=>"IV", macro=>"1"},
            {name=>"COMPRESSED_ASTC_4x4_RGBA", type=>"IV", macro=>"1"},
            {name=>"COMPRESSED_ASTC_8x8_RGBA", type=>"IV", macro=>"1"},
            {name=>"COMPRESSED_DXT1_RGB", type=>"IV", macro=>"1"},
            {name=>"COMPRESSED_DXT1_RGBA", type=>"IV", macro=>"1"},
            {name=>"COMPRESSED_DXT3_RGBA", type=>"IV", macro=>"1"},
            {name=>"COMPRESSED_DXT5_RGBA", type=>"IV", macro=>"1"},
            {name=>"COMPRESSED_ETC1_RGB", type=>"IV", macro=>"1"},
            {name=>"COMPRESSED_ETC2_EAC_RGBA", type=>"IV", macro=>"1"},
            {name=>"COMPRESSED_ETC2_RGB", type=>"IV", macro=>"1"},
            {name=>"COMPRESSED_PVRT_RGB", type=>"IV", macro=>"1"},
            {name=>"COMPRESSED_PVRT_RGBA", type=>"IV", macro=>"1"},
            {name=>"FILTER_ANISOTROPIC_16X", type=>"IV", macro=>"1"},
            {name=>"FILTER_ANISOTROPIC_4X", type=>"IV", macro=>"1"},
            {name=>"FILTER_ANISOTROPIC_8X", type=>"IV", macro=>"1"},
            {name=>"FILTER_BILINEAR", type=>"IV", macro=>"1"},
            {name=>"FILTER_POINT", type=>"IV", macro=>"1"},
            {name=>"FILTER_TRILINEAR", type=>"IV", macro=>"1"},
            {name=>"FONT_BITMAP", type=>"IV", macro=>"1"},
            {name=>"FONT_DEFAULT", type=>"IV", macro=>"1"},
            {name=>"FONT_SDF", type=>"IV", macro=>"1"},
            {name=>"GESTURE_DOUBLETAP", type=>"IV", macro=>"1"},
            {name=>"GESTURE_DRAG", type=>"IV", macro=>"1"},
            {name=>"GESTURE_HOLD", type=>"IV", macro=>"1"},
            {name=>"GESTURE_NONE", type=>"IV", macro=>"1"},
            {name=>"GESTURE_PINCH_IN", type=>"IV", macro=>"1"},
            {name=>"GESTURE_PINCH_OUT", type=>"IV", macro=>"1"},
            {name=>"GESTURE_SWIPE_DOWN", type=>"IV", macro=>"1"},
            {name=>"GESTURE_SWIPE_LEFT", type=>"IV", macro=>"1"},
            {name=>"GESTURE_SWIPE_RIGHT", type=>"IV", macro=>"1"},
            {name=>"GESTURE_SWIPE_UP", type=>"IV", macro=>"1"},
            {name=>"GESTURE_TAP", type=>"IV", macro=>"1"},
            {name=>"HMD_DEFAULT_DEVICE", type=>"IV", macro=>"1"},
            {name=>"HMD_OCULUS_GO", type=>"IV", macro=>"1"},
            {name=>"HMD_OCULUS_RIFT_CV1", type=>"IV", macro=>"1"},
            {name=>"HMD_OCULUS_RIFT_DK2", type=>"IV", macro=>"1"},
            {name=>"HMD_SONY_PSVR", type=>"IV", macro=>"1"},
            {name=>"HMD_VALVE_HTC_VIVE", type=>"IV", macro=>"1"},
            {name=>"LOC_COLOR_AMBIENT", type=>"IV", macro=>"1"},
            {name=>"LOC_COLOR_DIFFUSE", type=>"IV", macro=>"1"},
            {name=>"LOC_COLOR_SPECULAR", type=>"IV", macro=>"1"},
            {name=>"LOC_MAP_ALBEDO", type=>"IV", macro=>"1"},
            {name=>"LOC_MAP_BRDF", type=>"IV", macro=>"1"},
            {name=>"LOC_MAP_CUBEMAP", type=>"IV", macro=>"1"},
            {name=>"LOC_MAP_EMISSION", type=>"IV", macro=>"1"},
            {name=>"LOC_MAP_HEIGHT", type=>"IV", macro=>"1"},
            {name=>"LOC_MAP_IRRADIANCE", type=>"IV", macro=>"1"},
            {name=>"LOC_MAP_METALNESS", type=>"IV", macro=>"1"},
            {name=>"LOC_MAP_NORMAL", type=>"IV", macro=>"1"},
            {name=>"LOC_MAP_OCCLUSION", type=>"IV", macro=>"1"},
            {name=>"LOC_MAP_PREFILTER", type=>"IV", macro=>"1"},
            {name=>"LOC_MAP_ROUGHNESS", type=>"IV", macro=>"1"},
            {name=>"LOC_MATRIX_MODEL", type=>"IV", macro=>"1"},
            {name=>"LOC_MATRIX_MVP", type=>"IV", macro=>"1"},
            {name=>"LOC_MATRIX_PROJECTION", type=>"IV", macro=>"1"},
            {name=>"LOC_MATRIX_VIEW", type=>"IV", macro=>"1"},
            {name=>"LOC_VECTOR_VIEW", type=>"IV", macro=>"1"},
            {name=>"LOC_VERTEX_COLOR", type=>"IV", macro=>"1"},
            {name=>"LOC_VERTEX_NORMAL", type=>"IV", macro=>"1"},
            {name=>"LOC_VERTEX_POSITION", type=>"IV", macro=>"1"},
            {name=>"LOC_VERTEX_TANGENT", type=>"IV", macro=>"1"},
            {name=>"LOC_VERTEX_TEXCOORD01", type=>"IV", macro=>"1"},
            {name=>"LOC_VERTEX_TEXCOORD02", type=>"IV", macro=>"1"},
            {name=>"LOG_DEBUG", type=>"IV", macro=>"1"},
            {name=>"LOG_ERROR", type=>"IV", macro=>"1"},
            {name=>"LOG_INFO", type=>"IV", macro=>"1"},
            {name=>"LOG_OTHER", type=>"IV", macro=>"1"},
            {name=>"LOG_WARNING", type=>"IV", macro=>"1"},
            {name=>"MAP_ALBEDO", type=>"IV", macro=>"1"},
            {name=>"MAP_BRDF", type=>"IV", macro=>"1"},
            {name=>"MAP_CUBEMAP", type=>"IV", macro=>"1"},
            {name=>"MAP_EMISSION", type=>"IV", macro=>"1"},
            {name=>"MAP_HEIGHT", type=>"IV", macro=>"1"},
            {name=>"MAP_IRRADIANCE", type=>"IV", macro=>"1"},
            {name=>"MAP_METALNESS", type=>"IV", macro=>"1"},
            {name=>"MAP_NORMAL", type=>"IV", macro=>"1"},
            {name=>"MAP_OCCLUSION", type=>"IV", macro=>"1"},
            {name=>"MAP_PREFILTER", type=>"IV", macro=>"1"},
            {name=>"MAP_ROUGHNESS", type=>"IV", macro=>"1"},
            {name=>"NPT_3PATCH_HORIZONTAL", type=>"IV", macro=>"1"},
            {name=>"NPT_3PATCH_VERTICAL", type=>"IV", macro=>"1"},
            {name=>"NPT_9PATCH", type=>"IV", macro=>"1"},
            {name=>"UNCOMPRESSED_GRAYSCALE", type=>"IV", macro=>"1"},
            {name=>"UNCOMPRESSED_GRAY_ALPHA", type=>"IV", macro=>"1"},
            {name=>"UNCOMPRESSED_R32", type=>"IV", macro=>"1"},
            {name=>"UNCOMPRESSED_R32G32B32", type=>"IV", macro=>"1"},
            {name=>"UNCOMPRESSED_R32G32B32A32", type=>"IV", macro=>"1"},
            {name=>"UNCOMPRESSED_R4G4B4A4", type=>"IV", macro=>"1"},
            {name=>"UNCOMPRESSED_R5G5B5A1", type=>"IV", macro=>"1"},
            {name=>"UNCOMPRESSED_R5G6B5", type=>"IV", macro=>"1"},
            {name=>"UNCOMPRESSED_R8G8B8", type=>"IV", macro=>"1"},
            {name=>"UNCOMPRESSED_R8G8B8A8", type=>"IV", macro=>"1"},
            {name=>"WRAP_CLAMP", type=>"IV", macro=>"1"},
            {name=>"WRAP_MIRROR", type=>"IV", macro=>"1"},
            {name=>"WRAP_REPEAT", type=>"IV", macro=>"1"},
            {name=>"false", type=>"IV", macro=>"1"},
            {name=>"true", type=>"IV", macro=>"1"});

print constant_types(), "\n"; # macro defs
foreach (C_constant ("Graphics::Raylib::XS", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("Graphics::Raylib::XS", $types);
__END__
   */

  switch (len) {
  case 4:
    if (memEQ(name, "true", 4)) {
      *iv_return = true;
      return PERL_constant_ISIV;
    }
    break;
  case 5:
    return constant_5 (aTHX_ name, iv_return);
    break;
  case 6:
    return constant_6 (aTHX_ name, iv_return);
    break;
  case 7:
    return constant_7 (aTHX_ name, iv_return);
    break;
  case 8:
    return constant_8 (aTHX_ name, iv_return);
    break;
  case 9:
    return constant_9 (aTHX_ name, iv_return);
    break;
  case 10:
    return constant_10 (aTHX_ name, iv_return);
    break;
  case 11:
    return constant_11 (aTHX_ name, iv_return);
    break;
  case 12:
    return constant_12 (aTHX_ name, iv_return);
    break;
  case 13:
    return constant_13 (aTHX_ name, iv_return);
    break;
  case 14:
    return constant_14 (aTHX_ name, iv_return);
    break;
  case 15:
    return constant_15 (aTHX_ name, iv_return);
    break;
  case 16:
    return constant_16 (aTHX_ name, iv_return);
    break;
  case 17:
    return constant_17 (aTHX_ name, iv_return);
    break;
  case 18:
    return constant_18 (aTHX_ name, iv_return);
    break;
  case 19:
    return constant_19 (aTHX_ name, iv_return);
    break;
  case 20:
    return constant_20 (aTHX_ name, iv_return);
    break;
  case 21:
    return constant_21 (aTHX_ name, iv_return);
    break;
  case 22:
    return constant_22 (aTHX_ name, iv_return);
    break;
  case 23:
    return constant_23 (aTHX_ name, iv_return);
    break;
  case 24:
    return constant_24 (aTHX_ name, iv_return);
    break;
  case 25:
    return constant_25 (aTHX_ name, iv_return);
    break;
  case 26:
    /* Names all of length 26.  */
    /* GAMEPAD_ANDROID_DPAD_RIGHT GAMEPAD_XBOX_BUTTON_SELECT */
    /* Offset 17 gives the best switch position.  */
    switch (name[17]) {
    case 'O':
      if (memEQ(name, "GAMEPAD_XBOX_BUTTON_SELECT", 26)) {
      /*                                ^               */
#ifdef GAMEPAD_XBOX_BUTTON_SELECT
        *iv_return = GAMEPAD_XBOX_BUTTON_SELECT;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'P':
      if (memEQ(name, "GAMEPAD_ANDROID_DPAD_RIGHT", 26)) {
      /*                                ^               */
#ifdef GAMEPAD_ANDROID_DPAD_RIGHT
        *iv_return = GAMEPAD_ANDROID_DPAD_RIGHT;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 27:
    /* Names all of length 27.  */
    /* GAMEPAD_ANDROID_DPAD_CENTER GAMEPAD_PS3_BUTTON_TRIANGLE */
    /* Offset 17 gives the best switch position.  */
    switch (name[17]) {
    case 'N':
      if (memEQ(name, "GAMEPAD_PS3_BUTTON_TRIANGLE", 27)) {
      /*                                ^                */
#ifdef GAMEPAD_PS3_BUTTON_TRIANGLE
        *iv_return = GAMEPAD_PS3_BUTTON_TRIANGLE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'P':
      if (memEQ(name, "GAMEPAD_ANDROID_DPAD_CENTER", 27)) {
      /*                                ^                */
#ifdef GAMEPAD_ANDROID_DPAD_CENTER
        *iv_return = GAMEPAD_ANDROID_DPAD_CENTER;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

