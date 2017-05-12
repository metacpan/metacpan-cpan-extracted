use strict;
use warnings;
use Test::More;
use Future::Q;


note('--- all constructors should return Future::Q object.');

{
    my $f = new_ok('Future::Q');
    $f->done();
}

{
    my $f = new_ok('Future::Q');
    my $g = $f->new();
    isa_ok($g, 'Future::Q', '(obj)->new()');
    $f->done; $g->done;
}

{
    my $f = Future::Q->done();
    isa_ok($f, 'Future::Q', "Future::Q->done()");
}

{
    my $f = Future::Q->fail("hoge");
    isa_ok($f, 'Future::Q', "Future::Q->fail()");
    $f->catch(sub {});
}

{
    my $f = Future::Q->wrap("a", "b", "c");
    isa_ok($f, "Future::Q", "Future::Q->wrap(values)");
}

{
    my $f = Future::Q->wrap(Future::Q->new);
    isa_ok($f, "Future::Q", "Future::Q->wrap(Future::Q)");
}

{
    my $f = Future::Q->call(sub { Future::Q->new });
    isa_ok($f, "Future::Q", "Future::Q->call(sub returning Future::Q)");
}

{
    my $f = Future::Q->call(sub { die "error" });
    isa_ok($f, "Future::Q", "Future::Q->call(sub dying)");
    $f->catch(sub {});
}

foreach my $method (qw(followed_by then_with_f else_with_f else then then_done then_fail else_done else_fail)) {
    my $f = new_ok('Future::Q');
    my $g = $f->$method(sub {
        return Future->new->done()
    });
    isa_ok($g, 'Future::Q', "$method()");
}

{
    my $f = new_ok('Future::Q');
    my $g = $f->transform(done => sub { 1 }, fail => sub { 0 });
    isa_ok($g, 'Future::Q', 'transform()');
    $f->done;
}

foreach my $method (qw(wait_all wait_any needs_all needs_any)) {
    my @subf = map { Future::Q->new } (1..3);
    my $f = Future::Q->$method(@subf);
    isa_ok($f, 'Future::Q', "$method(some Future::Q)");

    
    SKIP:
    {
        skip "Future returns a plain Future if no argument is given to $method. See https://rt.cpan.org/Public/Bug/Display.html?id=97537", 1;
        my $empty_f = Future::Q->$method();
        isa_ok($empty_f, "Future::Q", "$method(empty)");
    }
}

done_testing();
