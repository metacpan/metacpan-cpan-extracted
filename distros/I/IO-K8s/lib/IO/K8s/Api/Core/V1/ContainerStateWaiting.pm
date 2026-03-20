package IO::K8s::Api::Core::V1::ContainerStateWaiting;
# ABSTRACT: ContainerStateWaiting is a waiting state of a container.
our $VERSION = '1.009';
use IO::K8s::Resource;

k8s message => Str;


k8s reason => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::ContainerStateWaiting - ContainerStateWaiting is a waiting state of a container.

=head1 VERSION

version 1.009

=head2 message

Message regarding why the container is not yet running.

=head2 reason

(brief) reason the container is not yet running.

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
