use Test::More tests => 1;

eval {
    $CLASS->new(LOG_UNIX, 'a' x 10000, 0, LOG_LOCAL0, LOG_INFO, "mymachine", "logger");
};
like($@, qr/^Error in ->new/, "long filename");

# vim: filetype=perl
1;
