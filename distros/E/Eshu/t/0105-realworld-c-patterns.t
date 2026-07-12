use strict;
use warnings;
use Test::More tests => 12;
use Eshu;

# Linked list node operations
{
    my $in = <<'END';
node_t *list_insert(node_t *head, int val) {
node_t *n = malloc(sizeof(node_t));
if (!n) return head;
n->val  = val;
n->next = head;
return n;
}

void list_free(node_t *head) {
while (head) {
node_t *next = head->next;
free(head);
head = next;
}
}
END
    my $exp = <<'END';
node_t *list_insert(node_t *head, int val) {
	node_t *n = malloc(sizeof(node_t));
	if (!n) return head;
	n->val  = val;
	n->next = head;
	return n;
}

void list_free(node_t *head) {
	while (head) {
		node_t *next = head->next;
		free(head);
		head = next;
	}
}
END
    is(Eshu->indent_c($in), $exp, 'C: linked list insert and free');
}

# State machine with enum + switch
{
    my $in = <<'END';
typedef enum { STATE_IDLE, STATE_RUN, STATE_DONE, STATE_ERR } state_t;

state_t fsm_step(state_t s, int event) {
switch (s) {
case STATE_IDLE:
return (event == EV_START) ? STATE_RUN : STATE_IDLE;
case STATE_RUN:
if (event == EV_DONE) return STATE_DONE;
if (event == EV_ERR)  return STATE_ERR;
return STATE_RUN;
case STATE_DONE:
case STATE_ERR:
return STATE_IDLE;
default:
return STATE_ERR;
}
}
END
    my $exp = <<'END';
typedef enum { STATE_IDLE, STATE_RUN, STATE_DONE, STATE_ERR } state_t;

state_t fsm_step(state_t s, int event) {
	switch (s) {
		case STATE_IDLE:
			return (event == EV_START) ? STATE_RUN : STATE_IDLE;
		case STATE_RUN:
			if (event == EV_DONE) return STATE_DONE;
			if (event == EV_ERR)  return STATE_ERR;
			return STATE_RUN;
		case STATE_DONE:
		case STATE_ERR:
			return STATE_IDLE;
		default:
			return STATE_ERR;
	}
}
END
    is(Eshu->indent_c($in), $exp, 'C: state machine with enum and switch');
}

# Error handling with goto cleanup pattern
{
    my $in = <<'END';
int process_file(const char *path) {
int   rc  = -1;
FILE *fp  = NULL;
char *buf = NULL;

fp = fopen(path, "r");
if (!fp) goto done;

buf = malloc(BUF_SIZE);
if (!buf) goto done;

if (fread(buf, 1, BUF_SIZE, fp) == 0) goto done;

rc = do_work(buf);

done:
free(buf);
if (fp) fclose(fp);
return rc;
}
END
    my $exp = <<'END';
int process_file(const char *path) {
	int   rc  = -1;
	FILE *fp  = NULL;
	char *buf = NULL;

	fp = fopen(path, "r");
	if (!fp) goto done;

	buf = malloc(BUF_SIZE);
	if (!buf) goto done;

	if (fread(buf, 1, BUF_SIZE, fp) == 0) goto done;

	rc = do_work(buf);

done:
	free(buf);
	if (fp) fclose(fp);
	return rc;
}
END
    is(Eshu->indent_c($in), $exp, 'C: error handling with goto cleanup label');
}

# Bit manipulation utilities
{
    my $in = <<'END';
static inline uint32_t rotl32(uint32_t x, int k) {
return (x << k) | (x >> (32 - k));
}

static inline int popcount(uint64_t x) {
int n = 0;
while (x) {
n += x & 1;
x >>= 1;
}
return n;
}

#define BIT_SET(v, n)   ((v) |=  (1u << (n)))
#define BIT_CLR(v, n)   ((v) &= ~(1u << (n)))
#define BIT_TST(v, n)   ((v) &   (1u << (n)))
END
    my $exp = <<'END';
static inline uint32_t rotl32(uint32_t x, int k) {
	return (x << k) | (x >> (32 - k));
}

static inline int popcount(uint64_t x) {
	int n = 0;
	while (x) {
		n += x & 1;
		x >>= 1;
	}
	return n;
}

#define BIT_SET(v, n)   ((v) |=  (1u << (n)))
#define BIT_CLR(v, n)   ((v) &= ~(1u << (n)))
#define BIT_TST(v, n)   ((v) &   (1u << (n)))
END
    is(Eshu->indent_c($in), $exp, 'C: bit manipulation with macros and inline functions');
}

