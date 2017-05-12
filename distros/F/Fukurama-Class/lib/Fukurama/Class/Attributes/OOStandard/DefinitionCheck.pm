package Fukurama::Class::Attributes::OOStandard::DefinitionCheck;
use Fukurama::Class::Version(0.03);
use Fukurama::Class::Rigid;
use Fukurama::Class::Carp;
use Fukurama::Class::DataTypes();
use Fukurama::Class::Attributes::OOStandard::Decorator();
use Data::Dumper();
use Fukurama::Class::Tree();
use Fukurama::Class::Attributes::OOStandard::InheritationCheck();

my $DATATYPES = 'Fukurama::Class::DataTypes';
my $DECORATOR = 'Fukurama::Class::Attributes::OOStandard::Decorator';
my $WHITESPACES = qr/(?:[ \t\n\r]*,[ \t\n\r]*|[ \t\n\r]+)/;
my $SPLIT_TYPE = qr/^(.*?)((?:\[\]|\(\))*)$/;
my $SPLIT_PART = qr/\|/;
my $SPLIT_SUBPART = qr/[\@;]/;
my $DEF_ERROR = undef;
my $ATT_TYPE = undef;
my $REGISTER = {};

my $ACCESS_LEVEL = {
	public		=> 1,
	protected	=> 2,
	private		=> 3,
};
my $ACCESS_LEVEL_TYPE = {# ENUM('', 'unoverwritable')
	public		=> '',
	protected	=> '',
	private		=> '',
};
my $STATIC = {
	static		=> 1,
	''			=> 1,
};
my $TYPE = {
	abstract	=> 'overwrite',
	''			=> 'normal',
	final		=> 'unoverwritable',
};

=head1 NAME

Fukurama::Class::Attributes::OOStandard::DefinitionCheck - Helper-class to check syntax of code attributes

=head1 VERSION

Version 0.03 (beta)

=head1 SYNOPSIS

- (its only a collection of methods, it's unusable outside of it's own context :)

=head1 DESCRIPTION

A Helper class for Fukurama::Class::Attributes::OOStandard to check code attribute syntax.

=head1 EXPORT

-

=head1 METHODS

=over 4

=item get_translated_def( sub_data:\HASH, def:\HASH, sub_def:\ARRAY, result_def:\ARRAY,
 array_result_def:\ARRAY, para_def:\ARRAY, opt_para_def:\ARRAY) return:\HASH
	
Translate the given attribute data (e.g. static|void|string) into an wellformed hash which contain
all definitions include implizit definitions.

=item set_type( type:STRING ) return:VOID

Set the type-name of the actual checked code attribute. It's only for error messages. 

=item throw_def_error( sub_data:\HASH, msg:STRING) return:VOID

Died with the given message and output some detailed informations about the involved method(s).

=item resolve_def( sub_data:\HASH ) return:VOID

Resolved the method name from a given subroutine code reference.

=item try_check_translated_def( sub_data:\HASH, translated_def:\HASH, def:\HASH ) return:VOID

Check all defintions of the given code attribute declaration.

=item decorate_sub( def:\HASH ) return:VOID

Decorates subroutines with a check method to check parameter and return values.

=item try_check_parameter( id:STRING, io_list:\ARRAY ) return:VOID

Check the content of the parameter list for a subroutine.

=item try_check_result( id:SRING, io_list:\ARRAY, list_context:BOOLEAN ) return:VOID

Check the content of the return value(s) for a subroutine.

=item try_check_abstract( id:STRING ) return:VOID

Check the caller of a subroutine, to avoid directly called, abstract methods.

=item try_check_access( id:STRING ) return:VOID

Check the caller of a subroutine, to avoid unauthorized calls for e.g. private methods from outside the own class.

=item try_check_call( id:STRING, class_parameter:SCALAR ) return:VOID

Check the first argument of the method for static or nonstatic calls and the correct usage.

=item check_inheritation( method_name:STRING, parent_class:CLASS, child_class:CLASS, inheritation_type:STRING ) return:VOID

Check the inheritations of all defined declarations to avoid differend method signatures for parent and child.

=back

=head1 AUTHOR, BUGS, SUPPORT, ACKNOWLEDGEMENTS, COPYRIGHT & LICENSE

see perldoc of L<Fukurama::Class>

=cut


