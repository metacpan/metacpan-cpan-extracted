package IO::K8s::ExternalSecrets::V1alpha1::TemplateFrom;
# ABSTRACT: TemplateFrom specifies a source for templates.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s configMap              => '+IO::K8s::ExternalSecrets::V1alpha1::TemplateRef';
k8s literal                => Str;
k8s secret                 => '+IO::K8s::ExternalSecrets::V1alpha1::TemplateRef';
k8s target                 => Str, { default => 'Data' };
k8s valuesDecodingStrategy => Str, { enum => [qw(Auto Base64 Base64URL None)] };






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1alpha1::TemplateFrom - TemplateFrom specifies a source for templates.

=head1 VERSION

version 1.108

=head2 configMap

TemplateRef specifies a reference to either a ConfigMap or a Secret resource.

=head2 literal

No description in the upstream schema.

=head2 secret

TemplateRef specifies a reference to either a ConfigMap or a Secret resource.

=head2 target

Target specifies where to place the template result.
For Secret resources the accepted values are empty, "Data", "Annotations" and "Labels";
any other value is rejected because it would allow writes to privileged Secret fields.
For custom resources (when spec.target.manifest is set), this supports
nested paths like "spec.database.config" or "data".

=head2 valuesDecodingStrategy

Used to define a decoding Strategy for the rendered template values.
Defaults to None when omitted.

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
