# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Gimp-ScriptFu-Client.t'

#########################

use Test::More tests => 2;
# use_ok won't work - the filter needs to be part of a script
# BEGIN { use_ok('Gimp::ScriptFu::Client') };

#########################

# t/t.pl:
# (throw (string-append "Success\n2+2=" (number->string (let ((x 2)(y 2))(+ {"x"} {"y"})))))

like( `perl t/t.pl -vc`,
 qr/\(error \(string-append "Success\\n2\+2=" \(number->string \(let \(\(x 2\)\(y 2\)\)\(\+ x y\)\)\)\)\)/,
  'syntax check' );
like( `perl t/t.pl`, qr/2\+2=4/, 'Gimp request' ) or diag( "\nGimp server may not be running\n\n" );


