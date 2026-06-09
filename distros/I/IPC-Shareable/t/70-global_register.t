use strict;
use warnings;

use Data::Dumper;
use Test::More;

use FindBin;
use lib $FindBin::Bin;
use IPCShareableTest qw(assert_clean_process unique_glue);
use IPC::Shareable;
IPC::Shareable->testing_set('IPC::Shareable');


my $mod = 'IPC::Shareable';

# Bug 38: Ensure global register populates before access to the underlying
# data
{
    # Global register
    {
        my ($knot, %hv);

        {
            $knot = tie my %hv, $mod, {
                create  => 1,
                key     => unique_glue('testing123'),
                destroy => 1,
            };

            my $id = $knot->seg->id;
            my $key = $knot->seg->key;

            my $dump = Dumper tied(%hv)->global_register;

            is grep(/\s+'$id'\s+/, $dump), 1, "Segment ID is in the global_register Dumper output ok";
            is grep(/'_key' => $key/, $dump), 1, "So is the key in global_register output";
        }

        is % hv, 0, "hash deleted after we go out of scope";
    }
    # Process register
    {
        my ($knot, %hv);

        {
            $knot = tie my %hv, $mod, {
                create  => 1,
                key     => unique_glue('testing123'),
                destroy => 1,
            };

            my $id = $knot->seg->id;
            my $key = $knot->seg->key;

            my $dump = Dumper tied(%hv)->process_register;

            is grep(/\s+'$id'\s+/, $dump), 1, "Segment ID is in the process_register Dumper output ok";
            is grep(/'_key' => $key/, $dump), 1, "So is the key in process_register output";
        }

        is % hv, 0, "hash deleted after we go out of scope";
    }
}

IPC::Shareable->clean_up_all;
IPC::Shareable::_end;


assert_clean_process();

done_testing();


