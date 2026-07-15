use strict;
use warnings;
use Test::More;
use Eshu;

sub c { Eshu->indent_c($_[0]) }

# ── already-formatted snippets pass through unchanged ──────────────

# 1. simple void function
{
	my $code = <<'END';
void greet(void) {
	printf("Hello, world!\n");
}
END
	is(c($code), $code, 'C: simple void function');
}

# 2. function returning int
{
	my $code = <<'END';
int add(int a, int b) {
	return a + b;
}
END
	is(c($code), $code, 'C: function returning int');
}

# 3. nested if/else
{
	my $code = <<'END';
int clamp(int v, int lo, int hi) {
	if (v < lo) {
		return lo;
	} else if (v > hi) {
		return hi;
	} else {
		return v;
	}
}
END
	is(c($code), $code, 'C: nested if/else/else-if');
}

# 4. for loop
{
	my $code = <<'END';
void zero_array(int *arr, int n) {
	for (int i = 0; i < n; i++) {
		arr[i] = 0;
	}
}
END
	is(c($code), $code, 'C: for loop over array');
}

# 5. while loop with break
{
	my $code = <<'END';
int find_first(int *arr, int n, int val) {
	int i = 0;
	while (i < n) {
		if (arr[i] == val) {
			break;
		}
		i++;
	}
	return i;
}
END
	is(c($code), $code, 'C: while loop with break');
}

# 6. struct definition
{
	my $code = <<'END';
struct Point {
	double x;
	double y;
	double z;
};
END
	is(c($code), $code, 'C: struct definition');
}

# 7. struct with function pointer
{
	my $code = <<'END';
struct Handler {
	const char *name;
	int (*handle)(void *ctx, const char *data, size_t len);
	void (*cleanup)(void *ctx);
};
END
	is(c($code), $code, 'C: struct with function pointer fields');
}

# 8. enum definition
{
	my $code = <<'END';
enum Color {
	COLOR_RED,
	COLOR_GREEN,
	COLOR_BLUE,
	COLOR_COUNT
};
END
	is(c($code), $code, 'C: enum definition');
}

# 9. typedef struct
{
	my $code = <<'END';
typedef struct {
	size_t capacity;
	size_t length;
	char *data;
} Buffer;
END
	is(c($code), $code, 'C: typedef struct');
}

# 10. nested struct
{
	my $code = <<'END';
typedef struct {
	struct {
		int x;
		int y;
	} origin;
	struct {
		int w;
		int h;
	} size;
} Rect;
END
	is(c($code), $code, 'C: nested anonymous struct');
}

# 11. function with multiple returns
{
	my $code = <<'END';
const char *error_string(int code) {
	if (code == 0) {
		return "OK";
	}
	if (code == -1) {
		return "NOT_FOUND";
	}
	if (code == -2) {
		return "PERMISSION_DENIED";
	}
	return "UNKNOWN";
}
END
	is(c($code), $code, 'C: function with multiple returns');
}

# 12. do-while loop
{
	my $code = <<'END';
int next_power_of_two(int n) {
	int p = 1;
	do {
		p <<= 1;
	} while (p < n);
	return p;
}
END
	is(c($code), $code, 'C: do-while loop');
}

# 13. static function
{
	my $code = <<'END';
static int compare_ints(const void *a, const void *b) {
	int x = *(const int *)a;
	int y = *(const int *)b;
	if (x < y) {
		return -1;
	}
	if (x > y) {
		return 1;
	}
	return 0;
}
END
	is(c($code), $code, 'C: qsort comparator');
}

# 14. struct with bitfields
{
	my $code = <<'END';
typedef struct {
	unsigned int r : 8;
	unsigned int g : 8;
	unsigned int b : 8;
	unsigned int a : 8;
} RGBA;
END
	is(c($code), $code, 'C: struct with bitfields');
}

