package Eixo::Base::Util;

use strict;
use warnings;

use Scalar::Util;

use Attribute::Handlers;

#
# Signature-based validation 
#
my $EQUIVALENCES = {

	i => 'integer',
	f => 'float',
	s => 'string',
	b => 'boolean',
	o => 'object',
};

#
# Signature of the subroutine
#
sub UNIVERSAL::Sig :ATTR(CODE){

	my ($pkg, $sym, $code, $attr_name, $data) = @_;

	unless(ref($data)){

		$data = [split(/\s*\,\s*/, $data)];	
	
	}

	my @e = @$data;

	my @validators;

	my $arg_n = 0;

	foreach my $e (@e){

		my ($n, $expected_value) = ($arg_n++, $e);

		if($e =~ /^([\d|\*]+)\:(.+)$/){
			($n, $expected_value) = ($1, $2);
		}

		push @validators, [&__createValidator($n, $expected_value, $pkg), $expected_value, $n];

	}

	my $f_v = sub {

		foreach my $validator (@validators){
			
			unless($validator->[0]->(\@_)){

				my $expected_value = $EQUIVALENCES->{$validator->[1]} || $validator->[1];

				die(*{$sym}{NAME} . ': expected value \'' . $expected_value . '\' in arg (' . $validator->[2] . ')');

			}
		}

	};

	no warnings 'redefine';
	
	*{$sym} = sub {
	
		$f_v->(@_);
		
		$code->(@_);

	}

}

	sub __createValidator{
		my ($dim, $expected_value, $pkg) = @_;

		sub {
			my $args = $_[0];

			if($dim eq '*') {
 
				foreach(@$args){

					return unless(&__v($_, $expected_value));
				}

				return 1;

			}
			else{

				&__v($args->[$dim], $expected_value, $pkg);
			}
		}

	}


	my $PERL_REFS_REG = qr/^(SCALAR|ARRAY|HASH|CODE|GLOB|RegExp)$/o;

	sub __v{
		my ($v, $e, $pkg) = @_;

		if($e eq 'b'){
			return !defined($v) || $v == 1
		}
		elsif(!defined($v)){
			return undef;
		}
		elsif($e eq 'i'){
			return $v =~ /^(\-)?\d+$/;			
		}
		elsif($e eq 'f'){
			return $v =~ /^(\-)?\d+\.\d+$/;
		}
		elsif($e eq 's'){
			return !ref($v) 
		}
		elsif($e eq 'o'){
			return &Scalar::Util::blessed($v);
		}
		elsif($e eq 'self'){

			&Scalar::Util::blessed($v) && $v->isa($pkg)			

		}
		elsif($e =~ $PERL_REFS_REG){
			return ref($v) eq $e;
		}
		else{

			return ref($v) 

				&& ref($v) !~ $PERL_REFS_REG

				&& $v->isa($e);

		}

	}

1;

