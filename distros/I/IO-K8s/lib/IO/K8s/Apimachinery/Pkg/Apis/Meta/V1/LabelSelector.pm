package IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector;
# ABSTRACT: A label selector is a label query over a set of resources. The result of matchLabels and matchExpressions are ANDed. An empty label selector matches all objects. A null label selector matches no objects.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s matchExpressions => ['Meta::V1::LabelSelectorRequirement'];


k8s matchLabels => { Str => 1 };


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector - A label selector is a label query over a set of resources. The result of matchLabels and matchExpressions are ANDed. An empty label selector matches all objects. A null label selector matches no objects.

=head1 VERSION

version 1.100

=head2 matchExpressions

matchExpressions is a list of label selector requirements. The requirements are ANDed.

=head2 matchLabels

matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is "key", the operator is "In", and the values array contains only "value". The requirements are ANDed.

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
