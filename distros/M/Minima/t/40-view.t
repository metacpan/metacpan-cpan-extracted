use v5.40;
use Test2::V0;

use Minima::View;

my $v = Minima::View->new;
my $body;

like(
    warning { $body = $v->render },
    qr/base.*called/i,
    'warns on calling base &render'
);

done_testing;