# 15. function pointer typedef
{
	my $code = <<'END';
typedef int (*Comparator)(const void *a, const void *b);

void sort(void *base, size_t n, size_t size, Comparator cmp) {
	qsort(base, n, size, cmp);
}
END
	is(c($code), $code, 'C: function pointer typedef');
}

# 16. linked-list node
{
	my $code = <<'END';
typedef struct Node {
	int value;
	struct Node *next;
} Node;

Node *node_new(int value) {
	Node *n = malloc(sizeof(Node));
	if (!n) {
		return NULL;
	}
	n->value = value;
	n->next  = NULL;
	return n;
}
END
	is(c($code), $code, 'C: linked-list node and constructor');
}

# 17. linked-list insert
{
	my $code = <<'END';
void list_push(Node **head, int value) {
	Node *n = node_new(value);
	if (!n) {
		return;
	}
	n->next = *head;
	*head   = n;
}
END
	is(c($code), $code, 'C: linked-list push');
}

# 18. linked-list free
{
	my $code = <<'END';
void list_free(Node *head) {
	while (head) {
		Node *next = head->next;
		free(head);
		head = next;
	}
}
END
	is(c($code), $code, 'C: linked-list free');
}

# 19. goto-cleanup pattern
{
	my $code = <<'END';
int process_file(const char *path) {
	int rc = -1;
	FILE *f = fopen(path, "r");
	if (!f) {
		goto done;
	}
	char *buf = malloc(4096);
	if (!buf) {
		goto close_file;
	}
	rc = do_work(f, buf);
	free(buf);
close_file:
	fclose(f);
done:
	return rc;
}
END
	is(c($code), $code, 'C: goto-cleanup pattern');
}

# 20. arena allocator struct
{
	my $code = <<'END';
typedef struct {
	char *base;
	size_t offset;
	size_t capacity;
} Arena;

void *arena_alloc(Arena *a, size_t size) {
	if (a->offset + size > a->capacity) {
		return NULL;
	}
	void *ptr = a->base + a->offset;
	a->offset += size;
	return ptr;
}
END
	is(c($code), $code, 'C: arena allocator');
}

# 21. signal handler
{
	my $code = <<'END';
static volatile sig_atomic_t running = 1;

static void handle_sigint(int sig) {
	(void)sig;
	running = 0;
}

void install_handler(void) {
	struct sigaction sa = {0};
	sa.sa_handler = handle_sigint;
	sigaction(SIGINT, &sa, NULL);
}
END
	is(c($code), $code, 'C: signal handler installation');
}

# 22. hash table lookup
{
	my $code = <<'END';
typedef struct Entry {
	unsigned long   hash;
	const char     *key;
	void           *value;
	struct Entry   *next;
} Entry;

void *ht_get(Entry **table, size_t cap, const char *key) {
	unsigned long h = hash_str(key) % cap;
	for (Entry *e = table[h]; e; e = e->next) {
		if (strcmp(e->key, key) == 0) {
			return e->value;
		}
	}
	return NULL;
}
END
	is(c($code), $code, 'C: hash table get');
}

# 23. variadic logger
{
	my $code = <<'END';
void log_msg(const char *level, const char *fmt, ...) {
	va_list ap;
	va_start(ap, fmt);
	fprintf(stderr, "[%s] ", level);
	vfprintf(stderr, fmt, ap);
	fputc('\n', stderr);
	va_end(ap);
}
END
	is(c($code), $code, 'C: variadic logger');
}

# 24. recursive fibonacci
{
	my $code = <<'END';
long fib(int n) {
	if (n <= 1) {
		return n;
	}
	return fib(n - 1) + fib(n - 2);
}
END
	is(c($code), $code, 'C: recursive fibonacci');
}

# 25. macro-guarded inline function
{
	my $code = <<'END';
static inline int max_int(int a, int b) {
	return a > b ? a : b;
}

static inline int min_int(int a, int b) {
	return a < b ? a : b;
}
END
	is(c($code), $code, 'C: inline min/max functions');
}

