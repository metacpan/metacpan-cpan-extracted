
# This file contains tests for things that previously segfaulted, failed etc.

use Test;
use File::Spec;

BEGIN { plan tests => 2 };
use lib qw(../blib/lib ../blib/arch);
use Mail::Transport::Dbx;
use File::Spec;

ok(1); # If we made it this far, we're ok.

# [ id: #1 ]

{
    my $email;
    {
        my $dbx = Mail::Transport::Dbx->new
            (File::Spec->catfile("t", "test.dbx"));
        $email = $dbx->get(0);
    }
    ok($email->as_string);
}