# STATIC boolean
sub get_translated_def {
	my $class = $_[0];
	my $sub_data = $_[1];
	my $def = $_[2];
	my $sub_def = $_[3];
	my $result_def = $_[4];
	my $array_result_def = $_[5];
	my $para_def = $_[6];
	my $opt_para_def = $_[7];
	
	my $access_level = $class->_extract_access_level_def($sub_def, $sub_data->{'sub_name'});
	$class->_try_check_access_level_def($sub_data, $access_level);
	
	my $static = $class->_extract_static_def($sub_def);
	$class->_try_check_static_def($sub_data, $static);
	
	my $type = $class->_extract_type_def($sub_def);
	$class->_try_check_type_def($sub_data, $type);

	my $result = $class->_extract_io_def($result_def);
	$class->_try_check_io_def($sub_data, $result, '$return value', []);
	if(scalar(@$result) != 1) {
		$class->throw_def_error($sub_data, "\$return value definition must contain exact 1 element but is " . scalar(@$result) . " elements long.");
	} 
	if($result->[0]->{'ref'} eq '()') {
		$class->throw_def_error($sub_data, "\$return value '$result->[0]->{'type'}$result->[0]->{'ref'}' is not allowed. You can't use () in scalar context.");
	}
	
	my $array_result = $class->_extract_io_def($array_result_def);
	if(@$array_result) {
		$class->_try_check_io_def($sub_data, $array_result, '@return value', [qw/void/]);
		$class->_try_check_list_result($sub_data, [@$array_result]);
	}
	
	my $para = $class->_extract_io_def($para_def);
	$class->_try_check_io_def($sub_data, $para, 'parameter', [qw/void/]);
	
	my $opt_para = $class->_extract_io_def($opt_para_def);
	$class->_try_check_io_def($sub_data, $opt_para, 'optional parameter', [qw/void/]);
	
	$class->_try_check_list_parameter($sub_data, [@$para, @$opt_para], scalar(@$para));

	return {
		access_level	=> $access_level,
		static			=> $static,
		type			=> $type,
		result			=> $result,
		array_result	=> $array_result,
		para			=> $para,
		opt_para		=> $opt_para,
		sub_data		=> $sub_data,
	};
}
# STATIC void
sub _try_check_list_result {
	my $class = $_[0];
	my $sub_data = $_[1];
	my $list = $_[2];
	
	my $last_element = pop(@$list);
	my $i = 0;
	foreach my $entry (@$list) {
		if($entry->{'ref'} eq '()') {
			$class->throw_def_error($sub_data, "\@result $i '$entry->{'type'}$entry->{'ref'}' is not allowed. You can use () only as last element.");
		}
		++$i;
	}
	return;
}
# STATIC void
sub _try_check_list_parameter {
	my $class = $_[0];
	my $sub_data = $_[1];
	my $list = $_[2];
	my $needed_length = $_[3];
	
	my $last_element = pop(@$list);
	my $i = 0;
	foreach my $entry (@$list) {
		if($entry->{'ref'} eq '()') {
			my $name = ($i > $needed_length ? 'optional parameter' : 'parameter');
			$class->throw_def_error($sub_data, "$name $i '$entry->{'type'}$entry->{'ref'}' is not allowed. You can use () only as last element.");
		}
		++$i;
	}
	return;
}
# STATIC void
sub set_type {
	my $class = $_[0];
	my $type = $_[1];
	
	$ATT_TYPE = $type;
	return:
}
# STATIC void
sub throw_def_error {
	my $class = $_[0];
	my $sub_data = $_[1];
	my $msg = $_[2];
	
	my $type = (defined($ATT_TYPE) ? " $ATT_TYPE": '');
	if($DEF_ERROR) {
		$DEF_ERROR = "Last error thrown twice";
	} else {
		$DEF_ERROR = "Error in$type declaration:\n    $sub_data->{'class'}\->$sub_data->{'sub_name'}($sub_data->{'data'})\n> $msg\n\n";
	}
	_croak($DEF_ERROR);
	return;
}
# STATIC array[]
sub resolve_def {
	my $class = $_[0];
	my $sub_data = $_[1];
	
	my @data = ();
	foreach my $part (split($SPLIT_PART, $sub_data->{'data'})) {
		my @subdata = ();
		foreach my $subpart (split($SPLIT_SUBPART, $part . ' ')) {
			my @entry = ();
			foreach my $entry (split($WHITESPACES, $subpart)) {
				my ($type, $ref) = $entry =~ $SPLIT_TYPE;
				push(@entry, {
					data	=> $type,
					type	=> $ref,
				});
			}
			if($subpart =~ m/,$/ || $subpart =~ m/^$WHITESPACES$/) {
				push(@entry, {
					data	=> '',
					type	=> '',
				});
			}
			push(@subdata, \@entry);
		}
		push(@data, \@subdata);
	}
	return \@data;
}
# STATIC string
sub _extract_access_level_def {
	my $class = $_[0];
	my $sub_def = $_[1];
	my $sub_name = $_[2];
	
	my $access_level = {};
	foreach my $entry (@$sub_def) {
		if($ACCESS_LEVEL->{$entry->{'data'}}) {
			return undef if($access_level->{$entry->{'data'}});
			$access_level->{$entry->{'data'}} = 1;
		}
	}
	
	if($sub_name =~ /^_/) {
		return undef if($access_level->{'public'});
		$access_level->{'protected'} = 1 if(!$access_level->{'protected'} && !$access_level->{'private'});
		
	} else {
		return undef if($access_level->{'protected'} || $access_level->{'private'});
		$access_level->{'public'} = 1;
	}
	
	
	my @access_level = keys(%$access_level);
	return undef if(scalar(@access_level) != 1);
	return $access_level[0];
}
# STATIC void
sub _try_check_access_level_def {
	my $class = $_[0];
	my $sub_data = $_[1];
	my $access_level = $_[2];

	$class->throw_def_error($sub_data, 'access level declaration is wrong. Maybe a conflict between sub name and declared access level.') if(!defined($access_level) || !$ACCESS_LEVEL->{$access_level});
	return;
}
# STATIC string
sub _extract_static_def {
	my $class = $_[0];
	my $sub_def = $_[1];
	
	my $static = {};
	foreach my $entry (@$sub_def) {
		if($STATIC->{$entry->{'data'}}) {
			return undef if($static->{$entry->{'data'}});
			$static->{$entry->{'data'}} = 1;
		}
	}
	my @static = keys(%$static);
	return undef if(scalar(@static) > 1);
	return $static[0] || '';
}
# STATIC void
sub _try_check_static_def {
	my $class = $_[0];
	my $sub_data = $_[1];
	my $static = $_[2];
	
	$class->throw_def_error($sub_data, 'static declaration is wrong') if(!defined($static) || !$STATIC->{$static});
	return;
}
# STATIC string[]
sub _extract_type_def {
	my $class = $_[0];
	my $sub_def = $_[1];
	
	my $type = {};
	foreach my $entry (@$sub_def) {
		if($TYPE->{$entry->{'data'}}) {
			return undef if($type->{$entry->{'data'}});
			$type->{$entry->{'data'}} = 1;
		}
	}
	
	my @type = keys(%$type);
	return undef if(scalar(@type) > 1);
	return $type[0] || '';
}
# STATIC void
sub _try_check_type_def {
	my $class = $_[0];
	my $sub_data = $_[1];
	my $type = $_[2];
	
	$class->throw_def_error($sub_data, 'type declaration is not allowed') if(!defined($type) || !$TYPE->{$type});
	return;
}
# STATIC string[]
sub _extract_io_def {
	my $class = $_[0];
	my $io_def = $_[1];
	
	my $io = [];
	foreach my $entry (@$io_def) {
		push(@$io, {
			type	=> $entry->{'data'},
			ref		=> $entry->{'type'},
			check	=> $DATATYPES->get_check_definition($entry->{'data'}, $entry->{'type'}),
		});
	}
	return $io;
}
# STATIC void
sub _try_check_io_def {
	my $class = $_[0];
	my $sub_data = $_[1];
	my $io = $_[2];
	my $name = $_[3];
	my $forbidden_types = $_[4];
	
	foreach my $entry (@$io) {
		if(!$DATATYPES->is_ref_allowed($entry->{'ref'})) {
			$class->throw_def_error($sub_data, "$name definition '$entry->{'type'}$entry->{'ref'}' is not allowed");
		}
		my $error = 0;
		foreach my $type (@$forbidden_types) {
			$error = 1 if($entry->{'type'} eq $type);
		}
		if($error || !$DATATYPES->check_parameter_definition($entry->{'type'}, $entry->{'check'})) {
			if($entry->{'check'}->{'is_class'}) {
				$class->throw_def_error(
					$sub_data,
					"$name '$entry->{'type'}$entry->{'ref'}' is wrong. This class is not loaded or doesn't exist."
				);
			} else {
				$class->throw_def_error(
					$sub_data,
					"$name '$entry->{'type'}$entry->{'ref'}' is not allowed."
				);
			}
		}
	}
}
# STATIC void
sub try_check_translated_def {
	my $class = $_[0];
	my $sub_data = $_[1];
	my $translated_def = $_[2];
	my $def = $_[3];
	
	my $def_keys = {};
	foreach my $entry (@{$def->[0]->[0]}) {
		$def_keys->{$entry->{'data'}} = 1;
	}
	
	foreach my $key (values(%$translated_def)) {
		delete($def_keys->{$key});
	}
	
	my @forbidden_keys = keys(%$def_keys);
	if(@forbidden_keys) {
		my $keys = join(', ', @forbidden_keys);
		$class->throw_def_error($sub_data, "forbidden key(s): '$keys' used in declaration");
	}
	return;
}
# STATIC void
sub decorate_sub {
	my $class = $_[0];
	my $def = $_[1];
	
	my $sub_data = $def->{'sub_data'};
	my $old = $sub_data->{'sub'};
	my $identifier = $sub_data->{'class'} . '::' . $sub_data->{'sub_name'};

	$DECORATOR->remove_decoration($identifier, $old) if($REGISTER->{$identifier});
	$DECORATOR->decorate($identifier, $old, __PACKAGE__);
	$REGISTER->{$identifier} = $def;
	return;
}
# STATIC void
sub try_check_parameter {
	my $class = $_[0];
	my $id = $_[1];
	my $io_list = $_[2];
	
	my $def = $REGISTER->{$id};
	_croak("Internal error:\n    sub $id() has no definition\n\n") if(!$def);
	
	my $io_def_list = [@{$def->{'para'}}, @{$def->{'opt_para'}}];
	my $length = scalar(@$io_def_list);
	my $needed_length = scalar(@{$def->{'para'}});
	my $given_length = scalar(@$io_list);
	
	$length = $given_length if($given_length >= $needed_length);
	$class->_try_check_io($io_def_list, $io_list, $length, $def, 'parameter');
	return;
}
# STATIC void
sub try_check_result {
	my $class = $_[0];
	my $id = $_[1];
	my $io_list = $_[2];
	my $list_context = $_[3];
	
	my $def = $REGISTER->{$id};
	_croak("Internal error:\n    sub $id() has no definition\n\n") if(!$def);
	
	my $io_type = undef;
	my $io_def_list = undef;
	if($list_context && scalar(@{$def->{'array_result'}})) {
		$io_def_list = [@{$def->{'array_result'}}];
		$io_type = 'listcontext result';
	} else {
		$io_def_list = [@{$def->{'result'}}];
		$io_type = 'result';
	}
	
	
	my $length = scalar(@$io_def_list);
	my $needed_length = $length;
	my $given_length = scalar(@$io_list);
	
	$length = $given_length if($given_length > $needed_length);
	$class->_try_check_io($io_def_list, $io_list, $length, $def, $io_type);
	return;
}
# STATIC void
sub _try_check_io {
	my $class = $_[0];
	my $io_def_list = $_[1];
	my $io_list = $_[2];
	my $length = $_[3];
	my $def = $_[4];
	my $io_type = $_[5];
	
	my $errors = [];
	for(my $i = 0; $i < $length; $i++) {
		my $pdef = $io_def_list->[$i];
		my $entry = $io_list->[$i];
		if(!ref($pdef)) {
			my $defined = '';
			if(!defined($entry)) {
				$defined = ' (undefined)';
				$entry = '';
			}
			push(@$errors, "Error in $io_type " . ($i + 1) .
				":\n	$def->{'sub_data'}->{'class'}->$def->{'sub_data'}->{'sub_name'}($def->{'sub_data'}->{'data'})\n" .
				"> no further $io_type expected, only " . scalar(@$io_def_list) . " is/are allowed.\n" .
				"> extra $io_type '$entry'$defined given\n\n");
			next;
		}
		my $old_entry = $entry;
		(my $is_ok, $entry, my $error_msg) = &{$pdef->{'check'}->{'check'}}($pdef->{'check'}->{'param_0'}, $entry, $pdef->{'type'}, \$i, $io_list);
		if(!$is_ok) {
			my $defined = '';
			if(!defined($old_entry) || !defined($entry)) {
				$defined = ' (undefined)' if(!defined($old_entry));
				$entry = '';
			} elsif(ref($entry) eq 'ARRAY') {
				local $Data::Dumper::Maxdepth = 1;
				$entry = Data::Dumper::Dumper($entry);
				$entry =~ s/^[^\[]*//;
				$entry =~ s/[^\]]*$//;
			}
			my $class = ($pdef->{'check'}->{'is_class'} ? ' class (or child of)' : '');
			$class = 'Any kind of a' if($pdef->{'type'} eq 'class');
			my $extended_msg = (defined($error_msg) ? " ($error_msg)" : '');
			push(@$errors, "Error in $io_type " . ($i + 1) .
				":\n	$def->{'sub_data'}->{'class'}->$def->{'sub_data'}->{'sub_name'}($def->{'sub_data'}->{'data'})\n" .
				"> $class '$pdef->{'type'}$pdef->{'ref'}' expected but '$entry'$defined given$extended_msg.\n\n");
			next;
		}
	}
	_croak(join('', @$errors)) if(@$errors);
	return;
}
# STATIC void
sub try_check_abstract {
	my $class = $_[0];
	my $id = $_[1];
	
	my $def = $REGISTER->{$id};
	_croak("Internal error:\n    sub $id() has no definition\n\n") if(!$def);
	
	if($def->{'type'} eq 'abstract') {
		$class->_throw_access_error(
			$def,
			'This ' . lcfirst($def->{'sub_data'}->{'attribute'}) . ' is declared as abstract but called directly.'
		);
	}
	return;
}
# STATIC void
sub try_check_access {
	my $class = $_[0];
	my $id = $_[1];
	
	my $def = $REGISTER->{$id};
	_croak("Internal error:\n    sub $id() has no definition\n\n") if(!$def);
	
	return if($def->{'access_level'} eq 'public');
	
	my ($caller_package, $filename, $line) = caller();
	my $msg = '';
	if($def->{'access_level'} eq 'protected') {
		return if(UNIVERSAL::isa($caller_package, $def->{'sub_data'}->{'class'}) || UNIVERSAL::isa($def->{'sub_data'}->{'class'}, $caller_package));
		$msg = 'protected but called from outside the inheritation';
	} elsif($def->{'access_level'} eq 'private') {
		return if($caller_package eq $def->{'sub_data'}->{'class'});
		$msg = 'private but called from another class';
	}
	$class->_throw_access_error(
		$def,
		'This ' . lcfirst($def->{'sub_data'}->{'attribute'}) . " is declared as $msg",
		"Called from class/package: '$caller_package'"
	);

	return;	
}
# STATIC void
sub check_inheritation {
	my $class = $_[0];
	my $method_name = $_[1];
	my $parent_class = $_[2];
	my $child_class = $_[3];
	my $inheritation_type = $_[4];
	
	my $definition_data = {
		register			=> $REGISTER,
		type				=> $TYPE,
		access_level_type	=> $ACCESS_LEVEL_TYPE,
		access_level		=> $ACCESS_LEVEL,
	};
	Fukurama::Class::Attributes::OOStandard::InheritationCheck->check_inheritation($method_name, $parent_class, $child_class, $inheritation_type, $definition_data);
	return;
}
#STATIC void
sub try_check_call {
	my $class = $_[0];
	my $id = $_[1];
	my $class_param = $_[2];
	
	my $def = $REGISTER->{$id};
	_croak("Internal error:\n    sub $id() has no definition\n\n") if(!$def);
	
	my $is_class = ref($class_param) || $class_param;
	my $should_class = $def->{'sub_data'}->{'class'};
	
	if(!defined($is_class) || !defined($should_class)) {
		$class->_throw_access_error($def, 'this subroutine was called directly, not over a class or an object');
	} elsif(UNIVERSAL::isa($is_class, $should_class) || UNIVERSAL::isa($should_class, $is_class)) {
		return if($def->{'static'} eq 'static');
		
		return if(ref($class_param));
		$class->_throw_access_error(
			$def,
			'this non-static method was called as static method',
			'only over a class, not an object',
			'used class: ' . $class_param
		);
	} else {
		$class->_throw_access_error(
			$def,
			'this method was called over the wrong class/object',
			'it seems that you call it direct an pass a wrong, first parameter into it',
			'1st parameter: ' . $class_param
		);
	}
	return;	
}
# STATIC void
sub _throw_access_error {
	my ($class, $def, @msg) = @_;
	
	_croak("Error in access " .
		":\n	$def->{'sub_data'}->{'class'}->$def->{'sub_data'}->{'sub_name'}($def->{'sub_data'}->{'data'})\n" .
		" > " . join("\n > ", @msg) . "\n\n");
}
1;
