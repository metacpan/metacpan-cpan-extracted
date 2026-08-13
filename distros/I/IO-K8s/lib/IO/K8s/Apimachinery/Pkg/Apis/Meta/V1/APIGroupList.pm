package IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::APIGroupList;
# ABSTRACT: APIGroupList is a list of APIGroup, to allow clients to discover the API at /apis.
our $VERSION = '1.106';
use IO::K8s::Resource;

k8s apiVersion => Str;


k8s groups => ['Meta::V1::APIGroup'], 'required';


k8s kind => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::APIGroupList - APIGroupList is a list of APIGroup, to allow clients to discover the API at /apis.

=head1 VERSION

version 1.106

=head2 apiVersion

APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources

=head2 groups

groups is a list of APIGroup.

=head2 kind

Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds

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
