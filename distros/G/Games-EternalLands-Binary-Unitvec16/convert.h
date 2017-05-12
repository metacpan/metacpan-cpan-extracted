#ifndef UNITVEC16_CONVERT_H
#define UNITVEC16_CONVERT_H

typedef unsigned short unitvec16_t;

unitvec16_t unitvec16_pack(float *n);
void unitvec16_unpack(unitvec16_t p, float *n);

#endif /* UNITVEC16_CONVERT_H */
