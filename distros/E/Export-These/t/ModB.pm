package ModB;
# TEST PACKAGE IMPORTED BY MOD A
use Export::These (
  "sub4", group2=>["group2_sub", "\$group2_scalar"]
);
our $group2_scalar="group2_scalar";
sub sub4 {
  "sub4";
}

sub group2_sub {
  "group2_sub";
}
__PACKAGE__;
