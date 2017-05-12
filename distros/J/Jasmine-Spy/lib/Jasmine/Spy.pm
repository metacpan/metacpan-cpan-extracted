package Jasmine::Spy;
# ABSTRACT: Mocking library for perl inspired by Jasmine's spies
$Jasmine::Spy::VERSION = '1.02';
=head1 NAME

Jasmine::Spy

=head1 VERSION

version 1.02

=head1 SYNOPSIS

	use Test::Spec;
	use Jasmine::Spy qw(spyOn stopSpying expectSpy);

	describe "FooClass" => sub {
		before each => sub {
			spyOn("BarClass", "bazMethod")->andReturn("Bop");
			spyOn("BarClass", "bam")->andCallThrough;
		};
		it "calls BarClass" => sub {
			FooClass->doTheThing();
			expectSpy("BarClass", "bazMethod")->toHaveBeenCalled();
		};
		it "calls BarClass->bat method with 'bam'" => sub {
			FooClass->doTheThing();
			expectSpy("BarClass", "bat")->toHaveBeenCalledWith('bam')
		};
		after each => sub {
			stopSpying("BarClass");
		};
	};

=head1 Methods

Nothing is exported by default, but they cann all be pulled in with the :all tag

=head2 Base Class Methods

=over 1

=item spyOn($invocant, $method)

This is the setup method to begin spying. $invocant may be either an object instance or the name of
a class. Spying on a Class will automatically spy on all instances of the class, even those created
before setting up the spy.  Spyng on an instance only effects that instance, not the class or
other instances of that class.

A "spy" object is returned from this call which will allow introspection and testing of
calls.  However there is no need to catch this, as other convience methods provide a better
way of performing the same introspection later.

=item stopSpying($invocant)

Use this call to stop spying and restore original functionality to the object or class.

=item expectSpy($invocant, $method)

Use this to retrieve the "spy" object created by spyOn.  It also sets the spy object to
introspect of the provided C<$method>.  There is only one spy object created for each
distinct $invocant beign spied on, even if multiple methods are being watched. This is why
C<expectSpy> is the recomended way to start introspection on a spied method.

=item getCalls($invocant, $method)

This will fetch an array of array's containing the arguments passed each time the C<$method>
was called.  This is a tied array ref which also provides convience methods C<first> and
C<mostRecent>.

=back

=head2 Spy object methods

=over 1

=item toHaveBeenCalled

Test that the spied method has been called atleast once.

=item notToHaveBeenCalled

Test that the spied method was never called.

=item toHaveBeenCalledWith($matchers)

Expects that the spied method has been called with arguments matching C<$matchers> atleast once.
This is done with deep comparison via L<Test::Deep>.

=item notToHaveBeenCalledWith($matchers)

Inverse of toHaveBeenCalledWith.

=item andReturn($value)

Sets the spied method to return the supplied value.  Usually this would be called directly
on the return from C<spyOn>.

For example:

	spyOn($foo, 'bar')->andReturn('baz')

=item andCallThrough

Sets the spied method to call through to the original method, recording arguments passed along
the way.

=item andCallFake(sub {})

Sets the spied method to invoke the supplied code reference in place of the original method.
It does also record the arguments along the way.

=back

=head2 Qunatifiers

Quantifiers may be called on the return of either C<toHaveBeenCalled> or C<toHaveBeenCalledWith>
to stipulate how many times the method should have been called.

=over 1

=item once()

The method was called exactly one time

=item atleast(X)

Method was called atleast X times

=item atMost(X)

Method was not called more than X times

=item exactly(X)

Method was called exactly X times.

=back

=head1 TODO

=over 1

=item Convience Method for andThrow

Having put some thought into this, I haven't come up with a clean robust way to handle it.
In the end, I think you are better off using C<andCallFake> to throw an exception
if you need to test that.

=back

=head1 See also

L<Test::Spec>, L<Test::Deep>

=cut

use strict;
use warnings;
use vars qw(@EXPORT @EXPORT_OK %EXPORT_TAGS);
use base qw(Exporter);
use Class::MOP;


my (%spies) = ();

BEGIN {
	@EXPORT    = ();
	@EXPORT_OK = qw(
		spyOn
		stopSpying
		expectSpy
		getCalls
	);
	%EXPORT_TAGS = (
		all => \@EXPORT_OK,
	);
}

sub spyOn {
	my ($proto, $method) = @_;
	if(exists($spies{$proto})){
		$spies{$proto}->spyOnMethod($proto, $method);
	}
	else {
		my $spy = Jasmine::Spy::Instance->new($proto, $method);
		$spies{$proto} = $spy;
	}
	return $spies{$proto};
}

sub stopSpying {
	my ($proto) = @_;
	my $spy = delete $spies{$proto};
	if($spy){
		$spy->stopSpying;
	}
}

sub expectSpy {
	my($proto, $method) = @_;
	$spies{$proto}->setCurrentMethod($method);
	return $spies{$proto};
}

sub getCalls {
	expectSpy(@_)->calls;
}

package Jasmine::Spy::Instance;
$Jasmine::Spy::Instance::VERSION = '1.02';
use warnings;
use strict;
use base qw(Test::Builder::Module);
use Test::Deep;
use Want;

sub new {
	my ($mp, $proto, $method) = @_;
	my $class = ref($proto) || $proto;
	eval "package $class; use metaclass;" unless ($proto->can("metaclass"));


	my $self = bless(
		{
			proto => $proto,
			class => $class,
		},
		ref($mp) || $mp
	);
	if (ref($proto)) {
		my $spyClass = Class::MOP::Class->create_anon_class(superclasses => [$class]);
		$spyClass->rebless_instance($proto);
		$self->{spyClass} = $spyClass;
	}

	$self->spyOnMethod($proto, $method);

	return $self;
}

