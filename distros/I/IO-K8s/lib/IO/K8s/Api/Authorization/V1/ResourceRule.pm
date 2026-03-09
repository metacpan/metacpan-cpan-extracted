package IO::K8s::Api::Authorization::V1::ResourceRule;
# ABSTRACT: ResourceRule is the list of actions the subject is allowed to perform on resources. The list ordering isn't significant, may contain duplicates, and possibly be incomplete.
our $VERSION = '1.008';
use IO::K8s::Resource;

k8s apiGroups => [Str];


k8s resourceNames => [Str];


k8s resources => [Str];


k8s verbs => [Str], 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Authorization::V1::ResourceRule - ResourceRule is the list of actions the subject is allowed to perform on resources. The list ordering isn't significant, may contain duplicates, and possibly be incomplete.

=head1 VERSION

version 1.008

=head2 apiGroups

APIGroups is the name of the APIGroup that contains the resources.  If multiple API groups are specified, any action requested against one of the enumerated resources in any API group will be allowed.  "*" means all.

=head2 resourceNames

ResourceNames is an optional white list of names that the rule applies to.  An empty set means that everything is allowed.  "*" means all.

=head2 resources

Resources is a list of resources this rule applies to.  "*" means all in the specified apiGroups.
 "*/foo" represents the subresource 'foo' for all resources in the specified apiGroups.

=head2 verbs

Verb is a list of kubernetes resource API verbs, like: get, list, watch, create, update, delete, proxy.  "*" means all.

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
