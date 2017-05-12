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
     DEG2RAD KEY_F10 KEY_F11 KEY_F12 KEY_ONE KEY_SIX KEY_TWO RAD2DEG */
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
     KEY_BACK KEY_DOWN KEY_FIVE KEY_FOUR KEY_LEFT KEY_MENU KEY_NINE KEY_ZERO */
  /* Offset 7 gives the best switch position.  */
  switch (name[7]) {
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
     KEY_EIGHT KEY_ENTER KEY_RIGHT KEY_SEVEN KEY_SPACE KEY_THREE */
  /* Offset 5 gives the best switch position.  */
  switch (name[5]) {
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
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_10 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     KEY_ESCAPE LIGHT_SPOT WRAP_CLAMP */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'M':
    if (memEQ(name, "WRAP_CLAMP", 10)) {
    /*                       ^        */
      *iv_return = WRAP_CLAMP;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "LIGHT_SPOT", 10)) {
    /*                       ^        */
      *iv_return = LIGHT_SPOT;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "KEY_ESCAPE", 10)) {
    /*                       ^        */
#ifdef KEY_ESCAPE
      *iv_return = KEY_ESCAPE;
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
constant_11 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     BLEND_ALPHA CAMERA_FREE GESTURE_TAP HMD_FOVE_VR LIGHT_POINT WRAP_MIRROR
     WRAP_REPEAT */
  /* Offset 7 gives the best switch position.  */
  switch (name[7]) {
  case 'E':
    if (memEQ(name, "HMD_FOVE_VR", 11)) {
    /*                      ^          */
      *iv_return = HMD_FOVE_VR;
      return PERL_constant_ISIV;
    }
    break;
  case 'F':
    if (memEQ(name, "CAMERA_FREE", 11)) {
    /*                      ^          */
      *iv_return = CAMERA_FREE;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "BLEND_ALPHA", 11)) {
    /*                      ^          */
      *iv_return = BLEND_ALPHA;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "LIGHT_POINT", 11)) {
    /*                      ^          */
      *iv_return = LIGHT_POINT;
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
     FILTER_POINT GESTURE_DRAG GESTURE_HOLD GESTURE_NONE KEY_LEFT_ALT */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
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
  case 'N':
    if (memEQ(name, "GESTURE_NONE", 12)) {
    /*                       ^          */
      *iv_return = GESTURE_NONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "FILTER_POINT", 12)) {
    /*                       ^          */
      *iv_return = FILTER_POINT;
      return PERL_constant_ISIV;
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
     CAMERA_CUSTOM KEY_BACKSPACE KEY_RIGHT_ALT KEY_VOLUME_UP */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'M':
    if (memEQ(name, "KEY_VOLUME_UP", 13)) {
    /*                       ^           */
#ifdef KEY_VOLUME_UP
      *iv_return = KEY_VOLUME_UP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "KEY_BACKSPACE", 13)) {
    /*                       ^           */
#ifdef KEY_BACKSPACE
      *iv_return = KEY_BACKSPACE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "KEY_RIGHT_ALT", 13)) {
    /*                       ^           */
#ifdef KEY_RIGHT_ALT
      *iv_return = KEY_RIGHT_ALT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "CAMERA_CUSTOM", 13)) {
    /*                       ^           */
      *iv_return = CAMERA_CUSTOM;
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
     BLEND_ADDITIVE CAMERA_ORBITAL FLAG_SHOW_LOGO HMD_RAZER_OSVR KEY_LEFT_SHIFT
     */
  /* Offset 0 gives the best switch position.  */
  switch (*name++) {
  case 'B':
    if (memEQ(name, "LEND_ADDITIVE", 13)) {
    /*                B                    */
      *iv_return = BLEND_ADDITIVE;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "AMERA_ORBITAL", 13)) {
    /*                C                    */
      *iv_return = CAMERA_ORBITAL;
      return PERL_constant_ISIV;
    }
    break;
  case 'F':
    if (memEQ(name, "LAG_SHOW_LOGO", 13)) {
    /*                F                    */
#ifdef FLAG_SHOW_LOGO
      *iv_return = FLAG_SHOW_LOGO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "MD_RAZER_OSVR", 13)) {
    /*                H                    */
      *iv_return = HMD_RAZER_OSVR;
      return PERL_constant_ISIV;
    }
    break;
  case 'K':
    if (memEQ(name, "EY_LEFT_SHIFT", 13)) {
    /*                K                    */
#ifdef KEY_LEFT_SHIFT
      *iv_return = KEY_LEFT_SHIFT;
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
     GAMEPAD_PLAYER3 GAMEPAD_PLAYER4 KEY_RIGHT_SHIFT KEY_VOLUME_DOWN */
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
  case 'R':
    if (memEQ(name, "FILTER_BILINEA", 14)) {
    /*                             R      */
      *iv_return = FILTER_BILINEAR;
      return PERL_constant_ISIV;
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
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_16 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     BLEND_MULTIPLIED FILTER_TRILINEAR GESTURE_PINCH_IN GESTURE_SWIPE_UP
     KEY_LEFT_CONTROL MAX_TOUCH_POINTS */
  /* Offset 15 gives the best switch position.  */
  switch (name[15]) {
  case 'D':
    if (memEQ(name, "BLEND_MULTIPLIE", 15)) {
    /*                              D      */
      *iv_return = BLEND_MULTIPLIED;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "KEY_LEFT_CONTRO", 15)) {
    /*                              L      */
#ifdef KEY_LEFT_CONTROL
      *iv_return = KEY_LEFT_CONTROL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "GESTURE_PINCH_I", 15)) {
    /*                              N      */
      *iv_return = GESTURE_PINCH_IN;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "GESTURE_SWIPE_U", 15)) {
    /*                              P      */
      *iv_return = GESTURE_SWIPE_UP;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "FILTER_TRILINEA", 15)) {
    /*                              R      */
      *iv_return = FILTER_TRILINEAR;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "MAX_TOUCH_POINT", 15)) {
    /*                              S      */
#ifdef MAX_TOUCH_POINTS
      *iv_return = MAX_TOUCH_POINTS;
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
constant_17 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     FLAG_MSAA_4X_HINT GESTURE_DOUBLETAP GESTURE_PINCH_OUT KEY_RIGHT_CONTROL
     LIGHT_DIRECTIONAL MOUSE_LEFT_BUTTON */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'A':
    if (memEQ(name, "FLAG_MSAA_4X_HINT", 17)) {
    /*                       ^               */
#ifdef FLAG_MSAA_4X_HINT
      *iv_return = FLAG_MSAA_4X_HINT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "GESTURE_DOUBLETAP", 17)) {
    /*                       ^               */
      *iv_return = GESTURE_DOUBLETAP;
      return PERL_constant_ISIV;
    }
    break;
  case 'F':
    if (memEQ(name, "MOUSE_LEFT_BUTTON", 17)) {
    /*                       ^               */
#ifdef MOUSE_LEFT_BUTTON
      *iv_return = MOUSE_LEFT_BUTTON;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "GESTURE_PINCH_OUT", 17)) {
    /*                       ^               */
      *iv_return = GESTURE_PINCH_OUT;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "LIGHT_DIRECTIONAL", 17)) {
    /*                       ^               */
      *iv_return = LIGHT_DIRECTIONAL;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "KEY_RIGHT_CONTROL", 17)) {
    /*                       ^               */
#ifdef KEY_RIGHT_CONTROL
      *iv_return = KEY_RIGHT_CONTROL;
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
     FLAG_CENTERED_MODE GESTURE_SWIPE_DOWN GESTURE_SWIPE_LEFT
     HMD_DEFAULT_DEVICE HMD_VALVE_HTC_VIVE MOUSE_RIGHT_BUTTON */
  /* Offset 16 gives the best switch position.  */
  switch (name[16]) {
  case 'C':
    if (memEQ(name, "HMD_DEFAULT_DEVICE", 18)) {
    /*                               ^        */
      *iv_return = HMD_DEFAULT_DEVICE;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "FLAG_CENTERED_MODE", 18)) {
    /*                               ^        */
#ifdef FLAG_CENTERED_MODE
      *iv_return = FLAG_CENTERED_MODE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "GESTURE_SWIPE_LEFT", 18)) {
    /*                               ^        */
      *iv_return = GESTURE_SWIPE_LEFT;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "MOUSE_RIGHT_BUTTON", 18)) {
    /*                               ^        */
#ifdef MOUSE_RIGHT_BUTTON
      *iv_return = MOUSE_RIGHT_BUTTON;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "HMD_VALVE_HTC_VIVE", 18)) {
    /*                               ^        */
      *iv_return = HMD_VALVE_HTC_VIVE;
      return PERL_constant_ISIV;
    }
    break;
  case 'W':
    if (memEQ(name, "GESTURE_SWIPE_DOWN", 18)) {
    /*                               ^        */
      *iv_return = GESTURE_SWIPE_DOWN;
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
     CAMERA_FIRST_PERSON CAMERA_THIRD_PERSON COMPRESSED_DXT1_RGB
     COMPRESSED_ETC1_RGB COMPRESSED_ETC2_RGB COMPRESSED_PVRT_RGB
     GAMEPAD_PS3_AXIS_L2 GAMEPAD_PS3_AXIS_R2 GESTURE_SWIPE_RIGHT
     HMD_OCULUS_RIFT_CV1 HMD_OCULUS_RIFT_DK2 HMD_SAMSUNG_GEAR_VR
     MOUSE_MIDDLE_BUTTON UNCOMPRESSED_R5G6B5 UNCOMPRESSED_R8G8B8 */
  /* Offset 14 gives the best switch position.  */
  switch (name[14]) {
  case '1':
    if (memEQ(name, "COMPRESSED_DXT1_RGB", 19)) {
    /*                             ^           */
      *iv_return = COMPRESSED_DXT1_RGB;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "COMPRESSED_ETC1_RGB", 19)) {
    /*                             ^           */
      *iv_return = COMPRESSED_ETC1_RGB;
      return PERL_constant_ISIV;
    }
    break;
  case '2':
    if (memEQ(name, "COMPRESSED_ETC2_RGB", 19)) {
    /*                             ^           */
      *iv_return = COMPRESSED_ETC2_RGB;
      return PERL_constant_ISIV;
    }
    break;
  case '5':
    if (memEQ(name, "UNCOMPRESSED_R5G6B5", 19)) {
    /*                             ^           */
      *iv_return = UNCOMPRESSED_R5G6B5;
      return PERL_constant_ISIV;
    }
    break;
  case '8':
    if (memEQ(name, "UNCOMPRESSED_R8G8B8", 19)) {
    /*                             ^           */
      *iv_return = UNCOMPRESSED_R8G8B8;
      return PERL_constant_ISIV;
    }
    break;
  case 'A':
    if (memEQ(name, "HMD_SAMSUNG_GEAR_VR", 19)) {
    /*                             ^           */
      *iv_return = HMD_SAMSUNG_GEAR_VR;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "CAMERA_FIRST_PERSON", 19)) {
    /*                             ^           */
      *iv_return = CAMERA_FIRST_PERSON;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "CAMERA_THIRD_PERSON", 19)) {
    /*                             ^           */
      *iv_return = CAMERA_THIRD_PERSON;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "GAMEPAD_PS3_AXIS_L2", 19)) {
    /*                             ^           */
#ifdef GAMEPAD_PS3_AXIS_L2
      *iv_return = GAMEPAD_PS3_AXIS_L2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GAMEPAD_PS3_AXIS_R2", 19)) {
    /*                             ^           */
#ifdef GAMEPAD_PS3_AXIS_R2
      *iv_return = GAMEPAD_PS3_AXIS_R2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "GESTURE_SWIPE_RIGHT", 19)) {
    /*                             ^           */
      *iv_return = GESTURE_SWIPE_RIGHT;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "COMPRESSED_PVRT_RGB", 19)) {
    /*                             ^           */
      *iv_return = COMPRESSED_PVRT_RGB;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HMD_OCULUS_RIFT_CV1", 19)) {
    /*                             ^           */
      *iv_return = HMD_OCULUS_RIFT_CV1;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HMD_OCULUS_RIFT_DK2", 19)) {
    /*                             ^           */
      *iv_return = HMD_OCULUS_RIFT_DK2;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "MOUSE_MIDDLE_BUTTON", 19)) {
    /*                             ^           */
#ifdef MOUSE_MIDDLE_BUTTON
      *iv_return = MOUSE_MIDDLE_BUTTON;
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
     GAMEPAD_XBOX_AXIS_RT HMD_GOOGLE_CARDBOARD */
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
  case 'D':
    if (memEQ(name, "HMD_GOOGLE_CARDBOARD", 20)) {
    /*                             ^            */
      *iv_return = HMD_GOOGLE_CARDBOARD;
      return PERL_constant_ISIV;
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
     FILTER_ANISOTROPIC_4X FILTER_ANISOTROPIC_8X FLAG_RESIZABLE_WINDOW
     GAMEPAD_PS3_BUTTON_L1 GAMEPAD_PS3_BUTTON_L2 GAMEPAD_PS3_BUTTON_PS
     GAMEPAD_PS3_BUTTON_R1 GAMEPAD_PS3_BUTTON_R2 GAMEPAD_PS3_BUTTON_UP
     GAMEPAD_XBOX_BUTTON_A GAMEPAD_XBOX_BUTTON_B GAMEPAD_XBOX_BUTTON_X
     GAMEPAD_XBOX_BUTTON_Y UNCOMPRESSED_R4G4B4A4 UNCOMPRESSED_R5G5B5A1
     UNCOMPRESSED_R8G8B8A8 */
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
  case 'W':
    if (memEQ(name, "FLAG_RESIZABLE_WINDO", 20)) {
    /*                                   W      */
#ifdef FLAG_RESIZABLE_WINDOW
      *iv_return = FLAG_RESIZABLE_WINDOW;
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
     FILTER_ANISOTROPIC_16X FLAG_SHOW_MOUSE_CURSOR GAMEPAD_XBOX_BUTTON_LB
     GAMEPAD_XBOX_BUTTON_RB GAMEPAD_XBOX_BUTTON_UP UNCOMPRESSED_GRAYSCALE */
  /* Offset 21 gives the best switch position.  */
  switch (name[21]) {
  case 'B':
    if (memEQ(name, "GAMEPAD_XBOX_BUTTON_L", 21)) {
    /*                                    B      */
#ifdef GAMEPAD_XBOX_BUTTON_LB
      *iv_return = GAMEPAD_XBOX_BUTTON_LB;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GAMEPAD_XBOX_BUTTON_R", 21)) {
    /*                                    B      */
#ifdef GAMEPAD_XBOX_BUTTON_RB
      *iv_return = GAMEPAD_XBOX_BUTTON_RB;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "UNCOMPRESSED_GRAYSCAL", 21)) {
    /*                                    E      */
      *iv_return = UNCOMPRESSED_GRAYSCALE;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "GAMEPAD_XBOX_BUTTON_U", 21)) {
    /*                                    P      */
#ifdef GAMEPAD_XBOX_BUTTON_UP
      *iv_return = GAMEPAD_XBOX_BUTTON_UP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "FLAG_SHOW_MOUSE_CURSO", 21)) {
    /*                                    R      */
#ifdef FLAG_SHOW_MOUSE_CURSOR
      *iv_return = FLAG_SHOW_MOUSE_CURSOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "FILTER_ANISOTROPIC_16", 21)) {
    /*                                    X      */
      *iv_return = FILTER_ANISOTROPIC_16X;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_23 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     GAMEPAD_PS3_AXIS_LEFT_X GAMEPAD_PS3_AXIS_LEFT_Y GAMEPAD_PS3_BUTTON_DOWN
     GAMEPAD_PS3_BUTTON_LEFT HMD_SONY_PLAYSTATION_VR UNCOMPRESSED_GRAY_ALPHA */
  /* Offset 22 gives the best switch position.  */
  switch (name[22]) {
  case 'A':
    if (memEQ(name, "UNCOMPRESSED_GRAY_ALPH", 22)) {
    /*                                     A      */
      *iv_return = UNCOMPRESSED_GRAY_ALPHA;
      return PERL_constant_ISIV;
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
  case 'R':
    if (memEQ(name, "HMD_SONY_PLAYSTATION_V", 22)) {
    /*                                     R      */
      *iv_return = HMD_SONY_PLAYSTATION_VR;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
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
     GAMEPAD_PS3_AXIS_RIGHT_X GAMEPAD_PS3_AXIS_RIGHT_Y GAMEPAD_PS3_BUTTON_CROSS
     GAMEPAD_PS3_BUTTON_RIGHT GAMEPAD_PS3_BUTTON_START GAMEPAD_XBOX_AXIS_LEFT_X
     GAMEPAD_XBOX_AXIS_LEFT_Y GAMEPAD_XBOX_BUTTON_DOWN GAMEPAD_XBOX_BUTTON_HOME
     GAMEPAD_XBOX_BUTTON_LEFT */
  /* Offset 22 gives the best switch position.  */
  switch (name[22]) {
  case 'B':
    if (memEQ(name, "COMPRESSED_ASTC_4x4_RGBA", 24)) {
    /*                                     ^        */
      *iv_return = COMPRESSED_ASTC_4x4_RGBA;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "COMPRESSED_ASTC_8x8_RGBA", 24)) {
    /*                                     ^        */
      *iv_return = COMPRESSED_ASTC_8x8_RGBA;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "COMPRESSED_ETC2_EAC_RGBA", 24)) {
    /*                                     ^        */
      *iv_return = COMPRESSED_ETC2_EAC_RGBA;
      return PERL_constant_ISIV;
    }
    break;
  case 'F':
    if (memEQ(name, "GAMEPAD_XBOX_BUTTON_LEFT", 24)) {
    /*                                     ^        */
#ifdef GAMEPAD_XBOX_BUTTON_LEFT
      *iv_return = GAMEPAD_XBOX_BUTTON_LEFT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "GAMEPAD_PS3_BUTTON_RIGHT", 24)) {
    /*                                     ^        */
#ifdef GAMEPAD_PS3_BUTTON_RIGHT
      *iv_return = GAMEPAD_PS3_BUTTON_RIGHT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "GAMEPAD_XBOX_BUTTON_HOME", 24)) {
    /*                                     ^        */
#ifdef GAMEPAD_XBOX_BUTTON_HOME
      *iv_return = GAMEPAD_XBOX_BUTTON_HOME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "GAMEPAD_PS3_BUTTON_START", 24)) {
    /*                                     ^        */
#ifdef GAMEPAD_PS3_BUTTON_START
      *iv_return = GAMEPAD_PS3_BUTTON_START;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "GAMEPAD_PS3_BUTTON_CROSS", 24)) {
    /*                                     ^        */
#ifdef GAMEPAD_PS3_BUTTON_CROSS
      *iv_return = GAMEPAD_PS3_BUTTON_CROSS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'W':
    if (memEQ(name, "GAMEPAD_XBOX_BUTTON_DOWN", 24)) {
    /*                                     ^        */
#ifdef GAMEPAD_XBOX_BUTTON_DOWN
      *iv_return = GAMEPAD_XBOX_BUTTON_DOWN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "GAMEPAD_PS3_AXIS_RIGHT_X", 24)) {
    /*                                     ^        */
#ifdef GAMEPAD_PS3_AXIS_RIGHT_X
      *iv_return = GAMEPAD_PS3_AXIS_RIGHT_X;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GAMEPAD_PS3_AXIS_RIGHT_Y", 24)) {
    /*                                     ^        */
#ifdef GAMEPAD_PS3_AXIS_RIGHT_Y
      *iv_return = GAMEPAD_PS3_AXIS_RIGHT_Y;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GAMEPAD_XBOX_AXIS_LEFT_X", 24)) {
    /*                                     ^        */
#ifdef GAMEPAD_XBOX_AXIS_LEFT_X
      *iv_return = GAMEPAD_XBOX_AXIS_LEFT_X;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GAMEPAD_XBOX_AXIS_LEFT_Y", 24)) {
    /*                                     ^        */
#ifdef GAMEPAD_XBOX_AXIS_LEFT_Y
      *iv_return = GAMEPAD_XBOX_AXIS_LEFT_Y;
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
     GAMEPAD_PS3_BUTTON_CIRCLE GAMEPAD_PS3_BUTTON_SELECT
     GAMEPAD_PS3_BUTTON_SQUARE GAMEPAD_XBOX_AXIS_RIGHT_X
     GAMEPAD_XBOX_AXIS_RIGHT_Y GAMEPAD_XBOX_BUTTON_RIGHT
     GAMEPAD_XBOX_BUTTON_START */
  /* Offset 21 gives the best switch position.  */
  switch (name[21]) {
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

#!/opt/local/bin/perl5.24 -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(DEG2RAD FLAG_CENTERED_MODE FLAG_FULLSCREEN_MODE
	       FLAG_MSAA_4X_HINT FLAG_RESIZABLE_WINDOW FLAG_SHOW_LOGO
	       FLAG_SHOW_MOUSE_CURSOR FLAG_VSYNC_HINT GAMEPAD_PLAYER1
	       GAMEPAD_PLAYER2 GAMEPAD_PLAYER3 GAMEPAD_PLAYER4
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
	       GAMEPAD_XBOX_BUTTON_Y KEY_A KEY_B KEY_BACK KEY_BACKSPACE KEY_C
	       KEY_D KEY_DOWN KEY_E KEY_EIGHT KEY_ENTER KEY_ESCAPE KEY_F KEY_F1
	       KEY_F10 KEY_F11 KEY_F12 KEY_F2 KEY_F3 KEY_F4 KEY_F5 KEY_F6
	       KEY_F7 KEY_F8 KEY_F9 KEY_FIVE KEY_FOUR KEY_G KEY_H KEY_I KEY_J
	       KEY_K KEY_L KEY_LEFT KEY_LEFT_ALT KEY_LEFT_CONTROL
	       KEY_LEFT_SHIFT KEY_M KEY_MENU KEY_N KEY_NINE KEY_O KEY_ONE KEY_P
	       KEY_Q KEY_R KEY_RIGHT KEY_RIGHT_ALT KEY_RIGHT_CONTROL
	       KEY_RIGHT_SHIFT KEY_S KEY_SEVEN KEY_SIX KEY_SPACE KEY_T
	       KEY_THREE KEY_TWO KEY_U KEY_UP KEY_V KEY_VOLUME_DOWN
	       KEY_VOLUME_UP KEY_W KEY_X KEY_Y KEY_Z KEY_ZERO MAX_TOUCH_POINTS
	       MOUSE_LEFT_BUTTON MOUSE_MIDDLE_BUTTON MOUSE_RIGHT_BUTTON
	       RAD2DEG),
            {name=>"BLEND_ADDITIVE", type=>"IV", macro=>"1"},
            {name=>"BLEND_ALPHA", type=>"IV", macro=>"1"},
            {name=>"BLEND_MULTIPLIED", type=>"IV", macro=>"1"},
            {name=>"CAMERA_CUSTOM", type=>"IV", macro=>"1"},
            {name=>"CAMERA_FIRST_PERSON", type=>"IV", macro=>"1"},
            {name=>"CAMERA_FREE", type=>"IV", macro=>"1"},
            {name=>"CAMERA_ORBITAL", type=>"IV", macro=>"1"},
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
            {name=>"HMD_FOVE_VR", type=>"IV", macro=>"1"},
            {name=>"HMD_GOOGLE_CARDBOARD", type=>"IV", macro=>"1"},
            {name=>"HMD_OCULUS_RIFT_CV1", type=>"IV", macro=>"1"},
            {name=>"HMD_OCULUS_RIFT_DK2", type=>"IV", macro=>"1"},
            {name=>"HMD_RAZER_OSVR", type=>"IV", macro=>"1"},
            {name=>"HMD_SAMSUNG_GEAR_VR", type=>"IV", macro=>"1"},
            {name=>"HMD_SONY_PLAYSTATION_VR", type=>"IV", macro=>"1"},
            {name=>"HMD_VALVE_HTC_VIVE", type=>"IV", macro=>"1"},
            {name=>"LIGHT_DIRECTIONAL", type=>"IV", macro=>"1"},
            {name=>"LIGHT_POINT", type=>"IV", macro=>"1"},
            {name=>"LIGHT_SPOT", type=>"IV", macro=>"1"},
            {name=>"UNCOMPRESSED_GRAYSCALE", type=>"IV", macro=>"1"},
            {name=>"UNCOMPRESSED_GRAY_ALPHA", type=>"IV", macro=>"1"},
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
    if (memEQ(name, "GAMEPAD_XBOX_BUTTON_SELECT", 26)) {
#ifdef GAMEPAD_XBOX_BUTTON_SELECT
      *iv_return = GAMEPAD_XBOX_BUTTON_SELECT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 27:
    if (memEQ(name, "GAMEPAD_PS3_BUTTON_TRIANGLE", 27)) {
#ifdef GAMEPAD_PS3_BUTTON_TRIANGLE
      *iv_return = GAMEPAD_PS3_BUTTON_TRIANGLE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

