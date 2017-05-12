use Test::More;
use lib qw( ../lib ./lib );
use Egg::Helper;

eval{ require HTML::FillInForm };
if ($@) { plan skip_all=> "HTML::FillInForm is not installed." } else {

plan tests=> 16;

ok my $e= Egg::Helper->run( Vtest=> {
  vtest_plugins=> [qw/ FillInForm /],
  }), q{ load plugin. };

can_ok $e, 'fillin_ok';
  ok $e->fillin_ok(1), q{$e->fillin_ok(1)};
  ok $e->fillin_ok, q{$e->fillin_ok};
  ok ! $e->fillin_ok(0), q{! $e->fillin_ok(0)};
  ok ! $e->fillin_ok, q{! $e->fillin_ok};

can_ok $e, 'fillform';
  isa_ok $e, 'Egg::Plugin::FillInForm';
  my $body= join '', <DATA>;
  ok my $pm= $e->request->params, q{my $pm= $e->request->params};
  ok $pm->{test1}= 'test_ok1', q{$pm->{test1}= 'test_ok1'};
  ok $pm->{test2}= '1', q{$pm->{test2}= '1'};
  ok $pm->{test3}= '1', q{$pm->{test3}= '1'};
  ok $e->fillform(\$body), q{$e->fillform(\$body)};

my $check_code= sub {
	my($key, $value)= @_;
	for (split /\n/, $body) {
		/name=\"$key\"/    || next;
		/value=\"$value\"/ || next;
		/type=\"text\"/       and return 1;
		/checked=\"checked\"/
		 and ( /type=\"checkbox\"/ or /type=\"radio\"/ ) and return 1;
	}
  };

ok $check_code->( test1 => 'test_ok1' ), q{$check_code->( test1 => 'test_ok1' )};
ok $check_code->( test2 => 1 ), q{$check_code->( test2 => 1 )};
ok $check_code->( test3 => 1 ), q{$check_code->( test3 => 1 )};

}

__DATA__
<html>
<body>
<form method="POST" action="/">
<input type="text" name="test1" />
<input type="checkbox" name="test2" value="1" />
<input type="radio" name="test3" value="1" />
</form>
</body>
</html>
