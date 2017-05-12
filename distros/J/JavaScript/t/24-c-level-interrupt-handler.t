#!perl

package JavaScript::Runtime::Opcounted;

use Test::More;
use Test::Exception;

use File::Spec;
use JavaScript;

use strict;
use warnings;

BEGIN {
    eval "require Inline::C";
    plan skip_all => "Inline::C is required for testing C-level trap handlers" if $@;
}

my $typemap = File::Spec->catfile($ENV{PWD}, 'typemap');
my $inc = do {
    my @inc_paths = $ENV{PWD};
    if (exists $ENV{JS_INC}) {
        my $sep = $^O eq 'Win32' ? ';' : ':';
        push @inc_paths, split/$sep/, $ENV{JS_INC};
    }
    join(" ", map { "-I$_"} @inc_paths);
};

use Inline Config => FORCE_BUILD => 1;

Inline->bind('C' => <<'END_OF_CODE', TYPEMAPS => $typemap, INC => $inc, AUTO_INCLUDE => '#include "JavaScript.h"');

struct Opcount {
    int cnt;
    int limit;
};

typedef struct Opcount Opcount;

static JSTrapStatus Opcount_trap_handler(JSContext *cx, JSScript *script, jsbytecode *pc, jsval *rval, void *data) {
    Opcount * opcnt = (Opcount *) data;
    opcnt->cnt++;
    if ( opcnt->limit != 0 && opcnt->cnt > opcnt->limit ) {
        sv_setsv(ERRSV, newSVpv("opcount limit exceeded", 0));
        return JSTRAP_ERROR;
    }
    
    return JSTRAP_CONTINUE;
}

PJS_TrapHandler * 
_init_interrupt_handler() {
    PJS_TrapHandler *handler;
    Opcount *opcnt;
    
    Newz(1, handler, 1, PJS_TrapHandler);
    Newz(1, opcnt, 1, Opcount);
    
    opcnt->cnt = 0;
    opcnt->limit = 100;
    
    handler->handler = Opcount_trap_handler;
    handler->data = (void *) opcnt;

    return handler;
}

void _destroy_interrupt_handler(PJS_TrapHandler *handler) {
    Safefree(handler->data);
    Safefree(handler);
}

void _set_opcnt(PJS_TrapHandler *handler, int cnt) {
    ((Opcount *) handler->data)->cnt = cnt;
}

int _get_opcnt(PJS_TrapHandler *handler) {
    return ((Opcount *) handler->data)->cnt;
}

void _set_oplimit(PJS_TrapHandler *handler, int limit) {
    ((Opcount *) handler->data)->limit = limit;
}

int _get_oplimit(PJS_TrapHandler *handler) {
    return ((Opcount *) handler->data)->limit;
}
END_OF_CODE

sub _init {
    my $rt = shift;
    my $trap = _init_interrupt_handler();
    $rt->_add_interrupt_handler($trap);
    $rt->{_Opcounted} = $trap;
}

sub _destroy {
    my $rt = shift;
    $rt->_remove_interrupt_handler($rt->{_Opcounted});
    _destroy_interrupt_handler($rt->{_Opcounted});
}

sub oplimit {
    my $rt = shift;
    
    if (@_) {
        _set_oplimit($rt->{_Opcounted}, shift);
    }
    return _get_oplimit($rt->{_Opcounted});
}

sub opcnt {
    my $rt = shift;
    
    if (@_) {
        _set_opcnt($rt->{_Opcounted}, shift);
    }
    return _get_opcnt($rt->{_Opcounted});
}

plan tests => 8;

my $runtime = JavaScript::Runtime->new(qw(-Opcounted));
my $context = $runtime->create_context();

is($runtime->opcnt, 0, 'opcnt is 0');
is($runtime->oplimit, 100, 'oplimit is 100');

$context->eval("1+1");
isnt($runtime->opcnt, 0, "opcnt is > 0. Currently at: " . $runtime->opcnt);

$context->eval("for(v = 0; v < 100; v++) { 1 + 1; }");
ok($@, "Threw exception");
like($@, qr/exceeded/);

# Reset since we're going to try stacked
$runtime->opcnt(0);
$runtime->oplimit(0);

my $count = 0;
$runtime->set_interrupt_handler(sub { $count++; });
$context->eval("1 + 1;");
ok($runtime->opcnt, "Opcounter works");
ok($count, "Perl level works");

throws_ok {
    $runtime->foo();
} qr/Can't call method/;

1;

