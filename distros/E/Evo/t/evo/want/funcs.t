use Evo '-Want *';
use Test::More;

ok want_is_list(1);
ok want_is_scalar('');
ok want_is_void(undef);

ok want_is_list(WANT_LIST);
ok want_is_scalar(WANT_SCALAR);
ok want_is_void(WANT_VOID);

ok !want_is_list(2);
ok !want_is_list(undef);
ok !want_is_list('');

ok !want_is_scalar(2);
ok !want_is_scalar(1);
ok !want_is_scalar(undef);

ok !want_is_void(2);
ok !want_is_void('');
ok !want_is_void(1);

done_testing;

