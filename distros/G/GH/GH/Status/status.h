
#define STAT_OK 0
#define STAT_FAIL -1
#define STAT_EOF -2
#define STAT_NULL_PTR -3
#define STAT_NO_MEM -4
#define STAT_BAD_ARGS -5
#define STAT_BOUND_TOO_TIGHT -6
#define STAT_NOT_OPTIMAL -7

#define BailNull(ptr, status) \
{ \
  if(!ptr) { \
    status = STAT_NO_MEM; \
    goto bail; \
  } \
}
#define BailError(status) \
{ \
  if(status != STAT_OK) { \
    goto bail; \
  } \
}

#define BailErrorMsg(status, msg) \
{ \
  if(status != STAT_OK) { \
    status_message = msg; \
    goto bail; \
  } \
}

