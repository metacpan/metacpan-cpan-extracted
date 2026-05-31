use strict;
use warnings;
use Test::More;


# Test Hypersonic::Event module
use_ok('Hypersonic::Event');

# Test backend registry
subtest 'Backend registry' => sub {
    my @backends = Hypersonic::Event->available_backends;
    ok(scalar @backends >= 1, 'At least one backend available');

    # Check that common backends are in the list
    my %available = map { $_ => 1 } @backends;

    # poll and select should always be available (poll absent on native Win32)
    if ($^O eq 'MSWin32') {
        ok($available{select}, 'select backend registered (Win32)');
    } else {
        ok($available{poll}, 'poll backend registered');
        ok($available{select}, 'select backend registered');
    }

    note("Available backends: @backends");
};

# Test best_backend selection
subtest 'best_backend selection' => sub {
    my $best = Hypersonic::Event->best_backend;
    ok($best, "best_backend returned: $best");

    # Verify it's a valid backend name
    my @backends = Hypersonic::Event->available_backends;
    my %available = map { $_ => 1 } @backends;
    ok($available{$best}, "best_backend '$best' is in available list");

    # Platform-specific checks
    if ($^O eq 'darwin') {
        is($best, 'kqueue', 'macOS uses kqueue as best backend');
    } elsif ($^O eq 'linux') {
        like($best, qr/^(epoll|io_uring)$/, 'Linux uses epoll or io_uring');
    } elsif ($^O =~ /^(freebsd|openbsd|netbsd)$/) {
        is($best, 'kqueue', 'BSD uses kqueue as best backend');
    } elsif ($^O eq 'MSWin32') {
        like($best, qr/^(iocp|select)$/, 'Win32 uses iocp or select');
    }
};

# Test backend loading
subtest 'backend() loading' => sub {
    # Load the best backend
    my $backend_class = Hypersonic::Event->backend;
    ok($backend_class, "backend() returned class: $backend_class");
    like($backend_class, qr/^Hypersonic::Event::/, 'Backend class is in correct namespace');

    # Verify it can be used
    can_ok($backend_class, qw(name available includes defines event_struct));
    can_ok($backend_class, qw(gen_create gen_add gen_del gen_wait gen_get_fd));
};

# Test loading specific backends
subtest 'Load specific backends' => sub {
    my @always = $^O eq 'MSWin32' ? ('select') : ('poll', 'select');
    for my $name (@always) {
        my $class = Hypersonic::Event->backend($name);
        ok($class, "Loaded $name backend: $class");
        is($class->name, $name, "$name backend returns correct name");
        ok($class->available, "$name backend is available");
    }

    # Test platform-specific backends
    if ($^O eq 'darwin' || $^O =~ /bsd$/) {
        my $class = Hypersonic::Event->backend('kqueue');
        ok($class, "Loaded kqueue backend");
        is($class->name, 'kqueue', 'kqueue returns correct name');
    }

    if ($^O eq 'linux') {
        my $class = Hypersonic::Event->backend('epoll');
        ok($class, "Loaded epoll backend");
        is($class->name, 'epoll', 'epoll returns correct name');
    }
};

# Test invalid backend
subtest 'Invalid backend handling' => sub {
    eval { Hypersonic::Event->backend('nonexistent') };
    like($@, qr/Unknown event backend|not available/i, 'Invalid backend throws error');
};

# Test _can_link utility method
subtest '_can_link library verification' => sub {
    require Hypersonic::Event::Role;

    # Test with standard C library (should always work)
    my $can_link_libc = Hypersonic::Event::Role->_can_link('', 'strlen', '#include <string.h>');
    ok($can_link_libc, '_can_link works with libc strlen');

    # Test with a library that definitely doesn't exist
    my $cant_link = Hypersonic::Event::Role->_can_link('-lnonexistent_library_xyz123', 'fake_symbol');
    ok(!$cant_link, '_can_link returns false for nonexistent library');

    # Test with math library (should work on most Unix)
    SKIP: {
        skip 'math library test not reliable on all platforms', 1 if $^O eq 'MSWin32';
        my $can_link_math = Hypersonic::Event::Role->_can_link('-lm', 'sin', '#include <math.h>');
        ok($can_link_math, '_can_link works with libm sin');
    }
};

# Test backend priority order
subtest 'Backend priority' => sub {
    my @priority = Hypersonic::Event->backend_priority;
    ok(scalar @priority >= 4, 'At least 4 backends in priority list');

    # Verify poll and select are low priority (fallbacks)
    my %pos;
    for my $i (0 .. $#priority) {
        $pos{$priority[$i]} = $i;
    }

    ok($pos{poll} > $pos{kqueue} || !exists $pos{kqueue},
       'poll is lower priority than kqueue (or kqueue not available)');
    ok($pos{select} >= $pos{poll},
       'select is same or lower priority than poll');
};

done_testing();
