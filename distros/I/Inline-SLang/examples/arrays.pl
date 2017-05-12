use Inline 'SLang';

# you can send arrays to S-Lang
print_in_slang( [ 1, 2, 4 ] );

# and get them back from S-Lang
$aref = get_from_slang();
print "The array contains: " . join(',', @$aref) . "\n";

__END__
__SLang__

define print_in_slang (arr) {
  variable adims, ndim, atype;
  ( adims, ndim, atype ) = array_info(arr);
  vmessage( "Array has type=%S with %d dims", atype, ndim );
  foreach ( arr ) {
    variable val = ();
    vmessage( "  Value = %s", string(val) );
  }
}
define get_from_slang() { return ["a string","another one","3"]; }
