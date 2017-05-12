use File::Basename;
use Data::Dumper;
use Getopt::Long;

my $error_count = 0;
my $ln = 0;
my $loc = 0;
my $srcfile;
my $lstfile;
my $mixfile;
my $crdfile;
my $symbols = {};
my $local_symbols = {};
my $unget_token = undef;
my $byte_size = 64;
my $parse_phase = 1;
my $end_of_program = 0;
my $end_loc = 0;
my $code = undef;
my $codes = {};
my @implied_constant_words = ();
my $optable = {};
my $program_entry = -1;

GetOptions ("bytesize=i"   => \$byte_size);

if ($byte_size != 100 && $byte_size != 64) {
    print STDERR "BYTESIZE SHOULD BE 100 OR 64\n";
    exit(-1);
}

init_optable();

if (@ARGV != 1) {
	print STDERR "Usage: perl mixasm.pl <MIXALSOURCEFILE>";
	exit(1);
}
$srcfile = shift @ARGV;
my ($base, $path, $type) = fileparse($srcfile, qr{\..*});
$lstfile = $base . ".lst";
#$mixfile = $base . ".mix";
$crdfile = $base . ".crd";

########################################################################
## PARSE PHASE I
########################################################################

open FILE, "<$srcfile" || die "can't open $srcfile";

while (<FILE>) 
{
	$ln++;
#	printf "%04d: %s", $ln, remove_comment($_);
	next if m/^\s*$/;
	next if m/^\*/;
	parse1(remove_comment($_));
	last if $end_of_program;
}

if ($error_count > 0) 
{
	print STDERR "MIXASM: $error_count errors found.";
	close FILE;
	exit(1);
}


########################################################################
## PARSE PHASE II
########################################################################

seek FILE, 0, 0; ## rewind

open LSTFILE, ">$lstfile" || die "Can not open $lstfile for write";

$end_of_program = 0;
$end_loc = $loc;
$ln = 0;
$loc = 0;
my $currloc;
while (<FILE>) {
	my $srcline = $_;
	$ln++;
	$code = undef;
	$currloc = $loc;
	chop;

	my $empty = 0;
	$empty = 1 if m/^\s*$/;
	$empty = 1 if m/^\*/;
	parse2(remove_comment($_)) if !$empty;

	if (defined $code) {
		printf LSTFILE "%04d: %s ", $currloc, $code->{code};
		$codes->{$currloc} = $code;
	} else {
		print  LSTFILE ' ' x 24;
	}
	printf LSTFILE "  %4d  ", $ln;
	print LSTFILE $srcline;

	last if $end_of_program;
}

print LSTFILE "\n";

foreach (@implied_constant_words) {
	printf LSTFILE "%04d: %s \n", $_->{loc}, $_->{code};
}

close FILE;
close LSTFILE;

if ($error_count > 0) {
	print STDERR "MIXASM: $error_count errors found.";
	exit(1);
}

########################################################################
# Generating Card deck
########################################################################

open CRDFILE, ">$crdfile" || die "can not open $crdfile for write";

my @locs = sort {$a <=> $b} keys %{$codes};
my @cardbuf = ();
while (@locs) {
	if (@cardbuf == 0) {
		push @cardbuf, shift @locs;
	} else {
		if ($cardbuf[0] == $locs[0]-1 && @cardbuf < 7) {
			unshift @cardbuf, shift @locs;
		} else {
			print CRDFILE gen_card(@cardbuf), "\n";
			@cardbuf = ();
			unshift @cardbuf, shift @locs;
		}
	}
}

if (@cardbuf != 0) {
	print CRDFILE gen_card(@cardbuf), "\n";
}

if ($program_entry >= 0 && $program_entry <= 3999) {
	print CRDFILE sprintf("TRANS0%04d\n", $program_entry);
}

close CRDFILE;

