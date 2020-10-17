#!/usr/bin/env perl
# PODNAME: symbolics.pl
# ABSTRACT: Extract operators and generate XS for dispatching to operators

use FindBin;
use lib "$FindBin::Bin/../lib";

use Modern::Perl;
use File::Spec;
use Alien::Kiwisolver;
use List::UtilsBy qw(nsort_by);

my $namespace = "Intertangle::API::Kiwisolver";

my @types = (
	"double",
	"const Constraint&",
	"const Expression&",
	"const Term&",
	"const Variable&",
);
my %type_order = map { $types[$_] => $_ } 0..@types-1;

my %ops_cpp_to_perl = (
	'2-'  => { cpp => '-',  overload => '-',   name => '_op_minus'   },
	'2+'  => { cpp => '+',  overload => '+',   name => '_op_add'     },
	'2*'  => { cpp => '*',  overload => '*',   name => '_op_mult'    },
	'2/'  => { cpp => '/',  overload => '/',   name => '_op_div'     },
	'2>=' => { cpp => '>=', overload => '>=',  name => '_op_num_ge'  },
	'2==' => { cpp => '==', overload => '==',  name => '_op_num_eq'  },
	'2<=' => { cpp => '<=', overload => '<=',  name => '_op_num_le'  },
	'1-' =>  { cpp => '-',  overload => 'neg', name => '_op_neg'     },
	'2|' =>  { cpp => '|',  overload => '|',   name => '_op_or'      },
);

sub type_to_kiwi_CPP {
	my ($type) = @_;
	return $type if($type eq 'double');
	$type =~ s/(?:const )?(\w+)(?:\&)?/kiwi::$1/r;
}

sub type_to_Perl_NS {
	my ($type) = @_;
	return $type if($type eq 'double');
	$type =~ s/const (\w+)&/${namespace}::$1/r;
};

sub read_symbolic_h {
	my $symbolics_h = File::Spec->catfile(
		Alien::Kiwisolver->new->dist_dir,
		qw(include kiwi symbolics.h)
	);
	open(my $symbolics_fh, '<', $symbolics_h);

	my $operator_func = qr,
		(?<ReturnType> \w+)
		\s+
		operator
		(?<Operator> [-|*/+<>=]+)
		\(
			\s*
			(?<ParamsString> [^)]* )
			\s*
		\)
	,x;
	my $param = qr, (?<Type> ([\w\s*&]+)+ ) \s+ (?<Name> \w+),x;

	my @operators;
	while(defined( my $line = <$symbolics_fh> )) {
		chomp $line;
		next unless $line =~ $operator_func;
		my $function = { line => $line, %+ };
		$function->{Params} = [ map {
			$_ =~ $param;
			+{ %+ };
		} split /\s*,\s*/, delete $function->{ParamsString} ];

		push @operators, $function;
	}

	return \@operators;
}

sub operator_group {
	my ($operators) = @_;
	my %swap_exists;
	for my $op (@$operators) {
		if( $op->{Params}[0]{Type} eq 'double' ) {
			my $type = $op->{Params}[1]{Type};
			$swap_exists{$op->{Operator}}{$type} = 1;
		}
	}

	my %op_groups;
	for my $op (@$operators) {
		my $main_type = $op->{Params}[0]{Type};
		next if $main_type eq 'double';

		my $data;
		$data = { %$op };
		$data->{Swap} = @{ $op->{Params} } > 1
			&& exists $swap_exists{$op->{Operator}}{$main_type}
			&& $op->{Params}[1]{Type} eq 'double';
		my $operator = "" . ( 0+@{ $op->{Params} } ) . $op->{Operator};

		push @{ $op_groups{ $main_type }{ $operator } }, $data;
	}

	\%op_groups;
}

sub is_op_binary {
	my ($op) = @_;
	my $binary_op = $op =~ /^2/;
}

