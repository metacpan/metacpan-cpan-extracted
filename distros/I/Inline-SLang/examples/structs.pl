use Inline 'SLang';

# you can send arrays to S-Lang
# - note we use them like a hash reference
my $s1 = Struct_Type->new( ["xx","aa","one"] );
$$s1{xx} = 14; $$s1{aa} = "foo"; $$s1{one} = [1,2];
print_in_slang( $s1 );

# and get them back from S-Lang
my $s2 = get_from_slang();
print "The struct has a type of $s2\n";
while ( my ( $k, $v ) = each %$s2 ) {
  print "  field $k has type ",
    (ref($v) ? ref($v) : "perl scalar"),
    " and value $v\n";
}

__END__
__SLang__

define print_in_slang (st) {
  vmessage( "S-Lang has been sent a %S structure", typeof(st) );
  foreach ( get_struct_field_names(st) ) {
    variable f = ();
    vmessage( " and field %s = %S", f, get_struct_field(st,f) );
  }
}
typedef struct { key1, wowza } FooStruct;
define get_from_slang() {
  variable x = @FooStruct;
  x.key1 = "this is key 1";
  x.wowza = 4+3i;
  return x;
}
