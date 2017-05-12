package JSPL::Object;
use strict;
use warnings;

require JSPL::Boxed;

our @ISA = qw(JSPL::Boxed);

use overload '%{}' => \&HASH_REF, fallback => 1;

sub HASH_REF { $_[0]->__content->tie($_[0]->__context, 0); };

sub STORE {
    my ($self,$key,$val) = @_;
    $self->__content->set_prop($self->__context, $key, $val);
    $val;
}

sub FETCH {
    my ($self,$key) = @_;
    $self->__content->get_prop($self->__context, $key);
}

sub FIRSTKEY {
    my $self = shift;
    ${$self}->[4] = $self->__content->firstkey($self->__context);
    $self->NEXTKEY;
}

sub NEXTKEY {
    my $self = shift;
    my $next = ${$self}->[4]->nextkey($self->__context);
    ${$self}->[4] = undef unless defined $next;
    $next;
}

sub EXISTS {
    my $self = shift;
    defined $self->FETCH(@_);
}

sub DELETE {
    my ($self, $key) = @_;
    $self->__content->delete_prop($self->__context, $key);
}

sub CLASS_NAME {
    my $self = shift;
    $self->__content->get_class_name($self->__context);
}

sub __bind_to_stash {
    my $self = shift;
    my $package = shift;
    my $name = shift;
    my($sigil,$sym);
    if(($sigil,$sym) = $name =~ m/^([\%\@\&])(.+)/) {
	$name = $sym;
    } else {
	$sigil = '&';
    }
    my $code = 
	$sigil eq '%' ? \%{$self} :
	$sigil eq '@' ? \@{$self} : do {
	my $closure = sub {
	    local $JSPL::This = $JSPL::This;
	    if(@_ && !$JSPL::This) {
		if($_[0] eq $package) {
		    $JSPL::This = $self->__context->get_controller
			->added($package);
		    shift;
		} elsif(ref($_[0]) && ($_[0]->isa($package) ||
				       $_[0]->isa('JSPL::Boxed') ||
				       $_[0]->isa('JSPL::RawObj'))
		) {
		    $JSPL::This = shift;
		}
	    }
	    @_ = ($self->__context, $JSPL::This, $self, [@_]);
	    goto &JSPL::Context::jsc_call;
	};
	#eval "package $package; sub $name {\n#line 28 JSModule.js\n \&{\$closure} } \\\&$name" or die $@;
	$closure;
    };
    # warn "Want to bind $self to $sigil${package}::${name}\n";
    no strict 'refs';
    no warnings 'prototype';
    *{"${package}::${name}"} = $code;
    return 1;
}

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    my $method = (split('::',$AUTOLOAD))[-1];
    # warn "Search of $method\n";
    my $oargs = [@_];
    @_ = ($self->__context, $self->__content, $method, $oargs);
    goto &JSPL::Context::jsc_call;
}

package JSPL::XMLObject;
use overload '""' => sub { $_[0]->toXMLString };
@JSPL::XMLObject::ISA = qw(JSPL::Object);

1;

__END__

=head1 NAME

JSPL::Object - Reference to a JavaScript Object

=head1 DESCRIPTION

Besides primitives everything else in JavaScript is an object. This class (or
one of its subclasses) encapsulate a I<reference> to them.

    $adate = $ctx->eval(' new Date() ');
    print ref $adate;                       # 'JSPL::Object'
    print $adate->toString;		    # Today date

=head1 SIMPLE INTERFACE

Objects in JavaScript resemble perl HASHes. By default and for transparency to
unaware perl code, for the I<most simple> JavaScript objects, you won't see the
JSPL::Object instance wrapper. Instead the JSPL::Object instance will be
converted, via L<perlfunc/tie>, into perl HASHes and returned as
HASH-references.  So to access or modify the object properties you use the
regular perl HASH operations and functions.

