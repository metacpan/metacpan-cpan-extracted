use Test2::V0;

use IPC::Manager::Message;

subtest 'construction with required fields' => sub {
    my $msg = IPC::Manager::Message->new(from => 'a', to => 'b', content => {hello => 'world'});
    isa_ok($msg, ['IPC::Manager::Message']);
    is($msg->from, 'a', "from");
    is($msg->to, 'b', "to");
    is($msg->content, {hello => 'world'}, "content");
    ok($msg->id, "id is auto-generated");
    ok($msg->stamp, "stamp is auto-generated");
};

subtest 'broadcast message' => sub {
    my $msg = IPC::Manager::Message->new(from => 'a', broadcast => 1, content => 'hi');
    ok($msg->broadcast, "broadcast is set");
    ok(!$msg->to, "no 'to' on broadcast");
};

subtest 'missing from' => sub {
    like(
        dies { IPC::Manager::Message->new(to => 'b', content => 'x') },
        qr/'from' is a required attribute/,
        "dies without from",
    );
};

subtest 'missing content' => sub {
    like(
        dies { IPC::Manager::Message->new(from => 'a', to => 'b') },
        qr/'content' is a required attribute/,
        "dies without content",
    );
};

subtest 'missing to and broadcast' => sub {
    like(
        dies { IPC::Manager::Message->new(from => 'a', content => 'x') },
        qr/must either have a 'to' or 'broadcast'/,
        "dies without to or broadcast",
    );
};

subtest 'is_terminate' => sub {
    my $term = IPC::Manager::Message->new(from => 'a', to => 'b', content => {terminate => 1});
    ok($term->is_terminate, "terminate message detected");

    my $not_term = IPC::Manager::Message->new(from => 'a', to => 'b', content => {foo => 1});
    ok(!$not_term->is_terminate, "non-terminate message");

    my $str = IPC::Manager::Message->new(from => 'a', to => 'b', content => 'just a string');
    ok(!$str->is_terminate, "string content is not terminate");
};

subtest 'TO_JSON' => sub {
    my $msg = IPC::Manager::Message->new(from => 'a', to => 'b', content => {x => 1});
    my $json = $msg->TO_JSON;
    is(ref($json), 'HASH', "TO_JSON returns hashref");
    is($json->{from}, 'a', "from preserved");
    is($json->{to}, 'b', "to preserved");
};

subtest 'clone' => sub {
    my $msg = IPC::Manager::Message->new(from => 'a', to => 'b', content => {x => 1});
    my $clone = $msg->clone(to => 'c');
    isnt($clone->id, $msg->id, "clone gets a new id");
    is($clone->from, 'a', "from preserved in clone");
    is($clone->to, 'c', "to overridden in clone");
    is($clone->content, {x => 1}, "content preserved in clone");
};

done_testing;
