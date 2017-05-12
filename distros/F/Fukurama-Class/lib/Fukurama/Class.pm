package Fukurama::Class;
use 5.008;
use Fukurama::Class::Rigid;
use Fukurama::Class::Carp;
use Fukurama::Class::Version();
our $VERSION;
BEGIN {
	$VERSION = 0.032;
	Fukurama::Class::Version->import($VERSION);
}
use Fukurama::Class::Extends();
use Fukurama::Class::Implements();
use Fukurama::Class::Abstract();
use Fukurama::Class::Attributes();
use Fukurama::Class::Version();
use Fukurama::Class::DataTypes();
use Data::Dumper();

my $ALLOWED = {
	extends		=> ['', 'class'],
	implements	=> ['[]', 'class'],
	abstract	=> ['', 'boolean'],
	version		=> ['', 'decimal'],
};
my $CHECK_OPTIONS = {
	''				=> 0,
	checks			=> 0,
	runtime_checks	=> 1,
};
my $DISABLE_ALL				= 0;
my $ONLY_CHECK_COMPILETIME	= 1;

# AUTOMAGIC void
sub import {
	my $class = shift(@_);
	my @options = @_;
	
	my ($caller) = caller(0);
	local $Carp::CarpLevel = $Carp::CarpLevel + 1;
	$class->declare($caller, 1, @options);
	return undef;
}
# AUTOMAGIC void
sub unimport {
	my $class = $_[0];
	my $check_level = $_[1];
	$check_level = '' if(!defined($check_level));
	
	my $level = $CHECK_OPTIONS->{$check_level};
	_croak("Error in configuration: option 'no $class($check_level)' is not allowed.") if(!defined($level));
	
	if($level > $ONLY_CHECK_COMPILETIME) {
		$Fukurama::Class::Extends::CHECK_LEVEL = $Fukurama::Class::Extends::LEVEL_CHECK_CHILDS;
		$Fukurama::Class::Implements::CHECK_LEVEL = $Fukurama::Class::Implements::LEVEL_CHECK_ALL;
		$Fukurama::Class::Attributes::CHECK_LEVEL = $Fukurama::Class::Attributes::LEVEL_CHECK_ALL;
		$Fukurama::Class::Attributes::OOStandard::CHECK_LEVEL = $Fukurama::Class::Attributes::OOStandard::LEVEL_CHECK_ALL;
	}
	
	if($level <= $ONLY_CHECK_COMPILETIME) {
		$Fukurama::Class::Abstract::DISABLE = 1;
		$Fukurama::Class::Attributes::OOStandard::DISABLE_RUNTIME_CHECK = 1;
	}
	
	if($level <= $DISABLE_ALL) {
		$Fukurama::Class::Extends::CHECK_LEVEL = $Fukurama::Class::Extends::LEVEL_DISABLE;
		$Fukurama::Class::Implements::CHECK_LEVEL = $Fukurama::Class::Implements::LEVEL_CHECK_NONE;
		$Fukurama::Class::Attributes::CHECK_LEVEL = $Fukurama::Class::Attributes::LEVEL_CHECK_NONE;
		$Fukurama::Class::Attributes::OOStandard::CHECK_LEVEL = $Fukurama::Class::Attributes::OOStandard::LEVEL_CHECK_NONE;
		$Fukurama::Class::HideCaller::DISABLE = 1;
		$Fukurama::Class::Rigid::DISABLE = 1;
	}
	return;
}
# STATIC void
sub declare {
	my $class = shift(@_);
	my $declare_class = shift(@_);
	my $import_depth = shift(@_);
	my @options = @_;
	
	_croak('Error in class definition syntax. Uneven count of parameters given.') if(@options % 2);
	Fukurama::Class::Attributes->register_class($declare_class);
	Fukurama::Class::Rigid->rigid($import_depth + 1);
	
	my $options = { @options };
	if(scalar(@options) != (scalar(keys(%$options)) * 2) ) {
		_croak('Error in class definition syntax. Some options are defined twice.');
	}
	
	foreach my $option (keys(%$options)) {
		my $def = $ALLOWED->{$option};
		_croak("Error in class definition syntax. Option '$option' is not allowed.") if(!$def);
		my $value = $options->{$option};
		$class->_check_option($declare_class, $option, $value, $def);
		$class->_handle_option($declare_class, $option, $value);
	}
	return;
}
# STATIC void
sub _check_option {
	my $class = $_[0];
	my $declare_class = $_[1];
	my $option = $_[2];
	my $value = $_[3];
	my $def = $_[4];
	
	my $ref = $def->[0];
	$ref = '' if($option eq 'implements' && ref($value) ne 'ARRAY');
	
	my $check = Fukurama::Class::DataTypes->get_check_definition($def->[1], $ref);
	my ($ok, $evaluated_value, $value_failure) = &{$check->{'check'}}($check->{'param_0'}, $value);
	
	$ok = 1 if($option eq 'extends' && $value eq '');
	
	my $error = ($value_failure ? " ($value_failure)" : '');
	if($check->{'is_class'}) {
		$error .= " Maybe the class doesn't exist or isn't loaded.";
	}
	$evaluated_value = join(', ', @$evaluated_value) if(ref($evaluated_value) eq 'ARRAY');
	if(ref($evaluated_value) eq 'HASH') {
		$evaluated_value = Data::Dumper::Dumper($evaluated_value);
		$evaluated_value =~ s/^\$VAR1 = //;
		$evaluated_value =~ s/;\n$//;
	}
	if(!$ok) {
		$evaluated_value = '' if(!defined($evaluated_value));
		_croak("Error in class definition syntax. Value '$evaluated_value' for option '$option' is not allowed. $error");
	}
	return;
}
# STATIC void
sub _handle_option {
	my $class = $_[0];
	my $declare_class = $_[1];
	my $option = $_[2];
	my $value= $_[3];
	
	if($option eq 'extends') {
		Fukurama::Class::Extends->extends($declare_class, $value);

	} elsif($option eq 'version') {
		Fukurama::Class::Version->version($declare_class, $value);

	} elsif($option eq 'implements') {
		foreach my $interface ((ref($value) eq 'ARRAY' ? @$value : $value)) {
			Fukurama::Class::Implements->implements($declare_class, $interface);
		}

	} elsif($option eq 'abstract') {
		Fukurama::Class::Abstract->abstract($declare_class) if($value);
	}
	return;
}
# STATIC void
sub run_check {
	Fukurama::Class::Extends->run_check();
	Fukurama::Class::Implements->run_check();
	Fukurama::Class::Abstract->run_check();
	Fukurama::Class::Attributes->run_check();
}

