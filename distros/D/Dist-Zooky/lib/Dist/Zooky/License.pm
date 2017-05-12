package Dist::Zooky::License;
$Dist::Zooky::License::VERSION = '0.22';
# ABSTRACT: license objects for Dist::Zooky

use strict;
use warnings;
use Module::Pluggable search_path => 'Software::License', except => qr/(Custom)$/;
use Class::Load ();
use Moose;

has 'metaname' => (
  is => 'ro',
  isa => 'Str',
  required => 1,
);

has 'license' => (
  is => 'ro',
  isa => 'ArrayRef[Software::License]',
  lazy => 1,
  builder => '_build_license',
  init_arg => undef,
);

sub _build_license {
  my $self = shift;
  my @licenses;
  foreach my $plugin ( $self->plugins ) {
    Class::Load::load_class( $plugin );
    my $license;
    eval {
      $license = $plugin->new({ holder => 'noddy' }); # need to set holder
    };
    next if $@;
    push @licenses, $license
      if $license->meta2_name eq $self->metaname
      or $license->meta_name  eq $self->metaname;
  }
  return \@licenses;
}

__PACKAGE__->meta->make_immutable;
no Moose;

qq[Licenses];

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zooky::License - license objects for Dist::Zooky

=head1 VERSION

version 0.22

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
