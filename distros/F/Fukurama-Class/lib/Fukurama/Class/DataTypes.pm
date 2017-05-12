package Fukurama::Class::DataTypes;
use Fukurama::Class::Version(0.04);
use Fukurama::Class::Rigid;

=head1 NAME

Fukurama::Class::DataTypes - Helper class to register and check datatypes

=head1 VERSION

Version 0.04 (beta)

=head1 SYNOPSIS

 package MyClass;

 BEGIN {
 	use Fukurama::Class::DataTypes();
 	Fukurama::Class::DataTypes->set_type_checker('MyOwnClass', sub {
 		my $parameter = $_[0];
 		my $data_type_checker_name = $_[1];
 
 		my $error = undef;
 		my $is_ok = 0;
 		if(ref($parameter) && UNIVERSAL::isa($parameter, 'MyOwnClass')) {
 			if($parameter->get('name') eq 'MyOwnName') {
 				$is_ok = 1;
 			} else {
 				$error = 'nameIsNotCorrect';
 			}
 		} else {
 			$error = 'notAnObject';
 		}
 		return ($is_ok, $parameter, $error);
 	});
 }
 use Fukurama::Class;
 
 # Croak, if parameter one is not an instance of 'MyOwnClass'
 # and doesn't have the name 'MyOwnName' 
 sub set_my_own_class : Method(public|MyOwnClass|boolean) {
 	...
 }

=head1 DESCRIPTION

This helper-class provides functions to register and handle check-methods for several data types.

=head1 EXPORT

-

=head1 METHODS

=over 4

=item set_type_checker( name:STRING, checker:CODE ) return:BOOLEAN

Set a check-method for a new or an existing datatype. B<Name> is the identifier string for the data type,
B<checker> is a code reference to check the data type.

Examples for B<name>: I<string> , I<boolean>, I<MySpecial::Class>
Native data types have to be in lowercase. Object data types have to start with an uppercase letter.
You should be careful when you define the identifier because object data types would be handeled different as
native data types.

An example for a type checker for a simple hash reference:

 $class->set_type_checker('hashref', sub {
 	my $parameter = $_[0];
 	my $data_type_checker_name = $_[1];
 	
 	my $error = undef;
 	my $is_ok = 0;
 	if(ref($parameter) eq 'HASH') {
 		$is_ok = 1;
 	} else {
 		$error = 'notARef';
 	}
 	return ($is_ok, $parameter, $error);
 });

=item set_ref_checker( identifier:STRING, checker:CODE ) return:BOOLEAN

Set a check-method for a new or an existing reference type. B<identifier> is the string  which identifies this
reference, B<checker> is a code referende to check the reference type.

Examples for B<identifier>: I<[]> (for array reference), I<{}> (for hash reference)

