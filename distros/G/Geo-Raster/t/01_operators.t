use POSIX;
use Test::More qw(no_plan);

BEGIN { 
    use_ok( 'Geo::Raster' );
}

$a = Geo::Raster->new(10,10);
$a+=10;
ok($a->get(1,1) == 10,'+=');

sub diff {
    my ($a1,$a2) = @_;
    #print "$a1 == $a2?\n";
    return 0 unless defined $a1 and defined $a2;
    my $test = abs($a1 - $a2);
    $test /= $a1 unless $a1 == 0;
    abs($test) < 0.01;
}

# test overloaded operators and then some
# integer and real grids 
# grid arg, real arg, integer arg
my %ret = (neg=>1,plus=>1,minus=>1,times=>1,over=>1,modulo=>1,power=>1,add=>1,
	   subtract=>1,multiply_by=>1,divide_by=>1,modulus_with=>1,to_power_of=>1,
	   lt=>1,gt=>1,le=>1,ge=>1,eq=>1,ne=>1,cmp=>1,
	   atan2=>1,cos=>1,sin=>1,exp=>1,abs=>1,log=>1,sqrt=>1,round=>1,
	   acos=>1,atan=>1,ceil=>1,cosh=>1,floor=>1,log10=>1,sinh=>1,tan=>1,tanh=>1,
	   not=>1,and=>1,or=>1,
	   min=>1,max=>1);
my %args = (neg=>0,plus=>1,minus=>1,times=>1,over=>1,modulo=>1,power=>1,add=>1,
	    subtract=>1,multiply_by=>1,divide_by=>1,modulus_with=>1,to_power_of=>1,
	    lt=>1,gt=>1,le=>1,ge=>1,eq=>1,ne=>1,cmp=>1,
	    atan2=>1,cos=>0,sin=>0,exp=>0,abs=>0,log=>0,sqrt=>0,round=>0,
	    acos=>0,atan=>0,ceil=>0,cosh=>0,floor=>0,log10=>0,sinh=>0,tan=>0,tanh=>0,
	    not=>0,and=>1,or=>1,
	    min=>1,max=>1);
my %operator = (neg=>'-',plus=>'+',minus=>'-',times=>'*',over=>'/',modulo=>'%',power=>'**',add=>'+=',
		subtract=>'-=',multiply_by=>'*=',divide_by=>'/=',modulus_with=>'%=',to_power_of=>'**=',
		lt=>'<',gt=>'>',le=>'<=',ge=>'>=',eq=>'==',ne=>'!=',cmp=>'<=>',
		not=>'!',and=>'&&',or=>'||');

for my $method ('neg','plus','minus','times','over','modulo','power','add',
		'subtract','multiply_by','divide_by','modulus_with','to_power_of',
		'lt','gt','le','ge','eq','ne','cmp',
		'atan2','cos','sin','exp','abs','log','sqrt','round',
		'acos','atan','ceil','cosh','floor','log10','sinh','tan','tanh',
		'not','and','or',
		'min','max') {

#    exit if $method eq 'subtract';
#    next if $method eq 'atan2';
    next if $method eq 'and';
    next if $method eq 'or';

    for my $datatype1 ('int','real') {
	my $gd1 = new Geo::Raster($datatype1,10,10);
	$gd1->set(5);

	$operator{$method} = '' unless defined $operator{$method};

	if ($args{$method} and $operator{$method}) {

	    if ($ret{$method}) {
		
		for my $a1 ('ig','rg',13.56,4) {

		    my $arg= $a1;
		    if ($a1 eq 'ig') {
			$datatype2 = 'int';
			$arg = '$gd2';
		    } elsif ($a1 eq 'rg') {
			$datatype2 = 'real';
			$arg = '$gd2';
		    } else {
			next if $method eq 'atan2';
		    }

		    my $gd2 = new Geo::Raster($datatype2,10,10);
		    
		    $gd1->set(5) if $method eq 'to_power_of';
		    $gd2->set(2);

		    next if (($method =~ /^modul/) and 
			     ($datatype1 eq 'real' or $datatype2 eq 'real'));

		    mytest($method,$gd1,$gd2,$arg,1);

		}
	    } else {
		die "did not expect this";
	    }
	} else {
	    if ($ret{$method}) {
		mytest($method,$gd1,'','',2);
	    } else {
		die "did not expect this";
	    }
	}
    }
    $sub_tests = 0 if $method eq 'lt';
    $sub_tests = 0 if $method eq 'not';
}