sub gen_card {
	my @locs = @_;
	my $n = @locs;
	my $i = $n - 1;

	my $crd;
	
	if ($codes->{$locs[$i]}->{type} eq 'code') {
		$crd = sprintf("CODE %d%04d", $n, $locs[$i]);
	} else {
		$crd = sprintf("DATA %d%04d", $n, $locs[$i]);
	}

	my @chars     = qw(0 1 2 3 4 5 6 7 8 9);
	my @neg_chars = (" ", "A", "B", "C", "D", "E", "F", "G", "H", "I");
	for (; $i >= 0; $i--) {
		my @w = split /\s+/, $codes->{$locs[$i]}->{code};
		my $sign = shift @w;

	        if ($codes->{$locs[$i]}->{type} eq 'code') {
                    my $val = shift @w;
                    unshift @w, $val%$byte_size;
                    unshift @w, int($val/$byte_size);
                }

                my $val = 0;
                my $j;

                for ($j = 0; $j < 5; $j++) {
                    $val = $val * $byte_size + $w[$j];
                }
                my $tmp = "";
                for ($j = 0; $j < 10; $j++) {
                    if ($j == 0 && $sign eq '-') {
                        $tmp = @neg_chars[$val % 10] . $tmp;
                    } else {
                        $tmp = @chars[$val % 10] . $tmp;
                    }
                    $val = int($val/10);
                }
                $crd .= $tmp;
	}
	return $crd;
}

exit(0);

########################################################################
# Subroutines
########################################################################

sub debug {return; print $_ foreach @_ }

