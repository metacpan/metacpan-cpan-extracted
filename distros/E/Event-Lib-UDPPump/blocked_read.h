#ifndef _BLOCKED_READ_H_
#define _BLOCKED_READ_H_

#include <event.h>
#include <pthread.h>
#include <errno.h>
#include <netinet/in.h>

#define MAXMSGSIZE (4 * 1024)

typedef struct {
  struct sockaddr_in from;
  int len;
  int error;
  unsigned char buffer[MAXMSGSIZE];
} msg_t;

typedef struct {
  int fd;
  pthread_t tid;

  int push_fd;
  int pop_fd;
  
  struct event queue_ev;

  msg_t msg;
  
  pthread_mutex_t lock;
  pthread_cond_t processed;
  void (*callback)(void*, void*);
  void *data;
  void *cbarg;
} blocked_read_t;

blocked_read_t* register_blocked_read(int fd, 
                                      void (*callback)(void*, void*),
                                      void *cbarg
                                      );


#endif /* _BLOCKED_READ_ */