# 26. string builder append
{
	my $code = <<'END';
int buf_append(Buffer *b, const char *s, size_t n) {
	if (b->length + n >= b->capacity) {
		size_t newcap = b->capacity * 2 + n + 1;
		char *p = realloc(b->data, newcap);
		if (!p) {
			return -1;
		}
		b->data     = p;
		b->capacity = newcap;
	}
	memcpy(b->data + b->length, s, n);
	b->length += n;
	b->data[b->length] = '\0';
	return 0;
}
END
	is(c($code), $code, 'C: string builder append');
}

# 27. file read-all
{
	my $code = <<'END';
char *read_file(const char *path, size_t *out_len) {
	FILE *f = fopen(path, "rb");
	if (!f) {
		return NULL;
	}
	fseek(f, 0, SEEK_END);
	long len = ftell(f);
	rewind(f);
	char *buf = malloc((size_t)len + 1);
	if (!buf) {
		fclose(f);
		return NULL;
	}
	fread(buf, 1, (size_t)len, f);
	buf[len] = '\0';
	fclose(f);
	if (out_len) {
		*out_len = (size_t)len;
	}
	return buf;
}
END
	is(c($code), $code, 'C: read entire file');
}

# 28. observer callback registration
{
	my $code = <<'END';
#define MAX_OBSERVERS 16

typedef void (*Observer)(void *ctx, const char *event);

static Observer  obs_fn[MAX_OBSERVERS];
static void     *obs_ctx[MAX_OBSERVERS];
static int       obs_count = 0;

int observe_register(Observer fn, void *ctx) {
	if (obs_count >= MAX_OBSERVERS) {
		return -1;
	}
	obs_fn[obs_count]  = fn;
	obs_ctx[obs_count] = ctx;
	obs_count++;
	return 0;
}
END
	is(c($code), $code, 'C: observer callback registration');
}

# 29. event dispatch loop
{
	my $code = <<'END';
void event_dispatch(const char *event) {
	for (int i = 0; i < obs_count; i++) {
		obs_fn[i](obs_ctx[i], event);
	}
}
END
	is(c($code), $code, 'C: event dispatch loop');
}

# 30. doubly-linked list remove
{
	my $code = <<'END';
void dlist_remove(DNode **head, DNode *node) {
	if (node->prev) {
		node->prev->next = node->next;
	} else {
		*head = node->next;
	}
	if (node->next) {
		node->next->prev = node->prev;
	}
	node->prev = NULL;
	node->next = NULL;
}
END
	is(c($code), $code, 'C: doubly-linked list remove');
}

# ── normalization: messy → clean ──────────────────────────────────

# 31. unindented function body
{
	my $in = <<'END';
int square(int n) {
return n * n;
}
END
	my $exp = <<'END';
int square(int n) {
	return n * n;
}
END
	is(c($in), $exp, 'C: unindented function body normalised');
}

# 32. over-indented body
{
	my $in = <<'END';
int cube(int n) {
				return n * n * n;
}
END
	my $exp = <<'END';
int cube(int n) {
	return n * n * n;
}
END
	is(c($in), $exp, 'C: over-indented body normalised');
}

# 33. unindented nested blocks
{
	my $in = <<'END';
void fizzbuzz(int n) {
for (int i = 1; i <= n; i++) {
if (i % 15 == 0) {
puts("FizzBuzz");
} else if (i % 3 == 0) {
puts("Fizz");
} else if (i % 5 == 0) {
puts("Buzz");
} else {
printf("%d\n", i);
}
}
}
END
	my $exp = <<'END';
void fizzbuzz(int n) {
	for (int i = 1; i <= n; i++) {
		if (i % 15 == 0) {
			puts("FizzBuzz");
		} else if (i % 3 == 0) {
			puts("Fizz");
		} else if (i % 5 == 0) {
			puts("Buzz");
		} else {
			printf("%d\n", i);
		}
	}
}
END
	is(c($in), $exp, 'C: unindented nested for+if normalised');
}

