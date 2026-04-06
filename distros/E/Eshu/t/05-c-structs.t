use strict;
use warnings;
use Test::More tests => 7;
use Eshu;

# typedef struct
{
	my $input = <<'END';
typedef struct {
int x;
int y;
} Point;
END

	my $expected = <<'END';
typedef struct {
	int x;
	int y;
} Point;
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'typedef struct');
}

# union
{
	my $input = <<'END';
union Value {
int integer;
double floating;
char *string;
};
END

	my $expected = <<'END';
union Value {
	int integer;
	double floating;
	char *string;
};
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'union declaration');
}

# enum
{
	my $input = <<'END';
enum Direction {
NORTH,
SOUTH,
EAST,
WEST
};
END

	my $expected = <<'END';
enum Direction {
	NORTH,
	SOUTH,
	EAST,
	WEST
};
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'enum declaration');
}

# nested struct (anonymous inner struct)
{
	my $input = <<'END';
struct Config {
int width;
int height;
struct {
int r;
int g;
int b;
} color;
};
END

	my $expected = <<'END';
struct Config {
	int width;
	int height;
	struct {
		int r;
		int g;
		int b;
	} color;
};
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'nested anonymous struct member');
}

# struct with function pointer members (vtable pattern)
{
	my $input = <<'END';
struct VTable {
int (*init)(void);
void (*destroy)(void *self);
int (*process)(void *self, int n);
};
END

	my $expected = <<'END';
struct VTable {
	int (*init)(void);
	void (*destroy)(void *self);
	int (*process)(void *self, int n);
};
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'struct with function pointer members');
}

# typedef function pointer
{
	my $input = <<'END';
typedef int (*handler_t)(void *ctx, const char *msg);

void set_handler(handler_t fn) {
g_handler = fn;
}
END

	my $expected = <<'END';
typedef int (*handler_t)(void *ctx, const char *msg);

void set_handler(handler_t fn) {
	g_handler = fn;
}
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'typedef function pointer then function');
}

# enum + switch over it
{
	my $input = <<'END';
enum State {
STATE_IDLE,
STATE_RUNNING,
STATE_DONE
};

int handle(enum State s) {
switch (s) {
case STATE_IDLE:
return 0;
case STATE_RUNNING:
return 1;
default:
return -1;
}
}
END

	my $expected = <<'END';
enum State {
	STATE_IDLE,
	STATE_RUNNING,
	STATE_DONE
};

int handle(enum State s) {
	switch (s) {
		case STATE_IDLE:
		return 0;
		case STATE_RUNNING:
		return 1;
		default:
		return -1;
	}
}
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'enum declaration followed by switch over it');
}
