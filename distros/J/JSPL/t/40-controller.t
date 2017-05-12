#!perl
use Test::More tests => 100;
use utf8;
use strict;
use warnings;

use Test::Exception;
use IO::File;

use JSPL;

sub foo {
    my $self = shift;
    if(ref $self) {
	isa_ok($self, 'main', "Correct invocant, as a method");
	is($JSPL::This, $self, "'this' is \$self");
    } else {
	is($self, 'arg1', "Correct invocant, as a simple sub");
	isnt($JSPL::This, $self,  "'this' isnt \$self");
    }
    my $value = shift;
    return $value;
};

sub BarP::meth {
    my $self = shift;
    my $datum = shift;
    if(ref $self) {
	isa_ok($self, "BarP", "Correct invocant, as a method");
	is($JSPL::This, $self, "'this' is \$self");
    } else {
	is($self, 'BarP', "I was static called");
	isa_ok($JSPL::This, 'JSPL::Stash', "'this' isa Stash");
    }
    return $datum + 1;
}

{
    no warnings 'once';
    $BarP::scalar = 'mamá';
    %BarP::hash = ( a => 'perl', b => 'roks' );
    @BarP::array = (5,4,3,2,1);
}

sub BarP::sub1 {
    is($_[1], 'Perl roks!', $_[1]);
    is($JSPL::This, 8, "This ok");
    return $_[0];
}

