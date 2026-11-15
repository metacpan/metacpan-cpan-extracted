use strict;
use warnings;
use Test::More;
use Scalar::Util qw(blessed refaddr);
use HTTP::API::Core;
use HTTP::API::Core::Error;

# A legitimate subclass can have a false-valued name.  The class-name
# checks must use definedness rather than boolean truthiness.
{
    no strict 'refs';
    @{'0::ISA'} = ('HTTP::API::Core::Error');
}

my $original = bless HTTP::API::Core::Error->new(
    category  => 'transport',
    message   => 'structured failure from class zero',
    retryable => 0,
), '0';

is blessed($original), '0', 'test error has a false-valued package name';
ok $original->isa('HTTP::API::Core::Error'), 'test error is a core Error subclass';

{
    my $api = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        retry => { attempts => 1 },
        transport => sub { die $original },
    );

    my $caught;
    eval { $api->get('/transport'); 1 } or $caught = $@;

    is refaddr($caught), refaddr($original),
        'transport preserves the same false-valued Error subclass instance';
    is ref($caught), '0', 'transport keeps the original subclass';
}

{
    my $api = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        retry => { attempts => 1 },
        hooks => { before_request => sub { die $original } },
        transport => sub { die 'transport must not run' },
    );

    my $caught;
    eval { $api->get('/hook'); 1 } or $caught = $@;

    is refaddr($caught), refaddr($original),
        'hook preserves the same false-valued Error subclass instance';
    is ref($caught), '0', 'hook keeps the original subclass';
}

done_testing;
