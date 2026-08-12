use strict;
use warnings;
use Config;
use Test::More;

BEGIN {
    plan skip_all => 'perl not built with ithreads' unless $Config{useithreads};
}

use threads;
use JSON::YY qw(encode_json decode_json decode_json_ro);
use JSON::YY ':doc';

# perl_clone() copies mg_ptr verbatim, so without an svt_dup a live handle was
# owned by two interpreters and freed twice. sv_magicext() does not set MGf_DUP
# from the vtable either, so it has to be set explicitly -- these catch both.

# --- coder objects are copied and stay usable on both sides ---
{
    my $coder = JSON::YY->new(utf8 => 1);
    my $from_child = threads->create(sub { $coder->encode({ n => 1 }) })->join;
    is $from_child, '{"n":1}', 'cloned coder works in the child';
    is $coder->encode({ n => 2 }), '{"n":2}', 'original coder still works';

    # settings must survive the copy, not just the pointer
    my $pretty = JSON::YY->new(utf8 => 1, pretty => 1);
    my $out = threads->create(sub { $pretty->encode({ a => 1 }) })->join;
    like $out, qr/\n/, 'cloned coder kept its flags';
}

# --- functional API needs no state at all ---
{
    my $r = threads->create(sub { encode_json([1, 2, 3]) })->join;
    is $r, '[1,2,3]', 'encode_json in a thread';
    my $d = threads->create(sub { decode_json('{"k":"v"}') })->join;
    is_deeply $d, { k => 'v' }, 'decode_json in a thread';
}

# --- documents: parent keeps working, the clone refuses rather than crashes ---
{
    my $doc = jdoc '{"a":1,"b":[2,3]}';
    my $child = threads->create(sub { eval { "$doc" } ? 'used it' : $@ })->join;
    like $child, qr/cannot be shared between threads/,
        'cloned Doc croaks instead of touching the original document';
    is "$doc", '{"a":1,"b":[2,3]}', 'original Doc survives the clone';
    is +(jgetp $doc, "/b/1"), 3, 'original Doc is still readable';

    # a borrowed subtree holds an SV owned by the other interpreter
    my $sub = jget $doc, "/b";
    my $c2 = threads->create(sub { eval { "$sub" } ? 'used it' : $@ })->join;
    like $c2, qr/cannot be shared between threads/, 'cloned borrowed Doc croaks';
    is "$sub", '[2,3]', 'original borrowed Doc survives';
}

# --- iterators ---
{
    my $doc = jdoc '[1,2,3]';
    my $it  = jiter $doc, "";
    my $child = threads->create(sub { eval { jnext $it } ? 'used it' : $@ })->join;
    like $child, qr/cannot be shared between threads/, 'cloned iterator croaks';
    my @got;
    while (defined(my $v = jnext $it)) { push @got, jgetp $v, "" }
    is_deeply \@got, [1, 2, 3], 'original iterator still walks the array';
}

# --- decode_json_ro: strings point into the parse buffer, which is shared
#     with the clone, so the buffer must outlive both sides ---
{
    my $ro = decode_json_ro '{"s":"hello world","n":[1,2],"deep":{"x":"yz"}}';
    my $child = threads->create(sub { "$ro->{s}|$ro->{deep}{x}|$ro->{n}[1]" })->join;
    is $child, 'hello world|yz|2', 'cloned readonly structure reads correctly';
    is $ro->{s}, 'hello world', 'original readonly structure intact';
}
{
    # the parent drops its reference first: the child's copy must still be
    # backed by a live buffer
    my $ro = decode_json_ro '{"s":"still here","t":"and here"}';
    my $thr = threads->create(sub { my @v = ($ro->{s}, $ro->{t}); join '|', @v });
    undef $ro;
    is $thr->join, 'still here|and here',
        'readonly buffer outlives the interpreter that parsed it';
}

# --- many threads at once, exercising the refcount from several sides ---
{
    my $ro = decode_json_ro '{"v":"shared buffer contents"}';
    my @t = map { threads->create(sub { $ro->{v} }) } 1 .. 8;
    my @r = map { $_->join } @t;
    is_deeply \@r, [ ('shared buffer contents') x 8 ], '8 concurrent readers';
}

done_testing;
