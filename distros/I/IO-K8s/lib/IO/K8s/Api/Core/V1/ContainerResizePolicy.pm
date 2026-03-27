package IO::K8s::Api::Core::V1::ContainerResizePolicy;
# ABSTRACT: ContainerResizePolicy represents resource resize policy for the container.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s resourceName => Str, 'required';


k8s restartPolicy => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::ContainerResizePolicy - ContainerResizePolicy represents resource resize policy for the container.

=head1 VERSION

version 1.100

=head2 resourceName

Name of the resource to which this resource resize policy applies. Supported values: cpu, memory.

=head2 restartPolicy

Restart policy to apply when specified resource is resized. If not specified, it defaults to NotRequired.

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
