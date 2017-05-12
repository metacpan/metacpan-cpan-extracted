use Test::More tests => 2;

eval "require InlineX::XS;";
ok(!$@);
eval "require InlineX::XS::MM;";
ok(!$@);

# I know. I know.
