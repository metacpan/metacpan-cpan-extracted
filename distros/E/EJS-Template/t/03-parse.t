#!perl -T
use strict;
use warnings;

use Test::More tests => 20;

use EJS::Template::Test;

ejs_test_parse('', '');
ejs_test_parse('  ', 'print("  ");');

ejs_test_parse('<%'       , ''     );
ejs_test_parse('<%  '     , '  '   );
ejs_test_parse('<% %>'    , ' '    );
ejs_test_parse('<% %>  '  , '   '  );
ejs_test_parse('  <%'     , '  '   );
ejs_test_parse('  <%  '   , '    ' );
ejs_test_parse('  <% %>'  , '   '  );
ejs_test_parse('  <% %>  ', '     ');

ejs_test_parse('<%='       , 'print();'                         );
ejs_test_parse('<%=  '     , 'print(  );'                       );
ejs_test_parse('<%= %>'    , 'print( );'                        );
ejs_test_parse('<%= %>  '  , 'print( );print("  ");'            );
ejs_test_parse('  <%='     , 'print("  ");print();'             );
ejs_test_parse('  <%=  '   , 'print("  ");print(  );'           );
ejs_test_parse('  <%= %>'  , 'print("  ");print( );'            );
ejs_test_parse('  <%= %>  ', 'print("  ");print( );print("  ");');

ejs_test_parse(<<__EJS__, <<__OUT__);
Line 1
  <% var x %>\t
Line 2
__EJS__
print("Line 1\\n");
   var x \t
print("Line 2\\n");
__OUT__

ejs_test_parse(<<__EJS__, <<__OUT__);
Line 1
  <%= x %>\t
Line 2
__EJS__
print("Line 1\\n");
print("  ");print( x );print("\t\\n");
print("Line 2\\n");
__OUT__
