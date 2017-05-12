# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use warnings;
use Test::More tests => 12;
use HTML::YaTmpl;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $t=HTML::YaTmpl->new;

sub t {
  my ($got, $expected, $name)=@_;
  print "# expected: '$got'\n";
  print "# got: '$got'\n";
  ok $got eq $expected, $name;
}

ok( $t, 'new object' );

$t->template="aaaaaa";
t $t->evaluate, "aaaaaa", 'no subst';

$t->template="a<=abc/>a<=abc code=\"<:/>\"/>a<=xyz/>a<=xyz/>a";
ok(( $t->evaluate( abc=>'hallo', xyz=>'bello' ) eq
     "ahalloahalloabelloabelloa" )=>'simple subst');

$t->template=<<'EOF';
a<=abc code=":<: ucfirst $v />:"/>a<=abc p1 p2 p3>:<: uc $v />:</=abc>a
b<=xyz code="<:\":\\u$v:\"/>"/>b<=xyz><:':'."\U$v".':'/></=xyz>b
b<=xyz code="<:\":\\u$v:\"/>"/>b<=xyz><:':'.qq{\U$v}.':'/></=xyz>b
EOF

ok(( $t->evaluate( abc=>'hallo', xyz=>'bello' ) eq
     "a:Hallo:a:HALLO:a\nb:Bello:b:BELLO:b\nb:Bello:b:BELLO:b\n" )
   =>'perl eval');

{ no warnings 'once';
  $x::sub=sub {
    ucfirst shift;
  };
  sub x::my_ucfirst {
    ucfirst shift;
  }
}

$t->package='x';
$t->template=<<'EOF';
a<=abc code=":<: my_ucfirst($v) />:"/>a<=abc>:<: my @x=(1=>2); uc $v />:</=abc>a
b<=xyz code="<:$x::sub->(\":\\u$v:\")/>"/>b<=xyz><:':'."\U$v".':'/></=xyz>b
EOF

ok(( $t->evaluate( abc=>'hallo', xyz=>'bello' ) eq
     "a:Hallo:a:HALLO:a\nb:Bello:b:BELLO:b\n" )=>'perl code with -> and =>');

$t->template=<<'EOF';
a<=abc pre="pre" post="post"/>a<=abc><:pre>pre</:pre><:post>post</:post>:<: uc $v />:</=abc>a
EOF
ok(( $t->evaluate( abc=>'hallo', xyz=>'bello' ) eq
     "ahalloa:HALLO:a\n" )=>'pre/post');

$t->template=<<'EOF';
a<=abc type="array,empty" pre="pre" post="post"/>a
a<=undef type="array,empty" code="undef is empty"/>a
a<=empty type="array,empty">empty is empty</=empty>a
a<=earray type="array,empty">earray i<:/>s empty</=earray>a
a<=abc type="scalar,empty" pre="pre" post="post"/>a
a<=array type="scalar"><:pre>pre</:pre><:post>post</:post>:<: uc $v />:</=array>a
a<=array type="empty"><:pre>pre</:pre><:post>post</:post>:<: uc $v />:</=array>a
a<=array type="array"><:pre>pre</:pre><:post>post</:post>:<: uc $v />:</=array>a
a<=earray type="array"><:pre>pre</:pre><:post>post</:post>:<: uc $v />:</=earray>a
a<=array type="array"
         sort="$a cmp $b"
         map="qq{.$_.}"
         grep="!/klaus/i"
><:pre>pre</:pre><:post>post</:post>:<: uc $v />:</=array>a
EOF

ok(( $t->evaluate( abc=>'hallo',
		   xyz=>'bello',
		   array=>[qw{klaus heinz otto martin}],
		   earray=>[],
		   empty=>'' ) eq <<'EOF' )=>'type/map/sort/grep');
aa
aundef is emptya
aempty is emptya
aearray is emptya
ahalloa
aa
aa
apre:KLAUS::HEINZ::OTTO::MARTIN:posta
aa
apre:.HEINZ.::.MARTIN.::.OTTO.:posta
EOF

$t->template='a<=list><:for a="<: $v->{a} />" b="<:/>"><=a/><=b><: $v->{b} /></=b></:for></=list>b';
t $t->evaluate( list=>[
		       +{a=>'a1', b=>'b1'},
		       +{a=>'a2', b=>'b2'},
		      ] ), "aa1b1a2b2b", 'list of hash values';

$t->template='a<=scalar type=given>blub</=scalar>b';
t $t->evaluate( scalar=>'x' ), 'ablubb', 'type=given with non-empty scalar';

$t->template='a<=scalar type=given>blub</=scalar>b';
t $t->evaluate( scalar=>'' ), 'ab', 'type=given with empty scalar';

$t->template='a<=list type=given>blub</=list>b';
t $t->evaluate( list=>['x', 'y'] ), 'ablubb', 'type=given with non-empty list';

$t->template='a<=list type=given>blub</=list>b';
t $t->evaluate( list=>[] ), 'ab', 'type=given with empty list';

# Local Variables:
# mode: cperl
# End:
