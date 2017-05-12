package Fukurama::Class::Attributes::OOStandard::InheritationCheck;
use Fukurama::Class::Version(0.02);
use Fukurama::Class::Rigid;
use Fukurama::Class::Carp;
use Fukurama::Class::Tree();

my $AVOID_DOUBLE_INHERIT_ERRORS = {};
my $IGNORE_UNOVERWRITABLE_TYPE = {
	'implements'	=> 1,
};

=head1 NAME

Fukurama::Class::Attributes::OOStandard::InheritationCheck - Helper-class to check the inheritation of code attributes

=head1 VERSION

Version 0.02 (beta)

=head1 SYNOPSIS

- (its only a collection of methods, it's unusable outside of it's own context :)

=head1 DESCRIPTION

A helper class for Fukurama::Class::Attributes::OOStandard to check code attribute syntax.

=head1 EXPORT

-

=head1 METHODS

=over 4

=item check_inheritation( method_name:STRING, parent_class:CLASS, child_class:CLASS, inheritation_type:STRING, definition_data:\HASH ) return:VOID

Check the inheritations of all defined declarations to avoid differend method signatures for parent and child.

=back

=head1 AUTHOR, BUGS, SUPPORT, ACKNOWLEDGEMENTS, COPYRIGHT & LICENSE

see perldoc of L<Fukurama::Class>

=cut

