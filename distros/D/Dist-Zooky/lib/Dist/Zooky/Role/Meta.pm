package Dist::Zooky::Role::Meta;
$Dist::Zooky::Role::Meta::VERSION = '0.22';
# ABSTRACT: Dist::Zooky role for meta parsing

use strict;
use warnings;
use Moose::Role;
use CPAN::Meta;

sub prereqs_from_meta_file {
  my $self = shift;
  my $file = shift || return;

  if  ( -e $file ) {
    my $meta = eval { CPAN::Meta->load_file( $file ); };
    return { } unless $meta;
    my $prereqs = $meta->effective_prereqs;
    return $prereqs->as_string_hash;
  }
  return { }
}

sub meta_from_file {
  my $self = shift;
  my $file = shift || return;

  if  ( -e $file ) {
    my $meta = eval { CPAN::Meta->load_file( $file ); };
    return { } unless $meta;
    return $meta->as_struct;
  }
  return { }
}

no Moose::Role;

qq[Show me the META!];

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zooky::Role::Meta - Dist::Zooky role for meta parsing

=head1 VERSION

version 0.22

=head1 METHODS

=over

=item C<prereqs_from_meta_file>

=item C<meta_from_file>

=back

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
