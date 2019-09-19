use Test2::V0 -no_srand => 1;
use FFI::Platypus;
use FFI::Platypus::Record::StringArray;

my $ffi = FFI::Platypus->new;

subtest 'basic' => sub {

  my $a = FFI::Platypus::Record::StringArray->new(qw( foo bar baz ), undef );
  isa_ok $a, 'FFI::Platypus::Record::StringArray';
  is $a->size, 4;
  is $a->element(0), 'foo';
  is $a->element(1), 'bar';
  is $a->element(2), 'baz';
  is $a->element(3), undef;
  like $a->opaque, qr/^-?[0-9]+$/;

  is($ffi->cast('opaque' => 'string[]', $a->opaque), [qw( foo bar baz )]);
  is($ffi->cast('opaque' => 'string[4]', $a->opaque), [qw( foo bar baz ), undef]);

};

done_testing
