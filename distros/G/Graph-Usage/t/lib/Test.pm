package Testpackage;

require 5.6;
use Testpackage::Test2;
require Testpackage::Test2;

BEGIN { require Testpackage::Test3; }

sub somesub
  {
  require Carp;
  }

1;
