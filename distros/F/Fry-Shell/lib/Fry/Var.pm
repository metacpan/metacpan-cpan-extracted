package Fry::Var;
use strict;
use base 'Fry::List';
use base 'Fry::Base';
my $list = {};

#sub _hash_default { return {qw/scope global/} }
sub list { return $list }
sub defaultSet { shift->setMany('value',$_[0],$_[1]) } 

#subs
sub defaultNew {
	my ($cls,%arg) = @_;
	$cls->manyNewScalar('value',%arg);
	#old way
	#$cls->convertScalarToHash(\%arg,'value');
	#$cls->manyNew(%arg);
}
sub Var {
	my ($cls,$id) = @_;

	#using __PACKAGE__ since $cls->var hard to test
	if (__PACKAGE__->attrExists($id,'refname')) {
		my $name = __PACKAGE__->get($id,'refname');
		$name =~ s/^/main::/ if ($name !~ /::/);
		no strict 'refs';
		return $$name;
	}
	return  __PACKAGE__->get($id, 'value')
}
sub setVar {
	my ($cls,%arg) = @_;
	while (my ($id,$value) = each %arg) {
		#? put an if here to save time
		$arg{$id} = __PACKAGE__->verify_value($id,$value);

		if (my $refname = __PACKAGE__->get($id,'refname')) {
			no strict 'refs';
			$$refname = $arg{$id}
			#delete $arg{$id};
		}
	}
	__PACKAGE__->setMany('value',%arg)
}
sub verify_value {
	my ($cls,$id,$value) = @_;
	if (__PACKAGE__->attrExists($id,'enum') && __PACKAGE__->attrExists($id,'default')) {
		if (grep (/^$value$/,@{$cls->get($id,'enum')} ) > 0) {
			return $value
		}
		else { return $cls->get($id,'default') }
	}
	#w: not having necessary attr
	return $value
}
1;

__END__	

sub setOrMakeVar2 ($%) {
	my ($cls,%arg) = @_;
	while (my ($id,$value) = each %arg) {
		if (! $cls->objExists($id)) {
			$cls->defaultNew($id=>$value);
		}
		else { $cls->setMany('value',$id=>$value) }
	}
}

=head1 NAME

Fry::Var - Class for shell variables.

=head1 DESCRIPTION 

This module's objects store configuration data for the shell and its libraries. Since a shell's
configuration includes the current classes used for each shell component, Fry::Var is used often along
with Fry::Base to communicate between shell component classes. A Fry::Var object is the simplest of
shell component classes containg only id and value attributes. All values are scalar (ie
hashref or arrayref) since all var objects are stored in a hash.

You can also sync a variable to any public variable by setting the attribute refname to the
variable's full name. Note that the sync is only maintained by using &setVar and &Var ie (always set
the variable with &setVar and get its value with &Var).  Thus if you change the public variable
without using &setVar then it will have a different value than its corresponding variable object.

A variable object has the following attributes:

	Attributes with a '*' next to them are always defined.

	*id($): Unique id.
	*value($): Holds value. Can also be a reference to any data type. Isn't updated if an object
		uses refname.
	refname($): Full variable name of a public variable, usualy declared using our.
		ie 'Fry::Lib::Sample::FullVariable' 

=head1 PUBLIC METHODS

	Var($var): gets variable value
	setVar(%var_to_value): sets variable value
	verify_value($var,$value): Verifies a variable's value if it has the enum attribute. If an
		invalid value is given then it sets it to the value contained in the default
		attribute

=head1 AUTHOR

Me. Gabriel that is.  I welcome feedback and bug reports to cldwalker AT chwhat DOT com .  If you
like using perl,linux,vim and databases to make your life easier (not lazier ;) check out my website
at www.chwhat.com.


=head1 COPYRIGHT & LICENSE

Copyright (c) 2004, Gabriel Horner. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
