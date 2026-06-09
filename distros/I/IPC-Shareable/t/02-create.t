use warnings;
use strict;

use IPC::Shareable;
IPC::Shareable->testing_set('IPC::Shareable');
use Test::More;

use FindBin;
use lib $FindBin::Bin;
use IPCShareableTest qw(assert_clean_process unique_glue);


my $ok = eval {
    tie my $sv, 'IPC::Shareable', {key => unique_glue('test02'), destroy => 1, serializer => 'storable' };
    1;
};

is $ok, undef, "We croak ok if create is not set and segment doesn't yet exist";
like $@, qr/Could not acquire/, "...and error is sane.";

IPC::Shareable::_end;

assert_clean_process();

done_testing;

