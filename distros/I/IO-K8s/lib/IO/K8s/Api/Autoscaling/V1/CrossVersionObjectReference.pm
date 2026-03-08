package IO::K8s::Api::Autoscaling::V1::CrossVersionObjectReference;
# ABSTRACT: CrossVersionObjectReference contains enough information to let you identify the referred resource.
our $VERSION = '1.006';
use IO::K8s::Resource;

k8s apiVersion => Str;


k8s kind => Str, 'required';


k8s name => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Autoscaling::V1::CrossVersionObjectReference - CrossVersionObjectReference contains enough information to let you identify the referred resource.

=head1 VERSION

version 1.006

=head2 apiVersion

apiVersion is the API version of the referent

=head2 kind

kind is the kind of the referent; More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds

=head2 name

name is the name of the referent; More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names

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
