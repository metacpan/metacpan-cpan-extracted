use warnings;
use strict;

use Data::Dumper;
use IPC::Shareable;
IPC::Shareable->testing_set('IPC::Shareable');
use Test::More;

use FindBin;
use lib $FindBin::Bin;
use IPCShareableTest qw(assert_clean_process unique_glue);


my $mod = 'IPC::Shareable';

my $ph = $mod->new(
    key => unique_glue('hash'),
    create => 1,
    destroy => 1
);

my $k = tied %$ph;

is ref $k, 'IPC::Shareable', "tied() returns a proper IPC::Shareable object ok";
is exists $k->{attributes}, 1, "...and it has proper attributes ok";

IPC::Shareable::_end;

assert_clean_process();

done_testing();
