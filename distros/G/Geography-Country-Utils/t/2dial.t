use Test;
BEGIN { plan tests => 3 }

use Geography::Country::Utils qw(dialcode);

ok(defined &dialcode);
ok(dialcode('Sweden'), 46);

my $l2 = eval { require Net::Country; 1 };

skip(
    ($l2 ? 0 : "Skipping test on this platform"),
    eval { dialcode('NO') }, 47
);

