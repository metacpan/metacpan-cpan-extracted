#include <arpa/inet.h>
#include <assert.h>
#include <errno.h>
#include <fcntl.h>
#include <getopt.h>
#include <netinet/tcp.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/select.h>
#include <sys/un.h>
#include <unistd.h>

#define PROGNAME "keyedmutexd"
#define VERSION "0.04"

#define DEFAULT_SOCKPATH "/tmp/" PROGNAME ".sock"
#define DEFAULT_CONNS_SIZE 32
#define DEFAULT_TIMEOUT_SECS 30
#define KEY_SIZE (16)

#ifndef MIN
#define MIN(x, y) ((x) < (y) ? (x) : (y))
#endif
#ifndef MAX
#define MAX(x, y) ((x) < (y) ? (y) : (x))
#endif

#ifndef INLINE
#define INLINE __inline
#endif

/* messages */
#define OWNER_MSG "O"
#define RELEASE_MSG "R"

/* states, note that connections w. valid key have their lsb set */
#define CS_NOCONN   0x0
#define CS_KEYREAD  0x2
#define CS_OWNER    0x1
#define CS_NONOWNER 0x3
#define CS_STATE_MASK (0x3)
#define CS_IKEY_MASK (~CS_STATE_MASK)

/* conn_* arrays start from socket no. listen_fd + 1 */
static int* conn_states;
static char* conn_key_offsets;
static char (*conn_keys)[KEY_SIZE];
static time_t* owner_timeouts;
static int conns_length = 0; /* index of last valid conn + 1 */
static int conns_size = DEFAULT_CONNS_SIZE;  /* size of conns */

static int listen_fd;
static int exit_loop;

static struct sockaddr_un sun;
static struct sockaddr_in sin;
static int use_tcp;
static int timeout_secs = DEFAULT_TIMEOUT_SECS;
static int force;
static int print_info;
static int no_log;
static struct option longopts[] = {
  { "socket", required_argument, NULL, 's' },
  { "maxconn", required_argument, NULL, 'm' },
  { "timeout", required_argument, NULL, 't' },
  { "force", no_argument, NULL, 'f' },
  { "help", no_argument, &print_info, 'h' },
  { "version", no_argument, &print_info, 'v' },
  { "no-log", no_argument, &no_log, 1 },
  { NULL, no_argument, NULL, 0 },
};

#define LOG(fd, status, key) \
  do { \
    if (! no_log) write_log((fd), (status), (key)); \
  } while (0)

static void write_log(int fd, const char* status, const char* key)
{
  char hexkey[KEY_SIZE * 2 + 2];
  int i;
  
  if (key != NULL) {
    hexkey[0] = ' ';
    for (i = 0; i < KEY_SIZE; i++) {
      hexkey[i * 2 + 1] = ("0123456789abcdef")[(key[i] >> 4) & 0xf];
      hexkey[i * 2 + 2] = ("0123456789abcdef")[key[i] & 0xf];
    }
    hexkey[KEY_SIZE * 2 + 1] = '\0';
  } else {
    hexkey[0] = '\0';
  }
  
  printf("%d %s%s\n", fd, status, hexkey);
}

INLINE int reuse_addr(int fd)
{
  int arg = 1;
  return setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &arg, sizeof(arg));
}

INLINE int nonblock(int fd)
{
  return fcntl(fd, F_SETFL, O_NONBLOCK);
}

INLINE int nodelay(int fd)
{
  int arg = 0;
  return setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, &arg, sizeof(arg));
}

INLINE int key2i(const char* _key)
{
  const int* key = (void*)(_key + KEY_SIZE);
  int ikey = 0;
  
  do {
    ikey ^= *--key;
  } while (key != (void*)_key);
  
  return ikey & CS_IKEY_MASK;
}

INLINE void close_conn(int i)
{
  int fd = i + listen_fd + 1;
  close(fd);
  conn_states[i] = CS_NOCONN;
  if (i + 1 == conns_length) {
    for (conns_length -= 1; conns_length != 0; conns_length--) {
      if (conn_states[conns_length - 1] != CS_NOCONN) {
	break;
      }
    }
  }
  LOG(fd, "closed", NULL);
}

INLINE void setup_conn(int i)
{
  conn_states[i] = CS_KEYREAD;
  conn_key_offsets[i] = 0;
}

