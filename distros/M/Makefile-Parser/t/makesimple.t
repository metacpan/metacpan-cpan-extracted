my $reason;
BEGIN {
    my $line = (split /\n/, `make -v`)[0];
    if ($line) {
        warn $line, "\n";
        if ($line =~ /GNU Make (\d+\.\d+)(\s+(?:alpha|beta))?/) {
            my ($make_ver, $modifier) = ($1, $2);
            if ($make_ver < 3.81 || ($make_ver == 3.81 && $modifier)) {
                $reason = 'GNU make too old (at least 3.81 final is required).';
            }
        } else {
            $reason = 'No GNU make found.';
        }
    } else {
        $reason = 'No make found in env.';
    }
}

use Test::Base $reason ? (skip_all => $reason) : ();

use File::Slurp;
use IPC::Run3;
use Cwd;

use lib 't/lib';
use Test::Make::Util;
#use Test::LongString;

plan tests => 3 * blocks();

my $makefile = 'makesimple.tmp.mk';

my $saved_cwd = cwd;

run {
    my $block = shift;
    my $name = $block->name;
    chdir $saved_cwd;
    system('rm -rf t/tmp');
    system('mkdir t/tmp');
    chdir 't/tmp';
    write_file($makefile, $block->in);
    my ($stdout, $stderr, @options);
    if ($block->options) {
        @options = split /\s+/, $block->options;
    }
    my $touch = $block->touch;
    if ($touch) {
        for my $file (split /\s+/, $touch) {
            touch($file);
        }
    }
    run3(
        [$^X, "$saved_cwd/script/makesimple", '-f', $makefile, @options],
        undef,
        \$stdout,
        \$stderr,
    );
    is(($? >> 8), 0, "$name - process returned the 0 status");

    my $expected_out = $block->out;

    if (ref $expected_out && ref $expected_out eq 'Regexp') {
        like $stdout, $block->out,
            "$name - script/makesimple generated the right output";

    } else {
        is $stdout, $block->out,
            "$name - script/makesimple generated the right output";
    }

    is $stderr, $block->err,
        "$name - script/makesimple generated the right error";
};

__DATA__

=== TEST 1: basics
--- in

FOO = world
all: ; @ echo hello $(FOO)

--- out
all:
	@echo hello world
--- err



=== TEST 2: canned sequence of commands
--- in
define FOO
  @echo
  -touch
  :
endef

all:
	@$(FOO)
--- out
all:
	@echo
	@-touch
	@:
--- err



=== TEST 3: double-colon rules
--- in

all: foo

foo:: bar
	@echo $@ $<

foo:: blah blue
	-echo $^
--- out
all: foo

foo:: bar
	@echo foo bar

foo:: blah blue
	-echo blah blue

--- err
makesimple: *** No rule to make target `bar', needed by `foo'.  Ignored.
makesimple: *** No rule to make target `blah', needed by `foo'.  Ignored.
makesimple: *** No rule to make target `blue', needed by `foo'.  Ignored.



=== TEST 4: double-colon rules (no warnings)
--- in

all: foo

foo:: bar
	@echo $@ $<

foo:: blah blue
	-echo $^
--- out
all: foo

foo:: bar
	@echo foo bar

foo:: blah blue
	-echo blah blue

--- touch: bar blah blue
--- err



=== TEST 5: .DEFAUL_GOAL
--- in
.DEFAULT_GOAL = foo

all: foo
	@echo $<

foo: bah ; :


--- out
foo: bah
	:

all: foo
	@echo foo

--- err
makesimple: *** No rule to make target `bah', needed by `foo'.  Ignored.



=== TEST 6: order-only prereqs
--- in

all : a b \
    | c \
; echo

--- out
all: a b | c
	echo

--- err
makesimple: *** No rule to make target `a', needed by `all'.  Ignored.
makesimple: *** No rule to make target `b', needed by `all'.  Ignored.
makesimple: *** No rule to make target `c', needed by `all'.  Ignored.



=== TEST 7: multi-target rules
--- in
foo bar: a.h

foo: blah ; echo $< > $@

--- out
foo: blah a.h
	echo blah > foo

bar: a.h

--- err
makesimple: *** No rule to make target `blah', needed by `foo'.  Ignored.
makesimple: *** No rule to make target `a.h', needed by `foo'.  Ignored.



=== TEST 8: pattern rules (no match)
--- in
all: foo.x bar.w

%.x: %.h
	touch $@

%.w: %.hpp ; $(CC)

--- out
all: foo.x bar.w

--- err
makesimple: *** No rule to make target `foo.x', needed by `all'.  Ignored.
makesimple: *** No rule to make target `bar.w', needed by `all'.  Ignored.



=== TEST 9: pattern rules (no warnings)
--- in
all: foo.x bar.w

%.x: %.h
	touch $@

%.w: %.hpp ; $(CC)

--- touch: foo.x bar.w
--- out
all: foo.x bar.w

--- err



=== TEST 10: pattern rules (with match)
--- in
all: foo.x bar.w

%.x: %.h
	touch $@

%.w: %.hpp ; echo '$(CC)'

--- touch: foo.h bar.hpp
--- out
all: foo.x bar.w

foo.x: foo.h
	touch foo.x

bar.w: bar.hpp
	echo ''
--- err



=== TEST 11: chained implicit rules
--- in

all: foo.a bar.a baz.a

%.a: %.b ; @touch $@
%.b: %.d ; @touch $@

--- touch: foo.d bar.d baz.d
--- out
all: foo.a bar.a baz.a

