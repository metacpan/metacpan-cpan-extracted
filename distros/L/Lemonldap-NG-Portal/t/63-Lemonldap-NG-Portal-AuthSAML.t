use Test::More tests => 1;

SKIP: {
    eval "use Lasso;";
    skip "Lasso is not installed, can't test SAML features", 1 if ($@);
    use_ok('Lemonldap::NG::Portal::AuthSAML');
}
