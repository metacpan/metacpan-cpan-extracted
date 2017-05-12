package Heritable::Types;
no strict; # !!!

use Scalar::Util;
use Carp;

use vars qw/*CORE::GLOBAL::bless $VERSION/;

$VERSION     = '1.00';

BEGIN {	@{"${_}::ISA"} = 'Object' for
          qw/HASH ARRAY SCALAR CODE IO GLOB/ }

sub bless 
  { my($thing, $class) = @_;
    $class ||= caller;
    my $type = Scalar::Util::reftype($thing);

    push @{"$class\::ISA"}, $type unless UNIVERSAL::isa($class, $type);
    CORE::bless $thing, $class };

*CORE::GLOBAL::bless = \&bless;

sub UNIVERSAL::DESTROY { }

sub UNIVERSAL::AUTOLOAD
  { my($thing, @args) = @_;
    my $type = Scalar::Util::reftype($thing);
    my $class = ref($thing);
    my $method = $UNIVERSAL::AUTOLOAD;
    $method =~ s/.*:://;

    &bless($thing, $class) unless $class->isa($type); # Teehee

    $method = $class->can($method);
    if ($method)
      { goto &$method }
    else
      { croak qq{Can't locate object method "$method" via package $class} } }

=head1 NAME

Heritable::Types - Make object dispatch look at an object's type

=head1 SYNOPSIS

  use Heritable::Types

  sub Object::as_string
    { my($self) = @_;
      join " ", 'a', ref($self), $self->content_string; }

  sub HASH::content_string
    { my($self) = @_;
      my $str = join ', ', map {"$_ => $self->{$_}", keys %$self;
      return "{ $str }" }

  sub ARRAY::content_string
    { my($self) = @_;
      return '[ ', join(', ', @$self), ' ]' }

=head1 DESCRIPTION

Heritable::Types sets about making Perl's method dispatch system
consistent with the way C<isa> works. Right now, if you have an object
which you represent as, say, a blessed Hash, then, according to
C<UNIVERSAL::isa>, that object is a HASH. But if you implement, say
C<HASH::foo>, a method that only exists in the HASH namespace, then
C<UNIVERSAL:can> will not see it, nor will it get called if you do C<<
$obj->foo >>. This strikes me as an unsatisfactory state of affairs,
hence Heritable::Types.

=head1 USAGE

There's nothing to it, see the synopsis for how it works. Note that,
if once one module uses Heritable::Types then *all* objects will do
method lookup via their types.

If you want to have a method which all types can inherit from, but
which will ensure that individual types can override that method, then
you should implement it in the Object class, rather than in UNIVERSAL
(if you implement a method in UNIVERSAL there's a good chance that the
specific type's methods will never get called, which isn't what anyone
wants.

=head1 BUGS

None sighted so far. There are bound to be some though.

=head1 SUPPORT

What support there is for this module is provided on a "When the
author has time" basis. If you do have problems with it, please, drop
me a line. Support requests that come with a failing test are
I<greatly> appreciated. Bug reports that come with a new test and a
patch to fix it will earn my undying gratitude.

=head1 AUTHOR

	Piers Cawley
	CPAN ID: PDCAWLEY
	pdcawley@bofh.org.uk
	http://pc1.bofhadsl.ftech.co.uk:8080/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

############################################# main pod documentation end ##


1; #this line is important and will help the module return a true value
__END__

