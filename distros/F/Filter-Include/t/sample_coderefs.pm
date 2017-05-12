{
  no warnings;

  ## $currtest should be set just before the include
  Test::More::ok(true => "$main::currtest test worked");

  $sample_coderefs::incr++;

  sub sample_coderefs::INC {
    coderef_test::get_fh(@_);
  }
}
