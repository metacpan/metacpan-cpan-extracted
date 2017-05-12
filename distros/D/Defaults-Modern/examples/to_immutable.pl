use Defaults::Modern;

fun to_immutable ( (ArrayRef | ArrayObj) $arr ) {
  my $immutable = immarray( blessed $arr ? $arr->all : @$arr );
  confess "No items in array!" unless $immutable->has_any;
  $immutable
}

my $arr = array( 1 .. 5 );
my $imm = to_immutable($arr);

say "Array isa ".blessed $imm;
say "Array contains ".join ', ', $imm->all;
