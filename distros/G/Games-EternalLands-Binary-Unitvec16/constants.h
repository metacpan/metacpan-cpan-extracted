#ifndef UNITVEC16_CONSTANTS_H
#define UNITVEC16_CONSTANTS_H

#define ILTAB_SIZE  0x2000
#define XSIGN_MASK  (1<<15)
#define YSIGN_MASK  (1<<14)
#define ZSIGN_MASK  (1<<13)
#define SIGN_MASK   0xe000 /* 3 bits [15..13] */
#define TOP_MASK    0x1f80 /* 6 bits [12..7] */
#define BOTTOM_MASK 0x007f /* 7 bits [6..0] */

#endif /* UNITVEC16_CONSTANTS_H */
