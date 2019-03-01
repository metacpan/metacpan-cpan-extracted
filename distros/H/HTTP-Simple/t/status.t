use strict;
use warnings;
use Test::More;
use HTTP::Simple;

ok is_info($_), "HTTP $_ is informational" for 100..199;
ok is_success($_), "HTTP $_ is success" for 200..299;
ok is_redirect($_), "HTTP $_ is redirect" for 300..399;
ok is_error($_), "HTTP $_ is error" for 400..599;
ok is_client_error($_), "HTTP $_ is client error" for 400..499;
ok is_server_error($_), "HTTP $_ is server error" for 500..599;

ok !is_info($_), "HTTP $_ is not informational" for 0, 1, 99, 200;
ok !is_success($_), "HTTP $_ is not success" for 0, 2, 199, 300;
ok !is_redirect($_), "HTTP $_ is not redirect" for 0, 3, 299, 400;
ok !is_error($_), "HTTP $_ is not error" for 0, 4, 5, 399, 600;
ok !is_client_error($_), "HTTP $_ is not client error" for 0, 4, 399, 500;
ok !is_server_error($_), "HTTP $_ is not server error" for 0, 5, 499, 600;

done_testing;
