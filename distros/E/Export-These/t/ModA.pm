package ModA;
use ModB;
# TEST PACKAGE EXPORTING USING THE Export::These.
# Reexports symbols from ModB
#
use Export::These qw<sub1 sub2 $var1 @var2 %var3>;
use Export::These group1=>["group1_sub", "\$group1_scalar", "\@group1_array", "\%group1_hash"];

sub _reexport {

  ModB->import( "sub4", ":group2");
}

our $var1="var1";
our @var2=("var2","var2");
our %var3=(var3=>1);

our $group1_scalar="group1_scalar";
our @group1_array=("group1_array","asdf");
our %group1_hash="group1_hash";

sub sub1 {
  "sub1";
}

sub sub2 {
  "sub2";
}

sub sub3 {
  "sub3";
}

sub group1_sub {
"group1_sub";
}

__PACKAGE__;