static int owner_exists(int ikey, const char* key)
{
  int state = ikey | CS_OWNER, i;
  
  for (i = 0; i < conns_length; i++) {
    if (conn_states[i] == state && memcmp(conn_keys[i], key, KEY_SIZE) == 0) {
      return 1;
    }
  }
  return 0;
}

static void notify_nonowners(int ikey, const char* key)
{
  int state = ikey | CS_NONOWNER, i;
  
  for (i = 0; i < conns_length; i++) {
    if (conn_states[i] == state && memcmp(conn_keys[i], key, KEY_SIZE) == 0) {
      int fd = i + listen_fd + 1;
      if (write(fd, RELEASE_MSG, 1) <= 0) {
	close_conn(i);
      } else {
	LOG(fd, "notify", key);
	setup_conn(i);
      }
    }
  }
}

static void loop(void)
{
  while (! exit_loop) {
    
    fd_set readfds;
    struct timeval tv = { 60, 900 * 1000 };
    int i, num_conns = 0;
    time_t now = time(NULL);
    
    /* setup readfds and set noconn_exists */
    FD_ZERO(&readfds);
    for (i = 0; i < conns_length; i++) {
      switch (conn_states[i] & CS_STATE_MASK) {
      case CS_OWNER:
	if (owner_timeouts[i] <= now) {
	  tv.tv_sec = 0;
	} else {
	  tv.tv_sec = MIN(tv.tv_sec, owner_timeouts[i] - now);
	}
	/* continues */
      case CS_KEYREAD:
      case CS_NONOWNER:
	FD_SET(i + listen_fd + 1, &readfds);
	num_conns++;
	break;
      case CS_NOCONN:
	break;
      }
    }
    if (num_conns < conns_size) {
      FD_SET(listen_fd, &readfds);
    }
    
    /* select, and update time */
    select(listen_fd + conns_length + 1, &readfds, NULL, NULL, &tv);
    now = time(NULL);
    
    /* accept new connections */
    if (FD_ISSET(listen_fd, &readfds)) {
      do {
	int fd = accept(listen_fd, NULL, NULL);
	if (fd == -1) {
	  break;
	}
	nodelay(fd);
	i = fd - listen_fd - 1;
	assert(0 <= i && i < conns_size);
	assert(conn_states[i] == CS_NOCONN);
	setup_conn(i);
	conns_length = MAX(i + 1, conns_length);
	LOG(fd, "connected", NULL);
	num_conns++;
      } while (num_conns < conns_size);
    }
    
    /* read data */
    for (i = 0; i < conns_length; i++) {
      int fd = i + listen_fd + 1;
      switch (conn_states[i] & CS_STATE_MASK) {
      case CS_KEYREAD:
	if (FD_ISSET(fd, &readfds)) {
	  int r = read(fd, conn_keys[i] + conn_key_offsets[i],
		       KEY_SIZE - conn_key_offsets[i]);
	  if (r <= 0) {
	    close_conn(i);
	  } else {
	    if ((conn_key_offsets[i] += r) == KEY_SIZE) {
	      int ikey = key2i(conn_keys[i]);
	      if (owner_exists(ikey, conn_keys[i])) {
		conn_states[i] = ikey | CS_NONOWNER;
		LOG(fd, "notowner", conn_keys[i]);
	      } else {
		write(fd, OWNER_MSG, 1);
		conn_states[i] = ikey | CS_OWNER;
		owner_timeouts[i] = now + timeout_secs;
		LOG(fd, "owner", conn_keys[i]);
	      }
	    }
	  }
	}
	break;
      case CS_OWNER:
	if (FD_ISSET(fd, &readfds)) {
	  char ch;
	  int r = read(fd, &ch, 1);
	  LOG(fd, "release", conn_keys[i]);
	  notify_nonowners(conn_states[i] & CS_IKEY_MASK, conn_keys[i]);
	  if (r <= 0 || ch != RELEASE_MSG[0]) {
	      close_conn(i);
	  } else {
	    setup_conn(i);
	  }
	} else {
	  if (owner_timeouts[i] <= now) {
	    LOG(fd, "release_to", conn_keys[i]);
	    notify_nonowners(conn_states[i] & CS_IKEY_MASK, conn_keys[i]);
	    close_conn(i);
	  }
	}
	break;
      case CS_NONOWNER:
	if (FD_ISSET(fd, &readfds)) {
	  close_conn(i);
	}
	break;
      default:
	assert(! FD_ISSET(fd, &readfds));
	break;
      }
    }
  }
}

