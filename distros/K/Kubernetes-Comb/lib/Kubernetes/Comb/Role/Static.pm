package Kubernetes::Comb::Role::Static;
# ABSTRACT: Comb manifests loaded from .pk8s and YAML files
our $VERSION = '0.001';

use Moo::Role;

use Carp qw( croak );
use Path::Tiny qw( path );
use namespace::autoclean;

requires qw( io_k8s manifest_files );


has _static_manifests => (
  is       => 'lazy',
  init_arg => undef
);

sub _build__static_manifests {
  my ( $self ) = @_;
  return [ map { $self->_load_manifest_file($_) } $self->manifest_files ];
}

sub manifests { @{ shift->_static_manifests } }


sub manifest_dir { return }


sub _load_manifest_file {
  my ( $self, $file ) = @_;
  my $path   = path($file)->absolute( $self->manifest_dir );
  my $format = $path =~ /\.pk8s\z/ ? 'pk8s' : $path =~ /\.ya?ml\z/ ? 'yaml' : undef;
  croak ref($self).': manifest file '.$path.' is neither .pk8s nor .yaml/.yml' unless $format;
  croak ref($self).': manifest file '.$path.' does not exist' unless $path->is_file;
  my $io = $self->io_k8s;
  # load_yaml gets the text: given a path it reads bytes, and takes a path
  # that is not a file for YAML.
  my $objects = eval {
    $format eq 'pk8s' ? $io->load( $path->stringify ) : $io->load_yaml( $path->slurp_utf8 );
  } or croak ref($self).': cannot load manifest file '.$path.': '.( $@ =~ s/\s+\z//r );
  return @$objects;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::Comb::Role::Static - Comb manifests loaded from .pk8s and YAML files

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  # A stub that is just a file: it inherits the contract of the Mailer and
  # swaps the implementation.
  package MyApp::Comb::Mailer::Stub;
  use Moo;
  extends 'MyApp::Comb::Mailer';
  with 'Kubernetes::Comb::Role::Static';

  use File::ShareDir qw( dist_dir );

  sub manifest_dir   { dist_dir('MyApp-Combs') }
  sub manifest_files { 'mailer-stub.pk8s' }

  # mailer-stub.pk8s, in the share dir of MyApp-Combs
  Deployment {
    name => 'mailer',
    spec => { ... }
  };
  Service { name => 'mailer', spec => { ... } };

=head1 DESCRIPTION

Makes L<Kubernetes::Comb/manifests> of the consuming class the resources
declared in files: C<.pk8s> files (the Perl DSL of L<IO::K8s/load>) and
C<.yaml>/C<.yml> files, multi-document YAML included (L<IO::K8s/load_yaml>).
The class names the files with L</manifest_files>, the directory relative
names are resolved against with L</manifest_dir>.

The role goes into any L<Kubernetes::Comb> subclass, the stub of an existing
Comb class included: its C<manifests> replaces the inherited one. A class that
is only files extends L<Kubernetes::Comb::Static> instead.

The files are parsed with the Comb's L<Kubernetes::Comb/io_k8s>, so its CRD
providers (or C<< unknown_kinds => 'unstructured' >>) decide which custom
resource Kinds they may contain. They are read once per instance, on the
first call of C<manifests>; a failed read is tried again on the next call.
They are static: namespace and Comb labels come from
L<Kubernetes::Comb/deploy>, anything that depends on L<Kubernetes::Comb/config>
belongs into a C<manifests> of Perl code (an C<around> works).

A C<.pk8s> file is Perl code, run in-process: name only files that ship with
your code, never a path from a custom resource or its C<config>. YAML files are
read as UTF-8; a C<.pk8s> file is Perl source, so one with non-ASCII text
starts with C<use utf8;>.

=head2 manifests

The objects of all L</manifest_files>, in the order of the files and, within
a file, in the order they are declared. Dies naming the file when one does
not exist, has neither extension or does not parse.

=head2 manifest_files

Required from the consuming class: the list of the files, each a C<.pk8s>,
C<.yaml> or C<.yml> file, absolute or relative to L</manifest_dir>.

=head2 manifest_dir

The directory relative L</manifest_files> are resolved against, for example
the share dir of the distribution with the Comb classes. Default: none, they
are taken from the current directory.

=head1 SEE ALSO

=over

=item * L<Kubernetes::Comb::Static> -- a Comb class that is only files

=item * L<IO::K8s/load>, L<IO::K8s/load_yaml>

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
