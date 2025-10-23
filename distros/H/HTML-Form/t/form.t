#!perl

use strict;
use warnings;

use Test::More;
use HTML::Form;

my @warn;
$SIG{__WARN__} = sub { push( @warn, $_[0] ) };

my @f = HTML::Form->parse( "", "http://localhost/" );
is( @f, 0 );

@f = HTML::Form->parse( <<'EOT', "http://localhost/" );
<form action="abc" name="foo">
<input name="name">
</form>
<form></form>
EOT

is( @f, 2 );

my $f = shift @f;
is( $f->value("name"), "" );
is(
    $f->dump,
    "GET http://localhost/abc [foo]\n  name=                          (text)\n"
);

my $req = $f->click;
is( $req->method, "GET" );
is( $req->uri,    "http://localhost/abc?name=" );

$f->value( name => "Gisle Aas" );
$req = $f->click;
is( $req->method, "GET" );
is( $req->uri,    "http://localhost/abc?name=Gisle+Aas" );

is( $f->attr("name"),   "foo" );
is( $f->attr("method"), undef );

$f = shift @f;
is( $f->method,  "GET" );
is( $f->action,  "http://localhost/" );
is( $f->enctype, "application/x-www-form-urlencoded" );
is( $f->dump,    "GET http://localhost/\n" );

# try some more advanced inputs
$f = HTML::Form->parse( <<'EOT', base => "http://localhost/", verbose => 1 );
<form method=post>
   <input name=i type="image" src="foo.gif">
   <input name=c type="checkbox" checked>
   <input name=r type="radio" value="a">
   <input name=r type="radio" value="b" checked>
   <input name=t type="text">
   <input name=p type="PASSWORD">
   <input name=tel type="tel">
   <input name=date type="date">
   <input name=h type="hidden" value=xyzzy>
   <input name=s type="submit" value="Doit!">
   <input name=r type="reset">
   <input name=b type="button">
   <input name=f type="file" value="foo.txt">
   <input name=x type="xyzzy">

   <textarea name=a>
abc
   </textarea>

   <select name=s>
      <option>Foo
      <option value="bar" selected>Bar
   </select>

   <select name=m multiple>
      <option selected value="a">Foo
      <option selected value="b">Bar
   </select>
</form>
EOT

#print $f->dump;
#print $f->click->as_string;

chomp(my $expected_advanced = <<'EOT');
POST http://localhost/
Content-Length: 86
Content-Type: application/x-www-form-urlencoded

i.x=1&i.y=1&c=on&r=b&t=&p=&tel=&date=&h=xyzzy&f=&x=&a=%0D%0Aabc%0D%0A+++&s=bar&m=a&m=b
EOT
is( $f->click->as_string, $expected_advanced);

is( @warn, 1 );
like( $warn[0], qr/^Unknown input type 'xyzzy'/ );
@warn = ();

$f = HTML::Form->parse( <<'EOT', "http://localhost/" );
<form>
   <input type=submit value="Upload it!" name=n disabled>
   <input type=image alt="Foo">
   <input type=text name=t value="1">
</form>
EOT

#$f->dump;
is( $f->click->as_string, <<'EOT');
GET http://localhost/?x=1&y=1&t=1

EOT

# test file upload
$f = HTML::Form->parse( <<'EOT', "http://localhost/" );
<form method=post enctype="MULTIPART/FORM-DATA">
   <input name=f type=file value="/etc/passwd">
   <input type=submit value="Upload it!">
</form>
EOT

#print $f->dump;
#print $f->click->as_string;

is( $f->click->as_string, <<'EOT');
POST http://localhost/
Content-Length: 0
Content-Type: multipart/form-data; boundary=none

EOT

my $filename = sprintf "foo-%08d.txt", $$;
die if -e $filename;

open my $file, ">", $filename || die;
binmode($file);
print $file "This is some text\n";
close($file) || die;

$f->value( f => $filename );

#print $f->click->as_string;

