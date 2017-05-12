package Math::Symbolic::Custom::Transformation::Group;

use 5.006;
use strict;
use warnings;

use Carp qw/croak/;
use Math::Symbolic qw/:all/;
use Math::Symbolic::Custom::Pattern;
use base 'Math::Symbolic::Custom::Transformation', 'Exporter';

our $VERSION = '2.02';

=encoding utf8

=head1 NAME

Math::Symbolic::Custom::Transformation::Group - Group of Transformations

=head1 SYNOPSIS

  use Math::Symbolic::Custom::Transformation qw/:all/;
  use Math::Symbolic qw/parse_from_string/;
  
  my $group = new_trafo_group(
    ',',
    new_trafo( 'TREE_x ^ 1'       => 'TREE_x'                           ),
    new_trafo( 'TREE_x ^ CONST_a' => 'TREE_x * TREE_x^value{CONST_a-1}' ),
  );
  
  my $function = parse_from_string(
    '(foo+1)^3 + bar^2'
  );
  
  while(1) {
      my $result = $group->apply_recursive($function);
      last if not defined $result;
      $function = $result;
  }
  
  print $function."\n"
  # prints "((foo + 1) * ((foo + 1) * (foo + 1))) + (bar * bar)"

=head1 DESCRIPTION

A C<Math::Symbolic::Custom::Transformation::Group> object (Trafo Group for now)
represents a conjunction of several transformations and is a transformation
itself. An example is in order here:

  my $group = new_trafo_group( ',', $trafo1, $trafo2, ... );

Now, C<$group> can be applied to L<Math::Symbolic> trees as if it was
an ordinary transformation object itself. In fact it is, because this is
a subclass of L<Math::Symbolic::Custom::Transformation>.

The first argument to the constructor specifies the condition under which the
grouped transformations are applied. C<','> is the simplest form. It means
that all grouped transformations are always applied. C<'&'> means that
the next transformation will only be applied if the previous one succeeded.
Finally, C<'|'> means that the first transformation to succeed is the last
that is tried. C<'&'> and C<'|'> are C<and> and C<or> operators if you will.

=head2 EXPORT

None by default, but you may choose to import the C<new_trafo_group>
subroutine as an alternative constructor for
C<Math::Symbolic::Custom::Transformation::Group> objects.

=cut

=head2 METHODS

This is a list of public methods.

=over 2

=cut

=item new

This is the constructor for C<Math::Symbolic::Custom::Transformation::Group>
objects.
First argument must be the type of the group as explained above. (C<','>,
C<'&'>, or C<'|'>.) Following the group type may be any number
of transformations (or groups thereof).

=cut

our %EXPORT_TAGS = ( 'all' => [ qw(
	new_trafo_group
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

my %Conjunctions = (
    '&' => 1,
    '|' => 1,
    ',' => 1,
);

sub new {
	my $proto = shift;
	my $class = ref($proto)||$proto;

    my $conjunction = shift;
    $conjunction = ',' if not defined $conjunction;

    unless ($Conjunctions{$conjunction}) {
        croak("Invalid conjunction type '$conjunction'.");
    }

    my @trafos;
    while (@_) {
        my $this = shift @_;
        if (
            ref($this)
            and $this->isa('Math::Symbolic::Custom::Transformation')
           )
        {
            push @trafos, $this;
        }
        else {
            my $pattern = shift @_;
            my $trafo = Math::Symbolic::Custom::Transformation->new(
                $this, $pattern
            );
            push @trafos, $trafo;
        }
    }

	my $self = {
		transformations => \@trafos,
        conjunction => $conjunction,
	};

	bless $self => $class;

    return $self;
}


=item apply

Applies the transformation (group) to a
C<Math::Symbolic> tree. First argument must be
a C<Math::Symbolic> tree to transform. The tree is not transformed in-place,
but its matched subtrees are contained in the transformed tree, so if you plan
to use the original tree as well as the transformed tree, take
care to clone one of the trees.

C<apply()> returns the transformed tree if the transformation pattern matched
and a false value otherwise.

On errors, it throws a fatal error.

=cut

sub apply {
	my $self = shift;
	my $tree = shift;

    if (not ref($tree) =~ /^Math::Symbolic/) {
		croak("First argument to apply() must be a Math::Symbolic tree.");
	}

    my $new;
    my $trafos = $self->{transformations};
    my $conj = $self->{conjunction};

    # apply sequentially regardless of outcome
    if ($conj eq ',') {
        foreach my $trafo (@$trafos) {
            my $res = $trafo->apply($tree);
            $new = $tree = $res if defined $res;
        }
    }
    # apply as long as the previous applied
    elsif ($conj eq '&') {
        foreach my $trafo (@$trafos) {
            my $res = $trafo->apply($tree);
            $new = $tree = $res if defined $res;
            last unless defined $res;
        }
    }
    # apply until the first is applied
    elsif ($conj eq '|') {
        foreach my $trafo (@$trafos) {
            my $res = $trafo->apply($tree);
            if(defined $res) {
                $new = $tree = $res;
                last;
            }
        }
    }
    else {
        warn "Invalid conjunction '$conj'";
    }

	return $new;
}


=item to_string

Returns a string representation of the transformation.
In presence of the C<simplify> or C<value> hooks, this may
fail to return the correct represenation. It does not round-trip!

(Generally, it should work if only one hook is present, but fails if
more than one hook is found.)

=cut

sub to_string {
    my $self = shift;

    my $str = '[ ' . join(
        ' '.$self->{conjunction}.' ',
        map {
            $_->to_string()
        } @{$self->{transformations}}
    ) . ' ]';
    return $str;
}

=item apply_recursive

This method is inherited from L<Math::Symbolic::Custom::Transformation>.

=back

=head2 SUBROUTINES

This is a list of public subroutines.

=over 2

=cut

=item new_trafo_group

This subroutine is an alternative to the C<new()> constructor for
Math::Symbolic::Custom::Transformation::Group objects that uses a hard coded
package name. (So if you want to subclass this module, you should be aware
of that!)

=cut

sub new_trafo_group {
	unshift @_, __PACKAGE__;
	goto &new;
}

1;
__END__

=back

=head1 SEE ALSO

New versions of this module can be found on http://steffen-mueller.net or CPAN.

This module uses the L<Math::Symbolic> framework for symbolic computations.

L<Math::Symbolic::Custom::Pattern> implements the pattern matching routines.

=head1 AUTHOR

Steffen Müller, E<lt>symbolic-module at steffen-mueller dot netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006, 2007, 2008, 2013 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
