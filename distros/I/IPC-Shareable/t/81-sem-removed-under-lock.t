use warnings;
use strict;

use Errno qw(EINVAL);
use IPC::Shareable;
IPC::Shareable->testing_set('IPC::Shareable');
use IPC::Semaphore;
use Test::More;

use FindBin;
use lib $FindBin::Bin;
use IPCShareableTest qw(assert_clean_process unique_glue);

# Regression: when another process removes a segment's semaphore set, this
# process's subsequent semaphore calls fail with EINVAL -- getval() returns
# undef and op() returns false. The module must degrade gracefully rather than
# emit 'uninitialized value' warnings (the CPAN-tester symptom) or croak. This
# covers _write_permitted() and unlock(). The failing semaphore is simulated
# with a localized override of IPC::Semaphore, so the real IPC resources still
# clean up normally afterwards.

# --- _write_permitted() tolerates getval() returning undef ----------------
{
    my $knot = tie my %h, 'IPC::Shareable', unique_glue('semgone_w'), {
        create     => 1,
        destroy    => 1,
        serializer => 'storable',
    };

    my @warnings;
    my $permitted;

    {
        no warnings 'redefine';
        local *IPC::Semaphore::getval = sub { return undef };
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };

        $permitted = IPC::Shareable::_write_permitted($knot);
    }

    is $permitted, 1,
        "_write_permitted() permits the write when getval() returns undef";

    is scalar(grep { /uninitialized value/i } @warnings), 0,
        "_write_permitted() emits no 'uninitialized value' warning on a removed set"
        or diag "got warnings: @warnings";

    IPC::Shareable->clean_up_all;
}

# --- unlock() warns once, non-fatally, when op() fails with EINVAL ---------
{
    my $knot = tie my %h, 'IPC::Shareable', unique_glue('semgone_u'), {
        create     => 1,
        destroy    => 1,
        serializer => 'storable',
    };

    $knot->shlock;   # hold a lock so unlock() issues a release semop

    my @warnings;
    my $survived;

    {
        no warnings 'redefine';
        local *IPC::Semaphore::op = sub { $! = EINVAL; return 0 };
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };

        $survived = eval { $knot->shunlock; 1 };
    }

    is $survived, 1, "shunlock() does not die when the semaphore set is gone";

    is scalar(grep { /removed by another process/i } @warnings), 1,
        "shunlock() warns (once) that the set was removed by another process"
        or diag "got warnings: @warnings";

    IPC::Shareable->clean_up_all;
}

IPC::Shareable::_end;

assert_clean_process();

done_testing();