# STATIC void
sub _check_level_contains {
	my $class = $_[0];
	my $level = $_[1];
	
	{
		
		no strict 'refs';

		_croak("Internal error: check-level '$level' is not defined in attribute-class") if(!defined(${"Fukurama\::Class\::Attributes\::OOStandard\::$level"}));
		return 1 if($Fukurama::Class::Attributes::OOStandard::CHECK_LEVEL >= ${"Fukurama\::Class\::Attributes\::OOStandard\::$level"});
	}
	return 0;
}
# STATIC void
sub check_inheritation {
	my $class = $_[0];
	my $method_name = $_[1];
	my $parent_class = $_[2];
	my $child_class = $_[3];
	my $inheritation_type = $_[4];
	my $definition_data = $_[5];
	
	return if(!$class->_check_level_contains('LEVEL_CHECK_SYNTAX'));
	
	my $parent_id = "$parent_class\::$method_name";	
	my $child_id = "$child_class\::$method_name";
	
	if(Fukurama::Class::Tree->is_special_sub($method_name)) {
		if($definition_data->{'register'}->{$parent_id}) {
			$class->_throw_inherit_error("You can't defined any attribute for perl-intern subroutine", $parent_class, $method_name);
		}
		if($definition_data->{'register'}->{$child_id}) {
			$class->_throw_inherit_error("You can't defined any attribute for perl-intern subroutine", $child_class, $method_name);
		}
		return;
	}
	
	my $parent_exist = 0;
	my $child_exist = 0;
	{
		
		no strict 'refs';
		
		$parent_exist = 1 if(*{$parent_id}{'CODE'});
		$child_exist = 1 if(*{$child_id}{'CODE'});
	}
	
	my $parent = $definition_data->{'register'}->{$parent_id};
	my $child = $definition_data->{'register'}->{$child_id};
	if($class->_check_level_contains('LEVEL_CHECK_FORCE_ATTRIBUTES')) {
		if(!$definition_data->{'register'}->{$parent_id} && $parent_exist) {
			$class->_throw_inherit_error("You don't have defined any attribute for", $parent_class, $method_name);
		}
		if(!$definition_data->{'register'}->{$child_id} && $child_exist) {
			$class->_throw_inherit_error("You don't have defined any attribute for", $child_class, $method_name);
		}
		$class->_check_attribute_inheritation($parent, $parent_exist, $parent_class, $child, $child_exist, $child_class, $method_name);
	}
	$class->_check_inheritation_type($parent, $parent_exist, $parent_class, $child, $child_exist, $child_class, $method_name, $inheritation_type, $definition_data);
	
	if($parent_exist && $parent && $child_exist && $child) {
		$class->_compare_definitions($parent, $child, $definition_data);
	} 
	return;
}
# STATIC void
sub _check_attribute_inheritation {
	my $class = $_[0];
	my $parent = $_[1];
	my $parent_exist = $_[2];
	my $parent_class = $_[3];
	my $child = $_[4];
	my $child_exist = $_[5];
	my $child_class = $_[6];
	my $method_name = $_[7];
	
	if($parent_exist && $parent && $child_exist && !$child) {
		$class->_throw_inherit_error("You don't have defined any attribute for child of " .
			"'$parent_class->$method_name', which has an attribute ", $child_class, $method_name);
	}
	return;
}
# STATIC void
sub _check_inheritation_type {
	my $class = $_[0];
	my $parent = $_[1];
	my $parent_exist = $_[2];
	my $parent_class = $_[3];
	my $child = $_[4];
	my $child_exist = $_[5];
	my $child_class = $_[6];
	my $method_name = $_[7];
	my $inheritation_type = $_[8];
	my $definition_data = $_[9];

	return if(!$parent_exist || !$parent);
	
	if($definition_data->{'type'}->{$parent->{'type'}} eq 'unoverwritable') {
		if($child_exist && !$IGNORE_UNOVERWRITABLE_TYPE->{$inheritation_type}) {
			$class->_throw_inherit_error("You've overwritten the method '$parent_class->$method_name', " .
				"which is defined as '$parent->{'type'}'", $child_class, $method_name, $inheritation_type);
		}
	} elsif($definition_data->{'type'}->{$parent->{'type'}} eq 'overwrite') {
		if(!$child_exist) {
			$class->_throw_inherit_error("You don't have overwritten the method '$parent_class->$method_name', " .
				"which is defined as '$parent->{'type'}'", $child_class, $method_name);
		}
	}
	if($definition_data->{'access_level_type'}->{$parent->{'access_level'}} eq 'unoverwritable') {
		if($child_exist && !$IGNORE_UNOVERWRITABLE_TYPE->{$inheritation_type}) {
			$class->_throw_inherit_error("You've overwritten the method '$parent_class->$method_name', " .
				"which is defined as '$parent->{'access_level'}'", $child_class, $method_name);
		}
	}
	return;
}
# STATIC void
sub _compare_definitions {
	my $class = $_[0];
	my $parent = $_[1];
	my $child = $_[2];
	my $definition_data = $_[3];
	
	if($parent->{'sub_data'}->{'attribute'} ne $child->{'sub_data'}->{'attribute'}) {
		$class->_throw_compare_error("Child and parent have to be the same subroutine type ($parent->{'sub_data'}->{'attribute'})", $parent, $child);
	}
	if($parent->{'sub_data'}->{'sub_name'} ne $child->{'sub_data'}->{'sub_name'}) {
		$class->_throw_compare_error("INTERNAL ERROR: compare different subroutine-names", $parent, $child);
	}
	
	if($parent->{'static'} ne $child->{'static'}) {
		$class->_throw_compare_error("Child and parent have to be the same access type (" . ($parent->{'static'} ? 'static' : 'non static') . ")", $parent, $child);
	}
	if($definition_data->{'access_level'}->{$child->{'access_level'}} != $definition_data->{'access_level'}->{$parent->{'access_level'}}) {
		$class->_throw_compare_error("The child-access-level ($child->{'access_level'}) can't be another as the parent-access-level ($parent->{'access_level'})", $parent, $child);
	}
	
	my $io_errors = $class->_compare_list($parent, $child, 'para', 'parameter', 0);
	push(@$io_errors, @{$class->_compare_list($parent, $child, 'opt_para', 'optional parameter', 1)});
	push(@$io_errors, @{$class->_compare_list($parent, $child, 'result', '$return value', 0)});
	push(@$io_errors, @{$class->_compare_list($parent, $child, 'array_result', '@return value', 1)});
	if(scalar(@$io_errors)) {
		$class->_throw_compare_error(join("\n", @$io_errors), $parent, $child);
	}
	return;
}
# STATIC srting[]
sub _compare_list {
	my $class = $_[0];
	my $parent = $_[1];
	my $child = $_[2];
	my $io_key = $_[3];
	my $io_type = $_[4];
	my $child_can_extend = $_[5];
	
	my $errors = [];
	my $i = 0;
	while(1) {
		my $parent_io = $parent->{$io_key}->[$i];
		my $child_io = $child->{$io_key}->[$i];
		last if(!$parent_io && !$child_io);
		
		my $error_prefix = ">   - $io_type " . ($i + 1) . ': ';
		if(!$parent_io && $child_io) {
			if(!$child_can_extend) {
				push(@$errors, "$error_prefix no further $io_type is/are allowed in child " .
					"(- <> $child_io->{'type'}$child_io->{'ref'}).");
			}
		} elsif($parent_io && !$child_io) {
			push(@$errors, "$error_prefix child has less ${io_type}s than parent " .
				"($parent_io->{'type'}$parent_io->{'ref'} <> -).");
		} elsif($parent_io->{'ref'} ne $child_io->{'ref'} || $parent_io->{'type'} ne $child_io->{'type'}) {
			
			if($parent_io->{'check'}->{'is_class'} && $parent_io->{'ref'} eq $child_io->{'ref'}) {
				if(!UNIVERSAL::isa($child_io->{'type'}, $parent_io->{'type'})) {
					push(@$errors, "$error_prefix childs ${io_type}-class doesnt inherit from parents ${io_type}-class " .
						"($parent_io->{'type'}$parent_io->{'ref'} <> $child_io->{'type'}$child_io->{'ref'}).");
				}
			} else {
				push(@$errors, "$error_prefix child has different ${io_type}-definition than parent " .
					"($parent_io->{'type'}$parent_io->{'ref'} <> $child_io->{'type'}$child_io->{'ref'}).");
			}
		}
		++$i;
	}
	unshift(@$errors, "Error(s) in $io_type:") if(scalar(@$errors));
	return $errors;
}
# STATIC void
sub _throw_compare_error {
	my $class = $_[0];
	my $msg = $_[1];
	my $parent = $_[2];
	my $child = $_[3];
	
	my $parent_d = $parent->{'sub_data'};
	my $child_d = $child->{'sub_data'};
	my $parent_subdef = "$parent_d->{'class'}->$parent_d->{'sub_name'} : $parent_d->{'attribute'}($parent_d->{'data'})";
	my $child_subdef = "$child_d->{'class'}->$child_d->{'sub_name'} : $child_d->{'attribute'}($child_d->{'data'})";
	
	my $error = "Error in $parent->{'sub_data'}->{'attribute'} definition:\n> $msg\n> parent: $parent_subdef\n> child: $child_subdef\n"; 
	if(!$AVOID_DOUBLE_INHERIT_ERRORS->{$error}) {
		$AVOID_DOUBLE_INHERIT_ERRORS->{$error} = 1;
		_croak($error);
	}
	return;
}
# STATIC void
sub _throw_inherit_error {
	my $class = $_[0];
	my $msg = $_[1];
	my $classname = $_[2];
	my $subname = $_[3];
	my $inheritation_type = $_[4];
	
	my $type = ($inheritation_type ? " with '$inheritation_type'" : '');
	my $error = "Error in subroutine definition$type:\n> $msg\n> class: '$classname', subroutine '$subname'\n"; 
	if(!$AVOID_DOUBLE_INHERIT_ERRORS->{$error}) {
		$AVOID_DOUBLE_INHERIT_ERRORS->{$error} = 1;
		_croak($error);
	}
	return;
}
1;