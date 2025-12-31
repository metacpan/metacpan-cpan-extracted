use strict;
use warnings;
use Test::More;
use Getopt::EX::Config;
use Hash::Util qw(lock_keys);

# Test lock_keys compatibility
# Internal keys (_argv, _configure) should be pre-initialized
# so that lock_keys doesn't block deal_with/configure methods

# Test that deal_with works after lock_keys
{
    my $config = Getopt::EX::Config->new(
        width => 0,
        name  => "test",
    );
    lock_keys %{$config};

    my @argv = qw(--width -- other args);
    ok eval {
        $config->deal_with(\@argv, "width!", "name=s");
        1;
    }, 'deal_with works after lock_keys';

    ok($config->{width}, 'width set via --width');
    is($config->{name}, 'test', 'name unchanged');
}

# Test that configure works after lock_keys
{
    my $config = Getopt::EX::Config->new(
        foo => 0,
    );
    lock_keys %{$config};

    ok eval {
        $config->configure('pass_through');
        1;
    }, 'configure works after lock_keys';
}

# Test that configure + deal_with chain works after lock_keys
{
    my $config = Getopt::EX::Config->new(
        bar => 0,
    );
    lock_keys %{$config};

    my @argv = qw(--bar --unknown -- rest);
    ok eval {
        $config->configure('pass_through')->deal_with(\@argv, "bar!");
        1;
    }, 'configure + deal_with chain works after lock_keys';

    ok($config->{bar}, 'bar set via --bar');
}

# Test that argv method works after lock_keys + deal_with
{
    my $config = Getopt::EX::Config->new(
        opt => 0,
    );
    lock_keys %{$config};

    my @argv = qw(--opt --extra value -- rest);
    $config->configure('pass_through')->deal_with(\@argv, "opt!");

    my @remaining = $config->argv;
    is_deeply(\@remaining, [qw(--extra value)], 'argv returns remaining options');
}

# Test that internal keys exist after new
{
    my $config = Getopt::EX::Config->new(
        test => 1,
    );

    ok(exists $config->{_argv}, '_argv key exists after new');
    ok(exists $config->{_configure}, '_configure key exists after new');
    is_deeply($config->{_argv}, [], '_argv initialized as empty array');
    is_deeply($config->{_configure}, [], '_configure initialized as empty array');
}

done_testing();
