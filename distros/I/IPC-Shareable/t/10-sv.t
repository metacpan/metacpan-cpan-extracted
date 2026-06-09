use warnings;
use strict;

use IPC::Shareable;
IPC::Shareable->testing_set('IPC::Shareable');
use Test::More;

use FindBin;
use lib $FindBin::Bin;
use IPCShareableTest qw(assert_clean_process unique_glue);


tie my $sv, 'IPC::Shareable', {destroy => 1, serializer => 'storable' };

$sv = 'foo';
is $sv, 'foo', "SCALAR created ok, and set to 'foo'";

# This is a regression test for the
# bug fixed by using Scalar::Util::reftype
# instead of looking for HASH, SCALAR, ARRAY
# in the stringified version of the scalar.

for my $mod (qw/HASH SCALAR ARRAY/){
    # --- TIESCALAR
    my $sv;
    tie($sv, 'IPC::Shareable', { destroy => 'yes' , serializer => 'storable' })
        or die ('this was not expected to die here');

    $sv = $mod.'foo';
    is $sv, $mod.'foo', "SCALAR regression store/fetch ok";
}

# FETCH from a never-written scalar segment returns undef (empty segment path)
{
    tie my $sv, 'IPC::Shareable', { key => unique_glue('sv10e'), create => 1, destroy => 1 , serializer => 'storable' };
    is $sv, undef, "FETCH on never-written scalar returns undef ok";
}

# STORE edge case: previous value was undef. The TYPE_SCALAR STORE branch
# (Shareable.pm:189-196) assigns _data = \$val on every store, so after
# storing undef _data is a scalar-ref whose target is undef. A subsequent
# STORE then exercises the truthy-but-dereferences-to-undef branch in
# _remove_child without exploding.
{
    my $k = tie my $sv, 'IPC::Shareable', { key => unique_glue('sv10f'), create => 1, destroy => 1, serializer => 'storable' };

    $sv = undef;
    is $sv, undef, "scalar tied var assigned undef ok";

    # _data is now \$undef. Force STORE to re-enter so it sees that state.
    is ref($k->{_data}), 'SCALAR', "...and _data is a SCALAR ref (to an undef value)";
    is ${ $k->{_data} }, undef,     "...where the underlying value is undef";

    # Store a fresh value over the \$undef — STORE must walk the
    # ref-to-undef branch of _remove_child without exploding.
    $sv = 'after_undef';
    is $sv, 'after_undef', "STORE of plain scalar over previous \\\$undef succeeds";

    # And store a ref over what's now a plain scalar (TYPE_SCALAR branch with a tied child).
    $sv = { nested => 1 };
    is $sv->{nested}, 1, "STORE of hash ref over plain scalar succeeds";
}

IPC::Shareable::_end;

assert_clean_process();

done_testing();