foo.b: foo.d
	@touch foo.b

foo.a: foo.b
	@touch foo.a

bar.b: bar.d
	@touch bar.b

bar.a: bar.b
	@touch bar.a

baz.b: baz.d
	@touch baz.b

baz.a: baz.b
	@touch baz.a

--- err



=== TEST 12: extra goals given from the command line
--- in

all: foo.a

%.a: %.b ; @touch $@
%.b: %.d ; @touch $@

--- options: bar.a
--- touch: foo.d bar.d
--- out

all: foo.a

bar.b: bar.d
	@touch bar.b

bar.a: bar.b
	@touch bar.a

foo.b: foo.d
	@touch foo.b

foo.a: foo.b
	@touch foo.a

--- err



=== TEST 13: target-specific variables
--- in

FOO = foo
default: all any
all: FOO += one
all: FOO += two
all: BAR = bar
all: FOO += three
all: BAR += baz
all: ; @echo $(FOO); echo $(BAR)
any: ; @echo $(FOO); echo $(BAR) end

--- out
default: all any

all:
	@echo foo one two three; echo bar baz

any:
	@echo foo; echo  end

--- err



=== TEST 14: ditto (override cmd line vars)
--- in

all: override FOO = foo
all: ; @echo $(FOO)
--- options:  FOO=cmd
--- out
all:
	@echo foo
--- err



=== TEST 15: ditto (cmd line vars) (2)
--- in

all: FOO = foo
all: ; @echo $(FOO)
--- options:  FOO=cmd
--- out
all:
	@echo cmd
--- err



=== TEST 16: static pattern rules
--- in

CC = gcc
CFLAGS =
objects = foo.o bar.o

all: $(objects)

$(objects): %.o: %.c
	$(CC) -c $(CFLAGS) $< -o $@

--- out

all: foo.o bar.o

foo.o: foo.c
	gcc -c  foo.c -o foo.o

bar.o: bar.c
	gcc -c  bar.c -o bar.o

--- err
makesimple: *** No rule to make target `foo.c', needed by `foo.o'.  Ignored.
makesimple: *** No rule to make target `bar.c', needed by `bar.o'.  Ignored.



=== TEST 17: static pattern rules (no warnings)
--- in

CC = gcc
CFLAGS = -O
objects = foo.o bar.o

all: $(objects)

$(objects): %.o: %.c
	$(CC) -c $(CFLAGS) $< -o $@

--- touch: foo.c bar.c
--- out

all: foo.o bar.o

foo.o: foo.c
	gcc -c -O foo.c -o foo.o

bar.o: bar.c
	gcc -c -O bar.c -o bar.o

--- err



=== TEST 18: conditionals - ifdef $(foo)
--- in

bar = true
foo = bar
ifdef $(foo)
all: ; @echo hello
else
foo: bar
	touch $@
endif
	-rm blahblah

--- out

all:
	@echo hello
	-rm blahblah

--- err



=== TEST 19: conditionals - ifdef foo
--- in

foo = bar
ifdef foo
all: ; @echo hello
else
foo: bar
	touch $@
endif
	-rm blahblah

--- out

all:
	@echo hello
	-rm blahblah

--- err



=== TEST 20: conditionals - override var foo via cmd line options
--- in

foo = bar
ifdef foo
all: ; @echo hello
else
foo: bar
	touch $@
endif
	-rm blahblah

--- options: foo=
--- out

foo: bar
	touch foo
	-rm blahblah

--- err
makesimple: *** No rule to make target `bar', needed by `foo'.  Ignored.



=== TEST 21: functions in the first pass
--- in

objects = foo.o bar.o baz.o
all : $(objects:.o=.c)
	@ echo $^

--- out
all: foo.c bar.c baz.c
	@echo foo.c bar.c baz.c
--- err
makesimple: *** No rule to make target `foo.c', needed by `all'.  Ignored.
makesimple: *** No rule to make target `bar.c', needed by `all'.  Ignored.
makesimple: *** No rule to make target `baz.c', needed by `all'.  Ignored.



=== TEST 22: functions in the second pass
--- in

objects = foo.o bar.o baz.o
all :
	echo $(patsubst %.o,%.c,${objects})

--- out
all:
	echo foo.c bar.c baz.c
--- err



=== TEST 23: functions in the both passes
--- in

objects = $(sort $(wildcard *.o))
all : ; echo $(patsubst %.o,%.c,${objects})

--- touch: foo.o bar.o baz.o
--- out
all:
	echo bar.c baz.c foo.c
--- err



=== TEST 24: commands spanning multiple lines
--- in

foo=hello
bar=my
baz=world

all:
	@echo $(foo) \
  $(bar) \
      $(baz)

--- out eval
qr/^all:
\t\@echo hello \\
[ \t]+my \\
[ \t]+world
$/s
--- err



=== TEST 25: dynamics
--- in

head = all:
$(head)
	@echo $@

--- out
all:
	@echo all
--- err



=== TEST 26: dynamics (2)
--- in

head = all:
$(head)
	@echo $@

--- options: head=all:bar
--- out
all: bar
	@echo all
--- err
makesimple: *** No rule to make target `bar', needed by `all'.  Ignored.



=== TEST 27: ifeq/endif
--- in
FOO=123
ifeq ($(FOO), 123)
    FOO = bar
endif

all: ; echo $(FOO)
--- out
all:
	echo bar
--- err



=== TEST 28: define/endef
--- in
define foo =

     bar 
 
endef

all: ; echo $(foo)
--- out
all:
	echo bar
--- err

