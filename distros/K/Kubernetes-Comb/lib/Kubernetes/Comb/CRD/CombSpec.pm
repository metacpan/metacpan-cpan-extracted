package Kubernetes::Comb::CRD::CombSpec;
# ABSTRACT: Spec of the Comb custom resource
our $VERSION = '0.001';

use IO::K8s::Resource;
use IO::K8s::Types qw( Opaque );
use Carp qw( croak );


k8s class => Str, {
  required    => 1,
  description => 'Perl class of the Comb; a stub is just another class'
};


k8s dependsOn => [Str], {
  description => 'Combs this one needs, as "name" or "namespace/name"'
};


k8s config => Opaque, {
  preserve_unknown => 1,
  description      => 'Free-form configuration for the class'
};


k8s enabled => Bool, {
  description => 'Unset: automatic, false: off, true: on'
};


k8s upstream => Opaque, {
  nullable         => 1,
  preserve_unknown => 1,
  description      => 'Where the Comb borrows its service from: class plus'
    .' upstream-specific keys; null means local'
};

has '+upstream' => ( predicate => 1 );


sub FROM_STRUCT {
  my ( $class, $struct ) = @_;
  croak $class.'->FROM_STRUCT needs a hashref, got '.( ref $struct || 'a plain scalar' )
    unless ref $struct eq 'HASH';
  my %args;
  for my $key ( keys %$struct ) {
    my $value = $struct->{$key};
    next unless defined $value || $key eq 'upstream';
    $args{$key} = ref $value eq 'HASH'  ? { %$value }
                : ref $value eq 'ARRAY' ? [ @$value ]
                : $value;
  }
  return $class->new(%args);
}


around TO_JSON => sub {
  my ( $orig, $self, @args ) = @_;
  my $data = $self->$orig(@args);
  $data->{upstream} = undef if $self->has_upstream && !defined $self->upstream;
  return $data;
};


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::Comb::CRD::CombSpec - Spec of the Comb custom resource

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  my $spec = Kubernetes::Comb::CRD::CombSpec->new(
    class     => 'MyApp::Comb::NATS',
    dependsOn => [ 'db' ],
    config    => { cluster_size => 3 },
    upstream  => {
      class   => 'Kubernetes::Comb::Upstream::K8s',
      context => 'dev'
    }
  );

  # explicit "local": the key exists, its value is null
  my $local = Kubernetes::Comb::CRD::CombSpec->new(
    class    => 'MyApp::Comb::NATS',
    upstream => undef
  );
  $local->has_upstream;   # true
  $local->upstream;       # undef

=head1 DESCRIPTION

The C<spec> of a L<Kubernetes::Comb::CRD::Comb>, an L<IO::K8s> class like any
other with one addition: C<upstream> keeps the difference between a key that
is absent and a key that is present with C<null>. The upstream is resolved
from the first source that I<exists>, and an explicit C<upstream: null> in the
custom resource is the answer "local" that ends the lookup.

L<IO::K8s> drops a JSON C<null> on the way in and never writes one on the way
out -- C<nullable> is a schema-only option there. So this class inflates
itself through C<FROM_STRUCT>, the hook L<IO::K8s/struct_to_object> documents
for classes the generic path would lose data of, and adds the C<null> back in
C<TO_JSON>. The schema marks C<upstream> C<nullable>, so the API server keeps
the C<null> too.

=head2 class

Required. The Perl class that implements the Comb. Pointing it at a stub class
selects the stub.

=head2 dependsOn

ArrayRef of the Combs this one depends on, each C<name> or C<namespace/name>.

=head2 config

Free-form hashref for the Comb class. Never credentials.

=head2 enabled

Tri-state: C<undef> is automatic, false switches the Comb off, true on.

=head2 upstream

Hashref naming the upstream: C<class>, always the fully qualified class name,
plus the keys that class takes -- for L<Kubernetes::Comb::Upstream::K8s>
C<context>, C<namespace> and C<name>. C<undef> while L</has_upstream> is true
is the explicit "local".

=head2 has_upstream

True when the spec carries an C<upstream> key at all, an explicit C<null>
included. This, not the truth of L</upstream>, says whether the custom
resource has a say in the upstream resolution.

=head2 FROM_STRUCT

  my $spec = Kubernetes::Comb::CRD::CombSpec->FROM_STRUCT($hashref);

Called by L<IO::K8s> whenever a C<CombSpec> is built from a plain structure.
Behaves like the generic inflation -- a C<null> field counts as absent,
containers are copied one level -- except that C<upstream: null> is kept.
Croaks on anything but a hashref.

=head2 TO_JSON

The inherited serialization, plus C<< upstream => undef >> (JSON C<null>) when
the spec holds the explicit "local".

=head1 SEE ALSO

=over

=item * L<Kubernetes::Comb::CRD::Comb>

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