sub init_optable
{
    $optable = {
	NOP  => { c => 0, f => 1 },
	ADD  => { c => 1, f => 5 },
	FADD => { c => 1, f => 6 },
	SUB  => { c => 2, f => 5 },
	FSUB => { c => 2, f => 6 },
	MUL  => { c => 3, f => 5 },
	FMUL => { c => 3, f => 6 },
	DIV  => { c => 4, f => 5 },
	FDIV => { c => 4, f => 6 },
	NUM  => { c => 5, f => 0 },
	CHAR => { c => 5, f => 1 },
	HLT  => { c => 5, f => 2 },
	SLA  => { c => 6, f => 0 },
	SRA  => { c => 6, f => 1 },
	SLAX => { c => 6, f => 2 },
	SRAX => { c => 6, f => 3 },
	SLC  => { c => 6, f => 4 },
	SRC  => { c => 6, f => 5 },
	MOVE => { c => 7, f => 1 }, ## t = 1 + 2f
	LDA  => { c => 8, f => 5 },
	LD1  => { c => 9, f => 5 },
	LD2  => { c =>10, f => 5 },
	LD3  => { c =>11, f => 5 },
	LD4  => { c =>12, f => 5 },
	LD5  => { c =>13, f => 5 },
	LD6  => { c =>14, f => 5 },
	LDX  => { c =>15, f => 5 },
	LDAN => { c =>16, f => 5 },
	LD1N => { c =>17, f => 5 },
	LD2N => { c =>18, f => 5 },
	LD3N => { c =>19, f => 5 },
	LD4N => { c =>20, f => 5 },
	LD5N => { c =>21, f => 5 },
	LD6N => { c =>22, f => 5 },
	LDXN => { c =>23, f => 5 },
	STA  => { c =>24, f => 5 },
	ST1  => { c =>25, f => 5 },
	ST2  => { c =>26, f => 5 },
	ST3  => { c =>27, f => 5 },
	ST4  => { c =>28, f => 5 },
	ST5  => { c =>29, f => 5 },
	ST6  => { c =>30, f => 5 },
	STX  => { c =>31, f => 5 },
	STJ  => { c =>32, f => 2 },
	STZ  => { c =>33, f => 5 },
	JBUS => { c =>34, f => 0 },
	IOC  => { c =>35, f => 0 }, ## 1 + interlock time
	IN   => { c =>36, f => 0 }, ## 1 + interlock time
	OUT  => { c =>37, f => 0 }, ## 1 + interlock time
	JRED => { c =>38, f => 0 },
	JMP  => { c =>39, f => 0 },
	JSJ  => { c =>39, f => 1 },
	JOV  => { c =>39, f => 2 },
	JNOV => { c =>39, f => 3 },
	JL   => { c =>39, f => 4 },
	JE   => { c =>39, f => 5 },
	JG   => { c =>39, f => 6 },
	JGE  => { c =>39, f => 7 },
	JNE  => { c =>39, f => 8 },
	JLE  => { c =>39, f => 9 },

	JAN  => { c =>40, f => 0 },
	JAZ  => { c =>40, f => 1 },
	JAP  => { c =>40, f => 2 },
	JANN => { c =>40, f => 3 },
	JANZ => { c =>40, f => 4 },
	JANP => { c =>40, f => 5 },

	J1N  => { c =>41, f => 0 },
	J1Z  => { c =>41, f => 1 },
	J1P  => { c =>41, f => 2 },
	J1NN => { c =>41, f => 3 },
	J1NZ => { c =>41, f => 4 },
	J1NP => { c =>41, f => 5 },

	J2N  => { c =>42, f => 0 },
	J2Z  => { c =>42, f => 1 },
	J2P  => { c =>42, f => 2 },
	J2NN => { c =>42, f => 3 },
	J2NZ => { c =>42, f => 4 },
	J2NP => { c =>42, f => 5 },

	J3N  => { c =>43, f => 0 },
	J3Z  => { c =>43, f => 1 },
	J3P  => { c =>43, f => 2 },
	J3NN => { c =>43, f => 3 },
	J3NZ => { c =>43, f => 4 },
	J3NP => { c =>43, f => 5 },

	J4N  => { c =>44, f => 0 },
	J4Z  => { c =>44, f => 1 },
	J4P  => { c =>44, f => 2 },
	J4NN => { c =>44, f => 3 },
	J4NZ => { c =>44, f => 4 },
	J4NP => { c =>44, f => 5 },

	J5N  => { c =>45, f => 0 },
	J5Z  => { c =>45, f => 1 },
	J5P  => { c =>45, f => 2 },
	J5NN => { c =>45, f => 3 },
	J5NZ => { c =>45, f => 4 },
	J5NP => { c =>45, f => 5 },

	J6N  => { c =>46, f => 0 },
	J6Z  => { c =>46, f => 1 },
	J6P  => { c =>46, f => 2 },
	J6NN => { c =>46, f => 3 },
	J6NZ => { c =>46, f => 4 },
	J6NP => { c =>46, f => 5 },

	JXN  => { c =>47, f => 0 },
	JXZ  => { c =>47, f => 1 },
	JXP  => { c =>47, f => 2 },
	JXNN => { c =>47, f => 3 },
	JXNZ => { c =>47, f => 4 },
	JXNP => { c =>47, f => 5 },

	INCA => { c =>48, f => 0 },
	DECA => { c =>48, f => 1 },
	ENTA => { c =>48, f => 2 },
	ENNA => { c =>48, f => 3 },

	INC1 => { c =>49, f => 0 },
	DEC1 => { c =>49, f => 1 },
	ENT1 => { c =>49, f => 2 },
	ENN1 => { c =>49, f => 3 },

	INC2 => { c =>50, f => 0 },
	DEC2 => { c =>50, f => 1 },
	ENT2 => { c =>50, f => 2 },
	ENN2 => { c =>50, f => 3 },

	INC3 => { c =>51, f => 0 },
	DEC3 => { c =>51, f => 1 },
	ENT3 => { c =>51, f => 2 },
	ENN3 => { c =>51, f => 3 },

	INC4 => { c =>52, f => 0 },
	DEC4 => { c =>52, f => 1 },
	ENT4 => { c =>52, f => 2 },
	ENN4 => { c =>52, f => 3 },

	INC5 => { c =>53, f => 0 },
	DEC5 => { c =>53, f => 1 },
	ENT5 => { c =>53, f => 2 },
	ENN5 => { c =>53, f => 3 },

	INC6 => { c =>54, f => 0 },
	DEC6 => { c =>54, f => 1 },
	ENT6 => { c =>54, f => 2 },
	ENN6 => { c =>54, f => 3 },
	
	INCX => { c =>55, f => 0 },
	DECX => { c =>55, f => 1 },
	ENTX => { c =>55, f => 2 },
	ENNX => { c =>55, f => 3 },

	CMPA => { c =>56, f => 5 },
	FCMP => { c =>56, f => 6 },
	CMP1 => { c =>57, f => 5 },
	CMP2 => { c =>58, f => 5 },
	CMP3 => { c =>59, f => 5 },
	CMP4 => { c =>60, f => 5 },
	CMP5 => { c =>61, f => 5 },
	CMP6 => { c =>62, f => 5 },
	CMPX => { c =>63, f => 5 }
    };
}