By "most simple" in the last paragraph we're referring to all those objects
which its constructor is C<Object>.

    ...
    $obj = $ctx->eval('v = { foo:4, bar:{}, baz:true }; v;');

    print $obj->{foo};      # 4
    print ref $obj->{bar};  # 'HASH'

    print keys %$obj;               # foo bar baz
    print exists $obj->{bar}{fob};  # FALSE

All those HASHes are I<alive>, thats it, they refer to the original JavaScript
object, so if you modify them on one side, you are modifying both sides.

    $obj->{bar}{fob} = 'hi';
    print $ctx->eval( 'say(v.bar.fob);' ); # 'hi'

    $ctx->eval( 'delete v.baz' );
    print keys %$obj;		     # foo bar

But as the HASH is a plain perl one, you can't use it to call methods on
C<$obj>.

    $obj->toString(...);  # Throws an error.

You need to use:

    my $func = $obj->{toString};
    $func->call(...);              # $func isa JSPL::Function

The automatic conversion of JSPL::Object instances into HASH references
can be controled per context, via the L<JSPL::Context/AutoTie> option.

When C<AutoTie> is TRUE, the default, and you obtained a HASH reference, but
you need the underlaying JSPL::Object instance, you can get it using
L<perlfunc/tied>.

    my $jsobj = tied %$obj;
    print ref $jsobj;		    # 'JSPL::Object'

In fact, C<tied> is the only way to distinguish the HASH reference as a
JSPL::Object.

=head1 INSTANCE METHODS

To avoid name clashes with the methods defined for an object in JavaScript,
instances of JSPL::Object only define a minimum of methods, all in
UPPERCASE, so any other method called will be proxied to the original
JavaScript object.

=over 4

=item FETCH ( PROP )

  my $value = $jsobj->FETCH('foo');

Get the property named PROP from the object.

Remember that by JavaScript rules, the value returned not necessarily is an
B<own property> of the object, it may come from the prototype chain.  Also, if
in JavaScript the object has any B<getter> associated with that name, the
getter will be called.

Because overloading, you don't need to call the FETCH method, you can just say
C<< $jsobj->{foo} >>.

=item STORE ( PROP, VALUE )

  $jsobj->STORE('baz', $value);

Set the property named PROP to VALUE in the object.

If the JavaScript object has any B<setter> associated with that name, the
setter will be called, as expected.

Because overloading, you don't need to call the STORE method, you can just say
C<< $jsobj->{baz} = $value; >>

=item DELETE ( PROP )

  $jsobj->DELETE('foo');

Delete the property named PROP from the object.

Because overloading, you can just say C<< delete $jsobj->{foo} >>

=item EXISTS ( PROP )

  if($jsobj->EXISTS('foo')) { ... }

Returns a TRUE value if a property named PROP exists in object or, by
JavaScript rules, I<in any object in the prototype chain> of the object.
Otherwise it returns FALSE.

Because overloading, you can just say C<< if(exists $jsobj->{foo}) { ... } >>

Because the B<prototype based> nature of JavaScript, if you need to known if
the object contains the specified property as a direct property and not
inherited through the prototype chain you must use the JavaScript function
C<hasOwnProperty>

    if( $jsobj->hasOwnProperty('foo') ) { ... }

=item CLASS_NAME

Returns the native class name of the object

=item HASH_REF

Returns a HASH reference, tied to the underlaying JSPL::Object.

The reference is cached, so every time you call HASH_REF, you obtain the same
reference.  This reference is the same used for the L</"SIMPLE INTERFACE">
above and for L<"OVERLOADED OPERATIONS"> below, so you seldom need to call
this method.

=item I<foo> ( ARGS )

    $jsobj->foo(@someargs);

Any other method I<foo> results in a call to the object's method of the same
name.

=back

=head1 OVERLOADED OPERATIONS

Instances of this class overload the "%{}" operator, so when you use a
JSPL::Object instance in a context that expect a HASH reference, the
operation just work.

=cut
