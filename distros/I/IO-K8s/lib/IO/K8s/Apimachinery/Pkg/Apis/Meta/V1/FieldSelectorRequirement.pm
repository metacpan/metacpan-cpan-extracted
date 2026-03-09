package IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::FieldSelectorRequirement;
# ABSTRACT: FieldSelectorRequirement is a selector that contains values, a key, and an operator that relates the key and values.
our $VERSION = '1.008';
use IO::K8s::Resource;

k8s key => Str, 'required';


k8s operator => Str, 'required';


k8s values => [Str];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::FieldSelectorRequirement - FieldSelectorRequirement is a selector that contains values, a key, and an operator that relates the key and values.

=head1 VERSION

version 1.008

=head2 key

key is the field selector key that the requirement applies to.

=head2 operator

operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists, DoesNotExist. The list of operators may grow in the future.

=head2 values

values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty.

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
