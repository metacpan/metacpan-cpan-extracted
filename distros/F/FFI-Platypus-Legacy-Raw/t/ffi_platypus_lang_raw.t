use Test2::V0 -no_srand => 1;
use FFI::Platypus::Lang::Raw;
use FFI::Platypus::Legacy::Raw;
use Data::Dumper;

my @type_names = qw( void int uint short ushort long ulong int64 uint64 char uchar float double str );

foreach my $type_name (@type_names)
{
  my $type_sub = "FFI::Platypus::Legacy::Raw::$type_name";
  my $type = eval qq{ $type_sub(); };
  my $platypus_type = FFI::Platypus::Lang::Raw->native_type_map->{$type};
  my $test_name = sprintf "type %-35s %s %s", $type_sub, $type, defined $platypus_type ? "'$platypus_type'" : 'undef';
  ok $platypus_type, $test_name;
  my $meta = FFI::Platypus->type_meta($platypus_type);
  note(
    Data::Dumper
      ->new([$meta], [qw(meta)])
      ->Indent(0)
      ->Terse(1)
      ->Sortkeys(1)
      ->Dump
  );
}

done_testing;
