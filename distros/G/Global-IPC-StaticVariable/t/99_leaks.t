use strict;
use warnings;

use Test::More;
use Test::LeakTrace;
use Global::IPC::StaticVariable qw/var_create var_destory var_read var_update var_append var_getreset var_length/;

no_leaks_ok {
    my $id = var_create();
    var_update($id, "test");
    my $v = var_read($id);
    var_update($id, "");
    var_update($id, undef);
    var_append($id, "append");
    var_length($id);
    var_getreset($id);
    var_destory($id);
};

no_leaks_ok {
    var_read(undef);
    var_update(undef, undef);
    var_destory(undef);
};

done_testing;
