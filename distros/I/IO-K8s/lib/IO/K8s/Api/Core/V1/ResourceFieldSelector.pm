package IO::K8s::Api::Core::V1::ResourceFieldSelector;
# ABSTRACT: ResourceFieldSelector represents container resources (cpu, memory) and their output format
our $VERSION = '1.008';
use IO::K8s::Resource;

k8s containerName => Str;


k8s divisor => Quantity;


k8s resource => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::ResourceFieldSelector - ResourceFieldSelector represents container resources (cpu, memory) and their output format

=head1 VERSION

version 1.008

=head2 containerName

Container name: required for volumes, optional for env vars

=head2 divisor

Specifies the output format of the exposed resources, defaults to "1"

=head2 resource

Required: resource to select

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
