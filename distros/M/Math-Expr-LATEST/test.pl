# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "Compilation 1..1\n"; }
END {print "not ok 1\n" unless $loaded;}

require Math::Expr::Rule;
require Math::Expr::FormulaDB;
use Math::Expr;
require Math::Expr::OpperationDB;

$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$|=1;

$parse=[
			 ['a+b*c',
				'+(a:Real,*(b:Real,c:Real))',
				'a+b*c',
				'<math><mrow><mi>a</mi><mo>+</mo><mrow><mi>b</mi><mo>*</mo><mi>c</mi></mrow></mrow></math>'],
			 ['(a+b)*c',
				'*(+(a:Real,b:Real),c:Real)',
				'(a+b)*c',
				'<math><mrow><mrow><mo fence="true">(</mo><mrow><mi>a</mi><mo>+</mo><mi>b</mi></mrow><mo fence="true">)</mo></mrow><mo>*</mo><mi>c</mi></mrow></math>'],
			 ['a*b+c',
				'+(*(a:Real,b:Real),c:Real)',
				'a*b+c',
				'<math><mrow><mrow><mi>a</mi><mo>*</mo><mi>b</mi></mrow><mo>+</mo><mi>c</mi></mrow></math>'],
			 ['a*(b+c)',
				'*(a:Real,+(b:Real,c:Real))',
				'a*(b+c)',
				'<math><mrow><mi>a</mi><mo>*</mo><mrow><mo fence="true">(</mo><mrow><mi>b</mi><mo>+</mo><mi>c</mi></mrow><mo fence="true">)</mo></mrow></mrow></math>'],
			 ['1=a+b-c*d/a^d',
				'=(1,+(a:Real,-(b:Real,*(c:Real,/(d:Real,^(a:Real,d:Real))))))',
				'1=a+b-c*d/a^d',
				'<math><mrow><mn>1</mn><mo>=</mo><mrow><mi>a</mi><mo>+</mo><mrow><mi>b</mi><mo>-</mo><mrow><mi>c</mi><mo>*</mo><mfrac> <mi>d</mi> <msup><mrow><mi>a</mi></mrow><mi>d</mi></msup>  </mfrac></mrow></mrow></mrow></mrow></math>'],
			 ['1=a+b-c*(d/a)^d',
				'=(1,+(a:Real,-(b:Real,*(c:Real,^(/(d:Real,a:Real),d:Real)))))',
				'1=a+b-c*(d/a)^d',
				'<math><mrow><mn>1</mn><mo>=</mo><mrow><mi>a</mi><mo>+</mo><mrow><mi>b</mi><mo>-</mo><mrow><mi>c</mi><mo>*</mo><msup><mrow><mrow><mo fence="true">(</mo><mfrac> <mi>d</mi> <mi>a</mi>  </mfrac><mo fence="true">)</mo></mrow></mrow><mi>d</mi></msup></mrow></mrow></mrow></mrow></math>'],
			 ['1=a+b-c*sin(d)/a^d',
				'=(1,+(a:Real,-(b:Real,*(c:Real,/(sin(d:Real),^(a:Real,d:Real))))))',
				'1=a+b-c*sin(d)/a^d',
				'<math><mrow><mn>1</mn><mo>=</mo><mrow><mi>a</mi><mo>+</mo><mrow><mi>b</mi><mo>-</mo><mrow><mi>c</mi><mo>*</mo><mrow><mrow><mi fontstyle="normal">sin</mi><mo fence="true">(</mo><mi>d</mi><mo fence="true">)</mo></mrow><mo>/</mo><msup><mrow><mi>a</mi></mrow><mi>d</mi></msup></mrow></mrow></mrow></mrow></mrow></math>']];

print "Parse 0.." . $#{$parse} . "\n";

SetOppDB(new Math::Expr::OpperationDB('db/Opperations/Realtal'));