sub op_proto {
	my ($op, $type) = @_;
	print <<"EOF";
SV* @{[ $ops_cpp_to_perl{ $op }{name} ]} ( @{[ type_to_kiwi_CPP($type) ]}* a, Sv b, bool swap ) : OVERLOAD(@{[ $ops_cpp_to_perl{ $op }{overload} ]}) {
EOF
}

sub main {
	my $op_groups = operator_group( read_symbolic_h() );

	my @types =
		# grep { /Variable/ }
		nsort_by { $type_order{$_} }
		keys %$op_groups;

	PACKAGE:
	for my $type (@types) {
		my $ops_for_type = $op_groups->{$type};

		say <<"EOF";

MODULE = $namespace                PACKAGE = @{[ type_to_Perl_NS($type) ]}


EOF

		my @ops = sort keys %$ops_for_type;
		OP:
		for my $op_key (@ops) {
			my @dispatch_op = nsort_by {
				my $n_params = scalar @{ $_->{Params} };
				my $n_key = 10 * $n_params;
				if( $n_params > 1 ) {
					$n_key += $type_order{$_->{Params}[1]{Type}}
				}
				$n_key;
			} @{ $ops_for_type->{$op_key} };

			op_proto( $op_key, $type );

			if(  is_op_binary($op_key) ) {
			# Binary
			my @branches;
			push @branches, <<EOF;
if( ! b.defined() ) {
	throw std::invalid_argument( "$namespace: operation @{[ $ops_cpp_to_perl{ $op_key }{overload} ]} with undef operand" );
}
EOF
			for my $dyn (@dispatch_op) {
				my $dyn_type = $dyn->{Params}[1]{Type};
				my $ret_type = $dyn->{ReturnType};
				my $branch = "";
				$branch .= "// @{[ $dyn->{line} ]} @{[ $dyn->{Swap} ? ' (SWAP)' : '' ]}" . "\n";
				if( $dyn_type ne 'double' ) {
					$branch .= "if( xs::Object(b).isa(\"@{[ type_to_Perl_NS($dyn_type) ]}\") ) {" . "\n";
					$branch .= "\t" . join " ", (
						"@{[ type_to_kiwi_CPP($ret_type) ]}* result",
						"=",
						"new @{[ @{[ type_to_kiwi_CPP($ret_type) ]} ]} (",
							"*a",
							"@{[ $ops_cpp_to_perl{$op_key}{cpp} ]}",
							"*( xs::in<@{[ type_to_kiwi_CPP($dyn_type) ]}*>(b) )",
						");\n",
					);
				} else {
					$branch .= "if( ! b.is_object() && b.is_like_number() ) {\n";
					$branch .= "\t@{[ type_to_kiwi_CPP($ret_type) ]}* result;\n",
					my $cpp_a  = "*a";
					my $cpp_op = "@{[ $ops_cpp_to_perl{$op_key}{cpp} ]}";
					my $cpp_b  = "( xs::in<@{[ type_to_kiwi_CPP($dyn_type) ]}>(b) )";
					if( $dyn->{Swap} ) {
					$branch .= "\tif( ! swap ) {\n";
					$branch .= "\t\t" . join " ", ( "result", "=", "new @{[ @{[ type_to_kiwi_CPP($ret_type) ]} ]} (", $cpp_a, $cpp_op, $cpp_b, ");\n" );
					$branch .= "\t} else {\n";
					$branch .= "\t\t" . join " ", ( "result", "=", "new @{[ @{[ type_to_kiwi_CPP($ret_type) ]} ]} (", $cpp_b, $cpp_op, $cpp_a, ");\n" );
					$branch .= "\t}\n";
					} else {
					$branch .= "\t" . join " ", ( "result", "=", "new @{[ @{[ type_to_kiwi_CPP($ret_type) ]} ]} (", $cpp_a, $cpp_op, $cpp_b, ");\n" );
					}
				}
				$branch .= "\t". "RETVAL = xs::out<@{[ type_to_kiwi_CPP($ret_type) ]}*>(result, NULL).detach();" . "\n";
				#$branch .= "\t". "RETVAL = sv_2mortal(RETVAL);" . "\n";
				$branch .= "}";
				push @branches, $branch;
			}
			say join "\n\telse\n", map { s/^/\t/mgr } @branches;
			} else {
			# Unary
			my $dyn = $dispatch_op[0];
			my $ret_type = $dyn->{ReturnType};
			my $branch = "";
			$branch .= "// @{[ $dyn->{line} ]}" . "\n";
			$branch .= join " ", (
				"@{[ type_to_kiwi_CPP($ret_type) ]}* result",
				"=",
				"new @{[ @{[ type_to_kiwi_CPP($ret_type) ]} ]} (",
					"@{[ $ops_cpp_to_perl{$op_key}{cpp} ]}",
					"(*a)",
				");\n",
			);
			$branch .= "RETVAL = xs::out<@{[ type_to_kiwi_CPP($ret_type) ]}*>(result, NULL).detach();";
			$branch =~ s/^/\t/mg;
			say $branch;
			}

			say "}\n";
		}
	}
}

main;
