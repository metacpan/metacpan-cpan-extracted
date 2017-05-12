# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Inline-Win32COM.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 10;
use Test::Exception;
BEGIN { use_ok('Inline::WSC') };


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Inline::WSC VBScript => <<'MyVBScript';

  ' Say hello:
  Function Hello( ByVal Name )
    Hello = "Hello, " & Name
  End Function
  
  ' Handy method here:
  Function AsCurrency( ByVal Amount )
    AsCurrency = FormatCurrency( Amount )
  End Function

MyVBScript

ok( main->can('Hello'), "VBScript Hello() method created" );
ok( main->can('AsCurrency'), "VBScript AsCurrency() method created" );

my $vbres;
lives_ok { $vbres = Hello("John") } "Hello() is callable";
ok( $vbres eq 'Hello, John', "VBScript Hello() result is correct" );

# You may also use the 'compile' method directly:
Inline::WSC->compile( JScript => q~
  function greet( name ) {
    return "Hello, " + name + "!";
  }// end greet( name )
~);
ok( main->can('greet'), 'JScript greet() method created' );
my $jsresult;
lives_ok { $jsresult = greet('John') } "greet() is callable";
ok( $jsresult eq 'Hello, John!', "JScript greet() result is correct" );

# Make sure the object-returning works as expected:
Inline::WSC->compile( VBScript => q~
  Function ReturnsObject()
    Dim obj : Set obj = CreateObject("Scripting.Dictionary")
    obj.Add "Age", 28
    obj.Add "Location", "Denver"
    Set ReturnsObject = obj
  End Function
~);

my $obj = ReturnsObject();
ok( $obj->Item('Age') == 28, "ReturnsObject()->Item('Age')" );
ok( $obj->Item('Location') eq 'Denver', "ReturnsObject()->Item('Location')" );


