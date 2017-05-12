sub import_keys($){
  my $filename=shift;

  my $trusted =  scalar(@_) ? "--trusted-key 0x".shift : "";

  use File::Temp qw(tempdir);

  unless ( 0 == system("gpg --version 2>&1 >/dev/null") ) {
    return undef;
  }

  my $gpghome = tempdir( "mgtXXXXX", CLEANUP => 1);
  unless ( 0 == system("gpg --homedir $gpghome $trusted --import $filename 2>&1 >/dev/null")) {
    return undef;
  }
  return $gpghome;
}

1;
