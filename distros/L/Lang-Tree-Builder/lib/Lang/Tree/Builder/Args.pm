package Lang::Tree::Builder::Args;

use strict;
use warnings;
use Lang::Tree::Builder::Class;

=head1 NAME

Lang::Tree::Builder::Args - wrapper for a tree node constructor's argument list.

=head1 SYNOPSIS

  use Lang::Tree::Builder::Args;
  my $ra_args = Lang::Tree::Builder::Args->List([ [$classname, $argname ] ... ]);

Used internally by C<Lang::Tree::Builder> to encapsulate argument lists,
a C<Lang::Tree::Builder::Args> object is a Decorator of the underlying
C<Lang::Tree::Builder::Class>. It forwards all method requests to that class
and adds an addidional C<argname()> method returning the name of the
argument.

=cut

sub _new {
    my ($class, $arg, $argname) = @_;
    bless {
        arg     => $arg,
        argname => $argname,
    }, $class;
}

=head2 List

  my $list = Lang::Tree::Builder::Args->List(\@args);

C<@args> is an array of array refs. Each array ref contains a string
typename, and optionally a string varname, for example C<['Expr', 'left']>.

Returns a listref of C<Lang::Tree::Builder::Args> objects.

If the argument name is omitted from the sub array component describing
the argument, then the last part of the class namne will be used in its place.

Argument names will be sequentially numbered to avoid conflicts, but only
if necessary. For example given the following call

  my $ra_args = Lang::Tree::Builder::Args->List([
    [qw(Foo::Expr)],
    [qw(Foo::Expr)],
    [qw(Foo::Expr foo)],
    [qw(Foo::Expr foo)],
    [qw(Foo::Expr bar)],
    [qw(Foo::ExprList)]
  ])

The resulting argument names will be:

  Expr1, Expr2, foo1, foo2, bar, ExprList

=cut

sub List {
    my ($class, $ra_args) = @_;
    my @classes =
      map { Lang::Tree::Builder::Class->new(class => $_->[0]) } @$ra_args;
    my %count;
    my %counter;
    my @protonames =
      map { $ra_args->[$_][1] || $classes[$_]->lastpart }
      (0 .. (scalar(@classes) - 1));
    foreach my $arg (@protonames) {
        $count{$arg} ||= 0;
        $count{$arg}++;
        $counter{$arg} = 0;
    }
    my @argnames;
    foreach my $arg (@protonames) {
        push @argnames,
          (
            $arg
              . (
                $count{$arg} > 1
                ? ++$counter{$arg}
                : ''
              )
          );
    }

    [ map { $class->_new($classes[$_], $argnames[$_]) }
          (0 .. (scalar(@classes) - 1)) ];
}

# autoload interferes with tt2

sub name {
    my ($self, @args) = @_;
    return $self->{arg}->name(@args);
}

sub parent {
    my ($self, @args) = @_;
    return $self->{arg}->parent(@args);
}

sub args {
    my ($self, @args) = @_;
    return $self->{arg}->args(@args);
}

sub parts {
    my ($self, @args) = @_;
    return $self->{arg}->parts(@args);
}

sub lastpart {
    my ($self, @args) = @_;
    return $self->{arg}->lastpart(@args);
}

sub namespace {
    my ($self, @args) = @_;
    return $self->{arg}->namespace(@args);
}

sub interface {
    my ($self, @args) = @_;
    return $self->{arg}->namespace(@args);
}

sub is_scalar {
    my ($self, @args) = @_;
    return $self->{arg}->is_scalar(@args);
}

sub is_substantial {
    my ($self, @args) = @_;
    return $self->{arg}->is_substantial(@args);
}

sub argname {
    my ($self) = @_;
    return $self->{argname};
}

=head1 AUTHOR

  Bill Hails <me@billhails.net>

=head1 SEE ALSO

L<Lang::Tree::Builder>, L<Lang::Tree::Builder::Class>.

=cut

1;
