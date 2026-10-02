package Langertha::Manifest::Auth;
# ABSTRACT: One auth mechanism of a provider manifest (type only, never a secret)
our $VERSION = '0.503';
use Moose;
with 'Langertha::Manifest::Validation';


my @KNOWN_TYPES = qw( api_key );
my %KNOWN_TYPE  = map { $_ => 1 } @KNOWN_TYPES;

has id   => ( is => 'ro', isa => 'Str', required => 1 );
has type => ( is => 'ro', isa => 'Str', required => 1 );


sub BUILD {
  my ($self) = @_;
  $self->_check_id( 'id', $self->id );
  $self->_check_token( 'type', $self->type );
  return;
}

sub known_types { return @KNOWN_TYPES }


sub is_known_type { return $KNOWN_TYPE{ $_[0]->type } ? 1 : 0 }


sub from_hash {
  my ( $class, $data ) = @_;
  $class->_check_fields( $data, required => [qw( id type )] );
  return $class->new( map { $_ => $class->_string( $_, $data->{$_} ) } qw( id type ) );
}


sub to_hash {
  my ($self) = @_;
  return { id => $self->id, type => $self->type };
}


sub TO_JSON { shift->to_hash }

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Manifest::Auth - One auth mechanism of a provider manifest (type only, never a secret)

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    my $auth = Langertha::Manifest::Auth->new( id => 'api', type => 'api_key' );

=head1 DESCRIPTION

An auth entry of a L<Langertha::Manifest>. It names a B<mechanism> only. It
never holds a key, a secret path or an environment-variable name: which
local credential feeds the mechanism is the client's decision. The
header/query contract (C<Authorization: Bearer>, C<x-api-key>, C<?key=>, …)
belongs to the endpoint's dialect, not to this entry.

=head2 id

Local id, unique within the manifest; endpoints point at it with
C<auth_ref>.

=head2 type

Mechanism token (see L</known_types>). A pattern-valid but unknown type is
accepted; L</is_known_type> tells a client whether it can serve it.

=head2 known_types

The v1 auth-type vocabulary: C<api_key>.

=head2 is_known_type

True when L</type> is in the v1 vocabulary.

=head2 from_hash

Builds an auth entry from its JSON object form, rejecting unknown and
forbidden fields (a key, token, secret path or env-var name is forbidden).

=head2 to_hash

Returns the JSON object form.

=head1 SEE ALSO

=over

=item * L<Langertha::Manifest> - The provider manifest

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
