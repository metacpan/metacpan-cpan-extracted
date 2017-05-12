#include <stdlib.h>
#include "EditOp/editop.h"

EditOp *
newEditOp()
{
  EditOp *editop;
  editop= (EditOp*)malloc(sizeof(EditOp));
  if (editop) {
    editop->type = 0;
    editop->count = 0;
    editop->next = (EditOp *) 0;
  }
  return(editop);
}

