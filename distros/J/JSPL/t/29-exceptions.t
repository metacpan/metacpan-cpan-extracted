#!perl
use strict;
use warnings;

use Test::More tests => 34;
use Test::Exception;

use JSPL;


my $runtime = new JSPL::Runtime();
my $context = $runtime->create_context();

my $ret;
throws_ok {
    $ret = $context->eval(q| "bobabasdfasd"; joe; |);
} qr'not defined', "Not defined";
isa_ok($@, 'JSPL::Error');
is($ret, undef);

$context->bind_function(perl5_eval => sub { my $ret = eval $_[0]; die $@ if $@; $ret } );
$context->bind_function(alert => sub { warn @_ } );
$context->bind_function(isa_ok => \&isa_ok);
$context->bind_function(is => \&is);

dies_ok {
    $context->eval(q|
           perl5_eval('print "foo\\n"; die { foo => "fnord\\n"}; print "bar\\n"'); 1; 
    |)
} 'Perl die';
is_deeply($@, { foo => "fnord\n"} );

dies_ok {
    $context->eval(q| throw new Array (); 1; |)
} 'Throw Array';
isa_ok($@, 'ARRAY');


dies_ok {
    $context->eval(q|
	try {
	  perl5_eval('print "foo\\n"; die { foo => "fnord\\n"}; print "bar\\n"');
	}
	catch (e) {
	  isa_ok(e, "HASH");
	  throw e;
	}

	1;
    |)
} 'Try and catch';
is_deeply($@, { foo => "fnord\n"} );

throws_ok {
    $context->eval(q|
	blahblah this is bad;
    |)
} qr/missing ;/, 'Syntax';
like($@, qr/at main line 56/);

lives_ok {
    $ret = $context->eval(<<EOP);
	try {
	  perl5_eval("BOOM");
	} catch(e) {
	}
	2;
EOP
} 'Try an catch';
is($ret, 2, "returned 2");
ok(!$@, "no error thrown" );

# TODO, check why with 5.13.x the stricter form qr/^bar$/ FAILs
throws_ok {
    $context->eval(q|
	try {
	  perl5_eval('die "foo"');
	} catch (e) {
	  throw "bar";
	}
	1;
    |)
} qr/^bar/, 'Die in perl, rethrow another';

throws_ok {
    $context->eval(q|
	try {
	  throw "foo";
	} catch (e) {
	  throw "bar";
	}
	1;
    |)
} qr/^bar/, "Throws is js,  rethrow another";

# Round II, legacy
{ local $context->{RaiseExceptions} = 0;

$ret = $context->eval(<<EOP);
"bobabasdfasd";
joe;
EOP
is($ret, undef);
like($@, qr'not defined');
isa_ok($@, 'JSPL::Error');

$ret = $context->eval(<<EOP);
  perl5_eval('print "foo\\n" ;die { foo => "fnord\\n"}; print "bar\\n"');

1;

EOP
is_deeply($@, { foo => "fnord\n"} );
is($ret, undef);

$context->eval(<<EOP);
throw new Array ();
1;
EOP

isa_ok($@, 'ARRAY');

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

$ret = $context->eval(<<EOP);
blahblah this is bad;

EOP

is($ret, undef);
like($@, qr/at main line \d+/);

$ret = $context->eval(<<EOP);
try {
  perl5_eval("BOOM");
} catch(e) {
}
1;
EOP

is($ret, 1, "returned 1");
ok( !$@, "no error thrown" );

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
$context->eval("var f = new CantCreate");
like($@, qr/Can't create/);

} # RaiseExceptions default again

throws_ok {
    $context->eval("var f = new CantCreate");
} qr/Can't create/;
