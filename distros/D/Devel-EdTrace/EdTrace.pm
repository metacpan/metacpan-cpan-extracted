# -*- perl -*-

package Devel::EdTrace;
no warnings;
use strict;
use Data::Diff;
use Data::Grep;
use Data::Dumper;
use Data::DeepCopy;
use Config;

use vars qw($_brackets $_simple_parens);

my $_quotables = [ '@', '#', '%', '^', '&', '*', ':', '"', "'", '', '', '' ];

BEGIN 
{ 
	eval "use PadWalker qw(peek_my peek_our);\n";
	eval "use Devel::LexAlias qw(lexalias);\n";
	($_brackets , $_simple_parens) = ___brackets_parens();
#	eval "use Regex::Token qw(\$_brackets \$_simple_parens);\n";

#	if ($@) { print STDERR "HERE :$@:\n"; }
#
#	print STDERR "HERE: $_brackets\n";
#	die;
	if (!defined(&peek_my)) { print STDERR "SYSTEM WARNING: PadWalker not found!\n"; }
	if (!defined(&lexalias)) { print STDERR "SYSTEM WARNING: Devel::LexAlias not found!\n"; }

#	print STDERR ":$_simple_parens:\n";
	*lexalias = sub { {} } if (!defined(&lexalias));
	*peek_my = sub { {} } if (!defined(&peek_my));
	*peek_our = sub { {} } if (!defined(&peek_our));

    sub ___brackets_parens
    {
		my $_cpp_comment  = q$(?<![A-Za-z:])//[^\n]*(?=\n|\Z)$;
        my $_perl_comment = q,(?>\#[^\n]+(?:\n|\Z)),;
		my $_doublestring = q$(?>\"(?>[^\\\"]+|\\\.)*\")$; #"
		my $_singlestring = q$(?>\'(?>[^\\\']+|\\\.)*\')$; #'
		my $_simple_brackets;

		my $_simple_parens;

        my $_sub_simple_brackets = "\{(?>[^{}]+)\}";
        my $_sub_simple_parens = "(?>\\((?>[^()]+)\\))";

		my $_subbrackets =
					q$
						\{
							(?>
					$ . 
								$_perl_comment . '|' . 
								$_cpp_comment  . '|' .
								$_doublestring . '|' .
								$_singlestring .  '|' . 
					q$

								(?>[""''/\#])      |
								(?>[^{}""''/\#]+)
							)*
						\}
					$;  

        my $xx;
	    for ($xx = 0; $xx < 20; $xx++)
        {

		    $_simple_brackets = "(?>\\s*\{(?>[^{}]+|$_sub_simple_brackets)*\})";
		    $_sub_simple_brackets = $_simple_brackets;
					
		    $_brackets = 
					q$
						(?>\s*
							\{ 
								(?>
					$ . 			$_cpp_comment . '|' .
									$_doublestring .'|'.
									$_singlestring . '|' .
                                    $_perl_comment . '|' .
					q$
									(?>[""''/\#]) |
									(?>[^{}""''/\#]+) |
					$ .
									$_subbrackets .
					q$
								)*
							\}
						)$ 
					;

		        $_subbrackets = $_brackets;
        }

	    for ($xx = 0; $xx < 20; $xx++)
	    {
		    $_simple_parens = "(?>\\s*\\((?>[^()]+|$_sub_simple_parens)*\\))";
		    $_sub_simple_parens = $_simple_parens;
        }

        $_brackets =~ s"\s""sg;
        $_simple_parens =~ s"\s""sg;
		return($_brackets, $_simple_parens);
    }
}

use FileHandle;
use Time::HiRes qw(usleep);
use vars qw($_cached);

our $_tb_code;
our $_tb_delay;
our $_setme;
our $_destroy_lines = {};


use vars (qw ($VERSION $TRACE));
$VERSION = '0.10';
BEGIN { $TRACE = 1; }

$_cached = {};

use vars qw($tlfh);

$Devel::EdTrace::PrintEval  = ($ENV{TRACEEVAL})? 1 : 0;
$Devel::EdTrace::PrintLevel = ($ENV{TRACELEVEL})? $ENV{TRACELEVEL} : 1;
$Devel::EdTrace::ExpandBuiltin = ($ENV{TRACEBUILTIN} == 1)? 'keys|values|map' : ($ENV{TRACEBUILTIN})? $ENV{TRACEBUILTIN} : 0;
$Devel::EdTrace::NoExpandArray = ($ENV{TRACENOARRAY})? 1 : 0;
$Devel::EdTrace::SafeGuard     = ($ENV{TRACESAFE} eq 'none')? undef : ($ENV{TRACESAFE})? $ENV{TRACESAFE} : "hashref|functions|autovivify";
$Devel::EdTrace::GrepRegex    = ($ENV{TRACEGREP})? $ENV{TRACEGREP} : undef;
$Devel::EdTrace::TraceSys     = ($ENV{TRACESYS})? $ENV{TRACESYS} : undef;


# This is the important part.  The rest is just fluff.

#sub NEWDB::DB
sub DB::DB
{
    return unless $TRACE;
    my ($p, $f, $l) = caller;
	my $oldeval;

	no strict 'refs';
#   DB::eval();
	
	local($Data::DeepCopy::RefLevel) = (defined($ENV{TRACELEVEL}))? 
												$ENV{TRACELEVEL} : 1;
	local($Data::Diff::RefLevel) = (defined($ENV{TRACELEVEL}))? 
												$ENV{TRACELEVEL} : 1;
	local($Data::Grep::RefLevel) = (defined($ENV{TRACELEVEL}))? 
												$ENV{TRACELEVEL} : 1;

	___printwatchpoints();
	___printreversewatchpoints();

# 	$ENV{TRACEDELAY} = 1000000;
#	$ENV{TRACECB} = "sub { \$ENV{PERL5SHELL} = 'C:\\cygwin\\bin\\sh.exe -cf' if (!\$_setme++); system(\"/bin/ls.exe\"); }";

	if ($ENV{TRACEDELAY}) { usleep($ENV{TRACEDELAY}); }

	if ($ENV{TRACECB}) 
	{
		if ($_tb_code)
		{
			&{$_tb_code}();
		} 
		else 
		{ 
			$oldeval = $@;
			eval("\$_tb_code = $ENV{TRACECB}");
			$@ = $oldeval;
		}
	}

	___print(___prompt($f, $l)); 
}

my @oldopt;
sub CommonOn
{
	push(@oldopt, [ $Devel::EdTrace::PrintEval, $Devel::EdTrace::PrintLevel, $Devel::EdTrace::TRACE ]);

	$Devel::EdTrace::PrintEval = 1;
	$Devel::EdTrace::PrintLevel = 2;
	$Devel::EdTrace::TRACE = 1;
}

sub CommonOff
{
	if (@oldopt)
	{
		my ($opt) = pop(@oldopt);

		$Devel::EdTrace::PrintEval = $opt->[0];
		$Devel::EdTrace::PrintLevel = $opt->[1];
		$Devel::EdTrace::TRACE = $opt->[2];
	}
	else
	{
		$Devel::EdTrace::TRACE = 0;
	}
}

sub ___prompt
{
	my ($f, $l) = @_;
	
	no strict;

   	my $code = \@{"::_<$f"};

	my $toprint;
	if ($Devel::EdTrace::PrintEval)
	{
		my $cd = ___getstatement($code, $l);
		chomp($cd);

#			print STDERR ":$cd:\n";
		$toprint = ___eval_in_callers_scope($cd, $code);
#			print STDERR "HERE1 => :$toprint:\n";
#			$toprint = $code->[$l];
		
	}
	else
	{
		$toprint = ___getstatement($code, $l);
		$toprint = "\n$toprint";
	}

	if ($Devel::EdTrace::PrintLevel == 1)
	{
		return(">> $f :$l: $toprint");
	}
	elsif ($Devel::EdTrace::PrintLevel == 2)
	{
		my @stack;
		my $stack = 0;
		while (@stack = caller($stack))
		{
			$stack++;
		}
		return(("\t" x $stack) . ">> $f :$l: $toprint");
	}
	elsif ($Devel::EdTrace::PrintLevel == 3)
	{
		my $text;

		my @stack;
		my $stack = 0;

		while (@stack = caller($stack))
		{
			$stack++;
		}

		$stack--;
		my $join;
		while ($stack >= 1)
		{
			my @stack = caller($stack);
			$join .= "$stack[1] :$stack[2]: $code->[$stack[2]] ";
			$stack--;
		}

		$join =~ s"\n" -- "sg;
		return( "$join\n");
	}
}

sub ___getstatement
{
	my ($code, $l) = @_;

	my $open_here;
	my $ret;
	while (length($code->[$l]))
	{

		if ($open_here && $code->[$l] =~ m"^$open_here")
		{
			$ret .= $code->[$l];
			last;
		}
		elsif ($code->[$l] =~ m/.*<<["']?([_A-Z0-9!]+)["'\s;\),;]/ && !$open_here) 
		{ 
			$open_here = $1; 
			$ret .= $code->[$l]; 
		}
		else
		{
			$ret .= $code->[$l];
			last if (!$open_here && $code->[$l] =~ m";");
		}
		$l++;
	}
	return($ret);
}

sub ___eval_in_callers_scope
{
    my ($input_line, $code_lines) = @_;


	my $_specials = { '@ARGV' => 1 };

	no strict;
	my $return;

	chomp($input_line);

     my $callers_lexicals = peek_my(3);

     my $line;
#	 foreach $line (keys(%$callers_lexicals))
#	 {
#	 	print STDERR "LEXICAL => $line\n";
#		sleep(1);
#	}

#	print STDERR "HERE :$input_line: $@\n";
#    return($return);

    my $preamble = "";
	use Data::Dumper;
	
	my @full;
	my @stack;
	my $stack = 0;

	my (@stack) = caller(2);

	my $in_destroy_flag = ___in_destroy_flag($stack[1], $stack[2], $code_lines);

#	print STDERR Dumper(\@stack) if ($in_destroy_flag);
#	sleep(10) if ($in_destroy_flag);

	my $preamble = "dummy(); sub dummy {\n";
	for my $variable_name (keys(%$callers_lexicals))
	{
		my $val = $callers_lexicals->{$variable_name};
		my $repl;
		my $code_lines;

		if (!$in_destroy_flag)
		{
			$preamble .= "my $variable_name; Devel::EdTrace::lexalias(0, '$variable_name', \$callers_lexicals->{'$variable_name'}) if (Devel::EdTrace::___defined(\$callers_lexicals->{'$variable_name'}));\n";
#			$preamble .= "my $variable_name; lexalias(0, '$variable_name', \$callers_lexicals->{'$variable_name'});\n";
		}
	}
#		if (ref($val) eq 'SCALAR')
#		{
#			$repl = $$val;
#			$code_lines = "$variable_name = $repl;\n";
#		}
#		else
#		{
#			$code_lines = "_alias(\\$variable_name, $repl);\n";
#
#		print STDERR "VARB $variable_name => $repl\n";
#		$preamble .= "my $variable_name; $code_lines;";
#		}

	my $caller = [ caller(2) ];
#	print STDERR ":@$caller:\n";
#	sleep(4);

# print STDERR " FFFF => :$_brackets:\n";
#	my $tag = "AABBCCDDEEFF";

	chomp($input_line);
	my $eval_input_line = $input_line;

	my @bad_lines;
	push(@bad_liens, "BEF1 :$eval_input_line:\n");

	if ($Devel::EdTrace::NoExpandArray)
	{
		$eval_input_line =~ s"\@"\\\@"sg;
	}
	push(@bad_lines, "BEF2 :$eval_input_line:\n");

	if ($_brackets)
	{
		$eval_input_line =~ s/(\@(?:\w+))/"\@AOPBRACK [ $1 ] CLSBRACK"/sge;
		push(@bad_lines, "BEF3 :$eval_input_line:\n");

		while ($eval_input_line =~ s/\@(\s*$_brackets)/"\@AOPBRACK [ " . ___bracket_surgery($1, $eval_input_line, 'quotemeta' , $found_so_far) . "  ] CLSBRACK "/sge) { };
		push(@bad_lines, "BEF3b :$eval_input_line:\n");

		if ($Devel::EdTrace::ExpandBuiltin)
		{
			my $found_so_far = {};

			$eval_input_line =~ s/(\b(?:$Devel::EdTrace::ExpandBuiltin)\b\s*$_simple_parens)/"\@AOPBRACK [ $1 ] CLSBRACK"/sge;
			push(@bad_lines, "BEF4 :$eval_input_line:\n");
		}

#			print STDERR "HERE :$Devel::EdTrace::SafeGuard:\n";
		if ($Devel::EdTrace::SafeGuard =~ m"hashref")
		{
#			print STDERR "BEFORE :$eval_input_line:\n";
			while ($eval_input_line =~ s"(\$\w+(?:\->\s*)?)($_brackets)" $1 . ___bracket_surgery($2, $eval_input_line, undef, $found_so_far )"sge) { }
			push(@bad_lines, "BEF5 :$eval_input_line:\n");

			while ($eval_input_line =~ s"(\@)($_brackets)" $1 . ___bracket_surgery($2, $eval_input_line, 'func_call', $found_so_far)"sge) { }
			push(@bad_lines, "BEF6 :$eval_input_line:\n");

#			print STDERR "AFTER :$eval_input_line:\n";
		}
	}
	elsif ($Devel::EdTrace::ExpandBuiltin)
	{
		die "SYSTEM ERROR: ExpandBuiltin not supported without Regex::Token\n";
	}

	$eval_input_line =~ s"\+\+(\s*\$)"1 + $1"sg;
	push(@bad_lines, "BEF7 :$eval_input_line:\n");
	$eval_input_line =~ s"\+\+""sg;

	push(@bad_lines, "BEF8 :$eval_input_line:\n");
	$eval_input_line =~ s"\-\-(\s*\$)"$1 - 1"sg;

	push(@bad_lines, "BEF9 :$eval_input_line:\n");
	$eval_input_line =~ s"\-\-""sg;

	push(@bad_lines, "BEF10 :$eval_input_line:\n");

	___unbracket_surgery($eval_input_line);

	push(@bad_lines, "BEF10a :$eval_input_line:\n");

#	my $tags = join('|', keys(%$rephash));
#	$eval_input_line =~ s"($tags)"$rephash->{$1}"sg;

	$eval_input_line =~ s,\\*?(([\$\@\%])(\w+))(?=(\s*\[|\s*{|\b)), 

			my $cl = $1;
			my $sign = $2;
			my $val = $3;
			my $post = $4;
#			print STDERR ":$cl: :$sign: :$val: :$post:\n";	
			my $transsign = $sign;
			if ($post =~ m"{" && $sign eq '$') { $transsign = '%'; }
			if ($post =~ m"\[" && $sign eq '$') { $transsign = '@'; }

			if 	( !$callers_lexicals->{"$transsign$val"} && !$_specials->{"$transsign$val"} && !$_protected->{"$transsign$val"}) 
			{
				if 
				(
					($transsign eq '$' && defined(${"$caller->[0]" . "::" . $val})) || 
					($transsign eq '@' && defined(@{"$caller->[0]" . "::" . $val})) ||
					($transsign eq '%' && defined(%{"$caller->[0]" . "::" . $val}))
				)
				{
					if ($sign ne '@')
					{
						$sign . "$caller->[0]" . "::" . $val;
					} 
					else
					{
						if ($sign eq '@' && $Devel::EdTrace::NoExpandArray)
						{
							"\\$sign" . "$caller->[0]" . "::" . $val;
						}
						else
						{
							"$sign" . "$caller->[0]" . "::" . $val;
						}
					}
				}
				else
				{
					if ($Devel::EdTrace::NoExpandArray || $_protected->{$cl})
					{
						"\\$sign$val" 
					}
					else
					{
						"$sign$val";
					}
				}
			}
			elsif ($_protected->{$cl} || $sign ne '$') 
			{ 
				if ($Devel::EdTrace::NoExpandArray || $_protected->{$cl})
				{
					"\\$sign$val" 
				}
				else
				{
					"$sign$val";
				}
			} 
			else 
			{ 
				"$sign$val"; 
			},sge;

	push(@bad_lines, "BEF11 :$eval_input_line:\n");

	if ($Devel::EdTrace::SafeGuard =~ m"autovivify")
	{
#		print STDERR "BEF11b :$eval_input_line:\n";
		$eval_input_line =~ s,($_brackets)(((?:->)?$_brackets)),$1\\$2,sg;
	}
	push(@bad_lines, "BEF12 :$eval_input_line:\n");

#	print STDERR "WHOA :$preamble; \$return = q$input_line <=>  . qq >>>$eval_input_line<<< . \"\\\n\"";
#	sleep(4);

	my $width = $ENV{TRACEWIDTH} || 160; #"

	my %symbefore = map { $_ => 1 } keys(%YPAN::Map::Build::);

	my $code;
	if ($ENV{GOOD})
	{
		$code = "package ___junkit; $preamble \$return = Devel::EdTrace::___split_screen(\$width, q$input_line, q$eval_input_line) . \"\\n\"";
	}
	else
	{
		$code = "package ___junkit; $preamble \$return = Devel::EdTrace::___split_screen(\$width, q$input_line, qq$eval_input_line) . \"\\n\"";
	}
#	my $code = "$preamble";
#	my $code = "$preamble \$return = ___split_screen(\$width, q$input_line) . \"\\n\"";
	$code .= "\n}";
#	print STDERR "CODE:\n----\n$code\n----\n";
#	sleep(1);
	package ___junkit;
	my $oldeval = $@;
	eval($code);
	package Devel::EdTrace;
#	print STDERR ">>>$return<<<";

	my %symafter = map { $_ => 1 } keys(%YPAN::Map::Build::);

	if (%symafter != %symbefore)
	{
		foreach $sym (keys(%symafter))
		{
			if (!$symbefore{$sym})
			{
				print STDERR "SYMBOL :$sym: was introduced\n";
				print STDERR "YEEHAW :$code:\n";
			}
		}
	}

#	print STDERR "CODE:\n\n----\n$code\n----\n$@\n----\n";

	if ($@)
	{
#		print STDERR "^^^^$code^^^^$input_line^^^^ :$@: RRR :$return:\n";
#		print STDERR "WHAT THE..:$@: -- :$code:\n";
		print STDERR join("\n", @bad_lines) . "\n";
		print STDERR "BAD LINE: :$input_line: :$eval_input_line: :$@:\n";
		$@ = $oldeval;
		return("\n" . ___split_screen($width, $input_line, $eval_input_line) . "\n");
	}
	elsif ($input_line =~ m"backpan_mname")
	{
		print STDERR "AUTOVIV\n";
		print STDERR join("\n", @bad_lines) . "\n";
	}

	$@ = $oldeval;
		
#	sleep(1);
	
#	print STDERR "HERE4 :$return:\n";
#	sleep(4);

#	my $code = "\$return = sub { $preamble; return( q{ $input_line <=> } . qq{ $input_line } . \"\\\n\"; ); }->()";
#	print STDERR "$input_line";
#	print STDERR $code;
#	sleep(1);
#	print STDERR "HERE1\n";
#    DB::eval($code);
#	print STDERR "HERE2: $return\n";
#	sleep(1);
#	$return = "\n$return";
	$return = "\n$return";
	return($return);
}


sub ___unbracket_surgery
{
	my ($eval_input_line) = @_;

	$_[0] =~ s"AOPBRACK"{"sg;
	$_[0] =~ s"CLSBRACK"}"sg;
}



sub ___bracket_surgery
{
	my ($brack, $orig, $type, $found_so_far) = @_;

#	if ($brack =~ m"self.*os")
#	{
#		print STDERR "YEARGH :$orig: :$brack:\n";
#	}
	return($brack) if ($brack =~ m"^\s*{\s*\[");
	$brack =~ s"^{""s;
	$brack =~ s"}\Z""s;

	my $ql = _get_ql($orig, $found_so_far);
	if ($type eq 'quotemeta')
	{
		$brack = "qq${ql}$brack${ql}";
		return($brack);
	}

	if ($type eq 'func_call')
	{
		if ($brack =~ m"\s|\(|\)"s)
		{
			$brack = "AOPBRACKqq${ql}$brack${ql}CLSBRACK";
		}
		return($brack);
	}

	$brack = "AOPBRACKqq${ql}$brack${ql}CLSBRACK";

	return($brack);
}

sub _get_ql
{
	my ($orig, $found_so_far) = @_;

	my $ql;

	my $quot;
	foreach $quot (@$_quotables)
	{
		my $qm = quotemeta($quot);
		if (!$found_so_far->{$quot})
		{
			if ($orig =~ m"$qm") { $found_so_far->{$quot} = 1; } else { $ql = $quot; $found_so_far->{$quot} = 1; last; }
		}
	}

	if (scalar(keys(%$found_so_far)) == @$_quotables) {  die "SYSTEM ERROR: Could unparsable piece of code!\n"; }
	else 
	{
#		print STDERR scalar(keys(%$found_so_far)) . "," . @$_quotables . "\n";
	}
	return($ql);
}


my $_destroy_lines = {};

sub ___in_destroy_flag
{
	my ($file, $line, $code_lines) = @_;

	if (!$_destroy_lines->{$file})
	{
		my @range;
		my $start_destroy = 0;

		my $xx;
		for ($xx = 1; $xx <= @$code_lines; $xx++)
		{
			if ($code_lines->[$xx-1] =~ m"sub\s*DESTROY")
			{
#				print STDERR "$file -- $line -- " . join("\n", @$code_lines) . "\n";
#				sleep(5);
				$start_destroy = 1;
				$range[0] = $xx-1;
			}
			elsif ($start_destroy && ($code_lines->[$xx-1] =~ m"sub\s" || $xx == @$code_lines))
			{
				$range[1] = $xx-1;
				push(@{$_destroy_lines->{$file}}, [ @range ]);
#				print STDERR Dumper($_destroy_lines);
#				sleep(5);

				@range = ();
				$start_destroy = 0;
			}
		}
	}

	my $range;
	foreach $range (@{$_destroy_lines->{$file}})
	{
		if ($line >= $range->[0] && $line <= $range->[1])
		{
			return(1);				
		}
	}
	return(0);
}

sub ___defined
{
	my ($val) = @_;

	if (ref($val) =~ m"SCALAR" && !defined($$val)) 			{ return(0); }
	if (ref($val) =~ m"ARRAY"  && !@$val) 					{ return(0); }
	if (ref($val) =~ m"HASH"   && !scalar(%$val)) 			{ return(0); }

	return(1);
}


sub ___split_screen
{
    my ($width, $arg1, $arg2) = @_;

	if ($ENV{DRYRUN}) { $arg2 = $arg1; }
#	print STDERR "FFFFF\n";
#	return($arg1);
	$arg1 =~ s"\n"\\n"sg;
	$arg2 =~ s"\n"\\n"sg;

	$arg1 =~ s"\t"  "sg;
	$arg2 =~ s"\t"  "sg;

    my $ret;
    my $totlength = (length($arg1) > length($arg2))?
                        length($arg1) :
                        length($arg2);

    my $noperline = int($width/2) - 3;
    my $lines = "<" x $noperline;

    my $nolines = int($totlength/(int($width/2) - 3)) + 1;


    my (@val1) = ($arg1 =~ m"(.{1,$noperline})"sg);
    my (@val2) = ($arg2 =~ m"(.{1,$noperline})"sg);

    my $xx;
    for ($xx = 0; $xx < $nolines; $xx++)
    {
        $val1[$xx] ||= '';
        $val2[$xx] ||= '';

        $ret .= "    $val1[$xx]" . " " x ($noperline - length($val1[$xx])) . " | ";
        $ret .= "    $val2[$xx]" . " " x ($noperline - length($val2[$xx])) . "\n";
    }

	chomp($ret);
    return($ret);
}

sub ___print
{
	my ($text) = @_;

	if ($Devel::EdTrace::GrepRegex && $text !~ m"$Devel::EdTrace::GrepRegex") { return() };

#	if ($Devel::EdTrace::PrintLevel == 1)
#	{
   	if ($tlfh) { print $tlfh $text; } else { print STDERR $text; }
#	}
#	else
#	{
#    	if ($tlfh) { print $tlfh ___traceit($text); } else { print STDERR ___traceit($text); }
#	}
	if ($ENV{TRACESYS}) { my $oldsys = $?; system("$ENV{TRACESYS}"); $? = $oldsys; }
}

sub ___traceit
{
	my $caller = [ caller(3) ]; # hack
	return( join(" -- ", @$caller[0,1,2,3]). "\n\t" . $_[0] );
}

sub ___printwatchpoints
{
	if ($ENV{TRACEWATCH})
	{
		my @vars = split(m":", $ENV{TRACEWATCH});
		my $var;
		
		my $var;
		foreach $var (@vars)
		{
			if (___diff('my', $var)) { ___printdiff('my', $var); 		___set('my', $var); 	}
			if (___diff('our', $var)) { ___printdiff('our', $var); 		___set('our', $var); 	}
			if (___diff('glob', $var)) { ___printdiff('glob', $var); 	___set('glob', $var); }
		}
	}
}

sub ___printreversewatchpoints
{
	if ($ENV{TRACEREVERSE})
	{
		my @rwatch = split(m"<->", $ENV{TRACEREVERSE});

		grep(s"<\\->"<->"sg, @rwatch);
		grep(s"\|"\\|"sg, @rwatch);

		my $rwatch = join('|', @rwatch);

		my $var;
		foreach $var (___globals(3))
		{
#			print STDERR "WHOA : :$var:\n";
			if (___diff('glob', $var) && ___printgrep('glob', $var, $rwatch)) 	 
			{ 
#				print STDERR "AHA1: $var :$rwatch:\n";
				___set('glob', $var);   
			}
		}

		foreach $var (___ours(3))
		{
			if (___diff('our', $var) && ___printgrep('our', $var, $rwatch))
			{ 
#				print STDERR "AHA2: $var :$rwatch:\n";
				___set('our', $var);   
			}
		}

		my @vars = ___mys(3);

		foreach $var (___mys(3))
		{
#			print STDERR "AHAAAA :$var: mydiff: " . ___diff('my', $var) . "\n";
#			sleep(2);
			if (___diff('my', $var) && ___printgrep('my', $var, $rwatch)) 	 
			{ 
#				sleep(10);
#				print STDERR "AHA3: $var :$rwatch:\n";
				___set('my', $var);   
			}
		}
	}
}

sub ___globals
{
	my ($scope) = @_;

	no strict 'refs';
	my $package = ___getpkg('glob', undef, $scope);

	my @return;
	my @varnames = keys(%{"${package}::"});

	my $var;
	foreach $var (@varnames)
	{

		next if ($var !~ m"\w");
		next if ($var =~ m"<");
		next if ($var =~ m"::");

		if (defined(%{${"${package}::"}{$var}}))
		{
			push(@return, "%$var");
		}
		if (defined(@{${"${package}::"}{$var}}))
		{
			push(@return, "\@$var");
		}
		if (defined(${${"${package}::"}{$var}}))
		{
			push(@return, "\$$var");
		}
	}	

	return(@return);
}

sub ___ours
{
		my ($scope) = @_;

		my $hdl = peek_our($scope);

		return(keys(%$hdl));
}

sub ___mys
{
		my ($scope) = @_;
		my $hdl = peek_my($scope);

		return(keys(%$hdl));
}

sub ___set
{
	my ($type, $variable, $value) = @_;

	my $package = ___getpkg($type, $variable, 3);

	my ($val);
	if (@_ == 3)
	{
		undef($_cached->{$type}{$package}{$variable});
	}
	else
	{
		$_cached->{$type}{$package}{$variable} = ___copy($type, $variable);
	}
}


sub ___copy
{
	my ($type, $variable) = @_;

	no strict 'refs';
	my ($old, $new) = ___lookup($type, $variable, 5);

#	print STDERR  Dumper($old, $new);

	return(deepcopy($new));
}

sub ___getpkg
{
	my ($type, $variable, $scope) = @_;

	$scope ||= 4;

	return($type) if ($type eq 'our' || $type eq 'my');
	my ($p, $f, $l)  = caller($scope);
	return($p);
}

sub ___printgrep
{
	my ($type, $variable, $rwatch) = @_;

	my ($old, $new)= ___lookup($type, $variable, 4);

#	print STDERR "HERE: $variable: " . Dumper($old, $new) if ($variable =~ m"%ary" && $type eq 'our');

#	print STDERR "AHAME :$old: :$new: :$variable: :$rwatch:\n";
#	sleep(2);
	my $status = _datagrep
	(
		$rwatch, $new, 
		{ 
			name => $variable, 
			filter => sub 
					{ 
#						print STDERR Dumper($_[1]);
#						print STDERR "@{$_[1]}";
						return(0) if ($_[2]->{name} ne '%ENV');
						return(1) if ($_[2]->{name} =~ m"%ENV" && "@{$_[1]}" =~ m"TRACEREVERSE");
						return(0);
					},
			grepkey => 1,
			type 	=> $type 
		}
	);
	return($status);
}

sub ___printdiff
{
	my ($type, $variable) = @_;

	my ($old, $new) = ___lookup($type, $variable,4);

	if (ref($old) eq ref($new))
	{
			___compare($type, $variable);
	}
	elsif 
	(
		defined($old) || 
			(!defined($old) && ref($new) eq 'SCALAR' && defined(${$new})) ||
			(!defined($old) && ref($new) ne 'SCALAR')
	)
	{
		my $package = ___getpkg($type, $variable, 3);
		my ($sigil, $name)  = ( $variable =~ m"(.)(.*)");

		my $dumpa = ___dump($old, $name);
		my $dumpb = ___dump($new, $name);

		if ($dumpa =~ m"\n") { $dumpa =~ s"\n\s*"\n\t\t\t"sg; $dumpa = "\n\t\t$dumpa"; }
		if ($dumpb =~ m"\n") { $dumpb =~ s"\n\s*"\n\t\t\t"sg; $dumpb = "\n\t\t$dumpb"; }

		___print ( "	$type $variable: $dumpa +++> $dumpb" . "\n");
	}
}

sub ___ref
{
	my ($var) = @_;

	my $type = 	(defined($var) && ref($var) eq 'SCALAR' && ref($$var))? ref($$var) :
				(defined($var) && ref($var) ne 'SCALAR')? ref($var) :
				(!defined($var))? 'undef' :
				'scalar';
	return($type);
}

sub ___dump
{
	my ($var, $name) = @_;

	local($Data::Dumper::Varname) = "ZYZYZYZYZYZYZ";

	my $ret = 
		(defined($var) && ref($var) eq 'SCALAR' && ref($$var))? Dumper($$var) :
		(defined($var) && ref($var) ne 'SCALAR')? Dumper($var) :
		(!defined($var))? 'undef' :
		(ref($var) eq 'SCALAR')?  "'$$var'" :
		"'$var'";

	$ret =~ s"ZYZYZYZYZYZYZ1"$name"sg;

	return($ret);
}

sub ___diff
{
	my ($type, $var) = @_;

	my ($oldvar, $newvar) = ___lookup($type, $var,4);
#	print STDERR ":$oldvar: :$newvar:\n";
#	print STDERR ":$type: :$var: :$oldvar: :$newvar:\n";
#	sleep(1);

	return() if (!$oldvar && !$newvar);

	my $status = checkEq($oldvar, $newvar);
#	print STDERR "STATUS: " . Dumper ($status) . "\n";
	return(!$status) if (!ref($status));
	return(1) if (ref($status));

#	print STDERR Dumper($oldvar, $newvar, $status) if ($var =~m"hash");
#	return(!checkEq($oldvar, $newvar));
}

my $_die;
sub ___lookup
{
	my ($type, $var, $scope) = @_;

	$scope ||= 4;
	my $package = ___getpkg($type, $var, $scope);

	my $oldvar = $_cached->{$type}{$package}{$var};
	my $hdl; 
	my $newvar;

#	print STDERR "HERE!!!!!! :$var: :$hdl->{$var} :$newvar:\n";
	
	if ($type eq 'my')
	{
		$hdl = peek_my($scope);
		$newvar = (!defined($hdl->{$var}))? undef : 
						($var =~ m"^\%")? \%{$hdl->{$var}} : 
						($var =~ m"^\@")? \@{$hdl->{$var}} :
						${$hdl->{$var}};

#		print STDERR "DONE :$newvar:\n";
	}
	elsif ($type eq 'our')
	{
		$hdl = peek_our($scope);
		$newvar = (!defined($hdl->{$var}))? undef : 
						($var =~ m"^\%")? \%{$hdl->{$var}} : 
						($var =~ m"^\@")? \@{$hdl->{$var}} :
						${$hdl->{$var}};
	}
	else
	{

		no strict 'refs';
		my ($sigil, $name) = ($var =~ m"(.)(.*)"s);
#		print STDERR "YEEHAW :$sigil: :$name:\n";
		my $sym = ${"${package}::"}{$name};
#		print STDERR "DUMB THING\n";

#		print STDERR "WHOA!!!! :$:$sym: \n";
		$newvar = 
			($sigil eq '$' && ref(${$sym}))? ${$sym} : 
			($sigil eq '$')? \${$sym} : 
			($sigil eq '%')? \%{$sym} : 
			($sigil eq '@')? \@{$sym} :
			print STDERR "SYSTEM ERROR: Unknown Sigil $sigil for variable $name\n";
	}
	return($oldvar, $newvar);
}

sub ___compare
{
	my ($type, $varname) = @_;

	my ($old, $new) = ___lookup($type, $varname, 5);
	checkData
	(
		$old, $new,
		{ 
			check_data_type	=> $type,
			check_data_varname	=> $varname,
			check_data_coderef => 
				sub 
				{
					my ($a, $b, $config) = @_;
					if ($a ne $b)
					{

						if (!defined($a)) { $a = 'undef' } else { $a = "'$a'"; }
						if (!defined($b)) { $b = 'undef' } else { $b = "'$b'"; }

						___print(
								"	$config->{check_data_type} $config->{check_data_varname} " . 
									join("", @{$config->{data_path}}) . " : $a => $b\n");
					}
				}
		}
	);
}

sub ___printheader
{
    if ($tlfh)
    {
        print $tlfh  ___header();
    }
    else
    {
        print STDERR ___header();
    }
}

sub ___header
{
    my $ret = 
        "-----\n%ENV = \n\t" . Dumper(\%ENV) .
        "\n----\n%INC = \n\t" . Dumper(\%INC) . 
        "\n----\n\@INC = \n\t" . Dumper(\@INC) . 
        "\n----\n\@ARGV = \n\t" . Dumper(\@ARGV) . "\n-----\n";

    return($ret);
}

sub ___gettfh
{
    fclose($tlfh) if ($tlfh);

    my $dir = $0;
    $dir =~ s".*/""sg;

    my $tfile = 
        ($ENV{TRACELOG} && $ENV{TRACEPID})? 
            "$ENV{TRACELOG}.$$" : 
        ($ENV{TRACELOG} && !$ENV{TRACEPID})? 
            "$ENV{TRACELOG}" :  
        ($ENV{TRACEDIR} && $ENV{TRACEPID})?     
            "$ENV{TRACEDIR}/$dir.$$" :
        ($ENV{TRACEDIR} && !$ENV{TRACEPID})?     
            "$ENV{TRACEDIR}/$dir" :
            "";

my $tlfh2 = ($ENV{TRACERM} && $tfile)? 
            FileHandle->new("> $tfile") : 
            ($tfile)? FileHandle->new(">> $tfile") :
            undef;
    $tlfh = $tlfh2;
    return($tlfh2);
}

sub ___setdelay { my ($cb) = @_; $ENV{TRACEDELAY} = $cb; }
sub ___setcb { my ($cb) = @_; $ENV{TRACECB} = $cb; }

BEGIN
{
    ___gettfh();
    ___printheader() if ($ENV{TRACEHEADER});
}

sub import 
{
    my $package = shift;
    foreach (@_) {
        if ($_ eq 'trace') {
          my $caller = caller;
          *{$caller . '::trace'} = \&{$package . '::trace'};
        } else {
          use Carp;
          croak "Package $package does not export `$_'; aborting";
        }
    }
}

my %tracearg = ('on' => 1, 'off' => 0);
sub trace {
  my $arg = shift;
  $arg = $tracearg{$arg} while exists $tracearg{$arg};
  $TRACE = $arg;
}

sub ___junkit::AUTOLOAD
{
	no strict;
	my $method = $AUTOLOAD;
	$method =~ s".*::""sg;

	if ($Devel::EdTrace::SafeGuard)
	{
		my $args = join(",", @_);
		return("$method\($args\)");
	}
	else
	{
		my @stack = caller(3);
		&{"$stack[0]"}(@_);
	}
}

sub AUTOLOAD
{
	no strict;
	my $method = $AUTOLOAD;
	$method =~ s".*::""sg;

	if ($Devel::EdTrace::SafeGuard)
	{
		my $args = join(",", @_);
		return("$method\($args\)");
	}
	else
	{
		my @stack = caller(3);
		&{"$stack[0]"}(@_);
	}
}
1;


=head1 NAME

Devel::EdTrace - Print out each line before it is executed (like C<sh -x>)

=head1 SYNOPSIS

  perl -d:Trace program

=head1 DESCRIPTION

If you run your program with C<perl -d:Trace program>, this module
will print a message to standard error just before each line is executed.  
For example, if your program looks like this:

        #!/usr/bin/perl
        
        
        print "Statement 1 at line 4\n";
        print "Statement 2 at line 5\n";
        print "Call to sub x returns ", &x(), " at line 6.\n";
        
        exit 0;
        
        
        sub x {
          print "In sub x at line 12.\n";
          return 13;
        }

Then  the C<Trace> output will look like this:

        >> ./test:4: print "Statement 1 at line 4\n";
        >> ./test:5: print "Statement 2 at line 5\n";
        >> ./test:6: print "Call to sub x returns ", &x(), " at line 6.\n";
        >> ./test:12:   print "In sub x at line 12.\n";
        >> ./test:13:   return 13;
        >> ./test:8: exit 0;

This is something like the shell's C<-x> option.

=head1 DETAILS

Inside your program, you can enable and disable tracing by doing

    $Devel::EdTrace::TRACE = 1;   # Enable
    $Devel::EdTrace::TRACE = 0;   # Disable

or

    Devel::EdTrace::trace('on');  # Enable
    Devel::EdTrace::trace('off'); # Disable

C<Devel::EdTrace> exports the C<trace> function if you ask it to:

import Devel::EdTrace 'trace';

Then if you want you just say

    trace 'on';                 # Enable
    trace 'off';                # Disable


New features:

$Devel::EdTrace::PrintEval (or environmental variable TRACEEVAL)
    - Sets whether or not you want to have 'constant eval set on' This evaluates
	  and shows the value of the variables evaluated on a left panel of the scrren. 
	  For example:

	>> for ($xx = 0; $xx < 10; $xx++)             | for ( = 0; < 10; ++)
	>> {                                          | {
	>>     $yy = $xx;                             |    = 0
	>> }                                          | }

Note that the eval happens before the statement, not after.

$Devel::EdTrace::PrintLevel (or environmental variable TRACELEVEL)

    - sets whether or not indent is going to be turned on. 

	  If set to one, no indent is done. 

	  If set to 2, all output will be indented to the level 
	  at which the code was called (ie: the number of frames in)

$Devel::EdTrace::ExpandBuiltin (or environmental variable TRACEBUILTIN)

    - when set to 1 - and in conjunction with PrintEval, makes the functions 
	  keys, values and map be evaluated in place when evaluated

	- when set to a pipe (|) separated list, evaluates all functions in the list 
	  (eg: $ENV{TRACEBUILTIN} = 'keys|values' will evaluate keys and values functions)
	
$Devel::EdTrace::TraceSys (or environmental variable TRACESYS)

	- Causes each statement in the code to be followed by a system call (the one
	  in TRACESYS). For example

	  $ENV{TRACESYS} = 'ls'

	  will do an 'ls' before each perl statement.

Environmental variable TRACELOG

	Puts all tracing to a log (named tracelog).

Envionmental variable TRACERM

	In conjunction with TRACELOG, removes any previous tracelog before writing to the new tracelog.

=head1 Author

=begin text

Initial module by Mark-Jason Dominus (C<mjd-perl-trace@plover.com>), Plover Systems co.
Heavily modified, renamed by Edward Peschko (horos22@yahoo.com)

=end text

=begin man

Edward Peschko (horos22@gmail.com>).

=end man

=begin html
<p>Original module by Mark-Jason Dominus (<a href="mailto:mjd-perl-trace@plover.com"><tt>mjd-perl-trace@plover.com</tt></a>), Plover Systems co.</p>
<p>heavily modified by Edward Peschko (<a href="mailto:horos22@gmail.com"><tt>mjd-perl-trace@plover.com</tt></a>), Plover Systems co.</p>
<p>See <a href="http://www.plover.com/~mjd/perl/Trace/">The <tt>Devel::Trace.pm</tt> Page</a> for news and upgrades.</p>

=end html

=cut