# 34. unindented struct fields
{
	my $in = <<'END';
typedef struct {
int id;
const char *name;
double score;
} Record;
END
	my $exp = <<'END';
typedef struct {
	int id;
	const char *name;
	double score;
} Record;
END
	is(c($in), $exp, 'C: unindented struct fields normalised');
}

# 35. unindented enum values
{
	my $in = <<'END';
enum State {
STATE_IDLE,
STATE_RUNNING,
STATE_PAUSED,
STATE_DONE
};
END
	my $exp = <<'END';
enum State {
	STATE_IDLE,
	STATE_RUNNING,
	STATE_PAUSED,
	STATE_DONE
};
END
	is(c($in), $exp, 'C: unindented enum values normalised');
}

# 36. unindented while body
{
	my $in = <<'END';
void drain(Queue *q) {
while (!queue_empty(q)) {
Item *it = queue_pop(q);
item_free(it);
}
}
END
	my $exp = <<'END';
void drain(Queue *q) {
	while (!queue_empty(q)) {
		Item *it = queue_pop(q);
		item_free(it);
	}
}
END
	is(c($in), $exp, 'C: unindented while body normalised');
}

# 37. unindented if/else chain
{
	my $in = <<'END';
const char *weekday(int d) {
if (d == 0) {
return "Sunday";
} else if (d == 1) {
return "Monday";
} else if (d == 6) {
return "Saturday";
} else {
return "Weekday";
}
}
END
	my $exp = <<'END';
const char *weekday(int d) {
	if (d == 0) {
		return "Sunday";
	} else if (d == 1) {
		return "Monday";
	} else if (d == 6) {
		return "Saturday";
	} else {
		return "Weekday";
	}
}
END
	is(c($in), $exp, 'C: unindented if/else chain normalised');
}

# 38. unindented hash table set
{
	my $in = <<'END';
int ht_set(Entry **table, size_t cap, const char *key, void *value) {
unsigned long h = hash_str(key) % cap;
for (Entry *e = table[h]; e; e = e->next) {
if (strcmp(e->key, key) == 0) {
e->value = value;
return 0;
}
}
Entry *e = calloc(1, sizeof(Entry));
if (!e) {
return -1;
}
e->hash    = hash_str(key);
e->key     = key;
e->value   = value;
e->next    = table[h];
table[h]   = e;
return 0;
}
END
	my $exp = <<'END';
int ht_set(Entry **table, size_t cap, const char *key, void *value) {
	unsigned long h = hash_str(key) % cap;
	for (Entry *e = table[h]; e; e = e->next) {
		if (strcmp(e->key, key) == 0) {
			e->value = value;
			return 0;
		}
	}
	Entry *e = calloc(1, sizeof(Entry));
	if (!e) {
		return -1;
	}
	e->hash    = hash_str(key);
	e->key     = key;
	e->value   = value;
	e->next    = table[h];
	table[h]   = e;
	return 0;
}
END
	is(c($in), $exp, 'C: unindented hash-table set normalised');
}

# 39. unindented recursive tree
{
	my $in = <<'END';
int tree_height(Tree *t) {
if (!t) {
return 0;
}
int lh = tree_height(t->left);
int rh = tree_height(t->right);
return 1 + (lh > rh ? lh : rh);
}
END
	my $exp = <<'END';
int tree_height(Tree *t) {
	if (!t) {
		return 0;
	}
	int lh = tree_height(t->left);
	int rh = tree_height(t->right);
	return 1 + (lh > rh ? lh : rh);
}
END
	is(c($in), $exp, 'C: unindented recursive tree-height normalised');
}

