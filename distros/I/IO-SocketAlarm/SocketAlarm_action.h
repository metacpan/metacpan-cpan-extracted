#define ACT_KILL          0x10
#define ACT_SLEEP         0x20
#define ACT_JUMP          0x30
#define ACT_EXEC          0x40
#define ACT_RUN           0x41
#define ACT_FD_x          0x50
#define ACT_PNAME_x       0x60
#define ACT_SNAME_x       0x70
#define ACT_x_CLOSE       0x00
#define ACT_x_SHUT_R      0x01
#define ACT_x_SHUT_W      0x02
#define ACT_x_SHUT_RW     0x03

struct action_kill {
   pid_t pid;
   int signal;
};
struct action_fd {
   int fd;
};
struct action_sockname {
   struct sockaddr *addr;
   socklen_t addr_len;
};
struct action_run {
   char **argv;   // allocated to length argc+1
   int argc;
};
struct action_sleep {
   double seconds;
};
//struct action_jump {
//   int idx;
//};
struct action {
   int op;       // one of the ACT_* enum codes
   int orig_idx; // offset in original arrayref of actions
   union {
      struct action_kill       kill;
      struct action_fd         fd;
      struct action_sockname   nam;
      struct action_run        run;
      struct action_sleep      slp;
      //struct action_jump       jmp;
   } act;
};

static bool parse_actions(SV **spec, int n_spec, struct action *actions, size_t *n_actions, char *aux_buf, size_t *aux_len);
static bool execute_action(struct action *act, bool resume, struct timespec *now_ts, struct socketalarm *parent);
static const char *act_fd_variant_name(int variant);
static int snprint_action(char *buffer, size_t buflen, struct action *act);
static void inflate_action(struct action *act, AV *dest);