is( $f->click->as_string, <<"EOT");
POST http://localhost/
Content-Length: 139
Content-Type: multipart/form-data; boundary=xYzZY

--xYzZY\r
Content-Disposition: form-data; name="f"; filename="$filename"\r
Content-Type: text/plain\r
\r
This is some text
\r
--xYzZY--\r
EOT

unlink($filename) || warn "Can't unlink '$filename': $!";

is( @warn, 0 );

# Try to parse form HTTP::Response directly
{
    package MyResponse;
    require HTTP::Response;
    our @ISA = ('HTTP::Response');

    sub base { "http://www.example.com" }
}
my $response = MyResponse->new( 200, 'OK' );
$response->content("<form><input type=text value=42 name=x></form>");

$f = HTML::Form->parse($response);

is( $f->click->as_string, <<"EOT");
GET http://www.example.com?x=42

EOT

$f = HTML::Form->parse( <<EOT, "http://www.example.com" );
<form>
   <input type=checkbox name=x> I like it!
</form>
EOT

$f->find_input("x")->check;

is( $f->click->as_string, <<"EOT");
GET http://www.example.com?x=on

EOT

$f->value( "x", "off" );
is( $f->click->as_string, <<"EOT");
GET http://www.example.com

EOT

$f->value( "x", "I like it!" );
is( $f->click->as_string, <<"EOT");
GET http://www.example.com?x=on

EOT

$f->value( "x", "I LIKE IT!" );
is( $f->click->as_string, <<"EOT");
GET http://www.example.com?x=on

EOT

$f = HTML::Form->parse( <<EOT, "http://www.example.com" );
<form>
<select name=x>
   <option value=1>one
   <option value=2>two
   <option>3
</select>
<select name=y multiple>
   <option value=1>
</select>
</form>
EOT

$f->value( "x", "one" );

is( $f->click->as_string, <<"EOT");
GET http://www.example.com?x=1

EOT

$f->value( "x", "TWO" );
is( $f->click->as_string, <<"EOT");
GET http://www.example.com?x=2

EOT

is( join( ":", $f->find_input("x")->value_names ), "one:two:3" );
is( join( ":", map $_->name, $f->find_input( undef, "option" ) ), "x:y" );

$f = HTML::Form->parse( <<EOT, "http://www.example.com" );
<form>
<input name=x value=1 disabled>
<input name=y value=2 READONLY type=TEXT>
<input name=z value=3 type=hidden>
</form>
EOT

is( $f->value("x"),        1 );
is( $f->value("y"),        2 );
is( $f->value("z"),        3 );
is( $f->click->uri->query, "y=2&z=3" );

my $input = $f->find_input("x");
is( $input->type, "text" );
ok( !$input->readonly );
ok( $input->disabled );
ok( $input->disabled(0) );
ok( !$input->disabled );
is( $f->click->uri->query, "x=1&y=2&z=3" );

$input = $f->find_input("y");
is( $input->type, "text" );
ok( $input->readonly );
ok( !$input->disabled );
$input->value(22);
is( $f->click->uri->query, "x=1&y=22&z=3" );

$input->strict(1);
eval { $input->value(23); };
like( $@, qr/^Input 'y' is readonly/ );

ok( $input->readonly(0) );
ok( !$input->readonly );

$input->value(222);
is( @warn,                 0 );
is( $f->click->uri->query, "x=1&y=222&z=3" );

$input = $f->find_input("z");
is( $input->type, "hidden" );
ok( $input->readonly );
ok( !$input->disabled );

$f = HTML::Form->parse( <<EOT, "http://www.example.com" );
<form>
<textarea name="t" type="hidden">
<foo>
</textarea>
<select name=s value=s>
 <option name=y>Foo
 <option name=x value=bar type=x>Bar
</form>
EOT

is( $f->value("t"),                                          "\n<foo>\n" );
is( $f->value("s"),                                          "Foo" );
is( join( ":", $f->find_input("s")->possible_values ),       "Foo:bar" );
is( join( ":", $f->find_input("s")->other_possible_values ), "bar" );
is( $f->value( "s", "bar" ),                                 "Foo" );
is( $f->value("s"),                                          "bar" );
is( join( ":", $f->find_input("s")->other_possible_values ), "" );

