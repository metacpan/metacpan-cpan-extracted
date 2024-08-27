#define CONTROL_TERMINATE 't'
#define CONTROL_REWATCH   'r'

static pthread_t        watch_thread;
static int              control_pipe[2]= { -1, -1 };
static pthread_mutex_t  watch_list_mutex= PTHREAD_MUTEX_INITIALIZER;
static int     volatile watch_list_count= 0,
                        watch_list_alloc= 0;
static struct socketalarm
    *volatile *volatile watch_list= NULL;

// May only be called by Perl's thread
static bool watch_list_add(struct socketalarm *alarm);
// May only be called by Perl's thread
static bool watch_list_remove(struct socketalarm *alarm);
static void watch_list_item_get_status(struct socketalarm *alarm, int *cur_action_out);
static void shutdown_watch_thread();
static void* watch_thread_main(void*);
