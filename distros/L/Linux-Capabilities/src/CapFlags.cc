#include "CapFlags.h"

int CapFlags::any() {

    return effective || permitted || inheritable;
};