# Variadic function with va_list
{
    my $in = <<'END';
int log_message(int level, const char *fmt, ...) {
va_list ap;
int     n;

if (level < g_log_level) return 0;

va_start(ap, fmt);
n = vfprintf(stderr, fmt, ap);
va_end(ap);
return n;
}
END
    my $exp = <<'END';
int log_message(int level, const char *fmt, ...) {
	va_list ap;
	int     n;

	if (level < g_log_level) return 0;

	va_start(ap, fmt);
	n = vfprintf(stderr, fmt, ap);
	va_end(ap);
	return n;
}
END
    is(Eshu->indent_c($in), $exp, 'C: variadic function with va_list');
}

# Recursive descent parser fragment
{
    my $in = <<'END';
static ast_t *parse_expr(parser_t *p) {
ast_t *lhs = parse_unary(p);
while (is_binop(p->tok)) {
int    op  = p->tok;
int    prec = op_prec(op);
advance(p);
ast_t *rhs = parse_expr_prec(p, prec + 1);
lhs = ast_binop(op, lhs, rhs);
}
return lhs;
}
END
    my $exp = <<'END';
static ast_t *parse_expr(parser_t *p) {
	ast_t *lhs = parse_unary(p);
	while (is_binop(p->tok)) {
		int    op  = p->tok;
		int    prec = op_prec(op);
		advance(p);
		ast_t *rhs = parse_expr_prec(p, prec + 1);
		lhs = ast_binop(op, lhs, rhs);
	}
	return lhs;
}
END
    is(Eshu->indent_c($in), $exp, 'C: recursive descent parser');
}

# Header guard with nested structs
{
    my $in = <<'END';
#ifndef VEC_H
#define VEC_H

#include <stddef.h>

typedef struct {
float x;
float y;
float z;
} vec3_t;

typedef struct {
vec3_t origin;
vec3_t dir;
float  t_min;
float  t_max;
} ray_t;

vec3_t vec3_add(vec3_t a, vec3_t b);
float  vec3_dot(vec3_t a, vec3_t b);
vec3_t vec3_cross(vec3_t a, vec3_t b);

#endif /* VEC_H */
END
    my $exp = <<'END';
#ifndef VEC_H
#define VEC_H

#include <stddef.h>

typedef struct {
	float x;
	float y;
	float z;
} vec3_t;

typedef struct {
	vec3_t origin;
	vec3_t dir;
	float  t_min;
	float  t_max;
} ray_t;

vec3_t vec3_add(vec3_t a, vec3_t b);
float  vec3_dot(vec3_t a, vec3_t b);
vec3_t vec3_cross(vec3_t a, vec3_t b);

#endif /* VEC_H */
END
    is(Eshu->indent_c($in), $exp, 'C: header guard with nested typedef structs');
}

# Callback registration with function pointers
{
    my $in = <<'END';
typedef void (*handler_fn)(int sig, void *ctx);

typedef struct {
int        sig;
handler_fn fn;
void      *ctx;
} handler_t;

static handler_t handlers[MAX_SIG];
static int       nhandlers = 0;

int register_handler(int sig, handler_fn fn, void *ctx) {
if (nhandlers >= MAX_SIG) return -1;
handlers[nhandlers].sig = sig;
handlers[nhandlers].fn  = fn;
handlers[nhandlers].ctx = ctx;
nhandlers++;
return 0;
}
END
    my $exp = <<'END';
typedef void (*handler_fn)(int sig, void *ctx);

typedef struct {
	int        sig;
	handler_fn fn;
	void      *ctx;
} handler_t;

static handler_t handlers[MAX_SIG];
static int       nhandlers = 0;

int register_handler(int sig, handler_fn fn, void *ctx) {
	if (nhandlers >= MAX_SIG) return -1;
	handlers[nhandlers].sig = sig;
	handlers[nhandlers].fn  = fn;
	handlers[nhandlers].ctx = ctx;
	nhandlers++;
	return 0;
}
END
    is(Eshu->indent_c($in), $exp, 'C: callback registration with function pointer struct');
}