# comments start with the first blank column following column 20
sub remove_comment
{
    my $line = shift;
    return $line if length($line) < 21;
    my $s1 = substr($line, 0, 20);
    my $s2 = substr($line, 20);
    $s2 =~ s/\s+.*$//;
    return $s1 . $s2;
}

sub parse1 
{
	my $get_token = tokenizer(shift);
	my $label;

	$parse_phase = 1;
	my($type, $value) = &$get_token; 
	
	## Check Label field

	if ($type eq 'LABEL') {
		$label = $value;
		if ($label =~ m/\dH/) {
			# Local symbol
		} else {
			if (exists $symbols->{$label}) {
				error("predefined symbol: '$label'");
			}
		}
		debug "Label is $label, ";
		($type, $value) = &$get_token;
	}
	
	## Op field

	if ( $type ne 'SYMBOL' ) {
		error("undefined op $value");
		return;
	}

	debug "Op is $value";

	if ( $value eq 'EQU' ) {
		if (!defined $label) {
			error("missing label");
			return;
		}
		my $val = parse_w_value($get_token);
		if (defined $val) {
			debug ", Install symbol $label with value $val\n";
			install_symbol($label, $val);
		} else {
		    error("undefined w value for EQU");
		}
	} elsif ( $value eq 'ORIG' ) {
		# undef symbol is forbidden 
		# in ORIG statement
		$parse_phase = 2; 

		my $val = parse_w_value($get_token);

		$parse_phase = 1;

		if (!defined $val) {
			error("bad ORIG operand");
		} else {
			$loc = $val;
			debug ", set loc = $val";
			if (defined $label) {
				debug ", Install symbol $label with value $loc\n";
				install_symbol($label, $val);
			}
		}
	} elsif ( $value eq 'ALF' ) {
		if (defined $label) {
			debug ", Install symbol $label with value $loc\n";
			install_symbol($label, $loc);
		}
		$loc++;
	} elsif ( $value eq 'CON' ) {
		if (defined $label) {
			debug ", Install symbol $label with value $loc\n";
			install_symbol($label, $loc);
		}
		$loc++;
	} elsif ( $value eq 'END' ) {
		my $val = parse_w_value($get_token);
		if (defined $val) {
		    $program_entry = $val;
		} else {
		    error("invalid w value for END");
		}
		$end_of_program = 1;
	} else {
		if (!exists $optable->{$value}) {
			error("undefined op: $value");
		}
		if (defined $label) {
			debug ", Install symbol $label with value $loc\n";
			install_symbol($label, $loc);
		}
		$loc++;
	}
	
	debug "\n";
	$unget_token = undef;
}

sub parse_w_value
{
    my $get_token = shift;
    my $w = 0;
NEXT_W_VALUE:
    my $a = parse_expr($get_token);
    return undef if !defined $a;
    my ($type, $value) = $get_token->();
    if ($type eq '(') {
	my $f = parse_expr($get_token);
	return undef if !defined $f;
	($type, $value) = $get_token->();
	return undef if $type ne ')';

	# Calculate new w value
	my $l = int($f / 8);
	my $r = $f % 8;
	my $sign = ($w >= 0?1:-1);
	$w = - $w if $w < 0;
	$sign = ($a >= 0?1:-1) if $l == 0;
	$a = - $a if $a < 0;	
	if ($r == 0) {
	    $w = $sign * $w;
	} else {
	    my $wl = 0;
	    $wl = $w % ($byte_size ** (5-$r)) if $r < 5;
	    my $wh = ($w - ($w%($byte_size ** (6-$l))));
	    $a = $a % ($byte_size ** ($r - $l + 1));
	    $a = $a * ($byte_size ** (5-$r)) if $r < 5;
	    $w = $sign * ($wl + $wh + $a);
	}
	($type, $value) = $get_token->();
	return $w if $type ne ',';
	goto NEXT_W_VALUE;
    } elsif ($type eq ',') {
	# No field spec.
	# no matter whether w has been set or not, we have
	$w = $value;
	goto NEXT_W_VALUE;
    } elsif (!defined $type) {
	return $a;
    } elsif ($type eq '=') {
	$unget_token = [$type, $value];
	return $w;
    } else {
	return undef;
    }
}

