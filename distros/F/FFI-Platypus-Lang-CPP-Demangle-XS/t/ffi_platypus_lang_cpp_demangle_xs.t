use Test2::V0 -no_srand => 1;
use FFI::Platypus::Lang::CPP::Demangle::XS;

subtest 'basic' => sub {

  my $name = demangle('!@#$');
  is($name, undef, '!@#$ is not a valid mangled c++ name' );

};

done_testing;
