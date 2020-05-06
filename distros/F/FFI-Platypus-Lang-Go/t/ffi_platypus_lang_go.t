use Test2::V0 -no_srand => 1;
use FFI::Platypus::Lang::Go;
use FFI::Platypus;

subtest 'basic' => sub {

  my $ffi = FFI::Platypus->new;
  $ffi->lang('Go');

  my @types = qw(
    gobool
    goint  goint8  goint16  goint32  goint64
    gouint gouint8 gouint16 gouint32 gouint64 gouintptr
    gobyte
    gorune
    gofloat32 gofloat64
  );

  # gostring
  # support depends on C, libffi, etc
  # complex64 complex128

  foreach my $type (@types)
  {
    my $size = eval { $ffi->sizeof($type) };
    is $@, '', "size of $type == @{[ $size || 'undef' ]}";
  }

};

done_testing