An example for a reference checker for array references:

 $class->set_ref_checker('[]'	=> sub {
 	my $data_type_checker = $_[0];
 	my $parameter = $_[1];
 	my $data_type_checker_name = $_[2];
 	my $actual_subroutine_parameter = $_[3]; # \INT
 	my $full_subroutine_parameter_list = $_[4]; # \ARRAY
 	
 	return 0 if(ref($parameter) ne 'ARRAY');
 	my $i = 0;
 	my $error = undef;
 	# Check all entries of this array reference
 	foreach my $parameter_entry (@{$parameter}) {
 		my ($is_ok, $returned_parameter, $returned_error) = &{$data_type_checker}($parameter_entry, $data_type_checker_name);
 		if(!$is_ok) {
 			$parameter->[$i] = $returned_parameter;
 			$error = [ $is_ok, $parameter, $returned_error ];
 		}
 		++$i;
 	}
 	return @$error if($error) {
 	1;
 });

=item is_ref_allowed( identifier:STRING ) return:BOOLEAN

Method to check if the given identifier has a defined reference checker.

=item get_check_definition ( type_name:STRING, ref_identifier:STRING ) return:HASHREF

For internal usage in attribute helper classes. Get the defined checker
methods for data type and the reference identifier as a hash reference.

 {
  	is_class	=> data_type_is_a_class:BOOLEAN,
 	check		=> reference_checker:CODE,
 	param_0		=> data_type_checker:CODE,
 }

=item check_parameter_definition ( type_name:STRING, parameter_definition:HASHREF ) return:BOOLEAN

For internal usage in attribute helper classes. Check the given parameter definition.

=back

=head1 AUTHOR, BUGS, SUPPORT, ACKNOWLEDGEMENTS, COPYRIGHT & LICENSE

see perldoc of L<Fukurama::Class>

=cut

my $OVERFLOW_SIGN;
BEGIN {
	my $i = 0;
	my $float;
	while(++$i) {
		$float = '1.2e+' . ($i * 100);
		my $result = ($float * 1) - $float;
		if($result ne '0') {
			$OVERFLOW_SIGN = $float * 1;
			last;
		}
		if($i > 1_000) {
			$OVERFLOW_SIGN = 'inf';
			last;
		}
	}
}
my $HAS_OVERFLOW = sub {
	($_[0] * 1) eq $OVERFLOW_SIGN;
};
# param: value:SCALAR, type:STRING
my $TYPES = {
	void	=> sub {
		return 1 if(!defined($_[0]));
		(0, $_[0]);
	},
	scalar	=> sub {
		1
	},
	scalarref	=> sub {
		return 1 if(ref($_[0]) eq 'SCALAR');
		(0, $_[0]);
	},
	arrayref	=> sub {
		return 1 if(ref($_[0]) eq 'ARRAY');
		(0, $_[0]);
	},
	hashref		=> sub {
		return 1 if(ref($_[0]) eq 'HASH');
		(0, $_[0]);
	},
	typglobref	=> sub {
		return 1 if(ref($_[0]) eq 'GLOB');
		(0, $_[0]);
	},
	string	=> sub {
		return 1 if(defined($_[0]) && !ref($_[0]));
		(0, $_[0]);
	},
	boolean	=> sub {
		return 1 if(defined($_[0]) && ($_[0] eq '0' || $_[0] eq '1'));
		(0, $_[0]);
	},
	int		=> sub {
		return 1 if(defined($_[0]) && $_[0] =~ m/^\-?[0-9]+$/ && ($_[0] * 1) eq $_[0]);
		return (0, $_[0]) if(!defined($_[0]));
		return (0, $_[0], 'noInt') if($_[0] !~ m/^\-?[0-9]+$/);
		return (0, $_[0] * 1, 'overflow') if(&$HAS_OVERFLOW($_[0]) || ($_[0] * 1) ne $_[0]);
		(0, $_[0] * 1);
	},
	float		=> sub {
		return 1 if(
			defined($_[0])
			&& ( $_[0] =~ m/^[0-9]+\.?[0-9]*$/ || $_[0] =~ m/^[0-9]+\.?[0-9]*e\+?[0-9]+/)
			&& ($_[0] * 1) == $_[0]
			&& !&$HAS_OVERFLOW($_[0])
		);
		return (0, $_[0]) if(!defined($_[0]));
		return (0, $_[0], 'NaN') if($_[0] !~ m/^[0-9]+\.?[0-9]*$/ && $_[0] !~ m/^[0-9]+\.?[0-9]*e\+?[0-9]+$/);
		return (0, $_[0] * 1, 'overflow') if(&$HAS_OVERFLOW($_[0]) || ($_[0] * 1) != $_[0]);
		(0, $_[0]);
	},
	decimal		=> sub {
		return 1 if(defined($_[0]) && $_[0] =~ m/^\-?[0-9]+\.?[0-9]*$/ && ($_[0] * 1) eq $_[0]);
		return (0, $_[0]) if(!defined($_[0]));
		return (0, $_[0], 'NaN') if($_[0] !~ m/^[0-9]+\.?[0-9]*$/ && $_[0] !~ m/^[0-9]+\.?[0-9]*e\+?[0-9]+$/);
		return (0, $_[0] * 1, 'overflow') if(&$HAS_OVERFLOW($_[0]) || ($_[0] * 1) ne $_[0]);
		return (0, $_[0], 'noDec') if($_[0] !~ m/^\-?[0-9]+\.?[0-9]*$/);
		(0, $_[0] * 1);
	},
	class		=> sub {
		return 1 if(!ref($_[0]) && UNIVERSAL::isa($_[0], $_[0]));
		(0, $_[0]);
	},
	object		=> sub {
		return 1 if(ref($_[0]) && UNIVERSAL::isa($_[0], ref($_[0])));
		(0, $_[0]);
	},
	'*class*'	=> sub {
		return 1 if(ref($_[0]) && UNIVERSAL::isa($_[0], $_[1]));
		(0, $_[0]);
	},
};
my $CLASS_TYPES = {
	class	=> 1,
	object	=> 1,
};
# param: check_sub:CODE, value:SCALAR, type:STRING, pos:\INT, all_io:\ARRAY
my $REFS = {
	''		=> sub {
		&{$_[0]}($_[1], $_[2]);
	},
	'[]'	=> sub {
		return 0 if(ref($_[1]) ne 'ARRAY');
		my $i = 0;
		my $error = undef;
		foreach my $entry (@{$_[1]}) {
			my @result = &{$_[0]}($entry, $_[2]);
			if(!$result[0]) {
				$_[1]->[$i] = $result[1];
				$error = \@result;
			}
			++$i;
		}
		if($error) {
			$error->[1] = $_[1];
			return @$error;
		}
		1;
	},
	'()'	=> sub {
		my $error = undef;
		my @io = @{$_[4]}[${$_[3]}..$#{$_[4]}];
		foreach my $entry (@io) {
			my @result = &{$_[0]}($entry, $_[2]);
			if(!$result[0]) {
				$error = \@result;
				last;
			}
		}
		${$_[3]} = $#{$_[4]};
		return @$error if($error);
		1;
	},
	'{}'	=> sub {
		return 0 if(ref($_[1]) ne 'HASH');
		my $error = undef;
		foreach my $key (keys(%{$_[1]})) {
			my $entry = $_[1]->{$key};
			my @result = &{$_[0]}($entry, $_[2]);
			if(!$result[0]) {
				$_[1]->{$key} = $result[1];
				$error = \@result;
			}
		}
		if($error) {
			$error->[1] = $_[1];
			return @$error;
		}
		1;
	}
};
# boolean
sub set_ref_checker {
	my $class = $_[0];
	my $identifier = $_[1];
	my $code = $_[2];
	
	return 0 if(!length($identifier) || ref($code) ne 'CODE');
	$REFS->{$identifier} = $code;
	return 1;
}
# boolean
sub set_type_checker {
	my $class = $_[0];
	my $identifier = $_[1];
	
	my $code = $_[2];
	
	return 0 if(!length($identifier) || ref($code) ne 'CODE');
	$TYPES->{$identifier} = $code;
	return 1;
}
# boolean
sub is_ref_allowed {
	my $class = $_[0];
	my $identifier = $_[1];
	
	return 1 if(exists($REFS->{$identifier}));
	return 0;
}
# hashref
sub get_check_definition {
	my $class = $_[0];
	my $type = $_[1];
	my $ref = $_[2];
	
	my $ref_sub = $REFS->{$ref};
	return {} if(!$ref_sub);
	
	my $is_class = 0;
	my $type_sub = $TYPES->{$type};
	if(!$type_sub) {
		return {} if($type !~ /^[A-Z]/);
		$type_sub = $TYPES->{'*class*'};
		$is_class = 1;
	}
	$is_class = 1 if($CLASS_TYPES->{$type} || $type =~ m/^[A-Z]/);
	return {
		is_class	=> $is_class,
		check	=> $ref_sub,
		param_0	=> $type_sub,
	};
}
# boolean
sub check_parameter_definition {
	my $class = $_[0];
	my $param_type = $_[1];
	my $check_def = $_[2];
	
	return 0 if(!$check_def->{'check'});
	
	return 1 if($CLASS_TYPES->{$param_type});
	if($check_def->{'is_class'}) {
		return UNIVERSAL::isa($param_type, $param_type);
	}
	1;
}
1;
