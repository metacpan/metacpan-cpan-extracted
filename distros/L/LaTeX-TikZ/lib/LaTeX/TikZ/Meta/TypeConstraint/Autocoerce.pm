package LaTeX::TikZ::Meta::TypeConstraint::Autocoerce;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ::Meta::TypeConstraint::Autocoerce - Type constraint metaclass that autoloads type coercions.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    # The target class of the autocoercion (cannot be changed)
    {
     package X;
     use Mouse;
     has 'id' => (
      is  => 'ro',
      isa => 'Int',
     );
     use LaTeX::TikZ::Meta::TypeConstraint::Autocoerce;
     use Mouse::Util::TypeConstraints;
     register_type_constraint(
      LaTeX::TikZ::Meta::TypeConstraint::Autocoerce->new(
       name   => 'X::Autocoerce',
       target => find_type_constraint(__PACKAGE__),
       mapper => sub { join '::', __PACKAGE__, 'From', $_[1] },
      );
     );
     __PACKAGE__->meta->make_immutable;
    }

    # The class that does the coercion (cannot be changed)
    {
     package Y;
     use Mouse;
     has 'x' => (
      is      => 'ro',
      isa     => 'X::Autocoerce',
      coerce  => 1,
      handles => [ 'id' ],
     );
     __PACKAGE__->meta->make_immutable;
    }

    # Another class the user wants to use instead of X (cannot be changed)
    {
     package Z;
     use Mouse;
     has 'id' => (
      is  => 'ro',
      isa => 'Num',
     );
     __PACKAGE__->meta->make_immutable;
    }

    # The autocoercion class, defined by the user in X/From/Z.pm
    {
     package X::From::Z;
     use Mouse::Util::TypeConstraints;
     coerce 'X::Autocoerce'
         => from 'Z'
         => via { X->new(id => int $_->id) };
    }

    my $z = Z->new(id => 123);
    my $y = Y->new(x => $z);
    print $y->id; # 123

=head1 DESCRIPTION

When a type coercion is attempted, this type constraint metaclass tries to autoload a specific module which is supposed to contain the actual coercion code.
This allows you to declare types that can be replaced (through coercion) at the end user's discretion.

It only supports L<Mouse> currently.

Note that you will need L<Mouse::Util::TypeConstraints/register_type_constraint> to install this type constraint, which is only available starting L<Mouse> C<0.63>.

=cut

use Scalar::Util qw<blessed>;

use Sub::Name ();

use LaTeX::TikZ::Tools;

use Mouse;

=head1 RELATIONSHIPS

This class inherits from L<Mouse::Meta::TypeConstraint>.

=cut

extends 'Mouse::Meta::TypeConstraint';

=head1 ATTRIBUTES

=head2 C<name>

The name of the type constraint.
This must be the target of both the classes that want to use the autocoercion feature and the user defined coercions in the autoloaded classes.

This attribute is inherited from the L<Mouse> type constraint metaclass.

=head2 C<mapper>

A code reference that maps an object class name to the name of the package in which the coercion can be found, or C<undef> to disable coercion for this class name.
It is called with the type constraint object as first argument, followed by the class name.

=cut

has 'mapper' => (
 is       => 'ro',
 isa      => 'CodeRef',
 required => 1,
);

=head2 C<target>

A type constraint that defines into what the objects are going to be coerced.
Objects satisfying this type constraint will be automatically considered as valid and will not be coerced.
If it is given as a plain string, then a type constraint with the same name is searched for in the global type constraint registry.

=cut

has 'target' => (
 is       => 'ro',
 isa      => 'Mouse::Meta::TypeConstraint',
 required => 1,
);

my $target_tc = __PACKAGE__->meta->find_attribute_by_name('target')
                                 ->type_constraint;

=head1 METHODS

=head2 C<new>

    my $tc = LaTeX::TikZ::Meta::TypeConstraint::Autocoerce->new(
     name   => $name,
     mapper => $mapper,
     target => $target,
    );

Constructs a type constraint object that will attempt to autocoerce objects that are not valid according to C<$target> by loading the class returned by C<$mapper>.

=cut

around 'new' => sub {
 my ($orig, $class, %args) = @_;

 unless (exists $args{mapper}) {
  $args{mapper} = sub { join '::', $_[0]->target->name, $_[1] };
 }

 my $target = delete $args{target};
 unless (blessed $target) {
  my $target_name = defined $target ? "target $target" : 'undefined target';
  $target = LaTeX::TikZ::Tools::type_constraint($target) if defined $target;
  Carp::confess("No meta object for $target_name")   unless defined $target;
 }
 $target_tc->assert_valid($target);
 $args{target} = $target;

 $args{constraint} = Sub::Name::subname('_constraint' => sub {
  my ($thing) = @_;

  # Remember that when ->check is called inside coerce, a return value of 0
  # means that coercion should take place, while 1 signifies that the value is
  # already OK. Thus we should return true if and only if $thing passes the
  # target type constraint.

  return $target->check($thing);
 });

 return $class->$orig(%args);
};

=head2 C<coerce>

    $tc->coerce($thing)

Tries to coerce C<$thing> by first loading a class that might contain a type coercion for it.

=cut

around 'coerce' => sub {
 my ($orig, $tc, $thing) = @_;

 # The original coerce gets an hold onto the type coercions *before* calling
 # the constraint. Thus, we have to force the loading before recalling into
 # $orig.

 # First, check whether $thing is already of the right kind.
 return $thing if $tc->check($thing);

 # If $thing isn't even an object, don't bother trying to autoload a coercion
 my $class = blessed($thing);
 if (defined $class) {
  $class = $tc->mapper->($tc, $class);

  if (defined $class) {
   # Find the file to autoload
   (my $pm = $class) =~ s{::}{/}g;
   $pm .= '.pm';

   unless ($INC{$pm}) { # Not loaded yet
    local $@;
    eval {
     # We die often here, even though we're not really interested in the error.
     # However, if a die handler is set (e.g. to \&Carp::confess), this can get
     # very slow. Resetting the handler shows a 10% total time improvement for
     # the geodyn app.
     local $SIG{__DIE__};
     require $pm;
    };
   }
  }
 }

 $tc->$orig($thing);
};

__PACKAGE__->meta->make_immutable(
 inline_constructor => 0,
);

=head1 SEE ALSO

L<Mouse::Meta::TypeConstraint>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-latex-tikz at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LaTeX-TikZ>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LaTeX::TikZ

=head1 COPYRIGHT & LICENSE

Copyright 2010,2011,2012,2013,2014,2015 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of LaTeX::TikZ::Meta::TypeConstraint::Autocoerce