$f = HTML::Form->parse(
    <<EOT, base => "http://www.example.com", strict => 1 );
<form>

<input type=radio name=r0 value=1 disabled>one

<input type=radio name=r1 value=1 disabled>one
<input type=radio name=r1 value=2>two
<input type=radio name=r1 value=3>three

<input type=radio name=r2 value=1>one
<input type=radio name=r2 value=2 disabled>two
<input type=radio name=r2 value=3>three

<select name=s0>
 <option disabled>1
</select>

<select name=s1>
 <option disabled>1
 <option>2
 <option>3
</select>

<select name=s2>
 <option>1
 <option disabled>2
 <option>3
</select>

<select name=s3 disabled>
 <option>1
 <option disabled>2
 <option>3
</select>

<select name=m0 multiple>
 <option disabled>1
</select>

<select name=m1 multiple="">
 <option disabled>1
 <option>2
 <option>3
</select>

<select name=m2 multiple>
 <option>1
 <option disabled>2
 <option>3
</select>

<select name=m3 disabled multiple>
 <option>1
 <option disabled>2
 <option>3
</select>

</form>

EOT

#print $f->dump;
ok( $f->find_input("r0")->disabled );
ok( !eval { $f->value( "r0", 1 ); } );
like( $@, qr/^The value '1' has been disabled for field 'r0'/ );
ok( $f->find_input("r0")->disabled(0) );
ok( !$f->find_input("r0")->disabled );
is( $f->value( "r0", 1 ), undef );
is( $f->value("r0"),      1 );

ok( !$f->find_input("r1")->disabled );
is( $f->value( "r1", 2 ), undef );
is( $f->value("r1"),      2 );
ok( !eval { $f->value( "r1", 1 ); } );
like( $@, qr/^The value '1' has been disabled for field 'r1'/ );

is( $f->value( "r2", 1 ), undef );
ok( !eval { $f->value( "r2", 2 ); } );
like( $@, qr/^The value '2' has been disabled for field 'r2'/ );
ok( !eval { $f->value( "r2", "two" ); } );
like( $@, qr/^The value 'two' has been disabled for field 'r2'/ );
ok( !$f->find_input("r2")->disabled(1) );
ok( !eval { $f->value( "r2", 1 ); } );
like( $@, qr/^The value '1' has been disabled for field 'r2'/ );
ok( $f->find_input("r2")->disabled(0) );
ok( !$f->find_input("r2")->disabled );
is( $f->value( "r2", 2 ), 1 );

ok( $f->find_input("s0")->disabled );
ok( !$f->find_input("s1")->disabled );
ok( !$f->find_input("s2")->disabled );
ok( $f->find_input("s3")->disabled );

ok( !eval { $f->value( "s1", 1 ); } );
like( $@, qr/^The value '1' has been disabled for field 's1'/ );

ok( $f->find_input("m0")->disabled );
ok( $f->find_input( "m1",  undef, 1 )->disabled );
ok( !$f->find_input( "m1", undef, 2 )->disabled );
ok( !$f->find_input( "m1", undef, 3 )->disabled );

ok( !$f->find_input( "m2", undef, 1 )->disabled );
ok( $f->find_input( "m2",  undef, 2 )->disabled );
ok( !$f->find_input( "m2", undef, 3 )->disabled );

ok( $f->find_input( "m3", undef, 1 )->disabled );
ok( $f->find_input( "m3", undef, 2 )->disabled );
ok( $f->find_input( "m3", undef, 3 )->disabled );

$f->find_input( "m3", undef, 2 )->disabled(0);
ok( !$f->find_input( "m3", undef, 2 )->disabled );
is( $f->find_input( "m3",  undef, 2 )->value(2),     undef );
is( $f->find_input( "m3",  undef, 2 )->value(undef), 2 );

