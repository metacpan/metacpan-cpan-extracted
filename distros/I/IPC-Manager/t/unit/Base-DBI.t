use Test2::V0;
use Test2::Require::Module 'DBI' => '1.644';

use IPC::Manager::Base::DBI;

subtest 'abstract methods croak' => sub {
    for my $method (qw/dsn table_sql/) {
        like(
            dies { IPC::Manager::Base::DBI->$method },
            qr/Not Implemented/,
            "$method croaks in base class",
        );
    }
};

subtest 'escape defaults to empty string' => sub {
    is(IPC::Manager::Base::DBI->escape, '', "escape is empty by default");
};

subtest 'default_attrs returns nothing' => sub {
    ok(!defined IPC::Manager::Base::DBI->default_attrs, "default_attrs returns undef");
};

subtest 'pending_messages returns 0' => sub {
    is(IPC::Manager::Base::DBI->pending_messages, 0, "pending_messages always 0");
};

done_testing;
