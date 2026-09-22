package IO::K8s::GatewayAPI::V1beta1::HTTPPathModifier;
# ABSTRACT: Path defines a path rewrite.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s replaceFullPath    => Str;
k8s replacePrefixMatch => Str;
k8s type               => Str, { required => 'schema', enum => [qw(ReplaceFullPath ReplacePrefixMatch)] };




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1beta1::HTTPPathModifier - Path defines a path rewrite.

=head1 VERSION

version 1.108

=head2 replaceFullPath

ReplaceFullPath specifies the value with which to replace the full path
of a request during a rewrite or redirect.

=head2 replacePrefixMatch

ReplacePrefixMatch specifies the value with which to replace the prefix
match of a request during a rewrite or redirect. For example, a request
to "/foo/bar" with a prefix match of "/foo" and a ReplacePrefixMatch
of "/xyz" would be modified to "/xyz/bar".

Note that this matches the behavior of the PathPrefix match type. This
matches full path elements. A path element refers to the list of labels
in the path split by the `/` separator. When specified, a trailing `/` is
ignored. For example, the paths `/abc`, `/abc/`, and `/abc/def` would all
match the prefix `/abc`, but the path `/abcd` would not.

ReplacePrefixMatch is only compatible with a `PathPrefix` HTTPRouteMatch.
Using any other HTTPRouteMatch type on the same HTTPRouteRule will result in
the implementation setting the Accepted Condition for the Route to `status: False`.

Request Path | Prefix Match | Replace Prefix | Modified Path

=head2 type

Type defines the type of path modifier. Additional types may be
added in a future release of the API.

Note that values may be added to this enum, implementations
must ensure that unknown values will not cause a crash.

Unknown values here must result in the implementation setting the
Accepted Condition for the Route to `status: False`, with a
Reason of `UnsupportedValue`.

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
