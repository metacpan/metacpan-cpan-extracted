#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/uio.h>
#include <pthread.h>
#include "blocked_read.h"

static void msgqueue_pop(int fd, short flags, void *arg) {
   blocked_read_t *br = arg;
   char buf[64];
   void *data;

   read(fd, buf, sizeof(buf));

   pthread_mutex_lock(&br->lock);
   br->callback(br->data, br->cbarg);
   br->data = NULL;
   pthread_mutex_unlock(&br->lock);
   pthread_cond_signal(&br->processed);
}

static int msgqueue_push(blocked_read_t *br, void *msg) {
   const char buf[1] = { 0 };
   int r = 0;

   br->data = msg;
   write(br->push_fd, buf, 1);

   while (br->data) {
     pthread_cond_wait(&br->processed, &br->lock);
   }

   return(r);
}

static void *read_thread(void *argument) {
  socklen_t fromlen;
  blocked_read_t *br = (blocked_read_t *)argument;
  
  while (1) {
    fromlen = sizeof(br->msg.from);
    br->msg.len = recvfrom(br->fd, br->msg.buffer, MAXMSGSIZE, 0,
                           (struct sockaddr *)&br->msg.from, 
                           &fromlen
                           );
    if (br->msg.len == -1) {
      br->msg.error = errno;
    } else {
      br->msg.error = 0;
    }

    msgqueue_push(br, (void *)&br->msg);
  }

  return NULL;
}

/* returns handle on success and NULL on failure */
blocked_read_t* register_blocked_read(int fd, 
                                      void (*callback)(void*, void*),
                                      void *cbarg
                                      ) 
{
  blocked_read_t *br;
  int rc;
  int fds[2];

  br = calloc(sizeof(blocked_read_t), 1);
  br->fd = fd;

  if (socketpair(AF_UNIX, SOCK_STREAM, 0, fds) != 0) {
    free(br);
    return NULL;
  }

  br->push_fd = fds[0];
  br->pop_fd = fds[1];
  br->data = NULL;
  br->callback = callback;
  br->cbarg = cbarg;
  
  pthread_mutex_init(&br->lock, NULL);
  pthread_mutex_lock(&br->lock);
  pthread_cond_init(&br->processed, NULL);

  event_set(&br->queue_ev, br->pop_fd, EV_READ | EV_PERSIST, msgqueue_pop, br);
  event_add(&br->queue_ev, NULL);

  rc = pthread_create(&br->tid, 
                      NULL,
                      read_thread,
                      br);

  if (rc != 0) {
    free(br);
    return NULL;
  }

  pthread_detach(br->tid);
  
  return br;
}