void term_handler(int _unused)
{
  exit_loop = 1;
}

static void usage(void)
{
  fprintf(stdout,
	  "Usage: " PROGNAME " [OPTION]...\n"
	  "\n"
	  "Keyedmutexd is a tiny daemon that acts as a mutex for supplied key.\n"
	  "\n"
	  "Options:\n"
	  " -f,--force            removes old socket file if exists\n"
	  " -s,--socket=SOCKET    unix domain socket or tcp port number\n"
	  "                       (default: %s)\n"
	  " -m,--maxconn=MAXCONN  number of max. connections (default: %d)\n"
	  " -t,--timeout=secs     timeout for holding locks (default: %d)\n"
	  "    --no-log           omit logging\n"
	  "    --help             help\n"
	  "    --version          version\n"
	  "\n"
	  "Report bugs to http://labs.cybozu.co.jp/blog/kazuhoatwork/\n",
	  DEFAULT_SOCKPATH,
	  DEFAULT_CONNS_SIZE,
	  DEFAULT_TIMEOUT_SECS);
  exit(0);
}

int main(int argc, char** argv)
{
  int ch;
  
  sun.sun_family = AF_UNIX;
  strcpy(sun.sun_path, DEFAULT_SOCKPATH);
  sin.sin_family = AF_INET;
  sin.sin_addr.s_addr = htonl(INADDR_ANY);
  
  while ((ch = getopt_long(argc, argv, "s:m:t:f", longopts, NULL)) != -1) {
    switch (ch) {
    case 's':
      {
	unsigned short p;
	if (sscanf(optarg, "%hu", &p) == 1) {
	  sin.sin_port = htons(p);
	  use_tcp = 1;
	} else {
	  strncpy(sun.sun_path, optarg, sizeof(sun.sun_path) - 1);
	  sun.sun_path[sizeof(sun.sun_path) - 1] = '\0';
	}
      }
      break;
    case 'f':
      force = 1;
      break;
    case 'm':
      if (sscanf(optarg, "%d", &conns_size) != 1 || conns_size <= 0) {
	fprintf(stderr, "invalid value for parameter \"-n\"\n");
	exit(1);
      }
      break;
    case 't':
      if (sscanf(optarg, "%d", &timeout_secs) != 1 || timeout_secs <= 0) {
	fprintf(stderr, "invalid value for parameter \"-t\"\n");
	exit(1);
      }
      break;
    case 0:
      switch (print_info) {
      case 'h':
	usage();
	break;
      case 'v':
	fputs(PROGNAME " " VERSION "\n", stdout);
	exit(0);
      }
      break;
    default:
      fprintf(stderr, "unknown option: %s\n", argv[optind - 1]);
      exit(1);
    }
  }
  
  if ((conn_states = calloc(conns_size, sizeof(*conn_states))) == NULL
      || (conn_key_offsets = calloc(conns_size, sizeof(*conn_key_offsets)))
      == NULL
      || (conn_keys = calloc(conns_size, sizeof(*conn_keys))) == NULL
      || (owner_timeouts = calloc(conns_size, sizeof(*owner_timeouts))) == NULL
      ) {
    perror(NULL);
    exit(2);
  }
  
  if (use_tcp) {
    if ((listen_fd = socket(AF_INET, SOCK_STREAM, 0)) == -1
	|| reuse_addr(listen_fd) == -1
	|| nonblock(listen_fd) == -1
	|| bind(listen_fd, (struct sockaddr*)&sin, sizeof(sin)) == -1
	|| listen(listen_fd, 5) == -1) {
      perror("failed to open a listening socket");
      exit(2);
    }
  } else {
    if (force) {
      unlink(sun.sun_path);
    }
    if ((listen_fd = socket(AF_UNIX, SOCK_STREAM, 0)) == -1
	|| nonblock(listen_fd) == -1
	|| bind(listen_fd, (struct sockaddr*)&sun, sizeof(sun)) == -1
	|| listen(listen_fd, 5) == -1) {
      perror("failed to open a listening socket");
      exit(2);
    }
  }
  
  signal(SIGPIPE, SIG_IGN);
  signal(SIGHUP, term_handler);
  signal(SIGINT, term_handler);
  signal(SIGTERM, term_handler);
  
  loop();
  
  close(listen_fd);
  if (! use_tcp) {
    unlink(sun.sun_path);
  }
  
  return 0;
}
