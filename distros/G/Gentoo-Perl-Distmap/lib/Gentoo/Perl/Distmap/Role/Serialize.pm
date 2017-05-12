use strict;
use warnings;

package Gentoo::Perl::Distmap::Role::Serialize;
BEGIN {
  $Gentoo::Perl::Distmap::Role::Serialize::AUTHORITY = 'cpan:KENTNL';
}
{
  $Gentoo::Perl::Distmap::Role::Serialize::VERSION = '0.2.0';
}

# ABSTRACT: Basic utilities for serialising/sorting/indexing C<Distmap> nodes.

use Moose::Role;


requires to_rec =>;


requires from_rec =>;


sub hash {
  my ($self) = @_;
  require Data::Dump;
  my $rec = Data::Dump::pp( $self->to_rec );
  require Digest::SHA;
  return Digest::SHA::sha1_base64($rec);
}

no Moose::Role;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Gentoo::Perl::Distmap::Role::Serialize - Basic utilities for serialising/sorting/indexing C<Distmap> nodes.

=head1 VERSION

version 0.2.0

=head1 ROLE-REQUIRED METHODS

=head2 to_rec

=head2 from_rec

=head1 METHODS

=head2 hash

Returns C<SHA1> of C<<pp($instance->to_rec)>>

  $astring = $instance->hash()

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
