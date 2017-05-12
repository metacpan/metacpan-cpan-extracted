use Evo '-Class::T *; Test::More; Evo::Internal::Exception';

like exception { T_ENUM() }, qr/empty.+$0/;

# undefined
my $check_undef = T_ENUM(undef);
ok $check_undef->(undef);
ok !$check_undef->("");
ok !$check_undef->("ok");


my $check = T_ENUM(0, "ok", "");

# exists
ok $check->(0);
ok $check->("ok");
ok $check->("");

# false
ok !$check->(undef);
ok !$check->(33);

done_testing;
