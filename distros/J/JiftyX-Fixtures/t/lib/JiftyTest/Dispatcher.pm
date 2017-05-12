package JiftyTest::Dispatcher;
our $VERSION = '0.07';

use Jifty::Dispatcher -base;

before "*" => run {
  $current_user = JiftyTest::CurrentUser->superuser;
  $user_object = JiftyTest::Model::User->new(current_user => $current_user);
  # $user_object->load(1);
  $current_user->{user_object} = $user_object;
  Jifty->web->current_user( $current_user );

  Jifty->web->setup_session;
};

under qr{/(.*)} => run {
  my @params = split "/", $1;
  set controller  => shift @params;
  set action      => shift @params;
  set id          => shift @params;
};

on "redirect" => run {
  redirect "/foo/bar";
};

on qr{/foo/bar/(.*)} => run {
  set param => $1;
  show "/foo/bar";
};

under qr{post/(.*)} => run {
  show("/post/".get("action"));
};

before qr{/partial*} => run {
  redirect "/404.html";
};

under qr{user/(.*)} => run {
  show("/user/".get("action"));
};

1;
