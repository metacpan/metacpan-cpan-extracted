use Test::More;
use Linux::IO_Prio qw(:all);
use POSIX qw(ENOSYS);

if( $^O eq 'linux' && Linux::IO_Prio::_load_syscall()) {
    plan tests => 5;	

    ok(ioprio_set(IOPRIO_WHO_PROCESS, $$, IOPRIO_PRIO_VALUE(IOPRIO_CLASS_IDLE, 0)) == 0);

    ok(ioprio_get(IOPRIO_WHO_PROCESS, $$) >= 0);

    ok(ionice(IOPRIO_WHO_PROCESS, $$, IOPRIO_CLASS_IDLE, 0) == 0);

    ok(ionice_class(IOPRIO_WHO_PROCESS, $$) == IOPRIO_CLASS_IDLE);

    ok(ionice_data(IOPRIO_WHO_PROCESS, $$) == 0);

}
else {
    plan tests => 10;

    ok(ioprio_set(IOPRIO_WHO_PROCESS, $$, IOPRIO_PRIO_VALUE(IOPRIO_CLASS_IDLE, 0)) == -1);
    ok($! == ENOSYS);

    ok(ioprio_get(IOPRIO_WHO_PROCESS, $$) == -1);
    ok($! == ENOSYS);

    ok(ionice(IOPRIO_WHO_PROCESS, $$, IOPRIO_CLASS_IDLE, 0) == -1);
    ok($! == ENOSYS);

    ok(ionice_class(IOPRIO_WHO_PROCESS, $$) == -1);
    ok($! == ENOSYS);

    ok(ionice_data(IOPRIO_WHO_PROCESS, $$) == -1);
    ok($! == ENOSYS);

};


