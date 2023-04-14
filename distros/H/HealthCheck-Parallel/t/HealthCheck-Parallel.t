use Test2::V0 -target => 'HealthCheck::Parallel',
    qw< ok is like diag note done_testing >;

diag(qq($CLASS Perl $], $^X));

ok CLASS, "Loaded $CLASS";

{
    note "Successful basic results";

    my $hc = HealthCheck::Parallel->new(
        checks => [
            sub { return { id => 'id1', status => 'OK' } },
            sub { return { id => 'id2', status => 'OK' } },
        ],
    );

    is $hc->check, {
        status  => 'OK',
        results => [
            { id => 'id1', status => 'OK' },
            { id => 'id2', status => 'OK' },
        ],
    }, 'Got expected results with parallelization.';

    is $hc->check( max_procs => 0 ), {
        status  => 'OK',
        results => [
            { id => 'id1', status => 'OK' },
            { id => 'id2', status => 'OK' },
        ],
    }, 'Got expected results with no parallelization.';
}

{
    note "child_init process exit error";

    my $hc = HealthCheck::Parallel->new(
        checks     => [ sub { return { id => 'wontrun', status => 'OK' } } ],
        child_init => sub { exit 222 },
    );

    is $hc->check, {
        status => 'CRITICAL',
        info   => 'Child process exited with code 222.',
    }, 'Got expected results with child_init process exit error.';
}

{
    note "check process exit error";

    my $hc = HealthCheck::Parallel->new(
        checks => [
            sub { exit 111 },
            sub { return { id => 'ok', status => 'OK' } },
        ],
    );

    is $hc->check, {
        status  => 'CRITICAL',
        results => [
            {
                info   => 'Child process exited with code 111.',
                status => 'CRITICAL',
            },
            {
                id     => 'ok',
                status => 'OK',
            },
        ],
    }, 'Got expected results with child process exit error.'
}

{
    note "Invalid max_procs";

    my $err = 'max_procs must be a zero or positive integer!';

    local $@;
    eval { HealthCheck::Parallel->new( max_procs => -1 ) };
    like $@, qr/^\Q$err\E/,
        'Threw expected exception for invalid max_procs constructor.';

    my $hc = HealthCheck::Parallel->new(
        checks => [ sub { return { id => 'wontrun', status => 'OK' } } ],
    );
    my $r = $hc->check( max_procs => -1 );
    like $r, {
        status => 'CRITICAL',
        info   => qr/^\Q$err\E/,
    }, 'Got expected result for invalid max_procs parameter.';
}

{
    note "Invalid child_init";

    my $err = 'child_init must be a code reference!';

    local $@;
    eval { HealthCheck::Parallel->new( child_init => ['nope'] ) };
    like $@, qr/^\Q$err\E/,
        'Threw expected exception for invalid child_init constructor.';

    my $hc = HealthCheck::Parallel->new(
        checks => [ sub { return { id => 'wontrun', status => 'OK' } } ],
    );
    my $r = $hc->check( child_init => { wont => 'work' } );
    like $r, {
        status => 'CRITICAL',
        info   => qr/^\Q$err\E/,
    }, 'Got expected result for invalid child_init parameter.';
}

done_testing;
