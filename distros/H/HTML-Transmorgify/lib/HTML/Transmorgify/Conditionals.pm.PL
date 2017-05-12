
use Parse::RecDescent;
my $grammar;
END { 
	my $g = $grammar;
	$g =~ s/db\([^()]+\);//g;
	Parse::RecDescent->Precompile($g, "HTML::Transmorgify::Conditionals");
	rename("Conditionals.pm", "lib/HTML/Transmorgify/Conditionals.pm") or die "rename: $!";
	$grammar =~ s/sub db/\$::RD_TRACE = 1; sub db/;
	Parse::RecDescent->Precompile($grammar, "HTML::Transmorgify::ConditionalsDebug");
	rename("ConditionalsDebug.pm", "lib/HTML/Transmorgify/ConditionalsDebug.pm") or die "rename: $!";
}

$grammar = <<'END_OF_FILE';

#
# perl -MParse::RecDescent - grammar HTML::Transmorgify::Conditionals
#

{
	use Carp qw(confess);

	our @rtmp;

	sub db
	{
		require Data::Dumper;
		print Data::Dumper::Dumper((caller(1))[3], @_);
	}

	my $allowed_funcs = \%HTML::Transmorgify::allowed_functions;
	sub run
	{
		return $_[0] unless ref $_[0];
		return $_[0]->();
	}

	sub binary
	{
		db(@_);
		my ($t1, $op, $t2) = @_;
		confess if ref $op;
		my $eval = "sub { \$_[0] $op \$_[1] }";
		$allowed_funcs->{$op} ||= eval $eval or die "eval $eval: $@";
		return sub {
			$allowed_funcs->{$op}->(run($t1), run($t2));
		};
	}

	sub unary
	{
		db(@_);
		my ($op, $t1) = @_;
		confess if ref $op;
		my $eval = "sub { $op \$_[0] }";
		$allowed_funcs->{$op} ||= eval $eval or die "eval $eval: $@";
		return sub {
			$allowed_funcs->{$op}->(run($t1));
		};
	}
		
	sub assoc
	{
		db(@_);
		my ($r, @ops) = @_;
		while (my ($op, $term) = splice(@ops, 0, 2)) {
			confess if ref $op;
			my $eval = "sub { \$_[0] $op \$_[1] }";
			$allowed_funcs->{$op} ||= eval $eval or die "eval $eval: $@";
			my $left = $r;
			$r = sub {
				$allowed_funcs->{$op}->(run($left), run($term));
			};
		}
		return $r;
	}

	sub left
	{
		db(@_);
		assoc(@{$_[1]});
	}

	sub right
	{
		db(@_);
		assoc(reverse @{$_[1]});
	}

	sub nonassoc
	{
		db(@_);
		die if @{$_[1]} > 3;
		left(@_);
	}
}

conditional: expr /\Z/
	{ db(@item); $item[1] }

expr: <leftop: expr2 expr_op  expr2>
	{ db(@item); left(@item) }

expr_op: /or|xor/
	{ db(@item); $item[1] }

expr2: <leftop: expr5 expr2op  expr5>
	{ db(@item); left(@item) }

expr2op: "and"
	{ db(@item); return $item[1] }

expr5: "not" expr6 
	{ db(@item); unary('not', $item[2]) }
  | expr6
	{ db(@item); $item[1] }

expr6: expr7 "?" expr7 ":" expr6
	{ db(@item); sub { run($item[1]) ? run($item[3]) : run($item[5]) } }
  | expr7
	{ db(@item); $item[1] }

expr7: <leftop: expr8 expr7op expr8>
	{ db(@item); left(@item) }

expr7op: "||"
	{ db(@item); $item[1] }

expr8: <leftop: expr9 expr8op  expr9>
	{ db(@item); left(@item) }

expr8op: "&&"
	{ db(@item); $item[1] }

expr9: <leftop: expr10 expr9op expr10>
	{ db(@item); left(@item) }

expr9op: /(\||\^)/ 
	{ db(@item); $item[1] }

expr10: <leftop: expr11 expr10op expr11>
	{ db(@item); left(@item) }

expr10op: /(\&)/ 
	{ db(@item); $item[1] }

expr11: <leftop: expr12 expr11op expr12>
	{ db(@item); nonassoc(@item) }

expr11op: /(==|\!=|<=>|eq|ne|cmp)/ 
	{ db(@item); $item[1] }

expr12: <leftop: expr13 expr12op expr13>
	{ db(@item); nonassoc(@item) }

expr12op: /(<|>|<=|>=|lt|gt|le|ge)/ 
	{ db(@item); $item[1] }

expr13: <leftop: expr14 expr13op expr14>
	{ db(@item); left(@item) }

expr13op: /(<<|>>)/ 
	{ db(@item); $item[1] }

expr14: <leftop: expr15 expr14op expr15>
	{ db(@item); left(@item) }

expr14op: /(\+|-|\.)/ 
	{ db(@item); $item[1] }

expr15: <leftop: expr15a expr15op expr15a>
	{ db(@item); left(@item) }

expr15op: /(\*|\/|%|x)/ 
	{ db(@item); $item[1] }

expr15a: '-' expr16 
	{ db(@item); binary(0, '-', $item[1]) }
  | expr16
	{ db(@item); $item[1] }

expr16: <leftop: expr17 expr16op expr17>
	{ db(@item); left(@item) }

expr16op: /(=~|\!~)/ 
	{ db(@item); $item[1] }

expr17: <leftop: term expr17op term>
	{ db(@item); left(@item) }

expr17op: /(\*\*)/ 
	{ db(@item); $item[1] }

term: '(' expr ')'
	{ db(@item); $return = $item[2] }
  | constant
	{ db(@item); $return = $item[1] }
  | macro
	{ db(@item); $return = $item[1] }
  | function
	{ db(@item); $return = $item[1] }

function: /[A-Za-z_](?:\w|::(?=[^:]))*/ '(' expr(s /,/) ')'
	{ 
		db(@item);
		die unless $allowed_funcs->{$item[1]};
		$return = sub {
			$allowed_funcs->{$item[1]}->( map { run($_) } @item[3..$#item] );
		};
	}

constant: / -? (?: \d+ (?: \.\d+ )? | (?: \.\d+) ) (?:[eE]-?\d+)? /x
	{ db(@item); $item[1] }
  | "'" /[^"]*/ '"'
	{ db(@item); $item[2] }
  | '"' /[^']*/ "'"
	{ db(@item); $item[2] }

macro: /<macro (?: [^'">] | '[^'<>]*' | "[^"<>]*" )* >/x
	{
		db(@item);
		my $buf = HTML::Transmorgify::compile($HTML::Transmorgify::modules, \$item[1]);
		$return = sub {
			local(@rtmp) = ( '' );
			run($buf, \@rtmp);
			return $rtmp[0];
		};
	}


END_OF_FILE