# Platform #ifdef blocks inside function
{
    my $in = <<'END';
ssize_t safe_write(int fd, const void *buf, size_t n) {
const char *p = (const char *)buf;
size_t rem = n;
while (rem > 0) {
ssize_t w;
#ifdef _WIN32
w = _write(fd, p, (unsigned int)rem);
#else
w = write(fd, p, rem);
#endif
if (w < 0) {
#ifndef _WIN32
if (errno == EINTR) continue;
#endif
return -1;
}
p   += w;
rem -= (size_t)w;
}
return (ssize_t)n;
}
END
    my $exp = <<'END';
ssize_t safe_write(int fd, const void *buf, size_t n) {
	const char *p = (const char *)buf;
	size_t rem = n;
	while (rem > 0) {
		ssize_t w;
#ifdef _WIN32
		w = _write(fd, p, (unsigned int)rem);
#else
		w = write(fd, p, rem);
#endif
		if (w < 0) {
#ifndef _WIN32
			if (errno == EINTR) continue;
#endif
			return -1;
		}
		p   += w;
		rem -= (size_t)w;
	}
	return (ssize_t)n;
}
END
    is(Eshu->indent_c($in), $exp, 'C: platform #ifdef blocks inside nested function');
}

# Arena allocator
{
    my $in = <<'END';
typedef struct {
char  *base;
size_t used;
size_t cap;
} arena_t;

void arena_init(arena_t *a, size_t cap) {
a->base = malloc(cap);
a->used = 0;
a->cap  = cap;
}

void *arena_alloc(arena_t *a, size_t sz) {
sz = (sz + 7u) & ~7u; /* align to 8 bytes */
if (a->used + sz > a->cap) return NULL;
void *ptr = a->base + a->used;
a->used  += sz;
return ptr;
}

void arena_reset(arena_t *a) {
a->used = 0;
}

void arena_free(arena_t *a) {
free(a->base);
a->base = NULL;
a->used = a->cap = 0;
}
END
    my $exp = <<'END';
typedef struct {
	char  *base;
	size_t used;
	size_t cap;
} arena_t;

void arena_init(arena_t *a, size_t cap) {
	a->base = malloc(cap);
	a->used = 0;
	a->cap  = cap;
}

void *arena_alloc(arena_t *a, size_t sz) {
	sz = (sz + 7u) & ~7u; /* align to 8 bytes */
	if (a->used + sz > a->cap) return NULL;
	void *ptr = a->base + a->used;
	a->used  += sz;
	return ptr;
}

void arena_reset(arena_t *a) {
	a->used = 0;
}

void arena_free(arena_t *a) {
	free(a->base);
	a->base = NULL;
	a->used = a->cap = 0;
}
END
    is(Eshu->indent_c($in), $exp, 'C: arena allocator with alignment');
}

# Multi-level nested callbacks (qsort comparator pattern)
{
    my $in = <<'END';
static int cmp_record(const void *a, const void *b) {
const record_t *ra = (const record_t *)a;
const record_t *rb = (const record_t *)b;
if (ra->score != rb->score)
return (ra->score > rb->score) ? -1 : 1;
return strcmp(ra->name, rb->name);
}

void sort_records(record_t *recs, size_t n) {
qsort(recs, n, sizeof(record_t), cmp_record);
}
END
    my $exp = <<'END';
static int cmp_record(const void *a, const void *b) {
	const record_t *ra = (const record_t *)a;
	const record_t *rb = (const record_t *)b;
	if (ra->score != rb->score)
	return (ra->score > rb->score) ? -1 : 1;
	return strcmp(ra->name, rb->name);
}

void sort_records(record_t *recs, size_t n) {
	qsort(recs, n, sizeof(record_t), cmp_record);
}
END
    is(Eshu->indent_c($in), $exp, 'C: qsort comparator with multi-field comparison');
}

# Idempotency check on the above patterns
{
    my $snippets = [
        "node_t *p = head;\nwhile (p) {\nif (p->val > max) {\nmax = p->val;\n}\np = p->next;\n}\n",
        "for (int i = 0; i < n; i++) {\nfor (int j = i+1; j < n; j++) {\nif (a[i] > a[j]) {\nint tmp = a[i]; a[i] = a[j]; a[j] = tmp;\n}\n}\n}\n",
    ];
    my $ok = 1;
    for my $src (@$snippets) {
        my $once  = Eshu->indent_c($src);
        my $twice = Eshu->indent_c($once);
        $ok = 0 unless $once eq $twice;
    }
    ok($ok, 'C: realworld snippets are idempotent');
}
