package Lang::Tree::Builder::Class;

use strict;
use warnings;
use Lang::Tree::Builder::Scalar;
use Lang::Tree::Builder::Args;

our $VERSION = '0.01';


=head1 NAME

Lang::Tree::Builder::Data - Tree Data

=head1 SYNOPSIS

  use Lang::Tree::Builder::Parser;
  my $parser = new Lang::Tree::Builder::Parser();
  my $data = $parser->parseFile($datafile);
  foreach my $class ($data->classes()) {
      my $parent = $class->parent();
      my @args = $class->args();
      my $name = $class->name();
      # etc
  }

This package contains an ever-growing list of accessor methods
to make the maintainance and extension of templates easy.
See below for the full list.

=head1 DESCRIPTION

=head2 new

  my $class = new Lang::Tree::Builder::Class(%params);

Creates and returns a new instance of Class. Don't do this, the parser
does it for you, however for reference, C<%params> is:

=over 4

=item class

The class name.

=item parent

The parent class name, if any.

=item args

The arguments to the constructor,
will be passed to L<Lang::Tree::Builder::Args::List()>

=item abstract

True if the class was declared abstract.

=back

Note that each class is unique, and that additional calls to C<new>
may be used to add information to an existing class object which
will then be returned. It is an error for new information to conflict
with existing information however.

=cut

{
    my %symbols;

    sub new {
        my ($class, %params) = @_;
        die "no class specified" unless $params{class};
        my $name = $params{class};
        unless (exists $symbols{$name}) {
            if ($name eq 'scalar') {
                return new Lang::Tree::Builder::Scalar();
            } else {
                $symbols{$name} = bless {
                    _name => $name,
                    _substantial => 0,
                    _abstract => 0,
                    _parent => 0,
                    _children => {},
                    _args => 0,
                }, $class;
            }
        }
        my $self = $symbols{$name};
        $self->{parts} = [ split(/::/, $self->{_name}) ] unless $self->{parts};
        if ($params{parent}) {
            my $parent = $params{parent};
            if ($self->{_parent}) {
                die "parent conflict on $name: ",
                    $self->{_parent}->name(),
                    " ne $parent"
                    unless $self->{_parent}->name() eq $parent;
            } else {
                $self->{_parent} = $class->new(class => $parent);
            }
            $self->{_parent}->_acceptChild($self);
        }
        if ($params{args}) {
            my @args = @{$params{args}};
            if ($self->{_args}) {
                my @argnames = map {$_->name} @{$self->{_args}};
                my $l1 = '(' . join(', ', @args) . ')';
                my $l2 = '(' . join(', ', @argnames) . ')';
                die "args conflict on $name: $l1 ne $l2" unless $l1 eq $l2;
            } else {
                $self->{_args} = Lang::Tree::Builder::Args->List($params{args});
            }
        }
        if ($params{abstract}) {
            $self->{_abstract} = 1;
        }
        return $self;
    }
}

sub _acceptChild {
    my ($self, $child) = @_;
    $self->{_children}{$child->name} = $child;
}

sub descendants {
    my ($self) = @_;
    my @descendants = ();
    foreach my $child ( values %{$self->{_children}} ) {
        push @descendants, $child;
        push @descendants, $child->descendants;
    }
    return sort @descendants;
}

=head2 name

Returns the fully qualified class name, with parts joined by C<::>
by default. An alternative join string can be passed as an optional
argument.

=cut

sub name {
    my ($self, $join) = @_;
    $join = '::' unless defined $join;
    return join($join, $self->parts);
}

=head2 parent

Returns the parent class, or false if no parent.

=cut

sub parent {
    my ($self) = @_;
    return $self->{_parent};
}

=head2 args

Returns an array of arguments to the constructor.
Each element is a C<Lang::Tree::Builder::Args>.

=cut

sub args {
    my ($self) = @_;
    return wantarray ? @{$self->{_args}} : $self->{_args};
}

=head2 numargs

Returns the number of args the constructor accepts.

=cut

sub numargs {
    my ($self) = @_;
    return scalar(@{$self->{_args}});
}

=head2 parts

Returns an array or arrayref of the components of the class name.
For example C<Foo::Expr> has parts C<Foo> and C<Expr>.

=cut

sub parts {
    my ($self) = @_;
    return wantarray ? @{$self->{parts}} : $self->{parts};
}

=head2 lastpart

Returns the last component of C<parts> above.

=cut

sub lastpart {
    my ($self) = @_;
    return $self->{parts}[-1];
}

=head2 namespace

Returns all but the last component of C<parts>, joined with C<::> by default,
but an alternative can be supplied as an optional argument.

=cut

sub namespace {
    my ($self, $join) = @_;
    $join = '::' unless defined $join;
    my @parts = @{$self->{parts}};
    pop @parts;
    return join('::', @parts) || 'main';
}

=head2 interface

Returns an equivalent interface name by prepending a literal C<i> to the
last part of the class name.

=cut

sub interface {
    my ($self, $join) = @_;
    $join = '::' unless defined $join;
    my @parts = @{$self->{parts}};
    my $lastpart = pop @parts;
    $lastpart = 'i' . $lastpart;
    push @parts, $lastpart;
    return join($join, @parts);
}

=head2 is_scalar

Returns false

=cut

sub is_scalar { 0 }

# internal, sets a flag to say the class has a definition.
sub substantiate {
    my ($self) = @_;
    $self->{_substantial} = 1;
}

=head2 is_substantioal

Returns true if the class was defined in the config (as opposed to merely
being used as an argument type). Not to be confused with C<is_concrete>.

=cut

sub is_substantial {
    my ($self) = @_;
    return $self->{_substantial};
}

=head2 is_abstract

Returns true if the class was declared abstract.

=cut

sub is_abstract {
    my ($self) = @_;
    return $self->{_abstract};
}

=head2 is_concrete

Returns true if the class was not declared abstract. N.b. a class is
concrete by default, C<is_substantial> could still return false for
the same class.

=cut

sub is_concrete {
    my ($self) = @_;
    return !$self->{_abstract};
}

=head1 SEE ALSO

L<Lang::Tree::Builder>

=head1 AUTHOR

Bill Hails, E<lt>me@billhails.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Bill Hails

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