sub stopSpying {
	my $self = shift;
	if(ref($self->{proto})){
		$self->{class}->meta->rebless_instance_back($self->{proto});
	}
	else {
		foreach my $method (keys %{$self->{original_methods}}){
			$self->{class}->meta->remove_method($method);
			$self->{class}->meta->add_method($method, $self->{original_methods}{$method});
		}
	}
}

sub spyOnMethod {
	my($self, $proto, $method) = @_;

	my $class = ref($proto) || $proto;
	my $metaclass = $proto->meta;
	$metaclass->make_mutable if ($metaclass->is_immutable);

	$self->{current_method} = $method;
	$self->{original_methods}{$method} = $metaclass->get_method($method);
	$metaclass->remove_method($method);
	$self->{spyClass} = $metaclass;
	$self->{responses}{$method} = undef;
	$metaclass->add_method($method, sub { $self->__callFake($method, @_); });
}

sub setCurrentMethod {
	my $self = shift;
	$self->{current_method} = shift;
}

sub __callFake {
	my $self = shift;
	my $method = shift;
	if($_[0] eq $self->{proto}){
		shift;
	}
	elsif(ref($_[0]) && !ref($self->{proto}) && $_[0]->isa($self->{class})){
		shift;
	}
	$self->setCurrentMethod($method);
	push @{ $self->calls }, [@_];
	if(ref($self->{responses}{$method}) eq 'CODE'){
		return $self->{responses}{$method}->(@_);
	}
	elsif (ref($self->{responses}{$method}) eq 'Class::MOP::Method') {
		return $self->{responses}{$method}->execute(@_);
	}
	return $self->__returnFromValue($self->{responses}{$method});
}

sub __returnFromValue {
	my $self = shift;
	my $value = shift;
	if(wantarray){
		if(ref($value) eq 'ARRAY'){
			return @$value;
		}
		elsif(ref($value) eq 'HASH'){
			return %$value;
		}
	}
	return $value;
}

sub andReturn {
	my $self = shift;
	my($ret)  = @_;
	$self->{responses}{ $self->{current_method} } = $ret;
}

sub andReturnValues {
	my $self = shift;
	my(@returns) = @_;
	$self->{responses}{ $self->{current_method} } = sub { return $self->__returnFromValue(shift( @returns )) };
}

sub calls {
	my $self = shift;

	if(!exists $self->{calls}{ $self->{current_method} }){
		my(@calls) = ();
		$self->{calls}{ $self->{current_method} } = tie @calls, 'Jasmine::Spy::Instance::Calls';
	}

	return $self->{calls}{ $self->{current_method} };
}

sub andCallThrough {
	my $self = shift;
	my $toCall;
	if(ref($self->{proto})){
		$toCall = $self->{class}->meta->get_method($self->{current_method});
	}
	else {
		$toCall = $self->{original_methods}{ $self->{current_method} };
	}

	$self->andReturn($toCall);
}

sub andCallFake {
	shift->andReturn(@_);
}

sub toHaveBeenCalled {
	my($self) = shift;

	my $tb = __PACKAGE__->builder;

	if(want('VOID')){
		$tb->ok(scalar(@{ $self->calls }));
	}
	return $self->calls;
}

sub notToHaveBeenCalled {
	my($self) = shift;

	my $tb = __PACKAGE__->builder;

	if (scalar(@{ $self->calls })){
		$tb->ok(0);
		return 0;
	}
	$tb->ok(1);
	return 1;
}

sub toHaveBeenCalledWith {
	my($self) = shift;

	my $tb = __PACKAGE__->builder;

	my $calls = $self->__callsMatching(@_);

	if(want('VOID')){
		$tb->ok(scalar(@$calls));
	}

	return $calls;
}

sub notToHaveBeenCalledWith {
	my($self) = shift;

	my $tb = __PACKAGE__->builder;


	if (scalar(@{ $self->__callsMatching(@_) })){
		$tb->ok(0);
		return 0;
	}
	$tb->ok(1);
	return 1;
}

sub __callsMatching {
	my $self = shift;
	my(@calls) = ();
	my $calls = tie @calls, 'Jasmine::Spy::Instance::Calls';
	push @$calls, grep({eq_deeply([@_], $_)} @{ $self->calls } );
	return $calls;
}

package Jasmine::Spy::Instance::Calls;
$Jasmine::Spy::Instance::Calls::VERSION = '1.02';
use Tie::Array;
use Test::Builder::Module;
use vars qw(@ISA);
@ISA = qw(Tie::StdArray Test::Builder::Module);

sub first {
	my $self = shift;
	return $self->[0];
}

sub mostRecent {
	my $self = shift;
	return $self->[$#$self];
}

sub reset {
	my $self = shift;
	@$self = ();
}

sub once {
	my $self = shift;
	my $tb = __PACKAGE__->builder;
	$tb->ok(scalar(@$self) == 1);
}
sub atleast {
	my $self = shift;
	my $times = shift;
	my $tb = __PACKAGE__->builder;
	$tb->ok(scalar(@$self) >= $times);
}

sub atMost {
	my $self = shift;
	my $times = shift;
	my $tb = __PACKAGE__->builder;
	$tb->ok(scalar(@$self) <= $times);
}

sub exactly {
	my $self = shift;
	my $times = shift;
	my $tb = __PACKAGE__->builder;
	$tb->ok(scalar(@$self) == $times);
}

return 42;
