use Test2::V0;

use Role::Tiny ();

subtest 'role requires select_handles' => sub {
    my $err;
    {
        local $@;
        eval q{
            package TestSelect::Bad;
            use Role::Tiny::With;
            with 'IPC::Manager::Role::Service::Select';
            1;
        };
        $err = $@;
    }
    like($err, qr/select_handles/, "role requires select_handles");
};

subtest 'select with no handles returns undef' => sub {
    {
        package TestSelect::Empty;
        use Role::Tiny::With;
        sub select_handles { () }
        with 'IPC::Manager::Role::Service::Select';
        sub new { bless {}, shift }
    }

    my $obj = TestSelect::Empty->new;
    my $sel = $obj->select;
    is($sel, undef, "select returns undef when no handles");
};

subtest 'select with handles returns IO::Select' => sub {
    {
        package TestSelect::WithHandles;
        use Role::Tiny::With;

        sub select_handles {
            # Create a simple pipe to have a valid handle
            pipe(my $rh, my $wh) or die "pipe: $!";
            return $rh;
        }
        with 'IPC::Manager::Role::Service::Select';
        sub new { bless {}, shift }
    }

    my $obj = TestSelect::WithHandles->new;
    my $sel = $obj->select;
    isa_ok($sel, ['IO::Select'], "select returns IO::Select");

    # Second call returns cached
    my $sel2 = $obj->select;
    is($sel, $sel2, "cached select object");
};

subtest 'clear_serviceselect_fields' => sub {
    my $obj = TestSelect::WithHandles->new;
    $obj->select; # populate cache
    $obj->clear_serviceselect_fields;
    ok(!exists $obj->{_SELECT}, "cache cleared");
};

done_testing;