sub parse_expr
{
	my $get_token = shift;
	my $retval = 0;
	my ($type, $value) = &$get_token();
	my $undef_sym_is_seen = 0;

	# Get the first operand. If the first token is +/-,
	# use the default operand 0

	if ($type eq '-' || $type eq '+') { # unary op
		$unget_token = [$type, $value];
	} elsif ($type eq '*') {
		$retval = $loc;
	} elsif ($type eq 'INTEGER') {
		$retval = $value;
	} elsif ($type eq 'SYMBOL') {
		my $tmp = get_symbol_value($value);
		if (!defined $tmp) {
			if ($parse_phase == 1) {
				$undef_sym_is_seen = 1;
			} else {
				error("undefined symbol: '$value'");
				return;
			}
		} else {
			$retval = $tmp;
		}
	} else {
		error("expecting integer or symbol, but get '$value'");
		$unget_token = [$type, $value];
		return;
	}
	
	# Loop: find op and operand 2
	#       Use retval as the operand 1
        #       Calculate new retval by computing (opr1 op opr2)
	while ( ($type, $value) = &$get_token() ) {
		last if !defined $type;

		# End expr when encountering "(" or "=" or ","
		if (! is_op($type)) {
			$unget_token = [$type, $value]; 
			last;
		} 

		my $op = $value;

		($type, $value) = &$get_token();

		if (!defined $type) {
			error("operand missing");
			return;
		}
		my $tmp;
		if ($type eq '*') {
			$tmp = $loc;		
		} elsif ($type eq 'INTEGER') {
			$tmp = $value;
		} elsif ($type eq 'SYMBOL') {
			$tmp = get_symbol_value($value);
			if (!defined $tmp) {
				if ($parse_phase == 1) {
					$undef_sym_is_seen = 1;
				} else {
					error("undefined symbol: '$value'");
					return;
				}
			}
		} else {
			error("expecting integer or symbol, but get '$value'");
			$unget_token = [$type, $value];
			return;
		}
		next if $undef_sym_is_seen;
		
		$retval = do_op($op, $retval, $tmp);
	}
	return undef if $undef_sym_is_seen;
	return $retval;
}

sub do_op 
{
	my ($op, $operand1, $operand2) = @_;
	return $operand1 + $operand2 if $op eq '+';
	return $operand1 - $operand2 if $op eq '-';
	return $operand1 * $operand2 if $op eq '*';
	return $operand1 * 8 + $operand2 if $op eq ':';
	return int($operand1 / $operand2) if $op eq '/';
	if ($op eq '//') {
		my $tmp = $byte_size * $byte_size * $byte_size * $byte_size * $byte_size;
		return int(($operand1 * $tmp) / $operand2);
	}
	error("bad op: '$op'");
	return undef;
}

sub is_op {
	my $t = @_[0];
	return $t eq ':' || $t eq '+' || $t eq '-' || $t eq '*' || $t eq '/' || $t eq '//'; 
}

# FIXME: local symbol
sub get_symbol_value
{
	my ($sym) = @_;

	if ($sym =~ m/(\d)[fF]/) {
		my $nearline = -1;
		my $target = $1 . 'H';
		foreach (sort keys %{$local_symbols}) {
			my $tmp = $local_symbols->{$_}->{symbol};
			if ($tmp eq $target && $_ > $ln) {
				if ($nearline == -1) {
					$nearline = $_;
				} elsif ($_ < $nearline) {
					$nearline = $_;
				}
			}
		}
		return undef if $nearline < 0;
		return $local_symbols->{$nearline}->{value};
	} elsif ($sym =~ m/(\d)[bB]/) {
		my $nearline = -1;
		my $target = $1 . 'H';
		foreach (sort keys %{$local_symbols}) {
			my $tmp = $local_symbols->{$_}->{symbol};
			if ($tmp eq $target && $_ <= $ln) {
				if ($nearline == -1) {
					$nearline = $_;
				} elsif ($_ > $nearline) {
					$nearline = $_;
				}
			}
		}
		return undef if $nearline < 0;
		return $local_symbols->{$nearline}->{value};
		
	} else {
		return undef if !exists $symbols->{$sym};
		return $symbols->{$sym}->{value};
	}
}

