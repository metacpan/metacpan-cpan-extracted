package Kubernetes::Comb::Static;
# ABSTRACT: A Comb whose manifests are .pk8s and YAML files
our $VERSION = '0.001';

use Moo;
extends 'Kubernetes::Comb';
with 'Kubernetes::Comb::Role::Static';

use Carp qw( croak );
use namespace::autoclean;


sub manifest_files {
  my ( $self ) = @_;
  croak ref($self).' has no manifest files: override manifest_files';
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::Comb::Static - A Comb whose manifests are .pk8s and YAML files

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  package MyApp::Comb::GeoIP;
  use Moo;
  extends 'Kubernetes::Comb::Static';

  use File::ShareDir qw( dist_dir );

  sub endpoints      { { name => 'http', port => 8080 } }
  sub manifest_dir   { dist_dir('MyApp-Combs') }
  sub manifest_files { 'geoip.yaml', 'geoip-cron.pk8s' }

=head1 DESCRIPTION

A L<Kubernetes::Comb> whose L<Kubernetes::Comb/manifests> come from files, by
L<Kubernetes::Comb::Role::Static>. A subclass names the files with
C<manifest_files> and where relative ones are with C<manifest_dir>;
everything else of the contract is the one of L<Kubernetes::Comb>.

For the stub of an existing Comb class -- which has to extend that class --
compose L<Kubernetes::Comb::Role::Static> instead.

=head2 manifest_files

Dies: a subclass overrides it with its list of files, see
L<Kubernetes::Comb::Role::Static/manifest_files>.

=head1 SEE ALSO

=over

=item * L<Kubernetes::Comb::Role::Static>

=item * L<Kubernetes::Comb>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-kubernetes-comb/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
