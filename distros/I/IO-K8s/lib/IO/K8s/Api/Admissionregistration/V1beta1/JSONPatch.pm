package IO::K8s::Api::Admissionregistration::V1beta1::JSONPatch;
# ABSTRACT: JSONPatch defines a JSON Patch.
our $VERSION = '1.106';
use IO::K8s::Resource;

k8s expression => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Admissionregistration::V1beta1::JSONPatch - JSONPatch defines a JSON Patch.

=head1 VERSION

version 1.106

=head2 expression

expression will be evaluated by CEL to create a L<JSON patch|https://jsonpatch.com/>. ref: L<https://github.com/google/cel-spec>

expression must return an array of JSONPatch values.

For example, this CEL expression returns a JSON patch to conditionally modify a value:

  [
    JSONPatch{op: "test", path: "/spec/example", value: "Red"},
    JSONPatch{op: "replace", path: "/spec/example", value: "Green"}
  ]

To define an object for the patch value, use Object types. For example:

  [
    JSONPatch{
      op: "add",
      path: "/spec/selector",
      value: Object.spec.selector{matchLabels: {"environment": "test"}}
    }
  ]

To use strings containing '/' and '~' as JSONPatch path keys, use "jsonpatch.escapeKey". For example:

  [
    JSONPatch{
      op: "add",
      path: "/metadata/labels/" + jsonpatch.escapeKey("example.com/environment"),
      value: "test"
    },
  ]

CEL expressions have access to the types needed to create JSON patches and objects:

- 'JSONPatch' - CEL type of JSON Patch operations. JSONPatch has the fields 'op', 'from', 'path' and 'value'. See L<JSON patch|https://jsonpatch.com/> for more details. The 'value' field may be set to any of: string, integer, array, map or object. If set, the 'path' and 'from' fields must be set to a L<JSON pointer|https://datatracker.ietf.org/doc/html/rfc6901/> string, where the 'jsonpatch.escapeKey()' CEL function may be used to escape path keys containing '/' and '~'.
- 'Object' - CEL type of the resource object.
- 'Object.<fieldName>' - CEL type of object field (such as 'Object.spec')
- 'Object.<fieldName1>.<fieldName2>...<fieldNameN>' - CEL type of nested field (such as 'Object.spec.containers')

CEL expressions have access to the contents of the API request, organized into CEL variables as well as some other useful variables:

- 'object' - The object from the incoming request. The value is null for DELETE requests.
- 'oldObject' - The existing object. The value is null for CREATE requests.
- 'request' - Attributes of the API request (L<AdmissionRequest|/pkg/apis/admission/types.go#AdmissionRequest>).
- 'params' - Parameter resource referred to by the policy binding being evaluated. Only populated if the policy has a ParamKind.
- 'namespaceObject' - The namespace object that the incoming object belongs to. The value is null for cluster-scoped resources.
- 'variables' - Map of composited variables, from its name to its lazily evaluated value. For example, a variable named 'foo' can be accessed as 'variables.foo'.
- 'authorizer' - A CEL Authorizer. May be used to perform authorization checks for the principal (user or service account) of the request. See L<https://pkg.go.dev/k8s.io/apiserver/pkg/cel/library#Authz>
- 'authorizer.requestResource' - A CEL ResourceCheck constructed from the 'authorizer' and configured with the request resource.

Required.

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