sub install_symbol 
{
	my ($sym, $value) = @_;

	if ($sym =~ m/\dH/) {
		$local_symbols->{$ln}->{symbol} = $sym;
		$local_symbols->{$ln}->{value}  = $value;
	} else {
		$symbols->{$sym}->{value} = $value;
		$symbols->{$sym}->{line}  = $ln;
	}
}

sub parse2 
{
	my $src = shift;
	my $get_token = tokenizer($src);
	my $label;

	$parse_phase = 2;
	my($type, $value) = &$get_token; 
	
	## Check Label field

	if ($type eq 'LABEL') {
		$label = $value;
		($type, $value) = &$get_token;
	}
	
	## Op field
	if ( $value eq 'EQU' ) {
		if (!exists $symbols->{$label}) { ## Do evaluation
			my $val = parse_w_value($get_token);
			if (defined $val) {
				debug "Install symbol $label with value $val\n";
				$symbols->{$label}->{value} = $val;
			} else {
				error("can not determine the value of '$label'");
			}
		}
	} elsif ( $value eq 'ORIG' ) {
		$loc = parse_w_value($get_token);
	} elsif ( $value eq 'ALF' ) {
		if (length($src) < 21) {
			error("error ALF instruction, no enough chars");
		} else {
			$code->{type} = 'data';
			$code->{code} = string_to_word(substr($src, 16, 5));
		}
		$loc++;
	} elsif ( $value eq 'CON' ) {
		my $tmp = parse_w_value($get_token);
		if (!defined $tmp) {
			error("cannot determine the value of operand");
		} else {
			$code->{type} = 'data';
			$code->{code} = constant_to_word($tmp);
		}
		$loc++;
	} elsif ( $value eq 'END' ) {
		$end_of_program = 1;
	} else {
		my $op = $value;
		my $c  = $optable->{$op}->{c};
		my $f  = $optable->{$op}->{f};
		my $m  = 0;
		my $i  = 0;
		my $error = 0;
		my $create_constant_word = 0;

		($type, $value) = &$get_token();
		if (defined $type) {
			if ($type eq '=') {
				$create_constant_word = 1;	
			} else {
				$unget_token = [$type, $value];
			}
			my $tmp = parse_expr($get_token);

			if (defined $tmp) {
				$m = $tmp;
				($type, $value) = &$get_token();
			} elsif ($create_constant_word) {
				$error = 1;
			}

			if ($create_constant_word) {
				($type, $value) = &$get_token();
				$m = $end_loc;
				$codes->{$end_loc}->{code} = constant_to_word($tmp);
				$codes->{$end_loc}->{type} = 'data';
				push @implied_constant_words, {
					loc =>  $end_loc,
					code =>	constant_to_word($tmp)
				};
				$end_loc++;
			}
			if (!$error && $type eq ',') {
				$tmp = parse_expr($get_token);
				if (defined $tmp) {
					$i = $tmp;
					($type, $value) = &$get_token();
					if (defined $type) {
						if ($type eq '(') {
							$tmp = parse_expr($get_token);
							if (defined $tmp) {
								$f = $tmp;
								($type, $value) = &$get_token();
								if (!defined $type || $type ne ')') {
									error("missing ')'");
									$error = 1;
								}
							} else {
								error("expecting field, unexpected token: '$value'");
								$error = 1;
							}
						} else {
							error("unexpected token: '$value'");	
							$error = 1;
						}
					}
				} else {
					error("unexpected token: '$value'");
								$error = 1;
				}
			} elsif (!$error && $type eq '(') {
				$tmp = parse_expr($get_token);
				if (defined $tmp) {
					$f = $tmp;
					($type, $value) = &$get_token();
					if (!defined $type || $type ne ')') {
						error("unexpected token: '$value'");
						$error = 1;
					}
				} else {
					error("unexpected token: '$value'");
					$error = 1;
				}
			} elsif ($error) {
				error("unexpected token: '$value'");
				$error = 1;
			}
		}
		if (!$error) {
		  if ($i > 6) {
		    error("index register number overflow");
		    $error = 1;
		  } else {
		    my $tmpword = sprintf "%s   %4d %2d %2d %2d", $m>=0?'+':'-', $m>=0?$m:(-$m), $i, $f, $c;
		    $code = { type=>'code', code=>$tmpword };
		  }
		}
		$loc++;
	}

	$unget_token = undef;
}