my $rt1 = JSPL::Runtime->new;
{
my $ctx = $rt1->create_context;
$ctx->bind_all(is => \&is, like => \&like);

ok(my $ctl = $ctx->get_controller, "JS <-> Perl controlled created");
isa_ok($ctl, "JSPL::Controller");

ok(!$ctl->added('main'), "No main in stash");

$ctx->bind_value(obj => bless {});
isa_ok($ctx->eval('obj'), 'main', "Instance");

# Basic Stash properties
ok(my $stash = $ctl->added('main'), "Stash main expossed, automatically");
isa_ok($stash, 'JSPL::Stash', "A Stash");
is($stash->toString, '[object Stash]', "An [object Stash] in JS");
is($stash->{"__PACKAGE__"}, 'main', "Package is 'main'");

{
  # PerlObjects properties
  is($ctx->eval('obj.__PACKAGE__'), 'main', "JS have __PACKAGE__");
  ok(my $bar = $ctx->eval(q| obj.foo; |), "foo visible");
  isa_ok($bar, 'CODE', "From perl side");
  is($ctx->eval(q| obj.foo(8); |), 8, "Can be called as a method");
  like($ctx->eval(q| obj.foo.toString() |), qr/[perl code]/, "Correct type: [perl code]");
  ok(!$ctx->eval(q| obj.hasOwnProperty('foo'); |), "Inhered");
  is(ref($ctx->eval(q| bar = obj.foo; bar; |)), ref($bar), "Can be stoled");
  is($ctx->eval(q|bar('arg1','arg2');|), 'arg2', "Bar called as simple function");
}

# Forced overrides
{
  # part 1, simple
  local $stash->{foo} = 2;
  is($ctx->eval(q| __PERL__['main'].foo|), 2, "Can touch stash");
  ok($ctx->eval(q| __PERL__['main'].hasOwnProperty('foo')|), "stash owns foo");
  throws_ok { $ctx->eval(q| obj.foo(8); |) } qr/not a function/, "Can't be called"; 
  is($ctx->eval(q| obj.foo; |), 2, "foo visible, now 2");
  is($ctx->eval(q|bar('arg1','arg2');|), 'arg2', "Clone can be called");
}

{
  # Forced overrides, part 2
  local $stash->{foo} = sub { 'baz' };
  is($ctx->eval(q| obj.foo(); |), 'baz', "can override"); 
}
is($ctx->eval(q| obj.foo(9); |), 9, "now can be called again"); 

# Test access to another perl package
ok(!$ctl->added('BarP'), "No BarP package");
ok($ctl->add('BarP'), "BarP added");
ok(my $bstash = $ctl->added('BarP'), "Now a BarP package");
is($bstash->{"__PACKAGE__"}, 'BarP', "Package is 'BarP'");

ok($bstash->class_bind('Bar'), "Binded");
is($ctx->eval(q| Bar.meth(11) |), 12, "Static call");

is($ctx->eval(q| with(Bar) { __PACKAGE__ } |), 'BarP', "Package visible in JS");
is($ctx->jsc_eval($bstash, q| __PACKAGE__ |), 'BarP', "In eval too");
ok(!$ctx->eval(q| Bar.__export__ |), "Has __export__");

# Test symbol access
ok(!$ctx->eval(q| Bar.$scalar2 |), "Don't exists");
is($ctx->eval(q| Bar.$scalar |), 'mamá', "Scalar fetch");
is($ctx->eval(q| Bar['%hash'].b |), 'roks', "Hash fetch");
is($ctx->eval(q| Bar['@array'].toString() |), "5,4,3,2,1", "Array fetch");
ok($ctx->eval(q| Bar['&sub1'].apply(8, [1, "Perl roks!"]) |), "Sub fetch");

# Extend it
$ctx->eval(q| Bar.other = function() { return 'other' }; |) or
    die $@;
is($ctx->eval(q| Bar.other(); |), 'other', "Other");

# Allow modify it
ok(!$bstash->allow_from_js(1), "Allow exports into BarP");
is($bstash->{__export__}, 1, "Export state visible");

ok($ctx->eval(q| Bar.$scalar2 = "papa" |), "Can set scalar");
{ no warnings 'once';
  is($BarP::scalar2, "papa", "Scalar created");
}
$ctx->eval(q| Bar.$scalar3 = {a: 1, b: 2 } |);
{ no warnings 'once';
  isa_ok(tied(%{$BarP::scalar3}), "JSPL::Object");
}

ok(!defined(@BarP::array1),"Don't exists in perl");
is($ctx->eval(q| Bar['@array1'] |), undef, "Don't exists in JS");
ok($ctx->eval(q| Bar['@array1'] = ['a','b','c'] |), "Can set array");
ok(defined(@BarP::array1), "Array created");
ok(
    scalar(@BarP::array1) == 3 && 
    $BarP::array1[$#BarP::array1] eq 'c',
    "The correct one"
);

$ctx->eval(q| Bar.fun = function() { return "I'm JS!" } |);
ok(defined(&BarP::fun), "Sub created");
is(eval { BarP::fun() }, "I'm JS!", "and can be called");

$bstash->allow_from_js(0);
$ctx->eval(q| Bar.fun2 = function() { return 42 }; |);
ok(!defined(&BarP::fun2), "Was vetoed");

# Class_binded, so not as constructor
throws_ok { $ctx->eval(q|new Bar();|) } 
    qr/is not a constructor/, "Can't construct";

# But traps object instances
$ctx->bind_value(baz => bless({ yyy => 'mom' }, 'BarP'));
isa_ok(my $baz = $ctx->eval('baz'), 'BarP', "Instance");
is($ctx->eval(q| baz.meth(8); |), 9, "Can be called");
is($ctx->eval(q| baz.other(); |), 'other', "Proto works");
is($ctx->eval(q| baz.fun() |), "I'm JS!", "Proto works2");
is($ctx->eval(q| baz.fun2() |), 42, "Vetoed created in JS anyway");
is($ctx->eval(q| baz.yyy; |), 'mom', "Property works");
$ctx->eval(q| baz.yyy = 'dad'; |);
is($baz->{yyy}, 'dad', "Changes reflected");

{
  # Test namespace can be populated from JS land
  my $pack = 'somepack';
  ok($ctl->add($pack), "Create new package");
  ok(my $pstash = $ctl->added($pack), "Get stash");
  $pstash->allow_from_js(1);
  $ctx->jsc_eval($pstash, q|
    var $var0 = 'hello';
    var var1 = 1;
    function foo() { return __PACKAGE__ }
    function baz() { return this.__PACKAGE__ }
    function boz(a) { return a.__PACKAGE__ }
  |);
  { no warnings 'once';
    no strict 'refs';
    is(${$pack.'::var0'}, 'hello', "Scalar variable defined");
    is(${$pack.'::var1'}, undef, "Simple variable not defined");
  }
  ok(defined(&{$pack.'::foo'}), "Function defined");
  ok(!defined(&{$pack.'::bar'}), "But not other");
  is(somepack::foo(), 'somepack', "Call from perl works");
  is(somepack::baz(), undef, "In Global");
  is(somepack->baz(), 'somepack' , "In package");
  is($pstash->baz(), 'somepack', "Indirect call works");
  is(somepack->boz($bstash), 'BarP' , "Can pass some other");
  my $spo = bless {}, 'somepack';
  is($spo->baz, 'somepack', "Perl object can call JS method");
}

# Test hi level install, as constructor
ok($ctl->install('IO.File' => 'IO::File'), "Installed");
is(ref($ctx->eval('IO.File')), 'CODE', "Code set");
isa_ok((my $iost = $ctl->added('IO::File')), 'JSPL::Stash');
is(ref($iost->{Proxy}{constructor}),'CODE', "Constructor is code");
is($ctx->eval('IO.File.prototype'), $iost->{Proxy}, "Prototype set");
is(ref($ctx->eval('IO.File.prototype.constructor')), 'CODE', "Prototype.constructor set");
ok($ctx->eval('IO.File.prototype.constructor == IO.File'), 'Correct prototype chain');

# Use as a constructor
ok($ctx->eval(q|  io = new IO.File();   |), "Contructed now");
isa_ok($ctx->eval('io'), 'IO::File');

# Check other static methods or contructors
ok($ctx->eval(q| io = IO.File.new_tmpfile() |), "Other const called");
isa_ok($ctx->eval('io'), 'IO::File');

# Now a big test
ok($ctx->eval(q|
	var pos;
	io.print("Some text, line 1");
	io.print("more text, line 2");
	pos = io.getpos();
	io.print("This is line 3");
	io.seek(0, 0); // To the begining
	is(io.read(4), 'Some', "line1: Some");
	io.setpos(pos);
	like(io.getline(), /line 3/, "Line 3");
	io.eof();
|), "At EOF");

}

ok(1, "All done, clean");

