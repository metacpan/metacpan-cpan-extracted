package Die::Hard;

use 5.008;
use Moo;
use Scalar::Util ();
use Carp ();
use if $] < 5.010, 'UNIVERSAL::DOES';

BEGIN {
	no warnings;
	$Die::Hard::AUTHORITY = 'cpan:TOBYINK';
	$Die::Hard::VERSION   = '0.004';
}

has proxy_for => (
	is       => 'ro',
	isa      => sub {
		Scalar::Util::blessed($_[0])
			or Carp::confess("proxy_for must be a blessed object")
	},
	required => 1,
);

has last_error => (
	is       => 'ro',
	required => 0,
	writer   => '_set_last_error',
	clearer  => '_clear_last_error',
);

sub BUILDARGS
{
	my $class = shift;
	return +{ proxy_for => $_[0] } if @_ == 1 && Scalar::Util::blessed($_[0]);
	return $class->SUPER::BUILDARGS(@_);
}

sub AUTOLOAD
{
	my ($meth) = (our $AUTOLOAD =~ /::([^:]+)$/);
	
	local $@ = undef;
	my $self = shift;
	
	$self->_clear_last_error;
	
	my $coderef = $self->proxy_for->can($meth) || $meth;
	
	if (wantarray)
	{
		my @r;
		$self->_set_last_error($@)
			unless eval { @r = $self->proxy_for->$coderef(@_); 1 };
		return @r;
	}
	elsif (defined wantarray)
	{
		my $r;
		$self->_set_last_error($@)
			unless eval { $r = $self->proxy_for->$coderef(@_); 1 };
		return $r;
	}
	else
	{
		$self->_set_last_error($@)
			unless eval { $self->proxy_for->$coderef(@_); 1 };
		return;
	}
}

sub can
{
	my ($self, $method) = @_;
	return $self->SUPER::can($method) unless Scalar::Util::blessed($self);
	
	my $i_can  = $self->SUPER::can($method);
	my $he_can = $self->proxy_for->can($method);
	
	return $i_can if $i_can;
	return sub { our $AUTOLOAD = $method; goto \&AUTOLOAD } if $he_can;
	return;
}

sub DOES
{
	my ($self, $role) = @_;
	return $self->SUPER::DOES($role) unless Scalar::Util::blessed($self);
	$self->SUPER::DOES($role) or $self->proxy_for->DOES($role);
}

sub isa
{
	my ($self, $role) = @_;
	return $self->SUPER::isa($role) unless Scalar::Util::blessed($self);
	$self->SUPER::isa($role) or $self->proxy_for->isa($role);
}

no Moo;

1;
__END__

=head1 NAME

Die::Hard - objects as resistant to dying as John Maclane

=head1 SYNOPSIS

 my $fragile = Fragile::Object->new;
 my $diehard = Die::Hard->new($fragile);
 
 $diehard->isa('Fragile::Object'); # true
 $diehard->method_that_will_die;   # lives!
 $fragile->method_that_will_die;   # dies!

=head1 DESCRIPTION

Die::Hard allows you to create fairly transparent wrapper object that
delegates all method calls through to the wrapped object, but does so
within an C<< eval { ... } >> block. If the wrapped method call dies,
then it sets a C<< last_error >> attribute.

=head2 Constructor

=over

=item C<< new(%attributes) >>

Standard Moose-style constructor.

=item C<< new($object) >>

Shortcut for setting the C<proxy_for> attribute.

=back

=head2 Attributes

=over

=item C<< proxy_for >>

The object being wrapped. Read-only; required.

=item C<< last_error >>

If the last proxied method call died, then this attribute will contain
the error. Otherwise will be undef.

=back

=head2 Methods

=over

=item C<< isa >>

Tells lies; claims to be the object it's proxying.

=item C<< DOES >>

Tells the truth; claims to do the object it's proxying.

=item C<< can >>

Tells the truth; claims it can do anything the object it's proxying can do.

=back

=begin private

=item AUTOLOAD

=item BUILDARGS

=end private

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Die-Hard>.

=head1 SEE ALSO

L<No::Die>.

The C<< $_try >> function from L<Object::Util> is a different way to
achieve a similar effect.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

