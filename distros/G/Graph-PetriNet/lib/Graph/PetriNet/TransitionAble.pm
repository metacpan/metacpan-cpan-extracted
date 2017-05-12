package Graph::PetriNet::TransitionAble;

use Class::Trait 'base';

our @REQUIRES = qw();

=pod

=head1 NAME

Graph::PetriNet::TransitionAble - Trait for Petri net transition

=head1 SYNOPSIS

  {
    package My::Place::TimeDepend;
    use Class::Trait (
	'Graph::PetriNet::TransitionAble' => {
	    exclude => [ 'ignitable', 'ignite' ] });
    ...
    sub ignitable { ... }
    sub ignite    { ... }
   }

=head1 DESCRIPTION

Petri net transition nodes carry the information when they can be triggered, how they execute and
how they move information from the incoming data nodes to the outgoing ones.

The default behavior implemented here only takes tokens from the upstream pushing them into the
downstream data nodes.

=head1 TRAIT

=head2 Methods

=over

=item B<inputs>

Configures the list of incoming data nodes. Passed in as list reference.

=cut

sub inputs {
    my $self = shift;
    $self->{_in_places} = $_[0];
}

=pod

=item B<outputs>

Configures the list of outgoing data nodes. Passed in as list reference.

=cut

sub outputs {
    my $self = shift;
    $self->{_out_places} = $_[0];
}

=pod

=item B<ignitable>

Method to check whether this particular transition can be fired. Returns a non-zero result if that
is the case.

=cut

sub ignitable {
    my $self = shift;
    foreach my $in (@{ $self->{_in_places} }) {
	return 1 if $in->tokens;
    }
    return 0;
}

=pod

=item B<ignite>

Actually fire the transition.

=cut

sub ignite {
    my $self = shift;
    return unless $self->ignitable;
    $_->incr_tokens (-1) foreach @{ $self->{_in_places} };
    $_->incr_tokens (+1) foreach @{ $self->{_out_places} };
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

