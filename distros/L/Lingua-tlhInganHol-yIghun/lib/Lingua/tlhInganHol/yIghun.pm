package Lingua::tlhInganHol::yIghun;

use strict;
use warnings;

use Carp;
use Filter::Simple;

our $VERSION = '20090601';
my $DEBUG;
my $HONOURABLE = 1;

$DB::single=1;

my %numword = ( 0 => q{pagh},
                1 => q{wa'},
                2 => q{cha'},
                3 => q{wej},
                4 => q{loS},
                5 => q{vagh},
                6 => q{jav},
                7 => q{Soch},
                8 => q{chorgh},
                9 => q{Hut},
                10 => q{maH},
                100 => q{vatlh},
                1000 => q{SaD},
                10000 => q{netlh},
                100000 => q{bIp},
                1000000 => q{'uy'},
            );

my %val = reverse %numword;

my $numword = '(?='. join('|',values %numword) . ')';
$numword{unit} = '(?:'. join('|',@numword{0..9}) . ')';

my $number = qr{  $numword
		  (?:($numword{unit})($numword{+1000000}))? [ ]*
                  (?:($numword{unit})($numword{+100000}))? [ ]*
                  (?:($numword{unit})($numword{+10000}))? [ ]*
                  (?:($numword{unit})($numword{+1000}))? [ ]*
                  (?:($numword{unit})($numword{+100}))? [ ]*
                  (?:($numword{unit})($numword{+10}))? [ ]*
                  (?:($numword{unit}?) (?!$numword))? [ ]*
		  (  DoD [ ]* (?:$numword{unit} [ ]+)+ )?
                }xi;

sub to_Terran
{
    return "" unless $_[0];
    my @bits = $_[0] =~ $number or return;
    my @decimals = split /\s+/, ($bits[-1] && $bits[-1] =~ s/^DoD\s*// ? pop @bits : 'pagh');
    my ($value,$unit,$order) = 0;
    $value += $val{$unit||$order&&"wa'"||"pagh"} * $val{$order||"wa'"}
	while ($unit, $order) = splice @bits, 0, 2;
    $order = 0.1;
    foreach $unit (@decimals) {
	    $value += $val{$unit} * $order;
	    $order /= 10;
    }
    return $value;
}

sub from_Terran
{
    my ($number, $decimal) = split /[.]/, $_[0];
    my @decimals = $decimal ? split(//, $decimal) : ();
    my @bits = split //, $number;
    return $numword{0} unless grep $_, @bits;
    my $order = 1;
    my @numwords;
    my $last;
    for (reverse @bits) {
        next unless $_;
        push @numwords, $numword{$_};
        $numwords[-1] .= $numword{$order} if $order > 1;
    }
    continue { $order *= 10 }
    @decimals = map($numword{$_}, @decimals);
    unshift @decimals, 'DoD' if @decimals;
    return join " ", reverse(@numwords), @decimals;
}

sub print_honourably {
	my $handle = ref($_[0]) eq 'GLOB' ? shift : undef;
	@_ = $_ unless @_;
	my $output = join "", map {defined($_) ? $_ : ""} @_;
	# $output =~ s{(\d+)[.](\d+)}
		    # {from_Terran($1).' DoD '.map {from_Terran($_)} split '',$2}e;
	$output =~ s{(\d+(.\d+)?)}{from_Terran($1)}e;
	if ($handle) { print {$handle} $output }
	else         { print $output }
}

sub readline_honourably {
	my $handle = ref($_[0]) eq 'GLOB' ? shift : undef;
	my $input;
	if ($handle) { $input = readline $handle }
	else         { $input = readline }
	return unless defined $input;
	$input =~ s{($number)\s*DoD((\s*$number)+)}
		   {to_Terran($1) . '.' .
		    map {to_Terran($_)} grep /\S/, split /($number)/,$2}e;
	$input =~ s{($number)}{to_Terran($1)}e;
	return $input;
}

my $EOW = qr/(?![a-zA-Z'])/;

sub enqr {
	my $pattern = join '|', @_;
	return qr/((?:$pattern)$EOW)/;
}

sub inqr {
	my $pattern = join '|', @_;
	return qr/($pattern)/;
}

my %n_decl = qw(
	yoS		package	
);
my $n_decl = enqr keys %n_decl;
sub to_decl {
	my ($name, $cmd) = @_;
	return "$cmd->{trans} $name->{trans}";
}

my %sub_decl = qw(
	nab		sub	
);
my $sub_decl = enqr keys %sub_decl;
sub to_sub_decl {
	my ($block, $name, $cmd) = @_;
	return "$cmd->{trans} $name->{trans}" unless $block->{trans};
	return "$cmd->{trans} $block->{trans}" unless $name->{trans};
	return "$cmd->{trans} $name->{trans} $block->{trans}";
}

my %v_usage = qw(
	lo'		use	
	lo'Qo'		no	
);
my $v_usage = enqr keys %v_usage;
sub to_usage {
	my ($name, $cmd) = @_;
	return "$cmd->{trans} $name->{trans}";
}

my %v_go = qw(
	jaH		goto
	yInargh		last	
	yItaH		next 	
	yInIDqa'	redo	
);
my $v_go = enqr keys %v_go;
sub to_go {
	my ($name, $cmd) = @_;
	$name||={trans=>""};
	return "$cmd->{trans} $name->{trans}";
}

my %v_listop = qw(
	mISHa'		sort	
	wIv		grep	
	choH		map	
);
my $v_listop = enqr keys %v_listop;
sub to_listop {
	my ($block, @list) = @_;
	my $op = pop @list;
	return join " ", map("$_->{trans} ", $op, $block),
		join ",", map $_->{trans}, @list;
}


my %v_blockop = qw(
	chov		eval	
	vang		do	
);
my $v_blockop = enqr keys %v_blockop;
sub to_blockop {
	my ($block, $op) = @_;
	return "$op->{trans} $block->{trans}";
}

my %v_match = qw(
	ghov		m	
);
my $v_match = enqr keys %v_match;
sub to_match {
	my ($expr, $pattern, $op) = @_;
	$pattern->{trans} =~ s/^qq?<|>$//g;
	return "$expr->{trans} =~ $op->{trans}<$pattern->{trans}>";
}

my %v_change = qw(
	tam		s	
	mugh		tr	
);
my $v_change = enqr keys %v_change;
sub to_change {
	my ($expr, $becomes, $pattern, $op) = @_;
	$pattern->{trans} =~ s/^qq?<|>$//g;
	$becomes->{trans} =~ s/^qq?<|>$//g;
	return "$expr->{trans} =~ $op->{trans}<$pattern->{trans}><$becomes->{trans}>";
}

my %v_arg0 = qw (
	laD		readline
	chaqpoDmoH	chomp	
	poDmoH		chop	
	HaD		study	
	chImmoH		undef	
	Say'moH		reset	
	mIS		rand	
	juv		length	
	toq'a'		defined	
	rIn'a'		eof	
	ghomneH		wantarray
	mej		exit	
	Hegh		die	
	ghuHmoH		warn	
	pa'Hegh		Carp::croak
	pa'ghuHmoH	Carp::carp
	pongwI'		caller	
	buv		ref	
	Del		stat	
	ghum		alarm	
	mol		dump	
	bogh		fork	
	Qong		sleep	
	loS		wait	
	mach		lc	
	wa'Dichmach	lcfirst	
	tIn		uc	
	wa'DichtIn	ucfirst	
	nargh		quotemeta
);
my $v_arg0 = enqr keys %v_arg0;

my %v_arg1 = qw (
	tlhoch		not	
	noD		reverse		
	HaD		study	
	ja'		tell	
	Such		each	
	lI'a'		exists	
	pong		keys	
	'ar		abs	
	joqtaH		sin	
	joqtaHHa'	cos	
	poD		int	
	maHghurtaH	log	
	lo'Sar		sqrt	
	mIS		rand	
	mIScher		srand	
	mach		lc	
	wa'Dichmach	lcfirst	
	tIn		uc	
	wa'DichtIn	ucfirst	
	nargh		quotemeta
	juv		length	
	sIj		split	
	toq'a'		defined	
	mob		scalar	
	lo'laH		values	
	rIn'a'		eof	
	chov		eval	
	mej		exit	
	Hegh		die	
	ghuHmoH		warn	
	pa'Hegh		Carp::croak
	pa'ghuHmoH	Carp::carp
	pongwI'		caller	
	buv		ref	
	bagh'a'		tied	
	poQ		require	
	ghomchoH	chdir	
	Sach		glob	
	teq		unlink	
	ghomtagh	mkdir	
	ghomteq		rmdir	
	Del		stat	
	ghum		alarm	
	mol		dump	
	tagh		exec	
	Qong		sleep	
	ra'		system	
	loS		wait	
	ghomneH		wantarray
);
my $v_arg1 = enqr keys %v_arg1;
sub to_arg1 {
	my ($arg, $func) = @_;
	$arg ||= {trans=>""};	# handle optional args
	return $arg->{trans}."->$func->{trans}()" if $arg->{object};
	return $func->{trans}."($arg->{trans})";
}

my %v_arg1_da = qw (
	poS		open	
	laD		readline
	bot		flock	
	nup		truncate
	chaqpoDmoH	chomp	
	poDmoH		chop	
	chImmoH		undef	
	Say'moH		reset	
	woD		pop	
	nIH		shift	
	SoQmoH		close	
	Qaw'		delete	
	baghHa'		untie	
);
my $v_arg1_da = enqr keys %v_arg1_da;
sub to_arg1_da {
	my ($arg, $func) = @_;
	$arg ||= {trans=>""};	# handle optional args
	return $arg->{trans}."->$func->{trans}()" if $arg->{object};
	return "$func->{trans} $arg->{trans}" if $arg->{type} =~ /handle$/;
	return $func->{trans}."($arg->{trans})";
}

my %v_arg2 = qw (
	qojHa'		atan2	
	So'		crypt	
	boSHa'		unpack	
	Sam		index	
	naw'choH	chmod	
	pIn'a'choH	chown	
	rar		link	
	neq		rename	
);
my $v_arg2 = enqr keys %v_arg2;
sub to_arg2 {
	my ($arg1, $arg2, $func) = @_;
	return $arg1->{trans}."->$func->{trans}($arg2->{trans})"
		if $arg1->{object};
	return "$func->{trans}($arg1->{trans}, $arg2->{trans})";
}

# my %v_arg2_i = qw (
# );
# my $v_arg2_i = enqr keys %v_arg2_i;
##  sub to_arg2_i {
	# my ($arg1, $arg2, $func) = @_;
	# return "$arg1->{trans} $func->{trans} $arg2->{trans}";
# }

my %v_arg2_da = qw (
	DoQ		bless	
	bot		flock	
);
my $v_arg2_da = enqr keys %v_arg2_da;
sub to_arg2_da {
	my ($arg1, $arg2, $func) = @_;
	return $arg1->{trans}."->$func->{trans}($arg2->{trans})"
		if $arg1->{object};
	return "$func->{trans} $arg1->{trans} ($arg2->{trans})"
		if $arg1->{type} =~ /handle$/;
	return "$func->{trans}($arg1->{trans}, $arg2->{trans})";
}

my %v_arg2_a = qw (
	DIch		[...]
	DIchvo'		[...]
	DIchvaD		[...]
	Suq		{...}
	Suqvo'		{...}
	SuqvaD		{...}
);
my $v_arg2_a = enqr keys %v_arg2_a;
sub to_arg2_a {
	my ($arg1, $arg2, $func) = @_;
	$arg1->{trans} =~ s/^(\$.*)/$1\->/;
	$arg1->{trans} =~ s/^([%@])/\$/;
	die "<<Suq>> yIlo'Qo' <<DIch>> yIlo' jay'"	# Not "Suq"! "DIch"!
		if substr($func->{raw},0,3) eq 'Suq' && $1 eq '@';
	die "<<DIch>> yIlo'Qo' <<Suq>> yIlo' jay'"	# Not "DIch"! "Suq"!
		if substr($func->{raw},0,3) eq 'DIch' && $1 eq '%';
	$func->{trans} =~ s/\Q.../$arg2->{trans}/;

	return "$arg1->{trans}$func->{trans}";
}

my %v_args = qw (
	noD		reverse		
	boS		pack	
	sIj		split	
	muv		join	
	tatlh		return	
	Hegh		die	
	ghuHmoH		warn	
	pa'Hegh		Carp::croak
	pa'ghuHmoH	Carp::carp
	tagh		exec	
	HoH		kill	
	muH		kill
	chot		kill
	bach		kill
	Hiv		kill
	DIS		kill
	jey		kill
);
my $v_args = enqr keys %v_args;
sub to_args {
	my $func = pop @_;
	my $arg1 = shift @_;
	my $args = join(",",map $_->{trans}, @_);
	return $arg1->{trans}."->$func->{trans}($args)"
		if $arg1->{object};
	$args = ",$args" if $args;
	return "$func->{trans}($arg1->{trans}$args)";
}

sub to_args_u {
	my $func = pop @_;
	my $arg1 = shift @_;
	my $args = join(",",map $_->{trans}, @_);
	return $arg1->{trans}."->$func->{trans}($args)"
		if $arg1 && $arg1->{object};
	$args = ",$args" if $args;
	return "$func->{trans}($arg1->{trans}$args)" if $arg1;
	return "$func->{trans}()";
}

sub to_args_ur {
	my $func = pop @_;
	my $arg1 = shift @_;
	my $args = join(",",map $_->{trans}, @_);
	return $arg1->{trans}."->$func->{trans}($args)"
		if $arg1 && $arg1->{object};
	$args = ",$args" if $args;
	return "$func->{trans}->($arg1->{trans}$args)" if $arg1;
	return "$func->{trans}->()";
}

my %v_args_da = qw (
	ghItlh		print	
	lagh		substr	
	yuv		push	
	DuQ		splice	
	poS		open	
	nej		seek	
	bagh		tie	
	jegh		unshift	
);
my $v_args_da = enqr keys %v_args_da;
sub to_args_da {
	my $func = pop @_;
	my $arg1 = shift @_;
	$arg1 ||= tok("","","");
	my $args = join(",",map $_->{trans}, @_);
	return $arg1->{trans}."->$func->{trans}($args)"
		if $arg1->{object};
	return "$func->{trans} $arg1->{trans} ($args)"
		if $arg1->{type} =~ /handle$/;
	$args = ",$args" if $args;
	return "$func->{trans}($arg1->{trans}$args)";
}

my %v_unop = qw (
	HUH		-
);
my $v_unop = enqr keys %v_unop;
sub to_unop {
	my ($arg, $op) = @_;
	return "$op->{trans}$arg->{trans}";
}

my %v_unop_dpre = qw (
	ghur		++
	nup 		--
);
my $v_unop_dpre = enqr keys %v_unop_dpre;
sub to_unop_dpre {
	my ($arg, $op) = @_;
	return "$op->{trans}$arg->{trans}";
}

my %v_unop_dpost = qw (
	ghurQav		++
	nupQav 		--
);
my $v_unop_dpost = enqr keys %v_unop_dpost;
sub to_unop_dpost {
	my ($arg, $op) = @_;
	return "$arg->{trans}$op->{trans}";
}

my %v_binop = qw (
	'ov		cmp	
	chel		+
	chelHa'		-
	wav		/
	HUH		*
	chen		..
	chuv		%
);
my $v_binop = enqr keys %v_binop;

my %v_binop_np = qw (
	logh		x
	je		&&
	joq		||
	pIm'a'		ne	
	rap'a'		eq	
	mI'rap'a'	==
	mI'pIm'a'	!=
);
my $v_binop_np = enqr keys %v_binop_np;

sub to_binop {
	my ($left, $right, $op) = @_;
	return "$left->{trans} $op->{trans} $right->{trans}";
}

my %v_binop_d = qw (
	nob		=
);
my $v_binop_d = enqr keys %v_binop_d;
sub to_binop_d {
	my ($left, $right, $op) = @_;
	return "$left->{trans} $op->{trans} $right->{trans}";
}

my %v_ternop = qw (
	wuq		?:
);
my $v_ternop = enqr keys %v_ternop;
sub to_ternop {
	my ($cond, $iftrue, $iffalse, $op) = @_;
	return "$cond->{trans} ? $iftrue->{trans} : $iffalse->{trans}";
}


my %control = qw(
	teHchugh	if	
	teHchughbe'	unless	
	teHtaHvIS	while	
	teHtaHvISbe'	until	
	tIqel		for	
);
my $control = enqr keys %control;
sub to_control {
	my ($block, $condition, $control) = @_;
	return "$control->{trans} ($condition->{trans}) $block->{trans}";
}

my %s_decl = qw(
	wIj		my	
	meywIj		my	
	pu'wI'		my	
	maj		our	
	meymaj		our	
	pu'ma'		our	
	vam		local	
	meyvam		local	
	pu'vam		local	
);
my $s_decl = inqr keys %s_decl;

my %noun_dat = qw(
	ghochna'	STDOUT
	luSpetna'	STDERR
);
my $noun_dat = inqr keys %noun_dat;

my %noun_acc = qw(
	juH		main	
	'oH		$_
	chevwI'		$/
	natlhwI'	$|
	bIH		@_
);
my $noun_acc = inqr keys %noun_acc;

my %noun_abl = qw(
	mungna'vo'	STDIN	
	De'Daqvo'	DATA	
);
my $noun_abl = inqr keys %noun_abl;

my @stack;
sub tok {
	my %tok;
	@tok{qw(type raw trans)} = @_;
	return \%tok;
}

sub nostop {
	my ($word) = @_;
	$word =~ s/'/Z/g;
	return $word;
}

sub pushtok {
	my ($type, $raw, $trans) = @_;
	print STDERR qq{Treated "$raw" as $type meaning "$trans"\n} if $DEBUG;
	my $object;
	$object = $type = 'dat' if $type eq 'object';
	if ($type eq 'acc' && @stack && $stack[-1]{type} eq 'noun_conj') {
		my $conj = pop @stack;
		my $left = pop @stack;
		push @stack, tok('acc', "$left->{raw} $conj->{raw} $raw",
				 "$left->{trans} $conj->{trans} $trans");
	}
	else {
		push @stack, tok($type, @_[1..$#_]);
	}
	object() if $object;
	# use Data::Dumper 'Dumper';
	# print STDERR Dumper [ \@stack ] if $DEBUG;
	return $stack[-1];
}

sub top {
	return unless @stack and grep $_ eq $stack[-1]{type}, @_;
	pop @stack;
}

sub translate {
	my $raw = join " ", map { ref $_ ? $_->{raw} : $_ } @_;
	my $what = (caller(1))[3];
	$what =~ s/.*:://;
	no strict 'refs';
	my $trans = "to_$what"->(@_);
	return ($raw, $trans);
}

sub decl {
	my ($decl) = @_;
	my $name = top('acc')
		or die "$decl: pong Sambe'!\n" ;	# missing name
	$name->{trans} = nostop($name->{raw});
	$decl = tok('adj',$decl,$n_decl{$decl});
	pushtok('cmd', translate($name,$decl));
}

sub sub_decl {
	my ($decl) = @_;
	die "$decl: pong ngoqghom joq Sambe'!\n"	# missing name or block
		unless @stack;
	my $name = pop @stack;
	my $block;
	if ($name->{type} eq 'block') {
		$block = $name;
		$name  = tok("","","");
	}
	else {
		$block = top('block') || tok("","","");
	}
	$name->{trans} = nostop($name->{raw});
	$decl = tok('verb',$decl,$sub_decl{$decl});
	if ($name->{trans}) { pushtok('cmd', translate($block,$name,$decl)) }
	else 		    { pushtok('acc', translate($block,$name,$decl)) }
}

sub usage {
	my ($use) = @_;
	my $name = top('acc')
		or die "$use: pong Sambe'!\n";		# missing name
	$name->{trans} = $name->{raw};
	$use = tok('verb',$use,$v_usage{$use});
	pushtok('cmd', translate($name,$use));
}

sub go {
	my ($go) = @_;
	my $label = top('acc');
	$label->{trans} = $label->{raw};
	$go = tok('verb',$go,$v_go{$go});
	pushtok('cmd', translate($label,$go));
}

sub listop {
	my ($op) = @_;
	my @list;
	while (@stack) {
		unshift @list, top('acc','block')
			|| die "$op: ngoqghom Sambe'!\n"; # missing codegroup
		last if $list[0]{type} eq 'block';
	}
	$op = tok('verb',$op,$v_listop{$op});
	pushtok('acc', translate(@list,$op));
}

sub blockop {
	my ($op) = @_;
	my $name = top('acc','block')
		or die "$op: ngoqghom Sambe'!\n" ;	# missing codegroup
	$op = tok('verb',$op,$v_blockop{$op});
	pushtok('acc', translate($name,$op));
}

sub match {
	my ($op) = @_;
	my $pattern = top('acc')
		or die "$op: nejwI' Sambe'!\n" ;	# missing probe
	my $expr = top('acc')
		or die "$op: De' Sambe'!\n" ;		# missing data
	$op = tok('verb',$op,$v_match{$op});
	pushtok('acc', translate($expr,$pattern,$op));
}

sub change {
	my ($op) = @_;
	my $becomes = top('acc')
		or die "$op: tamwI' Sambe'!\n" ;	# missing substitution
	my $pattern = top('acc')
		or die "$op: nejwI' Sambe'!\n" ;	# missing probe
	my $expr = top('dat')
		or die "$op: DoS Sambe'!\n" ;		# missing data
	$op = tok('verb',$op,$v_change{$op});
	pushtok('acc', translate($expr,$becomes,$pattern,$op));
}

sub arg1 {
	my ($func) = @_;
	my $arg = top('acc') 
		or $func->{raw} =~ /$v_arg0/
		or die "$func: De' Sambe'!\n" ;        # missing data
	$func = tok('verb',$func,$v_arg1{$func});
	pushtok('acc', translate($arg, $func));
}

sub arg1_da {
	my ($func) = @_;
	my $arg = top('dat','abl','dat_handle','abl_handle') 
		or $func =~ /$v_arg0/
		or die "$func: DoS ghap Hal Sambe'!\n" ;
						# missing target or source
	$func = tok('verb',$func,$v_arg1_da{$func});
	if ($HONOURABLE && $func->{trans} =~ /print|readline/) {
		$func->{trans} =
			"Lingua::tlhInganHol::yIghun::$func->{trans}_honourably";
		if ($arg && $arg->{type} =~ s/_handle$//) {
			$arg->{trans} = '\\*'.$arg->{trans};
		}
	}
	pushtok('acc', translate($arg, $func));
}

sub arg2 {
	my ($func) = @_;
	my $arg2 = top('acc')
		or die "$func: De' cha'DIch Sambe'!\n";	# missing second data
	my $arg1 = top('acc')
		or die "$func: De' wa'DIch Sambe'!\n";	# missing first data
	$func = tok('verb',$func,$v_arg2{$func});
	pushtok('acc', translate($arg1, $arg2, $func));
}

sub arg2_da {
	my ($func) = @_;
	my $arg2 = top('acc')
		or die "$func: De' Sambe'!\n";		# missing data
	my $arg1 = top('dat','abl','dat_handle','abl_handle')
		or die "$func: DoS ghap Hal Sambe'!\n";
						# missing target or source
	$func = tok('verb',$func,$v_arg2_da{$func});
	pushtok('acc', translate($arg1, $arg2, $func));
}

sub arg2_a {	# pure *a*blative
	my ($func) = @_;
	my $arg2 = top('acc')
		or die "$func: De' Sambe'!\n";	# missing data
	my $arg1 = top('abl')
		or die "$func: Hal Sambe'!\n";	# missing source
	$func = tok('verb',$func,$v_arg2_a{$func});
	pushtok($func->{raw} =~ /vaD$/ ? 'dat' :
	        $func->{raw} =~ /vo'$/ ? 'abl' : 'acc',
		translate($arg1, $arg2, $func));
}

sub unop {
	my ($func) = @_;
	my $arg1 = top('acc')
		or die "$func: De' wa'DIch Sambe'!\n";	# missing first arg
	$func = tok('verb',$func,$v_unop{$func});
	pushtok('acc', translate($arg1, $func));
}

sub unop_dpre {
	my ($func) = @_;
	my $arg1 = top('dat')
		or die "$func: DoS Sambe'!\n";		# missing target
	$func = tok('verb',$func,$v_unop_dpre{$func});
	pushtok('dat', translate($arg1,$func));
}

sub unop_dpost {
	my ($func) = @_;
	my $arg1 = top('dat')
		or die "$func: DoS Sambe'!\n";		# missing target
	$func = tok('verb',$func,$v_unop_dpost{$func});
	pushtok('dat', translate($arg1,$func));
}

sub binop {
	my ($func) = @_;
	my $arg2 = top('acc')
		or die "$func: De' cha'DIch Sambe'!\n";	# missing second arg
	my $arg1 = top('acc')
		or die "$func: De' wa'DIch Sambe'!\n";	# missing first arg
	$func = tok('verb',$func,$v_binop{$func}||$v_binop_np{$func});
	pushtok('acc', translate($arg1, $arg2, $func));
}

sub binop_d {
	my ($func) = @_;
	my $arg2 = top('acc','dat')
		or die "$func: De' Sambe'!\n";		# missing data
	my $arg1 = top('dat')
		or die "$func: DoS Sambe'!\n";		# missing target
	$func = tok('verb',$func,$v_binop_d{$func});
	pushtok('dat', translate($arg1, $arg2, $func));
}

sub ternop {
	my ($func) = @_;
	my $iffalse = top('acc')
		or die "$func: vItvaD De' Sambe'!\n";	# missing truth data
	my $iftrue = top('acc')
		or die "$func: nepvaD De' Sambe'!\n";	# missing falsehood data
	my $cond = top('acc')
		or die "$func: wuqwI' Sambe'!\n";	# missing decider
	$func = tok('verb',$func,$v_ternop{$func});
	pushtok('acc', translate($cond, $iftrue, $iffalse, $func));
}

sub args_da {
	my ($func) = @_;
	my @args;
	my $first = 1;
	while (1) {
		my $arg = top('acc','dat','abl_handle','dat_handle') or last;
		unshift @args, $arg;
		last if $arg->{type} eq 'dat';
		last if $first and $arg->{list};
		$first=0;
	}
	$func = tok('verb',$func,$v_args_da{$func});
	if ($HONOURABLE && $func->{trans} =~ /print|readline/) {
		$func->{trans} =
			"Lingua::tlhInganHol::yIghun::$func->{trans}_honourably";
		if (@args && $args[0]{type} =~ s/_handle$//) {
			$args[0]{trans} = '\\*'.$args[0]{trans};
		}
	}
	pushtok('acc', translate(@args, $func));
}

sub args {
	my ($func) = @_;
	my @args;
	my $first = 1;
	while (1) {
		my $arg = top('acc') or last;
		unshift @args, $arg;
		last if $arg->{object};
		last if $first and $arg->{list};
		$first=0;
	}
	$func = tok('verb',$func,$v_args{$func});
	if ($HONOURABLE && $func->{trans} eq 'print') {
		$func->{trans} =
			"Lingua::tlhInganHol::yIghun::$func->{trans}_honourably";
		if (@args && $args[0]{type} =~ s/_handle$//) {
			$args[0]{trans} = '\\*'.$args[0]{trans};
		}
	}
	pushtok('acc', translate(@args, $func));
}

sub args_u {
	my ($func) = @_;
	my @args;
	my $first = 1;
	while (1) {
		my $arg = top('acc','dat') or last;
		unshift @args, $arg;
		last if $first && $arg->{list};
		last if $arg->{object};
		$first = 0;
	}
	$func = tok('verb',(@args>1 ? 'tI' : 'yI').$func,$func);
	pushtok('acc', translate(@args, $func));
}

sub args_ur {
	my ($func) = @_;
	my @args;
	my $first = 1;
	while (1) {
		my $arg = top('acc','dat') or last;
		unshift @args, $arg;
		last if $first && $arg->{list};
		last if $arg->{object};
		$first = 0;
	}
	$func = tok('verb',(@args>1 ? 'tI' : 'yI').$func.'vetlh',"\$$func");
	pushtok('acc', translate(@args, $func));
}

sub control {
	my ($control) = @_;
	my $condition = top('acc','dat') 
		or die "$control: tob Sambe'!\n";	# missing test
	my $block = top('block') 
		or die "$control: ngoqghom Sambe'!\n";	# missing code group
	$control = tok('control',$control,$control{$control});
	pushtok('cmd', translate($block,$condition,$control));
}


my @translation;

sub object {
	die "'e': Doch Sambe'"
		unless @stack && $stack[-1]{type} =~ /^(acc|dat)$/;
	$stack[-1]{raw} .= " 'e'";
	$stack[-1]{object} = 1;
}

sub done {
	my $cmd = top('cmd','acc','dat')
		or die +(@stack ? "<<$stack[-1]{raw}>>Daq: " : "") .
			'rIn pIHbe!';
							# unexpected ending
	$cmd = "$cmd->{trans};\n";
	while (my $conj = top('sent_conj')) {
		my $left = top('cmd','acc','dat')
		    or die +(@stack ? "<<$stack[-1]{raw} $conj>>Daq: " : "") .
		           "ra' PoS pIHbe!";		# unexpected left cmd
		$cmd = "$left->{trans} $conj->{trans} $cmd";
	}
	$translation[-1] .= $cmd;
}

sub startblock {
	# print STDERR qq<Treated "{" as start of block\n> if $DEBUG;
	push @translation, "";
	pushtok('start of block', "{", "{");
}

sub endblock {
	print STDERR qq<Treated "}" as end of block\n> if $DEBUG;
	top('start of block') 
		or @stack and die "betleH HivtaH Sampa' veQ: $stack[0]{raw}\n "
					# garbage found before attacking batleth
		or die "betleH HivtaH Sambe'";
					# missing attacking batleth
	pushtok('block', "{...}", "{".pop(@translation)."}");
}

my %nsuff = ( "vo'"    => 'abl',
	      "vo'Hal" => 'abl_handle',
	      "Hal"    => 'abl_handle',
	      "vaD"    => 'dat',
	      "vaDDoS" => 'dat_handle',
	      "DoS"    => 'dat_handle',
	      "'e'"    => 'object',
	      ""       => 'acc' );
my $nsuff   = qr/${\join"|",reverse sort keys %nsuff}/;

sub startlist {
	pushtok('start of list','(','(');
}

sub endlist {
	my $type = $nsuff{$_[0]};
	print STDERR qq<Treated ")" as end of $type list"\n> if $DEBUG;
	my @args;
	while (1) {
		die "'etlh HivtaH Sambe'" unless @stack;
						# missing attacking sword
		my $arg = pop @stack;
		last if $arg->{type} eq 'start of list';
		unshift @args, $arg;
	}
	my $raw   = join " ", map $_->{raw}, @args;
	my $trans = join ",", map $_->{trans}, @args;

	pushtok($type, "($raw)$_[0]", "($trans)")->{list} = 1;
}

my $sing   = qr/(?:yI)?/;
my $plur   = qr/(?:tI)?/;
my $any    = qr/(?:[yt]I)?/;

my %sigil  = ( "mey" => '@', "pu'" => '%', "" => '$' );
my $type   = qr/${\join"|",reverse sort keys %sigil}/;

my %comp   = ( "tIn"     => '>',   "mach"     => '<',
               "tInbe'"  => '<=',  "machbe'"  => '<',
	       "nung"    => 'lt',  "tlha'"    => 'gt',
	       "nungbe'" => 'ge',  "tlha'be'" => 'le',
	     );
my $comp = inqr keys %comp;

sub greater {
	my ($op) = @_;
	my $arg = top('acc') or die "$op law': DIp $op Sambe'"; # missing noun
	pushtok('greater', "$arg->{raw} $op law'", "$arg->{trans} $comp{$op}");
}

sub lesser {
	my ($op) = @_;
	my $arg = top('acc')
		or die "$op puS: DIp ${op}be' Sambe'!";		# missing noun
	my $greater = top('greater')
		or die "$op puS: <<$op law'>> nung Sambe'!";
						# preceding *op* law missing
	pushtok('acc', "$greater->{raw} $arg->{raw} $op puS",
		"$greater->{trans} $arg->{trans}");
}

# my %conj_h = ( "je"  => '&&',   "joq" => '||' );
my %conj_l = ( "'ej" => 'and',  "qoj" => 'or' );

# my $conj_h = enqr keys %conj_h;
my $conj_l = enqr keys %conj_l;

# sub conj_h {
	# my ($conj) = @_;
	# die "$conj: DIp poS Sambe'!"			# missing noun on left
		# unless @stack && $stack[-1]{type} eq 'acc';
	# pushtok('noun_conj', $conj, $conj_h{$conj});
# }

sub conj_l {
	pushtok('sent_conj', $_[0], $conj_l{$_[0]});
}


FILTER {
	$DEBUG = grep /yIQIj/, @_;
	$HONOURABLE = !grep /tera('|::)nganHol/, @_;
	my $TRANS = grep /yImugh/, @_;
	@stack = ();
	$translation[0] = "";
	pos $_ = 0;
	while (pos $_ < length $_) {
		   /\G\s+(#.*|jay')?/gc	# skip ws, invective, and comments
		or /\G!/gc		and done
		or /\G$conj_l/gc	and conj_l("$1")
		# or /\G$conj_h/gc	and conj_h("$1")
		or /\G($number)/gc	and pushtok('acc',"$1",to_Terran($1))
		or /\G(<<(.*?)>>('e')?)/gc
					and pushtok($3?'object':'acc',"$1",qq{qq<$2>})
		or /\G(<(.*?)>('e')?)/gc
					and pushtok($3?'object':'acc',"$1",qq{q<$2>})
		or /\G($comp)\s+law'/gc	and greater("$1")
		or /\G($comp)\s+puS/gc	and lesser("$1")
		or /\G$n_decl/gc	and decl(nostop $1)
		or /\G$sub_decl/gc	and sub_decl(nostop $1)
		or /\G$sing$v_usage/gc	and usage("$1")
		or /\G$sing$v_go/gc	and go("$1")
		or /\G$any$v_listop/gc	and listop("$1")
		or /\G$any$v_blockop/gc	and blockop("$1")
		or /\G$sing$v_match/gc	and match("$1")
		or /\G$any$v_change/gc	and change("$1")
		or /\G$sing$v_arg1/gc	and arg1("$1")
		or /\G$sing$v_arg1_da/gc	and arg1_da("$1")
		or /\G$plur$v_arg2/gc	and arg2("$1")
		# or /\G$plur$v_arg2_i/gc	and arg2_i("$1")
		or /\G$sing$v_arg2_da/gc	and arg2_da("$1")
		or /\G$sing$v_arg2_a/gc	and arg2_a("$1")
		or /\G$any$v_args/gc	and args("$1")
		or /\G$any$v_args_da/gc	and args_da("$1")
		or /\G$sing$v_unop/gc	and unop("$1")
		or /\G$sing$v_unop_dpre/gc
					and unop_dpre("$1")
		or /\G$sing$v_unop_dpost/gc
					and unop_dpost("$1")
		or /\G$plur$v_binop/gc	and binop("$1")
		or /\G$v_binop_np/gc	and binop("$1")
		or /\G$any$v_binop_d/gc	and binop_d("$1")
		or /\G$plur$v_ternop/gc	and ternop("$1")
		or /\G$control/gc	and control("$1")
		or /\G[yt]I([^\s!]+?)vetlh$EOW/gc
					and args_ur(nostop $1)
		or /\G[yt]I([^\s!]+)/gc	and args_u(nostop $1)
		or /\G[{]/gc		and startblock
		or /\G[}]/gc		and endblock
		or /\G[(]/gc		and startlist
		or /\G[)]($nsuff)/gc	and endlist("$1")
		or /\G((\S+?)$s_decl$EOW)/gc
					and pushtok('dat', "$1",
						    "$s_decl{$3} ".
						    ($sigil{substr$3,0,3}||'$').
						    nostop $2)
		or /\G((?:nuqDaq\s+)?(\S+?)laHwI'($nsuff)$EOW)/gc
					and pushtok($nsuff{$3}, "$1",
						    "\\&".nostop $2)
		or /\G(nuqDaq\s+(\S+?)($type)($nsuff)$EOW)/gc
					and pushtok($nsuff{$4}, "$1",
						    "\\".$sigil{$3}.nostop $2)
		or /\G((\S+?)($type)vetlh($nsuff)$EOW)/gc
					and pushtok($nsuff{$4}, "$1",
						    $sigil{$3}
						    . "{".nostop($2)."}")
		or /\G(nuqDaq\s+$noun_abl($nsuff)$EOW)/gc
					and pushtok($nsuff{$3},"$1",
						    "\\*$noun_abl{$2}")
		or /\G(nuqDaq\s+$noun_dat($nsuff)$EOW)/gc
					and pushtok($nsuff{$3},"$1",
						    "\\*$noun_dat{$2}")
		or /\G($noun_abl($nsuff)$EOW)/gc
					and pushtok($nsuff{$3},"$1",
						    $noun_abl{$2})
		or /\G($noun_dat($nsuff)$EOW)/gc
					and pushtok($nsuff{$3},"$1",
						    $noun_dat{$2})
		or /\G(nuqDaq\s+$noun_acc($nsuff)$EOW)/gc
					and pushtok($nsuff{$3},"$1",
						    "\\$noun_acc{$2}")
		or /\G($noun_acc($nsuff)$EOW)/gc
					and pushtok($nsuff{$3},"$1",
						    $noun_acc{$2})
		or /\G((\S+?)($type)($nsuff)$EOW)/gc
					and pushtok($nsuff{$4},"$1",
						    "$sigil{$3}". nostop $2) 
		or /\G(.+)\b/gc		and die "<<$1>>Daq ngoq SovlaHbe'"
							# Unrecognizable code
	}
	die "ngoq tlhol:\n\t" . join(" ", map $_->{raw}, @stack) . "\n "
		if @stack;				# unprocessed code
	$_ = $translation[0];
	print STDERR and exit if $TRANS;
}
qr/^\s*(Lingua(::|')tlhInganHol(::|')yIghun)?\s*(yI)?lo'Qo'\s*!\s*$/;

1;
__END__

=pod

=head1 NAME

Lingua::tlhInganHol::yIghun - "The Klingon Language: hey you, program in it!"


=head1 SYNOPSIS

	use Lingua::tlhInganHol::yIghun;
	
	<<'u' nuqneH!\n>> tIghItlh!
	 
	{
		wa' yIQong!
		Dotlh 'oH yIHoH yInob 
			qoj <mIw Sambe'> 'oH yIHegh jay'!
		<Qapla'!\n> yIghItlh!
	} jaghmey tIqel!


=head1 DESCRIPTION

The Lingua::tlhInganHol::yIghun module allows you to write Perl in 
the original Klingon.

=head2 Introduction

The Klingon language was first explained to Terrans in 1984 by Earth-born
linguist Dr Marc Okrand. Those who dare can learn more about it at the Klingon
Language Institute (www.kli.org).

The word order in Klingon sentences is I-O-V-S: indirect object, 
(direct) object, verb, subject. For example:

=over

B<luSpetna'vaD vay' vIghItlh jIH>

I<to-STDERR something write I>

=back

Naturally, commands given in the imperative form are far more common in
Klingon. In imperative statements, such as those used for programming
instructions, word order becomes I-O-V: indirect object, (direct)
object, (imperative) verb:

=over 

B<luSpetna'vaD vay' yIghItlh!>

I<to-STDERR something (I order you to) write!>

=back

Thus, for programming, Klingon is inherently a Reverse Polish notation.


=head2 Variables

Klingon uses inflection to denote number. So the command:

=over

B<luSpetna'vaD vay' yIghItlh!>

=back
           
is:

=over

I<to-STDERR something write!>

=back

whereas:

=over

I<to STDERR some B<things> write!>

=back

is:

=over

B<luSpetna'vaD vay'mey yIghItlh!>

=back


So in Klingon scalars and arrays can have the same root name 
(just as in regular Perl):

=over

B<vay'>    ---> C<$something>

B<vay'mey> ---> C<@something>

=back

The B<-mey> suffix only refers to things incapable of speech.
If the somethings had been articulate, the inflection would 
be:

=over

B<luSpetna'vaD vay'I<pu'> yIghItlh!>

=back

From a certain point-of-view, this parallels the difference between 
an array and a hash: arrays are subscripted mutely, with dumb integers;
whereas hashes are subscripted eloquently, with quoted strings.
Since hashes are thus in some sense "articulate", they are inflected
with the B<-pu'> suffix:

=over

B<vay'>    ---> C<$something>

B<vay'mey> ---> C<@something>

B<vay'pu'> ---> C<%something>

=back

=head2 Standard variables

Some variables have special names. Specifically:

B<'oH>		C<$_>		I<it>

B<biH>		C<@_>		I<them>

B<chevwI'>	C<$/>		I<that which separates>

B<natlhwI>	C<$|>		I<that which drains>


=head2 Subscripting arrays and hashes

Numerical subscripts are just ordinals. The command:

=over

C<kill $starships[5][3];>

=back

means:

=over

I<from starships, from the 5th of them, the 3rd of them, kill it!>

=back

which, in the Warrior's Tongue, is:

=over

B<'ejDo'meyvo' vagh DIchvo' wej Dich yIHoH!>

=back

The B<DIch> tag marks an ordinal number, whilst the ablative 
B<-vo'> suffix marks something being subscripted (i.e. something
that an element is taken from).

Note that the B<-mey> suffix on the original B<'ejDo'mey>
(C<@starships>) array didn't change. This implies that the literal
back-translation is:

=over

C<kill @starships[5][3];>

=back

Thus Klingon shows its superiority, in that it already honours the new
Perl 6 sigil conventions.

Hash indices have a different tag (B<Suq>). So:

=over

C<kill $enemies{"ancient"}{'human'};>

=back

which means:

=over

I<from enemies, from the "ancient" ones, the 'human' one, kill him!>

=back

is coded as:

=over

B<jaghpu'vo' E<lt>E<lt>ancientE<gt>E<gt> Suqvo' <humanE<gt> Suq yIHoH!>

=back

Once again the B<-pu'>"I'm-a-hash" suffix is retained when subscripting,
so the literal back-translation is the Perl6ish:

=over

C<kill %enemies{"ancient"}{'human'};>

=back

=head2 Element access through references

With references, the B<DIch> or B<Suq> tag still indicates what kind 
of thing is being subscripted. So there is no need for an explicit
dereferencer. So:

=over

B<jepaHDIlIwI'vo' E<lt>E<lt>stupidE<gt>E<gt> Suqvo' wa' DIch yIHoH!>

=back

can be translated:

=over

C<kill $jeopardyPoster{"stupid"}[1];     # Perl 6 syntax>

=back

but also means:

=over

C<kill $jeopardyPoster-E<gt>{"stupid"}[1];   # Perl 5 syntax>

=back


=head2 Distinguishing lvalues

All the variables shown above were written in the (uninflected)
accusative case. This is because they were used as direct objects 
(i.e. as data).

When variables are assigned to, they become indirect objects of 
the assignment (I<give the weapon B<to me>>). This means
that targets of assignment (or any other form of modification)
must be specified in the dative case, using the B<-vaD> suffix:

=over

B<'ejDo'meyvaD wa' 'uy' chen tInob!>

C<@starships = (1..1000000);>

=back

=over

B<jaghpu'vaD (E<lt>E<lt>QIpE<gt>E<gt> wa' E<lt>E<lt>jIvE<gt>E<gt> cha') tInob!>

C<%enemies = (stupidity=E<gt>1, ignorance=E<gt>2);>

=back

=over

B<jepaHDIlIwI'vo' wa' Dichvo' E<lt>E<lt>stupidE<gt>E<gt> SuqvaD ghur!>

C<++$jeopardyPoster-E<gt>[1]{"stupid"};>

=back


=head2 Variable declarations

Variable declarations also use suffixes for lexicals:

=over

B<scalarwIj!>	--->	my $scalar;

B<arraymeywIj!>	--->	my @array;

B<hashpu'wI'!>	--->	my %hash;

=back

for package variables:

=over

B<scalarmaj!>	--->	our $scalar;

B<arraymeymaj!>	--->	our @array;

B<hashpu'ma'!>	--->	our %hash;

=back

and for temporaries:

=over

B<scalarvam!>	--->	local $scalar;

B<arraymeyvam!>	--->	local @array;

B<hashpu'vam!>	--->	local %hash;

=back

=head2 Operators and other punctuation

In general, programming Perl in the original Klingon
requires far less punctuation than in the Terran corruption.

The only punctuation components of the language are:

=over 

=item B<E<lt>> and B<E<gt>>

These are B<pach poS> (I<left claw>) and B<pach niH>
(I<right claw>). They delimit an uninterpolated
character string. For example:

=over 

B<E<lt>petaQE<gt> yiHegh!>	--->	C<die 'scum';>

=back

=item B<E<lt>E<lt>> and B<E<gt>E<gt>>

These are B<pachmey poS> (I<left claws>) and B<pachmey niH>
(I<right claws>). They delimit an interpolated
character string. For example:

=over 

B<E<lt>E<lt>petaQ\nE<gt>E<gt> yiHegh!>	--->	C<die "scum\n";>

=back

=item B<(> and B<)>

These are B<'etlh HivtaH> and B<'etlh HubtaH>
(I<attaching sword> and I<defending sword>). They are used
as grouping expressions. For example:

=over

B<xvaD wa' (cha maH yIfunc) yIlogh yInob!>	--->	C<$x = 1*func(2,10)>

=back

For standard operators and functions with fixed parameter lists, this kind
of grouping is not needed due to the RPN ordering of Klingon:

=over

B<xvaD wa' cha maH yIchel yIlogh yInob!>        --->    C<$x = 1*(2+10)>

=back

=item B<{> and B<}>

These are B<betleH HivtaH> and B<betleH HubtaH>
(I<attacking batleth> and I<defending batleth>). 
They are used to group complete statements. For example:

=over

B<x joq { 'oH yIghItlh! 'oHvaD yIghur! } yIvang!>   --->	S<$x && do{ print $_; $_++ }>

=back

=item B<#>

This is the B<tajmey gho> (I<circle of daggers>), which is used to
indicate the beginning of a comment (which then runs to the end of the
line). Its use is widely reviled as a sign of weakness.

=back

=head2 Operators

The Klingon binding of Perl does not use sniveling Terran symbols
for important operations. It uses proper words. For example:

        =                 yInob                 "give!"
        +                 tIchel                "add!"
        -                 tIchelHa'             "un-add!"
        ++...             yIghur                "increase!"
        ...++             yIghurQav             "increase afterwards!"
        ..                tIchen                "form up!"
        eq                rap'a'                "the same?!"
        ==                mI'rap'a'             "the same number?!"

For a complete list, see L<Appendix 2|"Appendix 2: Terran-thlIngan dictionary">

Note that they all appear at the end of their argument lists:

	Qapla' vum toDuj yIchel buDghach yichelHa' yInob!
	       |_| |___| |____| 
               |______________| |______| |_______| 
	|____| |_________________________________| |____|


Most of the above examples begin with B<yI-> or B<tI->.
These prefixes indicate an imperative verb referring to one or
many objects (respectively). 

Hence, assignment is B<yInob> (I<give B<it> to...>), whilst
addition is B<tIchel> (I<add B<them>>).

Of course, in the heat of coding there is often not time for these
syntactic niceties, so Lingua::tlhIngan::yIghun allows you do just
drop them (i.e. use "clipped Klingon") if you wish.


=head2 Numeric literals

Klingon uses a decimal numbering system. The
digits are: 

=over

0       B<pagh>

1       B<wa'>

2       B<cha'>

3       B<wej>

4       B<loS>

5       B<vagh>

6       B<jav>

7       B<Soch>

8       B<chorgh>

9       B<Hut> 

=back

Powers of 10 are: 

=over

10      B<maH>

100     B<vatlh>

1000    B<SaD> or B<SanID>

10000   B<netlh>

100000  B<bIp>

1000000 B<'uy'>

=back

Numbers are formed by concatenating the appropriate digit and power
of ten in a descending sequence. For example:

=over

B<yearvaD wa'SaD Hutvatlh chorghmaH loS yInob!> --->    C<$year = 1984;>

=back

Decimals are created by specifying the decimal mark (B<DoD>) then
enumerating post-decimal digits individually.
For example:

=over

B<pivaD wej DoD wa' loS wa' vagh yInob!>        --->    C<$pi = 3.1415;>

=back

=head2 References

References are created by prepending the query B<nuqDaq> (I<where is...>)
to a referent. For example:

=over

B<refvaD nuqDaq var yInob!>     --->    C<$ref = \$var;>

=back

To dereference, the appropriate
B<-vetlh>, B<-meyvetlh>, or B<-pu'vetlh> suffix
(I<that...>, I<those...>, I<those ...>) is used, depending on the
type of the referent. For example:

=over

B<refvetlh yIghItlh!>           --->    C<print ${$ref};>

B<refmeyvetlh tIghItlh!>        --->    C<print @{$ref};>

B<refpu'vetlh tIghItlh!>        --->    C<print %{$ref};>

=back

=head2 Conjunctives and disjunctives

Just as Terran Perl's conjunctive and disjunctive operators come
in two precedences, so too do those of The Warrior's Perl.

When joining expressions, the high precedence operators (B<joq> and B<je>)
are used:

=over

B<x yImI'Suq joq yIghItlh!>     --->    C<print($x || get_num();)>

B<zvaD x yIy je yInob!>         --->    C<$z = ($x && y());>

=back

Unlike all other operators in Klingon, low-precedence
conjunctives and disjunctives (i.e. those between complete commands) are infix,
not postfix. The low precedence operators are B<qoj> and B<'ej>:

=over

B<x yIghItlh qoj yImI'Suq!>     --->    C<print($x) or get_num();>

B<zvaD x yInob 'ej yIy!>        --->    C<($z = $x) or y();>

=back

Note that (as the above exampe illustrate) changing precedence often
necessitates a radical change in word order.
                

=head2 Object-oriented features

Klingon Perl does not pander to feeble Terran object-oriented sensibilities 
by treating objects and methods specially.

A method is a subroutine, so in Klingon Perl
it is called exactly like a subroutine.

The first argument of a method is special, so 
in Klingon Perl it is explicitly marked it as being special.

For example, the procedural command:

=over

B<Hich DoSmey yIbaH!>

=back

translates as:

=over 

C<fire($weapon,@targets);>

=back

To call the same subroutine as a method, with C<$weapons> as its
invocant object, it is necessary to mark the referent using the 
topicalizer B<'e'>: 

=over

B<Hich'e' DoSmey yIbaH!>

=back

This then translates as:

=over

C<$weapon-E<gt>fire(@targets);>

=back

Likewise class methods are invoked by topicalizing the class name:

=over

B<E<lt>E<lt>JaghE<gt>E<gt>>'e' yItogh yIghItlh!>

=back

which is:

=over

C<print "Enemy"-E<gt>count();>

=back

To create an object, the B<DoQ> (I<claim ownership of>) command is used:

        {
            buvwIj bIH yInIH!              # my $class = shift @_;
            De'pu'wI' bIH yInob!           # %data = @_;
            nuqDaq De' buv yIDoQ yItatlh!  # return bless \%data, $class;
        } chu' nab!			   # sub new


=head2 Comparisons

The equality comparison operators (C<==>, C<!=>, C<eq>, C<ne>) are implemented
as questions in Klingon:

=over

B<x y rap'a'>           ---> C<$x eq $y>     (I<"x y are they the same?">)

B<x y mI'rap'a'>        ---> C<$x == $y>     (I<"x y are they the same number?">)

B<x y pIm'a'>           ---> C<$x ne $y>     (I<"x y are they different?">)

B<x y mI'pIm'a'>        ---> C<$x != $y>     (I<"x y are they different numbers?">)

=back

Inequalities are expressed with a different grammatical structure in Klingon.
There is only one inequality operator, whose syntax is:

=over

B<I<expr1> I<comparator> law' I<expr2> I<comparator> puS>

=back

Literally this means:

=over

I<comparator(expr1) is many; comparator(expr2) is few>

=back

or, in other words:

=over

I<comparator(expr1) E<gt> comparator(expr2)>

=back

The comparators tlhInganHol::yIghun supports are:

=over

=item C<E<gt>> : B<tIn>

=item C<E<lt>> : B<mach>

=item C<E<gt>=> : B<machbe'>

=item C<E<lt>> : B<tInbe'>

=item C<gt> : B<tlha'>

=item C<lt> : B<nung>

=item C<ge> : B<nungbe'>

=item C<le> : B<tlha'be'>

=back

For example:

=over

B<{ E<lt>E<lt>qaplaE<gt>E<gt> yIghItlh } mebmey mach law' maH mach puS je Soj nungbe' law' E<lt>qaghE<gt> nungbe' puS teHchugh!>

C<print "qapla!" if @guests < 10 && $food ge 'qagh';>

=back

=head2 Flow control

The flow control directives are:

=over

B<teHchugh>     C<if>           I<if is true>

B<teHchughbe'>  C<unless>       I<if is not true>

B<teHtaHvIS>    C<while>        I<while being true>

B<teHtaHvISbe'> C<until>        I<while not being true>

B<tIqel>        C<for(each)>    I<consider them>

B<yIjaH>	C<goto>		I<go!>

B<yInargh>	C<last>		I<escape!>

B<yItaH>	C<next>		I<go on>

B<yInIDqa'>	C<redo>		I<try again>

=back

=head2 Builtin functions

Perl builtins are represented as imperative verbs in tlhInganHol::yIghun.
L<Appendix 1|"Appendix 1: thlIngan-Terran dictionary">
has the complete list.

As with operators, they may take B<yI-> or B<tI-> prefixes and are themselves
postfix (the verb after it's arguments).

Note that there are a suitably large number of variations on the C<kill>
command.


=head2 User-defined subroutines

A user-defined subroutine is specified in a B<betleH> delimited block,
and given a name using the B<nab> (I<procedure>) specifier. For example:

	{
		<<Qapla'!\n>> ghItlh!
	} doit nab!

means:

	sub doit {
		print "Qapla'!\n";
	}

Such subroutines are then called using the (non-optional) B<yI->
or B<tI-> prefix:

	yIdoit!

Anonymous subroutines are created by omitting the name:

	refwIj {
		<<Qapla'!\n>> ghItlh!
	} nab nob!

which is:

	my $ref = sub {
                print "Qapla'!\n";
        }

Subroutine references can also be created by suffixing a subroutine name
with B<-laHwI'> (I<one who can...>):

	refwIj doitlaHwI' nob!

Either way, the subroutine is called through a reference by appending the
B<-vetlh> suffix (I<that...">) and prepending the imperative B<yI-> or B<tI->:

	yIrefvetlh!


=head2 Pattern matching

Patterns (or B<nejwI'>) are specified using the same line-noise syntax as in
Terran Perl.

To match against a pattern, the B<ghov> verb (I<recognize>) is used:

	'oH <\d+> yIghov 'ej <<vItu'>> yIghItlh!

which means:

	$_ =~ m/\d+/ and print "found it";

Note that the value being matched against must be explicitly specified,
even if it is B<'oH>.

To substitute against a pattern, use B<tam> (I<substitute>):

	De'vaD <\d+> <\n> yItam!

which means:

	$data =~ s/\d+/\n/;

The container whose value is being substituted must be explicitly
specified (again, even if it is B<'oH>). It is also the target of the
action and thus takes the B<-vaD> suffix.


=head2 Invective operator

Klingon is a language of great emotional depth.
By comparison, programming in Terran languages is an insipid, bloodless
experience.

Of particular note is the special programming construct: B<jay'>.
In Klingon it may be appended to a sentence to enhance it's emotional
intensity. Thus:

=over

B<qaSpu' nuq 'e' yIja'!>

I<Tell me what happened!>

=back

becomes:

=over

B<qaSpu' nuq 'e' yIja' jay'!>

I<Tell me what the *#@& happened!>

=back

This useful and satisfying internal documentation technique can be
used anywhere in a tlhInganHol::yIghun program. For example:

=over

B<{ E<lt>E<lt>De' sambe'E<gt>E<gt> yIghItlh jay'! } tu' yItlhoch teHchugh!>

C<if (!$found) { *#@&-ing print "Missing data!" }>

=back


=head2 Module control options

If the module is imported with the argument B<yIQij>:

        use Lingua::tlhInganHol::yIghun "yIQij";

it runs in debugging mode.

If the module is imported with the argument B<yImugh>:

        use Lingua::tlhInganHol::yIghun "yImugh";

it demeans itself to merely translating your glorious Klingon Perl code
into a pale Terran Perl imitation.

If the module is imported with the argument B<tera'nganHol> (or
B<tera::nganHol>:

        use Lingua::tlhInganHol::yIghun "tera'nganHol";

it debases itself to output numeric values in Terran, rather than in
the original Klingon.


=head1 DIAGNOSTICS

=over 4

=item C<<< <<Suq>> yIlo'Qo' <<DIch>> yIlo' jay' >>>

Array indices take the I<ordinal> suffix B<DIch>! You fool!

=item C<<< <<DIch>> yIlo'Qo' <<Suq>> yIlo' jay' >>>

Hash keys are indicated by B<Suq>, not an ordinal! You
imbecile!

=item C<<< %s: pong Sambe'! >>>

You forgot the name of a subroutine, package, or module! You cretin!

=item C<<< %s: pong ngoqghom joq Sambe'! >>>

You forgot to specify the name of a subroutine or a raw block! You moron!

=item C<<< %s: ngoqghom Sambe'! >>>

You forgot to specify a raw block! You idiot!

=item C<<< %s: nejwI' Sambe'! >>>

You forgot to specify a pattern! You dolt!

=item C<<< %s: tamwI' Sambe'! >>>

You forgot to specify a value to be substituted! You simpleton!

=item C<<< %s: De' Sambe'! >>>

You forgot to specify an argument! You half-wit!

=item C<<< %s: De' wa'DIch Sambe'! >>>

You forgot to specify the first argument! You clod!

=item C<<< %s: De' cha'DIch Sambe'! >>>

You forgot to specify the second argument! You knucklehead!

=item C<<< %s: DoS ghap Hal Sambe'! >>>

You forgot to specify a filehandle! You oaf!

=item C<<< %s: Hal Sambe'! >>>

You forgot to specify an input filehandle! You jerk!

=item C<<< %s: wuqwI' Sambe'! >>>

You forgot to specify a boolean expression for a ternary operator! You dumbbell!

=item C<<< %s: vItvaD Sambe'! >>>

You forgot to specify an "if true" value for a ternary operator! You buffoon!

=item C<<< %s: nepvaD Sambe'! >>>

You forgot to specify an "if false" value for a ternary operator! You dope!

=item C<<< %s: tob Sambe'! >>>

You forgot to specify a test for a control statement! You dummy!

=item C<<< %s: Doch Sambe'! >>>

You forgot to specify an object! You dunce!

=item C<<< %s %sDaq: ra' PoS pIHbe! >>>

What is that command doing on the left of that conjunction?! You dimwit!

=item C<<< %s %sDaq: 'rIn pIHbe! >>>

Where is the rest of the command?! You nincompoop!

=item C<<< betleH HivtaH Sampa' veQ: %s >>>

What is that garbage before the opening brace?! You dunderhead!

=item C<<< 'etlh HivtaH Sambe' >>>

Where is the opening parenthesis? You numbskull!

=item C<<< %s puS: DIp %sbe' Sambe' >>>

Where is the variable you're comparing?! You goose!

=item C<<< %s puS: <<%s law>> nung Sambe' >>>

Where is the B<I<comparator> law'> for this comparison? You blockhead!

=item C<<< %s: DIp poS Sambe' >>>

Where is the left operand?! You chump!

=item C<<< %sDaq ngoq Sovlahbe' >>>

This code is meaningless! You nimrod!

=item C<<< ngoq tlhol: %s >>>

What is this extra code doing here?! You I<human>!

=back


=head1 AUTHOR

Damian Conway <damian@conway.org> is the original author.

Michael G Schwern <schwern@pobox.com> assisted in its escape.


=head1 REPOSITORY

The source code of this module can be taken from
L<http://github.com/schwern/lingua-tlhinganhol-yighun/tree/master>


=head1 BUGS

In this module??? I should kill you where you stand!  You speak the
lies of a tah-keck!  If a p'tahk such as you dares insult our honor
with your bug report, you will send it to
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-tlhInganHol-yIghun>!


=head1 SEE ALSO

The Klingon Language Institute <http://www.kli.org/>

The Varaq programming language <http://www.geocities.com/connorbd/varaq/>


=head1 COPYRIGHT

       Copyright (c) 2001-2009, Damian Conway. All Rights Reserved.
       This module is free software. It may be used, redistributed
           and/or modified under the same Terms as Perl itself.


=head1 Appendix 1: thlIngan-Terran dictionary

        thlIngan        Terran          
        ========        ======
        'ar             abs
        'ej             and
        'ov             cmp
        'uy'            -000000
        -DoS            <suffix indicates use as an output handle>
        -Hal            <suffix indicates use as an input handle>
        -laHwI'         \& (subroutine reference)
        -vo'            suffix indicating something indexed
        bach            kill
        bagh            tie
        bagh'a'         tied
        baghHa'         untie
        bIp             -00000
        bogh            fork
        boS             pack
        boSHa'          unpack
        bot             flock
        buv             ref
        cha'            2
        chaqpoDmoH      chomp
        chel            + (addition)
        chelHa'         - (subtraction)
        chen            ..
        chen            ..
        chevwI'         $/
        chImmoH         undef
        choH            map
        chorgh          8
        chot            kill
        chov            eval
        chuv            %
        De'Daqvo'       DATA
        Del             stat
        DIch            ...[...]
        DIchvaD         ...[...] (when it's an lvalue)
        DIchvo'         ...[...] (when it's to be further indexed)
        DIS             kill
        Dochmeyvam      @_
        Dochvam         $_
        DoQ             bless
        DuQ             splice
        ghItlh          print
        ghochna'	STDOUT (used as name -- i.e. in an open)
        ghochna'DoS     STDOUT (used as handle -- i.e. in a print)
        ghomchoH        chdir
        ghomneH         wantarray
        ghomtagh        mkdir
        ghomteq         rmdir
        ghov            m
        ghuHmoH         warn
        ghum            alarm
        HaD             study
        Hegh            die
        Hiv             kill
        HoH             kill
        Hut             9
        ja'             tell
        jaH             goto
        jav             6
        jegh            unshift
        jey             kill
        joqtaH          sin
        joqtaHHa'       cos
        juH             main
        juv             length
        laD             readline
        mungna'vo'      STDIN (used as name -- i.e. in an open)
        mungna'vo'Hal   STDIN (used as handle -- i.e. in a readline)
        lagh            substr
        lI'a'           exists
        lo'             use
        lo'laH          values
        lo'Qo'          no
        lo'Sar          sqrt
        logh            x
        loS             4
        loS             wait
        ma'             our
        mach            lc
        mach law'       lt
        machbe' law'    ge
        maH             -0
        maHghurtaH      log
        maj             our
        mej             exit
        mI'pIm'a'       !=
        mI'rap'a'       ==
        mIS             rand
        mIScher         srand
        mISHa'          sort
        mob             scalar
        mol             dump
        mugh            tr
        muH             kill
        muv             join
        nab             sub
        nargh           quotemeta
        natlhwI'        $|
        naw'choH        chmod
        nej             seek
        neq             rename
        netlh           -0000
        nIH             shift
        nob             =
        noD             reverse
        nup             truncate
        pa'ghuHmoH      carp
        pa'Hegh         croak
        pagh            0
        pIm'a'          ne
        pIn'a'choH      chown
        poD             int
        poDmoH          chop
        pong            keys
        pongwI'         caller
        poQ             require
        poS             open
        luSpetna'	STDERR (used as name -- i.e. in an open)
        luSpetna'DoS    STDERR (used as handle -- i.e. in a print)
        Qaw'            delete
        qoj             or
        qojHa'          atan2
        Qong            sleep
        ra'             system
        rap'a'          eq
        rar             link
        rIn             continue
        rIn             continue
        rIn'a'          eof
        Sach            glob
        SaD             -000
        Sam             index
        SanID           -000
        Say'moH         reset
        sIj             split
        So'             crypt
        Soch            7
        SoQmoH          close
        Such            each
        Suq             ...{...}
        SuqvaD          ...{...} (when it's an lvalue)
        Suqvo'          ...{...} (when it's to be further indexed)
        tagh            exec
        tam             s
        tatlh           return
        teHchugh        if
        teHchughbe'     unless
        teHtaHvIS       while
        teHtaHvISbe'    until
        teq             unlink
        tI-             imperative prefix (2 or more arguments)
        tIn             uc
        tIn law'        gt
        tInbe' law'     le
        tIqel           for
        tlhoch          not
        toq'a'          defined
        vagh            5
        vam             local
        vang            do
        vatlh           -00
        wa'             1
        wa'Dichmach     lcfirst
        wa'DichtIn      ucfirst
        wej             3
        wI'             my
        wIj             my
        wIv             grep
        woD             pop
        wuq             ...?...:...
        yI-             imperative prefix (0 or 1 argument)
        yInargh         last
        yInHa'          kill
        yInIDqa'        redo
        yItaH           next 
        yoS             package
        yuv             push




=head1 Appendix 2: Terran-thlIngan dictionary

        
        Terran          thlIngan        Literal translation
        ======          ========        ===================
        =               nob             "give"
        ..              chen            "build up"
        {...}           {...}           "attacking batleth...defending batleth"
                                        (betleH HivtaH...betleH HubtaH")
        (...)           (...)           "attacking sword...defending sword"
                                        ('etlh HivtaH...'etlh HubtaH")
        ...[...]        DIch            ordinal suffix
        ...{...}        Suq             "get"
        ...?...:...     wuq             "decide"
        x               logh            "repeated"
        %               chuv            "be left over"
        +               chel            "add"
        -               chelHa'         "un-add"
        /               wav             "divide"
        ==              mI'rap'a'       "number same?"
        !=              mI'pIm'a'       "number different?"
        \& <sub ref>    -laHwI'         "one who is able to do..."
        abs             'ar             "how much"
        alarm           ghum            "alarm"
        and             'ej             "and"
        atan2           qojHa'          "anti cliff"
        bless           DoQ             "claim ownership of"
        caller          pongwI'         "one who calls"
        carp            pa'ghuHmoH      "warn over there"
        chdir           ghomchoH        "change grouping"
        chmod           naw'choH        "change access"
        chomp           chaqpoDmoH      "maybe clip"
        chop            poDmoH          "clip"
        chown           pIn'a'choH      "change master"
        close           SoQmoH          "close"
        cmp             'ov             "compete"
        continue        rIn             "be complete"
        cos             joqtaHHa'       "counter waving"
        croak           pa'Hegh         "die over there"
        crypt           So'             "hide"
        DATA            De'Daqvo'       "place from which data comes"
        defined         toq'a'          "is inhabited"
        delete          Qaw'            "destroy"
        die             Hegh            "die"
        do              vang            "take action"
        dump            mol             "bury"
        each            Such            "visit"
        eof             rIn'a'          "is finished"
        eq              rap'a'          "same?"
        eval            chov            "evaluate"
        exec            tagh            "begin a process"
        exists          lI'a'           "is useful"
        exit            mej             "depart"
        flock           bot             "prohibit"
        for             tIqel           "consider them"
        fork            bogh            "be born"
        ge              machbe' law'    "be not smaller"
        glob            Sach            "expand"
        goto            jaH             "go"
        grep            wIv             "choose"
        gt              tIn law'        "be larger"
        if              teHchugh        "if true"
        index           Sam             "locate"
        int             poD             "clip"
        join            muv             "join"
        keys            pong            "name"
        kill            HoH             "kill"
        kill            muH             "execute"
        kill            chot            "murder"
        kill            bach            "shoot"
        kill            Hiv             "attack"
        kill            DIS             "stop"
        kill            jey             "defeat"
        last            yInargh         "escape"
        lc              mach            "be small"
        lcfirst         wa'Dichmach     "the first be small"
        le              tInbe' law'     "be not larger"
        length          juv             "measure"
        link            rar             "connect"
        local           vam             "this"
        log             maHghurtaH      "ten log"
        lt              mach law'       "be smaller"
        m               ghov            "recognize"
        main            juH             "home"
        map             choH            "alter"
        mkdir           ghomtagh        "initiate grouping"
        my              wI'             "my sapient"
        my              wIj             "my"
        ne              pIm'a'          "different?"
        next            yItaH           "go on"
        no              lo'Qo'          "don't use"
        not             tlhoch          "contradict"
        open            poS             "open"
        or              qoj             "inclusive or"
        our             ma'             "our sapient"
        our             maj             "our"
        pack            boS             "collect"
        package         yoS             "district"
        pop             woD             "throw away"
        print           ghItlh          "write"
        push            yuv             "push"
        quotemeta       nargh           "escape"
        rand            mIS             "confuse"
        readline        laD             "read"
        redo            yInIDqa'        "try again"
        ref             buv             "classify"
        rename          neq             "move"
        require         poQ             "demand"
        reset           Say'moH         "cause to be clean"
        return          tatlh           "return something"
        reverse         noD             "retaliate"
        rmdir           ghomteq         "remove grouping"
        s               tam             "substitute"
        scalar          mob             "be alone"
        seek            nej             "seek"
        shift           nIH             "steal"
        sin             joqtaH          "waving"
        sleep           Qong            "sleep"
        sort            mISHa'          "be not mixed up"
        splice          DuQ             "stab"
        split           sIj             "slit"
        sqrt            lo'Sar          "fourth how much"
        srand           mIScher         "establish confusion"
        stat            Del             "describe"
        STDIN  <name>   mungna'vo'      "from the origin"
        STDIN  <handle> mungna'vo'Hal   "from the origin (source)"
        STDOUT <name>   ghochna'        "the destination"
        STDOUT <handle> ghochna'DoS     "the destination (target)"
        STDERR <name>   luSpetna'       "the black hole"
        STDERR <handle> luSpetna'DoS    "the black hole (target)"
        study           HaD             "study"
        sub             nab             "procedure"
        substr          lagh            "take apart"
        system          ra'             "command"
        tell            ja'             "report"
        tie             bagh            "tie"
        tied            bagh'a'         "is tied"
        tr              mugh            "translate"
        truncate        nup             "decrease"
        uc              tIn             "be big"
        ucfirst         wa'DichtIn      "the first be big"
        undef           chImmoH         "cause to be uninhabited"
        unless          teHchughbe'     "if not true"
        unlink          teq             "remove"
        unpack          boSHa'          "un collect"
        unshift         jegh            "surrender"
        untie           baghHa'         "untie"
        until           teHtaHvISbe'    "while not true"
        use             lo'             "use"
        values          lo'laH          "be valuable"
        wait            loS             "wait for"
        wantarray       ghomneH         "want group"
        warn            ghuHmoH         "warn"
        while           teHtaHvIS       "while true"
        pIm'a'          ne              "are they different?"
        rap'a'          eq              "are they the same?"
        0               pagh            0
        1               wa'             1
        2               cha'            2
        3               wej             3
        4               loS             4
        5               vagh            5
        6               jav             6
        7               Soch            7
        8               chorgh          8
        9               Hut             9
        -0              maH             -0
        -00             vatlh           -00
        -000            SaD             -000
        -000            SanID           -000
        -0000           netlh           -0000
        -00000          bIp             -00000
        -000000         'uy'            -000000
        $_              'oH             "it"
        @_              bIH             "them"
        $/              chevwI'         "that which separates"
        $|              natlhwI'        "drain?"