for ($i=0; $i<= $#{$parse}; $i++) {
	$e=Parse($parse->[$i][0]);
	$a=$e->tostr;
	$b=$e->toText;
	$c="<math>".$e->toMathML."</math>";
	if ($a eq $parse->[$i][1] && $b eq $parse->[$i][2] && $c eq $parse->[$i][3]){
		print "ok $i\n";
	} else {
		print "not ok $i\n";
	}
}

$rule = [
				 ['(a+b)*d','a*d+b*d','(a-b)*d',
					'+(*(a:Real,d:Real),*(d:Real,neg(b:Real)))'],
				 ['(i+j)*k','i*k+j*k','(a-b-c)*d',
					'+(*(+(a:Real,neg(b:Real)),d:Real),*(d:Real,neg(c:Real)))§§+(*(+(a:Real,neg(c:Real)),d:Real),*(d:Real,neg(b:Real)))§§+(*(+(neg(b:Real),neg(c:Real)),d:Real),*(a:Real,d:Real))'],

				 ['a*a','a^2','b*b','^(b:Real,2)'],
				 ['a*a','a^2','2*2','^(2,2)'],
				 ['a*a','a^2','(a+b)*(b+a)','^(+(a:Real,b:Real),2)'],
				 ['inv(c)*inv(d)', 'inv(a*b)', 'inv(a)*inv(b)*c', 
					'*(c:Real,inv(*(a:Real,b:Real)))'],
				 ['a','sqrt(a^2)','a*b',
					'*(a:Real,sqrt(^(b:Real,2)))§§sqrt(^(*(a:Real,b:Real),2))§§*(b:Real,sqrt(^(a:Real,2)))'],
				 ['a', 'sqrt(a^2)', 'inv(a)*inv(b)*c', 'c*sqrt((inv(a)*inv(b))^2)§§sqrt((c*inv(a)*inv(b))^2)§§inv(a)*sqrt((c*inv(b))^2)§§inv(b)*sqrt((c*inv(a))^2)§§c*inv(a)*inv(sqrt(b^2))§§c*inv(b)*inv(sqrt(a^2))§§c*inv(a)*sqrt(inv(b)^2)§§c*inv(b)*sqrt(inv(a)^2)§§inv(a)*inv(b)*sqrt(c^2)','txt'],
				 ['1', 'b/b', '1', '*(inv(q:Real),q:Real)','pre'],
				 ['1', 'b/b', 'a+b*1', 'b*inv(q)*q+a','pre','txt'],
				 ['a*b', 'a*b', 'a*b', '', 'pre'],
				];

print "Applying rules 0.." . $#{$rule} . "\n";

for ($i=0; $i<= $#{$rule}; $i++) {
	$f=Parse($rule->[$i][0]); $f=$f->Simplify;
	$t=Parse($rule->[$i][1]); $t=$t->Simplify;
	$e=Parse($rule->[$i][2]); $e=$e->Simplify;

	$r=new Math::Expr::Rule($f, $t);
	$str="";

	$pri=undef;
	if ($rule->[$i][4] eq 'pre') {
		$pri=new Math::Expr::VarSet;
		$pri->Set('b', new Math::Expr::Var('q'));
		$rule->[$i][4]=$rule->[$i][5];
	}

	foreach ($r->Apply($e,$pri)) {
		if ($rule->[$i][4] eq 'txt') {
			$str.='§§'.$_->toText;
		} else {
			$str.='§§'.$_->tostr;
		}
	}
	$str=~ s/^§§//;
#	print $str . "\n";

	if(comp($str,$rule->[$i][3])) {
		print "ok $i\n";
	} else {
		print "not ok $i\n";
	}
}

sub comp {
	my ($a, $b)=@_;
	my %t;
	my @a;

	foreach (split(/§§/, $a)) {
		$t{$_}=1;
	}

	foreach (split(/§§/, $b)) {
		if ($t{$_}) {
			delete $t{$_};
		} else {
			return 0;
		}
	}

	@a=keys %t;
	if ($#a>-1) {
		return 0;
	} else {
		return 1;
	}
}
