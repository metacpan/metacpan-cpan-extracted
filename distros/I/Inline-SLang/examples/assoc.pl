use Inline 'SLang';

# you can send hash references to S-Lang
print_in_slang( { a => 23, "b b" => "foo" } );

# and get them back from S-Lang
$href = get_from_slang();
print "The assoc array contains:\n" .
  join( "", map { "\t$_ => $$href{$_}\n"; } keys %$href );

__END__
__SLang__

define print_in_slang (assoc) {
  message( "SLang thinks you sent it an assoc. array with:" );
  foreach ( assoc ) using ( "keys", "values" ) {
    variable k, v;
    ( k, v ) = ();
    vmessage( " key %s = %S", k, v );
  }
}
define get_from_slang() {
  variable x = Assoc_Type [String_Type];
  x["a key"] = "a value";
  x["another key"] = "another value";
  return x;
}
