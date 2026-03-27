package IO::K8s::Api::Flowcontrol::V1::LimitResponse;
# ABSTRACT: LimitResponse defines how to handle requests that can not be executed right now.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s queuing => 'Flowcontrol::V1::QueuingConfiguration';


k8s type => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Flowcontrol::V1::LimitResponse - LimitResponse defines how to handle requests that can not be executed right now.

=head1 VERSION

version 1.100

=head2 queuing

`queuing` holds the configuration parameters for queuing. This field may be non-empty only if `type` is `"Queue"`.

=head2 type

`type` is "Queue" or "Reject". "Queue" means that requests that can not be executed upon arrival are held in a queue until they can be executed or a queuing limit is reached. "Reject" means that requests that can not be executed upon arrival are rejected. Required.

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
