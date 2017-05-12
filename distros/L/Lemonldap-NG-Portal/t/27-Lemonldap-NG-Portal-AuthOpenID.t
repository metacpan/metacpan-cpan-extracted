use Test::More tests => 1;

SKIP: {
    eval { require Net::OpenID::Consumer; };
    skip "Net::OpenID::Consumer is not installed, so "
      . "Lemonldap::NG::Portal::AuthOpenID will not be useable", 1
      if ($@);
    use_ok('Lemonldap::NG::Portal::AuthOpenID');
}
