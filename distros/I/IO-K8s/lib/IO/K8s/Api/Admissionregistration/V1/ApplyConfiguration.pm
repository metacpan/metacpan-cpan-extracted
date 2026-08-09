package IO::K8s::Api::Admissionregistration::V1::ApplyConfiguration;
# ABSTRACT: ApplyConfiguration defines the desired configuration values of an object.
our $VERSION = '1.105';
use IO::K8s::Resource;

k8s expression => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Admissionregistration::V1::ApplyConfiguration - ApplyConfiguration defines the desired configuration values of an object.

=head1 VERSION

version 1.105

=head2 expression

expression will be evaluated by CEL to create an apply configuration. ref: L<https://github.com/google/cel-spec>

Apply configurations are declared in CEL using object initialization. For example, this CEL expression returns an apply configuration to set a single field:

  Object{
    spec: Object.spec{
      serviceAccountName: "example"
    }
  }

Apply configurations may not modify atomic structs, maps or arrays due to the risk of accidental deletion of values not included in the apply configuration.

CEL expressions have access to the object types needed to create apply configurations:

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

The `apiVersion`, `kind`, `metadata.name` and `metadata.generateName` are always accessible from the root of the object. No other metadata properties are accessible.

Only property names of the form `[a-zA-Z_.-/][a-zA-Z0-9_.-/]*` are accessible. Accessible property names are escaped according to the following rules when accessed in the expression:

- '__' escapes to '__underscores__'
- '.' escapes to '__dot__'
- '-' escapes to '__dash__'
- '/' escapes to '__slash__'
- Property names that exactly match a CEL RESERVED keyword escape to '__{keyword}__'. The keywords are: "true", "false", "null", "in", "as", "break", "const", "continue", "else", "for", "function", "if", "import", "let", "loop", "package", "namespace", "return".

Equality on arrays with list type of 'set' or 'map' ignores element order, i.e. [1, 2] == [2, 1]. Concatenation on arrays with x-kubernetes-list-type use the semantics of the list type:

- 'set': `X + Y` performs a union where the array positions of all elements in `X` are preserved and non-intersecting elements in `Y` are appended, retaining their partial order.
- 'map': `X + Y` performs a merge where the array positions of all keys in `X` are preserved but the values are overwritten by values in `Y` when the key sets of `X` and `Y` intersect. Elements in `Y` with non-intersecting keys are appended, retaining their partial order.

Required.

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

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
