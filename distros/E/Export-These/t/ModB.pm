package ModB;
# TEST PACKAGE IMPORTED BY MOD A
use Export::These (
  "sub4",
  group2=>["group2_sub", "\$group2_scalar"],
  group3=>["group3_sub"]
);

our $group2_scalar="group2_scalar";
sub sub4 {
  "sub4";
}

sub group2_sub {
  "group2_sub";
}

sub group3_sub {
  "group3_sub";
}
__PACKAGE__;