sub constant_to_word
{
	my ($tmp) = @_;
	my $sign;
	my $tmpword = "";

	if ($tmp < 0) {
		$sign = '-';
		$tmp  = - $tmp;
	} else {
		$sign = '+';
	}
	for (1 .. 5) {
		my $r = $tmp % $byte_size;
		$tmp = int($tmp/$byte_size);
		$tmpword = ($r<10?"  ":" ") . $r . $tmpword;
	}
	return $sign . " " . $tmpword;
}

sub string_to_word
{
	my ($str) = @_;
	my $word = "+ ";
	my $len = length $str;
	$len = 5 if $len > 5;
	for ( 0 .. ($len-1) ) {
		my $ch = substr $str, $_, 1;
		my $tmp = get_char_code($ch);
		$word = $word . ($tmp<10?"  ":" ") . $tmp;
	}
	for ( $len .. 4 ) {
		$word = $word . "  0";
	}
	return $word;
}


sub get_char_code 
{ 
	my ($ch) = @_;
	my $charset = " ABCDEFGHI^JKLMNOPQR^^STUVWXYZ0123456789.,()+-*/=\$<>@;:'";
	return index($charset, $ch); 
}

sub code_to_char 
{ 
	my $charset = " ABCDEFGHI^JKLMNOPQR^^STUVWXYZ0123456789.,()+-*/=\$<>@;:'";
	return undef if $_[0] < 0 || $_[0] >= length($charset);
	return substr($charset, $_[0], 1);
}


sub tokenizer
{
	my $src = shift;
	return sub { 
		if (defined $unget_token) {
			my @tok = @$unget_token;
			$unget_token = undef;
			return @tok;
		}
	TOKEN: {
		return ( 'LABEL', $1 )    if $src =~ /^(\w+)/gcx;
#		return ( 'INTEGER', $1*8+$2) if $src =~ /\G(\d+)\:(\d+)/gcx;
		return ( 'INTEGER', $1 )  if $src =~ /\G(\d+)\b/gcx;
		return ( 'SYMBOL', $1 )   if $src =~ /\G(\w+)/gcx;
		return ( '+', $1 )        if $src =~ /\G(\+)/gcx;
		return ( '-', $1 )        if $src =~ /\G(\-)/gcx;
		return ( '*', $1 )        if $src =~ /\G(\*)/gcx;
		return ( ':', $1 )        if $src =~ /\G(\:)/gcx;
		return ( '//', $1 )       if $src =~ /\G(\/\/)/gcx;
		return ( '/', $1 )        if $src =~ /\G(\/)/gcx;
		return ( '(', $1 )        if $src =~ /\G(\()/gcx;
		return ( ')', $1 )        if $src =~ /\G(\))/gcx;
		return ( '=', $1 )        if $src =~ /\G(\=)/gcx;
		return ( ',', $1)         if $src =~ /\G(,)/gcx;
		return ( 'STRING', $1)    if $src =~ /\G\"([^\"]*)\"/gcx; 
		redo TOKEN                if $src =~ /\G\s+/gcx;
		return ( 'UNKOWN', $1 )   if $src =~ /\G(.)/gcx;
		return;
	} };
}


sub error 
{ 
	print STDERR "Error: $srcfile: Line $ln: ";
	print STDERR $_ foreach @_;
	print STDERR "\n";
	$error_count++;
}

