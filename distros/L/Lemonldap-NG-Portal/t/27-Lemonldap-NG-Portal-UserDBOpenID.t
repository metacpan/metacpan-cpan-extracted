use Test::More tests => 2;

SKIP: {
    eval { require Net::OpenID::Consumer; };
    skip "Net::OpenID::Consumer is not installed, so "
      . "Lemonldap::NG::Portal::AuthOpenID will not be useable", 2
      if ($@);
    use_ok('Lemonldap::NG::Portal::OpenID::SREG');
    use_ok('Lemonldap::NG::Portal::UserDBOpenID');
}
