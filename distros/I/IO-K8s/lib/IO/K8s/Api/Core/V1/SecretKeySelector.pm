package IO::K8s::Api::Core::V1::SecretKeySelector;
# ABSTRACT: SecretKeySelector selects a key of a Secret.
our $VERSION = '1.008';
use IO::K8s::Resource;

k8s key => Str, 'required';


k8s name => Str;


k8s optional => Bool;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::SecretKeySelector - SecretKeySelector selects a key of a Secret.

=head1 VERSION

version 1.008

=head2 key

The key of the secret to select from.  Must be a valid secret key.

=head2 name

Name of the referent. This field is effectively required, but due to backwards compatibility is allowed to be empty. Instances of this type with an empty value here are almost certainly wrong. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names

=head2 optional

Specify whether the Secret or its key must be defined

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Jose Luis Martinez <jlmartin@cpan.org> (original author, inactive)

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jose Luis Martinez.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