# 40. unindented thread worker
{
	my $in = <<'END';
void *worker_thread(void *arg) {
WorkQueue *q = (WorkQueue *)arg;
while (1) {
pthread_mutex_lock(&q->mutex);
while (queue_empty(q) && !q->shutdown) {
pthread_cond_wait(&q->cond, &q->mutex);
}
if (q->shutdown && queue_empty(q)) {
pthread_mutex_unlock(&q->mutex);
break;
}
Task t = queue_pop(q);
pthread_mutex_unlock(&q->mutex);
task_run(&t);
}
return NULL;
}
END
	my $exp = <<'END';
void *worker_thread(void *arg) {
	WorkQueue *q = (WorkQueue *)arg;
	while (1) {
		pthread_mutex_lock(&q->mutex);
		while (queue_empty(q) && !q->shutdown) {
			pthread_cond_wait(&q->cond, &q->mutex);
		}
		if (q->shutdown && queue_empty(q)) {
			pthread_mutex_unlock(&q->mutex);
			break;
		}
		Task t = queue_pop(q);
		pthread_mutex_unlock(&q->mutex);
		task_run(&t);
	}
	return NULL;
}
END
	is(c($in), $exp, 'C: unindented thread worker normalised');
}

# 41. unindented ring buffer
{
	my $in = <<'END';
int rb_push(RingBuf *rb, int val) {
if ((rb->write + 1) % rb->cap == rb->read) {
return -1;
}
rb->buf[rb->write] = val;
rb->write = (rb->write + 1) % rb->cap;
return 0;
}
END
	my $exp = <<'END';
int rb_push(RingBuf *rb, int val) {
	if ((rb->write + 1) % rb->cap == rb->read) {
		return -1;
	}
	rb->buf[rb->write] = val;
	rb->write = (rb->write + 1) % rb->cap;
	return 0;
}
END
	is(c($in), $exp, 'C: unindented ring-buffer push normalised');
}

# 42. unindented binary search
{
	my $in = <<'END';
int bsearch_int(const int *arr, int n, int target) {
int lo = 0, hi = n - 1;
while (lo <= hi) {
int mid = lo + (hi - lo) / 2;
if (arr[mid] == target) {
return mid;
} else if (arr[mid] < target) {
lo = mid + 1;
} else {
hi = mid - 1;
}
}
return -1;
}
END
	my $exp = <<'END';
int bsearch_int(const int *arr, int n, int target) {
	int lo = 0, hi = n - 1;
	while (lo <= hi) {
		int mid = lo + (hi - lo) / 2;
		if (arr[mid] == target) {
			return mid;
		} else if (arr[mid] < target) {
			lo = mid + 1;
		} else {
			hi = mid - 1;
		}
	}
	return -1;
}
END
	is(c($in), $exp, 'C: unindented binary search normalised');
}

# 43. unindented insertion sort
{
	my $in = <<'END';
void insertion_sort(int *arr, int n) {
for (int i = 1; i < n; i++) {
int key = arr[i];
int j = i - 1;
while (j >= 0 && arr[j] > key) {
arr[j + 1] = arr[j];
j--;
}
arr[j + 1] = key;
}
}
END
	my $exp = <<'END';
void insertion_sort(int *arr, int n) {
	for (int i = 1; i < n; i++) {
		int key = arr[i];
		int j = i - 1;
		while (j >= 0 && arr[j] > key) {
			arr[j + 1] = arr[j];
			j--;
		}
		arr[j + 1] = key;
	}
}
END
	is(c($in), $exp, 'C: unindented insertion sort normalised');
}

# 44. unindented arena reset + alloc
{
	my $in = <<'END';
void arena_reset(Arena *a) {
a->offset = 0;
}

char *arena_strdup(Arena *a, const char *s) {
size_t n = strlen(s) + 1;
char *p = arena_alloc(a, n);
if (p) {
memcpy(p, s, n);
}
return p;
}
END
	my $exp = <<'END';
void arena_reset(Arena *a) {
	a->offset = 0;
}

char *arena_strdup(Arena *a, const char *s) {
	size_t n = strlen(s) + 1;
	char *p = arena_alloc(a, n);
	if (p) {
		memcpy(p, s, n);
	}
	return p;
}
END
	is(c($in), $exp, 'C: unindented arena reset+strdup normalised');
}

