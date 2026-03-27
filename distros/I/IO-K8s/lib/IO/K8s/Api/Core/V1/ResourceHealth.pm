package IO::K8s::Api::Core::V1::ResourceHealth;
# ABSTRACT: ResourceHealth represents the health of a resource. It has the latest device health information. This is a part of KEP https://kep.k8s.io/4680 and historical health changes are planned to be added in future iterations of a KEP.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s health => Str;


k8s resourceID => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::ResourceHealth - ResourceHealth represents the health of a resource. It has the latest device health information. This is a part of KEP https://kep.k8s.io/4680 and historical health changes are planned to be added in future iterations of a KEP.

=head1 VERSION

version 1.100

=head2 health

Health of the resource. can be one of:  - Healthy: operates as normal 

=head2 resourceID

ResourceID is the unique identifier of the resource. See the ResourceID type for more information.

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
