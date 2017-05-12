package Graph::PetriNet::PlaceAble;

use Class::Trait 'base';

our @REQUIRES = qw();

=pod

=head1 NAME

Graph::PetriNet::PlaceAble - Trait for Petri net data nodes

=head1 SYNOPSIS

  # create your own data nodes with this trait
  {
    package My::Place::TimeDepend;
    use Class::Trait qw(Graph::PetriNet::PlaceAble);

    sub new {
	my $class = shift;
	return bless { ..., ... }, $class;
    }
    sub .... {
        ...
    }
  }

=head1 DESCRIPTION

Petri net data nodes are supposed to carry the information within the Petri net. What information
this is, the Petri net does not care.

The default behavior implemented here is the I<classical> interpretation of every node having
I<tokens>. Accordingly there is a method to set/read the number of tokens and one method to
increment/decrement that.

If your transitions do something completely different, then you will implement your own data nodes
without importing any of the functionality here.

=head1 TRAIT

=head2 Methods

=over

=item B<tokens>

Getter/setter method for the number of tokens in this node.

=cut

sub tokens {
    my $self = shift;
    my $tokens = shift;
    return defined $tokens ? $self->{_tokens} = $tokens : $self->{_tokens};
}

=pod

=item B<incr_tokens>

This method expects one integer parameter (positive or negative). Its value
is added to the number of tokens. The result will be corrected to zero.

=cut

sub incr_tokens {
    my $self = shift;
    my $delta = shift;
    $self->{_tokens} += $delta;
    $self->{_tokens} = 0 if $self->{_tokens} < 0;
}

=pod

=back

=head1 SEE ALSO

L<Graph::PetriNet>

=head1 AUTHOR

Robert Barta, E<lt>drrho@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Robert Barta

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself, either Perl version 5.10.0 or, at your option, any later version of Perl 5 you may have
available.


=cut

"against all gods";
