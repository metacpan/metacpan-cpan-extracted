#include <stdlib.h>
#include "Msp/msp.h"

MSP *
newMSP()
{
  MSP *msp;
  msp = (MSP *)malloc(sizeof(MSP));
  if (msp) {
    msp->pos1 = 0;
    msp->pos2 = 0;
    msp->len = 0;
    msp->score = 0;
    msp->next_msp = (MSP *)0;
  }
  return(msp);
}

