package IO::K8s::ExternalSecrets::V1::ExternalSecretTemplate;
# ABSTRACT: Template defines a blueprint for the created Secret resource.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s data          => { Str => 1 };
k8s engineVersion => Str, { enum => [qw(v2)], default => 'v2' };
k8s mergePolicy   => Str, { enum => [qw(Replace Merge)], default => 'Replace' };
k8s metadata      => '+IO::K8s::ExternalSecrets::V1::ExternalSecretTemplateMetadata';
k8s templateFrom  => ['+IO::K8s::ExternalSecrets::V1::TemplateFrom'];
k8s type          => Str;







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::ExternalSecretTemplate - Template defines a blueprint for the created Secret resource.

=head1 VERSION

version 1.108

=head2 data

No description in the upstream schema.

=head2 engineVersion

EngineVersion specifies the template engine version
that should be used to compile/execute the
template specified in .data and .templateFrom[].

=head2 mergePolicy

TemplateMergePolicy defines how the rendered template should be merged with the existing Secret data.

=head2 metadata

ExternalSecretTemplateMetadata defines metadata fields for the Secret blueprint.

=head2 templateFrom

No description in the upstream schema.

=head2 type

No description in the upstream schema.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <getty@cpan.org>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