sub print_symbols 
{
	foreach (keys %{$symbols}) {
		print "$_ = ", $symbols->{$_}->{value}, ", defined at line ", $symbols->{$_}->{line}, "\n";
	}
	foreach (sort keys %{$local_symbols}) {
		print "Line $_: ", $local_symbols->{$_}->{symbol}, " = ", $local_symbols->{$_}->{value}, "\n";
	}
}

sub word_to_string
{
	my $retval = "";
	my @w = @_;
	foreach (@w) {
		next if ($_ eq '+' || $_ eq '-');
		my $c = code_to_char($_);
		if (defined $c) {
			$retval .= $c;
		} else {
			$retval .= "?";
		}
	}
	return $retval;
}

sub code_to_data_word
{
	my ($w) = @_;
	my @w = split /\s+/, $w;
	return sprintf "%s  %2d %2d %2d %2d %2d", 
		$w[0], 
		int($w[1] / $byte_size), 
		$w[1] % $byte_size, 
		$w[2], $w[3], $w[4];
}

sub print_op_table
{
    my @ops = sort keys %$optable;
    my $i = 1;
    foreach (@ops) {
	printf "    " if $i % 5 == 1;
	printf "%-5s%3s%2s   ", $_, $optable->{$_}->{c}, $optable->{$_}->{f};
	printf "\n" if $i % 5 == 0;
	$i++;
    }
    print "\n";
}

__END__

=head1 SYNOPSIS

    perl mixasm.pl <inputfile>

=head1 DESCRIPTION


=head1 OUTPUT

=over 4

=item file dot crd

A file contains card deck produced by assembler. 
Each line is regarded as a card, holding no more than 80 characters.
For example, the content of C<primes.crd>:

    DATA 101000000000002
    DATA 5199501031018470001611333000219642003200942250321184086
    DATA 120240000002035
    DATA 320490000002010000000049I0000000003
    CODE 730000000001187053739552905376576740000262193015702869807906264090000524338
    CODE 730070000524467000000017600000083750025964868078800497500259649200000262195
    CODE 730140788529575078721847105229784690533463220001310738A01313341970025973064
    CODE 730210000000069000001718300002622600013107317079167505300000175730006308172
    CODE 2302807914127810000000133
    TRANS03000

This file serves as input to the loader of simulator C<mixsim.pl>. 
Columns 1-5 are ignored. The C<DATA>, C<CODE>, and C<TRANS> are there only for
documenting the type of each card.
Column 6 is the number of consecutive words on this card.
Columns 7-10 is the location of word 1, which is always greater than 100, so it
does not overlay the loading router.
Columns 11-20, 21-30, ..., 71-80 are the words to be loaded.

For example, a card which has

    DATA 320490000002010000000049I0000000003

should cause the following information to be loaded:

    2049: + 0000002010
    2050: - 0000000499
    2051: + 0000000003

You may have noticed that the word "000000049I" is loaded as "-499".
That is a tricky way to punch sign of word on card without using additional characters.

    SPACE 0
      A   1
      B   2
      C   3
      D   4
      E   5
      F   6
      G   7
      H   8
      I   9

If the least significant digit is among the special characters above,
the sign of word it represents is negative.

If the column 6 is `0', then this card is a transfer card. That means, 
after the loader reads this card, MIX jumps to location punched
in columns 7-10.

=item file dot lst

MIXAL program listing, 
with the assembled words and source lines sitting side by side.

=back

=head1 MIXAL SYNTAX

General rules:

    1. No tabs allowed.
    2. Lines started with star will be ignored.
    3. Empty lines are ignored.

Source line can be separated into four fields:

    1. Label field: columns 1-10
    2. Op field: columns 11-15
    3. Address field: from columns 16 to the first blank column
    4. Comment field: after column 20, started with a blank column.

Whitespaces are important in MIXAL programs.
They are used for separating label from op, and op from operands.
There should be no spaces in address field. 

    CHANGEM   ENT2  0,3    => OK
    CHANGEM   ENT2  0, 3   => ERROR