# 45. unindented strlen implementation
{
	my $in = <<'END';
size_t my_strlen(const char *s) {
const char *p = s;
while (*p) {
p++;
}
return (size_t)(p - s);
}
END
	my $exp = <<'END';
size_t my_strlen(const char *s) {
	const char *p = s;
	while (*p) {
		p++;
	}
	return (size_t)(p - s);
}
END
	is(c($in), $exp, 'C: unindented strlen implementation normalised');
}

# ── idempotency on complex patterns ───────────────────────────────

# 46. complex multi-function file
{
	my $messy = <<'END';
typedef struct { int x; int y; } Vec2;
Vec2 vec2_add(Vec2 a, Vec2 b) {
Vec2 r;
r.x = a.x + b.x;
r.y = a.y + b.y;
return r;
}
float vec2_dot(Vec2 a, Vec2 b) {
return (float)(a.x * b.x + a.y * b.y);
}
END
	my $once = c($messy);
	is(c($once), $once, 'C: vec2 helpers idempotent');
}

# 47. error-code chain
{
	my $messy = <<'END';
int pipeline(const char *input, char **output) {
char *stage1 = NULL; char *stage2 = NULL; int rc = -1;
rc = transform_a(input, &stage1);
if (rc < 0) { goto done; }
rc = transform_b(stage1, &stage2);
if (rc < 0) { goto done; }
*output = stage2; stage2 = NULL; rc = 0;
done: free(stage1); free(stage2);
return rc;
}
END
	my $once = c($messy);
	is(c($once), $once, 'C: pipeline with cleanup idempotent');
}

# 48. recursive quicksort partition
{
	my $messy = <<'END';
static int partition(int *a, int lo, int hi) {
int pivot = a[hi]; int i = lo - 1;
for (int j = lo; j < hi; j++) {
if (a[j] <= pivot) { i++; int t = a[i]; a[i] = a[j]; a[j] = t; }
}
int t = a[i+1]; a[i+1] = a[hi]; a[hi] = t;
return i + 1;
}
void quicksort(int *a, int lo, int hi) {
if (lo < hi) {
int p = partition(a, lo, hi);
quicksort(a, lo, p - 1);
quicksort(a, p + 1, hi);
}
}
END
	my $once = c($messy);
	is(c($once), $once, 'C: quicksort idempotent');
}

# 49. mutex-protected counter
{
	my $messy = <<'END';
typedef struct { pthread_mutex_t mu; int value; } Counter;
void counter_init(Counter *c) { pthread_mutex_init(&c->mu, NULL); c->value = 0; }
void counter_inc(Counter *c) { pthread_mutex_lock(&c->mu); c->value++; pthread_mutex_unlock(&c->mu); }
int counter_get(Counter *c) { pthread_mutex_lock(&c->mu); int v = c->value; pthread_mutex_unlock(&c->mu); return v; }
void counter_destroy(Counter *c) { pthread_mutex_destroy(&c->mu); }
END
	my $once = c($messy);
	is(c($once), $once, 'C: mutex-protected counter idempotent');
}

# 50. trie node insert/search
{
	my $messy = <<'END';
typedef struct Trie { struct Trie *children[26]; int terminal; } Trie;
void trie_insert(Trie *root, const char *word) {
Trie *cur = root;
for (const char *p = word; *p; p++) {
int idx = *p - 'a';
if (!cur->children[idx]) { cur->children[idx] = calloc(1, sizeof(Trie)); }
cur = cur->children[idx];
}
cur->terminal = 1;
}
int trie_search(Trie *root, const char *word) {
Trie *cur = root;
for (const char *p = word; *p; p++) {
int idx = *p - 'a';
if (!cur->children[idx]) { return 0; }
cur = cur->children[idx];
}
return cur->terminal;
}
END
	my $once = c($messy);
	is(c($once), $once, 'C: trie insert/search idempotent');
}

done_testing;
