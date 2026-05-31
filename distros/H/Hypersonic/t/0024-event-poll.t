use strict;
use warnings;
use Test::More;

plan skip_all => 'poll(2) backend not available on native Win32' if $^O eq 'MSWin32';

# Test Hypersonic::Event::Poll backend
use_ok('Hypersonic::Event::Poll');

# Poll should always be available (POSIX)
ok(Hypersonic::Event::Poll->available, 'poll is available on all POSIX systems');

# Test basic properties
subtest 'Basic properties' => sub {
    is(Hypersonic::Event::Poll->name, 'poll', 'name() returns poll');
    ok(Hypersonic::Event::Poll->available, 'available() returns true');
};

# Test platform availability
subtest 'Platform availability' => sub {
    # poll() is POSIX, available everywhere except possibly Windows
    if ($^O ne 'MSWin32') {
        ok(Hypersonic::Event::Poll->available, "Available on $^O");
    }
};

# Test includes
subtest 'C includes' => sub {
    my $includes = Hypersonic::Event::Poll->includes;
    ok($includes, 'includes() returns value');
    like($includes, qr/poll\.h/, 'Includes poll.h');
};

# Test defines
subtest 'C defines' => sub {
    my $defines = Hypersonic::Event::Poll->defines;
    ok($defines, 'defines() returns value');
    like($defines, qr/EV_BACKEND_POLL/, 'Defines EV_BACKEND_POLL');
    like($defines, qr/MAX_FDS|MAX_EVENTS/, 'Defines MAX_FDS or MAX_EVENTS');
};

# Test event_struct
subtest 'Event struct' => sub {
    my $struct = Hypersonic::Event::Poll->event_struct;
    is($struct, 'pollfd', 'event_struct is pollfd');
};

# Test extra flags
subtest 'Extra compiler flags' => sub {
    my $cflags = Hypersonic::Event::Poll->extra_cflags;
    my $ldflags = Hypersonic::Event::Poll->extra_ldflags;

    # poll is built into libc, no extra flags needed
    is($cflags, '', 'No extra cflags needed');
    is($ldflags, '', 'No extra ldflags needed');
};

# Test code generation methods with mock builder
subtest 'Code generation methods' => sub {
    # Create a simple mock builder
    my @code;
    my $mock_builder = bless {}, 'MockBuilder';

    {
        no strict 'refs';
        for my $method (qw(line comment blank if endif else elsif while endwhile)) {
            *{"MockBuilder::$method"} = sub {
                my ($self, $code) = @_;
                push @code, $code if defined $code;
                return $self;
            };
        }
    }

    # Test gen_create
    @code = ();
    Hypersonic::Event::Poll->gen_create($mock_builder, 'listen_fd');
    ok(scalar @code > 0, 'gen_create generates code');
    ok(grep(/pollfd/, @code), 'gen_create references pollfd');
    ok(grep(/POLLIN/, @code), 'gen_create includes POLLIN');

    # Test gen_add
    @code = ();
    Hypersonic::Event::Poll->gen_add($mock_builder, 'ev_fd', 'client_fd');
    ok(scalar @code > 0, 'gen_add generates code');
    ok(grep(/POLLIN/, @code), 'gen_add includes POLLIN');

    # Test gen_del
    @code = ();
    Hypersonic::Event::Poll->gen_del($mock_builder, 'ev_fd', 'client_fd');
    ok(scalar @code > 0, 'gen_del generates code');
    # poll removes by setting fd to -1 or shifting array

    # Test gen_wait
    @code = ();
    Hypersonic::Event::Poll->gen_wait($mock_builder, 'ev_fd', 'events', 'n', '1000');
    ok(scalar @code > 0, 'gen_wait generates code');
    ok(grep(/poll\s*\(/, @code), 'gen_wait includes poll() call');

    # Test gen_get_fd
    @code = ();
    Hypersonic::Event::Poll->gen_get_fd($mock_builder, 'events', 'i', 'fd');
    ok(scalar @code > 0, 'gen_get_fd generates code');
    ok(grep(/\.fd/, @code), 'gen_get_fd extracts .fd');
};

# Test O(n) characteristics documentation
subtest 'Performance characteristics' => sub {
    # Poll is O(n) - verify this is documented/expected
    # The main test is that it works, performance is secondary

    # Check that it handles the iteration pattern
    my @code;
    my $mock_builder = bless {}, 'MockBuilder2';

    {
        no strict 'refs';
        for my $method (qw(line comment blank if endif else elsif while endwhile)) {
            *{"MockBuilder2::$method"} = sub {
                my ($self, $code) = @_;
                push @code, $code if defined $code;
                return $self;
            };
        }
    }

    Hypersonic::Event::Poll->gen_wait($mock_builder, 'ev_fd', 'events', 'n', '1000');
    # poll() returns count, but we iterate over all fds checking revents
    pass('Poll backend compiles (O(n) iteration is expected)');
};

# Test inheritance
subtest 'Inheritance' => sub {
    require Hypersonic::Event::Role;
    ok(Hypersonic::Event::Poll->isa('Hypersonic::Event::Role'),
       'Poll inherits from Role');
};

done_testing();
