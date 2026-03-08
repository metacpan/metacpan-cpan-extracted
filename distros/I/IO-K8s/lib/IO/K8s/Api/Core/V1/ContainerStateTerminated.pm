package IO::K8s::Api::Core::V1::ContainerStateTerminated;
# ABSTRACT: ContainerStateTerminated is a terminated state of a container.
our $VERSION = '1.006';
use IO::K8s::Resource;

k8s containerID => Str;


k8s exitCode => Int, 'required';


k8s finishedAt => Time;


k8s message => Str;


k8s reason => Str;


k8s signal => Int;


k8s startedAt => Time;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::ContainerStateTerminated - ContainerStateTerminated is a terminated state of a container.

=head1 VERSION

version 1.006

=head2 containerID

Container's ID in the format '<type>://<container_id>'

=head2 exitCode

Exit status from the last termination of the container

=head2 finishedAt

Time at which the container last terminated

=head2 message

Message regarding the last termination of the container

=head2 reason

(brief) reason from the last termination of the container

=head2 signal

Signal from the last termination of the container

=head2 startedAt

Time at which previous execution of the container started

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
