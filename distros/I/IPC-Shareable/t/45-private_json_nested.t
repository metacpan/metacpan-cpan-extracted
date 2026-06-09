use warnings;
use strict;

use IPC::Shareable;
IPC::Shareable->testing_set('IPC::Shareable');
use Test::More;

use FindBin;
use lib $FindBin::Bin;
use IPCShareableTest qw(assert_clean_process);


# Under IPC_PRIVATE the Storable path lets child segments inherit IPC_PRIVATE,
# but the JSON path forces a random non-zero key so the child can be referenced
# from the encoded blob. See _magic_tie at Shareable.pm:1567.

# --- JSON: nested child under IPC_PRIVATE parent must have a non-zero key ---
{
    my $k = tie my %h, 'IPC::Shareable', {
        create     => 1,
        destroy    => 1,
        serializer => 'json',
    };

    is $k->{_key}, 0, "JSON parent created with default IPC_PRIVATE (key == 0)";

    $h{nested} = { x => 42 };

    my $child_knot = tied %{ $h{nested} };
    ok $child_knot, "JSON nested ref: child is tied ok";
    isnt $child_knot->{_key}, 0,
        "JSON nested under IPC_PRIVATE: child key is random/non-zero (not IPC_PRIVATE)";

    is $h{nested}{x}, 42, "JSON nested data readable through parent ok";

    IPC::Shareable->clean_up_all;
}

# --- Storable: nested child under IPC_PRIVATE parent inherits IPC_PRIVATE ---
{
    my $k = tie my %h, 'IPC::Shareable', {
        create     => 1,
        destroy    => 1,
        serializer => 'storable',
    };

    is $k->{_key}, 0, "Storable parent created with default IPC_PRIVATE (key == 0)";

    $h{nested} = { x => 42 };

    my $child_knot = tied %{ $h{nested} };
    ok $child_knot, "Storable nested ref: child is tied ok";
    is $child_knot->{_key}, 0,
        "Storable nested under IPC_PRIVATE: child key is also IPC_PRIVATE (legacy)";

    is $h{nested}{x}, 42, "Storable nested data readable through parent ok";

    IPC::Shareable->clean_up_all;
}

IPC::Shareable::_end;

assert_clean_process();

done_testing;