sub round {
    my $number = shift;
    return int($number + 0.5);
}

sub min {
    my $a = shift;
    my $b = shift;
    return $a < $b ? $a : $b;
}

sub max {
    my $a = shift;
    my $b = shift;
    return $a > $b ? $a : $b;
}

sub mytest {
    my($method,$gd1,$gd2,$arg,$o) = @_;

    my $ret;
    my $comp;

    return if $method eq 'max' and $o != 1;
    return if $method eq 'min' and $o != 1;
    return if $method eq 'not' and $gd1->data_type ne 'Integer';
    return if $method eq 'atan2' and $gd1->data_type ne 'Real';
    return if $method eq 'atan2' and (!$gd2 or $gd2->data_type ne 'Real');
    return if $method eq 'floor' and $gd1->data_type ne 'Real';
    return if $method eq 'ceil' and $gd1->data_type ne 'Real';
    
    if ($method eq 'acos') {
	$gd1->set(1);
    }

    my $val = $gd1->cell(3,3);

    if ($o == 1) {
	my $a = $arg;
	$a = $gd2->cell(3,3) if $arg eq '$gd2';
	$op1 = "\$val $operator{$method} $a";
	$op2 = "$method(\$val,$a)";
	$op2 = "round($op2)" if $gd1->data_type eq 'Integer';
    } else {
	$op1 = "$operator{$method} $val";
	$op2 = "$method(\$val)";
    }

    my $op = $operator{$method} ? $op1 : $op2;

    my $eval = "\$ret = \$gd1->$method($arg); \$comp = $op";

    $gd1->{NAME} = 'gd1';

    eval $eval;

    #print STDERR "$eval\n";
    my $r = $ret->cell(3,3);
    ok(diff($comp,$r), "$method");
}

{
    for my $datatype1 ('int','real') {
	my $a = new Geo::Raster($datatype1,5,10);
	$a->{NAME} = 'a';
	$a->multiply_by(1);
	for ('+=','-=','*=','/=') {
	    my $eval = "\$a $_ 1;";
	    eval $eval;
	    ok($a->{NAME} eq 'a',"keep attr in $_ ($a->{NAME})");
	}
	for ('+','-','*','/') {
	    my $b;
	    my $eval = "\$b = \$a $_ 1;";
	    eval $eval;
	    ok($a->{NAME} eq 'a',"keep attr in $_");
	}
    }
}

{
    for my $datatype1 ('int','real') {
	my $a = new Geo::Raster($datatype1,5,10);
	for my $datatype2 ('int') { #,'real') {
	    my $b = new Geo::Raster($datatype2,5,10);
	    for my $datatype3 ('','i','int','real') {
		print "a\n";
		my $c = new Geo::Raster($datatype3,5,10) if $datatype3 ne '';
		$c = 4 if $datatype3 eq '';
		$c = {0=>1,6=>2} if $datatype3 eq 'i';
		
		print "b\n";
		$a->set(1);
		print "c\n";
		$b->rect(2,2,4,6);

		print "d\n";
		$d = $a->if($b,$c);
		print "e\n";
		$s = $d->sum;
		ok(diff($s,50),"if then (else)");

		$a->if($b,$c);
		$s = $a->sum;
		ok(diff($s,50),"if then (else)");

	    }
	}
    }
}