=head1 NAME

Fukurama::Class - Pragma to extend the Perl-OO (in native Perl)

=head1 VERSION

Version 0.032 (beta)

=head1 SYNOPSIS

 package MyClass;
 use Fukurama::Class(
 	extends		=> 'MyParent::Class',
 	implements	=> ['MyFirst::Interface', 'MySecond::Interface'],
 	abstract	=> 1,
 	version		=> 1.7,
 );
 sub new : Constructor(public|string) {
 	my $class = $_[0];
 	my $name = $_[1];
 	
 	bless({ name => $name }, $class);
 }
 sub get_name : Method(public final|string|) {
 	my $self = $_[0];
 	
 	return $self->{'name'};
 }
 1;


=head1 EXPORT

=head2 METHODS

I<MODIFY_CODE_ATTRIBUTES>, I<UNIVERSAL::caller>, I<UNIVERSAL::isa>

Existing ones will be decorated, not overwritten

=head2 CODE ATTRIBUTES

I<Constructor>, I<Method>

=head1 CHANGES OF PERL MODULES

=head2 UNIVERSAL::isa

This method would be decorated to handle the implemented interfaces.

=head2 CORE::GLOBAL::caller

This method would be decorated to hide the check-wrappers for I<Method> and I<Constructor> attributes.

=head1 PROVIDED FUNCTIONS

=over 4

=item use of strict and warnings by default

I<use strict> and I<use warnings> are activated by default in your class.

=item package-name check

Your packagename has to be as provided by path and filename to avoid typos.

=item Abstract classes

Any access to these classes from non-childs would croak at B<runtime>

=item Multi-inheritation check

Multiple defined methods in multi-inheritations would croak at B<compiletime>

=item Implementation of interfaces

Not implemented subs would croak at B<compiletime>

=item Constructor and method signatures

Non-static subs croak at B<runtime> if you call them as static sub

Private subs croak at B<runtime> if you call them from other classes

Protected subs croak at B<runtime> if you call them from outside the inheritation

Final subs croak at B<compiletime> if any child try to overwrite them

Abstract methods croak at B<compiletime> if you doesn't define them in the child class

Abstract methods croak at B<runtime> if you call them

=item Parameter and return-value check of methods and constructors

Any parameter which isn't equivalent to the signature would croak at B<runtime>

Any return value which isn't equivalent to the signature would croak at B<runtime>

=back

=head1 DESCRIPTION

Use this pragma to have more reliability for developing your programs. It will slow down your code a bit but you
can disable the whole pragma for production with only one line without any side effect.

=head2 PRAGMA-OPTIONS

=over 4

=item B<extends> => STRING

Define, from wich class you would inherit. This is only a wrapper for the B<base> pragma. Feel free to use this
one or B<base> direct. It's only for the sake of completeness.

=item B<implements> => ARRAYREF of STRING

