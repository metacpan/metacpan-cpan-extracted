use warnings;
use strict;

use Data::Dumper;
use IPC::Shareable;
use Test::More;

use FindBin;
use lib $FindBin::Bin;
use IPCShareableTest qw(assert_clean_process unique_glue);


my $glue = unique_glue('testing');
my $k = tie my $sv, 'IPC::Shareable', $glue, {create => 1, destroy => 1, serializer => 'storable' };

my $attrs_tied = (tied $sv)->attributes;
is ref $attrs_tied, 'HASH', "tied var attributes() returns a hash ref ok";

my $attrs = { %{ $k->attributes } };

$k->testing_set('IPC::Shareable');

is ref $attrs, 'HASH', "attributes() returns a hash ref ok";

my @attr_list = qw(
    warn
    exclusive
    key
    serializer
    size
    protected
    testing
    limit
    magic
    mode
    create
    owner
    graceful
    destroy
    enforced_write_locking
    enforced_read_locking
    violated_write_lock_warn
    violated_read_lock_warn
);

is keys %$attrs, scalar @attr_list, "attributes() hash has proper count of keys";

for (@attr_list) {
    is $k->attributes($_), $attrs->{$_}, "attributes($_) returns proper value ok";
}

is $attrs->{warn},      0, "warn is set ok";
is $attrs->{exclusive}, 0, "exclusive is set ok";
is $attrs->{key},       $glue, "key is set ok";
is $attrs->{serializer},'storable', "serializer is set ok";
is $attrs->{size},      65536, "size is set ok";
is $attrs->{protected}, 0, "protected is set ok";
is $attrs->{testing},   0, "testing is set ok";
is $attrs->{limit},     1, "limit is set ok";
is $attrs->{magic},     0, "magic is set ok";
is $attrs->{mode},      438, "mode is set ok";
is $attrs->{create},    1, "create is set ok";
is $attrs->{owner},     $$, "owner is set ok";
is $attrs->{graceful},  0, "graceful is set ok";
is $attrs->{enforced_write_locking},   1, "enforced_write_locking is set ok";
is $attrs->{enforced_read_locking},    1, "enforced_read_locking is set ok";
is $attrs->{violated_write_lock_warn}, 1, "violated_write_lock_warn is set ok";
is $attrs->{violated_read_lock_warn},  1, "violated_read_lock_warn is set ok";

is $k->attributes('no_exist'), undef, "attributes() on an undefined attr is undef";

# _parse_args: 'no' is a deprecated option value -- silently coerced to 0
{
    my $k2 = tie my $sv2, 'IPC::Shareable', {
        create  => 'no',
        destroy => 1,
            serializer => 'storable',
    };
    is $k2->attributes('create'), 0,
        "_parse_args: 'no' value coerced to 0 (no warnings flag)";
}

# _parse_args: 'no' with $^W true emits a carp warning
{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    my $k3;
    {
        local $^W = 1;
        $k3 = tie my $sv3, 'IPC::Shareable', {
            create  => 'no',
            destroy => 1,
                    serializer => 'storable',
        };
    }
    is $k3->attributes('create'), 0,
        "_parse_args: 'no' with \$^W=1 still coerces to 0";
    ok scalar(grep { /obsolete/ } @warnings),
        "_parse_args: 'no' with \$^W=1 emits obsolete-usage warning";
}

# Default serializer should now be 'json'
{
    my $kd = tie my $sv_def, 'IPC::Shareable', { create => 1, destroy => 1 };
    is $kd->attributes('serializer'), 'json', "default serializer is 'json'";
}

IPC::Shareable::_end;

assert_clean_process();

done_testing;
