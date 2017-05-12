use Inline 'SLang' => Config => EXPORT =>
     [ 'sl_array', 'Integer_Type' ];
use Inline 'SLang';

my $aref = [ 1, 3, 2 ];
foo( $aref );
foo( sl_array( $aref, "Int_Type" ) );
foo( sl_array( $aref, [3] ) );
foo( sl_array( $aref, [3], Integer_Type() ) );

__END__
__SLang__

define foo(x) { vmessage("Array has type: %S", _typeof(x) ); }
