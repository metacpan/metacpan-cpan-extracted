use Test2::V0;

use IPC::Manager::Base::FS::Handle;

# Minimal mock subclass that never touches the filesystem.
# We bypass the real init chain entirely and set only the hash fields
# that pending_messages / ready_messages inspect.
{
    package Test::FSHandle;
    use parent -norequire, 'IPC::Manager::Base::FS::Handle';

    my $fill_result = 0;

    sub set_fill_result { $fill_result = $_[1] }

    sub new {
        my ($class, %args) = @_;
        return bless {
            pid            => $args{pid} // $$,
            buffer         => $args{buffer} // [],
            _has_resume    => $args{has_resume} // 0,
            disconnected   => 0,
        }, $class;
    }

    sub can_select       { 0 }
    sub have_resume_file { $_[0]->{_has_resume} }
    sub fill_buffer      { $fill_result }
    sub pid_check        { die "Client used from wrong PID" if $_[0]->{pid} != $$; $_[0] }

    # Stubs so disconnect/DESTROY don't touch disk
    sub disconnect       { $_[0]->{disconnected} = 1 }
    sub DESTROY          { }
}

subtest 'fill_buffer croaks in base class' => sub {
    like(
        dies { IPC::Manager::Base::FS::Handle->fill_buffer },
        qr/Not Implemented/,
        "fill_buffer croaks",
    );
};

subtest 'inherits from Base::FS' => sub {
    isa_ok('IPC::Manager::Base::FS::Handle', ['IPC::Manager::Base::FS']);
};

subtest 'Test::FSHandle inherits from Base::FS::Handle' => sub {
    isa_ok('Test::FSHandle', ['IPC::Manager::Base::FS::Handle']);
};

# --- pending_messages ---

subtest 'pending_messages returns 0 when empty' => sub {
    my $con = Test::FSHandle->new;
    Test::FSHandle->set_fill_result(0);
    ok(!$con->pending_messages, "no pending messages on fresh client");
};

subtest 'pending_messages returns 1 when buffer has items' => sub {
    my $con = Test::FSHandle->new(buffer => ['anything']);
    ok($con->pending_messages, "pending when buffer is non-empty");
};

subtest 'pending_messages returns 1 when resume file exists' => sub {
    my $con = Test::FSHandle->new(has_resume => 1);
    ok($con->pending_messages, "pending when resume file exists");
};

subtest 'pending_messages returns 1 when fill_buffer succeeds' => sub {
    my $con = Test::FSHandle->new;
    Test::FSHandle->set_fill_result(1);
    ok($con->pending_messages, "pending when fill_buffer returns true");
    Test::FSHandle->set_fill_result(0);
};

subtest 'pending_messages returns 0 when fill_buffer fails' => sub {
    my $con = Test::FSHandle->new;
    Test::FSHandle->set_fill_result(0);
    ok(!$con->pending_messages, "not pending when fill_buffer returns false");
};

subtest 'pending_messages checks pid' => sub {
    my $con = Test::FSHandle->new(pid => $$ + 99999);
    like(dies { $con->pending_messages }, qr/wrong PID/, "pending_messages checks pid");
};

# --- ready_messages ---

subtest 'ready_messages returns 0 when empty' => sub {
    my $con = Test::FSHandle->new;
    Test::FSHandle->set_fill_result(0);
    ok(!$con->ready_messages, "no ready messages on fresh client");
};

subtest 'ready_messages returns 1 when buffer has items' => sub {
    my $con = Test::FSHandle->new(buffer => ['anything']);
    ok($con->ready_messages, "ready when buffer is non-empty");
};

subtest 'ready_messages returns 1 when resume file exists' => sub {
    my $con = Test::FSHandle->new(has_resume => 1);
    ok($con->ready_messages, "ready when resume file exists");
};

subtest 'ready_messages returns 1 when fill_buffer succeeds' => sub {
    my $con = Test::FSHandle->new;
    Test::FSHandle->set_fill_result(1);
    ok($con->ready_messages, "ready when fill_buffer returns true");
    Test::FSHandle->set_fill_result(0);
};

subtest 'ready_messages returns 0 when fill_buffer fails' => sub {
    my $con = Test::FSHandle->new;
    Test::FSHandle->set_fill_result(0);
    ok(!$con->ready_messages, "not ready when fill_buffer returns false");
};

subtest 'ready_messages checks pid' => sub {
    my $con = Test::FSHandle->new(pid => $$ + 99999);
    like(dies { $con->ready_messages }, qr/wrong PID/, "ready_messages checks pid");
};

# --- interaction between the two ---

subtest 'ready_messages calls fill_buffer only when pending' => sub {
    # fill_buffer returns false → pending is false → ready short-circuits
    my $con = Test::FSHandle->new;
    Test::FSHandle->set_fill_result(0);
    ok(!$con->ready_messages, "not ready when nothing pending");

    # fill_buffer returns true → pending is true → ready calls fill_buffer again → true
    Test::FSHandle->set_fill_result(1);
    ok($con->ready_messages, "ready when fill_buffer says yes");
    Test::FSHandle->set_fill_result(0);
};

subtest 'resume file takes priority over fill_buffer' => sub {
    my $con = Test::FSHandle->new(has_resume => 1);
    Test::FSHandle->set_fill_result(0);
    ok($con->pending_messages, "pending due to resume file even if fill_buffer is false");
    ok($con->ready_messages, "ready due to resume file even if fill_buffer is false");
};

subtest 'buffer takes priority over fill_buffer' => sub {
    my $con = Test::FSHandle->new(buffer => ['x']);
    Test::FSHandle->set_fill_result(0);
    ok($con->pending_messages, "pending due to buffer even if fill_buffer is false");
    ok($con->ready_messages, "ready due to buffer even if fill_buffer is false");
};

done_testing;