A list of interfaces you have to implement. You will not inherit from theese classes even thought UNIVERSAL::isa
will say that.

=item B<abstract> => BOOLEAN

Declare this class as an abstract one.

=item B<version> => INT

Set the $VERSION variable in your module. Same as you say B<our $VERSION = INT> (at B<compiletime>)

=back

=head2 DEFINE SIGNATURES

You can define signatures for constructors and methods. If you overwride some subs from your parent-class, you have
to use exact the same signature ore an extended version (see L<EXTEND SIGNATURES>). Otherwise it will croak
at B<compiletime>.

=over 4

=item Constructor signatures

 sub new : Constructor(ACCESS_LEVEL TYPE | PARAMETERS) {

Any constructor is static. But if you call $object->new( ) it will cause no check-error.

The return-value of any constructor has to be a blessed reference which is a member of the actual class.

=item Method signatures

 sub get : Method(ACCESS_LEVEL IS_STATIC TYPE | RETURN_VALUE | PARAMETERS) {

=back

=head3 DECLARATION OPTIONS

=over 4

=item B<ACCESS_LEVEL>: ENUM

Can be on of the following. If you overwrite methods, you can't change the access-level in the
inheritation tree, because public methods start with no underscore and all other with an underscore.
With this caveat and the fact, that there are no real private methods in perl it's more uncomplicated
to do so.

=over 4

=item I<public>

You can access these sub from anywhere. There are no restrictions.

=item I<protected>

You can access these sub only from its own package or members of this class (even parents). All calls from
outside will croak at B<runtime>.

=item I<private>

You can access these sub only from its own package. All other calls will croak at B<runtime>. 

=back

There are two things to comply the perl-styleguide:

=over 4

=item sub _methodname

Any sub with an I<initial underscore> can be protected or private. If you doesn't define the ACCESS_LEVEL,
it will be protected by default. If you define this as public it will croak at B<compiletime>.

=item sub methodname

Any sub with no initial unterscore can be only public. If you doesn't define the ACCESS_LEVEL, it will be
public by default. If you define it as protected or private it will croak at B<compiletime>

=back

so you can say:

 sub _methodname : Method(|void|)

and you will get the same as

 sub _methodname : Method(protected|void|)

=item B<IS_STATIC>: ENUM

Can be...

=over 4

=item I<static>

If the sub is static, you can call it direct via CLASSNAME->sub( ) or via object $obj->sub(). A direct call
via I<&sub()> will croak at B<runtime>.

=back

If static is not defined, you can only call these sub via $object->sub(). All other accesses will croak
at B<runtime>

=item B<TYPE>: ENUM

Can be one of...

=over 4

=item B<abstract>

This sub is abstract. You doesn't have to define any method-body, because this method could be never called.
All children of this class have to implement this method with the same or the extended method-signature.

=item B<final>

This sub is finalized. No child can overwrite an redifine this method. This will croak at B<compiletime>

=back

=item B<RETURN_VALUE>

The definition of the return value. In this standard definition there is no determination between array and
scalar context. If you define void as return value and call it in scalar or array context, there would be
no warning.

If there is a difference between array and scalar context, you have to define the array-context return values
separate after an @ like

 sub append : Method(public|SCALAR_RETURN @ ARRAY_RETURN|);

B<Examples:>

=over 4

=item sub append : Method( public|string| )

returns a string
 
=item sub append : Method( public|string, boolean| )

returns a string and a boolean
 
=item sub append : Method( public|string[] @ string()| )

returns an arrayref of strings in scalar, and an array of strings in array context

=back

=item B<PARAMETERS>

The definition, which parameters your sub can take seperated by comma. If there is no parameter you have
to define nothing.

Optional parameters can be defined after a semicolon.

B<Examples:>

=over 4

=item sub append : Method( public|void| )

Takes no parameters

=item sub append : Method( public|void|string )

Takes a single string as parameter

=item sub append : Method( public | void | string[]; scalar, scalar )

Takes an arrayref of strings and two optional scalars as parameters

=back

=back

=head3 POSSIBLE PARAMETERS AND RETURN VALUES

The following things you can use for parameters or return values:

=over 4

=item void (only for return values)

The sub returns nothing (undef). Only valid for a single return value.

It isn't valid if you try to define a void return value for array-context or any other return value with void.
This will croak at B<compiletime>

=item scalar

Anything what you can put into a scalar variable, i.e. references, strings, objects, undef, etc.

=item scalarref

A reference to a scalar.

=item arrayref

A reference to an array.

=item hashref

A reference to a hash.

=item typeglobref

A reference to a typeglob

=item string

A scalar with string content. It behaves like scalar but it can't be undef.

=item boolean

A scalar which can contain 1 or 0.

=item int

A scalar which can contain an integer. It can't be undef. If this number is too big and produced
an overflow, for exampe a string with a huge number, it will croak at B<runtime>.

=item float

A scalar which can contain any floatingpoint number. It can't be undef. If the number is too big
and produced an overflow it will croak at B<runtime> like in int.

=item decimal

A scalar which can contain any decimal number. It can't be undef. If the number is too big and
produced an overflow it will croak at B<runtime> like in int.

B<But be aware!>

If you use too many digits after the point like 1.000000000000001, perl will cut this down to "1"
without any notice if you use it as number direct in your code or if you calculate with it. If you
give such a number to a method as string, Fukurama::Class would find fault with "overflow".

=item class

A string which contain a valid classname, i.e 'UNIVERSAL'. Can't be undef.

=item object

A scalar which can contain any object. 

=item AnyClassname

If there is no specific declaration for the datatype this would be interpreted as class. The parameter or return
value must be an OBJECT and a member of the defined class.

=back

At each of these things you can add trailing [] or () to say, that this is an arrayref or an array
or these thing. The () can be used for array-context return values and then it has
to be the last or the only return value. It also can be the last parameter/optional parameter.

B<Attention>: you can never add some parameters or return values when you use it!

Example:

=over 4

=item int[]

An arrayref that contain only integers

=item MyClass( )

An array that contain only members of the MyClass-class.

=back

=head2 EXTEND SIGNATURES

You can extend signatures by the following ways:

=over 4

=item set final

Any Non-final sub can be declared as final to avoid overwriting.

=item add new, optional parameter

You can add (more) optional parameters. The even defined parameters from the sub you overwrite must
be exact the same. To overwrite and extend a method for the example parent:

 package Parent;
 sub get_name : Method(public|string|boolean) {

...you can say:

 package Child;
 sub get_name : Method(public|string|boolean;string) {

...but not:

 package Child;
 sub get_name : Method(public|string|string) {

this will croak at B<compiletime>

=back

=head1 LOAD CLASSES AT RUNTIME

If some classes are loaded at runtime there couldn't be checked at compiletime. So these classes are
checked at destroy-time (END-block) and you will become a warning about this at runtime when the class is loaded.

=head1 DISABLE ALL CHECKS

To speed up your code to use it productive you can say:

=over 4

=item no Fukurama::Class('runtime_checks');

This will disable all runtime checks as to callers, parameters and return values. This will speed up
your code most.

=item no Fukurama::Class('checks');

This will disable all checks for runtime as above and for compiletime as to checks of implementations
of abstract methods and interfaces, use same or extended signatures for overwritten subs and the package-name checks.

If you say this, only decorations for the methods B<UNIVERSAL::isa( )> and B<MODIFY_CODE_ATTRIBUTE( )>
(which will be in several classes) would stay. Even B<warning> are disabled, because of the runtime-warning checks.

But the B<strict> would never be disabled.

=back

=head1 CUSTOM SETTINGS

You can control the whole behavior of all submodules. Take a look at the specific module documentation. 

=head1 METHODS

=over 4

=item declare( export_to_class:STRING, export_depth:INT ) return:VOID

Helper method to white wrapper or adapter for this class. You can define to which class all functionality would be exported.
For the automatic pollution of strict() an warnings() you have to define the caller level, in which this behavior would
be exported.

B<ATTENTION!> For automatic export of strict() and warnings() behavior you have to call this method in an B<import()> method
at compiletime.

=item run_check( ) return:VOID

Helper method for static perl (see BUGS). This method check all declarations and implement parameter and return value checker.

=item unimport( ) return:VOID

Perl-intern method to provide the 'no Fukurama::Class' functionality. See section L<DISABLE ALL CHECKS> above.

=back

=head1 AUTHOR

Tobias Tacke, C<< <cpan at tobias-tacke.de> >>

=head1 BUGS

This pragma you can only use for non-static perl. Most of the features use the perl-buildin CHECK-block,
but mod_perl or fastCGI doesn't support this block.

In mod_perl you can "fake" this, if you say:

 Fukurama::Class->run_check();

in the main-handler method and all is well. All compile-time checks would croak in this line, if there
are errors. Not fine but it works.

I still have to discover hov the attributes like "Private" in Catalyst work. There must be a hack :)

Please report any bugs or feature requests to
C<bug-fukurama-class at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Fukurama-Class>.
I will be notified, and then you'll automatically be notified of any progress on
your bug as I make changes.

=head1 SUPPORT

You can find the documentation of this module with the perldoc command.

    perldoc Fukurama::Class

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Fukurama-Class>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Fukurama-Class>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Fukurama-Class>

=item * Search CPAN

L<http://search.cpan.org/dist/Fukurama-Class>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Tobias Tacke, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;