$f->find_input( "m3", undef, 2 )->disabled(1);
ok( $f->find_input( "m3", undef, 2 )->disabled );
is( eval { $f->find_input( "m3", undef, 2 )->value(2) }, undef );
like( $@, qr/^The value '2' has been disabled/ );
is( eval { $f->find_input( "m3", undef, 2 )->value(undef) }, undef );
like( $@, qr/^The 'm3' field can't be unchecked/ );

# multiple select with the same name [RT#18993]
$f = HTML::Form->parse( <<EOT, "http://localhost/" );
<form action="target.html" method="get">
<select name="bug">
<option selected value=hi>hi
<option value=mom>mom
</select>
<select name="bug">
<option value=hi>hi
<option selected value=mom>mom
</select>
<select name="nobug">
<option value=hi>hi
<option selected value=mom>mom
</select>
EOT
is( join( "|", $f->form ), "bug|hi|bug|mom|nobug|mom" );

# Try a disabled radiobutton:
$f = HTML::Form->parse( <<EOT, "http://localhost/" );
<form>
 <input disabled checked type=radio name=f value=a>
 <input type=hidden name=f value=b>
</form>

EOT

is( $f->click->as_string, <<'EOT');
GET http://localhost/?f=b

EOT

$f = HTML::Form->parse( <<EOT, "http://www.example.com" );
<!-- from http://www.blooberry.com/indexdot/html/tagpages/k/keygen.htm -->
<form  METHOD="post" ACTION="http://example.com/secure/keygen/test.cgi" ENCTYPE="application/x-www-form-urlencoded">
   <keygen NAME="randomkey" CHALLENGE="1234567890">
   <input TYPE="text" NAME="Field1" VALUE="Default Text">
</form>
EOT

ok( $f->find_input("randomkey") );
is( $f->find_input("randomkey")->challenge, "1234567890" );
is( $f->find_input("randomkey")->keytype,   "rsa" );
chomp(my $expected_keygen = <<EOT);
POST http://example.com/secure/keygen/test.cgi
Content-Length: 19
Content-Type: application/x-www-form-urlencoded

Field1=Default+Text
EOT
is( $f->click->as_string, $expected_keygen);

$f->value( randomkey => "foo" );
chomp(my $expected_keygen_foo = <<EOT);
POST http://example.com/secure/keygen/test.cgi
Content-Length: 33
Content-Type: application/x-www-form-urlencoded

randomkey=foo&Field1=Default+Text
EOT
is( $f->click->as_string, $expected_keygen_foo);

$f = HTML::Form->parse( <<EOT, "http://www.example.com" );
<form  ACTION="http://example.com/">
   <select name=s>
     <option>1
     <option>2
   <input name=t>
</form>
EOT

ok($f);
ok( $f->find_input("t") );

@f = HTML::Form->parse( <<EOT, "http://www.example.com" );
<form  ACTION="http://example.com/">
   <select name=s>
     <option>1
     <option>2
</form>
<form  ACTION="http://example.com/">
     <input name=t>
</form>
EOT

is( @f, 2 );
ok( $f[0]->find_input("s") );
ok( $f[1]->find_input("t") );

$f = HTML::Form->parse( <<EOT, "http://www.example.com" );
<form  ACTION="http://example.com/">
  <fieldset>
    <legend>Radio Buttons with Labels</legend>
    <label>
      <input type=radio name=r0 value=0 />zero
    </label>
    <label>one
      <input type=radio name=r1 value=1>
    </label>
    <label for="r2">two</label>
    <input type=radio name=r2 id=r2 value=2>
    <label>
      <span>nested</span>
      <input type=radio name=r3 value=3>
    </label>
    <label>
      before
      and <input type=radio name=r4 value=4>
      after
    </label>
  </fieldset>
</form>
EOT

is( join( ":", $f->find_input("r0")->value_names ), "zero" );
is( join( ":", $f->find_input("r1")->value_names ), "one" );
is( join( ":", $f->find_input("r2")->value_names ), "two" );
is( join( ":", $f->find_input("r3")->value_names ), "nested" );
is( join( ":", $f->find_input("r4")->value_names ), "before and after" );

$f = HTML::Form->parse( <<EOT, "http://www.example.com" );
<form>
  <table>
    <TR>
      <TD align="left" colspan="2">
        &nbsp;&nbsp;&nbsp;&nbsp;Keep me informed on the progress of this election
        <INPUT type="checkbox" id="keep_informed" name="keep_informed" value="yes" checked>
      </TD>
    </TR>
    <TR>
      <TD align=left colspan=2>
        <BR><B>The place you are registered to vote:</B>
      </TD>
    </TR>
    <TR>
      <TD valign="middle" height="2" align="right">
        <A name="Note1back">County or Parish</A>
      </TD>
      <TD align="left">
        <INPUT type="text" id="reg_county" size="40" name="reg_county" value="">
      </TD>
      <TD align="left" width="10">
        <A href="#Note2" class="c2" tabindex="-1">Note&nbsp;2</A>
      </TD>
    </TR>
  </table>
</form>
EOT
is( join( ":", $f->find_input("keep_informed")->value_names ), "off:" );

$f = HTML::Form->parse( <<EOT, "http://www.example.com" );
<form action="test" method="post">
<select name="test">
<option value="1">One</option>
<option value="2">Two</option>
<option disabled="disabled" value="3">Three</option>
</select>
<input type="submit" name="submit" value="Go">
</form>
</body>
</html>
EOT
is( join( ":", $f->find_input("test")->possible_values ),       "1:2" );
is( join( ":", $f->find_input("test")->other_possible_values ), "2" );

@warn = ();
$f    = HTML::Form->parse( <<EOT, "http://www.example.com" );
<form>
<select id="myselect">
<option>one</option>
<option>two</option>
<option>three</option>
</select>
</form>
EOT
is( @warn, 0 );

$f = HTML::Form->parse( <<EOT, base => "http://localhost/" );
<form method=post>
<form action="test" method="post">
<button type="submit" name="submit" value="go">run</button>
</form>
EOT

chomp(my $expected_button_go = <<EOT);
POST http://localhost/
Content-Length: 9
Content-Type: application/x-www-form-urlencoded

submit=go
EOT
is( $f->click->as_string, $expected_button_go);

$f = HTML::Form->parse( <<EOT, base => "http://localhost/" );
<form method=post>
<form action="test" method="post">
<button type="submit" name="submit">run</button>
</form>
EOT

chomp(my $expected_button_empty = <<EOT);
POST http://localhost/
Content-Length: 7
Content-Type: application/x-www-form-urlencoded

submit=
EOT
is( $f->click->as_string, $expected_button_empty);

# select with a name followed by select without a name GH#2
$f = HTML::Form->parse( <<EOT, "http://localhost/" );
<form action="target.html" method="get">
<select>
<option selected>option in unnamed before</option>
</select>
<select name="foo">
<option selected>option in named</option>
</select>
<select>
<option selected>option in unnamed after 1</option>
</select>
<select name="">
<option selected>option in empty string name</option>
</select>
EOT

TODO: {
    local $TODO = 'input with empty name should not be included';
    is(
        join( "|", $f->form ),
        "foo|option in named",
        "options in unnamed selects are ignored"
    );
}

# explicitly selecting an input that has no name
my @nameless_inputs = $f->find_input( \undef );
is(
    scalar @nameless_inputs,
    3, 'find_input with ref to undef finds three forms'
);
ok(
    ( !grep { $_->{name} } @nameless_inputs ),
    '... and none of them has a name'
);

ok(
    !( scalar $f->find_input( \undef ) )->{name},
    'find_input with ref to undef in scalar context'
);
TODO: {
    local $TODO = 'input with empty name should not be included';
    is( $f->click->as_string, <<"EOT");
GET http://localhost/target.html?foo=option+in+named

EOT
}

done_testing;
