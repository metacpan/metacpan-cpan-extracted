use Test::More;
use Kelp;

my $app = Kelp->new;
ok $app->can('bcrypt');
is $app->bcrypt('snorkel'), 'Z5/RGX.lh5KWoJXG4ZLoIzA88CoOp9O';
is $app->bcrypt('password'), 'QOdasAr2yk/0qcrd.4rOZMvAjns9LPm';

done_testing;


