#!perl
use strict;
use Test::More;

use JavaScript;

BEGIN {
    # Skip these test if we don't have JavaScript 1.7 or later
    my $version = (JavaScript::get_engine_version())[1];
    $version =~ s/\.\d$// if $version =~ /\d+\.\d+\.\d+$/;
    plan skip_all => "Engine version 1.7 or later require" if $version < 1.7;
}

plan tests => 26;

my $runtime = new JavaScript::Runtime();
my $context = $runtime->create_context();

my $ret =
$context->eval(<<EOP);
"bobabasdfasd";
joe;
EOP
is($ret, undef);
like($@, qr'not defined');
isa_ok($@, 'JavaScript::Error');

$context->bind_function( name => 'perl5_eval',
             func => sub { my $ret = eval $_[0]; die $@ if $@; $ret } );

$context->bind_function( name => 'alert',
             func => sub { warn @_ } );

$context->bind_function( name => 'isa_ok',
             func => sub { isa_ok($_[0], $_[1]) } );
$context->bind_function( name => 'is',
             func => \&is );

$ret =
$context->eval(<<EOP);
  perl5_eval('print "foo\\n" ;die { foo => "fnord\\n"}; print "bar\\n"');

1;

EOP
is_deeply($@, { foo => "fnord\n"} );
is($ret, undef);

$ret =
$context->eval(<<EOP);
throw new Array ();
1;
EOP

isa_ok($@, 'ARRAY');
is($ret, undef);


$ret =
$context->eval(<<EOP);
try {
  perl5_eval('print "foo\\n" ;die { foo => "fnord\\n"}; print "bar\\n"');
}
catch (e) {
  isa_ok(e, "HASH");
  throw e;
}

1;

EOP
is_deeply($@, { foo => "fnord\n"} );
is($ret, undef);

$ret = $context->eval(<<EOP);
blahblah this is bad;

EOP

is($ret, undef);
like($@, qr/at main line 75 in 1/);


$ret = $context->eval(<<EOP);
try {
  perl5_eval("BOOM");
} catch(e) {
}
1;
EOP

is($ret, 1, "returned 1");
ok( !$@, "no error thrown" );


$ret =
$context->eval(<<EOP);
try {
  perl5_eval('die "foo"');
}
catch (e) {
  throw "bar";
}
1;
EOP
is($@, "bar" );

$ret =
$context->eval(<<EOP);
try {
  throw "foo";
}
catch (e) {
  throw "bar";
}
1;
EOP
is($@, "bar" );

$ret =
$context->eval(<<EOP);
try {
  throw "foo";
}
catch (e) {
}
1;
EOP
is($@, undef);

$context->bind_class(constructor => sub { die "Can't create"; }, name => 'CantCreate');
$ret = 
$context->eval("var f = new CantCreate");
like($@, qr/Can't create/);

$context->set_pending_exception("erple");
$context->eval("function(){ }");
like($@, qr/erple/);
$context->eval("function(){ };\n");
is($@, undef);

$context->set_pending_exception();
$context->eval("function(){ };\n");
is($@, undef);

{
    my $thing = sub {
        $context->set_pending_exception('bleh');
    };
    $context->bind_value(flibble => $thing);

    $context->eval("flibble();\n");
    like($@, qr{bleh});
    $context->eval("flibble();\n");
    like($@, qr{bleh});

    $context->eval("function(){ };\n");
    is($@, undef);
    $context->eval("try { flibble(); } catch(e){ e = undefined }");
    is($@, undef);
}

{
    my $thing = sub {
        $context->eval("throw 'yarghle';");
        like($@, qr{yarghle});
    };
    $context->bind_value(yargh => $thing);
    $context->eval("(function(){ yargh();})()");
}

undef $context;
