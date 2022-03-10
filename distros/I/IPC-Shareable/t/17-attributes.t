use warnings;
use strict;

use Data::Dumper;
use IPC::Shareable;
use Test::More;

BEGIN {
    if (! $ENV{CI_TESTING}) {
        plan skip_all => "Not on a legit CI platform...";
    }
}

warn "Segs Before: " . IPC::Shareable::ipcs() . "\n" if $ENV{PRINT_SEGS};

my $k = tie my $sv, 'IPC::Shareable', 'testing', {create => 1, destroy => 1};

my $attrs_tied = (tied $sv)->attributes;
is ref $attrs_tied, 'HASH', "tied var attributes() returns a hash ref ok";

my $attrs = $k->attributes;

is ref $attrs, 'HASH', "attributes() returns a hash ref ok";

my @attr_list = qw(
    warn
    exclusive
    key
    serializer
    size
    protected
    limit
    magic
    mode
    create
    owner
    graceful
    tidy
    destroy
);

is keys %$attrs, scalar @attr_list, "attributes() hash has proper count of keys";

for (@attr_list) {
    is $k->attributes($_), $attrs->{$_}, "attributes($_) returns proper value ok";
}

is $attrs->{warn},      0, "warn is set ok";
is $attrs->{exclusive}, 0, "exclusive is set ok";
is $attrs->{key},       'testing', "key is set ok";
is $attrs->{serializer},'storable', "serializer is set ok";
is $attrs->{size},      65536, "size is set ok";
is $attrs->{protected}, 0, "protected is set ok";
is $attrs->{limit},     1, "limit is set ok";
is $attrs->{magic},     0, "magic is set ok";
is $attrs->{mode},      438, "mode is set ok";
is $attrs->{create},    1, "create is set ok";
is $attrs->{owner},     $$, "owner is set ok";
is $attrs->{graceful},  0, "graceful is set ok";
is $attrs->{tidy},      0, "tidy is set ok";
is $attrs->{destroy},   1, "destroy is set ok";

is $k->attributes('no_exist'), undef, "attributes() on an undefined attr is undef";

IPC::Shareable::_end;
warn "Segs After: " . IPC::Shareable::ipcs() . "\n" if $ENV{PRINT_SEGS};

done_testing;
